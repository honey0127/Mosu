import 'package:flutter/material.dart';
import '../../data/experience_data.dart';
import '../../models/experience.dart';
import '../../models/app_state.dart';
import '../../services/auth_service.dart';
import '../experience/verify_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  void _refresh() {
    if (mounted) setState(() {});
  }

  // ── 주간 경험 추천 (완료된 경험 제외, 1주마다 자동 갱신) ───────────────────
  (Experience?, Experience?) _pickPair() {
    final state = AppState.i;
    final userId = AuthService.currentUserId ?? '';
    final currentWeek = AuthService.getWeekNumber(userId);

    // 주차가 바뀌었거나 재선택 예약(-1)이면 새 페어 배정
    if (state.homeWeekNumber != currentWeek) {
      final exclude = Set<String>.from(state.homeWeekExcluded);
      final (newFit, newDare) = _selectWeeklyPair(userId, currentWeek, exclude: exclude);
      state.setWeeklyPair(
        weekNum: currentWeek,
        fitId: newFit?.id,
        dareId: newDare?.id,
      );
      state.homeWeekExcluded = {}; // 선택 완료 후 초기화
    }

    // 이번 주 완료 + 전체 완료 경험은 숨김
    final weekDone = state.homeWeekCompletedIds;
    final allDone  = state.completedIds.toSet();

    Experience? fitExp;
    final fitId = state.homeWeekFitId;
    if (fitId != null && !weekDone.contains(fitId) && !allDone.contains(fitId)) {
      final found = allExperiences.where((e) => e.id == fitId);
      if (found.isNotEmpty) fitExp = found.first;
    }

    Experience? dareExp;
    final dareId = state.homeWeekDareId;
    if (dareId != null && !weekDone.contains(dareId) && !allDone.contains(dareId)) {
      final found = allExperiences.where((e) => e.id == dareId);
      if (found.isNotEmpty) dareExp = found.first;
    }

    return (fitExp, dareExp);
  }

  /// 난이도별 보너스 점수 — 쉬움 우선이되 키워드 매칭이 충분하면 보통/어려움도 추천
  static int _diffBonus(Difficulty d) => switch (d) {
    Difficulty.easy   => 3,
    Difficulty.medium => 2,
    Difficulty.hard   => 1,
  };

  /// 온보딩 프로필 + 키워드 선택에서 선호 키워드 Set 구성
  static Set<String> _buildPreferred(String userId) {
    final preferred = <String>{};

    // 1) 사용자가 직접 선택한 키워드 (keyword_selection_screen)
    preferred.addAll(AuthService.getUserKeywords(userId));

    // 2) 온보딩 프로필에서 유추한 키워드
    final profile = AuthService.getProfile(userId);
    if (profile == null) return preferred;

    if (profile.isIntrovert) {
      preferred.add('혼자');
    } else {
      preferred.add('함께');
    }
    if (profile.isIntuitive) {
      preferred.addAll(['낯선 곳', '처음 해보는', '도전적']);
    } else {
      preferred.addAll(['느린', '조용한']);
    }
    if (profile.age < 25) {
      preferred.addAll(['두근두근', '도전적', '함께']);
    } else if (profile.age < 35) {
      preferred.addAll(['새벽', '몸쓰는', '낯선 곳']);
    } else {
      preferred.addAll(['느린', '조용한', '자연']);
    }
    for (final hobby in profile.hobbies) {
      final h = hobby.toLowerCase();
      if (h.contains('운동') || h.contains('헬스') || h.contains('달리기')) {
        preferred.addAll(['몸쓰는', '새벽']);
      } else if (h.contains('요리') || h.contains('베이킹')) {
        preferred.addAll(['만들기', '먹는']);
      } else if (h.contains('독서') || h.contains('책')) {
        preferred.addAll(['조용한', '혼자', '느린']);
      } else if (h.contains('여행') || h.contains('산책')) {
        preferred.addAll(['낯선 곳', '걷기', '자연']);
      } else if (h.contains('음악') || h.contains('노래') || h.contains('악기')) {
        preferred.addAll(['감성적', '혼자']);
      } else if (h.contains('그림') || h.contains('그래픽') || h.contains('디자인')) {
        preferred.addAll(['만들기', '감성적']);
      } else if (h.contains('사진') || h.contains('영상')) {
        preferred.addAll(['감성적', '낯선 곳']);
      } else if (h.contains('게임')) {
        preferred.addAll(['혼자', '새벽']);
      } else if (h.contains('등산') || h.contains('클라이밍')) {
        preferred.addAll(['몸쓰는', '자연', '도전적']);
      }
    }
    return preferred;
  }

  /// 상위 후보 중 weekNum으로 로테이션하여 매주 다른 경험을 제공
  static Experience? _pickTop(List<(Experience, int)> scored, int weekNum) {
    if (scored.isEmpty) return null;
    // 최고 점수에서 1점 이내를 "동급 상위"로 묶어 로테이션
    final best = scored.first.$2;
    final topTier = scored.where((e) => e.$2 >= best - 1).toList();
    return topTier[weekNum % topTier.length].$1;
  }

  /// 주차별 맞춤/도전 경험 쌍 선택
  /// - 맞춤(Fit): 키워드 겹침 많음 + 쉬움 우선
  /// - 도전(Dare): 키워드 겹침 적음(의외) + 쉬움 우선
  (Experience?, Experience?) _selectWeeklyPair(
    String userId,
    int weekNum, {
    Set<String> exclude = const {},
  }) {
    // 명시적 제외 + 전체 완료 경험은 후보에서 빼기
    final allDone = AppState.i.completedIds.toSet();
    final skip = {...exclude, ...allDone};

    final fitCandidates = allExperiences
        .where((e) => e.isFit && !skip.contains(e.id))
        .toList();
    final dareCandidates = allExperiences
        .where((e) => !e.isFit && !skip.contains(e.id))
        .toList();

    if (fitCandidates.isEmpty && dareCandidates.isEmpty) return (null, null);

    final preferred = _buildPreferred(userId);

    // 프로필도 키워드도 없으면 쉬움 우선 단순 로테이션
    if (preferred.isEmpty) {
      final easyFit  = fitCandidates.where((e) => e.difficulty == Difficulty.easy).toList();
      final easyDare = dareCandidates.where((e) => e.difficulty == Difficulty.easy).toList();
      return (
        (easyFit.isNotEmpty ? easyFit : fitCandidates)[weekNum % (easyFit.isNotEmpty ? easyFit.length : fitCandidates.length)],
        (easyDare.isNotEmpty ? easyDare : dareCandidates)[weekNum % (easyDare.isNotEmpty ? easyDare.length : dareCandidates.length)],
      );
    }

    // ── 맞춤(Fit): 키워드 겹침 × 2 + 난이도 보너스 (높을수록 좋음) ──────────
    final scoredFit = fitCandidates
        .map((e) {
          final overlap = e.matchedKeywords.where(preferred.contains).length;
          return (e, overlap * 2 + _diffBonus(e.difficulty));
        })
        .toList()
      ..sort((a, b) => b.$2.compareTo(a.$2));

    // ── 도전(Dare): 겹침 적을수록 좋음 → 역산 + 난이도 보너스 ───────────────
    final scoredDare = dareCandidates
        .map((e) {
          final overlap = e.matchedKeywords.where(preferred.contains).length;
          return (e, -overlap * 2 + _diffBonus(e.difficulty));
        })
        .toList()
      ..sort((a, b) => b.$2.compareTo(a.$2));

    return (_pickTop(scoredFit, weekNum), _pickTop(scoredDare, weekNum));
  }

  @override
  Widget build(BuildContext context) {
    final state = AppState.i;
    final userId = AuthService.currentUserId ?? '';
    final (fitExp, dareExp) = _pickPair();
    final recCards = [
      if (fitExp != null) (fitExp, true),
      if (dareExp != null) (dareExp, false),
    ];
    final completed =
    allExperiences.where((e) => state.completedIds.contains(e.id)).toList();

    // ── [수정] 가입일 기준 주차 계산 ─────────────────────────────────────
    final weekNumber = AuthService.getWeekNumber(userId);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLow,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ── 상단 헤더 ──────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // [수정] 연간 주차 → 가입일 기준 주차
                            Text(
                              '$weekNumber주차 탐험 중 🗺️',
                              style: TextStyle(
                                  fontSize: 13, color: Colors.grey.shade500),
                            ),
                            const SizedBox(height: 4),
                            Text('탐험가 Lv.${state.level}',
                                style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w700)),
                          ],
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF7DB879)
                                .withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              const Text('⭐',
                                  style: TextStyle(fontSize: 16)),
                              const SizedBox(width: 6),
                              Text('${state.points}P',
                                  style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF5A9A4A))),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _LevelBar(xp: state.xpInLevel),
                    const SizedBox(height: 28),
                  ],
                ),
              ),
            ),

            // ── 오늘의 경험 추천 타이틀 ───────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('오늘의 경험 추천',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text(
                      // [수정] 프로필 기반 추천임을 표시
                      AuthService.getProfile(userId) != null
                          ? '내 취향을 분석한 맞춤 추천이에요'
                          : '두 가지 경험 중 하나를 선택해봐요',
                      style: TextStyle(
                          fontSize: 13, color: Colors.grey.shade500),
                    ),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 16)),

            // ── 경험 카드 (완료된 경험 제외) ─────────────────────────────
            if (recCards.isNotEmpty)
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList.separated(
                  itemCount: recCards.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 16),
                  itemBuilder: (_, i) => _ExpCard(
                    exp: recCards[i].$1,
                    isFit: recCards[i].$2,
                    onReturn: _refresh,
                  ),
                ),
              )
            else
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade100),
                    ),
                    child: Column(
                      children: [
                        const Text('🎉', style: TextStyle(fontSize: 40)),
                        const SizedBox(height: 12),
                        const Text('모든 경험을 완료했어요!',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 6),
                        Text('정말 대단해요. 새로운 경험이 곧 추가될 예정이에요.',
                            style: TextStyle(
                                fontSize: 13, color: Colors.grey.shade500),
                            textAlign: TextAlign.center),
                      ],
                    ),
                  ),
                ),
              ),

            const SliverToBoxAdapter(child: SizedBox(height: 28)),

            // ── 통계 카드 3개 ─────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    _StatCard(
                        label: '완료 경험',
                        value: '${state.completedIds.length}개',
                        emoji: '✅'),
                    const SizedBox(width: 12),
                    _StatCard(
                        label: '총 포인트',
                        value: '${state.totalEarned}P',
                        emoji: '⭐'),
                    const SizedBox(width: 12),
                    _StatCard(
                        label: '잠금 해제',
                        value: '${state.unlockedIds.length}개',
                        emoji: '🎁'),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 28)),

            // ── 완료한 경험 ───────────────────────────────────────────────
            if (completed.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: const Text('완료한 경험',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 12)),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList.separated(
                  itemCount: completed.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (_, i) => _CompletedCard(exp: completed[i]),
                ),
              ),
            ],

            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }
}

