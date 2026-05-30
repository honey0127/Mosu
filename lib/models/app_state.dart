import 'package:flutter/material.dart';
import 'wardrobe_item.dart';
import 'experience.dart';
import 'animal.dart';
import 'deco_item.dart';

// ─────────────────────────── AppState (singleton) ────────────────────────────
class AppState {
  static final AppState i = AppState._();
  AppState._();

  int points = 0;
  int totalEarned = 0;
  List<String> completedIds = [];
  Set<String> unlockedIds = {};
  List<String> preferredKeywordLabels = [];
  Map<String, String?> equipped = {
    'background': null,
    'slot1': null,
    'slot2': null,
    'slot3': null,
    'badge': null,
  };

  // ── 캐릭터/방 신규 시스템 ─────────────────────────────────────────────────
  /// 선택된 얼굴 이모지 (캐릭터 베이스)
  String selectedFaceEmoji = '🐱';

  /// 선택된 동물 id (null = 아직 미선택)
  String? selectedAnimalId;

  /// 선택된 동물 객체 (id 기반 조회)
  Animal? get selectedAnimal => animalById(selectedAnimalId);

  /// 동물 선택 — id 저장 + 이모지 동기화
  void selectAnimal(String id) {
    selectedAnimalId = id;
    final a = animalById(id);
    if (a != null) selectedFaceEmoji = a.emoji;
  }

  /// 잠금 해제된 캐릭터/방 아이템 id 집합 (실 경험을 통해서만 해제됨)
  Set<String> wardrobeUnlocked = {};

  /// 캐릭터에 장착된 아이템 (slot → itemId)
  Map<String, String?> characterEquipped = {
    'hat': null,
    'top': null,
    'bottom': null,
    'accessory': null,
  };

  /// 방에 배치된 아이템 (slot → itemId)
  Map<String, String?> roomEquipped = {
    'wall': null,
    'desk': null,
    'floor': null,
    'window': null,
  };

  /// 완료한 경험의 카테고리 카운트 (어떤 영역을 얼마나 채웠는지 추적)
  Map<ExperienceCategory, int> categoryCounts = {};

  // ── AI 생성 소품 인벤토리 ─────────────────────────────────────────────────
  List<DecoItem> aiDecoItems = [];

  void addAiDecoItem(DecoItem item) {
    aiDecoItems.add(item);
    unlockedIds.add(item.id);
  }

  List<DecoItem> get allOwnedDecoItems =>
      aiDecoItems.where((it) => unlockedIds.contains(it.id)).toList();

  // ── 방 아이템 자유 배치 ───────────────────────────────────────────────────
  Set<String> placedRoomItemIds = {};
  Map<String, Offset> roomItemPositions = {};

  void placeRoomItem(String id) {
    placedRoomItemIds.add(id);
    if (!roomItemPositions.containsKey(id)) {
      final idx = placedRoomItemIds.length;
      roomItemPositions[id] = Offset(
        0.15 + (idx % 4) * 0.18,
        0.35 + (idx ~/ 4) * 0.15,
      );
    }
  }

  void removeRoomItem(String id) => placedRoomItemIds.remove(id);

  void moveRoomItem(String id, Offset pos) {
    roomItemPositions[id] = Offset(
      pos.dx.clamp(0.0, 1.0),
      pos.dy.clamp(0.0, 1.0),
    );
  }

  // ── 주간 홈 경험 추적 ─────────────────────────────────────────────────────
  int homeWeekNumber = 0;
  String? homeWeekFitId;
  String? homeWeekDareId;
  Set<String> homeWeekCompletedIds = {};
  Set<String> homeWeekExcluded = {}; // 네 버튼 시 새 페어 선택에서 제외할 ID
  int? pendingLevelUp;               // 홈 화면에서 레벨업 폭죽 표시용

  void setWeeklyPair({
    required int weekNum,
    required String? fitId,
    required String? dareId,
  }) {
    homeWeekNumber = weekNum;
    homeWeekFitId = fitId;
    homeWeekDareId = dareId;
    homeWeekCompletedIds = {};
  }

  /// "네" 버튼: 다음 build에서 완료된 경험을 제외한 새 페어를 강제 선택하도록 예약
  void markForRefresh(String completedId) {
    homeWeekExcluded = {completedId};
    homeWeekNumber = -1; // _pickPair()에서 재선택 트리거
  }

  void addPoints(int p) {
    points += p;
    totalEarned += p;
  }

  /// 경험 완료 — 포인트 지급 + 카테고리 카운트 + 아이템 자동 해금
  /// 새로 해금된 아이템 목록을 반환 (RewardDialog에서 표시용)
  List<WardrobeItem> completeExperience(Experience exp) {
    addPoints(exp.difficulty.points);
    completedIds.add(exp.id);

    // 이번 주 홈 경험 완료 추적
    if (exp.id == homeWeekFitId || exp.id == homeWeekDareId) {
      homeWeekCompletedIds.add(exp.id);
    }

    // 카테고리 카운트 업데이트
    categoryCounts[exp.category] =
        (categoryCounts[exp.category] ?? 0) + 1;

    final newlyUnlocked = <WardrobeItem>[];

    for (final item in allWardrobeItems) {
      if (wardrobeUnlocked.contains(item.id)) continue;
      if (item.category != exp.category) continue;

      // 무료 아이템 → 즉시 자동 해금
      if (item.cost == 0) {
        wardrobeUnlocked.add(item.id);
        newlyUnlocked.add(item);
        continue;
      }

      // 유료 아이템 → 해당 카테고리 누적 횟수 기반 해금
      // 1회: cost ≤ 50 / 3회: cost ≤ 100 / 5회: 전체
      final count = categoryCounts[exp.category] ?? 0;
      final unlockable = (count >= 5) ||
          (count >= 3 && item.cost <= 100) ||
          (count >= 1 && item.cost <= 50);
      if (unlockable) {
        wardrobeUnlocked.add(item.id);
        newlyUnlocked.add(item);
      }
    }

    return newlyUnlocked;
  }

  bool buy(String id, int cost) {
    if (points < cost) return false;
    points -= cost;
    unlockedIds.add(id);
    return true;
  }

  /// 캐릭터/방 아이템 구매 — 별도 컬렉션에 저장
  bool buyWardrobe(WardrobeItem item) {
    if (points < item.cost) return false;
    points -= item.cost;
    wardrobeUnlocked.add(item.id);
    return true;
  }

  /// 캐릭터 슬롯 장착 / 해제 (id == null 이면 해제)
  void equipCharacter(String slot, String? id) =>
      characterEquipped[slot] = id;

  /// 방 슬롯 배치 / 제거
  void equipRoom(String slot, String? id) => roomEquipped[slot] = id;

  void equip(String slot, String id) => equipped[slot] = id;

  int get level => (totalEarned / 100).floor() + 1;
  int get xpInLevel => totalEarned % 100;

  /// 방이 얼마나 채워졌는지 (0.0 ~ 1.0)
  double get roomFillRatio {
    final filled = roomEquipped.values.where((v) => v != null).length;
    return filled / roomSlots.length;
  }

  /// 캐릭터가 얼마나 꾸며졌는지 (0.0 ~ 1.0)
  double get characterFillRatio {
    final filled = characterEquipped.values.where((v) => v != null).length;
    return filled / characterSlots.length;
  }
}
