import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/auth_service.dart';
import '../screens/main_shell.dart';

class OnboardingProfileScreen extends StatefulWidget {
  final String userId;
  const OnboardingProfileScreen({super.key, required this.userId});

  @override
  State<OnboardingProfileScreen> createState() =>
      _OnboardingProfileScreenState();
}

class _OnboardingProfileScreenState extends State<OnboardingProfileScreen>
    with SingleTickerProviderStateMixin {
  // ── 나이 ──────────────────────────────────────────────────────────────────
  final _ageCtrl = TextEditingController();

  // ── MBTI ──────────────────────────────────────────────────────────────────
  // 인덱스 0=E/I, 1=S/N, 2=T/F, 3=J/P
  final List<List<String>> _mbtiDims = [
    ['E', 'I'],
    ['S', 'N'],
    ['T', 'F'],
    ['J', 'P'],
  ];
  final List<String?> _mbtiSel = [null, null, null, null];

  // ── 직업 ──────────────────────────────────────────────────────────────────
  final List<String> _jobOptions = [
    '학생',
    '직장인',
    '프리랜서',
    '자영업자',
    '취업준비생',
    '주부',
    '무직',
    '기타',
  ];
  String? _selectedJob;
  final _jobDetailCtrl = TextEditingController();

  // ── 취미 ──────────────────────────────────────────────────────────────────
  final List<String> _defaultHobbies = [
    '독서', '영화 감상', '운동', '요리', '여행', '게임',
    '음악', '드로잉', '사진', '등산', '코딩', '요가',
  ];
  final Set<String> _selHobbies = {};
  final List<String> _customHobbies = [];
  final _hobbyCtrl = TextEditingController();

  // ── 공통 ──────────────────────────────────────────────────────────────────
  String? _error;
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

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

  // ── 완료 처리 ─────────────────────────────────────────────────────────────
  void _finish() {
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

    AuthService.saveProfile(
      userId: widget.userId,
      age: age,
      mbti: mbti,
      job: jobFull,
      hobbies: _selHobbies.toList(),
    );
    AuthService.completeOnboarding(widget.userId, []);

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const MainShell(),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 500),
      ),
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

  // ── 색상 상수 ─────────────────────────────────────────────────────────────
  static const _bg = Color(0xFF0E0E14);
  static const _surface = Color(0xFF1A1A24);
  static const _border = Color(0xFF2C2C3E);
  static const _purple = Color(0xFF7F77DD);
  static const _purpleLight = Color(0xFFAFA9EC);
  static const _purpleDim = Color(0xFF534AB7);
  static const _textPrimary = Colors.white;
  static const _textSub = Color(0xFF888899);

  // ── 공통 위젯 ─────────────────────────────────────────────────────────────
  Widget _sectionTitle(String title) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Text(
      title,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: _purpleLight,
        letterSpacing: 0.5,
      ),
    ),
  );

  Widget _card({required Widget child}) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: _surface,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: _border, width: 0.8),
    ),
    child: child,
  );

  InputDecoration _inputDeco(String hint, {IconData? icon}) => InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: _textSub, fontSize: 14),
    prefixIcon:
    icon != null ? Icon(icon, color: _textSub, size: 18) : null,
    filled: true,
    fillColor: const Color(0xFF11111A),
    contentPadding:
    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
      borderSide: const BorderSide(color: _purple, width: 1.5),
    ),
  );

  // ── 나이 섹션 ─────────────────────────────────────────────────────────────
  Widget _ageSection() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _sectionTitle('나이'),
      _card(
        child: TextField(
          controller: _ageCtrl,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: const TextStyle(
              color: _textPrimary, fontSize: 15),
          decoration: _inputDeco('예: 25', icon: Icons.cake_outlined),
        ),
      ),
    ],
  );

  // ── MBTI 섹션 ─────────────────────────────────────────────────────────────
  Widget _mbtiSection() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _sectionTitle('MBTI'),
      _card(
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
                    color: const Color(0xFF11111A),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _border),
                  ),
                  child: Row(
                    children: dim.map((letter) {
                      final sel = _mbtiSel[di] == letter;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => setState(
                                  () => _mbtiSel[di] = letter),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            decoration: BoxDecoration(
                              color: sel
                                  ? _purple
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(9),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              letter,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: sel
                                    ? Colors.white
                                    : _textSub,
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
            // 결과 표시
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Text(
                _mbtiSel.every((s) => s != null)
                    ? _mbtiSel.join()
                    : _mbtiSel
                    .map((s) => s ?? '_')
                    .join('  '),
                key: ValueKey(_mbtiSel.join()),
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 6,
                  color: _mbtiSel.every((s) => s != null)
                      ? _purple
                      : _textSub,
                ),
              ),
            ),
          ],
        ),
      ),
    ],
  );

  // ── 직업 섹션 ─────────────────────────────────────────────────────────────
  Widget _jobSection() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _sectionTitle('직업'),
      _card(
        child: Column(
          children: [
            // 직업 칩 그리드
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _jobOptions.map((job) {
                final sel = _selectedJob == job;
                return GestureDetector(
                  onTap: () => setState(() => _selectedJob = job),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: sel ? _purpleDim : const Color(0xFF11111A),
                      borderRadius: BorderRadius.circular(99),
                      border: Border.all(
                        color: sel ? _purple : _border,
                        width: sel ? 1.5 : 0.8,
                      ),
                    ),
                    child: Text(
                      job,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: sel ? Colors.white : _textSub,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            // 상세 직업 입력
            TextField(
              controller: _jobDetailCtrl,
              style:
              const TextStyle(color: _textPrimary, fontSize: 14),
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

  // ── 취미 섹션 ─────────────────────────────────────────────────────────────
  Widget _hobbySection() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _sectionTitle('취미'),
      _card(
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
                return GestureDetector(
                  onTap: () => setState(() {
                    sel
                        ? _selHobbies.remove(h)
                        : _selHobbies.add(h);
                  }),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: sel ? _purpleDim : const Color(0xFF11111A),
                      borderRadius: BorderRadius.circular(99),
                      border: Border.all(
                        color: sel ? _purple : _border,
                        width: sel ? 1.5 : 0.8,
                      ),
                    ),
                    child: Text(
                      h,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: sel ? Colors.white : _textSub,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            // 직접 추가
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _hobbyCtrl,
                    style: const TextStyle(
                        color: _textPrimary, fontSize: 14),
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
                      color: _purpleDim,
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

  // ── 빌드 ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: Column(
            children: [
              // ── 헤더 ────────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '나를 소개해요',
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        height: 1.22,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '입력한 정보로 더 맞춤화된 경험을 추천해드릴게요',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.40),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ── 스크롤 영역 ──────────────────────────────────────────────
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

                      // ── 에러 메시지 ────────────────────────────────────
                      if (_error != null) ...[
                        Row(
                          children: [
                            const Icon(Icons.error_outline,
                                color: Color(0xFFE57373), size: 15),
                            const SizedBox(width: 6),
                            Text(
                              _error!,
                              style: const TextStyle(
                                color: Color(0xFFE57373),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                      ],

                      // ── 완료 버튼 ──────────────────────────────────────
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: _finish,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _purple,
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