import 'dart:math';
import 'package:flutter/material.dart';
import '../../models/keyword.dart';
import '../../services/auth_service.dart';
import 'onboarding_profile_screen.dart';

class KeywordSelectionScreen extends StatefulWidget {
  final String userId;
  const KeywordSelectionScreen({super.key, required this.userId});

  @override
  State<KeywordSelectionScreen> createState() => _KeywordSelectionScreenState();
}

class _KeywordSelectionScreenState extends State<KeywordSelectionScreen>
    with TickerProviderStateMixin {
  static const _minSelect = 5;
  static const _green = Color(0xFF7DB879);
  static const _bg = Color(0xFFF5F5F0);

  final Set<String> _selected = {};
  late final List<AnimationController> _floatCtrls;
  late final List<Animation<double>> _floatAnims;
  bool _showHint = false;

  @override
  void initState() {
    super.initState();
    final rng = Random(42);
    _floatCtrls = List.generate(allKeywords.length, (i) {
      return AnimationController(
        vsync: this,
        duration: Duration(milliseconds: 2000 + rng.nextInt(2000)),
      );
    });
    _floatAnims = List.generate(allKeywords.length, (i) {
      return Tween<double>(begin: -5.0, end: 5.0).animate(
        CurvedAnimation(parent: _floatCtrls[i], curve: Curves.easeInOut),
      );
    });

    final rng2 = Random(7);
    for (int i = 0; i < _floatCtrls.length; i++) {
      _floatCtrls[i].value = rng2.nextDouble();
      _floatCtrls[i].repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    for (final c in _floatCtrls) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _proceed() async {
    if (_selected.length < _minSelect) {
      setState(() => _showHint = true);
      return;
    }
    await AuthService.saveKeywords(widget.userId, _selected.toList());
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) =>
            OnboardingProfileScreen(userId: widget.userId),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final remaining = _minSelect - _selected.length;
    final canProceed = _selected.length >= _minSelect;

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── 헤더 ──────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '지금 끌리는게 뭐야?',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF2A2A2A),
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${_selected.length}개 선택됨  (최소 ${_minSelect}개)',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade500,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => setState(() {
                          _selected.clear();
                          _showHint = false;
                        }),
                        child: Text(
                          '초기화',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── 키워드 칩 영역 ─────────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Wrap(
                  spacing: 10,
                  runSpacing: 12,
                  children: List.generate(allKeywords.length, (i) {
                    final kw = allKeywords[i];
                    final sel = _selected.contains(kw.id);
                    final fontSize = (13.0 * kw.size).clamp(12.0, 16.0);
                    final hPad = (14.0 * kw.size).clamp(12.0, 22.0);

                    return AnimatedBuilder(
                      animation: _floatAnims[i],
                      builder: (_, child) => Transform.translate(
                        offset: Offset(0, _floatAnims[i].value),
                        child: child,
                      ),
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            if (sel) {
                              _selected.remove(kw.id);
                            } else {
                              _selected.add(kw.id);
                            }
                            if (_selected.length >= _minSelect) {
                              _showHint = false;
                            }
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: EdgeInsets.symmetric(
                            horizontal: hPad,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: sel ? _green : Colors.white,
                            borderRadius: BorderRadius.circular(99),
                            border: Border.all(
                              color: sel ? _green : const Color(0xFFDDDDDD),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.06),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            kw.label,
                            style: TextStyle(
                              fontSize: fontSize,
                              fontWeight: FontWeight.w500,
                              color: sel
                                  ? Colors.white
                                  : const Color(0xFF333333),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),

            // ── 하단 버튼 영역 ─────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
              child: Column(
                children: [
                  AnimatedSize(
                    duration: const Duration(milliseconds: 200),
                    child: _showHint && !canProceed
                        ? Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Text(
                              '$remaining개 더 선택해요',
                              style: const TextStyle(
                                color: Color(0xFFE57373),
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _proceed,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _green,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        '경험찾기  →',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
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
