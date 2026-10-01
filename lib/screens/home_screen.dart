import 'package:flutter/material.dart';

import '../models/customer.dart';
import '../models/customer_overview.dart';
import '../services/customer_database.dart';
import '../theme.dart';
import '../utils/date_format.dart';
import '../widgets/customer_name.dart';
import '../widgets/status_chip.dart';
import 'customer_detail_screen.dart';
import 'customer_form_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _database = CustomerDatabase.instance;
  late Future<List<CustomerOverview>> _overviewsFuture;

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
      _overviewsFuture = _database.getOverviews();
    });
  }

  /// 새 환자를 등록하고 바로 상세 화면으로 이동해 첫 일정을 넣게 합니다.
  Future<void> _addCustomer() async {
    final result = await Navigator.of(context).push<Customer>(
      MaterialPageRoute(builder: (_) => const CustomerFormScreen()),
    );
    if (result == null) return;
    final saved = await _database.insertCustomer(result);
    if (!mounted) return;
    _openDetail(saved);
  }

  void _openDetail(Customer customer) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CustomerDetailScreen(customerId: customer.id!),
      ),
    );
  }

  Future<bool> _confirmDelete(Customer customer) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('환자 삭제'),
        content: Text('"${customer.name}" 환자를 삭제하시겠습니까?\n삭제하면 되돌릴 수 없습니다.'),
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
    return confirmed ?? false;
  }

  Future<void> _delete(Customer customer) async {
    await _database.deleteCustomer(customer.id!);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: kPrimaryGreen,
        foregroundColor: Colors.white,
        title: const Text('내 환자의 모든 것'),
      ),
      body: FutureBuilder<List<CustomerOverview>>(
        future: _overviewsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          final overviews = snapshot.data ?? [];

          if (overviews.isEmpty) {
            return const _EmptyState();
          }

          return ListView.separated(
            padding: const EdgeInsets.only(top: 8, bottom: 96),
            itemCount: overviews.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final overview = overviews[index];
              final customer = overview.customer;
              return Dismissible(
                key: ValueKey(customer.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  color: Theme.of(context).colorScheme.errorContainer,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Icon(
                    Icons.delete,
                    color: Theme.of(context).colorScheme.onErrorContainer,
                  ),
                ),
                confirmDismiss: (_) => _confirmDelete(customer),
                onDismissed: (_) => _delete(customer),
                child: _CustomerTile(
                  overview: overview,
                  onTap: () => _openDetail(customer),
                  onLongPress: () async {
                    final confirmed = await _confirmDelete(customer);
                    if (confirmed) _delete(customer);
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: kPrimaryGreen,
        foregroundColor: Colors.white,
        onPressed: _addCustomer,
        icon: const Icon(Icons.person_add),
        label: const Text('환자 추가'),
      ),
    );
  }
}

class _CustomerTile extends StatelessWidget {
  const _CustomerTile({
    required this.overview,
    required this.onTap,
    required this.onLongPress,
  });

  final CustomerOverview overview;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final customer = overview.customer;
    final isFemale = customer.gender == '여';
    final needsContact = overview.needsContact;
    final needsCheck = overview.uncheckedBookings.isNotEmpty;
    final next = overview.nextBooking;

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: (isFemale ? Colors.pink : kPrimaryGreen).withValues(
          alpha: 0.15,
        ),
        child: Icon(
          isFemale ? Icons.woman : Icons.man,
          color: isFemale ? Colors.pink : kPrimaryGreenDark,
        ),
      ),
      title: Row(
        children: [
          Flexible(
            child: CustomerName(
              customer: customer,
              color: needsContact ? kNoShowRed : null,
            ),
          ),
          if (needsContact) ...[
            const SizedBox(width: 8),
            const StatusChip(label: '연락 필요', color: kNoShowRed),
          ],
          if (needsCheck) ...[
            const SizedBox(width: 6),
            const StatusChip(label: '내원 확인', color: Colors.orange),
          ],
          if (overview.needsHerbCheck) ...[
            const SizedBox(width: 6),
            const StatusChip(label: '복약 확인', color: kHerbPurple),
          ],
        ],
      ),
      subtitle: Text(
        '최종내원 ${formatDate(overview.lastVisit)}'
        '  ·  다음예약 ${next == null ? '없음' : formatShortDate(next.date)}',
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
      onLongPress: onLongPress,
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.groups_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              '아직 등록된 환자가 없어요.',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              '오른쪽 아래 + 버튼을 눌러 첫 환자를 등록해보세요.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
