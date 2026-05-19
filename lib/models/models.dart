import 'package:flutter/material.dart';

// ─────────────────────────── Keyword ─────────────────────────────────────────
class Keyword {
  final String id;
  final String label;
  final String emoji;
  final String category;
  final double size; // 버블 상대적 크기 (0.8 ~ 1.4)
  const Keyword({
    required this.id,
    required this.label,
    required this.emoji,
    required this.category,
    this.size = 1.0,
  });
}

// ─────────────────────────── Difficulty ──────────────────────────────────────
enum Difficulty { easy, medium, hard }

extension DifficultyX on Difficulty {
  String get label => switch (this) {
    Difficulty.easy => '쉬움',
    Difficulty.medium => '보통',
    Difficulty.hard => '어려움',
  };
  int get points => switch (this) {
    Difficulty.easy => 30,
    Difficulty.medium => 70,
    Difficulty.hard => 150,
  };
  Color get color => switch (this) {
    Difficulty.easy => const Color(0xFF1D9E75),
    Difficulty.medium => const Color(0xFFBA7517),
    Difficulty.hard => const Color(0xFFD85A30),
  };
  String get emoji => switch (this) {
    Difficulty.easy => '🌿',
    Difficulty.medium => '⚡',
    Difficulty.hard => '🔥',
  };
}

// ─────────────────────────── Experience ──────────────────────────────────────
class Experience {
  final String id;
  final String title;
  final String subtitle;
  final List<String> matchedKeywords;
  final Difficulty difficulty;
  final int energy;
  final int courage;
  final int cost;
  final bool isFit;

  const Experience({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.matchedKeywords,
    required this.difficulty,
    required this.energy,
    required this.courage,
    required this.cost,
    required this.isFit,
  });
}

// ─────────────────────────── DecoItem ────────────────────────────────────────
class DecoItem {
  final String id;
  final String name;
  final String emoji;
  final int cost;
  final String slot;
  final String hint;

  const DecoItem({
    required this.id,
    required this.name,
    required this.emoji,
    required this.cost,
    required this.slot,
    required this.hint,
  });
}

// ─────────────────────────── Experience Category ─────────────────────────────
/// 경험 카테고리 — 어떤 경험을 했냐에 따라 얻을 수 있는 아이템이 달라짐
enum ExperienceCategory {
  cooking,    // 요리
  exercise,   // 운동
  travel,     // 여행
  social,     // 소셜·만남
  creative,   // 창작·만들기
  reading,    // 독서
  meditation, // 명상
  hobby,      // 취미·수집
  music,      // 음악·감상
  nature,     // 자연·산책
}

extension ExperienceCategoryX on ExperienceCategory {
  String get label => switch (this) {
    ExperienceCategory.cooking    => '요리',
    ExperienceCategory.exercise   => '운동',
    ExperienceCategory.travel     => '여행',
    ExperienceCategory.social     => '만남',
    ExperienceCategory.creative   => '창작',
    ExperienceCategory.reading    => '독서',
    ExperienceCategory.meditation => '명상',
    ExperienceCategory.hobby      => '취미',
    ExperienceCategory.music      => '음악',
    ExperienceCategory.nature     => '자연',
  };
  String get emoji => switch (this) {
    ExperienceCategory.cooking    => '🍳',
    ExperienceCategory.exercise   => '🏃',
    ExperienceCategory.travel     => '✈️',
    ExperienceCategory.social     => '👥',
    ExperienceCategory.creative   => '🎨',
    ExperienceCategory.reading    => '📚',
    ExperienceCategory.meditation => '🧘',
    ExperienceCategory.hobby      => '🎯',
    ExperienceCategory.music      => '🎧',
    ExperienceCategory.nature     => '🌿',
  };
  /// 외면(캐릭터)에 반영되는 경험인지, 내면(방)에 반영되는 경험인지
  SelfDimension get dimension => switch (this) {
    ExperienceCategory.cooking    => SelfDimension.external,
    ExperienceCategory.exercise   => SelfDimension.external,
    ExperienceCategory.travel     => SelfDimension.external,
    ExperienceCategory.social     => SelfDimension.external,
    ExperienceCategory.creative   => SelfDimension.external,
    ExperienceCategory.reading    => SelfDimension.internal,
    ExperienceCategory.meditation => SelfDimension.internal,
    ExperienceCategory.hobby      => SelfDimension.internal,
    ExperienceCategory.music      => SelfDimension.internal,
    ExperienceCategory.nature     => SelfDimension.internal,
  };
}

