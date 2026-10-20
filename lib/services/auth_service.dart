import 'package:supabase_flutter/supabase_flutter.dart';

import 'customer_database.dart';

/// 직원 로그인 / 로그아웃.
///
/// 직원 계정은 관리자가 Supabase 대시보드에서 만듭니다 (앱에서 가입 불가).
/// 로그인 상태는 기기에 저장돼서 앱을 다시 켜도 유지됩니다.
class AuthService {
  AuthService._();

  static GoTrueClient get _auth => Supabase.instance.client.auth;

  static bool get isSignedIn => _auth.currentSession != null;

  static String? get email => _auth.currentUser?.email;

  /// 성공하면 null, 실패하면 보여줄 한국어 문구.
  static Future<String?> signIn(String email, String password) async {
    try {
      await _auth.signInWithPassword(email: email.trim(), password: password);
      CustomerDatabase.instance
        ..notifyChanged()
        ..startRealtime();
      return null;
    } on AuthException catch (e) {
      final m = e.message.toLowerCase();
      if (m.contains('host lookup') ||
          m.contains('socketexception') ||
          m.contains('clientexception') ||
          m.contains('connection')) {
        return '인터넷 연결을 확인해 주세요';
      }
      if (m.contains('invalid login') || m.contains('invalid_credentials')) {
        return '이메일 또는 비밀번호가 맞지 않아요';
      }
      if (m.contains('email not confirmed')) {
        return '아직 승인되지 않은 계정이에요. 관리자에게 문의하세요';
      }
      return '로그인하지 못했어요: ${e.message}';
    } catch (_) {
      return '인터넷 연결을 확인해 주세요';
    }
  }

  static Future<void> signOut() async {
    await CustomerDatabase.instance.clearLocal();
    try {
      await _auth.signOut();
    } catch (_) {
      // 인터넷이 없어도 이 기기에서는 로그아웃 처리됩니다.
    }
  }
}
