import 'package:flutter/material.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _fadeAnim = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
    _scaleAnim = Tween<double>(begin: 0.88, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic),
    );
    _ctrl.forward();

    Future.delayed(const Duration(milliseconds: 2400), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (_, _, _) => const LoginScreen(),
            transitionsBuilder: (_, anim, _, child) =>
                FadeTransition(opacity: anim, child: child),
            transitionDuration: const Duration(milliseconds: 600),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F0),
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: ScaleTransition(
            scale: _scaleAnim,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── 꽃 로고 (SVG-like CustomPaint) ──
                SizedBox(
                  width: 96,
                  height: 96,
                  child: CustomPaint(painter: _FlowerPainter()),
                ),
                const SizedBox(height: 32),
                // ── MOSU ──
                const Text(
                  'M O S U',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w300,
                    letterSpacing: 10,
                    color: Color(0xFF9A9A9A),
                  ),
                ),
                const SizedBox(height: 6),
                // ── KNU ──
                const Text(
                  'K N U',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    letterSpacing: 6,
                    color: Color(0xFFB0B0B0),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── 꽃 로고 Painter ───────────────────────────────────────────────────────────
class _FlowerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFB8B8B8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.8
      ..strokeCap = StrokeCap.round;

    final cx = size.width / 2;
    final cy = size.height / 2;
    const petalCount = 6;
    const r1 = 22.0; // 꽃잎 길이
    const r0 = 10.0; // 안쪽 반지름

    for (var i = 0; i < petalCount; i++) {
      final angle = (i * 2 * 3.141592653589793) / petalCount - 1.5707963;
      final x1 = cx + r0 * _cos(angle);
      final y1 = cy + r0 * _sin(angle);
      final x2 = cx + r1 * _cos(angle);
      final y2 = cy + r1 * _sin(angle);

      // 꽃잎 타원
      canvas.save();
      canvas.translate((x1 + x2) / 2, (y1 + y2) / 2);
      canvas.rotate(angle + 1.5707963);
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset.zero,
          width: 12,
          height: r1 - r0 + 6,
        ),
        paint,
      );
      canvas.restore();
    }

    // 중심 점
    final dotPaint = Paint()
      ..color = const Color(0xFFB8B8B8)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(cx, cy), 3, dotPaint);
  }

  double _cos(double a) => _mathCos(a);
  double _sin(double a) => _mathSin(a);

  static double _mathCos(double a) {
    // dart:math 미사용 버전 (import 없이)
    return _taylorCos(a);
  }

  static double _mathSin(double a) {
    return _taylorCos(a - 1.5707963265358979);
  }

  static double _taylorCos(double x) {
    // 범위 정규화
    x = x % (2 * 3.141592653589793);
    double result = 1;
    double term = 1;
    for (int n = 1; n <= 10; n++) {
      term *= -x * x / ((2 * n - 1) * (2 * n));
      result += term;
    }
    return result;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}