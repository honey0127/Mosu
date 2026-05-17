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

class _OnboardingKeywordScreenState extends State<OnboardingKeywordScreen>
    with TickerProviderStateMixin {
  final Set<String> _selected = {};

  late final AnimationController _headerCtrl;
  late final Animation<double> _headerFade;

  // 버블별 둥둥 애니메이션 (keyword_screen과 동일 방식)
  late final List<AnimationController> _floatCtrls;
  late final List<Animation<double>> _floatAnims;

  // 30개 버블 고정 위치 (너비 비율, 높이 비율) — 스크롤 캔버스 기준
  // 캔버스 높이 = 화면 높이 * 1.8 로 설정
  static const List<List<double>> _frac = [
    [0.05, 0.02], [0.42, 0.00], [0.70, 0.03],
    [0.15, 0.11], [0.52, 0.09], [0.82, 0.07],
    [0.03, 0.19], [0.30, 0.18], [0.60, 0.17], [0.87, 0.20],
    [0.12, 0.28], [0.43, 0.27], [0.72, 0.26],
    [0.02, 0.36], [0.25, 0.35], [0.55, 0.34], [0.80, 0.37],
    [0.10, 0.45], [0.38, 0.44], [0.65, 0.43], [0.90, 0.46],
    [0.04, 0.54], [0.28, 0.53], [0.58, 0.52], [0.83, 0.55],
    [0.14, 0.63], [0.44, 0.62], [0.70, 0.61],
    [0.06, 0.72], [0.35, 0.71],
  ];

  @override
  void initState() {
    super.initState();

    // 헤더 페이드
    _headerCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _headerFade =
        CurvedAnimation(parent: _headerCtrl, curve: Curves.easeOut);
    _headerCtrl.forward();

    // 버블별 둥둥 애니 — keyword_screen과 동일
    final rng = Random(77);
    _floatCtrls = List.generate(allKeywords.length, (i) {
      final ms = 1500 + rng.nextInt(1400);
      return AnimationController(
          vsync: this, duration: Duration(milliseconds: ms));
    });
    _floatAnims = _floatCtrls
        .map((c) => Tween<double>(begin: -9, end: 9).animate(
        CurvedAnimation(parent: c, curve: Curves.easeInOut)))
        .toList();

    for (var i = 0; i < _floatCtrls.length; i++) {
      Future.delayed(Duration(milliseconds: i * 70), () {
        if (mounted) _floatCtrls[i].repeat(reverse: true);
      });
    }
  }

  @override
  void dispose() {
    _headerCtrl.dispose();
    for (final c in _floatCtrls) c.dispose();
    super.dispose();
  }

  void _toggle(String id) => setState(
          () => _selected.contains(id) ? _selected.remove(id) : _selected.add(id));

  void _finish() {
    AuthService.completeOnboarding(widget.userId, _selected.toList());
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const MainShell(),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E0E14),
      body: SafeArea(
        child: Column(
          children: [
            // ── 헤더 ──────────────────────────────────────────────────
            FadeTransition(
              opacity: _headerFade,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '어떤 경험이\n끌리나요?',
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        height: 1.22,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '마음에 드는 버블을 눌러봐요  •  스크롤해서 더 보기',
                      style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withValues(alpha: 0.40)),
                    ),
                    const SizedBox(height: 10),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: _selected.isEmpty
                          ? Text(
                        '아무거나 골라봐요 ✨',
                        key: const ValueKey('empty'),
                        style: TextStyle(
                            fontSize: 13,
                            color: Colors.white.withValues(alpha: 0.28)),
                      )
                          : Text(
                        '${_selected.length}개 선택됨',
                        key: ValueKey(_selected.length),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF9F99F5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),

            // ── 버블 필드 (스크롤 가능) ────────────────────────────────
            Expanded(
              child: LayoutBuilder(builder: (ctx, box) {
                final w = box.maxWidth;
                final canvasH = box.maxHeight * 1.75; // 스크롤 캔버스 높이

                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: SizedBox(
                    width: w,
                    height: canvasH,
                    child: Stack(
                      clipBehavior: Clip.hardEdge,
                      children: List.generate(allKeywords.length, (i) {
                        final frac = _frac[i % _frac.length];
                        final kw = allKeywords[i];
                        final sel = _selected.contains(kw.id);
                        final r = 44.0 * kw.size;
                        final left = (frac[0] * (w - r * 2)).clamp(0.0, w - r * 2);
                        final top  = (frac[1] * (canvasH - r * 2)).clamp(0.0, canvasH - r * 2);

                        return AnimatedBuilder(
                          animation: _floatAnims[i],
                          builder: (_, child) => Positioned(
                            left: left,
                            top: top + _floatAnims[i].value,
                            child: child!,
                          ),
                          child: _BubbleChip(
                            keyword: kw,
                            radius: r,
                            selected: sel,
                            onTap: () => _toggle(kw.id),
                          ),
                        );
                      }),
                    ),
                  ),
                );
              }),
            ),

            // ── 하단 바 ────────────────────────────────────────────────
            Container(
              color: const Color(0xFF0E0E14),
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 선택 태그 가로 스크롤
                  if (_selected.isNotEmpty) ...[
                    SizedBox(
                      height: 34,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _selected.length,
                        separatorBuilder: (_, __) =>
                        const SizedBox(width: 6),
                        itemBuilder: (_, idx) {
                          final id = _selected.elementAt(idx);
                          final kw =
                          allKeywords.firstWhere((k) => k.id == id);
                          final cat =
                              _catColor[kw.category] ?? const Color(0xFF9F99F5);
                          return Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 5),
                            decoration: BoxDecoration(
                              color: cat.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: cat.withValues(alpha: 0.5)),
                            ),
                            child: Text('${kw.emoji} ${kw.label}',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: cat,
                                    fontWeight: FontWeight.w600)),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],

                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _finish,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _selected.isNotEmpty
                            ? const Color(0xFF7F77DD)
                            : const Color(0xFF242430),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Text(
                        _selected.isNotEmpty ? '탐험 시작하기 →' : '건너뛰기',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: _selected.isNotEmpty
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.35),
                        ),
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

// ── 원형 버블 칩 ──────────────────────────────────────────────────────────────
class _BubbleChip extends StatefulWidget {
  final Keyword keyword;
  final double radius;
  final bool selected;
  final VoidCallback onTap;

  const _BubbleChip({
    required this.keyword,
    required this.radius,
    required this.selected,
    required this.onTap,
  });

  @override
  State<_BubbleChip> createState() => _BubbleChipState();
}

class _BubbleChipState extends State<_BubbleChip>
    with SingleTickerProviderStateMixin {
  late AnimationController _press;

  @override
  void initState() {
    super.initState();
    _press = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 110),
      lowerBound: 0.88,
      upperBound: 1.0,
      value: 1.0,
    );
  }

  @override
  void dispose() {
    _press.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final kw = widget.keyword;
    final r = widget.radius;
    final d = r * 2;
    final cat = _catColor[kw.category] ?? const Color(0xFF9F99F5);

    return GestureDetector(
      onTapDown: (_) => _press.reverse(),
      onTapUp: (_) {
        _press.forward();
        widget.onTap();
      },
      onTapCancel: () => _press.forward(),
      child: ScaleTransition(
        scale: _press,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: d,
          height: d,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.selected
                ? cat
                : cat.withValues(alpha: 0.13),
            border: Border.all(
              color: widget.selected
                  ? cat
                  : cat.withValues(alpha: 0.40),
              width: widget.selected ? 2.0 : 1.2,
            ),
            boxShadow: widget.selected
                ? [
              BoxShadow(
                  color: cat.withValues(alpha: 0.45),
                  blurRadius: 16,
                  spreadRadius: 1)
            ]
                : [],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(kw.emoji,
                  style: TextStyle(fontSize: r * 0.36)),
              const SizedBox(height: 2),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: r * 0.1),
                child: Text(
                  kw.label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: r * 0.27,
                    fontWeight: FontWeight.w600,
                    color: widget.selected
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.75),
                    height: 1.2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

const _catColor = {
  'mood':      Color(0xFF9F99F5),
  'time':      Color(0xFFD4A843),
  'place':     Color(0xFF4CAF8C),
  'social':    Color(0xFFFF7B54),
  'activity':  Color(0xFF3B9EE8),
  'challenge': Color(0xFFE25B7A),
};