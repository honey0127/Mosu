import 'package:flutter/material.dart';
import 'wardrobe_item.dart';
import 'experience.dart';
import 'animal.dart';
import 'deco_item.dart';

class AppState {
  static final AppState i = AppState._();
  AppState._();

  int points = 0;
  int totalEarned = 0;
  List<String> completedIds = [];
  Set<String> unlockedIds = {};
  List<String> preferredKeywordLabels = [];
  Map<String, String?> equipped = {
    'background': null, 'slot1': null, 'slot2': null, 'slot3': null, 'badge': null,
  };

  /// 현재 얼굴 표정 (캐릭터 탭에서 사용)
  String selectedFaceEmoji = '😊';

  /// 선택된 동물 id (null = 지정되지 않음)
  String? selectedAnimalId;

  /// 선택된 동물 객체
  Animal? get selectedAnimal => animalById(selectedAnimalId);

  /// 동물 선택 id 반영 + 얼굴 초기화
  void selectAnimal(String id) {
    selectedAnimalId = id;
    final a = animalById(id);
    if (a != null) selectedFaceEmoji = a.emoji;
  }

  /// 해금 완료한 캐릭터/방 아이템 id 목록 (공통 경험을 통해 획득)
  Set<String> wardrobeUnlocked = {};

  /// 캐릭터 장착 정보 (slot -> itemId)
  Map<String, String?> characterEquipped = {
    'hat': null, 'top': null, 'bottom': null, 'accessory': null,
  };

  /// 방 장착 정보 (slot -> itemId)
  Map<String, String?> roomEquipped = {
    'wall': null, 'desk': null, 'floor': null, 'window': null,
  };

  /// 완료된 경험들의 카테고리 카운트 (특정 카테고리 경험 횟수에 따라 아이템 해금)
  Map<ExperienceCategory, int> categoryCounts = {};

  // ── 주간 추천 상태 ───────────────────────────────────────────────
  int homeWeekNumber = 0;
  Set<String> homeWeekExcluded = {}; // 재선택 버튼 클릭 시 한 번 배제할 추천 ID들
  List<String> homeWeekCompletedIds = [];
  String? homeWeekFitId;
  String? homeWeekDareId;
  int? pendingLevelUp; // 레벨업 이벤트 대기 중인 레벨

  void setWeeklyPair({
    required int weekNum,
    String? fitId,
    String? dareId,
  }) {
    homeWeekNumber = weekNum;
    homeWeekFitId = fitId;
    homeWeekDareId = dareId;
    homeWeekCompletedIds = [];
  }

  /// "재선택" 버튼: 다시 build하도록 완료 경험 목록에 임시 추가 후 주차 초기화
  void markForRefresh(String completedId) {
    homeWeekExcluded = {completedId};
    homeWeekNumber = -1; // _pickPair()에서 재선택 트리거
  }

  // ── AI 생성 소품 및 자유 배치 시스템 ─────────────────────────────
  List<DecoItem> aiDecoItems = [];

  void addAiDecoItem(DecoItem item) {
    aiDecoItems.add(item);
    unlockedIds.add(item.id);
  }

  List<DecoItem> get allOwnedDecoItems =>
      allItems.where((it) => unlockedIds.contains(it.id)).toList() + aiDecoItems;

  Set<String> placedRoomItemIds = {};
  Map<String, Offset> roomItemPositions = {}; // 상대 좌표 (0.0~1.0)

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

  void removeRoomItem(String id) {
    placedRoomItemIds.remove(id);
  }

  void moveRoomItem(String id, Offset relativePos) {
    roomItemPositions[id] = Offset(
      relativePos.dx.clamp(0.0, 1.0),
      relativePos.dy.clamp(0.0, 1.0),
    );
  }

  void addPoints(int p) {
    points += p;
    totalEarned += p;
  }

  int get level => (totalEarned ~/ 100) + 1;
  int get xpInLevel => totalEarned % 100;

  /// 캐릭터 꾸미기 진척도 (0.0 ~ 1.0)
  double get characterFillRatio {
    final filled = characterEquipped.values.where((v) => v != null).length;
    return filled / 4.0; // hat, top, bottom, accessory
  }

  /// 방 꾸미기 진척도 (0.0 ~ 1.0)
  double get roomFillRatio {
    final total = aiDecoItems.where((it) => it.dimension == SelfDimension.internal).length;
    if (total == 0) return 0;
    return placedRoomItemIds.length / total.clamp(1, 99);
  }

  void equipCharacter(String slot, String? id) => characterEquipped[slot] = id;
  void equipRoom(String slot, String? id) => roomEquipped[slot] = id;
  void equip(String slot, String id) => equipped[slot] = id;

  /// 경험 완료 시 포인트 지급 + 카테고리 카운트 + 아이템 해금
  List<WardrobeItem> completeExperience(Experience exp) {
    addPoints(exp.difficulty.points);
    completedIds.add(exp.id);

    // 이번 주 추천 경험 여부 체크
    if (exp.id == homeWeekFitId || exp.id == homeWeekDareId) {
      homeWeekCompletedIds.add(exp.id);
    }

    categoryCounts[exp.category] = (categoryCounts[exp.category] ?? 0) + 1;
    final newlyUnlocked = <WardrobeItem>[];

    for (final item in allWardrobeItems) {
      if (wardrobeUnlocked.contains(item.id)) continue;
      if (item.category != exp.category) continue;

      if (item.cost == 0) {
        wardrobeUnlocked.add(item.id);
        newlyUnlocked.add(item);
        continue;
      }

      // 완료 횟수에 따른 자동 해금 조건
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

  bool buyWardrobe(WardrobeItem item) {
    if (points < item.cost) return false;
    points -= item.cost;
    wardrobeUnlocked.add(item.id);
    return true;
  }
}

const List<DecoItem> allItems = [];
