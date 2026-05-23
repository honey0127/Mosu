import 'animal.dart';
import 'wardrobe_item.dart';
import 'experience.dart';

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
  /// 선택된 동물 (캐릭터 베이스). null = 아직 미선택 → picker 띄워야 함
  String? selectedAnimalId;

  Animal? get selectedAnimal => animalById(selectedAnimalId);

  void selectAnimal(String id) {
    selectedAnimalId = id;
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

  void addPoints(int p) {
    points += p;
    totalEarned += p;
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
