class CommunityRoom {
  final String id;
  final String name;
  final String description;
  final String creatorId;
  final List<String> memberIds;
  final String inviteCode;
  final DateTime createdAt;

  static const int maxMembers = 30;

  const CommunityRoom({
    required this.id,
    required this.name,
    required this.description,
    required this.creatorId,
    required this.memberIds,
    required this.inviteCode,
    required this.createdAt,
  });

  int get memberCount => memberIds.length;
  bool isCreator(String userId) => creatorId == userId;
  bool isMember(String userId) => memberIds.contains(userId);

  CommunityRoom copyWith({
    String? name,
    String? description,
    String? creatorId,
    List<String>? memberIds,
  }) {
    return CommunityRoom(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      creatorId: creatorId ?? this.creatorId,
      memberIds: memberIds ?? this.memberIds,
      inviteCode: inviteCode,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'creatorId': creatorId,
        'memberIds': memberIds,
        'inviteCode': inviteCode,
        'createdAt': createdAt.toIso8601String(),
      };

  factory CommunityRoom.fromJson(Map<String, dynamic> json) {
    return CommunityRoom(
      id: json['id'] as String,
      name: json['name'] as String,
      description: (json['description'] as String?) ?? '',
      creatorId: json['creatorId'] as String,
      memberIds: List<String>.from(json['memberIds'] as List),
      inviteCode: json['inviteCode'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