// ─────────────────────────── Self Dimension ──────────────────────────────────
/// 외면(밖에서 어떤 사람) vs 내면(방·내부 세계)
enum SelfDimension { external, internal }

extension SelfDimensionX on SelfDimension {
  String get label => switch (this) {
    SelfDimension.external => '캐릭터',
    SelfDimension.internal => '방',
  };
  String get description => switch (this) {
    SelfDimension.external => '밖에서 어떤 사람인지',
    SelfDimension.internal => '내면이 어떤지',
  };
}

// ─────────────────────────── Character Customization ─────────────────────────

/// 캐릭터 성별 — 이미지 선택에 사용
enum CharacterGender { female, male }

extension CharacterGenderX on CharacterGender {
  String get label => switch (this) {
    CharacterGender.female => '여자',
    CharacterGender.male   => '남자',
  };
  String get assetPath => switch (this) {
    CharacterGender.female => 'assets/characters/woman.webp',
    CharacterGender.male   => 'assets/characters/man.webp',
  };
}

/// 머리 스타일 — 동물의숲 스타일 사람 캐릭터에 적용
enum HairStyle { shortBoy, bob, long, pigtails }

extension HairStyleX on HairStyle {
  String get label => switch (this) {
    HairStyle.shortBoy => '숏컷',
    HairStyle.bob      => '단발',
    HairStyle.long     => '긴머리',
    HairStyle.pigtails => '양갈래',
  };
  String get emoji => switch (this) {
    HairStyle.shortBoy => '✂️',
    HairStyle.bob      => '💆',
    HairStyle.long     => '👱',
    HairStyle.pigtails => '🎀',
  };
}

class HairColorOption {
  final String id;
  final String label;
  final Color color;
  const HairColorOption({required this.id, required this.label, required this.color});
}

final List<HairColorOption> allHairColors = const [
  HairColorOption(id: 'brown',  label: '갈색',   color: Color(0xFF5C3318)),
  HairColorOption(id: 'auburn', label: '적갈색', color: Color(0xFF8B3A1A)),
  HairColorOption(id: 'black',  label: '검정',   color: Color(0xFF1A1008)),
  HairColorOption(id: 'blonde', label: '금발',   color: Color(0xFFD4A832)),
  HairColorOption(id: 'red',    label: '빨강',   color: Color(0xFFB83232)),
  HairColorOption(id: 'pink',   label: '핑크',   color: Color(0xFFD46A8A)),
  HairColorOption(id: 'blue',   label: '파랑',   color: Color(0xFF3A6AB0)),
  HairColorOption(id: 'white',  label: '흰색',   color: Color(0xFFD8D4C8)),
];

class SkinColorOption {
  final String id;
  final String label;
  final Color color;
  const SkinColorOption({required this.id, required this.label, required this.color});
}

final List<SkinColorOption> allSkinColors = const [
  SkinColorOption(id: 'light',  label: '밝은',   color: Color(0xFFF5C9A0)),
  SkinColorOption(id: 'medium', label: '보통',   color: Color(0xFFDBA078)),
  SkinColorOption(id: 'tan',    label: '구릿빛', color: Color(0xFFBF7D50)),
  SkinColorOption(id: 'dark',   label: '어두운', color: Color(0xFF7A4E2D)),
];

/// 캐릭터 프로필 — 사람 한 명의 외형 정보 + 장착 아이템
class CharacterProfile {
  String name;
  CharacterGender gender;
  HairStyle hairStyle;
  String hairColorId;
  String skinColorId;
  Map<String, String?> equipped;

  CharacterProfile({
    required this.name,
    this.gender = CharacterGender.female,
    this.hairStyle = HairStyle.shortBoy,
    this.hairColorId = 'brown',
    this.skinColorId = 'light',
    Map<String, String?>? equipped,
  }) : equipped = equipped ?? {
    'hat': null,
    'top': 'char_top_basic',
    'bottom': 'char_bottom_basic',
    'accessory': null,
  };

