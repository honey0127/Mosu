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
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('지금 끌리는 게 뭐야?',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 20)),
      ),
      body: Column(
        children: [
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
          Expanded(
            child: _KeywordCloud(
              keywords: allKeywords,
              selected: _selected,
              onTap: _toggle,
            ),
          ),
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
                        : '${_minSelect - _selected.length}개 더 선택해요',
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

// ─── 부유 키워드 클라우드 ─────────────────────────────────────────────────────
class _KeywordCloud extends StatefulWidget {
  final List<Keyword> keywords;
  final Set<String> selected;
  final void Function(String) onTap;

  const _KeywordCloud(
      {required this.keywords, required this.selected, required this.onTap});

  @override
  State<_KeywordCloud> createState() => _KeywordCloudState();
}

class _KeywordCloudState extends State<_KeywordCloud>
    with TickerProviderStateMixin {
  late final List<AnimationController> _ctrls;
  late final List<Animation<double>> _floats;

  // 30개 키워드 위치 (너비·높이 대비 비율)
  static const List<List<double>> _frac = [
    [0.03, 0.02], [0.38, 0.00], [0.65, 0.03], [0.82, 0.00],
    [0.08, 0.16], [0.30, 0.14], [0.55, 0.12], [0.75, 0.15],
    [0.01, 0.30], [0.22, 0.28], [0.46, 0.27], [0.68, 0.30], [0.86, 0.27],
    [0.10, 0.44], [0.33, 0.42], [0.57, 0.41], [0.78, 0.44],
    [0.04, 0.57], [0.26, 0.56], [0.50, 0.55], [0.72, 0.57], [0.90, 0.55],
    [0.12, 0.70], [0.35, 0.69], [0.60, 0.68], [0.80, 0.70],
    [0.05, 0.83], [0.28, 0.82], [0.53, 0.81], [0.76, 0.83],
  ];

  @override
  void initState() {
    super.initState();
    final rng = Random(42);

    _ctrls = List.generate(widget.keywords.length, (i) {
      final ms = 1600 + rng.nextInt(1200);
      return AnimationController(
          vsync: this, duration: Duration(milliseconds: ms));
    });

    _floats = _ctrls
        .map((c) => Tween<double>(begin: -8, end: 8).animate(
        CurvedAnimation(parent: c, curve: Curves.easeInOut)))
        .toList();

    for (var i = 0; i < _ctrls.length; i++) {
      Future.delayed(Duration(milliseconds: i * 80), () {
        if (mounted) _ctrls[i].repeat(reverse: true);
      });
    }
  }

  @override
  void dispose() {
    for (final c in _ctrls) c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final w = constraints.maxWidth;
      final h = constraints.maxHeight;

      return Stack(
        children: List.generate(widget.keywords.length, (i) {
          final frac = _frac[i % _frac.length];
          final kw = widget.keywords[i];
          final isSelected = widget.selected.contains(kw.id);
          final left = (frac[0] * (w - 130)).clamp(0.0, w - 130);
          final top = (frac[1] * (h - 50)).clamp(0.0, h - 60);

          return AnimatedBuilder(
            animation: _floats[i],
            builder: (_, child) => Positioned(
              left: left,
              top: top + _floats[i].value,
              child: child!,
            ),
            child: _KeywordChip(
              label: kw.label,
              isSelected: isSelected,
              onTap: () => widget.onTap(kw.id),
            ),
          );
        }),
      );
    });
  }
}

// ─── 키워드 칩 ────────────────────────────────────────────────────────────────
class _KeywordChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _KeywordChip(
      {required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF7F77DD) : Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF534AB7)
                : Colors.grey.shade300,
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? const Color(0xFF7F77DD).withValues(alpha: 0.35)
                  : Colors.black.withValues(alpha: 0.07),
              blurRadius: isSelected ? 14 : 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}