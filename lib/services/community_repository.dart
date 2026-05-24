import 'package:supabase_flutter/supabase_flutter.dart';

/// 커뮤니티(프로필·친구·방·초대코드) Supabase 접근 계층.
///
/// 모든 쓰기 로직은 0001_community.sql 의 RPC/RLS 가 검증한다.
/// 이 클래스는 호출 + 결과 매핑 + 에러 한글화만 담당한다.
///
/// 사용 예)
///   final repo = CommunityRepository();
///   final join = await repo.redeemInviteCode('MOS7K2');
class CommunityRepository {
  CommunityRepository({SupabaseClient? client})
      : _db = client ?? Supabase.instance.client;

  final SupabaseClient _db;

  String _requireUid() {
    final uid = _db.auth.currentUser?.id;
    if (uid == null) throw CommunityException('로그인이 필요해요.');
    return uid;
  }

  /// 현재 로그인된 Supabase 유저 ID (익명 포함). 없으면 null.
  String? get currentUserId => _db.auth.currentUser?.id;

  /// Supabase 세션 보장 — 없으면 익명 로그인.
  /// ⚠️ 대시보드 > Authentication > Sign In/Up > Anonymous sign-ins 활성화 필요.
  Future<void> ensureSignedIn() async {
    if (_db.auth.currentUser != null) return;
    try {
      await _db.auth.signInAnonymously();
    } on AuthException catch (e) {
      throw CommunityException(
        '익명 로그인에 실패했어요. Supabase 대시보드에서 '
        'Anonymous sign-ins를 켰는지 확인해 주세요. (${e.message})',
      );
    }
  }

  // ── 프로필 ──────────────────────────────────────────────────────────────────

  /// 핸들(아이디)로 사용자 검색. 없으면 null.
  Future<AppProfile?> findByHandle(String handle) async {
    final row = await _db
        .from('profiles')
        .select()
        .eq('handle', handle.trim().toLowerCase())
        .maybeSingle();
    return row == null ? null : AppProfile.fromMap(row);
  }

  /// 내 핸들 설정/변경. 이미 사용 중이면 CommunityException.
  Future<void> setHandle(String handle) async {
    try {
      await _db
          .from('profiles')
          .update({'handle': handle.trim().toLowerCase()})
          .eq('id', _requireUid());
    } on PostgrestException catch (e) {
      if (e.code == '23505') throw CommunityException('이미 사용 중인 아이디예요.');
      if (e.code == '23514') throw CommunityException('아이디는 영소문자·숫자·_ 3~20자만 가능해요.');
      throw _map(e);
    }
  }

  /// 내 표시 이름/사진 갱신.
  Future<void> updateProfile({String? displayName, String? photoUrl}) async {
    final patch = <String, dynamic>{
      'display_name': ?displayName,
      'photo_url': ?photoUrl,
    };
    if (patch.isEmpty) return;
    await _db.from('profiles').update(patch).eq('id', _requireUid());
  }

  // ── 친구 ────────────────────────────────────────────────────────────────────

  /// 친구 요청 보내기.
  /// 반환: 'accepted'(상대 요청이 있어 즉시 성사) 또는 'pending'(요청 전송됨).
  Future<FriendSendResult> sendFriendRequest(String addresseeId) async {
    final status = await _rpcString('send_friend_request', {'p_addressee': addresseeId});
    return status == 'accepted' ? FriendSendResult.accepted : FriendSendResult.pending;
  }

  /// 받은 요청에 응답. action: accept / decline / block.
  Future<void> respondToRequest(int requestId, FriendAction action) =>
      _rpcString('respond_to_friend_request',
          {'p_request_id': requestId, 'p_action': action.name});

  /// 친구 삭제(양방향).
  Future<void> removeFriend(String otherId) async {
    final me = _requireUid();
    await _db.from('friendships').delete().or(
          'and(requester_id.eq.$me,addressee_id.eq.$otherId),'
          'and(requester_id.eq.$otherId,addressee_id.eq.$me)',
        );
  }

  /// 내 친구 목록.
  Future<List<Friend>> listFriends() async {
    final rows = await _db.rpc('list_friends') as List;
    return rows.map((r) => Friend.fromMap(r as Map<String, dynamic>)).toList();
  }

  /// 나에게 들어온 친구 요청 목록.
  Future<List<FriendRequest>> listIncomingRequests() async {
    final rows = await _db.rpc('list_incoming_requests') as List;
    return rows.map((r) => FriendRequest.fromMap(r as Map<String, dynamic>)).toList();
  }

