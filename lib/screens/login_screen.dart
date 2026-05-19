import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'signup_screen.dart';
import 'onboarding_keyword_screen.dart';
import 'main_shell.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _idCtrl = TextEditingController();
  final _pwCtrl = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  String? _error;

  Future<void> _login() async {
    final id = _idCtrl.text.trim();
    final pw = _pwCtrl.text;
    if (id.isEmpty || pw.isEmpty) {
      setState(() => _error = '아이디와 비밀번호를 입력해주세요.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    final result = AuthService.login(id, pw);
    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;
    setState(() => _loading = false);

    if (result == null) {
      setState(() => _error = '아이디 또는 비밀번호가 올바르지 않아요.');
      return;
    }

    final needsOnboarding = !AuthService.hasCompletedOnboarding(id);
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => needsOnboarding
            ? OnboardingKeywordScreen(userId: id)
            : const MainShell(),
      ),
    );
  }

  @override
  void dispose() {
    _idCtrl.dispose();
    _pwCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // ── 레이어 1: 스플래시 배경 ─────────────────────────────────
          Positioned.fill(
            child: Container(
              color: const Color(0xFFF2F2F0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 큰 꽃 로고
                  SizedBox(
                    width: 140,
                    height: 140,
                    child: CustomPaint(painter: _SplashFlowerPainter()),
                  ),
                  const SizedBox(height: 28),
                  const Text(
                    'M O S U',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w300,
                      letterSpacing: 12,
                      color: Color(0xFFC0C0C0),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'S E O U L',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w300,
                      letterSpacing: 7,
                      color: Color(0xFFCCCCCC),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── 레이어 2: 로그인 카드 (화면 정중앙) ────────────────────────
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                    horizontal: 28, vertical: 40),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.09),
                        blurRadius: 36,
                        spreadRadius: 0,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // ── 타이틀 ────────────────────────────────────
                      const Text(
                        '다시 만나서\n반가워요 👋',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                          height: 1.35,
                          color: Color(0xFF2A2A2A),
                        ),
                      ),

                      const SizedBox(height: 28),

                      // ── 아이디 ────────────────────────────────────
                      _buildLabel('아이디'),
                      const SizedBox(height: 8),
                      _buildTextField(
                        controller: _idCtrl,
                        hint: '아이디를 입력하세요',
                        icon: Icons.person_outline,
                      ),

                      const SizedBox(height: 18),

                      // ── 비밀번호 ──────────────────────────────────
                      _buildLabel('비밀번호'),
                      const SizedBox(height: 8),
                      _buildTextField(
                        controller: _pwCtrl,
                        hint: '비밀번호를 입력하세요',
                        icon: Icons.lock_outline,
                        obscure: _obscure,
                        suffix: IconButton(
                          icon: Icon(
                            _obscure
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: Colors.grey.shade400,
                            size: 20,
                          ),
                          onPressed: () =>
                              setState(() => _obscure = !_obscure),
                        ),
                      ),

                      // ── 오류 메시지 ───────────────────────────────
                      if (_error != null) ...[
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            const Icon(Icons.error_outline,
                                color: Color(0xFFE57373), size: 16),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                _error!,
                                style: const TextStyle(
                                    color: Color(0xFFE57373),
                                    fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ],

                      const SizedBox(height: 28),

                      // ── 로그인 버튼 ───────────────────────────────
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: _loading ? null : _login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF7F77DD),
                            foregroundColor: Colors.white,
                            disabledBackgroundColor:
                            Colors.grey.shade200,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                                borderRadius:
                                BorderRadius.circular(14)),
                          ),
                          child: _loading
                              ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white),
                          )
                              : const Text(
                            '로그인',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),

                      const SizedBox(height: 18),

                      // ── 회원가입 링크 ─────────────────────────────
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '처음이세요?',
                            style: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: 14),
                          ),
                          const SizedBox(width: 4),
                          GestureDetector(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) =>
                                  const SignupScreen()),
                            ),
                            child: const Text(
                              '회원가입',
                              style: TextStyle(
                                color: Color(0xFF7F77DD),
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) => Text(
    text,
    style: const TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w600,
      color: Color(0xFF444444),
    ),
  );

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscure = false,
    Widget? suffix,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      style: const TextStyle(fontSize: 15, color: Color(0xFF2A2A2A)),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle:
        TextStyle(color: Colors.grey.shade400, fontSize: 14),
        prefixIcon: Icon(icon, color: Colors.grey.shade400, size: 20),
        suffixIcon: suffix,
        filled: true,
        fillColor: const Color(0xFFF6F6F6),
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
              color: Color(0xFF7F77DD), width: 1.5),
        ),
      ),
    );
  }
}

// ── 스플래시용 꽃 로고 ────────────────────────────────────────────────────────
// 이미지 참고: 6개 꽃잎이 이중 윤곽선으로 교차하는 형태
class _SplashFlowerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    final outerPaint = Paint()
      ..color = const Color(0xFFB8B8B8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final innerPaint = Paint()
      ..color = const Color(0xFFC8C8C8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    const petalCount = 6;
    final outerR = size.width * 0.38;
    final innerR = size.width * 0.13;

    for (var i = 0; i < petalCount; i++) {
      final angle =
          (i * 2 * math.pi) / petalCount - math.pi / 2;

      final px = cx + (innerR + outerR) / 2 * math.cos(angle);
      final py = cy + (innerR + outerR) / 2 * math.sin(angle);

      final petalW = (outerR - innerR) * 0.56;
      final petalH = outerR - innerR;

      canvas.save();
      canvas.translate(px, py);
      canvas.rotate(angle + math.pi / 2);

      // 바깥 꽃잎
      canvas.drawOval(
        Rect.fromCenter(
            center: Offset.zero, width: petalW, height: petalH),
        outerPaint,
      );
      // 안쪽 작은 타원 (이중선)
      canvas.drawOval(
        Rect.fromCenter(
            center: Offset.zero,
            width: petalW * 0.5,
            height: petalH * 0.52),
        innerPaint,
      );
      canvas.restore();
    }

    // 중앙 원
    canvas.drawCircle(
      Offset(cx, cy),
      size.width * 0.048,
      Paint()
        ..color = const Color(0xFFB8B8B8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0,
    );
    canvas.drawCircle(
      Offset(cx, cy),
      size.width * 0.02,
      Paint()..color = const Color(0xFFB8B8B8),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter o) => false;
}