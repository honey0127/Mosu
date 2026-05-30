import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/app_colors.dart';
import '../../services/community_repository.dart';
import 'room_chat_screen.dart';

/// 방 상세 — 멤버 목록 + 사진 인증 + (방장/관리자) 승인 + (방장) 초대코드/역할 관리
class RoomDetailScreen extends StatefulWidget {
  final String roomId;
  final String roomName;
  const RoomDetailScreen({
    super.key,
    required this.roomId,
    required this.roomName,
  });

  @override
  State<RoomDetailScreen> createState() => _RoomDetailScreenState();
}

typedef _RoomData = ({
  List<RoomMember> members,
  List<Verification> verifs,
  List<JoinRequest> requests,
});

class _RoomDetailScreenState extends State<RoomDetailScreen> {
  final _repo = CommunityRepository();
  final _picker = ImagePicker();
  late Future<_RoomData> _dataFuture;

  @override
  void initState() {
    super.initState();
    _dataFuture = _load();
  }

  Future<_RoomData> _load() async {
    final members = await _repo.roomMembers(widget.roomId);
    final myId = _repo.currentUserId;
    final myRole = members
        .where((m) => m.userId == myId)
        .map((m) => m.role)
        .firstOrNull;
    final iAmAdmin = myRole == 'owner' || myRole == 'admin';

    List<Verification> verifs;
    try {
      verifs = await _repo.roomVerifications(widget.roomId);
    } catch (_) {
      // 인증 마이그레이션(0003) 적용 전이면 멤버만이라도 보이게 비워둔다.
      verifs = const [];
    }

    List<JoinRequest> requests = const [];
    if (iAmAdmin) {
      try {
        requests = await _repo.listJoinRequests(widget.roomId);
      } catch (_) {
        // 가입요청 마이그레이션(0006) 적용 전이면 무시.
        requests = const [];
      }
    }
    return (members: members, verifs: verifs, requests: requests);
  }

