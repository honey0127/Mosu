import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'keyword_screen.dart';
import 'my_page_screen.dart';

/// 로그인·온보딩 통과 후 보이는 앱 본체
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;
  Widget get _body =>
      _index == 0 ? const HomeScreen() : const MyPageScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _body,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const KeywordScreen()),
          );
          setState(() {});
        },
        backgroundColor: const Color(0xFF7F77DD),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.explore_outlined),
        label: const Text('탐험 시작',
            style: TextStyle(fontWeight: FontWeight.w600)),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              icon: Icon(_index == 0 ? Icons.home : Icons.home_outlined),
              onPressed: () => setState(() => _index = 0),
              tooltip: '홈',
            ),
            const SizedBox(width: 80),
            IconButton(
              icon: Icon(
                  _index == 1 ? Icons.person : Icons.person_outline),
              onPressed: () => setState(() => _index = 1),
              tooltip: '마이',
            ),
          ],
        ),
      ),
    );
  }
}