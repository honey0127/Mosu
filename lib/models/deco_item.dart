import 'experience.dart';

// ─────────────────────────── DecoItem ────────────────────────────────────────
class DecoItem {
  final String id;
  final String name;
  final String emoji;
  final int cost;
  final String slot;
  final String hint;
  final bool isAiGenerated;
  // external = 캐릭터 코디, internal = 방 소품
  final SelfDimension dimension;

  const DecoItem({
    required this.id,
    required this.name,
    required this.emoji,
    required this.cost,
    required this.slot,
    required this.hint,
    this.isAiGenerated = false,
    this.dimension = SelfDimension.internal,
  });
}
