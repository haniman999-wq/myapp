import 'package:flutter/material.dart';

import '../models/appointment.dart';
import '../models/customer.dart';
import '../models/customer_overview.dart';
import '../models/herb_alert.dart';
import '../services/customer_database.dart';
import '../theme.dart';
import '../utils/date_format.dart';
import '../utils/phone.dart';
import '../widgets/appointment_sheet.dart';
import '../widgets/customer_name.dart';
import '../widgets/status_chip.dart';
import 'customer_form_screen.dart';
import 'herb_plan_screen.dart';

/// 고객 한 명의 정보와 예약·내원 기록.
class CustomerDetailScreen extends StatefulWidget {
  const CustomerDetailScreen({super.key, required this.customerId});

  final int customerId;

  @override
  State<CustomerDetailScreen> createState() => _CustomerDetailScreenState();
}

class _CustomerDetailScreenState extends State<CustomerDetailScreen> {
  final _database = CustomerDatabase.instance;
  late Future<CustomerOverview?> _future;

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

  void _reload() {
    setState(() {
      _future = _database.getOverview(widget.customerId);
    });
  }

  Future<void> _edit(Customer customer) async {
    final result = await Navigator.of(context).push<Customer>(
      MaterialPageRoute(builder: (_) => CustomerFormScreen(customer: customer)),
    );
    if (result != null) await _database.updateCustomer(result);
  }

