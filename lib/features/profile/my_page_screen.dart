import 'package:flutter/material.dart';
import '../../models/app_state.dart';
import '../../models/experience.dart';
import '../../data/experience_data.dart';
import '../../services/auth_service.dart';
import '../onboarding/onboarding_profile_screen.dart';

class MyPageScreen extends StatefulWidget {
  const MyPageScreen({super.key});

  @override
  State<MyPageScreen> createState() => _MyPageScreenState();
}

class _MyPageScreenState extends State<MyPageScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
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
                  Container(
                    width: 56,
                    height: 56,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFFEEEDFE),
                    ),
                    child: const Center(
                        child: Text('🧭', style: TextStyle(fontSize: 28))),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(nickname,
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w700)),
                      Text('총 ${state.completedIds.length}개 경험 완료',
                          style: TextStyle(
                              fontSize: 13, color: Colors.grey.shade500)),
                    ],
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEEDFE),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text('⭐ ${state.points}P',
                        style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF534AB7))),
                  ),
                ],
              ),
            ),

            // ── 탭 바 ──────────────────────────────────────────────────
            TabBar(
              controller: _tab,
              tabs: const [Tab(text: '경험 도장'), Tab(text: '내 설정')],
              indicatorColor: const Color(0xFF7F77DD),
              labelColor: const Color(0xFF7F77DD),
              unselectedLabelColor: Colors.grey,
              indicatorWeight: 2,
            ),

            Expanded(
              child: TabBarView(
                controller: _tab,
                children: [
                  _StampBoardTab(),
                  _SettingsTab(onReset: () => setState(() {})),
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

class _StampBoardTab extends StatelessWidget {
  const _StampBoardTab();

  @override
  Widget build(BuildContext context) {
    final completed = AppState.i.completedIds.toSet();
    final total = allExperiences.length;
    final doneCount = allExperiences.where((e) => completed.contains(e.id)).length;

    final easy   = allExperiences.where((e) => e.difficulty == Difficulty.easy).toList();
    final medium = allExperiences.where((e) => e.difficulty == Difficulty.medium).toList();
    final hard   = allExperiences.where((e) => e.difficulty == Difficulty.hard).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 80),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── 진행 요약 ──────────────────────────────────────────────
          _ProgressBanner(done: doneCount, total: total),
          const SizedBox(height: 28),

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
          colors: [Color(0xFF7F77DD), Color(0xFF534AB7)],
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
              Text('$done / $total 완료',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700)),
              const Spacer(),
              Text('${(ratio * 100).round()}%',
                  style: const TextStyle(
                      color: Colors.white70, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 7,
              backgroundColor: Colors.white.withValues(alpha: 0.25),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(Colors.white),
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
            Text(difficultyLabel,
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: color)),
            const SizedBox(width: 8),
            Text('$doneCount/${experiences.length}',
                style: TextStyle(
                    fontSize: 13, color: Colors.grey.shade500)),
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
            color: isDone ? stampColor.withValues(alpha: 0.6) : Colors.grey.shade300,
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
                          ? Icon(Icons.check_rounded,
                              size: 20, color: stampColor)
                          : Icon(Icons.lock_outline_rounded,
                              size: 18, color: Colors.grey.shade400),
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
                      fontWeight: isDone
                          ? FontWeight.w600
                          : FontWeight.w400,
                      color: isDone
                          ? Colors.black87
                          : Colors.grey.shade500,
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
  const _SettingsTab({required this.onReset});

  @override
  Widget build(BuildContext context) {
    final userId = AuthService.currentUserId ?? '';
    final profile = AuthService.getProfile(userId);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 80),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('내 프로필',
              style:
                  TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),

          if (profile == null)
            const _EmptyProfileCard()
          else
            _ProfileCard(profile: profile),

          const SizedBox(height: 32),

          // ── 온보딩 재설정 ──────────────────────────────────────────
          const Text('설정',
              style:
                  TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          _SettingItem(
            icon: Icons.refresh_rounded,
            label: '온보딩 다시 설정하기',
            subtitle: '나이, MBTI, 직업, 취미를 다시 입력할 수 있어요',
            onTap: () => _confirmReset(context, userId),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmReset(BuildContext context, String userId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('온보딩 재설정',
            style: TextStyle(fontWeight: FontWeight.w700)),
        content: const Text(
          '나이, MBTI, 직업, 취미를 다시 입력하게 돼요.\n경험 기록과 포인트는 그대로 유지돼요.',
          style: TextStyle(fontSize: 14, height: 1.6),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('취소',
                style: TextStyle(color: Colors.grey)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF7F77DD),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
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
        pageBuilder: (_, _, _) =>
            OnboardingProfileScreen(userId: userId),
        transitionsBuilder: (_, anim, _, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 400),
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
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFEEEDFE),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(profile.mbti,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF534AB7))),
            ),
          ),
          const Divider(height: 24),
          _ProfileRow(
            label: '나이',
            child: Text('${profile.age}세',
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w500)),
          ),
          const Divider(height: 24),
          _ProfileRow(
            label: '직업',
            child: Text(profile.job,
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w500)),
          ),
          const Divider(height: 24),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('취미',
                  style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade500,
                      fontWeight: FontWeight.w500)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: profile.hobbies
                    .map((h) => Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEEEDFE),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(h,
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF534AB7))),
                        ))
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
          child: Text(label,
              style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.w500)),
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
        child: Text('프로필 정보가 없어요. 아래에서 온보딩을 설정해보세요.',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 13, color: Colors.grey.shade400, height: 1.6)),
      ),
    );
  }
}

class _SettingItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  const _SettingItem({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFEEEDFE),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon,
                  size: 20, color: const Color(0xFF7F77DD)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey.shade500)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }
}
