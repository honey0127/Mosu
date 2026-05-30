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

  // 캐릭터/방 시스템
  String? selectedAnimalId;
  Animal? get selectedAnimal => animalById(selectedAnimalId);
  void selectAnimal(String id) => selectedAnimalId = id;

  Set<String> wardrobeUnlocked = {};

  Map<String, String?> characterEquipped = {
    'hat': null,
    'top': null,
    'bottom': null,
    'accessory': null,
  };

  Map<String, String?> roomEquipped = {
    'wall': null,
    'desk': null,
    'floor': null,
    'window': null,
  };

  Map<ExperienceCategory, int> categoryCounts = {};

  // AI 생성 소품 인벤토리
  List<DecoItem> aiDecoItems = [];

  void addAiDecoItem(DecoItem item) {
    aiDecoItems.add(item);
    unlockedIds.add(item.id);
  }

  List<DecoItem> get allOwnedDecoItems =>
      allItems.where((it) => unlockedIds.contains(it.id)).toList() + aiDecoItems;

  void addPoints(int p) {
    points += p;
    totalEarned += p;
  }

  // 레벨 시스템 (100P per level)
  int get level => (totalEarned ~/ 100) + 1;
  int get xpInLevel => totalEarned % 100;

  // 캐릭터/방 채움 비율
  double get characterFillRatio {
    final slots = characterEquipped.keys.toList();
    final filled = slots.where((s) => characterEquipped[s] != null).length;
    return filled / slots.length;
  }

  double get roomFillRatio {
    final slots = roomEquipped.keys.toList();
    final filled = slots.where((s) => roomEquipped[s] != null).length;
    return filled / slots.length;
  }

  // 장착/해제
  void equipCharacter(String slot, String? id) {
    characterEquipped[slot] = id;
  }

  void equipRoom(String slot, String? id) {
    roomEquipped[slot] = id;
  }

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

// 기존 DecoItem 상점 목록 (비어있음)
const List<DecoItem> allItems = [];
