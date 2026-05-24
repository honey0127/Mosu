import 'dart:io';
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
      if (e.code == '23505') {
        throw CommunityException('이미 사용 중인 아이디예요.');
      }
      if (e.code == '23514') {
        throw CommunityException('아이디는 영소문자·숫자·_ 3~20자만 가능해요.');
      }
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

  /// 프로필 사진 파일을 Storage('avatars' 버킷)에 올리고 공개 URL을 반환.
  /// 경로는 `<uid>/avatar_<timestamp>.<ext>` — RLS상 본인 폴더에만 쓸 수 있다.
  /// ⚠️ 대시보드에 public 'avatars' 버킷 + 정책 필요 (0002_avatars_storage.sql 참고).
  Future<String> uploadAvatar(File file) async {
    final uid = _requireUid();
    final ext = file.path.split('.').last.toLowerCase();
    final safeExt = const {'png', 'jpg', 'jpeg', 'webp'}.contains(ext)
        ? ext
        : 'jpg';
    final path =
        '$uid/avatar_${DateTime.now().millisecondsSinceEpoch}.$safeExt';
    try {
      await _db.storage
          .from('avatars')
          .upload(path, file, fileOptions: const FileOptions(upsert: true));
      return _db.storage.from('avatars').getPublicUrl(path);
    } on StorageException catch (e) {
      throw CommunityException('사진 업로드에 실패했어요. (${e.message})');
    }
  }

  // ── 친구 ────────────────────────────────────────────────────────────────────

  /// 친구 요청 보내기.
  /// 반환: 'accepted'(상대 요청이 있어 즉시 성사) 또는 'pending'(요청 전송됨).
  Future<FriendSendResult> sendFriendRequest(String addresseeId) async {
    final status = await _rpcString('send_friend_request', {
      'p_addressee': addresseeId,
    });
    return status == 'accepted'
        ? FriendSendResult.accepted
        : FriendSendResult.pending;
  }

  /// 받은 요청에 응답. action: accept / decline / block.
  Future<void> respondToRequest(int requestId, FriendAction action) =>
      _rpcString('respond_to_friend_request', {
        'p_request_id': requestId,
        'p_action': action.name,
      });

  /// 친구 삭제(양방향).
  Future<void> removeFriend(String otherId) async {
    final me = _requireUid();
    await _db
        .from('friendships')
        .delete()
        .or(
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
    return rows
        .map((r) => FriendRequest.fromMap(r as Map<String, dynamic>))
        .toList();
  }

  // ── 방 ──────────────────────────────────────────────────────────────────────

  /// 방 생성. 생성된 roomId 반환.
  Future<String> createRoom({
    required String name,
    String? goal,
    DateTime? deadline,
    int maxMembers = 50,
  }) async {
    final id = await _db.rpc(
      'create_room',
      params: {
        'p_name': name,
        'p_goal': goal,
        'p_deadline': deadline?.toUtc().toIso8601String(),
        'p_max': maxMembers,
      },
    );
    return id as String;
  }

  /// 방의 영구 초대 코드 조회 (멤버만). 방 생성 시 만들어진 뒤 바뀌지 않는다.
  Future<String> getRoomCode(String roomId) async {
    final code = await _rpc('get_room_code', {'p_room': roomId});
    return code as String;
  }

  /// 코드로 방 가입 "요청" (즉시 입장 X — 방장/관리자 승인 대기).
  Future<JoinRequestResult> requestJoin(String code) async {
    await ensureSignedIn();
    final rows = await _rpc('request_join', {'p_code': code.trim()}) as List;
    if (rows.isEmpty) throw CommunityException('가입 요청에 실패했어요.');
    final m = rows.first as Map<String, dynamic>;
    return JoinRequestResult(
      roomName: m['room_name'] as String,
      status: m['status'] as String,
    );
  }

  /// 방장/관리자: 대기 중인 가입 요청 목록.
  Future<List<JoinRequest>> listJoinRequests(String roomId) async {
    final rows = await _rpc('list_join_requests', {'p_room': roomId}) as List;
    return rows
        .map((r) => JoinRequest.fromMap(r as Map<String, dynamic>))
        .toList();
  }

  /// 방장/관리자: 가입 요청 승인/거절. approve=true → 멤버로 추가.
  Future<void> reviewJoinRequest(int requestId, {required bool approve}) =>
      _rpcString('review_join_request', {
        'p_request_id': requestId,
        'p_action': approve ? 'approve' : 'reject',
      });

  /// 내가 속한 방 목록.
  Future<List<Room>> listMyRooms() async {
    final rows = await _db.rpc('list_my_rooms') as List;
    return rows.map((r) => Room.fromMap(r as Map<String, dynamic>)).toList();
  }

  /// 방 멤버 목록 (RLS: 같은 방 멤버만 조회 가능). FK가 1개라 임베드로 충분.
  Future<List<RoomMember>> roomMembers(String roomId) async {
    final rows = await _db
        .from('room_members')
        .select(
          'user_id, role, joined_at, profiles(handle, display_name, photo_url)',
        )
        .eq('room_id', roomId);
    return (rows as List)
        .map((r) => RoomMember.fromMap(r as Map<String, dynamic>))
        .toList();
  }

  /// 방 나가기. 방장이 나가면 위임 또는 방 삭제가 일어난다.
  /// 반환: 'LEFT'(탈퇴) | 'TRANSFERRED'(방장 위임) | 'DELETED'(방 삭제)
  Future<String> leaveRoom(String roomId) =>
      _rpcString('leave_room', {'p_room_id': roomId});

  /// 멤버 역할 변경 (방장만). role: 'admin' | 'member'
  Future<void> setMemberRole(String roomId, String userId, String role) => _rpc(
    'set_member_role',
    {'p_room': roomId, 'p_user': userId, 'p_role': role},
  );

  // ── 인증 (미션 사진 인증) ─────────────────────────────────────────────────────

  /// 인증 사진을 Storage('verifications' 버킷)에 올리고 공개 URL을 반환.
  Future<String> uploadVerificationPhoto(File file) async {
    final uid = _requireUid();
    final ext = file.path.split('.').last.toLowerCase();
    final safeExt = const {'png', 'jpg', 'jpeg', 'webp'}.contains(ext)
        ? ext
        : 'jpg';
    final path = '$uid/${DateTime.now().millisecondsSinceEpoch}.$safeExt';
    try {
      await _db.storage.from('verifications').upload(path, file);
      return _db.storage.from('verifications').getPublicUrl(path);
    } on StorageException catch (e) {
      throw CommunityException('사진 업로드에 실패했어요. (${e.message})');
    }
  }

  /// 인증 제출 — pending 상태로 생성된다.
  Future<void> submitVerification({
    required String roomId,
    required String photoUrl,
    String? caption,
  }) async {
    try {
      await _db.from('verifications').insert({
        'room_id': roomId,
        'user_id': _requireUid(),
        'photo_url': photoUrl,
        'caption': caption,
      });
    } on PostgrestException catch (e) {
      throw _map(e);
    }
  }

  /// 방의 인증 목록 (최신순). 같은 방 멤버만 조회 가능.
  Future<List<Verification>> roomVerifications(String roomId) async {
    final rows =
        await _rpc('list_room_verifications', {'p_room': roomId}) as List;
    return rows
        .map((r) => Verification.fromMap(r as Map<String, dynamic>))
        .toList();
  }

  /// 인증 승인/거절 (방장·관리자만).
  Future<void> reviewVerification(String id, {required bool approve}) =>
      _rpcString('review_verification', {
        'p_id': id,
        'p_action': approve ? 'approve' : 'reject',
      });

  /// 내 인증 전체 (캘린더용).
  Future<List<MyVerification>> myVerifications() async {
    final rows = await _rpc('list_my_verifications', {}) as List;
    return rows
        .map((r) => MyVerification.fromMap(r as Map<String, dynamic>))
        .toList();
  }

  // ── 채팅 (실시간) ─────────────────────────────────────────────────────────────

  /// 방 메시지 실시간 스트림 (오래된 → 최신 순).
  /// ⚠️ 0004_chat.sql 로 테이블 생성 + realtime publication 등록 필요.
  Stream<List<RoomMessage>> roomMessageStream(String roomId) {
    return _db
        .from('room_messages')
        .stream(primaryKey: ['id'])
        .eq('room_id', roomId)
        .order('created_at')
        .map((rows) => rows.map(RoomMessage.fromMap).toList());
  }

  /// 메시지 전송.
  Future<void> sendMessage(String roomId, String content) async {
    final text = content.trim();
    if (text.isEmpty) return;
    try {
      await _db.from('room_messages').insert({
        'room_id': roomId,
        'user_id': _requireUid(),
        'content': text,
      });
    } on PostgrestException catch (e) {
      throw _map(e);
    }
  }

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

  /// SQL 함수가 raise 한 토큰 / Postgres 에러 코드를 한글 메시지로 변환.
  /// 알 수 없는 경우엔 실제 원인(코드·메시지)을 그대로 노출해 디버깅을 돕는다.
  CommunityException _map(PostgrestException e) {
    // 1) RPC 함수가 raise 한 도메인 토큰
    final token = switch (e.message) {
      'UNAUTHENTICATED' => '로그인이 필요해요.',
      'CODE_NOT_FOUND' || 'CODE_INACTIVE' => '존재하지 않는 코드예요.',
      'CODE_EXPIRED' => '만료된 코드예요.',
      'CODE_EXHAUSTED' || 'ROOM_FULL' => '정원이 찼거나 사용 횟수를 초과했어요.',
      'ALREADY_MEMBER' => '이미 참여 중인 방이에요.',
      'ROOM_NOT_FOUND' => '방을 찾을 수 없어요.',
      'NOT_A_MEMBER' => '이 방의 멤버가 아니에요.',
      'NOT_ROOM_OWNER' => '방장만 초대코드를 만들 수 있어요.',
      'CANNOT_FRIEND_SELF' => '자기 자신은 친구로 추가할 수 없어요.',
      'USER_NOT_FOUND' => '사용자를 찾을 수 없어요.',
      'ALREADY_FRIENDS' => '이미 친구예요.',
      'REQUEST_ALREADY_SENT' => '이미 친구 요청을 보냈어요.',
      'BLOCKED' => '차단된 관계예요.',
      'REQUEST_NOT_FOUND' => '요청을 찾을 수 없어요.',
      'NOT_AUTHORIZED' => '권한이 없어요.',
      'NOT_PENDING' => '이미 처리된 항목이에요.',
      'NOT_FOUND' => '대상을 찾을 수 없어요.',
      'INVALID_ACTION' || 'INVALID_ROLE' => '잘못된 요청이에요.',
      'CANNOT_CHANGE_SELF' => '자기 자신의 역할은 바꿀 수 없어요.',
      _ => null,
    };
    if (token != null) return CommunityException(token);

    // 2) Postgres / PostgREST 시스템 에러 코드
    final byCode = switch (e.code) {
      // FK 위반 — 보통 익명 유저의 프로필 행이 없어서 발생
      '23503' =>
        '프로필이 아직 준비되지 않았어요. 앱을 완전히 종료한 뒤 다시 실행해 주세요. '
            '(문제가 계속되면 DB 마이그레이션 0005를 적용해 주세요.)',
      '23505' => '이미 존재하는 항목이에요.',
      // 함수가 스키마 캐시에 없음 — 마이그레이션 미적용
      'PGRST202' => '서버에 필요한 기능이 설치되지 않았어요. (DB 마이그레이션을 확인해 주세요.)',
      _ => null,
    };
    if (byCode != null) return CommunityException(byCode);

    // 3) 알 수 없는 오류 — 실제 원인을 노출해 진단을 돕는다.
    final detail = [
      if (e.code != null && e.code!.isNotEmpty) e.code,
      e.message,
    ].join(': ');
    return CommunityException('문제가 발생했어요. ($detail)');
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

  const AppProfile({
    required this.id,
    this.handle,
    this.displayName,
    this.photoUrl,
  });

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
  final String? role; // 'owner' | 'member' (내 방 목록일 때)
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

/// 가입 요청 결과 — status 는 보통 'pending'(방장 승인 대기).
class JoinRequestResult {
  final String roomName;
  final String status;
  const JoinRequestResult({required this.roomName, required this.status});
}

/// 방장이 보는 대기 중인 가입 요청 1건.
class JoinRequest {
  final int requestId;
  final String userId;
  final String? handle;
  final String? displayName;
  final String? photoUrl;
  final DateTime? createdAt;

  const JoinRequest({
    required this.requestId,
    required this.userId,
    this.handle,
    this.displayName,
    this.photoUrl,
    this.createdAt,
  });

  String get name => displayName ?? handle ?? '익명 탐험가';

  factory JoinRequest.fromMap(Map<String, dynamic> m) => JoinRequest(
    requestId: m['request_id'] as int,
    userId: m['user_id'] as String,
    handle: m['handle'] as String?,
    displayName: m['display_name'] as String?,
    photoUrl: m['photo_url'] as String?,
    createdAt: _parseDate(m['created_at']),
  );
}

/// 방 안에서 본 인증 1건 (작성자 정보 포함).
class Verification {
  final String id;
  final String userId;
  final String photoUrl;
  final String? caption;
  final String status; // 'pending' | 'approved' | 'rejected'
  final String? reviewedBy;
  final DateTime? reviewedAt;
  final DateTime createdAt;
  final String? handle;
  final String? displayName;

  const Verification({
    required this.id,
    required this.userId,
    required this.photoUrl,
    this.caption,
    required this.status,
    this.reviewedBy,
    this.reviewedAt,
    required this.createdAt,
    this.handle,
    this.displayName,
  });

  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved';
  bool get isRejected => status == 'rejected';
  String get authorName => displayName ?? handle ?? '익명 탐험가';

  factory Verification.fromMap(Map<String, dynamic> m) => Verification(
    id: m['id'] as String,
    userId: m['user_id'] as String,
    photoUrl: m['photo_url'] as String,
    caption: m['caption'] as String?,
    status: m['status'] as String,
    reviewedBy: m['reviewed_by'] as String?,
    reviewedAt: _parseDate(m['reviewed_at']),
    createdAt: _parseDate(m['created_at'])!,
    handle: m['handle'] as String?,
    displayName: m['display_name'] as String?,
  );
}

/// 내 인증 1건 (캘린더용 — 방 이름 포함).
class MyVerification {
  final String id;
  final String roomId;
  final String roomName;
  final String photoUrl;
  final String? caption;
  final String status;
  final DateTime createdAt;
  final DateTime? reviewedAt;

  const MyVerification({
    required this.id,
    required this.roomId,
    required this.roomName,
    required this.photoUrl,
    this.caption,
    required this.status,
    required this.createdAt,
    this.reviewedAt,
  });

  bool get isApproved => status == 'approved';
  bool get isRejected => status == 'rejected';

  factory MyVerification.fromMap(Map<String, dynamic> m) => MyVerification(
    id: m['id'] as String,
    roomId: m['room_id'] as String,
    roomName: m['room_name'] as String,
    photoUrl: m['photo_url'] as String,
    caption: m['caption'] as String?,
    status: m['status'] as String,
    createdAt: _parseDate(m['created_at'])!,
    reviewedAt: _parseDate(m['reviewed_at']),
  );
}

/// 방 채팅 메시지 1건. (작성자 표시는 방 멤버 목록에서 매핑한다)
class RoomMessage {
  final String id;
  final String userId;
  final String content;
  final DateTime createdAt;

  const RoomMessage({
    required this.id,
    required this.userId,
    required this.content,
    required this.createdAt,
  });

  factory RoomMessage.fromMap(Map<String, dynamic> m) => RoomMessage(
    id: m['id'] as String,
    userId: m['user_id'] as String,
    content: m['content'] as String,
    createdAt: _parseDate(m['created_at'])!,
  );
}

DateTime? _parseDate(dynamic v) =>
    v == null ? null : DateTime.tryParse(v.toString())?.toLocal();
