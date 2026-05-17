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

  void equip(String slot, String id) => equipped[slot] = id;

  int get level => (totalEarned / 100).floor() + 1;
  int get xpInLevel => totalEarned % 100;
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