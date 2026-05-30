import 'package:flutter/material.dart';

// ─────────────────────────── Animal (캐릭터 종족) ────────────────────────────
/// 캐릭터의 베이스가 되는 귀여운 동물.
/// 동물의숲처럼 의인화시켜서, 선택한 동물 위에 옷·소품이 레이어링됨.
///
/// 각 동물은 실제 외형에 가까운 털색(furColor)과 윤곽 강조색(furAccent),
/// 그리고 체형/비율(bodyScale, torsoAspect, legLengthRatio, headSize)을 가짐.
/// 아바타 위젯은 이 비율들을 사용해 동물마다 다른 실루엣을 그림.
class Animal {
  final String id;
  final String emoji;
  final String name;

  /// 동물의 실제 털색 — 몸통/팔/다리/발이 이 색으로 칠해짐
  final Color furColor;

  /// 윤곽선·그림자에 쓰이는 더 진한 톤
  final Color furAccent;

  /// 배 부분(약간 더 밝은 톤) — null이면 fur과 동일하게 처리
  final Color? bellyColor;

  /// 전체 크기 배율 (1.0 기준, 곰·판다 = 큼, 햄스터·개구리 = 작음)
  final double bodyScale;

  /// 몸통 폭 배율 (1.0 기준, 곰·개구리 = 통통, 토끼·여우 = 슬림)
  final double torsoAspect;

  /// 다리 길이 배율 (1.0 기준, 토끼 = 김, 개구리·햄스터 = 짧음)
  final double legLengthRatio;

  /// 머리 크기 배율 (1.0 기준, 햄스터 = 머리 큼)
  final double headSize;

  const Animal({
    required this.id,
    required this.emoji,
    required this.name,
    required this.furColor,
    required this.furAccent,
    this.bellyColor,
    this.bodyScale = 1.0,
    this.torsoAspect = 1.0,
    this.legLengthRatio = 1.0,
    this.headSize = 1.0,
  });
}

final List<Animal> allAnimals = const [
  // 토끼 — 슬림하고 다리 김. 흰 털, 약간 분홍빛.
  Animal(
    id: 'rabbit', emoji: '🐰', name: '토끼',
    furColor:  Color(0xFFFAF1E8),
    furAccent: Color(0xFFC4A993),
    bellyColor: Color(0xFFFFFAF4),
    bodyScale: 1.00, torsoAspect: 0.88, legLengthRatio: 1.18, headSize: 1.00,
  ),
  // 고양이 — 표준 비율. 옅은 갈색 태비.
  Animal(
    id: 'cat', emoji: '🐱', name: '고양이',
    furColor:  Color(0xFFE2B07C),
    furAccent: Color(0xFF8C5A30),
    bellyColor: Color(0xFFF1D2A8),
    bodyScale: 0.98, torsoAspect: 0.95, legLengthRatio: 1.00, headSize: 1.00,
  ),
  // 강아지 — 약간 통통. 골든 톤.
  Animal(
    id: 'dog', emoji: '🐶', name: '강아지',
    furColor:  Color(0xFFD2A26B),
    furAccent: Color(0xFF7B5128),
    bellyColor: Color(0xFFEBC691),
    bodyScale: 1.00, torsoAspect: 1.02, legLengthRatio: 0.98, headSize: 1.00,
  ),
  // 곰 — 크고 통통. 갈색.
  Animal(
    id: 'bear', emoji: '🐻', name: '곰',
    furColor:  Color(0xFFA6794D),
    furAccent: Color(0xFF5E3D1F),
    bellyColor: Color(0xFFC9A87E),
    bodyScale: 1.12, torsoAspect: 1.20, legLengthRatio: 0.90, headSize: 0.98,
  ),
  // 여우 — 슬림. 주황색.
  Animal(
    id: 'fox', emoji: '🦊', name: '여우',
    furColor:  Color(0xFFD46B3D),
    furAccent: Color(0xFF8A381A),
    bellyColor: Color(0xFFF2D1B6),
    bodyScale: 0.99, torsoAspect: 0.92, legLengthRatio: 1.05, headSize: 1.00,
  ),
  // 판다 — 크고 둥글. 흰색에 회색 강조.
  Animal(
    id: 'panda', emoji: '🐼', name: '판다',
    furColor:  Color(0xFFF0F0F0),
    furAccent: Color(0xFF454545),
    bellyColor: Color(0xFFFFFFFF),
    bodyScale: 1.10, torsoAspect: 1.18, legLengthRatio: 0.92, headSize: 1.02,
  ),
  // 햄스터 — 작고 둥글. 머리가 상대적으로 큼. 골든 탄.
  Animal(
    id: 'hamster', emoji: '🐹', name: '햄스터',
    furColor:  Color(0xFFE0B274),
    furAccent: Color(0xFF9C7138),
    bellyColor: Color(0xFFF1D5A4),
    bodyScale: 0.86, torsoAspect: 1.12, legLengthRatio: 0.80, headSize: 1.14,
  ),
  // 개구리 — 작고 squat (낮고 옆으로 넓음). 다리 짧음. 녹색.
  Animal(
    id: 'frog', emoji: '🐸', name: '개구리',
    furColor:  Color(0xFF8DBB6A),
    furAccent: Color(0xFF466F2E),
    bellyColor: Color(0xFFD8E9B4),
    bodyScale: 0.92, torsoAspect: 1.28, legLengthRatio: 0.72, headSize: 1.05,
  ),
];

Animal? animalById(String? id) {
  if (id == null) return null;
  for (final a in allAnimals) {
    if (a.id == id) return a;
  }
  return null;
}