  Color get hairColor =>
      allHairColors.firstWhere((h) => h.id == hairColorId,
          orElse: () => allHairColors.first).color;

  Color get skinColor =>
      allSkinColors.firstWhere((s) => s.id == skinColorId,
          orElse: () => allSkinColors.first).color;
}

// ─────────────────────────── Wardrobe Item ───────────────────────────────────
/// 캐릭터/방을 꾸미는 아이템.
/// dimension=external → 캐릭터(옷·소품), dimension=internal → 방(가구·소품)
class WardrobeItem {
  final String id;
  final String name;
  final String emoji;
  final String slot;                    // 캐릭터: hat/top/bottom/accessory · 방: wall/desk/floor/window
  final SelfDimension dimension;
  final ExperienceCategory category;
  final int cost;
  final String unlockHint;

  const WardrobeItem({
    required this.id,
    required this.name,
    required this.emoji,
    required this.slot,
    required this.dimension,
    required this.category,
    required this.cost,
    required this.unlockHint,
  });
}

/// 캐릭터 슬롯 정의 (위→아래 순서)
const characterSlots = <String>['hat', 'top', 'bottom', 'accessory'];
const characterSlotLabels = <String, String>{
  'hat': '모자',
  'top': '상의',
  'bottom': '하의',
  'accessory': '소품',
};

/// 방 슬롯 정의
const roomSlots = <String>['wall', 'desk', 'floor', 'window'];
const roomSlotLabels = <String, String>{
  'wall': '벽',
  'desk': '책상',
  'floor': '바닥',
  'window': '창문',
};

// ─────────────────────────── AppState (singleton) ────────────────────────────
class AppState {
  static final AppState i = AppState._();
  AppState._();

  int points = 150;
  int totalEarned = 150;
  List<String> completedIds = ['exp_001'];
  Set<String> unlockedIds = {'bg_forest', 'obj_seed'};
  Map<String, String?> equipped = {
    'background': 'bg_forest',
    'slot1': 'obj_seed',
    'slot2': null,
    'slot3': null,
    'badge': null,
  };

  // ── 두 캐릭터 프로필 ──────────────────────────────────────────────────────
  List<CharacterProfile> characters = [
    CharacterProfile(
      name: '나',
      gender: CharacterGender.female,
      hairStyle: HairStyle.bob,
      hairColorId: 'brown',
      skinColorId: 'light',
      equipped: {
        'hat': null,
        'top': 'char_top_basic',
        'bottom': 'char_bottom_basic',
        'accessory': null,
      },
    ),
    CharacterProfile(
      name: '친구',
      gender: CharacterGender.male,
      hairStyle: HairStyle.shortBoy,
      hairColorId: 'auburn',
      skinColorId: 'light',
      equipped: {
        'hat': null,
        'top': 'char_top_basic',
        'bottom': 'char_bottom_basic',
        'accessory': null,
      },
    ),
  ];

  /// 현재 편집 중인 캐릭터 인덱스 (0 또는 1)
  int selectedCharacterIndex = 0;

  CharacterProfile get currentCharacter => characters[selectedCharacterIndex];

  /// 잠금 해제된 캐릭터/방 아이템 id 집합 (실 경험을 통해서만 해제됨)
  Set<String> wardrobeUnlocked = {
    'char_top_basic',
    'char_bottom_basic',
    'room_wall_empty_paint',
  };

  /// 방에 배치된 아이템 (slot → itemId)
  Map<String, String?> roomEquipped = {
    'wall': 'room_wall_empty_paint',
    'desk': null,
    'floor': null,
    'window': null,
  };

  /// 완료한 경험의 카테고리 카운트 (어떤 영역을 얼마나 채웠는지 추적)
  Map<ExperienceCategory, int> categoryCounts = {
    ExperienceCategory.cooking: 0,
    ExperienceCategory.exercise: 0,
    ExperienceCategory.nature: 1, // exp_001 (새벽 산책)을 nature로 가정
  };

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

  /// 특정 캐릭터 슬롯 장착 / 해제 (id == null 이면 해제)
  void equipCharacter(int charIndex, String slot, String? id) =>
      characters[charIndex].equipped[slot] = id;

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

