import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// 전화 앱을 번호가 입력된 상태로 엽니다.
Future<void> callPhone(BuildContext context, String phone) async {
  final uri = Uri(scheme: 'tel', path: phone.replaceAll('-', ''));
  bool ok;
  try {
    ok = await launchUrl(uri);
  } catch (_) {
    ok = false;
  }
  if (!ok && context.mounted) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('전화 앱을 열 수 없어요')));
  }
}
