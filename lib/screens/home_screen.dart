import 'package:flutter/material.dart';

import '../models/customer.dart';
import '../services/customer_database.dart';
import '../theme.dart';
import '../utils/date_format.dart';
import 'customer_form_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _database = CustomerDatabase.instance;
  late Future<List<Customer>> _customersFuture;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    setState(() {
      _customersFuture = _database.getAllCustomers();
    });
  }

  Future<void> _openForm({Customer? customer}) async {
    final result = await Navigator.of(context).push<Customer>(
      MaterialPageRoute(builder: (_) => CustomerFormScreen(customer: customer)),
    );

    if (result == null) return;

    if (customer == null) {
      await _database.insertCustomer(result);
    } else {
      await _database.updateCustomer(result);
    }
    _reload();
  }

  Future<bool> _confirmDelete(Customer customer) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('고객 삭제'),
        content: Text('"${customer.name}" 고객을 삭제할까요?\n삭제하면 되돌릴 수 없습니다.'),
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
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: kPrimaryGreen,
        foregroundColor: Colors.white,
        title: const Text('내 고객의 모든 것'),
      ),
      body: FutureBuilder<List<Customer>>(
        future: _customersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          final customers = snapshot.data ?? [];

          if (customers.isEmpty) {
            return const _EmptyState();
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: customers.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final customer = customers[index];
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
                  customer: customer,
                  onTap: () => _openForm(customer: customer),
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
        onPressed: () => _openForm(),
        icon: const Icon(Icons.person_add),
        label: const Text('고객 추가'),
      ),
    );
  }
}

class _CustomerTile extends StatelessWidget {
  const _CustomerTile({
    required this.customer,
    required this.onTap,
    required this.onLongPress,
  });

  final Customer customer;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final isFemale = customer.gender == '여';
    final noShow = customer.isNoShow;

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: (isFemale ? Colors.pink : kPrimaryGreen)
            .withValues(alpha: 0.15),
        child: Icon(
          isFemale ? Icons.woman : Icons.man,
          color: isFemale ? Colors.pink : kPrimaryGreenDark,
        ),
      ),
      title: Row(
        children: [
          Flexible(
            child: Text(
              customer.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: noShow ? kNoShowRed : null,
              ),
            ),
          ),
          if (noShow) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: kNoShowRed.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                '예약일 미방문',
                style: TextStyle(
                  color: kNoShowRed,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
      subtitle: Text('최종내원일  ${formatDate(customer.lastVisit)}'),
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
              '아직 등록된 고객이 없어요.',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              '오른쪽 아래 + 버튼을 눌러 첫 고객을 등록해보세요.',
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
