import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'keyword_screen.dart';
import 'my_page_screen.dart';
import 'character_room_screen.dart';

/// 로그인·온보딩 통과 후 보이는 앱 본체
/// 탭 구조: 홈 / 내 공간 / 마이  (중앙에 '탐험 시작' FAB)
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  static const _primary = Color(0xFF7F77DD);

  int _index = 0;

  Widget get _body {
    switch (_index) {
      case 0: return const HomeScreen();
      case 1: return const CharacterRoomScreen();
      case 2: return const MyPageScreen();
      default: return const HomeScreen();
    }
  }

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
        backgroundColor: _primary,
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
            _NavButton(
              icon: Icons.home_outlined,
              activeIcon: Icons.home,
              label: '홈',
              selected: _index == 0,
              onTap: () => setState(() => _index = 0),
            ),
            _NavButton(
              icon: Icons.weekend_outlined,
              activeIcon: Icons.weekend,
              label: '내 공간',
              selected: _index == 1,
              onTap: () => setState(() => _index = 1),
            ),
            // FAB 노치 자리
            const SizedBox(width: 72),
            _NavButton(
              icon: Icons.person_outline,
              activeIcon: Icons.person,
              label: '마이',
              selected: _index == 2,
              onTap: () => setState(() => _index = 2),
            ),
          ],
        ),
      ),
    );
  }
}

/// 하단 네비 버튼 — 아이콘 + 라벨, 선택 시 색 변경
class _NavButton extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NavButton({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? const Color(0xFF7F77DD) : Colors.grey.shade500;
    return InkResponse(
      onTap: onTap,
      radius: 28,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(selected ? activeIcon : icon, color: color, size: 22),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