  Future<void> _delete(Customer customer) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('고객 삭제'),
        content: Text(
          '"${customer.name}" 고객과 모든 예약 기록을 삭제하시겠습니까?\n삭제하면 되돌릴 수 없습니다.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('삭제', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _database.deleteCustomer(customer.id!);
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _logContact(Customer customer) async {
    await _database.logContact(customer.id!);
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('${customer.name} 고객 연락 기록을 남겼어요')));
  }

  void _openHerbPlan(CustomerOverview overview) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => HerbPlanScreen(
          customer: overview.customer,
          pendingAlerts: overview.pendingHerbAlerts,
        ),
      ),
    );
  }

  Future<void> _postponeHerb(Customer customer) async {
    final days = await showPostponeDialog(context);
    if (days == null) return;
    await _database.postponeHerbPlan(customer.id!, days);
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('복약 일정을 $days일 미뤘어요. 알림도 다시 맞췄어요.')));
  }

  Future<void> _endHerb(Customer customer) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('복약 종료'),
        content: Text('${customer.name} 고객의 한약 복약을 종료할까요?\n남은 복약 알림이 모두 취소돼요.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('복약 종료'),
          ),
        ],
      ),
    );
    if (confirmed == true) await _database.endHerbPlan(customer.id!);
  }

  void _openSheet(Customer customer, {Appointment? existing}) {
    showAppointmentSheet(
      context,
      customerId: customer.id!,
      customerName: customer.name,
      existing: existing,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<CustomerOverview?>(
      future: _future,
      builder: (context, snapshot) {
        final overview = snapshot.data;
        if (overview == null) {
          return Scaffold(
            appBar: AppBar(
              backgroundColor: kPrimaryGreen,
              foregroundColor: Colors.white,
            ),
            body: snapshot.connectionState == ConnectionState.done
                ? const Center(child: Text('고객 정보를 찾을 수 없어요'))
                : const Center(child: CircularProgressIndicator()),
          );
        }

        final customer = overview.customer;
        final history = overview.appointments.reversed.toList();

        return Scaffold(
          appBar: AppBar(
            backgroundColor: kPrimaryGreen,
            foregroundColor: Colors.white,
            title: Row(
              children: [
                Flexible(
                  child: Text(customer.name, overflow: TextOverflow.ellipsis),
                ),
                if (customer.isHerbal) ...[
                  const SizedBox(width: 8),
                  const HerbBadge(),
                ],
              ],
            ),
            actions: [
              IconButton(
                onPressed: () => _edit(customer),
                icon: const Icon(Icons.edit),
                tooltip: '정보 수정',
              ),
              IconButton(
                onPressed: () => _delete(customer),
                icon: const Icon(Icons.delete_outline),
                tooltip: '고객 삭제',
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.only(bottom: 96),
            children: [
              _SummaryCard(
                overview: overview,
                onCall: () => callPhone(context, customer.phone),
              ),
              _MemoCard(memo: customer.memo, onEdit: () => _edit(customer)),
              _HerbCard(
                overview: overview,
                onStartOrEdit: () => _openHerbPlan(overview),
                onPostpone: () => _postponeHerb(customer),
                onEnd: () => _endHerb(customer),
                onComplete: (alert) => _database.completeHerbAlert(alert.id!),
              ),
              if (overview.needsContact)
                _ContactBanner(
                  overview: overview,
                  onCall: () => callPhone(context, customer.phone),
                  onContacted: () => _logContact(customer),
                  onRebook: () => _openSheet(customer),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
                child: Text(
                  '예약 · 내원 기록',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(color: kPrimaryGreenDark),
                ),
              ),
              if (history.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(
                    child: Text(
                      '아직 기록이 없어요.\n아래 버튼으로 내원/예약을 추가해보세요.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                ),
              for (final a in history)
                _AppointmentTile(
                  appointment: a,
                  onTap: () => _openSheet(customer, existing: a),
                  onMark: (status) =>
                      _database.saveAppointment(a.copyWith(status: status)),
                ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            backgroundColor: kPrimaryGreen,
            foregroundColor: Colors.white,
            onPressed: () => _openSheet(customer),
            icon: const Icon(Icons.event_available),
            label: const Text('일정 추가'),
          ),
        );
      },
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.overview, required this.onCall});

  final CustomerOverview overview;
  final VoidCallback onCall;

  @override
  Widget build(BuildContext context) {
    final c = overview.customer;
    final next = overview.nextBooking;
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${c.phone}  ·  ${c.gender}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                IconButton.filledTonal(
                  onPressed: onCall,
                  icon: const Icon(Icons.call),
                  tooltip: '전화 걸기',
                ),
              ],
            ),
            const SizedBox(height: 8),
            _InfoRow(label: '마지막 내원', value: formatDate(overview.lastVisit)),
            _InfoRow(
              label: '다음 예약',
              value: next == null ? '없음' : formatDateWithWeekday(next.date),
            ),
            _InfoRow(label: '마지막 연락', value: formatDate(overview.lastContact)),
          ],
        ),
      ),
    );
  }
}

/// 한약 복약 카드. 복약 중이 아니면 [복약 시작] 버튼만 보여줍니다.
class _HerbCard extends StatelessWidget {
  const _HerbCard({
    required this.overview,
    required this.onStartOrEdit,
    required this.onPostpone,
    required this.onEnd,
    required this.onComplete,
  });

  final CustomerOverview overview;
  final VoidCallback onStartOrEdit;
  final VoidCallback onPostpone;
  final VoidCallback onEnd;
  final ValueChanged<HerbAlert> onComplete;

  @override
  Widget build(BuildContext context) {
    final start = overview.customer.herbStart;

    if (start == null) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        child: OutlinedButton.icon(
          onPressed: onStartOrEdit,
          icon: const Text('🌿', style: TextStyle(fontSize: 18)),
          label: const Text('한약 복약 시작'),
          style: OutlinedButton.styleFrom(
            foregroundColor: kHerbPurple,
            side: const BorderSide(color: kHerbPurple),
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      );
    }

    final pending = overview.pendingHerbAlerts;
    final elapsed = today().difference(start).inDays;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kHerbPurple.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kHerbPurple.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const HerbBadge(label: '한약 복약 중'),
              const Spacer(),
              TextButton(
                onPressed: onStartOrEdit,
                style: TextButton.styleFrom(foregroundColor: kHerbPurple),
                child: const Text('일정 수정'),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '복약 시작 ${formatDateWithWeekday(start)}'
            '${elapsed >= 0 ? '  ·  오늘 복약 $elapsed일째' : ''}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          if (pending.isEmpty)
            const Text('남은 복약 알림이 없어요.', style: TextStyle(color: Colors.grey)),
          for (final a in pending)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: [
                  Icon(
                    a.isDue
                        ? Icons.notifications_active
                        : Icons.notifications_none,
                    size: 18,
                    color: a.isDue ? kNoShowRed : kHerbPurple,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    overview.herbLabel(a),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: a.isDue ? kNoShowRed : kHerbPurple,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(formatDateWithWeekday(a.date)),
                  const Spacer(),
                  if (a.isDue)
                    TextButton(
                      onPressed: () => onComplete(a),
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                      ),
                      child: const Text('확인 완료'),
                    ),
                ],
              ),
            ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(backgroundColor: kHerbPurple),
                  onPressed: onPostpone,
                  icon: const Icon(Icons.update, size: 18),
                  label: const Text('일정 미루기'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: onEnd,
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.grey),
                  child: const Text('복약 종료'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 특이사항 메모. 비어 있으면 '메모 추가' 안내만 보여줍니다.
class _MemoCard extends StatelessWidget {
  const _MemoCard({required this.memo, required this.onEdit});

  final String memo;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final empty = memo.trim().isEmpty;
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      color: const Color(0xFFFFF8E1),
      child: InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.sticky_note_2_outlined, color: Colors.amber),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '특이사항',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      empty ? '눌러서 메모를 추가하세요' : memo,
                      style: TextStyle(color: empty ? Colors.grey : null),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(label, style: const TextStyle(color: Colors.grey)),
          ),
          Text(value),
        ],
      ),
    );
  }
}

