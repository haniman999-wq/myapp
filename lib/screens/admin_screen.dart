import 'package:flutter/material.dart';

import '../models/department.dart';
import '../services/customer_database.dart';
import '../widgets/customer_name.dart';

/// 관리자 설정 (master1 등 관리자만): 진료과 이름 바꾸기, 직원 통계 권한.
class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final _db = CustomerDatabase.instance;
  late Future<(List<Department>, List<StaffMember>, StaffMember?)> _future;

  @override
  void initState() {
    super.initState();
    _db.changes.addListener(_reload);
    _reload();
  }

  @override
  void dispose() {
    _db.changes.removeListener(_reload);
    super.dispose();
  }

  void _reload() {
    setState(() {
      _future = () async {
        return (
          await _db.getDepartments(),
          await _db.getStaff(),
          await _db.me(),
        );
      }();
    });
  }

  Future<void> _rename(Department d) async {
    final controller = TextEditingController(text: d.name);
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('진료과 이름'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: '예: 침구과'),
          onSubmitted: (v) => Navigator.of(context).pop(v),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: const Text('저장'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (name == null || name.trim().isEmpty || name.trim() == d.name) return;
    await _db.renameDepartment(d.id, name);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF37474F),
        foregroundColor: Colors.white,
        title: const Text('관리자 설정'),
      ),
      body: FutureBuilder(
        future: _future,
        builder: (context, snapshot) {
          final data = snapshot.data;
          if (data == null) {
            return const Center(child: CircularProgressIndicator());
          }
          final (depts, staff, me) = data;
          if (me == null || !me.isAdmin) {
            return const Center(child: Text('관리자만 볼 수 있어요'));
          }
          return ListView(
            padding: const EdgeInsets.all(14),
            children: [
              const Text(
                '진료과 이름',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              const Text(
                '눌러서 이름을 바꿀 수 있어요. 바꾸면 모든 기기에 바로 반영돼요.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 6),
              Card(
                child: Column(
                  children: [
                    for (final d in depts)
                      ListTile(
                        leading: DeptBadge(dept: d, fontSize: 14),
                        title: Text(d.name),
                        trailing: const Icon(Icons.edit),
                        onTap: () => _rename(d),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                '경영 통계 보기 권한',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              const Text(
                '켜 둔 계정만 설정 → [경영 통계]를 열 수 있어요. 관리자는 항상 볼 수 있어요.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 6),
              Card(
                child: Column(
                  children: [
                    for (final s in staff)
                      SwitchListTile(
                        secondary: Icon(
                          s.isAdmin ? Icons.admin_panel_settings : Icons.person,
                        ),
                        title: Text(s.email),
                        subtitle: Text(s.isAdmin ? '관리자' : '직원'),
                        value: s.canViewStats || s.isAdmin,
                        onChanged: s.isAdmin
                            ? null
                            : (v) => _db.setStatsPermission(s.id, v),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                '새 직원 계정은 Supabase 관리 화면(Authentication → Users → Add user)에서 만들면 '
                '여기에 자동으로 나타나요. 퇴사한 직원은 그곳에서 계정을 삭제하세요.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          );
        },
      ),
    );
  }
}
