import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/app_state.dart';
import '../../models/animal.dart';
import '../../models/experience.dart';
import '../../data/experience_data.dart';
import '../../services/auth_service.dart';
import '../../services/community_repository.dart';
import '../auth/login_screen.dart';
import '../onboarding/onboarding_profile_screen.dart';
import 'mission_calendar_tab.dart';

class MyPageScreen extends StatefulWidget {
  const MyPageScreen({super.key});

  @override
  State<MyPageScreen> createState() => _MyPageScreenState();
}

class _MyPageScreenState extends State<MyPageScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;
  final _picker = ImagePicker();
  final _community = CommunityRepository();

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  // ── 프로필 사진 변경 ───────────────────────────────────────────────────────
  Future<void> _openAvatarSheet(String userId) async {
    final hasAnimal = AppState.i.selectedAnimal != null;
    final current = AuthService.getAvatar(userId);

    await showModalBottomSheet<void>(
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
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 16, 20, 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '프로필 사진 설정',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
            ),
            ListTile(
              leading: const Text('🐾', style: TextStyle(fontSize: 24)),
              title: const Text('내 캐릭터로 설정'),
              subtitle: Text(
                hasAnimal ? '내 공간에서 만든 캐릭터 얼굴을 써요' : '먼저 내 공간에서 캐릭터를 만들어 주세요',
              ),
              enabled: hasAnimal,
              onTap: () {
                Navigator.pop(ctx);
                _setAvatar(userId, AuthService.avatarAnimal);
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.photo_library_outlined,
                color: Color(0xFF7DB879),
              ),
              title: const Text('갤러리에서 선택'),
              subtitle: const Text('내 사진 중에서 골라요'),
              onTap: () {
                Navigator.pop(ctx);
                _pickFromGallery(userId);
              },
            ),
            if (current != null)
              ListTile(
                leading: Icon(
                  Icons.refresh_rounded,
                  color: Colors.grey.shade600,
                ),
                title: const Text('기본 이모지로 되돌리기'),
                onTap: () {
                  Navigator.pop(ctx);
                  _setAvatar(userId, null);
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _setAvatar(String userId, String? value) async {
    // 로컬(마이 페이지 표시용)에 먼저 저장
    await AuthService.setAvatar(userId, value);
    if (mounted) setState(() {});
    // 커뮤니티(Supabase 프로필)에도 반영 — 실패해도 로컬 설정은 유지
    await _syncAvatarToCommunity(value);
  }

  /// 로컬 아바타 값을 커뮤니티 photo_url 형태로 바꿔 동기화한다.
  ///   null         → '' (지움)
  ///   avatarAnimal → 'animal:<이모지>'
  ///   그 외(URL)    → 그대로
  Future<void> _syncAvatarToCommunity(String? value) async {
    try {
      await _community.ensureSignedIn();
      final String remote;
      if (value == null) {
        remote = '';
      } else if (value == AuthService.avatarAnimal) {
        final emoji = AppState.i.selectedAnimal?.emoji ?? '';
        remote = emoji.isEmpty ? '' : 'animal:$emoji';
      } else {
        remote = value;
      }
      await _community.updateProfile(photoUrl: remote);
    } catch (e) {
      _snack(
        '커뮤니티 동기화에 실패했어요. ${e is CommunityException ? e.message : ''}',
        error: true,
      );
    }
  }

  Future<void> _pickFromGallery(String userId) async {
    final XFile? picked;
    try {
      picked = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1080,
      );
    } catch (_) {
      _snack('사진 접근 권한을 허용해 주세요', error: true);
      return;
    }
    if (picked == null) return;

    try {
      await _community.ensureSignedIn();
      final url = await _community.uploadAvatar(File(picked.path));
      await _setAvatar(userId, url); // URL을 로컬+커뮤니티에 반영
    } catch (e) {
      // 업로드 실패 — 로컬 파일로라도 프로필에 적용
      await AuthService.setAvatar(userId, picked.path);
      if (mounted) setState(() {});
      _snack(
        '프로필엔 적용했지만 업로드엔 실패했어요. ${e is CommunityException ? e.message : ''}',
        error: true,
      );
    }
  }

  void _snack(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        backgroundColor: error ? Colors.red.shade400 : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = AppState.i;
    final userId = AuthService.currentUserId ?? '';
    final nickname = AuthService.getNickname(userId);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // ── 프로필 헤더 ────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              child: Row(
                children: [
                  _ProfileAvatar(
                    avatar: AuthService.getAvatar(userId),
                    animal: state.selectedAnimal,
                    size: 56,
                    onTap: () => _openAvatarSheet(userId),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nickname,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        '총 ${state.completedIds.length}개 경험 완료',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                ],
              ),
            ),

            // ── 탭 바 ──────────────────────────────────────────────────
            TabBar(
              controller: _tab,
              tabs: const [
                Tab(text: '경험 도장'),
                Tab(text: '캘린더'),
                Tab(text: '내 설정'),
              ],
              indicatorColor: const Color(0xFF7DB879),
              labelColor: const Color(0xFF7DB879),
              unselectedLabelColor: Colors.grey,
              indicatorWeight: 2,
            ),

            Expanded(
              child: TabBarView(
                controller: _tab,
                children: [
                  _StampBoardTab(),
                  const MissionCalendarTab(),
                  _SettingsTab(
                    onReset: () => setState(() {}),
                    onChangeAvatar: () => _openAvatarSheet(userId),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════ 경험 도장판 탭 ══════════════════════════════════

class _StampBoardTab extends StatefulWidget {
  const _StampBoardTab();

  @override
  State<_StampBoardTab> createState() => _StampBoardTabState();
}

class _StampBoardTabState extends State<_StampBoardTab> {
  final _community = CommunityRepository();
  late Future<List<Room>> _roomsFuture;

  @override
  void initState() {
    super.initState();
    _roomsFuture = _loadRooms();
  }

  Future<List<Room>> _loadRooms() async {
    await _community.ensureSignedIn();
    return _community.listMyRooms();
  }

  @override
  Widget build(BuildContext context) {
    final completed = AppState.i.completedIds.toSet();
    final total = allExperiences.length;
    final doneCount = allExperiences
        .where((e) => completed.contains(e.id))
        .length;

    final easy = allExperiences
        .where((e) => e.difficulty == Difficulty.easy)
        .toList();
    final medium = allExperiences
        .where((e) => e.difficulty == Difficulty.medium)
        .toList();
    final hard = allExperiences
        .where((e) => e.difficulty == Difficulty.hard)
        .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 80),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── 진행 요약 ──────────────────────────────────────────────
          _ProgressBanner(done: doneCount, total: total),
          const SizedBox(height: 20),

          // ── 참여 중인 커뮤니티 목표 ──────────────────────────────────
          _CommunityGoals(future: _roomsFuture),

          _StampSection(
            difficultyLabel: '쉬움',
            difficultyEmoji: '🌿',
            color: const Color(0xFF1D9E75),
            bgColor: const Color(0xFFE8F8F2),
            experiences: easy,
            completed: completed,
          ),
          const SizedBox(height: 28),

          _StampSection(
            difficultyLabel: '보통',
            difficultyEmoji: '⚡',
            color: const Color(0xFFBA7517),
            bgColor: const Color(0xFFFFF3E0),
            experiences: medium,
            completed: completed,
          ),
          const SizedBox(height: 28),

          _StampSection(
            difficultyLabel: '어려움',
            difficultyEmoji: '🔥',
            color: const Color(0xFFD85A30),
            bgColor: const Color(0xFFFDECE6),
            experiences: hard,
            completed: completed,
          ),
        ],
      ),
    );
  }
}

// ── 참여 중인 커뮤니티 목표 ───────────────────────────────────────────────────
// 진행 요약(0/42) 아래에 내가 속한 방들의 목표를 보여준다.
// 로딩·에러·빈 목록일 때는 자리만 살짝 띄우고 숨겨서 도장판 레이아웃을 유지한다.
class _CommunityGoals extends StatelessWidget {
  final Future<List<Room>> future;
  const _CommunityGoals({required this.future});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Room>>(
      future: future,
      builder: (context, snap) {
        final rooms = snap.data ?? const <Room>[];
        // 아직 로딩 중이거나, 실패했거나, 참여 방이 없으면 → 간격만 유지
        if (snap.connectionState != ConnectionState.done ||
            snap.hasError ||
            rooms.isEmpty) {
          return const SizedBox(height: 8);
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('🎯', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 6),
                const Text(
                  '참여 중인 목표',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
                const SizedBox(width: 6),
                Text(
                  '${rooms.length}',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ...rooms.map((r) => _GoalCard(room: r)),
            const SizedBox(height: 28),
          ],
        );
      },
    );
  }
}

class _GoalCard extends StatelessWidget {
  final Room room;
  const _GoalCard({required this.room});

  @override
  Widget build(BuildContext context) {
    final goal = room.goalDescription;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F3E3),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.flag_rounded,
              color: Color(0xFF7DB879),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  room.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (goal != null && goal.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    goal,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ],
            ),
          ),
          Text(
            '${room.memberCount}명',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }
}