// ── 경험 추천 카드 ────────────────────────────────────────────────────────────
class _ExpCard extends StatelessWidget {
  final Experience exp;
  final bool isFit;
  final VoidCallback? onReturn;
  const _ExpCard({required this.exp, required this.isFit, this.onReturn});

  @override
  Widget build(BuildContext context) {
    final accent = isFit ? const Color(0xFF7DB879) : const Color(0xFFD85A30);
    final bg = isFit
        ? const Color(0xFFE8F3E3)
        : const Color(0xFFFEEDE8);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isFit ? '✨ 맞춤' : '🔥 도전',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: accent),
                ),
              ),
              const Spacer(),
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  exp.difficulty.label,
                  style: TextStyle(
                      fontSize: 11, color: Colors.grey.shade600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(exp.title,
              style: const TextStyle(
                  fontSize: 17, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(exp.subtitle,
              style:
              TextStyle(fontSize: 13, color: Colors.grey.shade500)),
          const SizedBox(height: 14),
          Row(
            children: [
              _DotStat(label: '체력', value: exp.energy, color: accent),
              const SizedBox(width: 20),
              _DotStat(label: '용기', value: exp.courage, color: accent),
              const SizedBox(width: 20),
              _DotStat(label: '비용', value: exp.cost, color: accent),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: exp.matchedKeywords
                .map((kw) => Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text('#$kw',
                  style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600)),
            ))
                .toList(),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: accent,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => VerifyScreen(exp: exp)),
                );
                onReturn?.call();
              },
              child: const Text('이 경험 선택하기',
                  style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}

