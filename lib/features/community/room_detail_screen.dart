import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/community_room.dart';
import '../../services/auth_service.dart';
import '../../services/community_service.dart';

class RoomDetailScreen extends StatefulWidget {
  final String roomId;
  const RoomDetailScreen({super.key, required this.roomId});

  @override
  State<RoomDetailScreen> createState() => _RoomDetailScreenState();
}

class _RoomDetailScreenState extends State<RoomDetailScreen> {
  static const _purple = Color(0xFF7F77DD);
  static const _bg = Color(0xFFF2F2F0);

  CommunityRoom? _room;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    setState(() {
      _room = CommunityService.getRoomById(widget.roomId);
    });
  }

  String get _myId => AuthService.currentUserId ?? '';
  bool get _isCreator => _room?.isCreator(_myId) ?? false;

  Future<void> _copyCode() async {
    if (_room == null) return;
    await Clipboard.setData(ClipboardData(text: _room!.inviteCode));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('초대코드가 복사됐어요 👍'),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _leaveOrDelete() async {
    if (_room == null) return;
    final isDelete = _isCreator && _room!.memberCount == 1;
    final action = _isCreator && !isDelete ? '방장 권한을 넘기고 나가기' :
        isDelete ? '방 삭제하기' : '방 나가기';

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(isDelete ? '방 삭제' : '방 나가기'),
        content: Text(isDelete
            ? '방을 삭제하면 모든 멤버가 나가게 돼요.\n정말 삭제할까요?'
            : _isCreator
                ? '방장 권한이 다음 멤버에게 넘어가요.\n정말 나가실 건가요?'
                : '정말 방을 나가실 건가요?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('취소')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
                foregroundColor: const Color(0xFFE57373)),
            child: Text(isDelete ? '삭제' : '나가기'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    if (isDelete) {
      await CommunityService.deleteRoom(widget.roomId);
    } else {
      await CommunityService.leaveRoom(_myId, widget.roomId);
    }
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final room = _room;
    if (room == null) {
      return const Scaffold(
        body: Center(child: Text('방을 찾을 수 없어요')),
      );
    }

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              size: 18, color: Color(0xFF444444)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          room.name,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: Color(0xFF2A2A2A),
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // ── 방 정보 카드 ─────────────────────────────────────────
            _card(
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: _purple.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Center(
                      child: Text('🏠', style: TextStyle(fontSize: 26)),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          room.name,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF2A2A2A),
                          ),
                        ),
                        if (room.description.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Text(
                            room.description,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                        const SizedBox(height: 4),
                        Text(
                          '개설일 ${_formatDate(room.createdAt)}',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── 초대코드 섹션 ─────────────────────────────────────────
            _sectionTitle('초대코드'),
            const SizedBox(height: 8),
            _card(
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          room.inviteCode,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 6,
                            color: _purple,
                            fontFamily: 'monospace',
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '이 코드를 친구에게 알려주세요',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: _copyCode,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: _purple.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.copy_rounded,
                              size: 15, color: _purple),
                          SizedBox(width: 4),
                          Text(
                            '복사',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: _purple,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── 멤버 섹션 ─────────────────────────────────────────────
            Row(
              children: [
                _sectionTitle('멤버'),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: _purple.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    '${room.memberCount}/${CommunityRoom.maxMembers}명',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _purple,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _card(
              child: Column(
                children: room.memberIds.map((memberId) {
                  final nickname = AuthService.getNickname(memberId);
                  final isRoomCreator = room.isCreator(memberId);
                  final isMe = memberId == _myId;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor:
                              _purple.withValues(alpha: 0.15),
                          child: Text(
                            nickname.isNotEmpty
                                ? nickname[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: _purple,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            '$nickname${isMe ? ' (나)' : ''}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF2A2A2A),
                            ),
                          ),
                        ),
                        if (isRoomCreator)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF3CD),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              '방장',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF856404),
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 24),

            // ── 나가기 / 삭제 버튼 ────────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton(
                onPressed: _leaveOrDelete,
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFE57373),
                  side: BorderSide(
                      color: Colors.red.shade200, width: 1),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  _isCreator && room.memberCount == 1
                      ? '방 삭제하기'
                      : '방 나가기',
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _card({required Widget child}) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: child,
      );

  Widget _sectionTitle(String t) => Text(
        t,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: Color(0xFF444444),
          letterSpacing: 0.3,
        ),
      );

  String _formatDate(DateTime dt) =>
      '${dt.year}.${dt.month.toString().padLeft(2, '0')}.${dt.day.toString().padLeft(2, '0')}';
}
