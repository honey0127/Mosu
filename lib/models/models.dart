import 'package:flutter/material.dart';

// ─────────────────────────── Keyword ─────────────────────────────────────────
class Keyword {
  final String id;
  final String label;
  final String category;
  const Keyword({required this.id, required this.label, required this.category});
}

// ─────────────────────────── Difficulty ──────────────────────────────────────
enum Difficulty { easy, medium, hard }

extension DifficultyX on Difficulty {
  String get label => switch (this) {
    Difficulty.easy   => '쉬움',
    Difficulty.medium => '보통',
    Difficulty.hard   => '어려움',
  };
  int get points => switch (this) {
    Difficulty.easy   => 30,
    Difficulty.medium => 70,
    Difficulty.hard   => 150,
  };
  Color get color => switch (this) {
    Difficulty.easy   => const Color(0xFF1D9E75),
    Difficulty.medium => const Color(0xFFBA7517),
    Difficulty.hard   => const Color(0xFFD85A30),
  };
  String get emoji => switch (this) {
    Difficulty.easy   => '🌿',
    Difficulty.medium => '⚡',
    Difficulty.hard   => '🔥',
  };
}

// ─────────────────────────── Experience ──────────────────────────────────────
class Experience {
  final String id;
  final String title;
  final String subtitle;
  final List<String> matchedKeywords;
  final Difficulty difficulty;
  final int energy;   // 1–3
  final int courage;  // 1–3
  final int cost;     // 1–3
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
  final String slot; // 'background' | 'object' | 'badge'
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

// ─────────────────────────── Sample Data ─────────────────────────────────────
final List<Keyword> allKeywords = [
  const Keyword(id: 'k01', label: '혼자',      category: 'social'),
  const Keyword(id: 'k02', label: '함께',      category: 'social'),
  const Keyword(id: 'k03', label: '새벽',      category: 'time'),
  const Keyword(id: 'k04', label: '낮',        category: 'time'),
  const Keyword(id: 'k05', label: '저녁',      category: 'time'),
  const Keyword(id: 'k06', label: '느린',      category: 'mood'),
  const Keyword(id: 'k07', label: '빠른',      category: 'mood'),
  const Keyword(id: 'k08', label: '감성적',    category: 'mood'),
  const Keyword(id: 'k09', label: '도전적',    category: 'mood'),
  const Keyword(id: 'k10', label: '낯선 곳',   category: 'place'),
  const Keyword(id: 'k11', label: '도심',      category: 'place'),
  const Keyword(id: 'k12', label: '자연',      category: 'place'),
  const Keyword(id: 'k13', label: '몸쓰는',    category: 'intensity'),
  const Keyword(id: 'k14', label: '조용한',    category: 'intensity'),
  const Keyword(id: 'k15', label: '소란스러운', category: 'intensity'),
];

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
    subtitle: '지도 없이 처음 보는 역서 2시간',
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
  const DecoItem(id: 'bg_forest', name: '새벽 숲',     emoji: '🌲', cost: 50,  slot: 'background', hint: '자연 경험 완료'),
  const DecoItem(id: 'bg_city',   name: '도심 야경',   emoji: '🌃', cost: 100, slot: 'background', hint: '도심 경험 3회'),
  const DecoItem(id: 'bg_ocean',  name: '새벽 바다',   emoji: '🌊', cost: 200, slot: 'background', hint: '어려움 경험 완료'),
  const DecoItem(id: 'obj_seed',  name: '씨앗',        emoji: '🌱', cost: 0,   slot: 'object',     hint: '첫 경험 완료'),
  const DecoItem(id: 'obj_mug',   name: '새벽 머그',   emoji: '☕', cost: 30,  slot: 'object',     hint: '새벽 경험 완료'),
  const DecoItem(id: 'obj_pot',   name: '항아리',      emoji: '🏺', cost: 70,  slot: 'object',     hint: '도자기 클래스 완료'),
  const DecoItem(id: 'obj_moon',  name: '달',          emoji: '🌙', cost: 100, slot: 'object',     hint: '혼자 경험 5회'),
  const DecoItem(id: 'badge_brave', name: '용감한 탐험가', emoji: '🦁', cost: 150, slot: 'badge', hint: '어려움 3회'),
  const DecoItem(id: 'badge_dawn',  name: '새벽을 사는 자', emoji: '🌅', cost: 80, slot: 'badge', hint: '새벽 경험 3회'),
];