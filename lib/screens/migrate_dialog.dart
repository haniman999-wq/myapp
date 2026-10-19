import 'package:flutter/material.dart';

import '../services/customer_database.dart';
import '../services/legacy_local_store.dart';
import '../theme.dart';

/// 이 휴대폰에 남아 있는 예전(서버 이전) 데이터를 공유 서버로 옮깁니다.
///
/// 서버에 이미 환자가 있으면 지우지 않고 '더하기'로 옮깁니다.
/// 옮겼으면 true. 취소했거나 옮길 게 없으면 false.
Future<bool> migrateLegacyData(BuildContext context) async {
  final data = await LegacyLocalStore.read();
  if (data == null || !context.mounted) return false;
  final tables = data['tables'] as Map;
  final count = (tables['customers'] as List).length;
  final appts = (tables['appointments'] as List).length;
  final serverCount =
      (await CustomerDatabase.instance.getAllCustomers()).length;
  if (!context.mounted) return false;

  final ok = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('예전 데이터 서버로 옮기기'),
      content: Text(
        '이 휴대폰 안에 서버로 옮기기 전의 데이터가 있어요.\n'
        '환자 $count명 · 예약/내원 $appts건\n\n'
        '${serverCount == 0 ? '공유 서버로 옮기면 접수 PC와 모든 직원이 함께 볼 수 있어요.' : '서버에 이미 환자 $serverCount명이 있어요. 지우지 않고 그 뒤에 더해서 옮겨요. (같은 환자가 두 번 들어갈 수 있으니 한 번만 옮기세요)'}',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('나중에'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: kPrimaryGreenDark),
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('서버로 옮기기'),
        ),
      ],
    ),
  );
  if (ok != true) return false;

  try {
    await CustomerDatabase.instance.importData(data, replace: false);
  } on OfflineException {
    return false; // 안내 문구는 저장소가 띄웁니다.
  }
  await LegacyLocalStore.markMigrated();
  CustomerDatabase.instance.messengerKey.currentState?.showSnackBar(
    SnackBar(content: Text('환자 $count명을 서버로 옮겼어요')),
  );
  return true;
}
