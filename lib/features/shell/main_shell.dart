import 'package:flutter/material.dart';
import '../home/home_screen.dart';
import '../profile/my_page_screen.dart';
import '../character/character_room_screen.dart';
import '../community/community_screen.dart';

/// 로그인·온보딩 통과 후 보이는 앱 본체
/// 탭 구조: 홈 / 내 공간 / 커뮤니티 / 마이
class MainShell extends StatefulWidget {
  final int initialIndex;
  const MainShell({super.key, this.initialIndex = 0});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  late int _index = 0;

  @override
  void initState() {                               // ← 추가
    super.initState();
    _index = widget.initialIndex;                  // ← 추가
  }

  Widget get _body {
    switch (_index) {
      case 0: return const HomeScreen();
      case 1: return const CharacterRoomScreen();
      case 2: return const CommunityScreen();
      case 3: return const MyPageScreen();
      default: return const HomeScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _body,
      bottomNavigationBar: BottomAppBar(
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
            _NavButton(
              icon: Icons.people_outline,
              activeIcon: Icons.people,
              label: '커뮤니티',
              selected: _index == 2,
              onTap: () => setState(() => _index = 2),
            ),
            _NavButton(
              icon: Icons.person_outline,
              activeIcon: Icons.person,
              label: '마이',
              selected: _index == 3,
              onTap: () => setState(() => _index = 3),
            ),
          ],
        ),
      ),
    );
  }
}

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
    final color = selected ? const Color(0xFF7DB879) : Colors.grey.shade500;
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
