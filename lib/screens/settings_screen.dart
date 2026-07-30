import 'package:flutter/material.dart';

import '../services/idea_database.dart';

const Color _kPrimaryBlue = Color(0xFF0080F7);

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _database = IdeaDatabase.instance;
  late Future<int> _countFuture;

  @override
  void initState() {
    super.initState();
    _reloadCount();
  }

  void _reloadCount() {
    setState(() {
      _countFuture = _database.getAllIdeas().then((ideas) => ideas.length);
    });
  }

  Future<void> _confirmDeleteAll() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('전체 삭제'),
        content: const Text('정말 다 지울까요?\n삭제하면 되돌릴 수 없습니다.'),
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
      await _database.deleteAllIdeas();
      _reloadCount();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('설정')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 16),
              const Text(
                '아이디어 저장소',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: _kPrimaryBlue,
                ),
              ),
              const SizedBox(height: 12),
              FutureBuilder<int>(
                future: _countFuture,
                builder: (context, snapshot) {
                  final count = snapshot.data;
                  return Text(
                    count == null ? '불러오는 중...' : '저장된 아이디어: $count개',
                    style: const TextStyle(fontSize: 16),
                  );
                },
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
