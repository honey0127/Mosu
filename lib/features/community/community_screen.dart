import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../services/community_repository.dart';
import 'room_detail_screen.dart';

/// 커뮤니티 탭 — 내가 속한 목표 방 목록 + 방 만들기 / 코드로 입장
class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  final _repo = CommunityRepository();
  late Future<List<Room>> _roomsFuture;

  @override
  void initState() {
    super.initState();
    _roomsFuture = _load();
  }

  Future<List<Room>> _load() async {
    await _repo.ensureSignedIn(); // 익명 세션 보장
    return _repo.listMyRooms();
  }

  Future<void> _refresh() async {
    setState(() => _roomsFuture = _load());
    await _roomsFuture;
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  // ── 방 만들기 ────────────────────────────────────────────────────────────────
  Future<void> _createRoom() async {
    final input = await showDialog<({String name, String? goal, int max})>(
      context: context,
      builder: (_) => const _CreateRoomDialog(),
    );
    if (input == null) return;
    try {
      final roomId = await _repo.createRoom(
        name: input.name,
        goal: input.goal,
        maxMembers: input.max,
      );
      _snack('방을 만들었어요!');
      await _refresh();
      _openRoom(roomId, input.name);
    } on CommunityException catch (e) {
      _snack(e.message);
    }
  }

  // ── 코드로 입장 ──────────────────────────────────────────────────────────────
  Future<void> _joinByCode() async {
    final code = await showDialog<String>(
      context: context,
      builder: (_) => const _JoinByCodeDialog(),
    );
    if (code == null || code.trim().isEmpty) return;
    try {
      final res = await _repo.requestJoin(code.trim());
      _snack('‘${res.roomName}’에 가입 요청을 보냈어요. 방장이 승인하면 입장돼요.');
    } on CommunityException catch (e) {
      _snack(e.message);
    }
  }

  void _openRoom(String roomId, String roomName) {
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RoomDetailScreen(roomId: roomId, roomName: roomName),
      ),
    ).then((_) => _refresh()); // 돌아오면 목록 갱신
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLow,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 헤더
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('커뮤니티',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text('함께 목표를 향해 달리는 방',
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
                  const SizedBox(height: 16),
                ],
              ),
            ),
            // 액션 버튼
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _createRoom,
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('방 만들기'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _joinByCode,
                      icon: const Icon(Icons.vpn_key_outlined, size: 18),
                      label: const Text('코드로 입장'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // 목록
            Expanded(
              child: RefreshIndicator(
                onRefresh: _refresh,
                child: FutureBuilder<List<Room>>(
                  future: _roomsFuture,
                  builder: (context, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snap.hasError) {
                      return _ErrorView(
                        message: snap.error.toString(),
                        onRetry: _refresh,
                      );
                    }
                    final rooms = snap.data ?? [];
                    if (rooms.isEmpty) return const _EmptyView();
                    return ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                      itemCount: rooms.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (_, i) => _RoomCard(
                        room: rooms[i],
                        onTap: () => _openRoom(rooms[i].id, rooms[i].name),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────── 방 카드 ─────────────────────────────────────────
class _RoomCard extends StatelessWidget {
  final Room room;
  final VoidCallback onTap;
  const _RoomCard({required this.room, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isOwner = room.role == 'owner';
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.fitBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.flag_rounded, color: AppColors.primary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            room.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w700),
                          ),
                        ),
                        if (isOwner) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text('방장',
                                style: TextStyle(
                                    fontSize: 10,
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w700)),
                          ),
                        ],
                      ],
                    ),
                    if (room.goalDescription != null &&
                        room.goalDescription!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        room.goalDescription!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style:
                            TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                    ],
                    const SizedBox(height: 6),
                    Text('멤버 ${room.memberCount}/${room.maxMembers}',
                        style: TextStyle(
                            fontSize: 11, color: Colors.grey.shade500)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────── 빈 상태 / 에러 ──────────────────────────────────
class _EmptyView extends StatelessWidget {
  const _EmptyView();
  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 80),
        const Center(child: Text('🏁', style: TextStyle(fontSize: 52))),
        const SizedBox(height: 16),
        const Center(
          child: Text('아직 참여 중인 방이 없어요',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        ),
        const SizedBox(height: 8),
        Center(
          child: Text('방을 만들거나 코드로 입장해보세요',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
        ),
      ],
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;
  const _ErrorView({required this.message, required this.onRetry});
  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 60),
        const Center(
            child: Icon(Icons.error_outline,
                size: 40, color: Colors.redAccent)),
        const SizedBox(height: 12),
        Center(
          child: Text(message,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
        ),
        const SizedBox(height: 16),
        Center(
          child: OutlinedButton(
              onPressed: onRetry, child: const Text('다시 시도')),
        ),
      ],
    );
  }
}

// ─────────────────────────── 방 만들기 다이얼로그 ────────────────────────────
class _CreateRoomDialog extends StatefulWidget {
  const _CreateRoomDialog();
  @override
  State<_CreateRoomDialog> createState() => _CreateRoomDialogState();
}

class _CreateRoomDialogState extends State<_CreateRoomDialog> {
  final _name = TextEditingController();
  final _goal = TextEditingController();
  int _max = 50;

  @override
  void dispose() {
    _name.dispose();
    _goal.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('방 만들기'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _name,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: '방 이름',
              hintText: '예: 아침 6시 기상 챌린지',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _goal,
            decoration: const InputDecoration(
              labelText: '목표 (선택)',
              hintText: '예: 한 달간 매일 인증',
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Text('최대 인원', style: TextStyle(fontSize: 13)),
              const Spacer(),
              DropdownButton<int>(
                value: _max,
                items: const [10, 20, 50, 100]
                    .map((n) => DropdownMenuItem(value: n, child: Text('$n명')))
                    .toList(),
                onChanged: (v) => setState(() => _max = v ?? 50),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소')),
        FilledButton(
          onPressed: () {
            final name = _name.text.trim();
            if (name.isEmpty) return;
            Navigator.pop(context, (
              name: name,
              goal: _goal.text.trim().isEmpty ? null : _goal.text.trim(),
              max: _max,
            ));
          },
          child: const Text('만들기'),
        ),
      ],
    );
  }
}

// ─────────────────────────── 코드 입장 다이얼로그 ────────────────────────────
class _JoinByCodeDialog extends StatefulWidget {
  const _JoinByCodeDialog();
  @override
  State<_JoinByCodeDialog> createState() => _JoinByCodeDialogState();
}

class _JoinByCodeDialogState extends State<_JoinByCodeDialog> {
  final _code = TextEditingController();

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('코드로 입장'),
      content: TextField(
        controller: _code,
        autofocus: true,
        textCapitalization: TextCapitalization.characters,
        decoration: const InputDecoration(
          labelText: '초대 코드',
          hintText: '예: MOS7K2',
        ),
        onSubmitted: (v) => Navigator.pop(context, v),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소')),
        FilledButton(
          onPressed: () => Navigator.pop(context, _code.text),
          child: const Text('입장'),
        ),
      ],
    );
  }
}
