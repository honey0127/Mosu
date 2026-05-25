import 'dart:convert';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/community_room.dart';

class CommunityService {
  static const _kRooms = 'community_rooms';
  static final Map<String, CommunityRoom> _rooms = {};

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_kRooms);
    if (json == null) return;
    final Map<String, dynamic> raw = jsonDecode(json);
    raw.forEach((id, val) {
      _rooms[id] = CommunityRoom.fromJson(val as Map<String, dynamic>);
    });
  }

  static Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _kRooms,
      jsonEncode(_rooms.map((k, v) => MapEntry(k, v.toJson()))),
    );
  }

  static String _generateId() {
    return '${DateTime.now().millisecondsSinceEpoch}'
        '${Random().nextInt(9999).toString().padLeft(4, '0')}';
  }

  static String _generateInviteCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rng = Random();
    String code;
    do {
      code = List.generate(6, (_) => chars[rng.nextInt(chars.length)]).join();
    } while (_rooms.values.any((r) => r.inviteCode == code));
    return code;
  }

  /// 방 생성
  static Future<CommunityRoom> createRoom({
    required String creatorId,
    required String name,
    required String description,
  }) async {
    final room = CommunityRoom(
      id: _generateId(),
      name: name.trim(),
      description: description.trim(),
      creatorId: creatorId,
      memberIds: [creatorId],
      inviteCode: _generateInviteCode(),
      createdAt: DateTime.now(),
    );
    _rooms[room.id] = room;
    await _save();
    return room;
  }

  /// 초대코드로 방 참여. 이미 멤버면 기존 방 반환, 없는 코드면 null
  static Future<CommunityRoom?> joinByCode(
      String userId, String code) async {
    final normalizedCode = code.trim().toUpperCase();
    CommunityRoom? found;
    for (final r in _rooms.values) {
      if (r.inviteCode == normalizedCode) {
        found = r;
        break;
      }
    }
    if (found == null) return null;
    if (found.isMember(userId)) return found;
    if (found.memberCount >= CommunityRoom.maxMembers) return null;

    final updated = found.copyWith(
      memberIds: [...found.memberIds, userId],
    );
    _rooms[updated.id] = updated;
    await _save();
    return updated;
  }

  /// 유저가 속한 방 목록 (최신순)
  static List<CommunityRoom> getUserRooms(String userId) {
    return _rooms.values
        .where((r) => r.isMember(userId))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  static CommunityRoom? getRoomById(String id) => _rooms[id];

  /// 방 나가기. 방장이 마지막 멤버면 방 삭제, 아니면 방장 권한 다음 멤버에게 이전
  static Future<void> leaveRoom(String userId, String roomId) async {
    final room = _rooms[roomId];
    if (room == null) return;

    if (room.memberCount == 1) {
      _rooms.remove(roomId);
    } else if (room.isCreator(userId)) {
      final remaining =
          room.memberIds.where((id) => id != userId).toList();
      _rooms[roomId] =
          room.copyWith(memberIds: remaining, creatorId: remaining.first);
    } else {
      final remaining =
          room.memberIds.where((id) => id != userId).toList();
      _rooms[roomId] = room.copyWith(memberIds: remaining);
    }
    await _save();
  }

  /// 방 삭제 (방장 전용)
  static Future<void> deleteRoom(String roomId) async {
    _rooms.remove(roomId);
    await _save();
  }
}
