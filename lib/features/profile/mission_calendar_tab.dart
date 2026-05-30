import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../services/community_repository.dart';

/// 마이 → 캘린더 탭.
/// 내 인증 기록을 날짜별로 모아, 승인된 날은 파랑·거절된 날은 빨강으로 표시한다.
/// (성공/실패 기준 = 사진 인증 승인 결과. 0003_verifications.sql 기반)
class MissionCalendarTab extends StatefulWidget {
  const MissionCalendarTab({super.key});

  @override
  State<MissionCalendarTab> createState() => _MissionCalendarTabState();
}

enum _DayStatus { success, fail, pending }

class _MissionCalendarTabState extends State<MissionCalendarTab> {
  static const _success = Color(0xFF4A90E2); // 파랑
  static const _fail = Color(0xFFE2574A); // 빨강
  static const _weekdays = ['일', '월', '화', '수', '목', '금', '토'];

  final _community = CommunityRepository();

  bool _loading = true;
  String? _error;
  List<MyVerification> _all = const [];
  Map<DateTime, _DayStatus> _statusByDay = const {};

  DateTime _month = _firstOfMonth(DateTime.now());
  DateTime? _selected;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await _community.ensureSignedIn();
      final list = await _community.myVerifications();
      if (!mounted) return;
      setState(() {
        _all = list;
        _statusByDay = _aggregate(list);
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e is CommunityException ? e.message : '캘린더를 불러오지 못했어요.';
        _loading = false;
      });
    }
  }

  /// 하루에 여러 인증이 있으면 우선순위: 성공 > 실패 > 대기.
  Map<DateTime, _DayStatus> _aggregate(List<MyVerification> list) {
    final map = <DateTime, _DayStatus>{};
    for (final v in list) {
      final day = _dateOnly(v.createdAt);
      final s = v.isApproved
          ? _DayStatus.success
          : v.isRejected
          ? _DayStatus.fail
          : _DayStatus.pending;
      final cur = map[day];
      if (cur == null || s.index < cur.index) map[day] = s;
    }
    return map;
  }

  void _shiftMonth(int delta) {
    setState(() {
      _month = DateTime(_month.year, _month.month + delta);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return _ErrorView(message: _error!, onRetry: _load);
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 80),
        children: [
          _monthHeader(),
          const SizedBox(height: 12),
          _legend(),
          const SizedBox(height: 16),
          _weekdayRow(),
          const SizedBox(height: 4),
          _grid(),
          const SizedBox(height: 20),
          if (_selected != null) _dayDetail(),
        ],
      ),
    );
  }

  // ── 월 이동 헤더 ──────────────────────────────────────────────────────────
  Widget _monthHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          onPressed: () => _shiftMonth(-1),
          icon: const Icon(Icons.chevron_left),
        ),
        Text(
          '${_month.year}년 ${_month.month}월',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        IconButton(
          onPressed: () => _shiftMonth(1),
          icon: const Icon(Icons.chevron_right),
        ),
      ],
    );
  }

  Widget _legend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _legendDot(_success, '성공'),
        const SizedBox(width: 20),
        _legendDot(_fail, '실패'),
        const SizedBox(width: 20),
        _legendDot(Colors.grey.shade300, '대기'),
      ],
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget _weekdayRow() {
    return Row(
      children: List.generate(7, (i) {
        final color = i == 0
            ? _fail
            : i == 6
            ? _success
            : Colors.grey.shade500;
        return Expanded(
          child: Center(
            child: Text(
              _weekdays[i],
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
        );
      }),
    );
  }

  // ── 날짜 그리드 ───────────────────────────────────────────────────────────
  Widget _grid() {
    final leadingBlanks = _month.weekday % 7; // 일요일 시작 보정
    final daysInMonth = DateTime(_month.year, _month.month + 1, 0).day;
    final cellCount = leadingBlanks + daysInMonth;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: cellCount,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        childAspectRatio: 1,
      ),
      itemBuilder: (_, i) {
        if (i < leadingBlanks) return const SizedBox.shrink();
        return _dayCell(i - leadingBlanks + 1);
      },
    );
  }

  Widget _dayCell(int day) {
    final date = DateTime(_month.year, _month.month, day);
    final status = _statusByDay[date];
    final isToday = _isSameDay(date, DateTime.now());
    final isSelected = _selected != null && _isSameDay(date, _selected!);

    Color? bg;
    Color fg = Colors.black87;
    switch (status) {
      case _DayStatus.success:
        bg = _success;
        fg = Colors.white;
      case _DayStatus.fail:
        bg = _fail;
        fg = Colors.white;
      case _DayStatus.pending:
        bg = Colors.grey.shade300;
      case null:
        break;
    }

    return GestureDetector(
      onTap: () => setState(() => _selected = date),
      child: Container(
        margin: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: bg,
          shape: BoxShape.circle,
          border: isSelected
              ? Border.all(color: AppColors.primary, width: 2)
              : isToday
              ? Border.all(color: Colors.grey.shade400)
              : null,
        ),
        alignment: Alignment.center,
        child: Text(
          '$day',
          style: TextStyle(
            fontSize: 13,
            color: fg,
            fontWeight: status != null ? FontWeight.w700 : FontWeight.w400,
          ),
        ),
      ),
    );
  }

  // ── 선택한 날 상세 ────────────────────────────────────────────────────────
  Widget _dayDetail() {
    final sel = _selected!;
    final items = _all.where((v) => _isSameDay(v.createdAt, sel)).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${sel.month}월 ${sel.day}일',
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        if (items.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              '이 날은 인증이 없어요.',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
            ),
          )
        else
          ...items.map(_detailRow),
      ],
    );
  }

  Widget _detailRow(MyVerification v) {
    final (label, color) = v.isApproved
        ? ('성공', _success)
        : v.isRejected
        ? ('실패', _fail)
        : ('대기중', Colors.grey.shade500);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              v.photoUrl,
              width: 44,
              height: 44,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Container(
                width: 44,
                height: 44,
                color: Colors.grey.shade100,
                child: Icon(
                  Icons.broken_image_outlined,
                  size: 18,
                  color: Colors.grey.shade400,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  v.roomName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (v.caption != null && v.caption!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    v.caption!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // ── 날짜 헬퍼 ─────────────────────────────────────────────────────────────
  static DateTime _firstOfMonth(DateTime d) => DateTime(d.year, d.month);
  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
  static bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

class _ErrorView extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        const SizedBox(height: 80),
        const Center(
          child: Icon(Icons.error_outline, size: 40, color: Colors.redAccent),
        ),
        const SizedBox(height: 12),
        Center(
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: OutlinedButton(onPressed: onRetry, child: const Text('다시 시도')),
        ),
      ],
    );
  }
}