  // ── 방 ──────────────────────────────────────────────────────────────────────

  /// 방 생성. 생성된 roomId 반환.
  Future<String> createRoom({
    required String name,
    String? goal,
    DateTime? deadline,
    int maxMembers = 50,
  }) async {
    final id = await _db.rpc('create_room', params: {
      'p_name': name,
      'p_goal': goal,
      'p_deadline': deadline?.toUtc().toIso8601String(),
      'p_max': maxMembers,
    });
    return id as String;
  }

  /// 방장이 초대코드 생성. 생성된 6자리 코드 반환.
  Future<String> createInviteCode(String roomId, {int? maxUses, int? ttlHours}) async {
    final code = await _rpc('create_invite_code', {
      'p_room_id': roomId,
      'p_max_uses': maxUses,
      'p_ttl_hours': ttlHours,
    });
    return code as String;
  }

  /// ⭐ 코드로 방 입장 (서버에서 원자적 검증·정원 체크).
  Future<JoinResult> redeemInviteCode(String code) async {
    final rows = await _rpc('redeem_invite_code', {'p_code': code}) as List;
    if (rows.isEmpty) throw CommunityException('방에 입장하지 못했어요.');
    return JoinResult.fromMap(rows.first as Map<String, dynamic>);
  }

  /// 내가 속한 방 목록.
  Future<List<Room>> listMyRooms() async {
    final rows = await _db.rpc('list_my_rooms') as List;
    return rows.map((r) => Room.fromMap(r as Map<String, dynamic>)).toList();
  }

  /// 방 멤버 목록 (RLS: 같은 방 멤버만 조회 가능). FK가 1개라 임베드로 충분.
  Future<List<RoomMember>> roomMembers(String roomId) async {
    final rows = await _db
        .from('room_members')
        .select('user_id, role, joined_at, profiles(handle, display_name, photo_url)')
        .eq('room_id', roomId);
    return (rows as List).map((r) => RoomMember.fromMap(r as Map<String, dynamic>)).toList();
  }

  /// 방 나가기. 방장이 나가면 위임 또는 방 삭제가 일어난다.
  /// 반환: 'LEFT'(탈퇴) | 'TRANSFERRED'(방장 위임) | 'DELETED'(방 삭제)
  Future<String> leaveRoom(String roomId) =>
      _rpcString('leave_room', {'p_room_id': roomId});

  // ── 내부 헬퍼 ────────────────────────────────────────────────────────────────

  /// RPC 호출 + 에러 한글화.
  Future<dynamic> _rpc(String fn, Map<String, dynamic> params) async {
    try {
      return await _db.rpc(fn, params: params);
    } on PostgrestException catch (e) {
      throw _map(e);
    }
  }

  Future<String> _rpcString(String fn, Map<String, dynamic> params) async =>
      (await _rpc(fn, params)).toString();

  /// SQL 함수가 raise 한 토큰을 사용자 친화적 한글 메시지로 변환.
  CommunityException _map(PostgrestException e) {
    final msg = switch (e.message) {
      'UNAUTHENTICATED'      => '로그인이 필요해요.',
      'CODE_NOT_FOUND' || 'CODE_INACTIVE' => '존재하지 않는 코드예요.',
      'CODE_EXPIRED'         => '만료된 코드예요.',
      'CODE_EXHAUSTED' || 'ROOM_FULL'     => '정원이 찼거나 사용 횟수를 초과했어요.',
      'ALREADY_MEMBER'       => '이미 참여 중인 방이에요.',
      'ROOM_NOT_FOUND'       => '방을 찾을 수 없어요.',
      'NOT_A_MEMBER'         => '이 방의 멤버가 아니에요.',
      'NOT_ROOM_OWNER'       => '방장만 초대코드를 만들 수 있어요.',
      'CANNOT_FRIEND_SELF'   => '자기 자신은 친구로 추가할 수 없어요.',
      'USER_NOT_FOUND'       => '사용자를 찾을 수 없어요.',
      'ALREADY_FRIENDS'      => '이미 친구예요.',
      'REQUEST_ALREADY_SENT' => '이미 친구 요청을 보냈어요.',
      'BLOCKED'              => '차단된 관계예요.',
      'REQUEST_NOT_FOUND'    => '요청을 찾을 수 없어요.',
      'NOT_AUTHORIZED'       => '권한이 없어요.',
      'NOT_PENDING'          => '이미 처리된 요청이에요.',
      _                      => '잠시 후 다시 시도해 주세요.',
    };
    return CommunityException(msg);
  }
}

