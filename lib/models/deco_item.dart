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

  factory DecoItem.fromJson(Map<String, dynamic> json) => DecoItem(
    id: json['id'] as String,
    name: json['name'] as String,
    emoji: json['emoji'] as String,
    cost: json['cost'] as int,
    slot: json['slot'] as String,
    hint: json['hint'] as String,
    isAiGenerated: (json['isAiGenerated'] as bool?) ?? false,
    dimension: SelfDimension.values.firstWhere(
      (e) => e.name == json['dimension'],
      orElse: () => SelfDimension.internal,
    ),
    imageUrl: json['imageUrl'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'emoji': emoji,
    'cost': cost,
    'slot': slot,
    'hint': hint,
    'isAiGenerated': isAiGenerated,
    'dimension': dimension.name,
    'imageUrl': imageUrl,
  };
}
