import 'package:flutter/material.dart';

import '../models/customer_overview.dart';
import '../models/herb_alert.dart';
import '../theme.dart';

/// 앱 사용법 설명서.
class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: kPrimaryGreen,
        foregroundColor: Colors.white,
        title: const Text('앱 사용법'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 32),
        children: [
          const _Intro(),
          const SizedBox(height: 8),
          for (final s in _sections) _SectionTile(section: s),
        ],
      ),
    );
  }
}

class _Intro extends StatelessWidget {
  const _Intro();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kPrimaryGreen.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '내 환자의 모든 것',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: kPrimaryGreenDark,
            ),
          ),
          SizedBox(height: 8),
          Text(
            '환자 예약을 달력으로 관리하고, 연락해야 할 환자를 놓치지 않게 알려주는 앱이에요.\n\n'
            '• 마지막 방문 후 $kRevisitDays일 동안 재예약이 없는 환자\n'
            '• 한약 복용 환자의 복약 확인 전화 날짜\n\n'
            '를 매일 아침 한 번 모아서 알려드려요. 아래 항목을 눌러 자세한 사용법을 보세요.',
            style: TextStyle(height: 1.5),
          ),
        ],
      ),
    );
  }
}

/// 설명서 한 단원.
class _Section {
  const _Section(this.icon, this.title, this.blocks);

  final IconData icon;
  final String title;
  final List<_Block> blocks;
}

/// 단원 안의 내용 한 덩어리: 소제목(선택) + 문단 + 항목들.
class _Block {
  const _Block({this.heading, this.text, this.items = const []});

  final String? heading;
  final String? text;
  final List<String> items;
}

class _SectionTile extends StatelessWidget {
  const _SectionTile({required this.section});

