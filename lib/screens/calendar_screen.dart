import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

import '../models/appointment.dart';
import '../models/customer.dart';
import '../models/customer_overview.dart';
import '../models/herb_alert.dart';
import '../services/customer_database.dart';
import '../theme.dart';
import '../utils/date_format.dart';
import '../widgets/customer_name.dart';
import '../widgets/appointment_sheet.dart';
import '../widgets/status_chip.dart';
import 'customer_detail_screen.dart';

/// 달력에 표시할 일정 한 칸.
class _Entry {
  const _Entry(this.customer, this.appointment);

  final Customer customer;
  final Appointment appointment;

  bool get isCancelled => appointment.status == AppointmentStatus.cancelled;
}

/// 첫 화면: 날짜별 예약 인원 달력 + 선택한 날의 예약자 명단.
class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final _database = CustomerDatabase.instance;

  List<CustomerOverview> _overviews = [];
  Map<DateTime, List<_Entry>> _byDay = {};
  Map<DateTime, List<(CustomerOverview, HerbAlert)>> _herbByDay = {};
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
    // 취소는 맨 아래, 나머지는 이름순
    for (final list in byDay.values) {
      list.sort((a, b) {
        if (a.isCancelled != b.isCancelled) return a.isCancelled ? 1 : -1;
        return a.customer.name.compareTo(b.customer.name);
      });
    }
    // 복약 확인 알림 (복약 중인 환자의 미완료 알림)
    final herbByDay = <DateTime, List<(CustomerOverview, HerbAlert)>>{};
    for (final o in overviews) {
      if (!o.customer.isHerbal) continue;
      for (final a in o.pendingHerbAlerts) {
        herbByDay.putIfAbsent(dateOnly(a.date), () => []).add((o, a));
      }
    }
    if (!mounted) return;
    setState(() {
      _overviews = overviews;
      _byDay = byDay;
      _herbByDay = herbByDay;
    });
  }

  List<_Entry> _entriesFor(DateTime day) => _byDay[dateOnly(day)] ?? const [];

  List<(CustomerOverview, HerbAlert)> _herbFor(DateTime day) =>
      _herbByDay[dateOnly(day)] ?? const [];

  /// 취소를 뺀 예약 인원.
  int _countFor(DateTime day) =>
      _entriesFor(day).where((e) => !e.isCancelled).length;

  void _goToday() {
    setState(() {
      _focusedDay = today();
      _selectedDay = today();
    });
  }

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

  void _openDetail(Customer customer) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CustomerDetailScreen(customerId: customer.id!),
      ),
    );
  }

  Widget _buildDay(DateTime day, DateTime focusedDay) {
    final entries = _entriesFor(day);
    return _DayCell(
      day: day,
      count: _countFor(day),
      herbCount: _herbFor(day).length,
      hasUnchecked: entries.any((e) => e.appointment.needsCheck),
      isToday: isSameDay(day, today()),
      isSelected: isSameDay(day, _selectedDay),
      isOutside:
          _format == CalendarFormat.month && day.month != focusedDay.month,
    );
  }

  @override
  Widget build(BuildContext context) {
    final entries = _entriesFor(_selectedDay);
    final count = _countFor(_selectedDay);
    final herbs = _herbFor(_selectedDay);
    final isTodaySelected = isSameDay(_selectedDay, today());

    return Scaffold(
      appBar: AppBar(
        backgroundColor: kPrimaryGreen,
        foregroundColor: Colors.white,
        title: const Text('예약 달력'),
        actions: [
          TextButton.icon(
            onPressed: _goToday,
            style: TextButton.styleFrom(foregroundColor: Colors.white),
            icon: const Icon(Icons.today),
            label: const Text('오늘'),
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
              CalendarFormat.month: '한 달',
              CalendarFormat.twoWeeks: '2주',
              CalendarFormat.week: '1주',
            },
            rowHeight: 70,
            daysOfWeekHeight: 22,
            startingDayOfWeek: StartingDayOfWeek.sunday,
            selectedDayPredicate: (day) => isSameDay(day, _selectedDay),
            onDaySelected: (selected, focused) => setState(() {
              _selectedDay = dateOnly(selected);
              _focusedDay = focused;
            }),
            onFormatChanged: (f) => setState(() => _format = f),
            onPageChanged: (focused) => _focusedDay = focused,
            headerStyle: const HeaderStyle(
              titleCentered: true,
              titleTextStyle: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            calendarBuilders: CalendarBuilders(
              prioritizedBuilder: (context, day, focusedDay) =>
                  _buildDay(day, focusedDay),
              dowBuilder: (context, day) => Center(
                child: Text(
                  const ['월', '화', '수', '목', '금', '토', '일'][day.weekday - 1],
                  style: TextStyle(
                    fontSize: 13,
                    color: _weekdayColor(day) ?? Colors.grey.shade700,
                  ),
                ),
              ),
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              children: [
                if (isTodaySelected) ...[
                  const StatusChip(label: '오늘', color: kPrimaryGreenDark),
                  const SizedBox(width: 8),
                ],
                Text(
                  formatDateWithWeekday(_selectedDay),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: kPrimaryGreenDark,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  '예약 $count명',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          Expanded(
            child: entries.isEmpty && herbs.isEmpty
                ? const Center(
                    child: Text(
                      '이 날은 예약이 없어요',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.only(bottom: 96),
                    children: [
                      for (final (i, e) in entries.indexed) ...[
                        if (i > 0) const Divider(height: 1, indent: 72),
                        _EntryTile(
                          entry: e,
                          number: i + 1,
                          onTap: () => _openDetail(e.customer),
                          onStatusTap: () => showAppointmentSheet(
                            context,
                            customerId: e.customer.id!,
                            customerName: e.customer.name,
                            existing: e.appointment,
                          ),
                        ),
                      ],
                      if (herbs.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                          child: Text(
                            '🌿 복약 확인 전화 ${herbs.length}명',
                            style: const TextStyle(
                              color: kHerbPurple,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      for (final (o, a) in herbs)
                        ListTile(
                          onTap: () => _openDetail(o.customer),
                          leading: CircleAvatar(
                            backgroundColor: kHerbPurple.withValues(
                              alpha: 0.12,
                            ),
                            child: const Text('🌿'),
                          ),
                          title: CustomerName(customer: o.customer),
                          subtitle: Text(o.customer.phone),
                          trailing: StatusChip(
                            label: o.herbLabel(a),
                            color: kHerbPurple,
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

/// 일요일 빨강, 토요일 파랑.
Color? _weekdayColor(DateTime day) {
  if (day.weekday == DateTime.sunday) return Colors.red.shade400;
  if (day.weekday == DateTime.saturday) return Colors.blue.shade400;
  return null;
}

/// 달력 한 칸: 날짜 숫자 + 예약 인원 배지.
class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.count,
    required this.herbCount,
    required this.hasUnchecked,
    required this.isToday,
    required this.isSelected,
    required this.isOutside,
  });

  final DateTime day;
  final int count;
  final int herbCount;
  final bool hasUnchecked;
  final bool isToday;
  final bool isSelected;
  final bool isOutside;

  @override
  Widget build(BuildContext context) {
    final isPast = day.isBefore(today());

    Color background = Colors.transparent;
    Color numberColor = _weekdayColor(day) ?? Colors.black87;
    if (isToday) {
      background = kPrimaryGreen;
      numberColor = Colors.white;
    } else if (isSelected) {
      background = kPrimaryGreen.withValues(alpha: 0.12);
    }

    // 배지 색: 내원 확인 필요 → 주황, 지난 날 → 회색, 오늘·앞으로 → 초록
    Color badgeColor;
    Color badgeText = Colors.white;
    if (isToday) {
      badgeColor = Colors.white;
      badgeText = kPrimaryGreenDark;
    } else if (hasUnchecked) {
      badgeColor = Colors.orange;
    } else if (isPast) {
      badgeColor = Colors.grey.shade400;
    } else {
      badgeColor = kPrimaryGreenDark;
    }

    return Opacity(
      opacity: isOutside ? 0.35 : 1,
      child: Container(
        width: double.infinity,
        height: double.infinity,
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(10),
          border: isSelected
              ? Border.all(
                  color: isToday ? kPrimaryGreenDark : kPrimaryGreen,
                  width: isToday ? 3 : 2,
                )
              : null,
          boxShadow: isToday
              ? [
                  BoxShadow(
                    color: kPrimaryGreen.withValues(alpha: 0.4),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${day.day}',
              style: TextStyle(
                color: numberColor,
                fontSize: isToday ? 19 : 15,
                fontWeight: isToday || isSelected
                    ? FontWeight.bold
                    : FontWeight.normal,
              ),
            ),
            const SizedBox(height: 3),
            if (count == 0)
              const SizedBox(height: 16)
            else
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                decoration: BoxDecoration(
                  color: badgeColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$count명',
                  style: TextStyle(
                    color: badgeText,
                    fontSize: 11,
                    height: 1.4,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            // 모든 칸이 같은 높이를 갖도록 🌿 줄 자리는 항상 비워둡니다.
            if (herbCount == 0)
              const SizedBox(height: 13)
            else
              Text(
                '🌿$herbCount',
                style: TextStyle(
                  fontSize: 10,
                  height: 1.3,
                  fontWeight: FontWeight.bold,
                  color: isToday ? Colors.white : kHerbPurple,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// 선택한 날의 예약자 한 줄. 누르면 고객 상세, 오른쪽 상태 배지를 누르면 상태 변경.
class _EntryTile extends StatelessWidget {
  const _EntryTile({
    required this.entry,
    required this.number,
    required this.onTap,
    required this.onStatusTap,
  });

  final _Entry entry;
  final int number;
  final VoidCallback onTap;
  final VoidCallback onStatusTap;

  @override
  Widget build(BuildContext context) {
    final a = entry.appointment;
    final c = entry.customer;
    final memo = c.memo.trim().split('\n').first;
    final statusLabel = a.needsCheck ? '내원 확인' : a.status.label;
    final statusColor = a.needsCheck ? Colors.orange : a.status.color;

    return Opacity(
      opacity: entry.isCancelled ? 0.45 : 1,
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: statusColor.withValues(alpha: 0.15),
          child: Text(
            '$number',
            style: TextStyle(color: statusColor, fontWeight: FontWeight.bold),
          ),
        ),
        title: CustomerName(customer: c, strike: entry.isCancelled),
        subtitle: Text(
          memo.isEmpty ? c.phone : '${c.phone}  ·  $memo',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: InkWell(
          onTap: onStatusTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: StatusChip(label: statusLabel, color: statusColor),
          ),
        ),
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
