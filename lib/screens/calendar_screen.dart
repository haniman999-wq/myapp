import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

import '../models/appointment.dart';
import '../models/customer.dart';
import '../models/customer_overview.dart';
import '../services/customer_database.dart';
import '../theme.dart';
import '../utils/date_format.dart';
import '../widgets/appointment_sheet.dart';
import '../widgets/status_chip.dart';
import 'customer_detail_screen.dart';

/// 달력에 표시할 일정 한 칸.
class _Entry {
  const _Entry(this.customer, this.appointment);

  final Customer customer;
  final Appointment appointment;
}

/// 날짜별 예약·내원 현황 달력.
class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final _database = CustomerDatabase.instance;

  List<CustomerOverview> _overviews = [];
  Map<DateTime, List<_Entry>> _byDay = {};
  DateTime _focusedDay = today();
  DateTime _selectedDay = today();
  CalendarFormat _format = CalendarFormat.month;

  @override
  void initState() {
    super.initState();
    _database.changes.addListener(_reload);
    _reload();
  }

  @override
  void dispose() {
    _database.changes.removeListener(_reload);
    super.dispose();
  }

  Future<void> _reload() async {
    final overviews = await _database.getOverviews();
    final byDay = <DateTime, List<_Entry>>{};
    for (final o in overviews) {
      for (final a in o.appointments) {
        byDay
            .putIfAbsent(dateOnly(a.date), () => [])
            .add(_Entry(o.customer, a));
      }
    }
    if (!mounted) return;
    setState(() {
      _overviews = overviews;
      _byDay = byDay;
    });
  }

  List<_Entry> _entriesFor(DateTime day) => _byDay[dateOnly(day)] ?? const [];

  Future<void> _addForSelectedDay() async {
    final customer = await showDialog<Customer>(
      context: context,
      builder: (_) => _CustomerPickerDialog(
        customers: [for (final o in _overviews) o.customer],
      ),
    );
    if (customer == null || !mounted) return;
    await showAppointmentSheet(
      context,
      customerId: customer.id!,
      customerName: customer.name,
      initialDate: _selectedDay,
    );
  }

  @override
  Widget build(BuildContext context) {
    final entries = _entriesFor(_selectedDay);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: kPrimaryGreen,
        foregroundColor: Colors.white,
        title: const Text('예약 달력'),
        actions: [
          IconButton(
            onPressed: () => setState(() {
              _focusedDay = today();
              _selectedDay = today();
            }),
            icon: const Icon(Icons.today),
            tooltip: '오늘',
          ),
        ],
      ),
      body: Column(
        children: [
          TableCalendar<_Entry>(
            locale: 'ko_KR',
            firstDay: DateTime(2020),
            lastDay: DateTime(today().year + 5, 12, 31),
            focusedDay: _focusedDay,
            calendarFormat: _format,
            availableCalendarFormats: const {
              CalendarFormat.month: '월',
              CalendarFormat.twoWeeks: '2주',
              CalendarFormat.week: '주',
            },
            startingDayOfWeek: StartingDayOfWeek.sunday,
            selectedDayPredicate: (day) => isSameDay(day, _selectedDay),
            eventLoader: (day) => _entriesFor(day)
                .where(
                  (e) => e.appointment.status != AppointmentStatus.cancelled,
                )
                .toList(),
            onDaySelected: (selected, focused) => setState(() {
              _selectedDay = dateOnly(selected);
              _focusedDay = focused;
            }),
            onFormatChanged: (f) => setState(() => _format = f),
            onPageChanged: (focused) => _focusedDay = focused,
            headerStyle: const HeaderStyle(titleCentered: true),
            calendarStyle: CalendarStyle(
              todayDecoration: BoxDecoration(
                color: kPrimaryGreen.withValues(alpha: 0.35),
                shape: BoxShape.circle,
              ),
              selectedDecoration: const BoxDecoration(
                color: kPrimaryGreenDark,
                shape: BoxShape.circle,
              ),
            ),
            calendarBuilders: CalendarBuilders(
              markerBuilder: (context, day, events) {
                if (events.isEmpty) return null;
                return Positioned(
                  bottom: 4,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (final e in events.take(4))
                        Container(
                          width: 6,
                          height: 6,
                          margin: const EdgeInsets.symmetric(horizontal: 1),
                          decoration: BoxDecoration(
                            color: e.appointment.needsCheck
                                ? Colors.orange
                                : e.appointment.status.color,
                            shape: BoxShape.circle,
                          ),
                        ),
                      if (events.length > 4)
                        Text(
                          '+${events.length - 4}',
                          style: const TextStyle(fontSize: 9),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              children: [
                Text(
                  formatDateWithWeekday(_selectedDay),
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(color: kPrimaryGreenDark),
                ),
                const Spacer(),
                Text(
                  '${entries.length}건',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
          Expanded(
            child: entries.isEmpty
                ? const Center(
                    child: Text(
                      '이 날은 일정이 없어요',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.only(bottom: 96),
                    children: [
                      for (final e in entries)
                        ListTile(
                          leading: Icon(
                            Icons.circle,
                            size: 12,
                            color: e.appointment.status.color,
                          ),
                          title: Text(e.customer.name),
                          subtitle: Text(e.customer.phone),
                          trailing: e.appointment.needsCheck
                              ? const StatusChip(
                                  label: '내원 확인',
                                  color: Colors.orange,
                                )
                              : StatusChip(
                                  label: e.appointment.status.label,
                                  color: e.appointment.status.color,
                                ),
                          onTap: () => showAppointmentSheet(
                            context,
                            customerId: e.customer.id!,
                            customerName: e.customer.name,
                            existing: e.appointment,
                          ),
                          onLongPress: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => CustomerDetailScreen(
                                customerId: e.customer.id!,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: kPrimaryGreen,
        foregroundColor: Colors.white,
        onPressed: _overviews.isEmpty ? null : _addForSelectedDay,
        icon: const Icon(Icons.add),
        label: const Text('이 날 예약'),
      ),
    );
  }
}

/// 예약을 넣을 고객 고르기.
class _CustomerPickerDialog extends StatefulWidget {
  const _CustomerPickerDialog({required this.customers});

  final List<Customer> customers;

  @override
  State<_CustomerPickerDialog> createState() => _CustomerPickerDialogState();
}

class _CustomerPickerDialogState extends State<_CustomerPickerDialog> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final q = _query.toLowerCase();
    final filtered = widget.customers
        .where(
          (c) =>
              c.name.toLowerCase().contains(q) ||
              c.phone.replaceAll('-', '').contains(q.replaceAll('-', '')),
        )
        .toList();

    return AlertDialog(
      title: const Text('고객 선택'),
      contentPadding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      content: SizedBox(
        width: double.maxFinite,
        height: 360,
        child: Column(
          children: [
            TextField(
              autofocus: true,
              decoration: const InputDecoration(
                hintText: '이름 또는 전화번호',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (v) => setState(() => _query = v.trim()),
            ),
            Expanded(
              child: ListView(
                children: [
                  for (final c in filtered)
                    ListTile(
                      title: Text(c.name),
                      subtitle: Text(c.phone),
                      onTap: () => Navigator.of(context).pop(c),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('취소'),
        ),
      ],
    );
  }
}
