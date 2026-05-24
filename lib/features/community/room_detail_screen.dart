import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/app_colors.dart';
import '../../services/community_repository.dart';

/// 방 상세 — 멤버 목록 + (방장) 초대코드 생성 + 방 나가기
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

class _RoomDetailScreenState extends State<RoomDetailScreen> {
  final _repo = CommunityRepository();
  late Future<List<RoomMember>> _membersFuture;

  @override
  void initState() {
    super.initState();
    _membersFuture = _repo.roomMembers(widget.roomId);
  }

  void _reload() =>
      setState(() => _membersFuture = _repo.roomMembers(widget.roomId));

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  // ── 초대 코드 만들기 ─────────────────────────────────────────────────────────
  Future<void> _createInvite() async {
    try {
      final code = await _repo.createInviteCode(
        widget.roomId,
        maxUses: 20,
        ttlHours: 168, // 7일
      );
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (_) => _InviteCodeDialog(code: code),
      );
    } on CommunityException catch (e) {
      _snack(e.message);
    }
  }

  // ── 방 나가기 (방장이면 위임/삭제) ───────────────────────────────────────────
  Future<void> _leave() async {
    // 확인 문구를 위해 현재 멤버 상황 파악 (이미 로드된 future라 즉시 반환됨)
    List<RoomMember> members = const [];
    try {
      members = await _membersFuture;
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
              child: const Text('취소')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.dareAccent),
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
            tooltip: '방 나가기',
            icon: const Icon(Icons.logout, size: 20),
            onPressed: _leave,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => _reload(),
        child: FutureBuilder<List<RoomMember>>(
          future: _membersFuture,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snap.hasError) {
              return ListView(
                children: [
                  const SizedBox(height: 80),
                  Center(
                    child: Text(snap.error.toString(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.grey)),
                  ),
                ],
              );
            }
            final members = snap.data ?? [];
            final iAmOwner =
                members.any((m) => m.userId == myId && m.role == 'owner');
            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              children: [
                if (iAmOwner)
                  FilledButton.icon(
                    onPressed: _createInvite,
                    icon: const Icon(Icons.qr_code_2, size: 18),
                    label: const Text('초대 코드 만들기'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      minimumSize: const Size.fromHeight(48),
                    ),
                  ),
                const SizedBox(height: 20),
                Text('멤버 ${members.length}명',
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                ...members.map(
                  (m) => _MemberTile(member: m, isMe: m.userId == myId),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ─────────────────────────── 멤버 타일 ───────────────────────────────────────
class _MemberTile extends StatelessWidget {
  final RoomMember member;
  final bool isMe;
  const _MemberTile({required this.member, required this.isMe});

  @override
  Widget build(BuildContext context) {
    final name = member.displayName ?? member.handle ?? '익명 탐험가';
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: AppColors.fitBg,
        child: Text(
          name.isNotEmpty ? name.substring(0, 1) : '?',
          style: const TextStyle(
              color: AppColors.primary, fontWeight: FontWeight.w700),
        ),
      ),
      title: Text(isMe ? '$name (나)' : name),
      trailing: member.role == 'owner'
          ? const Text('방장',
              style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 12))
          : null,
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
          const Text('이 코드를 친구에게 공유하세요',
              style: TextStyle(fontSize: 13, color: Colors.grey)),
          const SizedBox(height: 16),
          Container(
            padding:
                const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
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
          const Text('20명까지 · 7일간 유효',
              style: TextStyle(fontSize: 11, color: Colors.grey)),
        ],
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('닫기')),
        FilledButton.icon(
          onPressed: () {
            Clipboard.setData(ClipboardData(text: code));
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('코드를 복사했어요')));
            Navigator.pop(context);
          },
          icon: const Icon(Icons.copy, size: 16),
          label: const Text('복사'),
        ),
      ],
    );
  }
}
