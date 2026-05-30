import 'experience.dart';

class DecoItem {
  final String id;
  final String name;
  final String emoji;
  final int cost;
  final String slot;
  final String hint;
  final bool isAiGenerated;
  final SelfDimension dimension;

  final String? imageUrl;

  const DecoItem({
    required this.id,
    required this.name,
    required this.emoji,
    required this.cost,
    required this.slot,
    required this.hint,
    this.isAiGenerated = false,
    this.dimension = SelfDimension.internal,
    this.imageUrl,
  });
}
