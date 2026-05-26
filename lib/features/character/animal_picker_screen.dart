import 'package:flutter/material.dart';
import '../../models/app_state.dart';

const _faces = [
  '🐱', '🐶', '🐻', '🐼', '🦊', '🐰',
  '🐸', '🐮', '🐯', '🦁', '🐺', '🦝',
  '🐨', '🦔', '🐹', '🦦', '🦉', '🐧',
];

/// 얼굴 이모지 선택 화면 — 캐릭터 베이스를 고르는 UI.
class AnimalPickerScreen extends StatefulWidget {
  final bool isFirstTime;
  const AnimalPickerScreen({super.key, this.isFirstTime = false});

  @override
  State<AnimalPickerScreen> createState() => _AnimalPickerScreenState();
}

class _AnimalPickerScreenState extends State<AnimalPickerScreen> {
  late String _selected;

  @override
  void initState() {
    super.initState();
    _selected = AppState.i.selectedFaceEmoji;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          widget.isFirstTime ? '내 캐릭터 고르기' : '캐릭터 바꾸기',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF534AB7),
        elevation: 0,
        automaticallyImplyLeading: !widget.isFirstTime,
      ),
      body: Column(
        children: [
          // ── 미리보기 ──────────────────────────────────────────
          Container(
            margin: const EdgeInsets.fromLTRB(20, 8, 20, 4),
            height: 130,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFAF8F1), Color(0xFFEFE8DC)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: Text(
                  _selected,
                  key: ValueKey(_selected),
                  style: const TextStyle(fontSize: 76),
                ),
              ),
            ),
          ),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Text(
              '어떤 얼굴로 시작할까요?',
              style: TextStyle(fontSize: 14, color: Color(0xFF8E8E93)),
            ),
          ),

          // ── 얼굴 그리드 ─────────────────────────────────────
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1,
              ),
              itemCount: _faces.length,
              itemBuilder: (_, i) {
                final face = _faces[i];
                final isSelected = face == _selected;
                return GestureDetector(
                  onTap: () => setState(() => _selected = face),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFFEEEDFE)
                          : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF7F77DD)
                            : Colors.grey.shade200,
                        width: isSelected ? 2.5 : 1,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      face,
                      style: TextStyle(fontSize: isSelected ? 42 : 36),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),

      // ── 확인 버튼 ───────────────────────────────────────────
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          child: FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF7F77DD),
              minimumSize: const Size(double.infinity, 52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            onPressed: () {
              AppState.i.selectedFaceEmoji = _selected;
              Navigator.of(context).pop();
            },
            child: const Text(
              '이 얼굴로 시작하기',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ),
    );
  }
}