class _ProgressBanner extends StatelessWidget {
  final int done;
  final int total;
  const _ProgressBanner({required this.done, required this.total});

  @override
  Widget build(BuildContext context) {
    final ratio = done / total;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF7DB879), Color(0xFF5A9A4A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🗂️', style: TextStyle(fontSize: 22)),
              const SizedBox(width: 10),
              Text(
                '$done / $total 완료',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Text(
                '${(ratio * 100).round()}%',
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 7,
              backgroundColor: Colors.white.withValues(alpha: 0.25),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class _StampSection extends StatelessWidget {
  final String difficultyLabel;
  final String difficultyEmoji;
  final Color color;
  final Color bgColor;
  final List<Experience> experiences;
  final Set<String> completed;

  const _StampSection({
    required this.difficultyLabel,
    required this.difficultyEmoji,
    required this.color,
    required this.bgColor,
    required this.experiences,
    required this.completed,
  });

  @override
  Widget build(BuildContext context) {
    final doneCount = experiences.where((e) => completed.contains(e.id)).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 섹션 헤더
        Row(
          children: [
            Text(difficultyEmoji, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 8),
            Text(
              difficultyLabel,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '$doneCount/${experiences.length}',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // 도장 그리드
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 0.85,
          ),
          itemCount: experiences.length,
          itemBuilder: (_, i) {
            final exp = experiences[i];
            final isDone = completed.contains(exp.id);
            return _StampCard(
              experience: exp,
              isDone: isDone,
              stampColor: color,
              stampBg: bgColor,
            );
          },
        ),
      ],
    );
  }
}

class _StampCard extends StatelessWidget {
  final Experience experience;
  final bool isDone;
  final Color stampColor;
  final Color stampBg;

  const _StampCard({
    required this.experience,
    required this.isDone,
    required this.stampColor,
    required this.stampBg,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: isDone ? 1.0 : 0.38,
      duration: const Duration(milliseconds: 300),
      child: Container(
        decoration: BoxDecoration(
          color: isDone ? stampBg : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDone
                ? stampColor.withValues(alpha: 0.6)
                : Colors.grey.shade300,
            width: isDone ? 2 : 1,
          ),
        ),
        child: Stack(
          children: [
            // 도장 찍힌 이모지 워터마크
            if (isDone)
              Positioned(
                top: 6,
                right: 8,
                child: Text(
                  experience.difficulty.emoji,
                  style: TextStyle(
                    fontSize: 11,
                    color: stampColor.withValues(alpha: 0.5),
                  ),
                ),
              ),
            // 메인 콘텐츠
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 10, 8, 8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 완료 시 체크, 미완료 시 잠금
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDone
                          ? stampColor.withValues(alpha: 0.15)
                          : Colors.grey.shade200,
                    ),
                    child: Center(
                      child: isDone
                          ? Icon(
                              Icons.check_rounded,
                              size: 20,
                              color: stampColor,
                            )
                          : Icon(
                              Icons.lock_outline_rounded,
                              size: 18,
                              color: Colors.grey.shade400,
                            ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    experience.title,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isDone ? FontWeight.w600 : FontWeight.w400,
                      color: isDone ? Colors.black87 : Colors.grey.shade500,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════ 내 설정 탭 ══════════════════════════════════════

class _SettingsTab extends StatelessWidget {
  final VoidCallback onReset;
  final VoidCallback onChangeAvatar;
  const _SettingsTab({required this.onReset, required this.onChangeAvatar});

  @override
  Widget build(BuildContext context) {
    final userId = AuthService.currentUserId ?? '';
    final profile = AuthService.getProfile(userId);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 80),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '내 프로필',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),

          _ProfileHeaderCard(
            userId: userId,
            onEditNickname: () => _changeNickname(context, userId),
            onChangeAvatar: onChangeAvatar,
          ),
          const SizedBox(height: 16),

          if (profile == null)
            const _EmptyProfileCard()
          else
            _ProfileCard(profile: profile),

          const SizedBox(height: 32),

          // ── 온보딩 재설정 ──────────────────────────────────────────
          const Text(
            '설정',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          _SettingItem(
            icon: Icons.refresh_rounded,
            label: '온보딩 다시 설정하기',
            subtitle: '나이, MBTI, 직업, 취미를 다시 입력할 수 있어요',
            onTap: () => _confirmReset(context, userId),
          ),
          const SizedBox(height: 12),
          _SettingItem(
            icon: Icons.logout_rounded,
            label: '로그아웃',
            subtitle: '계정에서 로그아웃해요',
            onTap: () => _confirmLogout(context),
            isDanger: true,
          ),
        ],
      ),
    );
  }

  Future<void> _changeNickname(BuildContext context, String userId) async {
    final newName = await showDialog<String>(
      context: context,
      builder: (_) => _NicknameDialog(initial: AuthService.getNickname(userId)),
    );

    if (newName == null || newName.isEmpty) return;

    // 로컬(마이 헤더) + Supabase(커뮤니티/채팅 표시 이름) 둘 다 갱신.
    await AuthService.setNickname(userId, newName);
    String? syncError;
    try {
      final community = CommunityRepository();
      await community.ensureSignedIn();
      await community.updateProfile(displayName: newName);
    } catch (e) {
      syncError = e is CommunityException ? e.message : '커뮤니티 동기화에 실패했어요.';
    }

    onReset(); // 부모 새로고침 → 헤더 닉네임 반영
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(syncError ?? '닉네임을 변경했어요.'),
        backgroundColor: syncError != null ? Colors.red.shade400 : null,
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text(
          '로그아웃',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        content: const Text(
          '정말 로그아웃 하시겠어요?',
          style: TextStyle(fontSize: 14, height: 1.6),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('취소', style: TextStyle(color: Colors.grey)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red.shade400,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('로그아웃'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    if (!context.mounted) return;

    AuthService.logout();

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  Future<void> _confirmReset(BuildContext context, String userId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text(
          '온보딩 재설정',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        content: const Text(
          '나이, MBTI, 직업, 취미를 다시 입력하게 돼요.\n경험 기록과 포인트는 그대로 유지돼요.',
          style: TextStyle(fontSize: 14, height: 1.6),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('취소', style: TextStyle(color: Colors.grey)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF7DB879),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('재설정하기'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    if (!context.mounted) return;

    await AuthService.resetOnboarding(userId);

    if (!context.mounted) return;
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, _, _) => OnboardingProfileScreen(userId: userId),
        transitionsBuilder: (_, anim, _, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }
}

// 닉네임 입력 다이얼로그.
// 컨트롤러를 State가 소유해 dispose()를 라우트 해제 이후 올바른 시점에 호출한다.
// (showDialog의 future는 pop 애니메이션 전에 완료되므로, await 직후 수동 dispose하면
//  아직 트리에 남아 애니메이션 중인 TextField 때문에 InheritedElement 단언이 깨진다.)
class _NicknameDialog extends StatefulWidget {
  final String initial;
  const _NicknameDialog({required this.initial});

  @override
  State<_NicknameDialog> createState() => _NicknameDialogState();
}

class _NicknameDialogState extends State<_NicknameDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initial);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      title: const Text(
        '닉네임 변경',
        style: TextStyle(fontWeight: FontWeight.w700),
      ),
      content: TextField(
        controller: _controller,
        autofocus: true,
        maxLength: 20,
        decoration: const InputDecoration(
          hintText: '새 닉네임',
          border: OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('취소', style: TextStyle(color: Colors.grey)),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF7DB879),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          onPressed: () => Navigator.pop(context, _controller.text.trim()),
          child: const Text('저장'),
        ),
      ],
    );
  }
}

// 내 설정 탭 상단 프로필 카드.
// 사진(탭 → 변경)·닉네임(연필 → 변경)을 여기서 바로 바꾸고,
// 탐험가 레벨·완료한 목표 개수 등 활동 요약을 보여준다.
class _ProfileHeaderCard extends StatelessWidget {
  final String userId;
  final VoidCallback onEditNickname;
  final VoidCallback onChangeAvatar;

  const _ProfileHeaderCard({
    required this.userId,
    required this.onEditNickname,
    required this.onChangeAvatar,
  });

  @override
  Widget build(BuildContext context) {
    final state = AppState.i;
    final nickname = AuthService.getNickname(userId);
    final week = AuthService.getWeekNumber(userId);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              _ProfileAvatar(
                avatar: AuthService.getAvatar(userId),
                animal: state.selectedAnimal,
                size: 64,
                onTap: onChangeAvatar,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            nickname,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: onEditNickname,
                          behavior: HitTestBehavior.opaque,
                          child: Icon(
                            Icons.edit_rounded,
                            size: 16,
                            color: Colors.grey.shade400,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F3E3),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '🧭 탐험가 Lv.${state.level}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF5A9A4A),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 28),
          Row(
            children: [
              _ProfileStat(
                value: '${state.completedIds.length}',
                label: '완료한 목표',
              ),

              _statDivider(),
              _ProfileStat(value: '$week', label: '활동 주차'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statDivider() =>
      Container(width: 1, height: 28, color: Colors.grey.shade200);
}

class _ProfileStat extends StatelessWidget {
  final String value;
  final String label;
  const _ProfileStat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF5A9A4A),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  final UserProfile profile;
  const _ProfileCard({required this.profile});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _ProfileRow(
            label: 'MBTI',
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F3E3),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                profile.mbti,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF5A9A4A),
                ),
              ),
            ),
          ),
          const Divider(height: 24),
          _ProfileRow(
            label: '나이',
            child: Text(
              '${profile.age}세',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
          const Divider(height: 24),
          _ProfileRow(
            label: '직업',
            child: Text(
              profile.job,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
          const Divider(height: 24),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '취미',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: profile.hobbies
                    .map(
                      (h) => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F3E3),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          h,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF5A9A4A),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProfileRow extends StatelessWidget {
  final String label;
  final Widget child;
  const _ProfileRow({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 48,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade500,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(width: 12),
        child,
      ],
    );
  }
}

class _EmptyProfileCard extends StatelessWidget {
  const _EmptyProfileCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Center(
        child: Text(
          '프로필 정보가 없어요. 아래에서 온보딩을 설정해보세요.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade400,
            height: 1.6,
          ),
        ),
      ),
    );
  }
}

class _SettingItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;
  final bool isDanger;

  const _SettingItem({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
    this.isDanger = false,
  });

  @override
  Widget build(BuildContext context) {
    final iconBg = isDanger ? Colors.red.shade50 : const Color(0xFFE8F3E3);
    final iconColor = isDanger ? Colors.red.shade400 : const Color(0xFF7DB879);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDanger ? Colors.red.shade100 : Colors.grey.shade100,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 20, color: iconColor),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDanger ? Colors.red.shade400 : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════ 프로필 사진 아바타 ══════════════════════════════
//
// avatar 값 해석:
//   null                       → 기본 이모지(🧭)
//   AuthService.avatarAnimal   → 내 공간 캐릭터 동물 얼굴
//   그 외 문자열               → 갤러리 사진 파일 경로
// 우측 하단 카메라 배지로 탭하면 바꿀 수 있음을 표시한다.
class _ProfileAvatar extends StatelessWidget {
  final String? avatar;
  final Animal? animal;
  final double size;
  final VoidCallback onTap;

  const _ProfileAvatar({
    required this.avatar,
    required this.animal,
    required this.size,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: size,
            height: size,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(shape: BoxShape.circle, color: _bgColor),
            child: Center(child: _content),
          ),
          Positioned(
            right: -2,
            bottom: -2,
            child: Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: const Color(0xFF7DB879),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: const Icon(
                Icons.camera_alt_rounded,
                size: 11,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color get _bgColor {
    if (avatar == AuthService.avatarAnimal && animal != null) {
      return animal!.furColor;
    }
    return const Color(0xFFE8F3E3);
  }

  Widget get _content {
    final a = avatar;
    // 캐릭터 얼굴
    if (a == AuthService.avatarAnimal) {
      return _emoji(animal?.emoji ?? '🧭');
    }
    // 업로드된 사진(URL)
    if (a != null && a.startsWith('http')) {
      return Image.network(
        a,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _emoji('🧭'),
      );
    }
    // 로컬 파일 경로 (업로드 실패 시 폴백)
    if (a != null) {
      final file = File(a);
      if (file.existsSync()) {
        return Image.file(file, width: size, height: size, fit: BoxFit.cover);
      }
    }
    // 기본
    return _emoji('🧭');
  }

  Widget _emoji(String e) => Text(e, style: TextStyle(fontSize: size * 0.5));
}