  /// 두 캐릭터 합산 완성도 (0.0 ~ 1.0)
  double get characterFillRatio {
    final total = characterSlots.length * characters.length;
    final filled = characters.fold<int>(
        0, (sum, c) => sum + c.equipped.values.where((v) => v != null).length);
    return filled / total;
  }
}

// ─────────────────────────── Keywords (30개) ─────────────────────────────────
final List<Keyword> allKeywords = [
  const Keyword(id: 'k01', label: '느린',        emoji: '🐌', category: 'mood',      size: 1.0),
  const Keyword(id: 'k02', label: '감성적',      emoji: '🎨', category: 'mood',      size: 1.2),
  const Keyword(id: 'k03', label: '조용한',      emoji: '🤫', category: 'mood',      size: 1.0),
  const Keyword(id: 'k04', label: '설레는',      emoji: '💫', category: 'mood',      size: 1.1),
  const Keyword(id: 'k05', label: '몽환적',      emoji: '🌫️', category: 'mood',      size: 0.9),
  const Keyword(id: 'k06', label: '빠른',        emoji: '⚡', category: 'mood',      size: 0.85),
  const Keyword(id: 'k07', label: '새벽',        emoji: '🌙', category: 'time',      size: 1.15),
  const Keyword(id: 'k08', label: '이른 아침',   emoji: '🌅', category: 'time',      size: 1.3),
  const Keyword(id: 'k09', label: '낮',          emoji: '☀️', category: 'time',      size: 0.9),
  const Keyword(id: 'k10', label: '저녁',        emoji: '🌆', category: 'time',      size: 1.0),
  const Keyword(id: 'k11', label: '주말',        emoji: '📅', category: 'time',      size: 1.1),
  const Keyword(id: 'k12', label: '낯선 곳',    emoji: '🗺️', category: 'place',     size: 1.25),
  const Keyword(id: 'k13', label: '도심',        emoji: '🏙️', category: 'place',     size: 1.0),
  const Keyword(id: 'k14', label: '자연',        emoji: '🌿', category: 'place',     size: 1.2),
  const Keyword(id: 'k15', label: '카페',        emoji: '☕', category: 'place',     size: 0.9),
  const Keyword(id: 'k16', label: '바닷가',      emoji: '🌊', category: 'place',     size: 1.15),
  const Keyword(id: 'k17', label: '골목',        emoji: '🏘️', category: 'place',     size: 0.85),
  const Keyword(id: 'k18', label: '혼자',        emoji: '🚶', category: 'social',    size: 1.1),
  const Keyword(id: 'k19', label: '함께',        emoji: '👫', category: 'social',    size: 1.1),
  const Keyword(id: 'k20', label: '소란스러운',  emoji: '🎉', category: 'social',    size: 1.35),
  const Keyword(id: 'k21', label: '낯선 사람',   emoji: '👤', category: 'social',    size: 1.05),
  const Keyword(id: 'k22', label: '몸쓰는',      emoji: '🏃', category: 'activity',  size: 1.0),
  const Keyword(id: 'k23', label: '만들기',      emoji: '🛠️', category: 'activity',  size: 1.1),
  const Keyword(id: 'k24', label: '먹는',        emoji: '🍜', category: 'activity',  size: 1.2),
  const Keyword(id: 'k25', label: '걷기',        emoji: '👟', category: 'activity',  size: 0.9),
  const Keyword(id: 'k26', label: '배우기',      emoji: '📖', category: 'activity',  size: 1.0),
  const Keyword(id: 'k27', label: '도전적',      emoji: '🔥', category: 'challenge', size: 1.3),
  const Keyword(id: 'k28', label: '처음 해보는', emoji: '🌱', category: 'challenge', size: 1.4),
  const Keyword(id: 'k29', label: '무계획',      emoji: '🎲', category: 'challenge', size: 1.0),
  const Keyword(id: 'k30', label: '두근두근',    emoji: '💓', category: 'challenge', size: 1.15),
];

