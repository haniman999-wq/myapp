import 'package:flutter/material.dart';

import '../models/appointment.dart';
import '../models/customer.dart';
import '../models/customer_overview.dart';
import '../services/customer_database.dart';
import '../theme.dart';
import '../utils/date_format.dart';
import '../utils/phone.dart';
import '../widgets/appointment_sheet.dart';
import '../widgets/status_chip.dart';
import 'customer_form_screen.dart';

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
            title: Text(customer.name),
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