// ── 점 지표 ───────────────────────────────────────────────────────────────────
class _DotStat extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  const _DotStat(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
        const SizedBox(height: 5),
        Row(
          children: List.generate(
            3,
                (i) => Container(
              width: 10,
              height: 10,
              margin: const EdgeInsets.only(right: 4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: i < value ? color : Colors.grey.shade200,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── 레벨 바 ───────────────────────────────────────────────────────────────────
class _LevelBar extends StatelessWidget {
  final int xp;
  const _LevelBar({required this.xp});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('다음 레벨까지',
                style:
                TextStyle(fontSize: 12, color: Colors.grey.shade500)),
            Text('$xp / 100 XP',
                style:
                TextStyle(fontSize: 12, color: Colors.grey.shade500)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: xp / 100,
            minHeight: 6,
            backgroundColor: Colors.grey.shade200,
            valueColor:
            const AlwaysStoppedAnimation<Color>(Color(0xFF7DB879)),
          ),
        ),
      ],
    );
  }
}

// ── 통계 카드 ─────────────────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String emoji;
  const _StatCard(
      {required this.label, required this.value, required this.emoji});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 8),
            Text(value,
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w700)),
            const SizedBox(height: 2),
            Text(label,
                style: TextStyle(
                    fontSize: 11, color: Colors.grey.shade500)),
          ],
        ),
      ),
    );
  }
}

// ── 완료 경험 카드 ────────────────────────────────────────────────────────────
class _CompletedCard extends StatelessWidget {
  final Experience exp;
  const _CompletedCard({required this.exp});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F3E3),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Center(
                child: Text('✅', style: TextStyle(fontSize: 18))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(exp.title,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(exp.subtitle,
                    style: TextStyle(
                        fontSize: 12, color: Colors.grey.shade500)),
              ],
            ),
          ),
          Text('+${exp.difficulty.points}P',
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF5A9A4A))),
        ],
      ),
    );
  }
}