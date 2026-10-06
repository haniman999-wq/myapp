import 'package:flutter/material.dart';

import '../models/appointment.dart';
import '../services/customer_database.dart';
import '../theme.dart';
import '../utils/date_format.dart';

/// 예약을 추가하거나 날짜·상태를 바꾸는 아래쪽 시트.
/// 저장/삭제는 시트 안에서 바로 DB 에 반영합니다.
Future<void> showAppointmentSheet(
  BuildContext context, {
  required int customerId,
  required String customerName,
  Appointment? existing,
  DateTime? initialDate,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _AppointmentSheet(
      customerId: customerId,
      customerName: customerName,
      existing: existing,
      initialDate: initialDate,
    ),
  );
}

class _AppointmentSheet extends StatefulWidget {
  const _AppointmentSheet({
    required this.customerId,
    required this.customerName,
    this.existing,
    this.initialDate,
  });

  final int customerId;
  final String customerName;
  final Appointment? existing;
  final DateTime? initialDate;

  @override
  State<_AppointmentSheet> createState() => _AppointmentSheetState();
}

class _AppointmentSheetState extends State<_AppointmentSheet> {
  late DateTime _date;
  late AppointmentStatus _status;
  int? _minuteOfDay;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    _date = widget.existing?.date ?? dateOnly(widget.initialDate ?? today());
    _status = widget.existing?.status ?? _defaultStatusFor(_date);
    _minuteOfDay = widget.existing?.minuteOfDay;
  }

  /// 오늘·미래 날짜면 '예약', 지난 날짜면 '내원'으로 기본 선택.
  AppointmentStatus _defaultStatusFor(DateTime date) => !date.isBefore(today())
      ? AppointmentStatus.booked
      : AppointmentStatus.visited;

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 5),
    );
    if (picked == null) return;
    setState(() {
      _date = dateOnly(picked);
      if (!_isEditing) _status = _defaultStatusFor(_date);
    });
  }

  Future<void> _pickTime() async {
    final m = _minuteOfDay ?? 10 * 60;
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: m ~/ 60, minute: m % 60),
      helpText: '예약 시간',
    );
    if (picked == null) return;
    setState(() => _minuteOfDay = picked.hour * 60 + picked.minute);
  }

  Future<void> _save() async {
    final base =
        widget.existing ??
        Appointment(
          customerId: widget.customerId,
          date: _date,
          status: _status,
        );
    await CustomerDatabase.instance.saveAppointment(
      base.copyWith(
        date: _date,
        status: _status,
        minuteOfDay: _minuteOfDay,
        clearTime: _minuteOfDay == null,
      ),
    );
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    await CustomerDatabase.instance.deleteAppointment(widget.existing!.id!);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        0,
        20,
        20 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '${widget.customerName} · ${_isEditing ? '일정 수정' : '일정 추가'}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: _pickDate,
            icon: const Icon(Icons.calendar_today_outlined),
            label: Text(formatDateWithWeekday(_date)),
            style: OutlinedButton.styleFrom(
              foregroundColor: kPrimaryGreenDark,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickTime,
                  icon: const Icon(Icons.access_time),
                  label: Text(
                    _minuteOfDay == null
                        ? '시간 선택 (선택사항)'
                        : formatTimeOfDay(
                            _minuteOfDay! ~/ 60,
                            _minuteOfDay! % 60,
                          ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: kPrimaryGreenDark,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              if (_minuteOfDay != null)
                IconButton(
                  onPressed: () => setState(() => _minuteOfDay = null),
                  icon: const Icon(Icons.close),
                  tooltip: '시간 지우기',
                ),
            ],
          ),
          const SizedBox(height: 16),
          SegmentedButton<AppointmentStatus>(
            segments: [
              for (final s in AppointmentStatus.values)
                ButtonSegment(value: s, label: Text(s.label)),
            ],
            selected: {_status},
            showSelectedIcon: false,
            onSelectionChanged: (v) => setState(() => _status = v.first),
          ),
          const SizedBox(height: 20),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: kPrimaryGreen,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            onPressed: _save,
            child: const Text('저장'),
          ),
          if (_isEditing) ...[
            const SizedBox(height: 8),
            TextButton(
              onPressed: _delete,
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('이 기록 삭제'),
            ),
          ],
        ],
      ),
    );
  }
}
