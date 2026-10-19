import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

/// 휴대폰: 전화 앱을 번호가 입력된 상태로 엽니다.
/// PC: 전화를 걸 수 없으니 번호를 크게 보여주고 복사해 둡니다 (사무실 전화로 걸 때 보고 누르기).
Future<void> callPhone(BuildContext context, String phone) async {
  if (!kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux)) {
    await Clipboard.setData(ClipboardData(text: phone));
    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.call, size: 32),
        title: const Text('전화번호'),
        content: SelectableText(
          phone,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
        ),
        actions: [
          const Text('번호를 복사해 두었어요', style: TextStyle(color: Colors.grey)),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('닫기'),
          ),
        ],
      ),
    );
    return;
  }

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
