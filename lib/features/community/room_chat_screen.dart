import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../services/community_repository.dart';

/// 방 채팅 — Supabase Realtime 으로 메시지를 실시간 수신/전송.
/// 작성자 이름·아바타는 방 멤버 목록(한 번 로드)에서 매핑한다.
class RoomChatScreen extends StatefulWidget {
  final String roomId;
  final String roomName;
  const RoomChatScreen({
    super.key,
    required this.roomId,
    required this.roomName,
  });

  @override
  State<RoomChatScreen> createState() => _RoomChatScreenState();
}

class _RoomChatScreenState extends State<RoomChatScreen> {
  final _repo = CommunityRepository();
  final _input = TextEditingController();
  late final Stream<List<RoomMessage>> _stream;

  Map<String, RoomMember> _members = const {};
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _stream = _repo.roomMessageStream(widget.roomId);
    _loadMembers();
  }

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  Future<void> _loadMembers() async {
    try {
      await _repo.ensureSignedIn();
      final members = await _repo.roomMembers(widget.roomId);
      if (!mounted) return;
      setState(() => _members = {for (final m in members) m.userId: m});
    } catch (_) {
      // 멤버를 못 불러와도 메시지는 보이게 둔다 (이름은 '익명'으로 폴백).
    }
  }

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    _input.clear();
    try {
      await _repo.sendMessage(widget.roomId, text);
    } on CommunityException catch (e) {
      _input.text = text; // 실패 시 복구
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final myId = _repo.currentUserId;
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLow,
      appBar: AppBar(
        title: Text('${widget.roomName} 채팅'),
        backgroundColor: Colors.transparent,
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<RoomMessage>>(
              stream: _stream,
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snap.hasError) {
                  return _CenteredHint(
                    text: '채팅을 불러오지 못했어요.\n0004_chat.sql 을 적용했는지 확인해 주세요.',
                  );
                }
                final msgs = snap.data ?? const [];
                if (msgs.isEmpty) {
                  return const _CenteredHint(text: '첫 메시지를 남겨보세요!');
                }
                // 스트림이 최신순(내림차순)으로 오므로 reverse:true 로
                // index 0(최신)을 화면 맨 아래에 표시 → 카카오톡 스타일
                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  itemCount: msgs.length,
                  itemBuilder: (_, i) {
                    final m = msgs[i];
                    return _MessageBubble(
                      message: m,
                      isMine: m.userId == myId,
                      author: _members[m.userId],
                    );
                  },
                );
              },
            ),
          ),
          _inputBar(),
        ],
      ),
    );
  }

  Widget _inputBar() {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Colors.grey.shade200)),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _input,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _send(),
                decoration: InputDecoration(
                  hintText: '메시지 입력…',
                  filled: true,
                  fillColor: AppColors.fitBg,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            IconButton(
              onPressed: _sending ? null : _send,
              icon: const Icon(Icons.send_rounded),
              color: AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final RoomMessage message;
  final bool isMine;
  final RoomMember? author;
  const _MessageBubble({
    required this.message,
    required this.isMine,
    required this.author,
  });

  String _fmtTime(DateTime d) {
    final h = d.hour.toString().padLeft(2, '0');
    final m = d.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  Widget build(BuildContext context) {
    final name = author?.displayName ?? author?.handle ?? '익명 탐험가';
    final time = _fmtTime(message.createdAt);

    final bubble = Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isMine ? AppColors.primary : Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        message.content,
        style: TextStyle(
          fontSize: 14,
          color: isMine ? Colors.white : Colors.black87,
          height: 1.35,
        ),
      ),
    );

    if (isMine) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 10, left: 48),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              time,
              style: TextStyle(fontSize: 10, color: Colors.grey.shade400),
            ),
            const SizedBox(width: 6),
            Flexible(child: bubble),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10, right: 48),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _avatar(name),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 3),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Flexible(child: bubble),
                    const SizedBox(width: 6),
                    Text(
                      time,
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade400,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _avatar(String name) {
    final photo = author?.photoUrl;
    if (photo != null && photo.startsWith('http')) {
      return CircleAvatar(
        radius: 16,
        backgroundColor: AppColors.fitBg,
        backgroundImage: NetworkImage(photo),
      );
    }
    if (photo != null && photo.startsWith('animal:')) {
      return CircleAvatar(
        radius: 16,
        backgroundColor: AppColors.fitBg,
        child: Text(photo.substring(7), style: const TextStyle(fontSize: 16)),
      );
    }
    return CircleAvatar(
      radius: 16,
      backgroundColor: AppColors.fitBg,
      child: Text(
        name.isNotEmpty ? name.substring(0, 1) : '?',
        style: const TextStyle(
          color: AppColors.primary,
          fontWeight: FontWeight.w700,
          fontSize: 13,
        ),
      ),
    );
  }
}

class _CenteredHint extends StatelessWidget {
  final String text;
  const _CenteredHint({required this.text});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade500,
            height: 1.5,
          ),
        ),
      ),
    );
  }
}