// ─────────────────────────── Sample Experiences ───────────────────────────────
final List<Experience> allExperiences = [
  const Experience(
    id: 'exp_001', isFit: true,
    title: '새벽 3시 편의점 산책',
    subtitle: '아무도 없는 골목을 혼자 걷기',
    matchedKeywords: ['혼자', '새벽', '도심', '느린'],
    difficulty: Difficulty.easy, energy: 1, courage: 1, cost: 1,
  ),
  const Experience(
    id: 'exp_002', isFit: false,
    title: '도자기 원데이 클래스',
    subtitle: '처음 만나는 사람들과 흙 빚기',
    matchedKeywords: ['함께', '낮', '몸쓰는'],
    difficulty: Difficulty.medium, energy: 2, courage: 2, cost: 2,
  ),
  const Experience(
    id: 'exp_003', isFit: true,
    title: '낯선 동네 무작정 내리기',
    subtitle: '지도 없이 처음 보는 역에서 2시간',
    matchedKeywords: ['혼자', '낯선 곳', '도전적'],
    difficulty: Difficulty.medium, energy: 1, courage: 3, cost: 1,
  ),
  const Experience(
    id: 'exp_004', isFit: false,
    title: '48시간 디지털 디톡스',
    subtitle: '스마트폰 없이 이틀을 버텨보기',
    matchedKeywords: ['혼자', '도전적', '느린'],
    difficulty: Difficulty.hard, energy: 1, courage: 3, cost: 1,
  ),
  const Experience(
    id: 'exp_005', isFit: true,
    title: '새벽 수영장 첫 도전',
    subtitle: '아침 6시 수영장에서 수영 배우기',
    matchedKeywords: ['새벽', '몸쓰는', '도전적'],
    difficulty: Difficulty.hard, energy: 3, courage: 2, cost: 2,
  ),
];

final List<DecoItem> allItems = [
  const DecoItem(id: 'bg_forest', name: '새벽 숲',       emoji: '🌲', cost: 50,  slot: 'background', hint: '자연 경험 완료'),
  const DecoItem(id: 'bg_city',   name: '도심 야경',     emoji: '🌃', cost: 100, slot: 'background', hint: '도심 경험 3회'),
  const DecoItem(id: 'bg_ocean',  name: '새벽 바다',     emoji: '🌊', cost: 200, slot: 'background', hint: '어려움 경험 완료'),
  const DecoItem(id: 'obj_seed',  name: '씨앗',          emoji: '🌱', cost: 0,   slot: 'object',     hint: '첫 경험 완료'),
  const DecoItem(id: 'obj_mug',   name: '새벽 머그',     emoji: '☕', cost: 30,  slot: 'object',     hint: '새벽 경험 완료'),
  const DecoItem(id: 'obj_pot',   name: '항아리',        emoji: '🏺', cost: 70,  slot: 'object',     hint: '도자기 클래스 완료'),
  const DecoItem(id: 'obj_moon',  name: '달',            emoji: '🌙', cost: 100, slot: 'object',     hint: '혼자 경험 5회'),
  const DecoItem(id: 'badge_brave', name: '용감한 탐험가', emoji: '🦁', cost: 150, slot: 'badge',    hint: '어려움 3회'),
  const DecoItem(id: 'badge_dawn',  name: '새벽을 사는 자', emoji: '🌅', cost: 80, slot: 'badge',   hint: '새벽 경험 3회'),
];

