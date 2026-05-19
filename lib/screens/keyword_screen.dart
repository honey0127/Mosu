import 'dart:math';
import 'package:flutter/material.dart';
import '../models/models.dart';
import 'recommendation_screen.dart';

class KeywordScreen extends StatefulWidget {
  const KeywordScreen({super.key});

  @override
  State<KeywordScreen> createState() => _KeywordScreenState();
}

class _KeywordScreenState extends State<KeywordScreen> {
  final Set<String> _selected = {};
  static const int _minSelect = 5;

  void _toggle(String id) => setState(() {
    _selected.contains(id) ? _selected.remove(id) : _selected.add(id);
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final remaining = _minSelect - _selected.length;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F5F7),
        elevation: 0,
        title: const Text(
          '지금 끌리는 게 뭐야?',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 20),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── 선택 상태 표시 ─────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: Row(
              children: [
                Text(
                  '${_selected.length}개 선택됨 (최소 $_minSelect개)',
                  style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13),
                ),
                const Spacer(),
                if (_selected.isNotEmpty)
                  TextButton(
                    onPressed: () => setState(() => _selected.clear()),
                    child: const Text('초기화'),
                  ),
              ],
            ),
          ),

          // ── 키워드 칩 목록 ─────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: _StaggeredChipGrid(
                keywords: allKeywords,
                selected: _selected,
                onTap: _toggle,
              ),
            ),
          ),

          // ── 다음 버튼 ──────────────────────────────────────────────
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF7F77DD),
                    disabledBackgroundColor: Colors.grey.shade200,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: _selected.length >= _minSelect
                      ? () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => RecommendationScreen(
                          selectedKeywordIds: _selected.toList()),
                    ),
                  )
                      : null,
                  child: Text(
                    _selected.length >= _minSelect
                        ? '경험 찾기 →'
                        : '$remaining개 더 선택해요',
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
          ),
        ],
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
            runSpacing: 0,
            children: rows[r].map((kw) {
              return _KeywordChip(
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

// ─── 키워드 칩 ────────────────────────────────────────────────────────────────
class _KeywordChip extends StatefulWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final int index;

  const _KeywordChip({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.index,
  });

  @override
  State<_KeywordChip> createState() => _KeywordChipState();
}

class _KeywordChipState extends State<_KeywordChip>
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
            color: widget.isSelected ? const Color(0xFF7F77DD) : Colors.white,
            borderRadius: BorderRadius.circular(32),
            border: Border.all(
              color: widget.isSelected
                  ? const Color(0xFF534AB7)
                  : Colors.grey.shade200,
              width: widget.isSelected ? 1.5 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.isSelected
                    ? const Color(0xFF7F77DD).withValues(alpha: 0.30)
                    : Colors.black.withValues(alpha: 0.06),
                blurRadius: widget.isSelected ? 12 : 8,
                spreadRadius: 0,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              color: widget.isSelected
                  ? Colors.white
                  : const Color(0xFF2A2A2A),
              fontWeight:
                  widget.isSelected ? FontWeight.w600 : FontWeight.w400,
              fontSize: 15,
            ),
          ),
        ),
      ),
    );
  }
}
