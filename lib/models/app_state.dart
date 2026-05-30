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

  String? selectedAnimalId;
  Animal? get selectedAnimal => animalById(selectedAnimalId);
  void selectAnimal(String id) => selectedAnimalId = id;

  Set<String> wardrobeUnlocked = {};

  Map<String, String?> characterEquipped = {
    'hat': null, 'top': null, 'bottom': null, 'accessory': null,
  };

  Map<String, String?> roomEquipped = {
    'wall': null, 'desk': null, 'floor': null, 'window': null,
  };

  Map<ExperienceCategory, int> categoryCounts = {};

  // ── 주간 추천 상태 ──
  int homeWeekNumber = 0;
  Set<String> homeWeekExcluded = {};
  List<String> homeWeekCompletedIds = [];
  String? homeWeekFitId;
  String? homeWeekDareId;

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

  // AI 생성 소품
  List<DecoItem> aiDecoItems = [];

  void addAiDecoItem(DecoItem item) {
    aiDecoItems.add(item);
    unlockedIds.add(item.id);
  }

  List<DecoItem> get allOwnedDecoItems =>
      allItems.where((it) => unlockedIds.contains(it.id)).toList() + aiDecoItems;

  // 자유 배치 방 시스템
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

  double get characterFillRatio {
    final slots = characterEquipped.keys.toList();
    return slots.where((s) => characterEquipped[s] != null).length / slots.length;
  }

  double get roomFillRatio {
    final total = aiDecoItems.where((it) => it.dimension == SelfDimension.internal).length;
    if (total == 0) return 0;
    return placedRoomItemIds.length / total.clamp(1, 99);
  }

  void equipCharacter(String slot, String? id) => characterEquipped[slot] = id;
  void equipRoom(String slot, String? id) => roomEquipped[slot] = id;

  List<WardrobeItem> completeExperience(Experience exp) {
    addPoints(exp.difficulty.points);
    completedIds.add(exp.id);
    categoryCounts[exp.category] = (categoryCounts[exp.category] ?? 0) + 1;
    final newlyUnlocked = <WardrobeItem>[];
    for (final item in allWardrobeItems) {
      if (wardrobeUnlocked.contains(item.id)) continue;
      if (item.category != exp.category) continue;
      if (item.cost == 0) {
        wardrobeUnlocked.add(item.id);
        newlyUnlocked.add(item);
      }
    }
    return newlyUnlocked;
  }
}

const List<DecoItem> allItems = [];
