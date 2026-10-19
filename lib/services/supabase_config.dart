/// 공유 서버(Supabase) 연결 정보.
///
/// publishable 키는 앱 안에 들어가는 공개용 열쇠입니다. 서버의 접근 규칙(RLS)과
/// '가입 막기' 설정 덕분에 이 키만으로는 로그인하지 않은 사람이 아무것도 볼 수 없습니다.
/// ⚠️ secret / service_role 키는 절대 여기에 넣지 마세요.
abstract final class SupabaseConfig {
  static const url = 'https://beidakpbtmaoqpoxptnw.supabase.co';
  static const publishableKey =
      'sb_publishable__Lo72-3aMlJg8Mv5hNRbIg_Ze_QLfoT';
}
