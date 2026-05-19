import 'package:flutter/material.dart';
import '../models/models.dart';

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

  void _complete() {
    if (_completed) return;
    // 포인트 적립 & 완료 기록
    AppState.i.addPoints(widget.exp.difficulty.points);
    AppState.i.completedIds.add(widget.exp.id);
    setState(() => _completed = true);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _RewardDialog(
        exp: widget.exp,
        onClose: () {
          // dialog → verify → recommendation → keyword 순으로 pop
          Navigator.of(context)
            ..pop()
            ..pop()
            ..pop()
            ..pop();
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
                  color: const Color(0xFFEEEDFE),
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
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15)),
                          const SizedBox(height: 3),
                          Text(
                            '+${exp.difficulty.points}P 획득 예정',
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF534AB7)),
                          ),
                        ],
                      ),
                    ),
                    // 난이도 뱃지
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
                onTap: () {
                  // 실제 구현 시 image_picker 패키지 사용
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('카메라 연동은 image_picker 패키지로 구현해요'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                child: Container(
                  width: double.infinity,
                  height: 160,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_a_photo_outlined,
                          size: 32, color: Colors.grey.shade400),
                      const SizedBox(height: 8),
                      Text('사진 추가하기',
                          style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 13,
                              fontWeight: FontWeight.w500)),
                      const SizedBox(height: 4),
                      Text('위치 · 시간이 자동으로 기록돼요',
                          style: TextStyle(
                              color: Colors.grey.shade400,
                              fontSize: 11)),
                    ],
                  ),
                ),
              ),

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
                            ? const Color(0xFF7F77DD)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: sel
                              ? const Color(0xFF7F77DD)
                              : Colors.grey.shade300,
                        ),
                      ),
                      child: Text(e,
                          style: TextStyle(
                              fontSize: 13,
                              color: sel
                                  ? Colors.white
                                  : Colors.black87,
                              fontWeight: sel
                                  ? FontWeight.w600
                                  : FontWeight.w400)),
                    ),
                  );
                }).toList(),
              ),

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
                    borderSide:
                    BorderSide(color: Colors.grey.shade200),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                    BorderSide(color: Colors.grey.shade200),
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
                    backgroundColor: const Color(0xFF7F77DD),
                    disabledBackgroundColor: Colors.grey.shade200,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: _completed ? null : _complete,
                  child: Text(
                    _completed
                        ? '완료됨! ✅'
                        : '완료하고 +${exp.difficulty.points}P 받기',
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

// ─── 포인트 획득 다이얼로그 ───────────────────────────────────────────────────
class _RewardDialog extends StatelessWidget {
  final Experience exp;
  final VoidCallback onClose;

  const _RewardDialog({required this.exp, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape:
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🎉', style: TextStyle(fontSize: 56)),
            const SizedBox(height: 16),
            const Text('경험 완료!',
                style: TextStyle(
                    fontSize: 22, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(exp.title,
                style: TextStyle(
                    color: Colors.grey.shade500, fontSize: 14),
                textAlign: TextAlign.center),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 24, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFEEEDFE),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('⭐',
                      style: TextStyle(fontSize: 26)),
                  const SizedBox(width: 10),
                  Text('+${exp.difficulty.points}P 획득!',
                      style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF534AB7))),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text('현재 포인트: ${AppState.i.points}P',
                style: TextStyle(
                    fontSize: 13, color: Colors.grey.shade500)),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF7F77DD),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: onClose,
                child: const Text('마이 페이지에서 꾸미기 →',
                    style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}