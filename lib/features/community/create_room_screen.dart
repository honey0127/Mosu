import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/community_service.dart';

class CreateRoomScreen extends StatefulWidget {
  const CreateRoomScreen({super.key});

  @override
  State<CreateRoomScreen> createState() => _CreateRoomScreenState();
}

class _CreateRoomScreenState extends State<CreateRoomScreen> {
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  static const _purple = Color(0xFF7DB879);
  static const _bg = Color(0xFFF2F2F0);

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      setState(() => _error = '방 이름을 입력해주세요.');
      return;
    }
    if (name.length > 20) {
      setState(() => _error = '방 이름은 20자 이내로 입력해주세요.');
      return;
    }

    final userId = AuthService.currentUserId;
    if (userId == null) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    final room = await CommunityService.createRoom(
      creatorId: userId,
      name: name,
      description: _descCtrl.text.trim(),
    );

    if (!mounted) return;
    setState(() => _loading = false);
    Navigator.of(context).pop(room);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              size: 18, color: Color(0xFF444444)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '방 만들기',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: Color(0xFF2A2A2A),
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              const Text(
                '같이 경험을 쌓을\n그룹을 만들어봐요',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  height: 1.3,
                  color: Color(0xFF2A2A2A),
                ),
              ),
              const SizedBox(height: 32),

              _label('방 이름 *'),
              const SizedBox(height: 8),
              _field(
                controller: _nameCtrl,
                hint: '예: 대구 탐험대',
                maxLength: 20,
              ),
              const SizedBox(height: 20),

              _label('한 줄 소개 (선택)'),
              const SizedBox(height: 8),
              _field(
                controller: _descCtrl,
                hint: '어떤 그룹인지 짧게 소개해주세요',
                maxLength: 50,
                maxLines: 2,
              ),

              if (_error != null) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.error_outline,
                        color: Color(0xFFE57373), size: 16),
                    const SizedBox(width: 6),
                    Text(_error!,
                        style: const TextStyle(
                            color: Color(0xFFE57373), fontSize: 13)),
                  ],
                ),
              ],

              const SizedBox(height: 36),

              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _loading ? null : _create,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _purple,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey.shade200,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Text(
                          '방 만들기',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String t) => Text(
        t,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Color(0xFF444444),
        ),
      );

  Widget _field({
    required TextEditingController controller,
    required String hint,
    int maxLength = 100,
    int maxLines = 1,
  }) =>
      TextField(
        controller: controller,
        maxLength: maxLength,
        maxLines: maxLines,
        style: const TextStyle(fontSize: 15, color: Color(0xFF2A2A2A)),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle:
              TextStyle(color: Colors.grey.shade400, fontSize: 14),
          filled: true,
          fillColor: Colors.white,
          counterStyle: TextStyle(
              color: Colors.grey.shade400, fontSize: 11),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
                color: Color(0xFF7DB879), width: 1.5),
          ),
        ),
      );
}
