import 'package:flutter/material.dart';
import '../../data/experience_data.dart';
import '../../models/app_state.dart';
import '../../models/experience.dart';
import '../../models/keyword.dart';
import '../../services/auth_service.dart';

/// 캘린더 탭 하단 - 선택 키워드 + 완료 경험 + 온보딩 프로필을 종합해
/// "당신은 이런 사람이에요" 형식의 특징 리포트를 보여줌.
class GrowthReportCard extends StatelessWidget {
  const GrowthReportCard({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = AuthService.currentUserId ?? '';
    final profile = AuthService.getProfile(userId);
    final state = AppState.i;

    if (state.completedIds.isEmpty) return const SizedBox.shrink();

    final selectedKeywordIds = AuthService.getUserKeywords(userId);
    final selectedKeywords =
        allKeywords.where((k) => selectedKeywordIds.contains(k.id)).toList();

    final completedExps =
        allExperiences.where((e) => state.completedIds.contains(e.id)).toList();

    final messages = _buildMessages(
      profile: profile,
      selectedKeywords: selectedKeywords,
      completedExps: completedExps,
      categoryCounts: state.categoryCounts,
    );

    if (messages.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(top: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF0F7EE), Color(0xFFE8F4E5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF7DB879).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF7DB879).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text('\u{1F9ED}',
                    style: TextStyle(fontSize: 20)),
              ),
              const SizedBox(width: 12),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '나는 이런 사람',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF3A6B36),
                    ),
                  ),
                  Text(
                    '경험으로 발견한 나의 특징',
                    style: TextStyle(fontSize: 12, color: Color(0xFF7DB879)),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...messages.map((msg) => _MessageRow(message: msg)),
        ],
      ),
    );
  }

  List<_ReportMessage> _buildMessages({
    required UserProfile? profile,
    required List<Keyword> selectedKeywords,
    required List<Experience> completedExps,
    required Map<ExperienceCategory, int> categoryCounts,
  }) {
    final messages = <_ReportMessage>[];
    final labels = selectedKeywords.map((k) => k.label).toSet();

    // ── 1. 가장 많이 한 경험 카테고리로 핵심 특징 도출 ───────────────────────
    final topCats = _topCategories(categoryCounts, n: 2);
    if (topCats.isNotEmpty) {
      final main = topCats.first;
      final sub = topCats.length > 1 ? topCats[1] : null;
      final catText = sub != null
          ? '${main.label}과(와) ${sub.label}'
          : main.label;
      messages.add(_ReportMessage(
        emoji: main.emoji,
        text: '$catText 경험을 즐겨 하는 분이에요. '
            '완료한 ${completedExps.length}개의 경험 중 이 분야가 가장 많아요.',
      ));
    }

    // ── 2. 선택 키워드 기반 분위기·스타일 ──────────────────────────────────
    final moodLabels = labels
        .where((l) => ['느린', '감성적', '조용한', '설레는', '몽환적', '빠른'].contains(l))
        .toList();
    final placeLabels = labels
        .where((l) => ['낯선 곳', '도심', '자연', '카페', '바닷가', '골목'].contains(l))
        .toList();

    if (moodLabels.isNotEmpty || placeLabels.isNotEmpty) {
      final moodPart = moodLabels.isNotEmpty
          ? moodLabels.take(2).join(', ') + ' 분위기'
          : null;
      final placePart = placeLabels.isNotEmpty
          ? placeLabels.take(2).join(', ') + ' 공간'
          : null;
      final combined = [moodPart, placePart].whereType<String>().join('과(와) ');
      if (combined.isNotEmpty) {
        messages.add(_ReportMessage(
          emoji: '\u{1F3DE}️',
          text: '$combined 을(를) 좋아하는 취향을 가지고 있어요.',
        ));
      }
    }

    // ── 3. 혼자 vs 함께 성향 ────────────────────────────────────────────────
    final likesAlone = labels.contains('혼자');
    final likesTogether = labels.contains('함께') || labels.contains('소란스러운');
    if (likesAlone && !likesTogether) {
      messages.add(_ReportMessage(
        emoji: '\u{1F6B6}',
        text: '혼자만의 시간을 소중히 여기는 분이에요. '
            '조용한 환경에서 집중력과 깊이 있는 사색을 즐기시는 것 같아요.',
      ));
    } else if (likesTogether && !likesAlone) {
      messages.add(_ReportMessage(
        emoji: '\u{1F46B}',
        text: '함께하는 경험에서 에너지를 얻는 분이에요. '
            '사람들과 나누고 연결되는 순간을 좋아하시는 것 같아요.',
      ));
    }

    // ── 4. 도전 성향 (난이도 비율로 판단) ─────────────────────────────────
    final easy = completedExps.where((e) => e.difficulty == Difficulty.easy).length;
    final hard = completedExps.where((e) => e.difficulty == Difficulty.hard).length;
    final total = completedExps.length;

    if (total >= 3 && hard >= 2) {
      messages.add(_ReportMessage(
        emoji: '\u{1F525}',
        text: '완료한 경험의 ${((hard / total) * 100).round()}%가 높은 난이도예요. '
            '어려운 도전일수록 더 빛나는 타입이에요.',
      ));
    } else if (total >= 3 && easy / total >= 0.7) {
      messages.add(_ReportMessage(
        emoji: '\u{1F33F}',
        text: '꾸준하고 안정적인 경험을 선호하는 분이에요. '
            '작은 실천을 쌓아가는 지속력이 남다른 것 같아요.',
      ));
    }

    // ── 5. 시간대 특징 ──────────────────────────────────────────────────────
    final timeLabels = labels
        .where((l) => ['새벽', '이른 아침', '낮', '저녁', '주말'].contains(l))
        .toList();
    if (timeLabels.isNotEmpty) {
      final timePart = timeLabels.take(2).join(', ');
      messages.add(_ReportMessage(
        emoji: '\u{23F0}',
        text: '$timePart 시간대를 즐기는 분이에요. '
            '그 시간만의 분위기를 잘 알고 있는 것 같아요.',
      ));
    }

    // ── 6. MBTI + 완료 경험 조합 특징 ──────────────────────────────────────
    if (profile != null && completedExps.isNotEmpty) {
      final mbti = profile.mbti;
      final isN = mbti.length > 1 && mbti[1] == 'N';
      final natureCount = categoryCounts[ExperienceCategory.nature] ?? 0;
      final creativeCount = categoryCounts[ExperienceCategory.creative] ?? 0;
      if (isN && (natureCount + creativeCount) >= 2) {
        messages.add(_ReportMessage(
          emoji: '\u{1F4AB}',
          text: '상상력과 감각을 자극하는 경험을 좋아하는 분이에요. '
              '자연과 창작 경험이 유독 잘 어울리는 타입이에요.',
        ));
      }
    }

    // ── 7. isFit(편안한) vs !isFit(도전적) 비율 ──────────────────────────
    final fitCount = completedExps.where((e) => e.isFit).length;
    final dareCount = completedExps.where((e) => !e.isFit).length;
    if (completedExps.length >= 4) {
      if (dareCount > fitCount) {
        messages.add(_ReportMessage(
          emoji: '\u{1F9ED}',
          text: '낯설고 새로운 경험을 편안한 경험보다 더 많이 선택하셨어요. '
              '틀을 벗어나는 걸 즐기는 탐험형 성격이에요.',
        ));
      } else if (fitCount > dareCount * 2) {
        messages.add(_ReportMessage(
          emoji: '\u{1F3E0}',
          text: '나에게 맞는 경험을 잘 알고 선택하는 분이에요. '
              '자신의 취향과 페이스를 존중하는 생활 방식을 가지고 계세요.',
        ));
      }
    }

    return messages.take(3).toList();
  }

  List<ExperienceCategory> _topCategories(
      Map<ExperienceCategory, int> counts, {required int n}) {
    if (counts.isEmpty) return [];
    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(n).map((e) => e.key).toList();
  }
}

class _ReportMessage {
  final String emoji;
  final String text;
  const _ReportMessage({required this.emoji, required this.text});
}

class _MessageRow extends StatelessWidget {
  final _ReportMessage message;
  const _MessageRow({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(message.emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message.text,
              style: const TextStyle(
                fontSize: 13,
                height: 1.55,
                color: Color(0xFF3A4A38),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
