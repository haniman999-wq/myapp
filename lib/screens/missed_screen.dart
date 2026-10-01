import 'package:flutter/material.dart';

import '../models/customer_overview.dart';
import '../services/customer_database.dart';
import '../theme.dart';
import '../utils/date_format.dart';
import '../utils/phone.dart';
import '../widgets/customer_name.dart';
import 'customer_detail_screen.dart';
import 'herb_plan_screen.dart';

/// '놓친 연락' 보관함.
///
/// 연락할 날부터 [kMaxReminderDays]일 동안 매일 알렸는데도 '연락함' / '확인 완료'를
/// 누르지 않은 환자들입니다. 여기서 연락하고 처리하면 목록에서 빠집니다.
class MissedScreen extends StatefulWidget {
  const MissedScreen({super.key});

  @override
  State<MissedScreen> createState() => _MissedScreenState();
}

class _MissedScreenState extends State<MissedScreen> {
  final _database = CustomerDatabase.instance;
  late Future<List<CustomerOverview>> _future;

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

  Future<void> _postpone(CustomerOverview o) async {
    final days = await showPostponeDialog(context);
    if (days != null) await _database.postponeHerbPlan(o.customer.id!, days);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: kMissedBrown,
        foregroundColor: Colors.white,
        title: const Text('놓친 연락'),
      ),
      body: FutureBuilder<List<CustomerOverview>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final all = snapshot.data ?? [];
          final herb = [
            for (final o in all)
              for (final a in o.missedHerbAlerts) (o, a),
          ]..sort((x, y) => x.$2.date.compareTo(y.$2.date));
          final revisit = all.where((o) => o.revisitMissed).toList()
            ..sort(
              (a, b) => (b.revisitOverdueDays ?? 0).compareTo(
                a.revisitOverdueDays ?? 0,
              ),
            );

          return ListView(
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              Container(
                margin: const EdgeInsets.all(12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: kMissedBrown.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  '연락할 날부터 $kMaxReminderDays일 동안 매일 아침 알렸는데도 '
                  '\'연락함\'이나 \'확인 완료\'를 누르지 않은 환자들이에요.\n'
                  '더 이상 아침 알림에는 나오지 않으니, 여기서 확인하고 처리해 주세요. '
                  '처리하면 이 목록에서 빠져요.',
                  style: TextStyle(fontSize: 13),
                ),
              ),
              if (herb.isEmpty && revisit.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 80),
                  child: Center(
                    child: Text(
                      '놓친 연락이 없어요 👍',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              if (herb.isNotEmpty) _Header('🌿 복약 확인 못 한 환자 (${herb.length}건)'),
              for (final (o, a) in herb)
                _MissedTile(
                  overview: o,
                  detail:
                      '${o.herbLabel(a)} 확인 · ${formatShortDate(a.date)}부터 '
                      '${_daysSince(a.date)}일째',
                  onTap: () => _openDetail(o),
                  onCall: () => callPhone(context, o.customer.phone),
                  actions: [
                    PopupMenuItem(
                      onTap: () => _database.completeHerbAlert(a.id!),
                      child: const Text('확인 완료'),
                    ),
                    PopupMenuItem(
                      onTap: () => _postpone(o),
                      child: const Text('일정 미루기'),
                    ),
                  ],
                ),
              if (revisit.isNotEmpty)
                _Header('재방문 연락 못 한 환자 (${revisit.length}명)'),
              for (final o in revisit)
                _MissedTile(
                  overview: o,
                  detail:
                      '${o.contactReason} · 연락 기한 '
                      '${formatShortDate(o.contactDueDate)}부터 '
                      '${o.revisitOverdueDays}일째',
                  onTap: () => _openDetail(o),
                  onCall: () => callPhone(context, o.customer.phone),
                  actions: [
                    PopupMenuItem(
                      onTap: () => _database.logContact(o.customer.id!),
                      child: const Text('연락함'),
                    ),
                    PopupMenuItem(
                      onTap: () => _openDetail(o),
                      child: const Text('재예약하러 가기'),
                    ),
                  ],
                ),
            ],
          );
        },
      ),
    );
  }

  static int _daysSince(DateTime d) => today().difference(dateOnly(d)).inDays;
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
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          color: kMissedBrown,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _MissedTile extends StatelessWidget {
  const _MissedTile({
    required this.overview,
    required this.detail,
    required this.onTap,
    required this.onCall,
    required this.actions,
  });

  final CustomerOverview overview;
  final String detail;
  final VoidCallback onTap;
  final VoidCallback onCall;
  final List<PopupMenuEntry<void>> actions;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: kMissedBrown.withValues(alpha: 0.15),
        child: const Icon(Icons.phone_missed, color: kMissedBrown),
      ),
      title: CustomerName(customer: overview.customer),
      subtitle: Text(detail),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: onCall,
            icon: const Icon(Icons.call, color: kPrimaryGreenDark),
            tooltip: '전화 걸기',
          ),
          PopupMenuButton<void>(
            tooltip: '처리',
            icon: const Icon(Icons.more_vert),
            itemBuilder: (_) => actions,
          ),
        ],
      ),
    );
  }
}
