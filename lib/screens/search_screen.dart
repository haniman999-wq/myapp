import 'package:flutter/material.dart';

import '../models/customer_overview.dart';
import '../services/customer_database.dart';
import '../theme.dart';
import '../utils/date_format.dart';
import 'customer_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _database = CustomerDatabase.instance;
  final _searchController = TextEditingController();
  late Future<List<CustomerOverview>> _customersFuture;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _customersFuture = _database.getOverviews();
    _database.changes.addListener(_reload);
    _searchController.addListener(() {
      setState(() {
        _query = _searchController.text.trim();
      });
    });
  }

  @override
  void dispose() {
    _database.changes.removeListener(_reload);
    _searchController.dispose();
    super.dispose();
  }

  List<CustomerOverview> _filter(List<CustomerOverview> customers) {
    final query = _query.toLowerCase();
    return customers
        .where(
          (c) =>
              c.customer.name.toLowerCase().contains(query) ||
              c.customer.phone
                  .replaceAll('-', '')
                  .contains(query.replaceAll('-', '')),
        )
        .toList();
  }

  void _reload() {
    setState(() {
      _customersFuture = _database.getOverviews();
    });
  }

  void _openCustomer(int customerId) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CustomerDetailScreen(customerId: customerId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: kPrimaryGreen,
        foregroundColor: Colors.white,
        title: const Text('고객 검색'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: '고객명 또는 전화번호 검색',
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
                focusedBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: kPrimaryGreen, width: 2),
                ),
              ),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<CustomerOverview>>(
              future: _customersFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (_query.isEmpty) {
                  return const Center(child: Text('찾고 싶은 고객을 검색해보세요 🔍'));
                }

                final customers = snapshot.data ?? [];
                final filtered = _filter(customers);

                if (filtered.isEmpty) {
                  return const Center(child: Text('찾는 고객이 없어요'));
                }

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: filtered.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final overview = filtered[index];
                    final customer = overview.customer;
                    return ListTile(
                      leading: const Icon(Icons.person_outline),
                      title: Text(
                        customer.name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        '${customer.phone}  ·  최종내원 ${formatDate(overview.lastVisit)}',
                      ),
                      onTap: () => _openCustomer(customer.id!),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
