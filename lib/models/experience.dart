import 'package:flutter/material.dart';

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
  final ExperienceCategory category;

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
    required this.category,
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