/// UI에서 바로 보여줄 수 있는 한글 메시지를 담은 예외.
class CommunityException implements Exception {
  final String message;
  CommunityException(this.message);
  @override
  String toString() => message;
}

// ─────────────────────────── 모델 ────────────────────────────────────────────

enum FriendAction { accept, decline, block }

enum FriendSendResult { pending, accepted }

class AppProfile {
  final String id;
  final String? handle;
  final String? displayName;
  final String? photoUrl;

  const AppProfile({required this.id, this.handle, this.displayName, this.photoUrl});

  factory AppProfile.fromMap(Map<String, dynamic> m) => AppProfile(
        id: m['id'] as String,
        handle: m['handle'] as String?,
        displayName: m['display_name'] as String?,
        photoUrl: m['photo_url'] as String?,
      );
}

class Friend {
  final int friendshipId;
  final String friendId;
  final String? handle;
  final String? displayName;
  final String? photoUrl;
  final DateTime? since;

  const Friend({
    required this.friendshipId,
    required this.friendId,
    this.handle,
    this.displayName,
    this.photoUrl,
    this.since,
  });

  factory Friend.fromMap(Map<String, dynamic> m) => Friend(
        friendshipId: m['friendship_id'] as int,
        friendId: m['friend_id'] as String,
        handle: m['handle'] as String?,
        displayName: m['display_name'] as String?,
        photoUrl: m['photo_url'] as String?,
        since: _parseDate(m['since']),
      );
}

class FriendRequest {
  final int friendshipId;
  final String requesterId;
  final String? handle;
  final String? displayName;
  final String? photoUrl;
  final DateTime? createdAt;

  const FriendRequest({
    required this.friendshipId,
    required this.requesterId,
    this.handle,
    this.displayName,
    this.photoUrl,
    this.createdAt,
  });

  factory FriendRequest.fromMap(Map<String, dynamic> m) => FriendRequest(
        friendshipId: m['friendship_id'] as int,
        requesterId: m['requester_id'] as String,
        handle: m['handle'] as String?,
        displayName: m['display_name'] as String?,
        photoUrl: m['photo_url'] as String?,
        createdAt: _parseDate(m['created_at']),
      );
}

class Room {
  final String id;
  final String name;
  final String? goalDescription;
  final DateTime? deadline;
  final String ownerId;
  final int memberCount;
  final int maxMembers;
  final String? role;       // 'owner' | 'member' (내 방 목록일 때)
  final DateTime? joinedAt;

  const Room({
    required this.id,
    required this.name,
    this.goalDescription,
    this.deadline,
    required this.ownerId,
    required this.memberCount,
    required this.maxMembers,
    this.role,
    this.joinedAt,
  });

  bool get isFull => memberCount >= maxMembers;

  factory Room.fromMap(Map<String, dynamic> m) => Room(
        id: m['id'] as String,
        name: m['name'] as String,
        goalDescription: m['goal_description'] as String?,
        deadline: _parseDate(m['deadline']),
        ownerId: m['owner_id'] as String,
        memberCount: m['member_count'] as int,
        maxMembers: m['max_members'] as int,
        role: m['role'] as String?,
        joinedAt: _parseDate(m['joined_at']),
      );
}

class RoomMember {
  final String userId;
  final String role;
  final DateTime? joinedAt;
  final String? handle;
  final String? displayName;
  final String? photoUrl;

  const RoomMember({
    required this.userId,
    required this.role,
    this.joinedAt,
    this.handle,
    this.displayName,
    this.photoUrl,
  });

  factory RoomMember.fromMap(Map<String, dynamic> m) {
    final p = (m['profiles'] as Map<String, dynamic>?) ?? const {};
    return RoomMember(
      userId: m['user_id'] as String,
      role: m['role'] as String,
      joinedAt: _parseDate(m['joined_at']),
      handle: p['handle'] as String?,
      displayName: p['display_name'] as String?,
      photoUrl: p['photo_url'] as String?,
    );
  }
}

class JoinResult {
  final String roomId;
  final String roomName;
  const JoinResult({required this.roomId, required this.roomName});

  factory JoinResult.fromMap(Map<String, dynamic> m) => JoinResult(
        roomId: m['room_id'] as String,
        roomName: m['room_name'] as String,
      );
}

DateTime? _parseDate(dynamic v) =>
    v == null ? null : DateTime.tryParse(v.toString())?.toLocal();