class _ContactBanner extends StatelessWidget {
  const _ContactBanner({
    required this.overview,
    required this.onCall,
    required this.onContacted,
    required this.onRebook,
  });

  final CustomerOverview overview;
  final VoidCallback onCall;
  final VoidCallback onContacted;
  final VoidCallback onRebook;

  @override
  Widget build(BuildContext context) {
    final contacted = overview.contactedSinceDue;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kNoShowRed.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kNoShowRed.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.notifications_active, color: kNoShowRed),
              const SizedBox(width: 8),
              const Text(
                '재방문 연락 필요',
                style: TextStyle(
                  color: kNoShowRed,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              if (contacted)
                StatusChip(
                  label: '연락함 ${formatShortDate(overview.lastContact)}',
                  color: Colors.grey,
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(overview.contactReason),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: onCall,
                icon: const Icon(Icons.call, size: 18),
                label: const Text('전화'),
              ),
              OutlinedButton.icon(
                onPressed: onContacted,
                icon: const Icon(Icons.check, size: 18),
                label: const Text('연락함'),
              ),
              FilledButton.icon(
                style: FilledButton.styleFrom(backgroundColor: kPrimaryGreen),
                onPressed: onRebook,
                icon: const Icon(Icons.event, size: 18),
                label: const Text('재예약'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AppointmentTile extends StatelessWidget {
  const _AppointmentTile({
    required this.appointment,
    required this.onTap,
    required this.onMark,
  });

  final Appointment appointment;
  final VoidCallback onTap;
  final ValueChanged<AppointmentStatus> onMark;

  @override
  Widget build(BuildContext context) {
    final a = appointment;
    return ListTile(
      onTap: onTap,
      leading: Icon(Icons.circle, size: 12, color: a.status.color),
      title: Text(formatDateWithWeekday(a.date)),
      subtitle: a.needsCheck
          ? const Text(
              '예약일이 지났어요. 내원했나요?',
              style: TextStyle(color: Colors.orange),
            )
          : null,
      trailing: a.needsCheck
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextButton(
                  onPressed: () => onMark(AppointmentStatus.visited),
                  child: const Text('내원'),
                ),
                TextButton(
                  onPressed: () => onMark(AppointmentStatus.noShow),
                  style: TextButton.styleFrom(foregroundColor: kNoShowRed),
                  child: const Text('노쇼'),
                ),
              ],
            )
          : StatusChip(label: a.status.label, color: a.status.color),
    );
  }
}
