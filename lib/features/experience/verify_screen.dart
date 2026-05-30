import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/experience.dart';
import '../../models/app_state.dart';
import '../../models/wardrobe_item.dart';
import '../../models/deco_item.dart';
import '../../services/deco_ai_service.dart';
import '../shell/main_shell.dart';

class VerifyScreen extends StatefulWidget {
  final Experience exp;
  const VerifyScreen({super.key, required this.exp});

  @override
  State<VerifyScreen> createState() => _VerifyScreenState();
}

class _VerifyScreenState extends State<VerifyScreen> {
  final Set<String> _emotions = {};
  final _reviewCtrl = TextEditingController();
  bool _completed = false;

  // ── 사진 관련 ──────────────────────────────────────────────
  XFile? _photo;
  final _picker = ImagePicker();

  static const _emotionOptions = [
    '예상 밖이었어',
    '행복했어',
    '힘들었어',
    '뿌듯했어',
    '다시 하고 싶어',
    '두 번은 모르겠어',
    '성장한 것 같아',
    '생각보다 쉬웠어',
  ];

  @override
  void dispose() {
    _reviewCtrl.dispose();
    super.dispose();
  }

  // ── 사진 선택 바텀시트 ──────────────────────────────────────
  Future<void> _showPhotoOptions() async {
    await showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 핸들
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '인증 사진 추가',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F3E3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.camera_alt_outlined,
                      color: Color(0xFF7DB879), size: 22),
                ),
                title: const Text('카메라로 찍기',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                subtitle: Text('지금 바로 사진을 촬영해요',
                    style: TextStyle(
                        fontSize: 12, color: Colors.grey.shade500)),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F3E3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.photo_library_outlined,
                      color: Color(0xFF7DB879), size: 22),
                ),
                title: const Text('갤러리에서 선택',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                subtitle: Text('내 기기의 사진을 불러와요',
                    style: TextStyle(
                        fontSize: 12, color: Colors.grey.shade500)),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.gallery);
                },
              ),
              // 이미 사진이 있으면 삭제 옵션 추가
              if (_photo != null) ...[
                const Divider(height: 1, indent: 16, endIndent: 16),
                ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.delete_outline,
                        color: Colors.red.shade400, size: 22),
                  ),
                  title: Text('사진 삭제',
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: Colors.red.shade400)),
                  onTap: () {
                    Navigator.pop(ctx);
                    setState(() => _photo = null);
                  },
                ),
              ],
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1920,
      );
      if (picked != null) {
        setState(() => _photo = picked);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(source == ImageSource.camera
              ? '카메라 권한을 허용해 주세요'
              : '사진 접근 권한을 허용해 주세요'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red.shade400,
        ),
      );
    }
  }

  // ── 완료 처리 ───────────────────────────────────────────────
  Future<void> _complete() async {
    if (_completed) return;
    final newItems = AppState.i.completeExperience(widget.exp);
    setState(() => _completed = true);

    // AI 소품 생성 (비동기)
    final decoItem = await DecoAiService.generateDecoItem(widget.exp);
    if (decoItem != null) {
      AppState.i.addAiDecoItem(decoItem);
    }

    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _RewardDialog(
        exp: widget.exp,
        newItems: newItems,
        newDecoItem: decoItem,
        onClose: () {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (_) => const MainShell(initialIndex: 3),
            ),
            (route) => false,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final exp = widget.exp;

    return Scaffold(
      appBar: AppBar(
        title: const Text('경험 완료하기',
            style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── 경험 요약 배너 ─────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F3E3),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Text(exp.difficulty.emoji,
                        style: const TextStyle(fontSize: 32)),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(exp.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700, fontSize: 15)),
                          const SizedBox(height: 3),

                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: exp.difficulty.color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(exp.difficulty.label,
                          style: TextStyle(
                              fontSize: 11,
                              color: exp.difficulty.color,
                              fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // ── 인증 사진 ──────────────────────────────────────────
              const Text('인증 사진',
                  style: TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w600)),
              const SizedBox(height: 10),

              GestureDetector(
                onTap: _showPhotoOptions,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: _photo == null
                  // ── 사진 없음: 플레이스홀더 ──
                      ? Container(
                    key: const ValueKey('placeholder'),
                    width: double.infinity,
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(16),
                      border:
                      Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_a_photo_outlined,
                            size: 36,
                            color: Colors.grey.shade400),
                        const SizedBox(height: 10),
                        Text('사진 추가하기',
                            style: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: 14,
                                fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        Text('카메라 촬영 또는 갤러리에서 선택',
                            style: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: 12)),
                        const SizedBox(height: 2),
                        Text('위치 · 시간이 자동으로 기록돼요',
                            style: TextStyle(
                                color: Colors.grey.shade400,
                                fontSize: 11)),
                      ],
                    ),
                  )
                  // ── 사진 있음: 미리보기 ──
                      : Stack(
                    key: const ValueKey('preview'),
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.file(
                          File(_photo!.path),
                          width: double.infinity,
                          height: 260,
                          fit: BoxFit.cover,
                        ),
                      ),
                      // 변경/삭제 오버레이 버튼
                      Positioned(
                        top: 10,
                        right: 10,
                        child: GestureDetector(
                          onTap: _showPhotoOptions,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.55),
                              borderRadius:
                              BorderRadius.circular(20),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.edit,
                                    color: Colors.white, size: 14),
                                SizedBox(width: 4),
                                Text('변경',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight:
                                        FontWeight.w600)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              if (_photo == null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.error_outline,
                        size: 14, color: Colors.red),
                    const SizedBox(width: 4),
                    Text('사진이 없습니다',
                        style: TextStyle(
                            fontSize: 12, color: Colors.red.shade600)),
                  ],
                ),
              ],

              const SizedBox(height: 28),

              // ── 감정 태그 ──────────────────────────────────────────
              const Text('어떤 감정이었나요?',
                  style: TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text('여러 개 선택 가능해요',
                  style: TextStyle(
                      fontSize: 12, color: Colors.grey.shade500)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _emotionOptions.map((e) {
                  final sel = _emotions.contains(e);
                  return GestureDetector(
                    onTap: () => setState(() =>
                    sel ? _emotions.remove(e) : _emotions.add(e)),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: sel
                            ? const Color(0xFF7DB879)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: sel
                              ? const Color(0xFF7DB879)
                              : Colors.grey.shade300,
                        ),
                      ),
                      child: Text(e,
                          style: TextStyle(
                              fontSize: 13,
                              color:
                              sel ? Colors.white : Colors.black87,
                              fontWeight: sel
                                  ? FontWeight.w600
                                  : FontWeight.w400)),
                    ),
                  );
                }).toList(),
              ),
              if (_emotions.isEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.error_outline,
                        size: 14, color: Colors.red),
                    const SizedBox(width: 4),
                    Text('감정을 선택해주세요',
                        style: TextStyle(
                            fontSize: 12, color: Colors.red.shade600)),
                  ],
                ),
              ],

              const SizedBox(height: 28),

              // ── 짧은 후기 ──────────────────────────────────────────
              const Text('짧은 후기',
                  style: TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w600)),
              const SizedBox(height: 10),
              TextField(
                controller: _reviewCtrl,
                maxLines: 3,
                maxLength: 150,
                decoration: InputDecoration(
                  hintText: '이 경험은 어땠나요? 솔직하게 적어봐요 :)',
                  hintStyle: TextStyle(
                      fontSize: 13, color: Colors.grey.shade400),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
              ),

              const SizedBox(height: 28),

              // ── 완료 버튼 ──────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 54,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF7DB879),
                    disabledBackgroundColor: Colors.grey.shade200,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: (_completed || _photo == null || _emotions.isEmpty)
                      ? null
                      : _complete,
                  child: Text(
                    _completed
                        ? '완료됨! ✅'
                        : '경험 완료하기 ✅',
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── 포인트 획득 + 아이템 해금 다이얼로그 ────────────────────────────────────
class _RewardDialog extends StatelessWidget {
  final Experience exp;
  final List<WardrobeItem> newItems;
  final DecoItem? newDecoItem;
  final VoidCallback onClose;

  const _RewardDialog({
    required this.exp,
    required this.newItems,
    this.newDecoItem,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(newItems.isNotEmpty ? '🎁' : '🎉',
                  style: const TextStyle(fontSize: 56)),
              const SizedBox(height: 16),
              const Text('경험 완료!',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text(exp.title,
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                  textAlign: TextAlign.center),
              const SizedBox(height: 20),

              // ── 포인트 획득 배너 ──────────────────────────────────────────
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F3E3),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('✨', style: TextStyle(fontSize: 20)),
                    const SizedBox(width: 10),
                    Text('+${exp.difficulty.points}P 획득',
                        style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF5A9A4A))),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text('현재 보유 포인트: ${AppState.i.points}P',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),


              // ── AI 생성 소품 보상 ─────────────────────────────────
              if (newDecoItem != null) ...[
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F0FF),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFB39DDB)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Text('✨', style: TextStyle(fontSize: 16)),
                          SizedBox(width: 6),
                          Text('새 소품 획득!',
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF5E35B1))),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          newDecoItem!.imageUrl != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    newDecoItem!.imageUrl!,
                                    width: 44,
                                    height: 44,
                                    fit: BoxFit.contain,
                                    errorBuilder: (_, __, ___) => Text(newDecoItem!.emoji, style: const TextStyle(fontSize: 36)),
                                  ),
                                )
                              : Text(newDecoItem!.emoji,
                                  style: const TextStyle(fontSize: 36)),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(newDecoItem!.name,
                                  style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700)),
                              const SizedBox(height: 2),
                              Text(newDecoItem!.hint,
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade500)),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],

              // ── 새로 해금된 캐릭터/방 아이템 ─────────────────────
              if (newItems.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF8E1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFFFCC02)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Text('🎁', style: TextStyle(fontSize: 16)),
                          SizedBox(width: 6),
                          Text('아이템 해금!',
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF795548))),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ...newItems.map((item) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 3),
                            child: Row(
                              children: [
                                Text(item.emoji,
                                    style: const TextStyle(fontSize: 22)),
                                const SizedBox(width: 8),
                                Text(item.name,
                                    style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600)),
                              ],
                            ),
                          )),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // ── 확인 버튼 ─────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF7DB879),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: onClose,
                  child: const Text('방 꾸미러 가기 →',
                      style:
                          TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