  void _reload() => setState(() {
        _dataFuture = _load();
      });

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  // ── 초대 코드 보기 (방 생성 시 만들어진 영구 코드) ────────────────────────────
  Future<void> _showInviteCode() async {
    try {
      final code = await _repo.getRoomCode(widget.roomId);
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (_) => _InviteCodeDialog(code: code),
      );
    } on CommunityException catch (e) {
      _snack(e.message);
    }
  }

  // ── 가입 요청 승인/거절 (방장·관리자) ─────────────────────────────────────────
  Future<void> _reviewJoin(int requestId, bool approve) async {
    try {
      await _repo.reviewJoinRequest(requestId, approve: approve);
      _snack(approve ? '가입을 승인했어요.' : '가입 요청을 거절했어요.');
      _reload();
    } on CommunityException catch (e) {
      _snack(e.message);
    }
  }

  // ── 사진 인증 제출 ───────────────────────────────────────────────────────────
  Future<void> _submitVerification() async {
    final source = await _pickSource();
    if (source == null) return;

    final XFile? picked;
    try {
      picked = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1600,
      );
    } catch (_) {
      _snack(
        source == ImageSource.camera ? '카메라 권한을 허용해 주세요' : '사진 접근 권한을 허용해 주세요',
      );
      return;
    }
    if (picked == null) return;
    final imgPath = picked.path;

    if (!mounted) return;
    final caption = await showDialog<String>(
      context: context,
      builder: (_) => _CaptionDialog(imagePath: imgPath),
    );
    if (caption == null) return; // 취소

    // 파일 경로가 아닌 바이트로 읽어 둔다(안드로이드 캐시 경로 업로드 멈춤 회피).
    final Uint8List bytes;
    try {
      bytes = await picked.readAsBytes();
    } catch (_) {
      _snack('사진을 읽지 못했어요. 다시 시도해 주세요.');
      return;
    }
    final ext = imgPath.split('.').last.toLowerCase();
    debugPrint('[verify] bytes read: ${bytes.length} bytes, ext=$ext');

    if (!mounted) return;

    var dialogOpen = true;
    void closeDialog() {
      if (dialogOpen && mounted) {
        dialogOpen = false;
        Navigator.of(context, rootNavigator: true).pop();
      }
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => PopScope(
        canPop: false,
        child: AlertDialog(
          content: const Row(
            children: [
              SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              ),
              SizedBox(width: 16),
              Expanded(child: Text('인증 사진 업로드 중…')),
            ],
          ),
          actions: [
            TextButton(
              onPressed: closeDialog,
              child: const Text('취소'),
            ),
          ],
        ),
      ),
    );

    try {
      debugPrint('[verify] upload start…');
      final url = await _repo
          .uploadVerificationPhoto(bytes, fileExt: ext)
          .timeout(const Duration(seconds: 20));
      debugPrint('[verify] upload done: $url');
      await _repo
          .submitVerification(
            roomId: widget.roomId,
            photoUrl: url,
            caption: caption.trim().isEmpty ? null : caption.trim(),
          )
          .timeout(const Duration(seconds: 12));
      debugPrint('[verify] submit done');
      closeDialog();
      if (!mounted) return;
      _snack('인증을 제출했어요! 방장·관리자 확인을 기다려요.');
      _reload();
    } on TimeoutException {
      debugPrint('[verify] TIMEOUT');
      closeDialog();
      _snack('업로드가 너무 오래 걸려요. 네트워크를 확인하고 다시 시도해 주세요.');
    } on CommunityException catch (e) {
      debugPrint('[verify] CommunityException: ${e.message}');
      closeDialog();
      _snack(e.message);
    } catch (e) {
      debugPrint('[verify] ERROR: $e');
      closeDialog();
      _snack('인증 제출에 실패했어요. ($e)');
    }
  }

  Future<ImageSource?> _pickSource() {
    return showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(
                Icons.camera_alt_outlined,
                color: AppColors.primary,
              ),
              title: const Text('카메라로 촬영'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(
                Icons.photo_library_outlined,
                color: AppColors.primary,
              ),
              title: const Text('갤러리에서 선택'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // ── 승인/거절 ────────────────────────────────────────────────────────────────
  Future<void> _review(String id, bool approve) async {
    String? reason;
    if (!approve) {
      reason = await showDialog<String>(
        context: context,
        builder: (_) => const _RejectReasonDialog(),
      );
      if (reason == null) return; // 취소
    }
    try {
      await _repo.reviewVerification(id, approve: approve, reason: reason);
      _snack(approve ? '인증을 승인했어요.' : '인증을 거절했어요.');
      _reload();
    } on CommunityException catch (e) {
      _snack(e.message);
    }
  }

  // ── 관리자 임명/해제 (방장만) ────────────────────────────────────────────────
  Future<void> _changeRole(String userId, String role) async {
    try {
      await _repo.setMemberRole(widget.roomId, userId, role);
      _snack(role == 'admin' ? '관리자로 임명했어요.' : '관리자에서 해제했어요.');
      _reload();
    } on CommunityException catch (e) {
      _snack(e.message);
    }
  }

  // ── 방 나가기 (방장이면 위임/삭제) ───────────────────────────────────────────
  Future<void> _leave() async {
    List<RoomMember> members = const [];
    try {
      members = (await _dataFuture).members;
    } catch (_) {}
    final myId = _repo.currentUserId;
    final iAmOwner = members.any((m) => m.userId == myId && m.role == 'owner');
    final otherCount = members.where((m) => m.userId != myId).length;

    final warning = iAmOwner
        ? (otherCount == 0
              ? '당신이 마지막 멤버예요. 나가면 이 방은 삭제돼요.'
              : '방장이 나가면 가장 먼저 들어온 멤버에게 방장이 위임돼요.')
        : '정말 이 방에서 나갈까요?';

    if (!mounted) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('방 나가기'),
        content: Text(warning),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.dareAccent,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('나가기'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      final result = await _repo.leaveRoom(widget.roomId);
      final msg = switch (result) {
        'DELETED' => '방에서 나왔고, 방이 삭제됐어요.',
        'TRANSFERRED' => '방에서 나왔고, 방장을 위임했어요.',
        _ => '방에서 나왔어요.',
      };
      _snack(msg);
      if (mounted) Navigator.pop(context);
    } on CommunityException catch (e) {
      _snack(e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final myId = _repo.currentUserId;
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLow,
      appBar: AppBar(
        title: Text(widget.roomName),
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            tooltip: '채팅',
            icon: const Icon(Icons.chat_bubble_outline, size: 20),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => RoomChatScreen(
                  roomId: widget.roomId,
                  roomName: widget.roomName,
                ),
              ),
            ),
          ),
          IconButton(
            tooltip: '방 나가기',
            icon: const Icon(Icons.logout, size: 20),
            onPressed: _leave,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => _reload(),
        child: FutureBuilder<_RoomData>(
          future: _dataFuture,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snap.hasError) {
              return ListView(
                children: [
                  const SizedBox(height: 80),
                  Center(
                    child: Text(
                      snap.error.toString(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ),
                ],
              );
            }
            final members = snap.data?.members ?? const [];
            final verifs = snap.data?.verifs ?? const [];
            final requests = snap.data?.requests ?? const <JoinRequest>[];
            final myRole = members
                .where((m) => m.userId == myId)
                .map((m) => m.role)
                .firstOrNull;
            final iAmOwner = myRole == 'owner';
            final iAmAdmin = myRole == 'owner' || myRole == 'admin';

            // 멤버별 최근(승인된 것 우선) 인증 = 그 사람의 "활동"
            Verification? latestFor(String uid) {
              Verification? best;
              for (final v in verifs) {
                if (v.userId != uid) continue;
                if (best == null || v.createdAt.isAfter(best.createdAt)) {
                  best = v;
                }
              }
              return best;
            }

            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              children: [
                // ── 멤버 활동 액자 (방 제목 바로 아래) ────────────────────
                if (members.isNotEmpty) ...[
                  _ActivityGrid(
                    members: members,
                    latestOf: latestFor,
                    myId: myId,
                  ),
                  const SizedBox(height: 22),
                ],
                if (iAmOwner) ...[
                  FilledButton.icon(
                    onPressed: _showInviteCode,
                    icon: const Icon(Icons.qr_code_2, size: 18),
                    label: const Text('초대 코드 보기'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      minimumSize: const Size.fromHeight(48),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
                // 사진 인증하기 (모든 멤버)
                FilledButton.icon(
                  onPressed: _submitVerification,
                  icon: const Icon(Icons.camera_alt_rounded, size: 18),
                  label: const Text('사진으로 인증하기'),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    minimumSize: const Size.fromHeight(48),
                    elevation: 0,
                  ),
                ),
                const SizedBox(height: 22),

                // ── 가입 요청 (방장·관리자만) ─────────────────────────────
                if (iAmAdmin) ...[
                  _JoinRequestsSection(
                    requests: requests,
                    onApprove: (id) => _reviewJoin(id, true),
                    onReject: (id) => _reviewJoin(id, false),
                  ),
                  const SizedBox(height: 24),
                ],

                // ── 인증 현황 ───────────────────────────────────────────
                Row(
                  children: [
                    const Text(
                      '인증 현황',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${verifs.length}',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                if (verifs.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Center(
                      child: Text(
                        '아직 인증이 없어요.\n첫 인증을 올려보세요!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade500,
                          height: 1.5,
                        ),
                      ),
                    ),
                  )
                else
                  ...verifs.map(
                    (v) => _VerificationCard(
                      v: v,
                      canReview: iAmAdmin,
                      onReview: (approve) => _review(v.id, approve),
                    ),
                  ),
                const SizedBox(height: 24),

                // ── 멤버 ───────────────────────────────────────────────
                Text(
                  '멤버 ${members.length}명',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                ...members.map(
                  (m) => _MemberTile(
                    member: m,
                    isMe: m.userId == myId,
                    canManage:
                        iAmOwner && m.role != 'owner' && m.userId != myId,
                    onSetRole: (role) => _changeRole(m.userId, role),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ─────────────────────────── 인증 카드 ───────────────────────────────────────
class _VerificationCard extends StatelessWidget {
  final Verification v;
  final bool canReview;
  final void Function(bool approve) onReview;
  const _VerificationCard({
    required this.v,
    required this.canReview,
    required this.onReview,
  });

  String _fmtDate(DateTime d) => '${d.month}월 ${d.day}일';

  void _openDetail(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        final hasCaption = v.caption != null && v.caption!.isNotEmpty;
        final showActions = canReview && v.isPending;
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 헤더: 작성자 + 상태
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 12, 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        v.authorName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    _StatusBadge(status: v.status),
                  ],
                ),
              ),
              // 사진
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AspectRatio(
                        aspectRatio: 1,
                        child: Image.network(
                          v.photoUrl,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, progress) =>
                              progress == null
                              ? child
                              : Container(
                                  color: Colors.grey.shade100,
                                  child: const Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                ),
                          errorBuilder: (_, _, _) => Container(
                            color: Colors.grey.shade100,
                            child: Icon(
                              Icons.broken_image_outlined,
                              color: Colors.grey.shade400,
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (hasCaption) ...[
                              Text(
                                v.caption!,
                                style: const TextStyle(fontSize: 13),
                              ),
                              const SizedBox(height: 6),
                            ],
                            Text(
                              _fmtDate(v.createdAt),
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade500,
                              ),
                            ),
                            if (v.isRejected &&
                                v.rejectReason != null &&
                                v.rejectReason!.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 7,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '거절 사유: ${v.rejectReason}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.red.shade700,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (showActions)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.of(sheetContext).pop();
                            onReview(false);
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red.shade400,
                            side: BorderSide(color: Colors.red.shade200),
                          ),
                          child: const Text('거절'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: FilledButton(
                          onPressed: () {
                            Navigator.of(sheetContext).pop();
                            onReview(true);
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.primary,
                          ),
                          child: const Text('승인'),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _openDetail(context),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  v.authorName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _StatusBadge(status: v.status),
              const SizedBox(width: 6),
              Icon(
                Icons.chevron_right,
                size: 20,
                color: Colors.grey.shade400,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (String label, Color fg, Color bg) = switch (status) {
      'approved' => ('승인됨', Color(0xFF1D9E75), Color(0xFFE8F8F2)),
      'rejected' => ('거절됨', Color(0xFFD85A30), Color(0xFFFDECE6)),
      _ => ('대기중', Color(0xFFBA7517), Color(0xFFFFF3E0)),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: fg),
      ),
    );
  }
}

// ─────────────────────────── 멤버 타일 ───────────────────────────────────────
// ─────────────────────────── 멤버 활동 액자 그리드 ───────────────────────────
class _ActivityGrid extends StatelessWidget {
  final List<RoomMember> members;
  final Verification? Function(String userId) latestOf;
  final String? myId;
  const _ActivityGrid({
    required this.members,
    required this.latestOf,
    required this.myId,
  });

  @override
  Widget build(BuildContext context) {
    final count = members.length;
    // 인원 수에 맞춰 칸(열) 조절: 1명 = 1열, 그 외 = 2열
    final cols = count <= 1 ? 1 : 2;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      itemCount: count,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: cols,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1,
      ),
      itemBuilder: (_, i) {
        final m = members[i];
        return _ActivityCell(
          member: m,
          latest: latestOf(m.userId),
          isMe: m.userId == myId,
        );
      },
    );
  }
}

class _ActivityCell extends StatelessWidget {
  final RoomMember member;
  final Verification? latest;
  final bool isMe;
  const _ActivityCell({
    required this.member,
    required this.latest,
    required this.isMe,
  });

  String get _name => member.displayName ?? member.handle ?? '익명 탐험가';
  String get _label => isMe ? '$_name (나)' : _name;

  String _fmtTime(DateTime d) {
    final h = d.hour.toString().padLeft(2, '0');
    final mi = d.minute.toString().padLeft(2, '0');
    return '$h:$mi';
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: latest != null ? _photoCell(latest!) : _emptyCell(),
    );
  }

  Widget _photoCell(Verification v) {
    final hasCaption = v.caption != null && v.caption!.isNotEmpty;
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.network(
          v.photoUrl,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, progress) => progress == null
              ? child
              : Container(color: AppColors.primaryExtraLight),
          errorBuilder: (_, _, _) =>
              Container(color: AppColors.primaryExtraLight),
        ),
        // 하단 가독성용 그라데이션
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.transparent, Colors.black54],
              stops: [0.45, 1.0],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(9),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _miniAvatar(onPhoto: true),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      _label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              if (hasCaption)
                Text(
                  v.caption!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              const SizedBox(height: 2),
              Text(
                _fmtTime(v.createdAt),
                style: const TextStyle(color: Colors.white70, fontSize: 11),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _emptyCell() {
    return Container(
      color: AppColors.primaryExtraLight,
      padding: const EdgeInsets.all(9),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _miniAvatar(onPhoto: false),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  _label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            '아직 활동이 없어요',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _miniAvatar({required bool onPhoto}) {
    final photo = member.photoUrl;
    if (photo != null && photo.startsWith('http')) {
      return CircleAvatar(
        radius: 12,
        backgroundColor: AppColors.white,
        backgroundImage: NetworkImage(photo),
      );
    }
    if (photo != null && photo.startsWith('animal:')) {
      return CircleAvatar(
        radius: 12,
        backgroundColor: AppColors.white,
        child: Text(photo.substring(7), style: const TextStyle(fontSize: 13)),
      );
    }
    return CircleAvatar(
      radius: 12,
      backgroundColor: AppColors.white,
      child: Text(
        _name.isNotEmpty ? _name.substring(0, 1) : '?',
        style: const TextStyle(
          color: AppColors.primary,
          fontWeight: FontWeight.w700,
          fontSize: 11,
        ),
      ),
    );
  }
}

class _MemberTile extends StatelessWidget {
  final RoomMember member;
  final bool isMe;
  final bool canManage;
  final void Function(String role)? onSetRole;
  const _MemberTile({
    required this.member,
    required this.isMe,
    this.canManage = false,
    this.onSetRole,
  });

  @override
  Widget build(BuildContext context) {
    final name = member.displayName ?? member.handle ?? '익명 탐험가';
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: _avatar(name),
      title: Text(isMe ? '$name (나)' : name),
      trailing: _trailing(),
    );
  }

  Widget? _trailing() {
    if (member.role == 'owner') {
      return const Text(
        '방장',
        style: TextStyle(
          color: AppColors.primary,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      );
    }
    final badge = member.role == 'admin'
        ? const Text(
            '관리자',
            style: TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          )
        : null;

    if (!canManage) return badge;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ?badge,
        PopupMenuButton<String>(
          icon: Icon(Icons.more_vert, color: Colors.grey.shade500, size: 20),
          onSelected: (v) => onSetRole?.call(v),
          itemBuilder: (_) => [
            if (member.role != 'admin')
              const PopupMenuItem(value: 'admin', child: Text('관리자로 임명')),
            if (member.role == 'admin')
              const PopupMenuItem(value: 'member', child: Text('관리자 해제')),
          ],
        ),
      ],
    );
  }

  /// photo_url 값에 따라 아바타를 그린다.
  ///   http(s)…   → 업로드된 사진
  ///   animal:🐰  → 캐릭터 이모지
  ///   그 외/없음 → 이름 첫 글자
  Widget _avatar(String name) {
    final photo = member.photoUrl;
    if (photo != null && photo.startsWith('http')) {
      return CircleAvatar(
        backgroundColor: AppColors.fitBg,
        backgroundImage: NetworkImage(photo),
      );
    }
    if (photo != null && photo.startsWith('animal:')) {
      return CircleAvatar(
        backgroundColor: AppColors.fitBg,
        child: Text(photo.substring(7), style: const TextStyle(fontSize: 20)),
      );
    }
    return CircleAvatar(
      backgroundColor: AppColors.fitBg,
      child: Text(
        name.isNotEmpty ? name.substring(0, 1) : '?',
        style: const TextStyle(
          color: AppColors.primary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ─────────────────────────── 캡션 입력 다이얼로그 ────────────────────────────
class _CaptionDialog extends StatefulWidget {
  final String imagePath;
  const _CaptionDialog({required this.imagePath});

  @override
  State<_CaptionDialog> createState() => _CaptionDialogState();
}

class _CaptionDialogState extends State<_CaptionDialog> {
  final _caption = TextEditingController();

  @override
  void dispose() {
    _caption.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      scrollable: true,
      title: const Text('인증 올리기'),
      insetPadding: const EdgeInsets.all(24),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(
                File(widget.imagePath),
                height: 140,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _caption,
              maxLength: 100,
              decoration: const InputDecoration(
                hintText: '한마디 남기기 (선택)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('취소'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _caption.text),
          child: const Text('제출'),
        ),
      ],
    );
  }
}

// ─────────────────────────── 거절 사유 다이얼로그 ─────────────────────────────
class _RejectReasonDialog extends StatefulWidget {
  const _RejectReasonDialog();

  @override
  State<_RejectReasonDialog> createState() => _RejectReasonDialogState();
}

class _RejectReasonDialogState extends State<_RejectReasonDialog> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      scrollable: true,
      title: const Text('거절 사유'),
      insetPadding: const EdgeInsets.all(24),
      content: SizedBox(
        width: double.maxFinite,
        child: TextField(
          controller: _ctrl,
          autofocus: true,
          maxLength: 100,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: '사유를 입력하세요 (선택)',
            border: OutlineInputBorder(),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('취소'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: Colors.red.shade400),
          onPressed: () => Navigator.pop(context, _ctrl.text),
          child: const Text('거절'),
        ),
      ],
    );
  }
}

// ─────────────────────────── 가입 요청 섹션 ──────────────────────────────────
class _JoinRequestsSection extends StatelessWidget {
  final List<JoinRequest> requests;
  final void Function(int requestId) onApprove;
  final void Function(int requestId) onReject;
  const _JoinRequestsSection({
    required this.requests,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              '가입 요청',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
            ),
            const SizedBox(width: 6),
            Text(
              '${requests.length}',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (requests.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              '대기 중인 가입 요청이 없어요',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
            ),
          )
        else
          ...requests.map(
            (r) => _JoinRequestTile(
              req: r,
              onApprove: () => onApprove(r.requestId),
              onReject: () => onReject(r.requestId),
            ),
          ),
      ],
    );
  }
}

class _JoinRequestTile extends StatelessWidget {
  final JoinRequest req;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  const _JoinRequestTile({
    required this.req,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          _avatar(),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              req.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton(
            onPressed: onReject,
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red.shade400,
              side: BorderSide(color: Colors.red.shade200),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              minimumSize: const Size(0, 38),
            ),
            child: const Text('거절'),
          ),
          const SizedBox(width: 6),
          FilledButton(
            onPressed: onApprove,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              minimumSize: const Size(0, 38),
            ),
            child: const Text('승인'),
          ),
        ],
      ),
    );
  }

  Widget _avatar() {
    final photo = req.photoUrl;
    if (photo != null && photo.startsWith('http')) {
      return CircleAvatar(
        radius: 18,
        backgroundColor: AppColors.fitBg,
        backgroundImage: NetworkImage(photo),
      );
    }
    if (photo != null && photo.startsWith('animal:')) {
      return CircleAvatar(
        radius: 18,
        backgroundColor: AppColors.fitBg,
        child: Text(photo.substring(7), style: const TextStyle(fontSize: 18)),
      );
    }
    final name = req.name;
    return CircleAvatar(
      radius: 18,
      backgroundColor: AppColors.fitBg,
      child: Text(
        name.isNotEmpty ? name.substring(0, 1) : '?',
        style: const TextStyle(
          color: AppColors.primary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ─────────────────────────── 초대 코드 다이얼로그 ────────────────────────────
class _InviteCodeDialog extends StatelessWidget {
  final String code;
  const _InviteCodeDialog({required this.code});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('초대 코드'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            '이 코드를 친구에게 공유하세요',
            style: TextStyle(fontSize: 13, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            decoration: BoxDecoration(
              color: AppColors.fitBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              code,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                letterSpacing: 4,
                color: AppColors.primaryDim,
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '이 코드는 바뀌지 않아요 · 입장하려면 방장 승인이 필요해요',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, color: Colors.grey),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('닫기'),
        ),
        FilledButton.icon(
          onPressed: () {
            Clipboard.setData(ClipboardData(text: code));
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('코드를 복사했어요')));
            Navigator.pop(context);
          },
          icon: const Icon(Icons.copy, size: 16),
          label: const Text('복사'),
        ),
      ],
    );
  }
}