  final _Section section;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        leading: Icon(section.icon, color: kPrimaryGreenDark),
        title: Text(
          section.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final b in section.blocks) ...[
            if (b.heading != null)
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 4),
                child: Text(
                  b.heading!,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: kPrimaryGreenDark,
                  ),
                ),
              ),
            if (b.text != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(b.text!, style: const TextStyle(height: 1.5)),
              ),
            for (final item in b.items)
              Padding(
                padding: const EdgeInsets.only(top: 4, left: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('•  ', style: TextStyle(height: 1.5)),
                    Expanded(
                      child: Text(item, style: const TextStyle(height: 1.5)),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
}

const _sections = [
  _Section(Icons.rocket_launch_outlined, '1. 처음 시작하기', [
    _Block(
      text:
          '앱을 처음 열면 "알림을 보내도록 허용할까요?"가 나와요. 꼭 [허용]을 눌러 주세요. '
          '허용하지 않으면 휴대폰 알림이 오지 않아요. (앱 안의 표시는 그대로 보여요)',
    ),
    _Block(
      heading: '알림을 정확한 시간에 받으려면',
      items: [
        '설정 탭 → "정확한 시간에 알림 받기"를 눌러 \'알람 및 리마인더\'를 허용하세요. '
            '이 항목이 안 보이면 이미 허용된 상태예요.',
        '허용하지 않으면 휴대폰이 배터리를 아끼느라 알림이 최대 1시간 늦게 올 수 있어요.',
        '삼성 휴대폰은 [설정 → 애플리케이션 → 내 환자의 모든 것 → 배터리]에서 '
            '\'제한 없음\'으로 해 두면 더 확실해요.',
      ],
    ),
    _Block(
      heading: '첫 환자 등록',
      items: [
        '아래 [환자] 탭 → 오른쪽 아래 [환자 추가]를 누르세요.',
        '저장하면 바로 그 환자 화면으로 넘어가요. [일정 추가]로 첫 내원이나 예약을 넣으면 돼요.',
      ],
    ),
  ]),
  _Section(Icons.dashboard_outlined, '2. 화면 구성 (아래 탭 5개)', [
    _Block(
      items: [
        '달력: 첫 화면. 날짜별 예약 인원과 그날 예약 환자 명단을 봐요.',
        '환자: 등록된 모든 환자 목록. 새 환자를 추가해요.',
        '연락: 오늘 연락해야 할 환자 모음. 연락할 사람이 있으면 종 모양 아이콘에 빨간 숫자가 붙고 깜빡여요.',
        '검색: 이름·전화번호·특이사항 메모로 환자를 찾아요.',
        '설정: 백업, 알림 시간, 이 사용법, 전체 삭제.',
      ],
    ),
  ]),
  _Section(Icons.person_add_alt, '3. 환자 등록 · 수정 · 삭제', [
    _Block(
      heading: '등록',
      items: [
        '환자명, 전화번호, 성별은 꼭 넣어야 해요.',
        '특이사항 / 메모: 알레르기, 주의사항, 치료 내용 등을 자유롭게 여러 줄로 적어요. '
            '달력 명단에 첫 줄이 함께 보이고, 검색에서도 찾을 수 있어요.',
        '이름·메모는 휴대폰 키보드(천지인, 두벌식 등) 무엇으로든 입력할 수 있어요.',
      ],
    ),
    _Block(
      heading: '수정',
      items: ['환자 화면 오른쪽 위 연필 아이콘, 또는 노란 특이사항 카드를 누르면 수정할 수 있어요.'],
    ),
    _Block(
      heading: '삭제',
      items: [
        '환자 화면 오른쪽 위 휴지통, 또는 환자 목록에서 이름을 왼쪽으로 밀거나 길게 누르세요.',
        '삭제하면 그 환자의 예약·내원·복약 기록도 모두 지워지고 되돌릴 수 없어요.',
      ],
    ),
  ]),
  _Section(Icons.event_note, '4. 예약 · 내원 기록', [
    _Block(
      text:
          '환자 화면의 [일정 추가]나 달력의 [이 날 예약]으로 기록을 넣어요. '
          '날짜를 고르고 상태를 고르면 돼요.',
    ),
    _Block(
      heading: '예약 시간',
      items: [
        '[시간 선택]을 눌러 예약 시간을 넣을 수 있어요. (선택사항, ✕ 로 지우기)',
        '달력 명단은 예약 시간 순서대로 위에서 아래로 보여요. '
            '시간이 없는 예약은 맨 아래에 "시간 미정"으로 나와요.',
        '환자 화면의 기록과 "다음 예약"에도 시간이 함께 보여요.',
      ],
    ),
    _Block(
      heading: '상태 4가지',
      items: [
        '예약(파랑): 앞으로 오기로 한 날. 오늘이나 미래 날짜는 기본으로 \'예약\'이 골라져요.',
        '내원(초록): 실제로 온 날. 지난 날짜는 기본으로 \'내원\'이 골라져요.',
        '노쇼(빨강): 예약했는데 오지 않은 날. 노쇼는 2주를 기다리지 않고 바로 연락 대상이 돼요.',
        '취소(회색): 취소된 예약. 계산에서 빠지고 달력 인원에도 세지 않아요.',
      ],
    ),
    _Block(
      heading: '내원 확인 (주황)',
      items: [
        '예약일이 지났는데 아직 \'예약\' 상태면 주황색 "내원 확인"이 붙어요.',
        '환자 화면 기록 옆의 [내원] / [노쇼] 버튼으로 바로 처리하세요.',
      ],
    ),
    _Block(
      heading: '고치기 · 지우기',
      items: ['기록을 누르면 날짜·상태를 바꾸거나 [이 기록 삭제]로 지울 수 있어요.'],
    ),
  ]),
  _Section(Icons.calendar_month, '5. 달력 보는 법', [
    _Block(
      items: [
        '오늘 날짜는 진한 초록색 칸으로 크게 보여요.',
        '날짜 아래 "3명" 같은 숫자는 그날 예약·내원 인원이에요. '
            '초록 = 오늘·앞으로, 회색 = 지난 날, 주황 = 내원 확인이 필요한 날.',
        '🌿2 는 그날 복약 확인 전화를 해야 하는 한약 환자 수예요.',
        '날짜를 누르면 아래에 그날 환자 명단이 예약 시간 순서로 나와요. 왼쪽에 "오전 10:30"처럼 시간이 보여요. '
            '이름을 누르면 환자 화면, 오른쪽 상태 표시를 누르면 상태를 바꿀 수 있어요.',
        '[이 날 예약]: 고른 날짜에 바로 예약을 넣어요. (환자를 골라야 해요)',
        '위쪽 [한 달 / 2주 / 1주] 버튼으로 보기를 바꾸고, [오늘]로 오늘로 돌아와요.',
        '일요일은 빨간색, 토요일은 파란색이에요.',
        '백업한 지 오래되면 달력 위에 주황색 안내 띠가 떠요. 누르면 바로 백업할 수 있어요.',
      ],
    ),
  ]),
  _Section(Icons.phone_callback, '6. 재방문 연락 규칙', [
    _Block(text: '마지막 일정 후 $kRevisitDays일이 지나도록 다음 예약이 없으면 "연락 필요" 환자가 돼요.'),
    _Block(
      heading: '자세한 기준',
      items: [
        '마지막 일정 = 오늘 이전의 내원·노쇼·처리 안 된 예약 중 가장 최근 날짜 (취소는 제외).',
        '오늘 또는 앞으로 \'예약\'이 하나라도 있으면 연락 대상이 아니에요.',
        '노쇼면 그날 바로 연락 대상이 돼요.',
        '환자 목록에서 이름이 빨간색이 되고 깜빡이는 "연락 필요" 표시가 붙어요.',
        '연락 탭 아래쪽 "3일 이내 연락 예정"에서 곧 연락할 환자를 미리 볼 수 있어요.',
      ],
    ),
    _Block(
      heading: '연락한 뒤에는',
      items: [
        '[연락함]을 누르면 처리돼요. 환자가 재예약하면 [재예약]으로 바로 예약을 넣으세요. '
            '예약이 생기면 연락 대상에서 자동으로 빠져요.',
      ],
    ),
  ]),
  _Section(Icons.auto_awesome, '7. 반짝이는 이름 (연락해야 할 환자)', [
    _Block(
      text:
          '지금 연락해야 하는 환자는 달력 명단 · 환자 목록 · 검색 · 연락 탭 어디서든 '
          '이름 둘레가 반짝반짝 빛나고 🔔 표시가 붙어요. 처리하면 빛이 꺼져요.',
      items: [
        '금색으로 빛남: 오늘 복약 확인 전화를 해야 하는 한약 환자',
        '빨간색으로 빛남: 재방문 연락이 필요한 환자 (일 동안 재예약 없음, 노쇼)',
        '[연락함] 또는 [확인 완료]를 누르거나 재예약하면 더 이상 빛나지 않아요.',
      ],
    ),
  ]),
  _Section(Icons.notifications_active_outlined, '8. 연락 탭 사용법', [
    _Block(
      text: '오늘 연락해야 할 환자가 모두 모여 있어요. 위에서부터 이렇게 나와요.',
      items: [
        '📁 놓친 연락 N명 ($kMaxReminderDays일 넘게 연락 못 한 환자가 있을 때만)',
        '🌿 복약 확인 전화',
        '지금 연락하기 (재방문)',
        '3일 이내 연락 예정',
      ],
    ),
    _Block(
      heading: '전화 걸기',
      items: [
        '초록 📞 버튼을 누르면 전화 앱이 그 번호가 입력된 채로 열려요. 통화 버튼만 누르면 돼요.',
        '잘못 눌러 바로 걸리는 일이 없도록 번호를 한 번 확인하는 단계가 있어요.',
      ],
    ),
    _Block(
      heading: '처리하기 ("알림 끄기")',
      items: [
        '재방문: ✓ 버튼(연락함)을 누르면 회색으로 바뀌고 다음 알림에서 빠져요.',
        '복약 확인: ⋮ 메뉴 → [확인 완료]. 약이 남았으면 [일정 미루기].',
        '처리할 때까지 매일 아침 알림에 계속 나오고, 목록의 표시도 계속 깜빡여요.',
        '"3/$kMaxReminderDays일째 알림"은 며칠째 알리고 있는지를 뜻해요.',
      ],
    ),
  ]),
  _Section(Icons.spa_outlined, '9. 한약 복약 관리', [
    _Block(
      text:
          '한약을 먹는 환자는 이름이 보라색·아주 굵게 보이고 🌿 한약 배지가 붙어 한눈에 구분돼요. '
          '한약 환자도 재방문 규칙($kRevisitDays일)은 똑같이 적용돼요.',
    ),
    _Block(
      heading: '복약 시작',
      items: [
        '환자 화면 → [🌿 한약 복약 시작]을 누르세요.',
        '오늘이 복약 시작일이 되고, 확인 전화 알림이 +15일, +25일로 자동 설정돼요. '
            '그대로 [복약 시작]을 누르면 끝.',
        '알림은 재예약 여부와 상관없이 그날 무조건 나와요.',
      ],
    ),
    _Block(
      heading: '알림 날짜 늘리기 · 빼기 (최대 $kMaxHerbAlerts개)',
      items: [
        '[달력에서 날짜 골라 추가]: 원하는 날을 직접 골라요. 여러 달 복약하는 환자는 한 달 뒤, 두 달 뒤도 미리 넣어둘 수 있어요.',
        '빠른 추가 (+7일 · +15일 · +30일 · +60일 · +90일 등): 시작일 기준으로 한 번에 넣어요.',
        '각 알림 오른쪽 ✕ 로 뺄 수 있어요.',
        '알림에는 "복약 15일"처럼 시작일로부터 며칠째인지가 표시돼요.',
      ],
    ),
    _Block(
      heading: '복약이 밀렸을 때 – [일정 미루기]',
      text:
          '연락해 보니 "7일 동안 약을 못 먹었다"면 [일정 미루기] → 7일을 고르세요. '
          '복약 시작일과 아직 확인 안 한 알림이 모두 7일씩 뒤로 밀리고, 알림도 다시 맞춰져요.',
      items: [
        '예: 시작 10/1, 알림 10/16(15일째)·10/26(25일째) → 7일 미루기 → '
            '시작 10/8, 알림 10/23(15일째)·11/2(25일째).',
        '3·5·7·10·14일 중에서 고르거나 원하는 숫자를 직접 넣을 수 있어요.',
      ],
    ),
    _Block(
      heading: '그 밖에',
      items: [
        '[일정 수정]: 시작일을 바꾸면 알림 날짜도 같은 만큼 함께 옮겨져요. 알림을 더하고 뺄 수도 있어요.',
        '[확인 완료]: 그 알림 하나만 끝내요. 다음 알림은 그대로 남아요.',
        '[복약 종료]: 남은 알림이 모두 취소되고 한약 표시가 사라져요. (확인한 기록은 남아요)',
      ],
    ),
  ]),
  _Section(Icons.alarm, '10. 휴대폰 알림', [
    _Block(
      text: '환자마다 따로 오지 않고, 매일 아침 정해둔 시간에 한 번 모아서 와요.',
      items: [
        '예: "오늘 연락할 환자 5명 (복약 확인 2명 · 재방문 3명)"\n'
            '     "🌿김한약, 이영희(3일째), 박철수 외 2명 · 눌러서 연락하기"',
        '알림을 누르면 앱의 [연락] 탭이 바로 열려요.',
        '잠금화면에서는 환자 이름이 가려져요. (개인정보 보호)',
      ],
    ),
    _Block(
      heading: '알림 시간 바꾸기',
      items: ['설정 → "아침 요약 알림 시간"을 눌러 원하는 시간(예: 오전 8:30)으로 바꾸세요. 기본은 오전 9:00.'],
    ),
    _Block(
      heading: '처리 안 하면 최대 $kMaxReminderDays일 동안 반복',
      items: [
        '연락할 날 알림을 놓쳐서 처리하지 않으면, 다음 날 아침에도 다시 알려드려요.',
        '두 번째 날부터는 이름 뒤에 "(2일째)", "(3일째)"처럼 며칠째인지 붙어요.',
        '$kMaxReminderDays일 동안 처리하지 않으면 알림에서 빠지고 "놓친 연락" 보관함으로 옮겨져요.',
      ],
    ),
    _Block(
      heading: '알아두세요',
      items: [
        '이미 지난 날짜의 기록을 오늘 입력하면 휴대폰 알림 없이 연락 탭에 바로 나와요.',
        '그날 알림 시간이 지난 뒤에 생긴 연락 대상은 다음 날 아침 알림부터 들어가요.',
        '알림이 안 오면: 알림 허용 · 정확한 시간 허용 · 배터리 \'제한 없음\'을 확인하세요.',
      ],
    ),
  ]),
  _Section(Icons.folder_special_outlined, '11. 놓친 연락 보관함', [
    _Block(
      text:
          '연락할 날부터 $kMaxReminderDays일 동안 매일 알렸는데도 [연락함] / [확인 완료]를 '
          '누르지 않은 환자들이 따로 모이는 곳이에요.',
      items: [
        '연락 탭 맨 위 갈색 "놓친 연락 N명"을 누르면 열려요.',
        '환자 목록에서도 갈색 "놓친 연락" 표시가 붙어요.',
        '여기서도 📞 전화, ⋮ 메뉴로 [연락함] · [확인 완료] · [일정 미루기]를 할 수 있어요.',
        '처리하면 목록에서 빠져요. 아침 알림에는 더 이상 나오지 않으니 가끔 확인해 주세요.',
      ],
    ),
  ]),
  _Section(Icons.search, '12. 검색', [
    _Block(
      items: [
        '이름, 전화번호, 특이사항 메모 내용으로 찾을 수 있어요.',
        '전화번호는 하이픈(-) 없이 숫자만 넣어도 찾아요.',
        '찾은 환자를 누르면 환자 화면으로 가요.',
      ],
    ),
  ]),
  _Section(Icons.backup_outlined, '13. 백업 · 복원 (꼭 해두세요)', [
    _Block(
      text:
          '환자 정보는 이 휴대폰 안에만 저장돼요. 앱을 지우거나 휴대폰을 잃어버리면 '
          '데이터도 함께 사라지니 백업 파일을 다른 곳에 보관해 두세요.',
    ),
    _Block(
      heading: '백업하기 (설정 → 데이터 백업)',
      items: [
        '[백업 파일 보내기]: 카카오톡 \'나와의 채팅\', 구글 드라이브, 메일로 보내요. 가장 추천해요.',
        '[휴대폰에 백업 파일 저장]: 다운로드 폴더 등에 저장해요. 휴대폰을 잃어버리면 같이 사라지니 주의.',
        '백업한 지 7일이 지나면 설정과 달력 위에 안내가 떠요.',
      ],
    ),
    _Block(
      heading: '복원하기',
      items: [
        '[백업 파일에서 복원] → 파일 선택 → 내용(환자 수 등)을 확인하고 [복원하기].',
        '복원하면 지금 앱의 데이터는 모두 백업 내용으로 바뀌어요.',
      ],
    ),
    _Block(
      heading: '휴대폰을 바꿀 때',
      items: [
        '① 예전 휴대폰에서 [백업 파일 보내기]',
        '② 새 휴대폰에 앱(APK) 설치',
        '③ 설정 → [백업 파일에서 복원]',
      ],
    ),
    _Block(
      heading: '주의',
      items: [
        '백업 파일에는 환자 이름·전화번호·메모가 그대로 들어 있어요. '
            '단체방이나 다른 사람에게 보내지 말고 본인만 볼 수 있는 곳에 보관하세요.',
      ],
    ),
  ]),
  _Section(Icons.help_outline, '14. 자주 묻는 질문', [
    _Block(
      heading: '여러 휴대폰에서 같이 쓸 수 있나요?',
      text:
          '지금은 한 휴대폰에서만 쓰는 앱이에요. 다른 휴대폰과 데이터가 자동으로 맞춰지지 않아요. '
          '옮길 때는 백업·복원을 쓰세요.',
    ),
    _Block(
      heading: '앱을 새 버전으로 업데이트하면 데이터가 지워지나요?',
      text: '아니요. 새 APK를 덮어 설치하면 데이터는 그대로예요. 앱을 \'삭제\'하면 지워지니 주의하세요.',
    ),
    _Block(
      heading: '알림이 안 와요.',
      items: [
        '휴대폰 설정에서 이 앱의 알림이 켜져 있는지 확인하세요.',
        '설정 탭의 "정확한 시간에 알림 받기"를 허용하세요.',
        '배터리 설정을 \'제한 없음\'으로 바꾸세요.',
        '연락할 환자가 없는 날은 알림이 오지 않아요.',
      ],
    ),
    _Block(
      heading: '[연락함]을 실수로 눌렀어요.',
      text:
          '그 환자는 이번 연락 기한에서는 처리된 것으로 봐요. '
          '다시 연락 대상으로 보려면 다음 예약·내원 기록을 넣으면 그 날짜 기준으로 다시 계산돼요.',
    ),
    _Block(
      heading: '전체 삭제는 되돌릴 수 있나요?',
      text: '아니요. 전체 삭제 전에 반드시 백업해 두세요. 백업 파일이 있으면 복원으로 되살릴 수 있어요.',
    ),
  ]),
];
