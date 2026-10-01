import 'package:flutter/material.dart';

import '../models/customer_overview.dart';
import '../models/herb_alert.dart';
import '../services/customer_database.dart';
import '../theme.dart';
import '../utils/date_format.dart';
import '../utils/phone.dart';
import '../widgets/blink.dart';
import '../widgets/customer_name.dart';
import '../widgets/status_chip.dart';
import 'customer_detail_screen.dart';
import 'herb_plan_screen.dart';
import 'missed_screen.dart';

/// 마지막 일정 후 2주가 지났는데 재예약이 없는 환자 목록.
class ContactScreen extends StatefulWidget {
  const ContactScreen({super.key});

  @override
  State<ContactScreen> createState() => _ContactScreenState();
}

class _ContactScreenState extends State<ContactScreen> {
  final _database = CustomerDatabase.instance;
  late Future<List<CustomerOverview>> _future;

  /// 이 기간 안에 연락 기한이 오는 환자는 '곧 연락' 으로 미리 보여줍니다.
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

          // 아직 연락 안 한 환자 먼저, 그 안에서는 오래된 순.
          final due = all.where((o) => o.revisitActive).toList()
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

          // 한약 복약 확인: 재예약과 상관없이 알림일이 되면 무조건 표시
          final herbDue = [
            for (final o in all)
              if (o.needsHerbCheck)
                for (final a in o.activeHerbAlerts) (o, a),
          ]..sort((x, y) => x.$2.date.compareTo(y.$2.date));

          // 7일(kMaxReminderDays) 동안 알렸는데도 연락 못 한 환자 → 놓친 연락 보관함
          final missed = all.where((o) => o.hasMissed).toList();

          if (due.isEmpty &&
              upcoming.isEmpty &&
              herbDue.isEmpty &&
              missed.isEmpty) {
            return const Center(
              child: Text(
                '지금 연락이 필요한 환자가 없어요 🎉',
                style: TextStyle(fontSize: 16),
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: [
              if (missed.isNotEmpty)
                _MissedFolderTile(
                  count: missed.length,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const MissedScreen()),
                  ),
                ),
              if (herbDue.isNotEmpty)
                _Header('🌿 복약 확인 전화 (${herbDue.length}건)', color: kHerbPurple),
              for (final (o, a) in herbDue)
                _HerbTile(
                  overview: o,
                  alert: a,
                  onTap: () => _openDetail(o),
                  onCall: () => callPhone(context, o.customer.phone),
                  onDone: () => _database.completeHerbAlert(a.id!),
                  onPostpone: () async {
                    final days = await showPostponeDialog(context);
                    if (days != null) {
                      await _database.postponeHerbPlan(o.customer.id!, days);
                    }
                  },
                ),
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
                  title: CustomerName(customer: o.customer),
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
  const _Header(this.text, {this.color = kPrimaryGreenDark});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Text(
        text,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

/// 복약 확인 전화 한 건.
class _HerbTile extends StatelessWidget {
  const _HerbTile({
    required this.overview,
    required this.alert,
    required this.onTap,
    required this.onCall,
    required this.onDone,
    required this.onPostpone,
  });

  final CustomerOverview overview;
  final HerbAlert alert;
  final VoidCallback onTap;
  final VoidCallback onCall;
  final VoidCallback onDone;
  final VoidCallback onPostpone;

  @override
  Widget build(BuildContext context) {
    final late = today().difference(alert.date).inDays;
    return ListTile(
      onTap: onTap,
      leading: Blink(
        child: CircleAvatar(
          backgroundColor: kHerbPurple.withValues(alpha: 0.12),
          child: const Text('🌿', style: TextStyle(fontSize: 18)),
        ),
      ),
      title: CustomerName(customer: overview.customer),
      subtitle: Text(
        '${overview.herbLabel(alert)} 확인 · ${formatShortDate(alert.date)}'
        ' · ${late + 1}/$kMaxReminderDays일째 알림',
        style: const TextStyle(color: kHerbPurple, fontWeight: FontWeight.w600),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: onCall,
            icon: const Icon(Icons.call, color: kPrimaryGreenDark),
            tooltip: '전화 걸기',
          ),
          PopupMenuButton<String>(
            tooltip: '처리',
            icon: const Icon(Icons.more_vert),
            onSelected: (v) => v == 'done' ? onDone() : onPostpone(),
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'done', child: Text('확인 완료')),
              PopupMenuItem(value: 'postpone', child: Text('일정 미루기')),
            ],
          ),
        ],
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
        leading: Blink(
          enabled: !contacted,
          child: CircleAvatar(
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
        ),
        title: Row(
          children: [
            Flexible(child: CustomerName(customer: overview.customer)),
            if (contacted) ...[
              const SizedBox(width: 8),
              StatusChip(
                label: '연락함 ${formatShortDate(overview.lastContact)}',
                color: Colors.grey,
              ),
            ],
          ],
        ),
        subtitle: Text(
          overview.contactReason +
              (contacted
                  ? ''
                  : ' · ${(overview.revisitOverdueDays ?? 0) + 1}/$kMaxReminderDays일째 알림'),
        ),
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

/// 연락 탭 맨 위 '놓친 연락' 보관함 입구.
class _MissedFolderTile extends StatelessWidget {
  const _MissedFolderTile({required this.count, required this.onTap});

  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.fromLTRB(12, 4, 12, 8),
      color: kMissedBrown.withValues(alpha: 0.1),
      child: ListTile(
        onTap: onTap,
        leading: const Icon(Icons.folder_special, color: kMissedBrown),
        title: Text(
          '놓친 연락 $count명',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: kMissedBrown,
          ),
        ),
        subtitle: const Text('$kMaxReminderDays일 동안 알렸는데도 연락하지 못한 환자'),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}
