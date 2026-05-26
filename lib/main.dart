import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'features/shell/splash_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AuthService.init();
  await Supabase.initialize(
    url: 'https://wqkwmkiqtovclqrsevae.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Indxa3dta2lxdG92Y2xxcnNldmFlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzk1ODY1MjgsImV4cCI6MjA5NTE2MjUyOH0.nRLx_41Hjad_YKvdIIUCqImmRWKTJeZAGecvEgi1EGE',
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
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'),
        Locale('ko'),
      ],
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF7F77DD)),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}
