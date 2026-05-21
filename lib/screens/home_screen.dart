import 'package:flutter/material.dart';
import '../models/models.dart';
import '../data/experience_data.dart';
import 'verify_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppState.i;

    // ── 이번 주 추천 경험 쌍 ─────────────────────────────────────────────
    final (fitExp, dareExp) = getWeeklyPair(
      preferredKeywords: state.preferredKeywordLabels,
      completedIds: Set<String>.from(state.completedIds),
    );

    final completed =
    allExperiences.where((e) => state.completedIds.contains(e.id)).toList();

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
                            Text('안녕하세요 👋',
                                style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey.shade500)),
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

            // ── 이번 주 경험 추천 타이틀 ──────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('이번 주 경험 추천',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600)),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF7F77DD).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${currentWeekNum}주차',
                        style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF7F77DD)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                child: Text(
                  state.preferredKeywordLabels.isEmpty
                      ? '키워드를 선택하면 취향 맞춤 추천이 시작돼요'
                      : '취향 맞춤 1개 + 완전히 다른 경험 1개',
                  style: TextStyle(
                      fontSize: 13, color: Colors.grey.shade500),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 12)),

            // ── 경험 카드 2개 ──────────────────────────────────────────────
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList.separated(
                itemCount: 2,
                separatorBuilder: (_, __) => const SizedBox(height: 16),
                itemBuilder: (_, i) => _ExpCard(
                  exp: i == 0 ? fitExp : dareExp,
                  isFit: i == 0,
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 28)),

            // ── 통계 카드 3개 ──────────────────────────────────────────────
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
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
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
    final accent =
    isFit ? const Color(0xFF7F77DD) : const Color(0xFFD85A30);
    final bg =
    isFit ? const Color(0xFFEEEDFE) : const Color(0xFFFAECE7);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, 4)),
        ],
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
                    color: bg, borderRadius: BorderRadius.circular(8)),
                child: Text(
                  isFit ? '✦ 핏한 경험' : '⚡ 색다른 경험',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: accent),
                ),
              ),
              const Spacer(),
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: exp.difficulty.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${exp.difficulty.emoji} +${exp.difficulty.points}P',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: exp.difficulty.color),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(exp.title,
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(exp.subtitle,
              style:
              TextStyle(fontSize: 13, color: Colors.grey.shade500)),
          const SizedBox(height: 16),
          // ── 스탯 도트 ────────────────────────────────────────────────
          Row(
            children: [
              _StatDots(label: '체력', value: exp.energy, color: accent),
              const SizedBox(width: 16),
              _StatDots(label: '용기', value: exp.courage, color: accent),
              const SizedBox(width: 16),
              _StatDots(label: '비용', value: exp.cost, color: accent),
            ],
          ),
          const SizedBox(height: 14),
          // ── 키워드 태그 ──────────────────────────────────────────────
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: exp.matchedKeywords.take(4).map((kw) {
              return Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text('#$kw',
                    style: TextStyle(
                        fontSize: 11, color: Colors.grey.shade600)),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          // ── 선택하기 버튼 ────────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            height: 44,
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
                  style: TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}

// ── 스탯 도트 ─────────────────────────────────────────────────────────────────
class _StatDots extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  const _StatDots(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
        const SizedBox(height: 4),
        Row(
          children: List.generate(
            3,
                (i) => Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.only(right: 3),
              decoration: BoxDecoration(
                color: i < value ? color : Colors.grey.shade200,
                shape: BoxShape.circle,
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
                style: TextStyle(
                    fontSize: 12, color: Colors.grey.shade500)),
            Text('$xp / 100 XP',
                style: TextStyle(
                    fontSize: 12, color: Colors.grey.shade500)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: xp / 100,
            minHeight: 6,
            backgroundColor: Colors.grey.shade200,
            valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFF7F77DD)),
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
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: [
          Text(exp.difficulty.emoji,
              style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(exp.title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: 2),
                Text(exp.subtitle,
                    style: TextStyle(
                        fontSize: 12, color: Colors.grey.shade500)),
              ],
            ),
          ),
          Container(
            padding:
            const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text('+${exp.difficulty.points}P',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.green.shade700)),
          ),
        ],
      ),
    );
  }
}