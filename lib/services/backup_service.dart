import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'customer_database.dart';

/// 마지막 백업 후 이 날 수가 지나면 백업하라고 안내합니다.
const int kBackupReminderDays = 7;

/// 데이터 백업 파일 만들기 · 공유 · 복원.
///
/// 백업 파일은 JSON 한 개입니다. 카카오톡·드라이브·메일로 보내거나 휴대폰에 저장해 두고,
/// 새 휴대폰이나 앱을 다시 설치했을 때 [restore] 로 그대로 되돌립니다.
class BackupService {
  BackupService._();

  static final _db = CustomerDatabase.instance;

  static String _fileName(DateTime now) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '내환자백업_${now.year}${two(now.month)}${two(now.day)}'
        '_${two(now.hour)}${two(now.minute)}.json';
  }

  static Future<(String, Uint8List)> _build() async {
    final now = DateTime.now();
    final json = const JsonEncoder.withIndent(
      ' ',
    ).convert(await _db.exportData());
    return (_fileName(now), Uint8List.fromList(utf8.encode(json)));
  }

  /// 공유 창(카카오톡, 드라이브, 메일 등)으로 백업 파일을 보냅니다.
  /// 보낼 곳을 고르면 true.
  static Future<bool> share() async {
    final (name, bytes) = await _build();
    final dir = await getTemporaryDirectory();
    final file = File(p.join(dir.path, name));
    await file.writeAsBytes(bytes, flush: true);

    final result = await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: 'application/json')],
        subject: '내 환자의 모든 것 백업',
        text: '내 환자의 모든 것 백업 파일 ($name)',
      ),
    );
    final ok = result.status == ShareResultStatus.success;
    if (ok) await _db.setLastBackupAt(DateTime.now());
    return ok;
  }

  /// 휴대폰 안 원하는 폴더(다운로드 등)에 백업 파일을 저장합니다. 저장하면 true.
  static Future<bool> saveToDevice() async {
    final (name, bytes) = await _build();
    final uri = await FilePicker.saveFile(
      fileName: name,
      bytes: bytes,
      mimeType: 'application/json',
      dialogTitle: '백업 파일 저장',
    );
    if (uri == null) return false;
    await _db.setLastBackupAt(DateTime.now());
    return true;
  }

  /// 백업 파일을 골라 내용을 읽습니다. 취소하면 null, 형식이 틀리면 [FormatException].
  static Future<BackupFile?> pick() async {
    final picked = await FilePicker.pickFile(dialogTitle: '백업 파일 선택');
    if (picked == null) return null;
    final Object? decoded;
    try {
      decoded = jsonDecode(utf8.decode(await picked.readAsBytes()));
    } catch (_) {
      throw const FormatException('백업 파일을 읽을 수 없어요');
    }
    if (decoded is! Map ||
        decoded['format'] != CustomerDatabase.backupFormat ||
        decoded['tables'] is! Map) {
      throw const FormatException('이 앱의 백업 파일이 아니에요');
    }
    return BackupFile(picked.name, decoded.cast<String, Object?>());
  }

  /// 고른 백업으로 지금 데이터를 모두 바꿉니다.
  static Future<void> restore(BackupFile backup) => _db.importData(backup.data);
}

/// 읽어 들인 백업 파일. 복원 전에 무엇이 들어 있는지 보여주는 데 씁니다.
class BackupFile {
  BackupFile(this.fileName, this.data);

  final String fileName;
  final Map<String, Object?> data;

  int _count(String table) {
    final rows = (data['tables'] as Map)[table];
    return rows is List ? rows.length : 0;
  }

  int get patientCount => _count('customers');
  int get appointmentCount => _count('appointments');
  int get herbAlertCount => _count('herb_alerts');

  DateTime? get exportedAt =>
      DateTime.tryParse(data['exportedAt'] as String? ?? '');
}