// ─────────────────────────── Wardrobe Items (캐릭터/방 통합) ──────────────────
/// 캐릭터 + 방 아이템 통합 리스트.
/// 각 아이템은 특정 경험 카테고리로만 잠금 해제됨 — "어떤 경험을 했느냐" 가 곧 외형이 됨.
final List<WardrobeItem> allWardrobeItems = [
  // ═══════ 캐릭터 (외면) ════════════════════════════════════════════════════
  // ── 기본 의상 (시드) ──
  const WardrobeItem(
    id: 'char_top_basic', name: '기본 티셔츠', emoji: '👕',
    slot: 'top', dimension: SelfDimension.external,
    category: ExperienceCategory.social, cost: 0,
    unlockHint: '첫 경험 완료 시 기본 지급',
  ),
  const WardrobeItem(
    id: 'char_bottom_basic', name: '기본 바지', emoji: '👖',
    slot: 'bottom', dimension: SelfDimension.external,
    category: ExperienceCategory.social, cost: 0,
    unlockHint: '첫 경험 완료 시 기본 지급',
  ),

  // ── 요리 (cooking) ──
  const WardrobeItem(
    id: 'char_top_apron', name: '앞치마', emoji: '🥻',
    slot: 'top', dimension: SelfDimension.external,
    category: ExperienceCategory.cooking, cost: 60,
    unlockHint: '🍳 요리 경험 완료',
  ),
  const WardrobeItem(
    id: 'char_hat_chef', name: '셰프 모자', emoji: '👨‍🍳',
    slot: 'hat', dimension: SelfDimension.external,
    category: ExperienceCategory.cooking, cost: 100,
    unlockHint: '🍳 요리 경험 3회',
  ),
  const WardrobeItem(
    id: 'char_acc_knife', name: '주방칼', emoji: '🔪',
    slot: 'accessory', dimension: SelfDimension.external,
    category: ExperienceCategory.cooking, cost: 80,
    unlockHint: '🍳 요리 경험 2회',
  ),

  // ── 운동 (exercise) ──
  const WardrobeItem(
    id: 'char_top_sportswear', name: '운동복', emoji: '🦺',
    slot: 'top', dimension: SelfDimension.external,
    category: ExperienceCategory.exercise, cost: 70,
    unlockHint: '🏃 운동 경험 완료',
  ),
  const WardrobeItem(
    id: 'char_bottom_shorts', name: '러닝 반바지', emoji: '🩳',
    slot: 'bottom', dimension: SelfDimension.external,
    category: ExperienceCategory.exercise, cost: 60,
    unlockHint: '🏃 운동 경험 완료',
  ),
  const WardrobeItem(
    id: 'char_hat_cap', name: '스포츠 캡', emoji: '🧢',
    slot: 'hat', dimension: SelfDimension.external,
    category: ExperienceCategory.exercise, cost: 80,
    unlockHint: '🏃 운동 경험 2회',
  ),

  // ── 여행 (travel) ──
  const WardrobeItem(
    id: 'char_acc_camera', name: '필름 카메라', emoji: '📷',
    slot: 'accessory', dimension: SelfDimension.external,
    category: ExperienceCategory.travel, cost: 120,
    unlockHint: '✈️ 여행 경험 완료',
  ),
  const WardrobeItem(
    id: 'char_hat_strawhat', name: '밀짚모자', emoji: '👒',
    slot: 'hat', dimension: SelfDimension.external,
    category: ExperienceCategory.travel, cost: 90,
    unlockHint: '✈️ 여행 경험 완료',
  ),
  const WardrobeItem(
    id: 'char_acc_backpack', name: '배낭', emoji: '🎒',
    slot: 'accessory', dimension: SelfDimension.external,
    category: ExperienceCategory.travel, cost: 100,
    unlockHint: '✈️ 여행 경험 2회',
  ),

  // ── 만남 (social) ──
  const WardrobeItem(
    id: 'char_top_blazer', name: '재킷', emoji: '🧥',
    slot: 'top', dimension: SelfDimension.external,
    category: ExperienceCategory.social, cost: 110,
    unlockHint: '👥 만남 경험 2회',
  ),
  const WardrobeItem(
    id: 'char_acc_flowers', name: '꽃다발', emoji: '💐',
    slot: 'accessory', dimension: SelfDimension.external,
    category: ExperienceCategory.social, cost: 70,
    unlockHint: '👥 만남 경험 완료',
  ),

  // ── 창작 (creative) ──
  const WardrobeItem(
    id: 'char_top_artist', name: '물감 앞치마', emoji: '🎨',
    slot: 'top', dimension: SelfDimension.external,
    category: ExperienceCategory.creative, cost: 90,
    unlockHint: '🎨 창작 경험 완료',
  ),
  const WardrobeItem(
    id: 'char_acc_brush', name: '붓', emoji: '🖌️',
    slot: 'accessory', dimension: SelfDimension.external,
    category: ExperienceCategory.creative, cost: 60,
    unlockHint: '🎨 창작 경험 완료',
  ),
  const WardrobeItem(
    id: 'char_hat_beret', name: '베레모', emoji: '🎩',
    slot: 'hat', dimension: SelfDimension.external,
    category: ExperienceCategory.creative, cost: 100,
    unlockHint: '🎨 창작 경험 2회',
  ),

  // ═══════ 방 (내면) ════════════════════════════════════════════════════════
  // ── 기본 (시드) ──
  const WardrobeItem(
    id: 'room_wall_empty_paint', name: '빈 흰 벽', emoji: '⬜',
    slot: 'wall', dimension: SelfDimension.internal,
    category: ExperienceCategory.reading, cost: 0,
    unlockHint: '기본 벽 — 아직 비어있음',
  ),

  // ── 독서 (reading) ──
  const WardrobeItem(
    id: 'room_desk_books', name: '책 더미', emoji: '📚',
    slot: 'desk', dimension: SelfDimension.internal,
    category: ExperienceCategory.reading, cost: 50,
    unlockHint: '📚 독서 경험 완료',
  ),
  const WardrobeItem(
    id: 'room_wall_bookshelf', name: '책장', emoji: '🗃️',
    slot: 'wall', dimension: SelfDimension.internal,
    category: ExperienceCategory.reading, cost: 130,
    unlockHint: '📚 독서 경험 3회',
  ),
  const WardrobeItem(
    id: 'room_desk_lamp', name: '독서등', emoji: '💡',
    slot: 'desk', dimension: SelfDimension.internal,
    category: ExperienceCategory.reading, cost: 70,
    unlockHint: '📚 독서 경험 2회',
  ),

  // ── 명상 (meditation) ──
  const WardrobeItem(
    id: 'room_floor_cushion', name: '명상 쿠션', emoji: '🟣',
    slot: 'floor', dimension: SelfDimension.internal,
    category: ExperienceCategory.meditation, cost: 60,
    unlockHint: '🧘 명상 경험 완료',
  ),
  const WardrobeItem(
    id: 'room_desk_incense', name: '향초', emoji: '🕯️',
    slot: 'desk', dimension: SelfDimension.internal,
    category: ExperienceCategory.meditation, cost: 50,
    unlockHint: '🧘 명상 경험 완료',
  ),
  const WardrobeItem(
    id: 'room_wall_zen', name: '선화', emoji: '🖼️',
    slot: 'wall', dimension: SelfDimension.internal,
    category: ExperienceCategory.meditation, cost: 120,
    unlockHint: '🧘 명상 경험 3회',
  ),

  // ── 취미 (hobby) ──
  const WardrobeItem(
    id: 'room_desk_puzzle', name: '직소 퍼즐', emoji: '🧩',
    slot: 'desk', dimension: SelfDimension.internal,
    category: ExperienceCategory.hobby, cost: 70,
    unlockHint: '🎯 취미 경험 완료',
  ),
  const WardrobeItem(
    id: 'room_floor_rug', name: '러그', emoji: '🟫',
    slot: 'floor', dimension: SelfDimension.internal,
    category: ExperienceCategory.hobby, cost: 100,
    unlockHint: '🎯 취미 경험 2회',
  ),

  // ── 음악 (music) ──
  const WardrobeItem(
    id: 'room_desk_record', name: '턴테이블', emoji: '💿',
    slot: 'desk', dimension: SelfDimension.internal,
    category: ExperienceCategory.music, cost: 140,
    unlockHint: '🎧 음악 경험 2회',
  ),
  const WardrobeItem(
    id: 'room_wall_poster', name: '음반 포스터', emoji: '🎵',
    slot: 'wall', dimension: SelfDimension.internal,
    category: ExperienceCategory.music, cost: 60,
    unlockHint: '🎧 음악 경험 완료',
  ),

  // ── 자연 (nature) ──
  const WardrobeItem(
    id: 'room_window_plant', name: '창가 식물', emoji: '🪴',
    slot: 'window', dimension: SelfDimension.internal,
    category: ExperienceCategory.nature, cost: 60,
    unlockHint: '🌿 자연 경험 완료',
  ),
  const WardrobeItem(
    id: 'room_window_sunlight', name: '아침 햇살', emoji: '🌤️',
    slot: 'window', dimension: SelfDimension.internal,
    category: ExperienceCategory.nature, cost: 90,
    unlockHint: '🌿 자연 경험 2회',
  ),
  const WardrobeItem(
    id: 'room_floor_stone', name: '정원석', emoji: '🪨',
    slot: 'floor', dimension: SelfDimension.internal,
    category: ExperienceCategory.nature, cost: 80,
    unlockHint: '🌿 자연 경험 2회',
  ),
];