import 'package:flutter/material.dart';

import '../models/customer_overview.dart';
import '../services/customer_database.dart';
import '../theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _database = CustomerDatabase.instance;
  late Future<int> _countFuture;

  @override
  void initState() {
    super.initState();
    _reloadCount();
  }

  void _reloadCount() {
    setState(() {
      _countFuture = _database.getAllCustomers().then(
        (customers) => customers.length,
      );
    });
  }

  Future<void> _confirmDeleteAll() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('전체 삭제'),
        content: const Text('모든 고객 정보를 지울까요?\n삭제하면 되돌릴 수 없습니다.'),
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

    if (confirmed == true) {
      await _database.deleteAllCustomers();
      _reloadCount();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: kPrimaryGreen,
        foregroundColor: Colors.white,
        title: const Text('설정'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 16),
              const Text(
                '내 고객의 모든 것',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: kPrimaryGreenDark,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '초진일부터 재진일까지, 고객 치료 스케쥴 관리',
                style: TextStyle(fontSize: 13, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              FutureBuilder<int>(
                future: _countFuture,
                builder: (context, snapshot) {
                  final count = snapshot.data;
                  return Text(
                    count == null ? '불러오는 중...' : '등록된 고객: $count명',
                    style: const TextStyle(fontSize: 16),
                  );
                },
              ),
              const SizedBox(height: 24),
              const ListTile(
                leading: Icon(
                  Icons.notifications_active_outlined,
                  color: kPrimaryGreenDark,
                ),
                title: Text('재방문 알림'),
                subtitle: Text(
                  '마지막 방문 후 $kRevisitDays일 동안 재예약이 없으면 '
                  '그날 오전 9시에 알림을 보내고 \'연락\' 탭에 표시합니다.',
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: _confirmDeleteAll,
                  child: const Text('전체 삭제'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
