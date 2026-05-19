import 'dart:math';
import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/auth_service.dart';
import 'main_shell.dart';

class OnboardingKeywordScreen extends StatefulWidget {
  final String userId;
  const OnboardingKeywordScreen({super.key, required this.userId});

  @override
  State<OnboardingKeywordScreen> createState() =>
      _OnboardingKeywordScreenState();
}

class _OnboardingKeywordScreenState extends State<OnboardingKeywordScreen> {
  final Set<String> _selected = {};
  static const int _minSelect = 5;

  void _toggle(String id) => setState(() {
    _selected.contains(id) ? _selected.remove(id) : _selected.add(id);
  });

  void _finish() {
    AuthService.completeOnboarding(widget.userId, _selected.toList());
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const MainShell()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final remaining = _minSelect - _selected.length;
    final canProceed = _selected.length >= _minSelect;

    return Scaffold(
      backgroundColor: const Color(0xFF111118),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── 헤더 ────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '어떤 경험이\n끌리나요?',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '마음에 드는 키워드를 눌러봐요  ·  스크롤해서 더 보기',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.45),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '아무거나 골라봐요 ✨',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.45),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '${_selected.length}개 선택됨 (최소 $_minSelect개)',
                    style: TextStyle(
                      fontSize: 12,
                      color: canProceed
                          ? const Color(0xFF7EDFA0)
                          : Colors.white.withValues(alpha: 0.35),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── 키워드 칩 목록 ─────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                child: _StaggeredChipGrid(
                  keywords: allKeywords,
                  selected: _selected,
                  onTap: _toggle,
                ),
              ),
            ),

            // ── 하단 버튼 영역 ─────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: canProceed
                            ? const Color(0xFF5FD68A)
                            : const Color(0xFF2A2A3A),
                        foregroundColor: canProceed
                            ? const Color(0xFF0D1F14)
                            : Colors.white38,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: canProceed ? _finish : null,
                      child: Text(
                        canProceed ? '탐험 시작하기 →' : '$remaining개 더 선택해요',
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: _finish,
                    child: Text(
                      '건너뛰기',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.35),
                        fontSize: 14,
                      ),
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

// ─── 지그재그 칩 그리드 ──────────────────────────────────────────────────────
class _StaggeredChipGrid extends StatelessWidget {
  final List<Keyword> keywords;
  final Set<String> selected;
  final void Function(String) onTap;

  const _StaggeredChipGrid({
    required this.keywords,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final rows = _buildRows(keywords);
    int chipIdx = 0;
    final rowWidgets = <Widget>[];

    for (int r = 0; r < rows.length; r++) {
      rowWidgets.add(
        Padding(
          padding: EdgeInsets.only(left: (r % 2 == 1) ? 20.0 : 0.0),
          child: Wrap(
            spacing: 10,
            children: rows[r].map((kw) {
              return _OnboardingChip(
                key: ValueKey(kw.id),
                label: kw.label,
                isSelected: selected.contains(kw.id),
                onTap: () => onTap(kw.id),
                index: chipIdx++,
              );
            }).toList(),
          ),
        ),
      );
      rowWidgets.add(const SizedBox(height: 12));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: rowWidgets,
    );
  }

  List<List<Keyword>> _buildRows(List<Keyword> kws) {
    final rng = Random(7);
    final result = <List<Keyword>>[];
    int i = 0;
    while (i < kws.length) {
      final count = 3 + rng.nextInt(2);
      result.add(kws.sublist(i, min(i + count, kws.length)));
      i += count;
    }
    return result;
  }
}

// ─── 온보딩용 칩 (다크 테마) ─────────────────────────────────────────────────
class _OnboardingChip extends StatefulWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final int index;

  const _OnboardingChip({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.index,
  });

  @override
  State<_OnboardingChip> createState() => _OnboardingChipState();
}

class _OnboardingChipState extends State<_OnboardingChip>
    with SingleTickerProviderStateMixin {
  late AnimationController _floatCtrl;

  @override
  void initState() {
    super.initState();
    _floatCtrl = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1800 + (widget.index % 8) * 180),
    );
    _floatCtrl.value = (widget.index * 0.17) % 1.0;
    _floatCtrl.repeat();
  }

  @override
  void dispose() {
    _floatCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _floatCtrl,
      builder: (_, child) => Transform.translate(
        offset: Offset(0, sin(_floatCtrl.value * 2 * pi) * 4.0),
        child: child,
      ),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? const Color(0xFF5FD68A)
                : const Color(0xFF1E1E2C),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(
              color: widget.isSelected
                  ? const Color(0xFF3EC470)
                  : Colors.white.withValues(alpha: 0.10),
              width: widget.isSelected ? 1.5 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.isSelected
                    ? const Color(0xFF5FD68A).withValues(alpha: 0.35)
                    : Colors.black.withValues(alpha: 0.25),
                blurRadius: widget.isSelected ? 14 : 6,
                spreadRadius: 0,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              color: widget.isSelected
                  ? const Color(0xFF0A1A0F)
                  : Colors.white.withValues(alpha: 0.85),
              fontWeight:
                  widget.isSelected ? FontWeight.w700 : FontWeight.w400,
              fontSize: 15,
            ),
          ),
        ),
      ),
    );
  }
}
