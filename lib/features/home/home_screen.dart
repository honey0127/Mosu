import 'package:flutter/material.dart';
import '../../data/experience_data.dart';
import '../../models/experience.dart';
import '../../models/app_state.dart';
import '../../services/auth_service.dart';
import '../experience/verify_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  // ── [수정] 프로필 기반 경험 추천 ─────────────────────────────────────────
  /// 사용자의 MBTI, 취미, 나이를 기반으로 Fit / Dare 경험 한 쌍 선택
  (Experience, Experience) _pickPair() {
    final userId = AuthService.currentUserId;
    final profile = userId != null ? AuthService.getProfile(userId) : null;

    if (profile == null) {
      // 프로필 없으면 기본값
      final fit = allExperiences.firstWhere((e) => e.isFit);
      final dare = allExperiences.firstWhere((e) => !e.isFit);
      return (fit, dare);
    }

    // ── 프로필 → 선호 키워드 변환 ──────────────────────────────────────────
    final preferredKeywords = <String>{};

    // MBTI 내향/외향
    if (profile.isIntrovert) {
      preferredKeywords.add('혼자');
    } else {
      preferredKeywords.add('함께');
    }

    // MBTI 직관형(N)이면 새로운 것, 감각형(S)이면 안정적인 것
    if (profile.isIntuitive) {
      preferredKeywords.addAll(['낯선 곳', '처음 해보는', '도전적']);
    } else {
      preferredKeywords.addAll(['느린', '조용한']);
    }

    // 나이대별 선호
    if (profile.age < 25) {
      preferredKeywords.addAll(['두근두근', '도전적', '함께']);
    } else if (profile.age < 35) {
      preferredKeywords.addAll(['새벽', '몸쓰는', '낯선 곳']);
    } else {
      preferredKeywords.addAll(['느린', '조용한', '자연']);
    }

    // 취미 → 키워드 매핑
    for (final hobby in profile.hobbies) {
      final h = hobby.toLowerCase();
      if (h.contains('운동') || h.contains('헬스') || h.contains('달리기')) {
        preferredKeywords.addAll(['몸쓰는', '새벽']);
      } else if (h.contains('요리') || h.contains('베이킹')) {
        preferredKeywords.addAll(['만들기', '먹는']);
      } else if (h.contains('독서') || h.contains('책')) {
        preferredKeywords.addAll(['조용한', '혼자', '느린']);
      } else if (h.contains('여행') || h.contains('산책')) {
        preferredKeywords.addAll(['낯선 곳', '걷기', '자연']);
      } else if (h.contains('음악') || h.contains('노래') || h.contains('악기')) {
        preferredKeywords.addAll(['감성적', '혼자']);
      } else if (h.contains('그림') || h.contains('그래픽') || h.contains('디자인')) {
        preferredKeywords.addAll(['만들기', '감성적']);
      } else if (h.contains('사진') || h.contains('영상')) {
        preferredKeywords.addAll(['감성적', '낯선 곳']);
      } else if (h.contains('게임')) {
        preferredKeywords.addAll(['혼자', '새벽']);
      } else if (h.contains('등산') || h.contains('클라이밍')) {
        preferredKeywords.addAll(['몸쓰는', '자연', '도전적']);
      }
    }

    // ── Fit 선택: 선호 키워드 오버랩 최대 ───────────────────────────────
    Experience? fit;
    int fitScore = -1;

    for (final exp in allExperiences.where((e) => e.isFit)) {
      final overlap =
          exp.matchedKeywords.where(preferredKeywords.contains).length;
      if (overlap > fitScore) {
        fitScore = overlap;
        fit = exp;
      }
    }

    // ── Dare 선택: 선호 키워드 오버랩 최소 (의외의 경험) ────────────────
    Experience? dare;
    int dareScore = 999;

    for (final exp in allExperiences.where((e) => !e.isFit)) {
      final overlap =
          exp.matchedKeywords.where(preferredKeywords.contains).length;
      if (overlap < dareScore) {
        dareScore = overlap;
        dare = exp;
      }
    }

    return (
    fit ?? allExperiences.firstWhere((e) => e.isFit),
    dare ?? allExperiences.firstWhere((e) => !e.isFit),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = AppState.i;
    final userId = AuthService.currentUserId ?? '';
    final (fitExp, dareExp) = _pickPair();
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
                            color: const Color(0xFF7F77DD)
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
                                      color: Color(0xFF534AB7))),
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

            // ── 경험 카드 2개 ─────────────────────────────────────────────
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList.separated(
                itemCount: 2,
                separatorBuilder: (_, _) => const SizedBox(height: 16),
                itemBuilder: (_, i) => _ExpCard(
                  exp: i == 0 ? fitExp : dareExp,
                  isFit: i == 0,
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
  const _ExpCard({required this.exp, required this.isFit});

  @override
  Widget build(BuildContext context) {
    final accent = isFit ? const Color(0xFF7F77DD) : const Color(0xFFD85A30);
    final bg = isFit
        ? const Color(0xFFEEEDFE)
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
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => VerifyScreen(exp: exp)),
              ),
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
            const AlwaysStoppedAnimation<Color>(Color(0xFF7F77DD)),
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
              color: const Color(0xFFEEEDFE),
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
                  color: Color(0xFF534AB7))),
        ],
      ),
    );
  }
}