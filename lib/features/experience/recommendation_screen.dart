import 'package:flutter/material.dart';
import '../../models/experience.dart';
import '../../models/app_state.dart';
import '../../models/keyword.dart';
import '../../data/experience_data.dart';
import 'verify_screen.dart';

class RecommendationScreen extends StatelessWidget {
  final List<String> selectedKeywordIds;

  const RecommendationScreen({super.key, required this.selectedKeywordIds});

  /// 선택한 키워드를 AppState에 저장하고 이번 주 추천 쌍 반환
  (Experience, Experience) _pickPair() {
    // 선택한 키워드 레이블 추출
    final labels = allKeywords
        .where((k) => selectedKeywordIds.contains(k.id))
        .map((k) => k.label)
        .toList();

    // AppState에 저장 → 홈 화면에서도 동일한 취향 기반 추천 가능
    AppState.i.preferredKeywordLabels = labels;

    return getWeeklyPair(
      preferredKeywords: labels,
      completedIds: Set<String>.from(AppState.i.completedIds),
    );
  }

  @override
  Widget build(BuildContext context) {
    final (fitExp, dareExp) = _pickPair();

    return Scaffold(
      appBar: AppBar(
        title: const Text('오늘의 추천',
            style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Text(
                '선택한 키워드 기반으로\n두 가지 경험을 찾았어요 👀',
                style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                    height: 1.6),
              ),
              const SizedBox(height: 8),
              // 선택한 키워드 미리보기
              if (selectedKeywordIds.isNotEmpty)
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: allKeywords
                      .where((k) => selectedKeywordIds.contains(k.id))
                      .map((k) => Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F3E3),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${k.emoji} ${k.label}',
                      style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF7DB879),
                          fontWeight: FontWeight.w500),
                    ),
                  ))
                      .toList(),
                ),
              const SizedBox(height: 24),
              _ExperienceCard(exp: fitExp, cardType: _CardType.fit),
              const SizedBox(height: 16),
              _ExperienceCard(exp: dareExp, cardType: _CardType.dare),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

enum _CardType { fit, dare }

// ─── 경험 카드 ────────────────────────────────────────────────────────────────
class _ExperienceCard extends StatelessWidget {
  final Experience exp;
  final _CardType cardType;

  const _ExperienceCard({required this.exp, required this.cardType});

  @override
  Widget build(BuildContext context) {
    final isFit = cardType == _CardType.fit;
    final accent =
    isFit ? const Color(0xFF7DB879) : const Color(0xFFD85A30);
    final bg =
    isFit ? const Color(0xFFE8F3E3) : const Color(0xFFFAECE7);

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
          // ── 배지 행 ────────────────────────────────────────────────────
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
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
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
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
          // ── 스탯 도트 ──────────────────────────────────────────────────
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
          // ── 키워드 태그 ────────────────────────────────────────────────
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
          // ── 선택하기 버튼 ──────────────────────────────────────────────
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
            style:
            TextStyle(fontSize: 10, color: Colors.grey.shade500)),
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