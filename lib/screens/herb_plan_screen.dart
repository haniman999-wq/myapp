import 'package:flutter/material.dart';

import '../models/customer.dart';
import '../models/herb_alert.dart';
import '../services/customer_database.dart';
import '../theme.dart';
import '../utils/date_format.dart';
import '../widgets/customer_name.dart';

/// 한약 복약 시작 / 수정 화면.
///
/// 복약 시작일과 확인 전화 알림 날짜(최대 [kMaxHerbAlerts]개)를 정합니다.
/// 처음 시작할 때는 시작일 + [kDefaultHerbAlertDays] 가 자동으로 채워집니다.
class HerbPlanScreen extends StatefulWidget {
  const HerbPlanScreen({
    super.key,
    required this.customer,
    this.pendingAlerts = const [],
  });

  final Customer customer;

  /// 이미 잡혀 있는 미완료 알림 (수정할 때).
  final List<HerbAlert> pendingAlerts;

  @override
  State<HerbPlanScreen> createState() => _HerbPlanScreenState();
}

class _HerbPlanScreenState extends State<HerbPlanScreen> {
  late DateTime _start;
  late List<DateTime> _dates;

  bool get _isNew => !widget.customer.isHerbal;

  @override
  void initState() {
    super.initState();
    _start = dateOnly(widget.customer.herbStart ?? today());
    _dates = _isNew
        ? [for (final d in kDefaultHerbAlertDays) _start.add(Duration(days: d))]
        : [for (final a in widget.pendingAlerts) dateOnly(a.date)];
    _sort();
  }

  void _sort() => _dates.sort();

  bool get _isFull => _dates.length >= kMaxHerbAlerts;

  bool _has(DateTime d) => _dates.any((x) => isSameDate(x, d));

  void _add(DateTime d) {
    final day = dateOnly(d);
    if (_has(day)) return;
    if (_isFull) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('알림은 최대 $kMaxHerbAlerts개까지 설정할 수 있어요')),
      );
      return;
    }
    setState(() {
      _dates.add(day);
      _sort();
    });
  }

  Future<DateTime?> _pick(DateTime initial, {DateTime? first}) {
    final now = DateTime.now();
    return showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: first ?? DateTime(now.year - 1),
      lastDate: DateTime(now.year + 3),
    );
  }

  /// 시작일을 바꾸면 알림 날짜들도 같은 만큼 함께 옮깁니다.
  Future<void> _changeStart() async {
    final picked = await _pick(_start);
    if (picked == null) return;
    final delta = dateOnly(picked).difference(_start);
    setState(() {
      _start = dateOnly(picked);
      _dates = [for (final d in _dates) d.add(delta)];
    });
  }

  Future<void> _addFromCalendar() async {
    final initial = _dates.isEmpty
        ? _start.add(const Duration(days: 15))
        : _dates.last.add(const Duration(days: 7));
    final picked = await _pick(initial, first: _start);
    if (picked != null) _add(picked);
  }

  Future<void> _save() async {
    await CustomerDatabase.instance.saveHerbPlan(
      customerId: widget.customer.id!,
      start: _start,
      dates: _dates,
    );
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    const quickDays = [7, 15, 25, 30, 45, 60, 90];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: kHerbPurple,
        foregroundColor: Colors.white,
        title: Text(_isNew ? '한약 복약 시작' : '복약 일정 수정'),
        actions: [
          IconButton(
            onPressed: _save,
            icon: const Icon(Icons.check),
            tooltip: '저장',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          CustomerName(
            customer: widget.customer.copyWith(herbStart: _start),
            fontSize: 20,
          ),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: const Icon(
                Icons.play_circle_outline,
                color: kHerbPurple,
              ),
              title: const Text('복약 시작일'),
              subtitle: Text(
                formatDateWithWeekday(_start),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              trailing: const Icon(Icons.edit_calendar),
              onTap: _changeStart,
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(4, 4, 4, 0),
            child: Text(
              '시작일을 바꾸면 아래 알림 날짜도 같은 만큼 함께 옮겨져요.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Text(
                '확인 전화 알림',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: kHerbPurple,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                '${_dates.length} / $kMaxHerbAlerts',
                style: const TextStyle(color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            '그날 아침 요약 알림에 들어가고, 재예약과 상관없이 연락 탭에 표시돼요.',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          if (_dates.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text(
                  '알림 날짜가 없어요. 아래에서 추가하세요.',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ),
          for (final d in _dates)
            Card(
              margin: const EdgeInsets.symmetric(vertical: 3),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: kHerbPurple.withValues(alpha: 0.12),
                  child: const Icon(
                    Icons.notifications_active,
                    color: kHerbPurple,
                  ),
                ),
                title: Text(
                  '복약 ${d.difference(_start).inDays}일',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(formatDateWithWeekday(d)),
                trailing: IconButton(
                  icon: const Icon(Icons.close),
                  tooltip: '이 알림 빼기',
                  onPressed: () => setState(() => _dates.remove(d)),
                ),
              ),
            ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _isFull ? null : _addFromCalendar,
            icon: const Icon(Icons.calendar_month),
            label: const Text('달력에서 날짜 골라 추가'),
            style: OutlinedButton.styleFrom(
              foregroundColor: kHerbPurple,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            '빠른 추가 (시작일 기준)',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              for (final days in quickDays)
                ActionChip(
                  label: Text('+$days일'),
                  onPressed: _has(_start.add(Duration(days: days))) || _isFull
                      ? null
                      : () => _add(_start.add(Duration(days: days))),
                ),
            ],
          ),
          const SizedBox(height: 28),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: kHerbPurple,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            onPressed: _save,
            icon: const Icon(Icons.save),
            label: Text(_isNew ? '복약 시작' : '저장'),
          ),
        ],
      ),
    );
  }
}

/// 복약이 밀렸을 때 며칠 미룰지 묻습니다. 취소하면 null.
Future<int?> showPostponeDialog(BuildContext context) {
  return showDialog<int>(
    context: context,
    builder: (_) => const _PostponeDialog(),
  );
}

class _PostponeDialog extends StatefulWidget {
  const _PostponeDialog();

  @override
  State<_PostponeDialog> createState() => _PostponeDialogState();
}

class _PostponeDialogState extends State<_PostponeDialog> {
  final _controller = TextEditingController(text: '7');

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  int? get _days {
    final v = int.tryParse(_controller.text.trim());
    return v == null || v <= 0 ? null : v;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('복약 일정 미루기'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('약을 못 먹은 날 수만큼 복약 시작일과 남은 알림을 모두 뒤로 미뤄요.'),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            children: [
              for (final d in const [3, 5, 7, 10, 14])
                ChoiceChip(
                  label: Text('$d일'),
                  selected: _days == d,
                  onSelected: (_) => setState(() => _controller.text = '$d'),
                ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: '미룰 날 수',
              suffixText: '일',
            ),
            onChanged: (_) => setState(() {}),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('취소'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: kHerbPurple),
          onPressed: _days == null
              ? null
              : () => Navigator.of(context).pop(_days),
          child: const Text('미루기'),
        ),
      ],
    );
  }
}
