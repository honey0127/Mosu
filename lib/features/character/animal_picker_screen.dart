import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../shell/main_shell.dart';

/// 캐릭터 베이스 동물 선택 화면.
/// 처음 '내 공간' 진입 시 자동 호출되며, 이후 아바타 옆 '동물 바꾸기' 버튼으로도 진입 가능.
///
/// dismiss 동작:
///   - 동물을 선택하고 '결정' 누르면 [Navigator.pop] with selected id (String)
///   - 그냥 뒤로 가면 선택 안 한 채로 닫힘 (null pop)
class AnimalPickerScreen extends StatefulWidget {
  /// 첫 진입 시 true — 제목/버튼 문구만 바뀜 (뒤로가기는 항상 가능)
  final bool isFirstTime;
  const AnimalPickerScreen({super.key, this.isFirstTime = false});

  @override
  State<AnimalPickerScreen> createState() => _AnimalPickerScreenState();
}

class _AnimalPickerScreenState extends State<AnimalPickerScreen> {
  static const _primary = Color(0xFF7DB879);
  String? _selectedId;

  @override
  void initState() {
    super.initState();
    // 기존에 선택한 동물이 있으면 그걸 디폴트로
    _selectedId = AppState.i.selectedAnimalId;
  }

  void _confirm() {
    if (_selectedId == null) return;
    AppState.i.selectAnimal(_selectedId!);
    Navigator.of(context).pop(_selectedId);
  }

  @override
  Widget build(BuildContext context) {
    final selected = animalById(_selectedId);

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) return;
        // 시스템 백·제스처 포함 — 첫 진입에서 선택 없이 닫혔으면 홈으로
        if (widget.isFirstTime && AppState.i.selectedAnimalId == null) {
          MainShell.goToTab(0);
        }
      },
      child: Scaffold(
      backgroundColor: const Color(0xFFF2F2F0),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF2F2F0),
        foregroundColor: Colors.black87,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(widget.isFirstTime ? Icons.close : Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
            // 첫 진입에서 동물 선택 없이 닫으면 → 홈 탭으로
            if (widget.isFirstTime && AppState.i.selectedAnimalId == null) {
              MainShell.goToTab(0);
            }
          },
        ),
        title: Text(
          widget.isFirstTime ? '캐릭터 선택' : '동물 바꾸기',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // ── 안내 카피 ─────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.isFirstTime ? '어떤 동물로 시작할래요?' : '캐릭터를 바꿔볼까요?',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '선택한 동물 위에 옷과 소품이 입혀져요.\n경험을 쌓을수록 더 다양하게 꾸밀 수 있어요.',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),

            // ── 동물 그리드 ───────────────────────────────────
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.95,
                ),
                itemCount: allAnimals.length,
                itemBuilder: (_, i) {
                  final a = allAnimals[i];
                  final isSelected = _selectedId == a.id;
                  return _AnimalTile(
                    animal: a,
                    selected: isSelected,
                    onTap: () => setState(() => _selectedId = a.id),
                  );
                },
              ),
            ),

            // ── 미리보기 + 확정 ───────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Column(
                children: [
                  if (selected != null)
                    Row(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: selected.furColor,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: selected.furAccent,
                              width: 2,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            selected.emoji,
                            style: const TextStyle(fontSize: 32),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              selected.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '이 친구로 시작할게요',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        '아래에서 동물을 골라주세요',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: _selectedId != null
                            ? _primary
                            : Colors.grey.shade200,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: _selectedId != null ? _confirm : null,
                      child: Text(
                        widget.isFirstTime ? '시작하기' : '결정',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
    );
  }
}

class _AnimalTile extends StatelessWidget {
  final Animal animal;
  final bool selected;
  final VoidCallback onTap;
  const _AnimalTile({
    required this.animal,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: animal.furColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? animal.furAccent : Colors.transparent,
            width: 3,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: animal.furAccent.withValues(alpha: 0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(animal.emoji, style: const TextStyle(fontSize: 52)),
                  const SizedBox(height: 6),
                  Text(
                    animal.name,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      color: selected ? Colors.black87 : Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ),
            if (selected)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: animal.furAccent,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, size: 14, color: Colors.white),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
