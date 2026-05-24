import 'experience.dart';

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
