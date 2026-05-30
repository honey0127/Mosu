import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../auth/login_screen.dart';
import '../onboarding/keyword_selection_screen.dart';
import '../onboarding/onboarding_profile_screen.dart';
import 'main_shell.dart';

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
      if (!mounted) return;

      final userId = AuthService.currentUserId;
      final Widget next;

      if (userId != null) {
        // 이미 로그인된 유저 → 온보딩 상태에 맞는 화면으로
        if (!AuthService.hasSelectedKeywords(userId)) {
          next = KeywordSelectionScreen(userId: userId);
        } else if (!AuthService.hasCompletedOnboarding(userId)) {
          next = OnboardingProfileScreen(userId: userId);
        } else {
          next = const MainShell();
        }
      } else {
        next = const LoginScreen();
      }

      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, a1, a2) => next,
          transitionsBuilder: (context, anim, a2, child) =>
              FadeTransition(opacity: anim, child: child),
          transitionDuration: const Duration(milliseconds: 600),
        ),
      );
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
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── 넛지 로고 텍스트 ──
                Text(
                  '넛지',
                  style: TextStyle(
                    fontSize: 72,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF7DB879),
                    height: 1.0,
                  ),
                ),
                SizedBox(height: 16),
                // ── 부제 ──
                Text(
                  '나를 발견하는 새로운 경험',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF888888),
                    letterSpacing: 0.3,
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
