import 'package:flutter/material.dart';

import '../models/customer_overview.dart';
import '../services/customer_database.dart';
import '../theme.dart';
import '../utils/date_format.dart';
import '../utils/phone.dart';
import '../widgets/status_chip.dart';
import 'customer_detail_screen.dart';

/// 마지막 일정 후 2주가 지났는데 재예약이 없는 고객 목록.
class ContactScreen extends StatefulWidget {
  const ContactScreen({super.key});

  @override
  State<ContactScreen> createState() => _ContactScreenState();
}

class _ContactScreenState extends State<ContactScreen> {
  final _database = CustomerDatabase.instance;
  late Future<List<CustomerOverview>> _future;

  /// 이 기간 안에 연락 기한이 오는 고객은 '곧 연락' 으로 미리 보여줍니다.
  static const _upcomingDays = 3;

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
      _future = _database.getOverviews();
    });
  }

  void _openDetail(CustomerOverview o) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CustomerDetailScreen(customerId: o.customer.id!),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: kPrimaryGreen,
        foregroundColor: Colors.white,
        title: const Text('연락 필요'),
      ),
      body: FutureBuilder<List<CustomerOverview>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final all = snapshot.data ?? [];

          // 아직 연락 안 한 고객 먼저, 그 안에서는 오래된 순.
          final due = all.where((o) => o.needsContact).toList()
            ..sort((a, b) {
              if (a.contactedSinceDue != b.contactedSinceDue) {
                return a.contactedSinceDue ? 1 : -1;
              }
              return (b.daysSinceLastSchedule ?? 0).compareTo(
                a.daysSinceLastSchedule ?? 0,
              );
            });

          final limit = today().add(const Duration(days: _upcomingDays));
          final upcoming =
              all.where((o) {
                final d = o.contactDueDate;
                return d != null && !o.needsContact && !d.isAfter(limit);
              }).toList()..sort(
                (a, b) => a.contactDueDate!.compareTo(b.contactDueDate!),
              );

          if (due.isEmpty && upcoming.isEmpty) {
            return const Center(
              child: Text(
                '지금 연락이 필요한 고객이 없어요 🎉',
                style: TextStyle(fontSize: 16),
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: [
              if (due.isNotEmpty) _Header('지금 연락하기 (${due.length}명)'),
              for (final o in due)
                _ContactTile(
                  overview: o,
                  onTap: () => _openDetail(o),
                  onCall: () => callPhone(context, o.customer.phone),
                  onContacted: () => _database.logContact(o.customer.id!),
                ),
              if (upcoming.isNotEmpty)
                _Header('$_upcomingDays일 이내 연락 예정 (${upcoming.length}명)'),
              for (final o in upcoming)
                ListTile(
                  onTap: () => _openDetail(o),
                  leading: const Icon(Icons.schedule, color: Colors.grey),
                  title: Text(o.customer.name),
                  subtitle: Text(
                    '${formatDate(o.contactDueDate)} 부터 연락 · ${o.contactReason}',
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Text(
        text,
        style: Theme.of(
          context,
        ).textTheme.titleSmall?.copyWith(color: kPrimaryGreenDark),
      ),
    );
  }
}

class _ContactTile extends StatelessWidget {
  const _ContactTile({
    required this.overview,
    required this.onTap,
    required this.onCall,
    required this.onContacted,
  });

  final CustomerOverview overview;
  final VoidCallback onTap;
  final VoidCallback onCall;
  final VoidCallback onContacted;

  @override
  Widget build(BuildContext context) {
    final contacted = overview.contactedSinceDue;
    return Opacity(
      opacity: contacted ? 0.55 : 1,
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: kNoShowRed.withValues(alpha: 0.12),
          child: Text(
            '${overview.daysSinceLastSchedule}일',
            style: const TextStyle(
              color: kNoShowRed,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Row(
          children: [
            Flexible(
              child: Text(
                overview.customer.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            if (contacted) ...[
              const SizedBox(width: 8),
              StatusChip(
                label: '연락함 ${formatShortDate(overview.lastContact)}',
                color: Colors.grey,
              ),
            ],
          ],
        ),
        subtitle: Text(overview.contactReason),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: onCall,
              icon: const Icon(Icons.call, color: kPrimaryGreenDark),
              tooltip: '전화 걸기',
            ),
            IconButton(
              onPressed: onContacted,
              icon: const Icon(Icons.check_circle_outline),
              tooltip: '연락함으로 표시',
            ),
          ],
        ),
      ),
    );
  }
}
