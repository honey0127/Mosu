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
