import 'package:flutter/material.dart';
import '../../models/community_room.dart';
import '../../services/auth_service.dart';
import '../../services/community_service.dart';
import 'create_room_screen.dart';
import 'room_detail_screen.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  static const _purple = Color(0xFF7F77DD);
  static const _bg = Color(0xFFF2F2F0);

  List<CommunityRoom> _rooms = [];

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    final userId = AuthService.currentUserId ?? '';
    setState(() {
      _rooms = CommunityService.getUserRooms(userId);
    });
  }

  Future<void> _openCreate() async {
    final result = await Navigator.push<CommunityRoom>(
      context,
      MaterialPageRoute(builder: (_) => const CreateRoomScreen()),
    );
    if (result != null) _reload();
  }

  Future<void> _openJoin() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _JoinSheet(onJoined: _reload),
    );
  }

  Future<void> _openDetail(String roomId) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => RoomDetailScreen(roomId: roomId)),
    );
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ── 헤더 ────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '커뮤니티',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF2A2A2A),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '탐험가들과 함께 경험을 쌓아봐요',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        _headerBtn(
                          icon: Icons.login_rounded,
                          label: '코드 입력',
                          onTap: _openJoin,
                        ),
                        const SizedBox(width: 8),
                        _headerBtn(
                          icon: Icons.add_rounded,
                          label: '방 만들기',
                          onTap: _openCreate,
                          filled: true,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 24)),

            // ── 방 목록 or 빈 상태 ───────────────────────────────────
            if (_rooms.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _EmptyState(
                  onCreate: _openCreate,
                  onJoin: _openJoin,
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, i) => _RoomCard(
                      room: _rooms[i],
                      myId: AuthService.currentUserId ?? '',
                      onTap: () => _openDetail(_rooms[i].id),
                    ),
                    childCount: _rooms.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _headerBtn({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool filled = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: filled ? _purple : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: filled ? _purple : Colors.grey.shade300,
          ),
        ),
        child: Row(
          children: [
            Icon(icon,
                size: 15,
                color: filled ? Colors.white : const Color(0xFF555555)),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: filled ? Colors.white : const Color(0xFF555555),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── 방 카드 ─────────────────────────────────────────────────────────────────
class _RoomCard extends StatelessWidget {
  final CommunityRoom room;
  final String myId;
  final VoidCallback onTap;
  const _RoomCard(
      {required this.room, required this.myId, required this.onTap});

  static const _purple = Color(0xFF7F77DD);

  @override
  Widget build(BuildContext context) {
    final isCreator = room.isCreator(myId);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _purple.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Text('🏠', style: TextStyle(fontSize: 22)),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          room.name,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF2A2A2A),
                          ),
                        ),
                      ),
                      if (isCreator)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF3CD),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            '방장',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF856404),
                            ),
                          ),
                        ),
                    ],
                  ),
                  if (room.description.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      room.description,
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey.shade500),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.group_outlined,
                          size: 13, color: Colors.grey.shade400),
                      const SizedBox(width: 3),
                      Text(
                        '${room.memberCount}명',
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade500),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: _purple.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          room.inviteCode,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: _purple,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                color: Colors.grey.shade400, size: 20),
          ],
        ),
      ),
    );
  }
}

// ── 빈 상태 ─────────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final VoidCallback onCreate;
  final VoidCallback onJoin;
  const _EmptyState({required this.onCreate, required this.onJoin});

  static const _purple = Color(0xFF7F77DD);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🌐', style: TextStyle(fontSize: 56)),
          const SizedBox(height: 20),
          const Text(
            '아직 참여한 방이 없어요',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: Color(0xFF2A2A2A),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '방을 만들거나 초대코드로\n친구 방에 참여해봐요',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade500,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onJoin,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _purple,
                    side: const BorderSide(color: _purple),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text(
                    '코드로 참여',
                    style: TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: onCreate,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _purple,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text(
                    '방 만들기',
                    style: TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 60),
        ],
      ),
    );
  }
}

// ── 초대코드 입력 바텀시트 ───────────────────────────────────────────────────
class _JoinSheet extends StatefulWidget {
  final VoidCallback onJoined;
  const _JoinSheet({required this.onJoined});

  @override
  State<_JoinSheet> createState() => _JoinSheetState();
}

class _JoinSheetState extends State<_JoinSheet> {
  final _ctrl = TextEditingController();
  bool _loading = false;
  String? _error;

  static const _purple = Color(0xFF7F77DD);

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _join() async {
    final code = _ctrl.text.trim().toUpperCase();
    if (code.length != 6) {
      setState(() => _error = '6자리 코드를 입력해주세요.');
      return;
    }

    final userId = AuthService.currentUserId;
    if (userId == null) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    final room = await CommunityService.joinByCode(userId, code);
    if (!mounted) return;
    setState(() => _loading = false);

    if (room == null) {
      setState(() => _error = '유효하지 않은 코드예요. 다시 확인해주세요.');
      return;
    }

    widget.onJoined();
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('\'${room.name}\' 방에 참여했어요 🎉'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottomInset),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            '초대코드로 참여',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF2A2A2A),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '친구에게 받은 6자리 코드를 입력하세요',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _ctrl,
            autofocus: true,
            textCapitalization: TextCapitalization.characters,
            maxLength: 6,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: 6,
              color: _purple,
            ),
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              counterText: '',
              hintText: '· · · · · ·',
              hintStyle: TextStyle(
                fontSize: 22,
                letterSpacing: 8,
                color: Colors.grey.shade300,
              ),
              filled: true,
              fillColor: const Color(0xFFF5F5FF),
              contentPadding: const EdgeInsets.symmetric(vertical: 16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide:
                    const BorderSide(color: _purple, width: 1.5),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide:
                    const BorderSide(color: _purple, width: 1.5),
              ),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!,
                style: const TextStyle(
                    color: Color(0xFFE57373), fontSize: 13)),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _loading ? null : _join,
              style: ElevatedButton.styleFrom(
                backgroundColor: _purple,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey.shade200,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: _loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Text(
                      '참여하기',
                      style: TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
