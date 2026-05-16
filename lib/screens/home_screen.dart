import 'package:flutter/material.dart';
import '../models/models.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppState.i;
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
                                    fontSize: 13, color: Colors.grey.shade500)),
                            const SizedBox(height: 4),
                            Text('탐험가 Lv.${state.level}',
                                style: const TextStyle(
                                    fontSize: 22, fontWeight: FontWeight.w700)),
                          ],
                        ),
                        const Spacer(),
                        // 포인트 뱃지
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color:
                            const Color(0xFF7F77DD).withOpacity(0.12),
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

            // ── 섹션 타이틀 ───────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: const Text('완료한 경험',
                    style:
                    TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 12)),

            // ── 경험 목록 ─────────────────────────────────────────────────
            if (completed.isEmpty)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(48),
                  child: Column(
                    children: [
                      Text('🗺️', style: TextStyle(fontSize: 52)),
                      SizedBox(height: 12),
                      Text('아직 탐험을 시작하지 않았어요',
                          style: TextStyle(color: Colors.grey)),
                      SizedBox(height: 4),
                      Text('하단 탐험 시작 버튼을 눌러봐요!',
                          style:
                          TextStyle(color: Colors.grey, fontSize: 13)),
                    ],
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList.separated(
                  itemCount: completed.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, i) => _CompletedCard(exp: completed[i]),
                ),
              ),

            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
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
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: [
          Text(exp.difficulty.emoji,
              style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 14),
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
            const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: exp.difficulty.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text('+${exp.difficulty.points}P',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: exp.difficulty.color)),
          ),
        ],
      ),
    );
  }
}