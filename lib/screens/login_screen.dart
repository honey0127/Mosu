import 'package:flutter/foundation.dart';
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

    setState(() { _loading = true; _error = null; });

    final result = AuthService.login(id, pw);
    await Future.delayed(const Duration(milliseconds: 500)); // UX 딜레이

    if (!mounted) return;
    setState(() => _loading = false);

    if (result == null) {
      setState(() => _error = '아이디 또는 비밀번호가 올바르지 않아요.');
      return;
    }

    // 키워드 온보딩 완료 여부 확인
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
      backgroundColor: const Color(0xFFF2F2F0),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 64),

              // ── 로고 영역 ──────────────────────────────────────────
              Center(
                child: Column(
                  children: [
                    SizedBox(
                      width: 56,
                      height: 56,
                      child: CustomPaint(painter: _SmallFlowerPainter()),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'M O S U',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w300,
                        letterSpacing: 8,
                        color: Color(0xFF9A9A9A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'K N U',
                      style: TextStyle(
                        fontSize: 11,
                        letterSpacing: 5,
                        color: Color(0xFFB8B8B8),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 56),

              // ── 타이틀 ─────────────────────────────────────────────
              const Text(
                '다시 만나서\n반가워요 👋',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  height: 1.35,
                  color: Color(0xFF2A2A2A),
                ),
              ),

              const SizedBox(height: 32),

              // ── 아이디 ─────────────────────────────────────────────
              _buildLabel('아이디'),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _idCtrl,
                hint: '아이디를 입력하세요',
                icon: Icons.person_outline,
              ),

              const SizedBox(height: 20),

              // ── 비밀번호 ───────────────────────────────────────────
              _buildLabel('비밀번호'),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _pwCtrl,
                hint: '비밀번호를 입력하세요',
                icon: Icons.lock_outline,
                obscure: _obscure,
                suffix: IconButton(
                  icon: Icon(
                    _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    color: Colors.grey.shade400,
                    size: 20,
                  ),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),

              // ── 오류 메시지 ─────────────────────────────────────────
              if (_error != null) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.error_outline,
                        color: Color(0xFFE57373), size: 16),
                    const SizedBox(width: 6),
                    Text(_error!,
                        style: const TextStyle(
                            color: Color(0xFFE57373), fontSize: 13)),
                  ],
                ),
              ],

              const SizedBox(height: 24),

              // ── 디버그 우회 버튼 (debug 빌드 한정) ─────────────────
              if (kDebugMode) ...[
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                            builder: (_) => const MainShell()),
                      );
                    },
                    icon: const Icon(Icons.bug_report,
                        size: 16, color: Color(0xFFFFB300)),
                    label: const Text(
                      'DEBUG · 로그인 건너뛰기',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF333333),
                        letterSpacing: 0.3,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.white,
                      side: BorderSide(color: Colors.grey.shade300),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // ── 로그인 버튼 ────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _loading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7F77DD),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey.shade200,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _loading
                      ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                      : const Text(
                    '로그인',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // ── 회원가입 링크 ──────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('처음이세요?',
                      style: TextStyle(
                          color: Colors.grey.shade500, fontSize: 14)),
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const SignupScreen()),
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

              const SizedBox(height: 40),
            ],
          ),
        ),
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
        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
        prefixIcon: Icon(icon, color: Colors.grey.shade400, size: 20),
        suffixIcon: suffix,
        filled: true,
        fillColor: Colors.white,
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
          borderSide:
          const BorderSide(color: Color(0xFF7F77DD), width: 1.5),
        ),
      ),
    );
  }
}

// ── 작은 꽃 로고 ──────────────────────────────────────────────────────────────
class _SmallFlowerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFB8B8B8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final cx = size.width / 2;
    final cy = size.height / 2;
    const petalCount = 6;

    for (var i = 0; i < petalCount; i++) {
      final angle = (i * 2 * 3.141592653589793) / petalCount - 1.5707963;
      final r0 = 6.0;
      final r1 = 14.0;
      final x1 = cx + r0 * _cos(angle);
      final y1 = cy + r0 * _sin(angle);
      final x2 = cx + r1 * _cos(angle);
      final y2 = cy + r1 * _sin(angle);

      canvas.save();
      canvas.translate((x1 + x2) / 2, (y1 + y2) / 2);
      canvas.rotate(angle + 1.5707963);
      canvas.drawOval(
        Rect.fromCenter(center: Offset.zero, width: 7, height: 11),
        paint,
      );
      canvas.restore();
    }

    canvas.drawCircle(Offset(cx, cy), 2,
        Paint()..color = const Color(0xFFB8B8B8));
  }

  double _cos(double a) => _c(a);
  double _sin(double a) => _c(a - 1.5707963265358979);
  static double _c(double x) {
    x = x % (2 * 3.141592653589793);
    double r = 1, t = 1;
    for (int n = 1; n <= 10; n++) {
      t *= -x * x / ((2 * n - 1) * (2 * n));
      r += t;
    }
    return r;
  }

  @override
  bool shouldRepaint(covariant CustomPainter o) => false;
}