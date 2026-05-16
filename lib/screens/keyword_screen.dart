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
          // 선택 상태 표시
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: Row(
              children: [
                Text(
                  '${_selected.length}개 선택됨 (최소 $_minSelect개)',
                  style:
                  TextStyle(color: cs.onSurfaceVariant, fontSize: 13),
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

          // 부유하는 키워드 클라우드
          Expanded(
            child: _KeywordCloud(
              keywords: allKeywords,
              selected: _selected,
              onTap: _toggle,
            ),
          ),

          // 다음 버튼
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
      {required this.keywords,
        required this.selected,
        required this.onTap});

  @override
  State<_KeywordCloud> createState() => _KeywordCloudState();
}

class _KeywordCloudState extends State<_KeywordCloud>
    with TickerProviderStateMixin {
  late final List<AnimationController> _ctrls;
  late final List<Animation<double>> _floats;

  // 15개 키워드의 고정 위치 (화면 너비·높이 대비 비율)
  static const List<List<double>> _frac = [
    [0.05, 0.04], [0.45, 0.02], [0.68, 0.07],
    [0.10, 0.22], [0.48, 0.20], [0.76, 0.18],
    [0.02, 0.42], [0.36, 0.38], [0.64, 0.36],
    [0.16, 0.60], [0.50, 0.57], [0.74, 0.55],
    [0.06, 0.76], [0.40, 0.73], [0.66, 0.70],
  ];

  @override
  void initState() {
    super.initState();
    final rng = Random(42); // 고정 시드 → 매번 같은 속도 패턴

    _ctrls = List.generate(widget.keywords.length, (i) {
      final ms = 1600 + rng.nextInt(1200);
      return AnimationController(
          vsync: this, duration: Duration(milliseconds: ms));
    });

    _floats = _ctrls
        .map((c) => Tween<double>(begin: -8, end: 8).animate(
        CurvedAnimation(parent: c, curve: Curves.easeInOut)))
        .toList();

    // 순차적으로 시작해서 전부 동시에 움직이지 않게
    for (var i = 0; i < _ctrls.length; i++) {
      Future.delayed(Duration(milliseconds: i * 90), () {
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
          // 칩이 화면 밖으로 나가지 않도록 여백 확보
          final left = (frac[0] * (w - 140)).clamp(0.0, w - 140);
          final top = (frac[1] * (h - 60)).clamp(0.0, h - 70);

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
      {required this.label,
        required this.isSelected,
        required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding:
        const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
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
                  ? const Color(0xFF7F77DD).withOpacity(0.35)
                  : Colors.black.withOpacity(0.07),
              blurRadius: isSelected ? 14 : 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight:
            isSelected ? FontWeight.w600 : FontWeight.w400,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}