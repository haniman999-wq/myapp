import 'package:flutter/material.dart';

import '../models/customer_overview.dart';
import '../services/backup_service.dart';
import '../services/customer_database.dart';
import '../theme.dart';
import '../utils/date_format.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _database = CustomerDatabase.instance;
  late Future<int> _countFuture;
  late Future<DateTime?> _lastBackupFuture;
  bool _busy = false;

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
      _countFuture = _database.getAllCustomers().then(
        (customers) => customers.length,
      );
      _lastBackupFuture = _database.getLastBackupAt();
    });
  }

  void _toast(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  /// 버튼을 여러 번 누르지 않도록 작업 중엔 막아둡니다.
  Future<void> _run(Future<void> Function() task) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await task();
    } catch (e) {
      if (mounted) _toast(e is FormatException ? e.message : '오류가 났어요: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _share() => _run(() async {
    final ok = await BackupService.share();
    if (ok && mounted) _toast('백업 파일을 보냈어요');
  });

  Future<void> _save() => _run(() async {
    final ok = await BackupService.saveToDevice();
    if (ok && mounted) _toast('백업 파일을 저장했어요');
  });

  Future<void> _restore() => _run(() async {
    final backup = await BackupService.pick();
    if (backup == null || !mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('백업에서 복원'),
        content: Text(
          '${backup.fileName}\n'
          '${backup.exportedAt == null ? '' : '백업 날짜: ${formatDate(backup.exportedAt)}\n'}'
          '\n환자 ${backup.patientCount}명 · 예약/내원 ${backup.appointmentCount}건'
          ' · 복약 알림 ${backup.herbAlertCount}건\n\n'
          '⚠️ 지금 앱에 있는 데이터는 모두 지워지고 이 백업 내용으로 바뀌어요.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: kPrimaryGreenDark),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('복원하기'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await BackupService.restore(backup);
    if (mounted) _toast('환자 ${backup.patientCount}명을 복원했어요');
  });

  Future<void> _confirmDeleteAll() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('전체 삭제'),
        content: const Text(
          '모든 환자 정보를 지울까요?\n삭제하면 되돌릴 수 없습니다.\n\n'
          '지우기 전에 먼저 백업해 두는 걸 권해요.',
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

    if (confirmed == true) await _database.deleteAllCustomers();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: kPrimaryGreen,
        foregroundColor: Colors.white,
        title: const Text('설정'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const SizedBox(height: 8),
          const Text(
            '내 환자의 모든 것',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: kPrimaryGreenDark,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '초진일부터 재진일까지, 환자 치료 스케쥴 관리',
            style: TextStyle(fontSize: 13, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          FutureBuilder<int>(
            future: _countFuture,
            builder: (context, snapshot) {
              final count = snapshot.data;
              return Text(
                count == null ? '불러오는 중...' : '등록된 환자: $count명',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              );
            },
          ),
          const SizedBox(height: 20),
          _BackupCard(
            lastBackupFuture: _lastBackupFuture,
            busy: _busy,
            onShare: _share,
            onSave: _save,
            onRestore: _restore,
          ),
          const SizedBox(height: 12),
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
          const SizedBox(height: 24),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            onPressed: _confirmDeleteAll,
            child: const Text('전체 삭제'),
          ),
        ],
      ),
    );
  }
}

/// 데이터 백업 카드: 마지막 백업 시각 + 공유 / 저장 / 복원 버튼.
class _BackupCard extends StatelessWidget {
  const _BackupCard({
    required this.lastBackupFuture,
    required this.busy,
    required this.onShare,
    required this.onSave,
    required this.onRestore,
  });

  final Future<DateTime?> lastBackupFuture;
  final bool busy;
  final VoidCallback onShare;
  final VoidCallback onSave;
  final VoidCallback onRestore;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Row(
              children: [
                Icon(Icons.backup_outlined, color: kPrimaryGreenDark),
                SizedBox(width: 8),
                Text(
                  '데이터 백업',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            FutureBuilder<DateTime?>(
              future: lastBackupFuture,
              builder: (context, snapshot) {
                final last = snapshot.data;
                final days = last == null
                    ? null
                    : today().difference(dateOnly(last)).inDays;
                final overdue = days == null || days >= kBackupReminderDays;
                return Text(
                  last == null
                      ? '아직 백업한 적이 없어요'
                      : '마지막 백업: ${formatDate(last)}'
                            '${days == 0 ? ' (오늘)' : ' ($days일 전)'}',
                  style: TextStyle(
                    color: overdue ? kNoShowRed : Colors.black87,
                    fontWeight: overdue ? FontWeight.bold : null,
                  ),
                );
              },
            ),
            const SizedBox(height: 4),
            const Text(
              '환자 정보는 이 휴대폰에만 저장돼요. 앱을 지우거나 휴대폰을 바꾸면 '
              '사라지니, 백업 파일을 카카오톡·드라이브·메일로 보내 두세요.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: kPrimaryGreenDark,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: busy ? null : onShare,
              icon: const Icon(Icons.share),
              label: const Text('백업 파일 보내기 (카톡·드라이브·메일)'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: busy ? null : onSave,
              icon: const Icon(Icons.save_alt),
              label: const Text('휴대폰에 백업 파일 저장'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: busy ? null : onRestore,
              style: OutlinedButton.styleFrom(foregroundColor: Colors.orange),
              icon: const Icon(Icons.restore),
              label: const Text('백업 파일에서 복원'),
            ),
          ],
        ),
      ),
    );
  }
}
