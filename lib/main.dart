import 'package:flutter/material.dart';
import 'features/shell/splash_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // 추가
import 'services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AuthService.init();
  await Supabase.initialize(
    url: 'https://wqkwmkiqtovclqrsevae.supabase.co',   // 프로젝트 URL — /rest/v1/ 붙이면 안 됨!
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Indxa3dta2lxdG92Y2xxcnNldmFlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzk1ODY1MjgsImV4cCI6MjA5NTE2MjUyOH0.nRLx_41Hjad_YKvdIIUCqImmRWKTJeZAGecvEgi1EGE', // anon public key
  );
  runApp(const DriftApp());
}

class DriftApp extends StatelessWidget {
  const DriftApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MOSU KNU',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF7F77DD)),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}