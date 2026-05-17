import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';
import 'screens/main_shell.dart';

export 'screens/main_shell.dart'; // 하위 호환용 (필요 시)

void main() => runApp(const DriftApp());

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