import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/auth_service.dart';
import '../shell/main_shell.dart';

class OnboardingProfileScreen extends StatefulWidget {
  final String userId;
  const OnboardingProfileScreen({super.key, required this.userId});

  @override
  State<OnboardingProfileScreen> createState() =>
      _OnboardingProfileScreenState();
}

class _OnboardingProfileScreenState extends State<OnboardingProfileScreen>
    with SingleTickerProviderStateMixin {
  final _ageCtrl = TextEditingController();

  final List<List<String>> _mbtiDims = [
    ['E', 'I'],
    ['S', 'N'],
    ['T', 'F'],
    ['J', 'P'],
  ];
  final List<String?> _mbtiSel = [null, null, null, null];

  final List<String> _jobOptions = [
    '학생', '직장인', '프리랜서', '자영업자', '취업준비생', '주부', '무직', '기타',
  ];
  String? _selectedJob;
  final _jobDetailCtrl = TextEditingController();

  final List<String> _defaultHobbies = [
    '독서', '영화 감상', '운동', '요리', '여행', '게임',
    '음악', '드로잉', '사진', '등산', '코딩', '요가',
  ];
  final Set<String> _selHobbies = {};
  final List<String> _customHobbies = [];
  final _hobbyCtrl = TextEditingController();

  String? _error;
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  static const _green = Color(0xFF7DB879);
  static const _greenDark = Color(0xFF5A9A4A);
  static const _greenLight = Color(0xFFE8F3E3);
  static const _bg = Color(0xFFF2F2F0);
  static const _textPrimary = Color(0xFF1A1A1A);
  static const _textSub = Color(0xFF888888);
  static const _border = Color(0xFFDDDDDD);

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _ageCtrl.dispose();
    _jobDetailCtrl.dispose();
    _hobbyCtrl.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    final age = int.tryParse(_ageCtrl.text.trim());
    if (age == null || age < 1 || age > 120) {
      setState(() => _error = '올바른 나이를 입력해 주세요.');
      return;
    }
    if (_mbtiSel.any((s) => s == null)) {
      setState(() => _error = 'MBTI 4가지를 모두 선택해 주세요.');
      return;
    }
    if (_selectedJob == null) {
      setState(() => _error = '직업을 선택해 주세요.');
      return;
    }
    if (_selHobbies.isEmpty) {
      setState(() => _error = '취미를 하나 이상 선택해 주세요.');
      return;
    }

    final mbti = _mbtiSel.join();
    final jobFull = _jobDetailCtrl.text.trim().isNotEmpty
        ? '$_selectedJob · ${_jobDetailCtrl.text.trim()}'
        : _selectedJob!;

    await AuthService.saveProfile(
      userId: widget.userId,
      age: age,
      mbti: mbti,
      job: jobFull,
      hobbies: _selHobbies.toList(),
    );
    await AuthService.completeOnboarding(widget.userId, []);

    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      PageRouteBuilder(
        pageBuilder: (_, _, _) => const MainShell(),
        transitionsBuilder: (_, anim, _, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 500),
      ),
      (route) => false,
    );
  }

  void _addCustomHobby() {
    final val = _hobbyCtrl.text.trim();
    if (val.isEmpty) return;
    setState(() {
      if (!_defaultHobbies.contains(val) && !_customHobbies.contains(val)) {
        _customHobbies.add(val);
      }
      _selHobbies.add(val);
    });
    _hobbyCtrl.clear();
  }

  Widget _sectionLabel(String t) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(
      t,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: _textPrimary,
      ),
    ),
  );

  InputDecoration _inputDeco(String hint, {IconData? icon}) => InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: _textSub, fontSize: 14),
    prefixIcon: icon != null ? Icon(icon, color: _textSub, size: 18) : null,
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: _border),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: _border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: _green, width: 1.5),
    ),
  );

  Widget _chip(String label, bool selected, VoidCallback onTap) =>
      GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? _green : Colors.white,
            borderRadius: BorderRadius.circular(99),
            border: Border.all(
              color: selected ? _green : _border,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: selected ? Colors.white : _textPrimary,
            ),
          ),
        ),
      );

  Widget _ageSection() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _sectionLabel('나이'),
      TextField(
        controller: _ageCtrl,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        style: const TextStyle(color: _textPrimary, fontSize: 15),
        decoration: _inputDeco('예: 25', icon: Icons.cake_outlined),
      ),
    ],
  );

  Widget _mbtiSection() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _sectionLabel('MBTI'),
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _border),
        ),
        child: Column(
          children: [
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 4,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 3.8,
              ),
              itemBuilder: (_, di) {
                final dim = _mbtiDims[di];
                return Container(
                  decoration: BoxDecoration(
                    color: _greenLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: dim.asMap().entries.map((entry) {
                      final letter = entry.value;
                      final sel = _mbtiSel[di] == letter;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () =>
                              setState(() => _mbtiSel[di] = letter),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 160),
                            margin: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              color: sel ? _green : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              letter,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: sel ? Colors.white : _textSub,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Text(
                _mbtiSel.every((s) => s != null)
                    ? _mbtiSel.join()
                    : _mbtiSel.map((s) => s ?? '_').join('  '),
                key: ValueKey(_mbtiSel.join()),
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 6,
                  color: _mbtiSel.every((s) => s != null)
                      ? _green
                      : _textSub,
                ),
              ),
            ),
          ],
        ),
      ),
    ],
  );

  Widget _jobSection() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _sectionLabel('직업'),
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _jobOptions.map((job) {
                final sel = _selectedJob == job;
                return _chip(job, sel, () => setState(() => _selectedJob = job));
              }).toList(),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _jobDetailCtrl,
              style: const TextStyle(color: _textPrimary, fontSize: 14),
              decoration: _inputDeco(
                '상세 직업 (선택)  예: 백엔드 개발자',
                icon: Icons.work_outline,
              ),
            ),
          ],
        ),
      ),
    ],
  );

  Widget _hobbySection() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _sectionLabel('취미'),
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ..._defaultHobbies,
                ..._customHobbies,
              ].map((h) {
                final sel = _selHobbies.contains(h);
                return _chip(h, sel, () => setState(() {
                  sel ? _selHobbies.remove(h) : _selHobbies.add(h);
                }));
              }).toList(),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _hobbyCtrl,
                    style:
                        const TextStyle(color: _textPrimary, fontSize: 14),
                    onSubmitted: (_) => _addCustomHobby(),
                    decoration: _inputDeco('직접 입력 후 추가'),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _addCustomHobby,
                  child: Container(
                    height: 46,
                    width: 46,
                    decoration: BoxDecoration(
                      color: _greenDark,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.add,
                        color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '나를 소개해요',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        height: 1.22,
                        color: _textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '입력한 정보로 더 맞춤화된 경험을 추천해드릴게요',
                      style: TextStyle(fontSize: 13, color: _textSub),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _ageSection(),
                      const SizedBox(height: 20),
                      _mbtiSection(),
                      const SizedBox(height: 20),
                      _jobSection(),
                      const SizedBox(height: 20),
                      _hobbySection(),
                      const SizedBox(height: 24),
                      if (_error != null) ...[
                        Row(
                          children: [
                            const Icon(Icons.error_outline,
                                color: Color(0xFFE57373), size: 15),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                _error!,
                                style: const TextStyle(
                                  color: Color(0xFFE57373),
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                      ],
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: _finish,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _green,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text(
                            '다음  →',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
