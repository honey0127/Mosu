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
