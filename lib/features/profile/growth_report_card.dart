import 'package:flutter/material.dart';
import '../../data/experience_data.dart';
import '../../models/app_state.dart';
import '../../models/experience.dart';
import '../../models/keyword.dart';
import '../../services/auth_service.dart';

class GrowthReportCard extends StatelessWidget {
  const GrowthReportCard({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = AuthService.currentUserId ?? '';
    final profile = AuthService.getProfile(userId);
    final state = AppState.i;

    if (state.completedIds.isEmpty) return const SizedBox.shrink();

    final selectedKeywordIds = AuthService.getUserKeywords(userId);
    final selectedKeywords = allKeywords
        .where((k) => selectedKeywordIds.contains(k.id))
        .toList();

    final completedExps = allExperiences
        .where((e) => state.completedIds.contains(e.id))
        .toList();

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
        border: Border.all(
          color: const Color(0xFF7DB879).withOpacity(0.3),
        ),
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
                child: const Text(
                  '\u{1F331}',
                  style: TextStyle(fontSize: 20),
                ),
              ),
              const SizedBox(width: 12),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '나의 성장 리포트',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF3A6B36),
                    ),
                  ),
                  Text(
                    '경험이 만들어낸 변화',
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

  List<_GrowthMessage> _buildMessages({
    required UserProfile? profile,
    required List<Keyword> selectedKeywords,
    required List<Experience> completedExps,
    required Map<ExperienceCategory, int> categoryCounts,
  }) {
    final messages = <_GrowthMessage>[];
    if (completedExps.isEmpty) return messages;

    final selectedLabels = selectedKeywords.map((k) => k.label).toSet();
    final selectedCategories = selectedKeywords.map((k) => k.category).toSet();

    final wasIntrovert = profile != null && profile.mbti[0] == 'I';
    final preferredAlone =
        selectedLabels.contains('혼자') ||
        selectedLabels.contains('조용한');
    final socialCount = categoryCounts[ExperienceCategory.social] ?? 0;
    final travelCount = categoryCounts[ExperienceCategory.travel] ?? 0;

    if ((wasIntrovert || preferredAlone) && socialCount + travelCount >= 2) {
      final topSocial = completedExps
          .where((e) =>
              e.category == ExperienceCategory.social ||
              e.category == ExperienceCategory.travel)
          .firstOrNull;
      final expTitle = topSocial?.title ?? '새로운 만남';
      final introLabel = wasIntrovert
          ? '내향적인 성향이셨지만'
          : '혼자를 좋아하셨지만';
      messages.add(_GrowthMessage(
        emoji: '\u{1F91D}',
        text: '$introLabel 「$expTitle」 등의 경험을 통해 '
            '사람과 연결되는 즐거움을 발견하셨어요.',
      ));
    }

    final preferredSafe = selectedLabels.contains('느린') ||
        selectedLabels.contains('조용한') ||
        !selectedCategories.contains('challenge');
    final hardCount =
        completedExps.where((e) => e.difficulty == Difficulty.hard).length;

    if (preferredSafe && hardCount >= 1) {
      final hardExp = completedExps
          .where((e) => e.difficulty == Difficulty.hard)
          .firstOrNull;
      final hardTitle =
          hardExp?.title ?? '어려운 도전';
      messages.add(_GrowthMessage(
        emoji: '\u{1F525}',
        text: '평소엔 안정적인 루틴을 선호하셨는데 '
            '「$hardTitle」 같은 높은 난이도 경험에도 '
            '도전하며 용기 있는 모습을 보여주셨어요.',
      ));
    }

    final preferredFamiliar =
        !selectedLabels.contains('낯선 곳') &&
        !selectedLabels.contains('낯선 사람') &&
        !selectedLabels.contains('무계획');
    final dareExps = completedExps.where((e) => !e.isFit).length;

    if (preferredFamiliar && dareExps >= 2) {
      final dareExp =
          completedExps.where((e) => !e.isFit).firstOrNull;
      final dareTitle =
          dareExp?.title ?? '낯선 경험';
      messages.add(_GrowthMessage(
        emoji: '\u{1F5FA}️',
        text: '익숙한 것을 선호하셨지만 '
            '「$dareTitle」처럼 '
            '예상치 못한 경험들을 통해 탐험가 기질이 커지고 있어요.',
      ));
    }

    final likedGolmok =
        selectedLabels.contains('골목');
    final likedNature = selectedLabels.contains('자연') ||
        selectedLabels.contains('바닷가');
    final natureCount = categoryCounts[ExperienceCategory.nature] ?? 0;

    if (likedGolmok && natureCount >= 1) {
      messages.add(_GrowthMessage(
        emoji: '\u{1F33F}',
        text: '골목길을 좋아하시는 분이 자연 속 경험까지 넓혀가고 계세요. '
            '공간의 경계가 점점 넓어지고 있어요.',
      ));
    } else if (likedNature && socialCount >= 2) {
      messages.add(_GrowthMessage(
        emoji: '\u{1F30A}',
        text: '자연과 혼자만의 시간을 즐기시던 분이 '
            '사람들과 함께하는 경험도 쌓아가고 계세요.',
      ));
    }

    final creativeCount =
        (categoryCounts[ExperienceCategory.creative] ?? 0) +
        (categoryCounts[ExperienceCategory.hobby] ?? 0);
    final likedCreative = selectedLabels.contains('만들기') ||
        selectedLabels.contains('감성적') ||
        (profile?.hobbies.any((h) =>
                h.contains('그림') ||
                h.contains('음악') ||
                h.contains('공예')) ??
            false);

    if (!likedCreative && creativeCount >= 2) {
      messages.add(_GrowthMessage(
        emoji: '\u{1F3A8}',
        text: '처음엔 창작 활동에 관심이 없으셨지만 '
            '경험을 통해 만들고 표현하는 즐거움을 찾아가고 계세요.',
      ));
    }

    if (messages.isEmpty) {
      final mostDone = _topCategory(categoryCounts);
      if (mostDone != null) {
        messages.add(_GrowthMessage(
          emoji: mostDone.emoji,
          text: '${completedExps.length}개의 경험을 완료하며 꾸준히 성장 중이에요. '
              '특히 ${mostDone.label} 분야에서 자신만의 색깔을 발견하고 계세요.',
        ));
      }
    }

    return messages.take(3).toList();
  }

  ExperienceCategory? _topCategory(Map<ExperienceCategory, int> counts) {
    if (counts.isEmpty) return null;
    return counts.entries
        .reduce((a, b) => a.value >= b.value ? a : b)
        .key;
  }
}

class _GrowthMessage {
  final String emoji;
  final String text;
  const _GrowthMessage({required this.emoji, required this.text});
}

class _MessageRow extends StatelessWidget {
  final _GrowthMessage message;
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
