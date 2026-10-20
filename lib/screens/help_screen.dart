import 'package:flutter/material.dart';

import '../models/appointment.dart';
import '../models/customer.dart';
import '../models/customer_overview.dart';
import '../models/herb_alert.dart';
import '../theme.dart';
import '../utils/date_format.dart';
import '../widgets/blink.dart';
import '../widgets/customer_name.dart';
import '../widgets/herb_energy_bar.dart';
import '../widgets/status_chip.dart';

/// 앱 사용법 설명서.
///
/// 실제 화면 캡처(assets/help/*.jpg, tool/make_help_images.dart 로 생성)와
/// 앱에서 쓰는 진짜 표시 위젯(초진 배지, ⑤, 에너지바, 반짝이는 이름 등)으로
/// 처음 쓰는 사람도 따라 할 수 있게 설명합니다.
class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final sections = _buildSections();
    return Scaffold(
      appBar: AppBar(
        backgroundColor: kPrimaryGreen,
        foregroundColor: Colors.white,
        title: const Text('앱 사용법'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 40),
        children: [
          const _Intro(),
          const SizedBox(height: 8),
          for (final s in sections) _SectionTile(section: s),
          const SizedBox(height: 16),
          const Center(
            child: Text(
              '항목을 누르면 펼쳐져요 · 사진을 누르면 크게 볼 수 있어요',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }
}

// ───────────────────────── 화면 조각 ─────────────────────────

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
            '한의원 환자 예약을 달력으로 관리하고, 연락해야 할 환자를 놓치지 않게 '
            '알려주는 앱이에요. 접수 PC와 직원 휴대폰이 직원 계정으로 로그인해 같은 데이터를 실시간으로 함께 봐요.\n\n'
            '처음 쓰신다면 아래 순서대로 읽어 보세요.\n'
            '① 처음 시작하기 → ② 화면 구성 → ③ 표시·아이콘 한눈에 보기\n'
            '그다음은 필요한 기능만 골라 읽으면 돼요.',
            style: TextStyle(height: 1.6),
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

/// 단원 안의 내용 한 덩어리.
/// 소제목 · 문단 · 번호 단계 · 점 항목 · 화면 사진 · 표시 견본(진짜 위젯) 중 필요한 것만 씁니다.
class _Block {
  const _Block({
    this.heading,
    this.text,
    this.steps = const [],
    this.items = const [],
    this.image,
    this.caption,
    this.legend = const [],
  });

  final String? heading;
  final String? text;

  /// ① ② ③ 처럼 번호를 붙여 보여줄 따라 하기 단계.
  final List<String> steps;

  /// • 점으로 보여줄 항목.
  final List<String> items;

  /// assets/help/ 안의 화면 캡처 파일 이름 (확장자 제외).
  final String? image;
  final String? caption;

  /// (견본 위젯, 설명) 목록. 앱에서 실제로 쓰는 표시를 그대로 보여줍니다.
  final List<(Widget, String)> legend;
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
        children: [for (final b in section.blocks) _BlockView(block: b)],
      ),
    );
  }
}

class _BlockView extends StatelessWidget {
  const _BlockView({required this.block});

  final _Block block;

  static const _body = TextStyle(height: 1.55, fontSize: 14.5);
  static const _nums = '①②③④⑤⑥⑦⑧⑨⑩⑪⑫';

  @override
  Widget build(BuildContext context) {
    final b = block;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (b.heading != null)
          Padding(
            padding: const EdgeInsets.only(top: 14, bottom: 4),
            child: Text(
              b.heading!,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: kPrimaryGreenDark,
              ),
            ),
          ),
        if (b.text != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(b.text!, style: _body),
          ),
        for (final (i, step) in b.steps.indexed)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 24,
                  child: Text(
                    i < _nums.length ? _nums[i] : '${i + 1}.',
                    style: const TextStyle(
                      fontSize: 16,
                      height: 1.35,
                      color: kPrimaryGreenDark,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(child: Text(step, style: _body)),
              ],
            ),
          ),
        for (final item in b.items)
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('•  ', style: _body),
                Expanded(child: Text(item, style: _body)),
              ],
            ),
          ),
        if (b.legend.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Column(
              children: [
                for (final (i, (sample, desc)) in b.legend.indexed) ...[
                  if (i > 0) Divider(height: 1, color: Colors.grey.shade200),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 150,
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: sample,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            desc,
                            style: const TextStyle(fontSize: 13.5, height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        if (b.image != null) _Shot(name: b.image!, caption: b.caption),
      ],
    );
  }
}

/// 화면 캡처 한 장. 누르면 크게 볼 수 있습니다.
class _Shot extends StatelessWidget {
  const _Shot({required this.name, this.caption});

  final String name;
  final String? caption;

  String get _path => 'assets/help/$name.jpg';

  void _zoom(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.all(12),
        child: Stack(
          children: [
            InteractiveViewer(
              maxScale: 4,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(_path),
              ),
            ),
            Positioned(
              right: 4,
              top: 4,
              child: IconButton.filled(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Column(
        children: [
          Center(
            child: GestureDetector(
              onTap: () => _zoom(context),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 330),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade400),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(11),
                  child: Image.asset(_path),
                ),
              ),
            ),
          ),
          if (caption != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                caption!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12.5, color: Colors.grey),
              ),
            ),
        ],
      ),
    );
  }
}

// ───────────────────────── 견본 위젯 ─────────────────────────

Customer _sample(
  String name, {
  HerbType? herb,
  int? days,
  int startDaysAgo = 0,
}) => Customer(
  name: name,
  phone: '010-0000-0000',
  gender: '여',
  herbStart: herb == null
      ? null
      : today().subtract(Duration(days: startDaysAgo)),
  herbType: herb ?? HerbType.nonInsured,
  herbDays: days,
  createdAt: today(),
);

Widget _firstVisitBadge() => Container(
  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
  decoration: BoxDecoration(
    color: kFirstVisitBlue,
    borderRadius: BorderRadius.circular(6),
  ),
  child: const Text(
    '초진',
    style: TextStyle(
      color: Colors.white,
      fontSize: 12,
      fontWeight: FontWeight.bold,
    ),
  ),
);

Widget _dayCount(String text, Color bg, {Color fg = Colors.white}) => Container(
  padding: const EdgeInsets.symmetric(horizontal: 6),
  decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
  child: Text(
    text,
    style: TextStyle(
      color: fg,
      fontSize: 11,
      height: 1.4,
      fontWeight: FontWeight.bold,
    ),
  ),
);

Widget _icon(IconData icon, {Color color = kPrimaryGreenDark, String? label}) =>
    Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 22),
        if (label != null) ...[
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(color: color, fontWeight: FontWeight.bold),
          ),
        ],
      ],
    );

// ───────────────────────── 설명서 내용 ─────────────────────────

List<_Section> _buildSections() => [
  _Section(Icons.rocket_launch_outlined, '1. 처음 시작하기', [
    const _Block(
      heading: '앱 설치 (휴대폰)',
      steps: [
        'PC에서 받은 "내환자의모든것.apk" 파일을 카카오톡 \'나와의 채팅\' 등으로 휴대폰에 보내요. '
            '카톡이 apk를 막으면 같은 이름의 .zip 파일을 보내고, 휴대폰 \'내 파일\' 앱에서 압축을 풀어요.',
        '휴대폰에서 apk 파일을 눌러요.',
        '"출처를 알 수 없는 앱" 경고가 나오면 [설정] → \'이 출처 허용\'을 켜고 뒤로 가서 [설치]를 눌러요. '
            '"Play 프로텍트" 경고가 나오면 [무시하고 설치]를 눌러요.',
        '새 버전을 받으면 지우지 말고 그냥 덮어 설치하세요. 데이터는 그대로 남아요.',
      ],
    ),
    const _Block(
      heading: '처음 켰을 때 꼭 할 것',
      steps: [
        '"알림을 보내도록 허용할까요?" → [허용]. 허용하지 않으면 휴대폰 알림이 오지 않아요.',
        '설정 탭 → "정확한 시간에 알림 받기"를 눌러 \'알람 및 리마인더\'를 허용해요. '
            '(이 줄이 안 보이면 이미 허용된 상태예요)',
        '삼성 휴대폰: 휴대폰 [설정 → 애플리케이션 → 내 환자의 모든 것 → 배터리]를 \'제한 없음\'으로.',
        '설정 탭 → "아침 요약 알림 시간"을 원하는 시간으로 맞춰요. (기본 오전 9:00)',
      ],
      image: 'settings_notify',
      caption: '설정 탭의 알림 설정',
    ),
    const _Block(
      heading: '첫 환자 등록해 보기',
      steps: [
        '아래 [환자] 탭 → 오른쪽 아래 초록 [환자 추가] 버튼.',
        '환자명 · 전화번호 · 성별을 넣고, 필요하면 특이사항/메모도 적어요.',
        '[저장하기] → "저장되었습니다!" → [확인]. 바로 그 환자 화면으로 넘어가요.',
        '환자 화면 오른쪽 아래 [일정 추가]로 첫 예약(또는 오늘 내원)을 넣으면 끝이에요.',
      ],
      image: 'form',
      caption: '새 환자 등록 화면',
    ),
  ]),
  _Section(Icons.dashboard_outlined, '2. 화면 구성 (아래 탭 5개)', [
    const _Block(
      text: '화면 맨 아래에 탭이 5개 있어요. 앱을 켜면 첫 화면은 [달력]이에요.',
      items: [
        '달력: 날짜별 예약 인원과, 고른 날짜의 예약 환자 명단(시간 순).',
        '환자: 등록된 모든 환자 목록. 새 환자 추가.',
        '연락: 오늘 연락해야 할 환자 모음. 연락할 사람이 있으면 종 아이콘에 빨간 숫자가 붙고 깜빡여요.',
        '검색: 이름 · 전화번호 · 특이사항 메모로 환자 찾기.',
        '설정: 앱 사용법, 데이터 백업·복원, 알림 시간, 전체 삭제.',
      ],
      image: 'calendar',
      caption: '첫 화면 [달력] 탭',
    ),
    _Block(
      heading: '화면 위쪽 버튼',
      legend: [
        (
          _icon(Icons.help_outline, color: Colors.grey.shade700),
          '달력 화면 오른쪽 위 ? → 이 사용법을 바로 열어요.',
        ),
        (
          _icon(Icons.today, color: Colors.grey.shade700, label: '오늘'),
          '다른 달을 보다가 오늘 날짜로 돌아와요.',
        ),
        (
          _icon(Icons.edit, color: Colors.grey.shade700),
          '환자 화면 오른쪽 위 연필 → 환자 정보 수정.',
        ),
        (
          _icon(Icons.delete_outline, color: Colors.grey.shade700),
          '환자 화면 오른쪽 위 휴지통 → 환자 삭제.',
        ),
        (
          _icon(Icons.call, color: kPrimaryGreenDark),
          '전화 버튼 → 전화 앱이 그 번호가 입력된 채 열려요. 통화 버튼만 누르면 돼요.',
        ),
      ],
    ),
  ]),
  _Section(Icons.palette_outlined, '3. 표시·아이콘 한눈에 보기', [
    const _Block(text: '앱 곳곳에 나오는 표시들이에요. 아래 견본은 앱에서 실제로 쓰는 모양 그대로예요.'),
    _Block(
      heading: '환자 이름 옆 표시',
      legend: [
        (
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _firstVisitBadge(),
              const SizedBox(width: 6),
              const Text('이서연', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          '초진 (첫 예약·내원). 달력 명단에서는 줄 전체가 연한 파랑 + 왼쪽 파란 띠.',
        ),
        (
          const Text('이재진  3회차', style: TextStyle(fontWeight: FontWeight.bold)),
          '재진. 몇 번째 오는지 작은 회색 글씨로.',
        ),
        (
          CustomerName(customer: _sample('한지우'), milestone: 5),
          '5회차 예약·내원. 분홍 동그라미 ⑤가 반짝여요.',
        ),
        (
          CustomerName(customer: _sample('박준호', herb: HerbType.insured)),
          '건보첩약 복용 환자: 청록색 굵은 이름 + 🌿 건.',
        ),
        (
          CustomerName(customer: _sample('김민지', herb: HerbType.nonInsured)),
          '비급여한약 복용 환자: 보라색 굵은 이름 + 🌿 비급.',
        ),
        (
          CustomerName(customer: _sample('김민지'), glow: kGlowGold),
          '금색으로 반짝: 오늘 복약 확인 전화를 해야 해요.',
        ),
        (
          CustomerName(customer: _sample('정하늘'), glow: kNoShowRed),
          '빨간색으로 반짝: 재방문 연락이 필요해요.',
        ),
      ],
    ),
    _Block(
      heading: '복약 에너지바 – 비급여한약만 (한 달 = 한 묶음, 1칸 = 15일)',
      legend: [
        (
          HerbEnergyBar(
            customer: _sample('a', herb: HerbType.nonInsured, days: 90),
          ),
          '3개월 처방, 막 시작 (꽉 참)',
        ),
        (
          HerbEnergyBar(
            customer: _sample(
              'a',
              herb: HerbType.nonInsured,
              days: 90,
              startDaysAgo: 15,
            ),
          ),
          '3개월 중 15일 지남 → 한 칸 줄어 75일 남음',
        ),
        (
          HerbEnergyBar(
            customer: _sample(
              'a',
              herb: HerbType.nonInsured,
              days: 90,
              startDaysAgo: 55,
            ),
          ),
          '절반 아래로 남으면 주황',
        ),
        (
          HerbEnergyBar(
            customer: _sample(
              'a',
              herb: HerbType.nonInsured,
              days: 90,
              startDaysAgo: 80,
            ),
          ),
          '거의 끝나면 빨강',
        ),
        (
          HerbEnergyBar(
            customer: _sample('a', herb: HerbType.nonInsured, days: 30),
          ),
          '1개월 처방: 첫 묶음만 쓰고 나머지는 흐린 테두리',
        ),
      ],
    ),
    _Block(
      heading: '예약·내원 상태',
      legend: [
        for (final s in AppointmentStatus.values)
          (
            StatusChip(label: s.label, color: s.color),
            switch (s) {
              AppointmentStatus.booked => '앞으로 오기로 한 날',
              AppointmentStatus.visited => '실제로 온 날',
              AppointmentStatus.noShow => '예약했는데 안 온 날 (바로 연락 대상)',
              AppointmentStatus.cancelled => '취소된 예약 (인원·회차에서 빠짐)',
            },
          ),
        (
          const StatusChip(label: '내원 확인', color: Colors.orange),
          '예약일이 지났는데 아직 내원/노쇼를 안 정한 기록',
        ),
      ],
    ),
    _Block(
      heading: '환자 목록 · 연락 탭의 표시',
      legend: [
        (
          const Blink(
            child: StatusChip(label: '연락 필요', color: kNoShowRed),
          ),
          '재방문 연락이 필요 (깜빡임)',
        ),
        (
          const Blink(
            child: StatusChip(label: '복약 확인', color: kHerbPurple),
          ),
          '오늘 복약 확인 전화 (깜빡임)',
        ),
        (
          const StatusChip(label: '놓친 연락', color: kMissedBrown),
          '7일 동안 알렸는데 처리 안 함 → 놓친 연락 보관함',
        ),
        (
          const StatusChip(label: '연락함 10.15', color: Colors.grey),
          '[연락함]을 누른 환자 (회색으로 흐려짐)',
        ),
        (
          Badge(
            label: const Text('3'),
            child: Blink(
              child: Icon(Icons.notifications, color: Colors.grey.shade600),
            ),
          ),
          '아래 [연락] 탭: 아직 처리 안 한 환자 수',
        ),
      ],
    ),
    _Block(
      heading: '달력 날짜 칸',
      legend: [
        (_dayCount('3명', kPrimaryGreenDark), '오늘·앞으로의 예약 인원'),
        (_dayCount('2명', Colors.grey.shade400), '지난 날의 인원'),
        (_dayCount('1명', Colors.orange), '내원 확인이 필요한 기록이 있는 날'),
        (
          const Text(
            '🌿2',
            style: TextStyle(color: kHerbPurple, fontWeight: FontWeight.bold),
          ),
          '그날 복약 확인 전화 인원',
        ),
        (
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: kPrimaryGreen,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              '15',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          '오늘 날짜 (진한 초록 칸)',
        ),
        (const Text('📝 첫 줄', style: TextStyle(fontSize: 13)), '그 날 기록에 적은 메모'),
      ],
    ),
  ]),
  const _Section(Icons.person_add_alt, '4. 환자 등록 · 수정 · 삭제', [
    _Block(
      heading: '등록',
      steps: [
        '[환자] 탭 → [환자 추가].',
        '환자명 · 전화번호(숫자만 쳐도 돼요) · 성별을 넣어요. 이 세 개는 꼭 넣어야 해요.',
        '특이사항 / 메모: 알레르기, 주의사항, 치료 내용 등을 여러 줄로 자유롭게. '
            '달력 명단에 첫 줄이 보이고, 검색으로도 찾을 수 있어요.',
        '[저장하기]. 저장하면 그 환자 화면으로 바로 넘어가요.',
      ],
    ),
    _Block(
      heading: '환자 화면에서 볼 수 있는 것',
      items: [
        '맨 위 카드: 전화번호 · 성별 · 마지막 내원 · 다음 예약(시간 포함) · 마지막 연락, 오른쪽 📞 버튼.',
        '노란 특이사항 카드: 누르면 바로 수정.',
        '한약 카드: 한약 환자면 복약 정보, 아니면 [🌿 한약 복약 시작] 버튼.',
        '빨간 "재방문 연락 필요" 상자: 연락 대상일 때만. [전화] [연락함] [재예약].',
        '예약 · 내원 기록: 최근 날짜부터. 날짜 · 시간 · 회차 · 상태 · 그 날 메모.',
      ],
      image: 'detail_herb',
      caption: '환자 화면 (비급여한약 복용 중인 환자)',
    ),
    _Block(
      heading: '수정 · 삭제',
      items: [
        '수정: 환자 화면 오른쪽 위 연필, 또는 노란 특이사항 카드를 눌러요.',
        '삭제: 환자 화면 오른쪽 위 휴지통, 또는 환자 목록에서 이름을 왼쪽으로 밀거나 길게 눌러요.',
        '삭제하면 그 환자의 예약 · 내원 · 복약 기록이 모두 지워지고 되돌릴 수 없어요.',
      ],
      image: 'patients',
      caption: '[환자] 탭 목록',
    ),
  ]),
  const _Section(Icons.event_note, '5. 예약 · 내원 기록 넣기', [
    _Block(
      text: '환자 화면의 [일정 추가], 또는 달력의 [이 날 예약]을 누르면 아래 창이 열려요.',
      image: 'sheet',
      caption: '일정 추가 창',
    ),
    _Block(
      heading: '따라 하기',
      steps: [
        '날짜 버튼을 눌러 날짜를 골라요. (달력의 [이 날 예약]이면 고른 날짜가 미리 들어가 있어요)',
        '[시간 선택]으로 예약 시간을 넣어요. 안 넣어도 되고, ✕ 로 지울 수 있어요.',
        '상태를 골라요: 예약 / 내원 / 노쇼 / 취소. '
            '오늘·앞으로 날짜는 \'예약\', 지난 날짜는 \'내원\'이 미리 골라져 있어요.',
        '"이 날 메모"에 그날 치료 내용이나 전달 사항을 적어요. (선택)',
        '[저장].',
      ],
    ),
    _Block(
      heading: '고치기 · 지우기 · 내원 처리',
      items: [
        '이미 넣은 기록을 누르면 같은 창이 열려 날짜·시간·상태·메모를 고칠 수 있어요. 맨 아래 [이 기록 삭제].',
        '예약일이 지났는데 \'예약\' 상태면 주황 "내원 확인"이 붙어요. 환자 화면 기록 옆 [내원] / [노쇼]로 바로 처리하세요.',
        '달력 명단에서 오른쪽 상태 표시(예약/내원 등)를 누르면 바로 상태를 바꿀 수 있어요.',
      ],
    ),
  ]),
  _Section(Icons.calendar_month, '6. 달력 보는 법', [
    const _Block(
      items: [
        '오늘 날짜는 진한 초록 칸으로 크게 보여요.',
        '날짜 아래 "4명"은 그날 예약·내원 인원(취소 제외). 초록 = 오늘·앞으로, 회색 = 지난 날, 주황 = 내원 확인 필요.',
        '🌿2 는 그날 복약 확인 전화를 해야 하는 한약 환자 수.',
        '일요일 빨강, 토요일 파랑.',
        '위쪽 [한 달 / 2주 / 1주] 버튼으로 보기를 바꾸고, ‹ › 로 앞뒤 달로 넘겨요. [오늘]로 돌아와요.',
        '백업한 지 7일이 넘으면 달력 위에 주황색 띠가 떠요. [지금 백업]으로 바로 백업.',
      ],
    ),
    const _Block(
      heading: '날짜를 누르면 – 그날 예약 명단',
      items: [
        '예약 시간 순서대로 위에서 아래로 나와요. 왼쪽에 "오전 9:30"처럼 시간. 시간이 없는 예약은 맨 아래 "시간 미정".',
        '초진은 줄 전체가 연한 파랑 + 왼쪽 파란 띠 + [초진] 배지.',
        '이름을 누르면 환자 화면, 오른쪽 상태 표시를 누르면 상태 변경.',
        '아래쪽 "🌿 복약 확인 전화" 명단: 그날 복약 확인할 한약 환자.',
        '[이 날 예약]: 환자를 골라 그 날짜에 바로 예약을 넣어요.',
      ],
      image: 'calendar_today',
      caption: '오늘 명단 – 9:30 초진 이서연, 10:00 재진 김민지(복약 확인으로 금색 반짝)',
    ),
  ]),
  _Section(Icons.looks_one_outlined, '7. 초진 · 회차 · 5회차', [
    _Block(
      text: '취소·노쇼를 뺀 예약·내원을 날짜·시간 순서대로 세어 회차를 매겨요.',
      legend: [
        (_firstVisitBadge(), '1회차 = 초진. 달력 명단에서 파란 줄로 강조.'),
        (
          const Text('4회차', style: TextStyle(color: Colors.grey)),
          '2~4회차, 6회차 이후는 작은 회색 글씨',
        ),
        (const MilestoneBadge(number: 5), '5회차는 반짝이는 분홍 ⑤'),
      ],
    ),
    const _Block(
      items: [
        '첫 예약에 노쇼였으면 세지 않으니, 다음 예약이 초진이 돼요.',
        '아직 오지 않은 예약도 셉니다. 그래서 "5회차 예약"도 미리 ⑤로 보여요.',
        '환자 목록에서는 다음 예약이 5회차인 환자 이름 뒤에 ⑤가 붙어요.',
      ],
      image: 'detail_visits',
      caption: '예약 · 내원 기록 – 초진, 2~4회차, 5회차(⑤)와 그 날 메모',
    ),
  ]),
  const _Section(Icons.phone_callback, '8. 재방문 연락 규칙 (2주)', [
    _Block(
      text: '마지막 일정 후 $kRevisitDays일이 지나도록 다음 예약이 없으면 "연락 필요" 환자가 돼요.',
      items: [
        '마지막 일정 = 오늘 이전의 내원 · 노쇼 · 처리 안 된 예약 중 가장 최근 날짜 (취소 제외).',
        '오늘 또는 앞으로 \'예약\'이 하나라도 있으면 연락 대상이 아니에요.',
        '노쇼면 2주를 기다리지 않고 그날 바로 연락 대상.',
        '한약 환자도 이 규칙은 똑같이 적용돼요.',
      ],
    ),
    _Block(
      heading: '연락한 뒤에는',
      steps: [
        '연락 탭이나 환자 화면에서 📞 로 전화해요.',
        '통화했으면 [연락함](✓ 버튼). 그 환자는 회색으로 흐려지고 다음 알림에서 빠져요.',
        '환자가 다시 예약하면 [재예약]으로 바로 예약을 넣어요. 예약이 생기면 연락 대상에서 자동으로 빠져요.',
      ],
    ),
  ]),
  const _Section(Icons.notifications_active_outlined, '9. 연락 탭 사용법', [
    _Block(
      text: '오늘 연락해야 할 환자가 모두 모여 있어요. 위에서부터:',
      items: [
        '📁 놓친 연락 N명 (있을 때만) – 누르면 놓친 연락 보관함.',
        '🌿 복약 확인 전화 – 오늘(또는 지난) 복약 확인 날인 한약 환자.',
        '지금 연락하기 – 재방문 연락이 필요한 환자.',
        '3일 이내 연락 예정 – 곧 연락 대상이 될 환자 (미리 보기).',
      ],
      image: 'contact',
      caption: '[연락] 탭',
    ),
    _Block(
      heading: '처리하는 법 (= 알림 끄기)',
      items: [
        '📞 초록 전화 버튼 → 전화 앱이 번호가 입력된 채 열려요.',
        '재방문: ✓ 버튼(연락함).',
        '복약 확인: ⋮ 메뉴 → [확인 완료]. 약이 남았으면 [일정 미루기].',
        '"3/7일째 알림"은 며칠째 알리고 있는지예요. 처리할 때까지 최대 7일 동안 매일 아침 다시 알려요.',
      ],
    ),
  ]),
  _Section(Icons.spa_outlined, '10. 한약 복약 관리', [
    _Block(
      heading: '한약 종류 2가지',
      legend: [
        (
          CustomerName(customer: _sample('박준호', herb: HerbType.insured)),
          '건보첩약: 확인 전화 기본 = 시작일 + 10일',
        ),
        (
          CustomerName(customer: _sample('김민지', herb: HerbType.nonInsured)),
          '비급여한약: 확인 전화 기본 = 시작일 + 15일, 25일',
        ),
      ],
    ),
    const _Block(
      heading: '복약 시작 – 따라 하기',
      steps: [
        '환자 화면 → [🌿 한약 복약 시작].',
        '맨 위 "한약 종류"에서 [건보첩약] 또는 [비급여한약]을 골라요. 확인 전화 날짜가 자동으로 채워져요.',
        '(비급여한약만) "복약 기간"에서 [1개월 / 2개월 / 3개월]을 골라요. 바로 아래에 에너지바 미리 보기가 나와요. 건보첩약은 10일치씩 나가서 이 칸이 없어요.',
        '복약 시작일은 오늘로 들어가요. 다른 날이면 시작일 칸을 눌러 바꿔요 (알림 날짜도 같이 옮겨져요).',
        '필요하면 확인 전화 날짜를 더해요: [달력에서 날짜 골라 추가] 또는 빠른 추가(+7일 · +10일 · +15일 · +25일 · +30일 · +45일 · +60일 · +90일). 최대 $kMaxHerbAlerts개. ✕ 로 빼기.',
        '아래 [복약 시작](또는 오른쪽 위 ✓)을 눌러 저장.',
      ],
      image: 'herb_plan',
      caption: '복약 시작 / 일정 수정 화면',
    ),
    const _Block(
      heading: '복약 중일 때 환자 화면의 한약 카드',
      items: [
        '복약 시작일 · 오늘 복약 며칠째 · 복약 기간 + 큰 에너지바 + "남은 75일".',
        '확인 전화 알림 목록: 빨간 🔔 = 오늘(또는 지남), 보라 🔔 = 앞으로. 오늘 것은 [확인 완료].',
        '[일정 수정]: 종류 · 기간 · 시작일 · 알림 날짜 고치기.',
        '[복약 종료]: 남은 알림이 모두 취소되고 한약 표시가 사라져요 (확인한 기록은 남아요).',
      ],
    ),
    const _Block(
      heading: '약을 못 먹어서 밀렸을 때 – [일정 미루기]',
      steps: [
        '한약 카드(또는 연락 탭 ⋮ 메뉴)에서 [일정 미루기].',
        '못 먹은 날 수를 골라요: 3 · 5 · 7 · 10 · 14일, 또는 직접 입력.',
        '[미루기]. 복약 시작일과 아직 확인 안 한 알림이 모두 그만큼 뒤로 밀리고, 에너지바도 그만큼 다시 채워져요.',
      ],
      image: 'postpone',
      caption: '일정 미루기 창',
    ),
    const _Block(
      text:
          '예: 10/1 시작, 확인 전화 10/16(15일째)·10/26(25일째) → 7일 미루기 → '
          '시작 10/8, 확인 전화 10/23·11/2. 에너지바도 7일만큼 다시 채워져요.',
    ),
  ]),
  _Section(Icons.auto_awesome, '11. 반짝이는 이름', [
    _Block(
      text:
          '지금 연락해야 하는 환자는 달력 명단 · 환자 목록 · 검색 · 연락 탭 어디서든 '
          '이름 둘레가 숨 쉬듯 반짝이고 🔔가 붙어요.',
      legend: [
        (
          CustomerName(
            customer: _sample('김민지', herb: HerbType.nonInsured),
            glow: kGlowGold,
          ),
          '금색: 오늘 복약 확인 전화',
        ),
        (
          CustomerName(customer: _sample('정하늘'), glow: kNoShowRed),
          '빨강: 재방문 연락 필요 / 노쇼',
        ),
      ],
    ),
    const _Block(items: ['[연락함]이나 [확인 완료]를 누르거나, 재예약하면 빛이 꺼져요.']),
  ]),
  const _Section(Icons.alarm, '12. 휴대폰 알림', [
    _Block(
      text: '환자마다 따로 오지 않고, 매일 정해둔 시간에 한 번 모아서 와요.',
      items: [
        '예: "오늘 연락할 환자 3명 (복약 확인 2명 · 재방문 1명)"\n'
            '     "🌿김민지(비급), 🌿박준호(건), 정하늘(4일째) · 눌러서 연락하기"',
        '알림을 누르면 앱의 [연락] 탭이 바로 열려요.',
        '잠금화면에서는 환자 이름이 가려져요 (개인정보 보호).',
        '상태 표시줄에는 작은 종 모양 아이콘으로 보여요.',
      ],
    ),
    _Block(
      heading: '처리 안 하면 최대 7일 동안 반복',
      items: [
        '연락할 날 놓쳐서 처리하지 않으면 다음 날 아침에도 다시 알려요. 이름 뒤에 "(2일째)", "(3일째)".',
        '7일 동안 처리하지 않으면 알림에서 빠지고 "놓친 연락" 보관함으로 옮겨져요.',
      ],
    ),
    _Block(
      heading: '알아두세요',
      items: [
        '그날 알림 시간이 지난 뒤에 생긴 연락 대상은 다음 날 아침 알림부터 들어가요 (연락 탭에는 바로 보여요).',
        '연락할 환자가 없는 날은 알림이 오지 않아요.',
        '알림이 안 오면: 알림 허용 · 정확한 시간 허용 · 배터리 \'제한 없음\'을 확인하세요.',
      ],
    ),
  ]),
  const _Section(Icons.folder_special_outlined, '13. 놓친 연락 보관함', [
    _Block(
      text: '연락할 날부터 7일 동안 매일 알렸는데도 [연락함] / [확인 완료]를 누르지 않은 환자들이 모이는 곳이에요.',
      items: [
        '[연락] 탭 맨 위 갈색 "놓친 연락 N명"을 눌러 열어요.',
        '환자 목록에도 갈색 "놓친 연락" 표시가 붙어요.',
        '📞 전화, ⋮ 메뉴로 [연락함] · [재예약하러 가기] · [확인 완료] · [일정 미루기].',
        '처리하면 목록에서 빠져요. 아침 알림에는 더 이상 안 나오니 가끔 확인해 주세요.',
      ],
      image: 'missed',
      caption: '놓친 연락 보관함',
    ),
  ]),
  const _Section(Icons.search, '14. 검색', [
    _Block(
      items: [
        '이름 · 전화번호 · 특이사항 메모 내용으로 찾아요. 일부만 쳐도 돼요.',
        '전화번호는 하이픈(-) 없이 숫자만 넣어도 찾아요.',
        '찾은 환자를 누르면 환자 화면으로 가요.',
      ],
      image: 'search',
      caption: '"1234"로 검색한 결과',
    ),
  ]),
  const _Section(Icons.backup_outlined, '15. 백업 · 복원 (꼭 해두세요)', [
    _Block(
      text:
          '환자 정보는 공유 서버(일본 도쿄)에 저장돼서 휴대폰을 잃어버려도 남아 있어요. '
          '그래도 실수로 지우는 경우에 대비해 가끔 백업 파일을 보관해 두세요. '
          '복원하면 서버 데이터가 바뀌어 모든 직원에게 함께 적용되니 조심하세요.',
      image: 'settings_backup',
      caption: '설정 탭 – 데이터 백업',
    ),
    _Block(
      heading: '백업하기',
      items: [
        '[백업 파일 보내기]: 카카오톡 \'나와의 채팅\', 구글 드라이브, 메일로 보내요. 가장 추천.',
        '[휴대폰에 백업 파일 저장]: 다운로드 폴더 등에 저장. 휴대폰을 잃어버리면 같이 사라지니 주의.',
        '마지막 백업이 7일 넘으면 빨간 글씨 + 달력 위 주황 띠로 알려줘요.',
      ],
    ),
    _Block(
      heading: '복원하기',
      steps: [
        '설정 → [백업 파일에서 복원].',
        '백업 파일(내환자백업_날짜_시간.json)을 골라요.',
        '환자 수 · 예약/내원 수 · 복약 알림 수를 확인하고 [복원하기].',
      ],
      items: ['복원하면 지금 앱의 데이터는 모두 백업 내용으로 바뀌어요.'],
    ),
    _Block(
      heading: '휴대폰을 바꿀 때',
      steps: [
        '예전 휴대폰에서 [백업 파일 보내기] (카톡 나와의 채팅 등).',
        '새 휴대폰에 앱(APK) 설치.',
        '새 휴대폰에서 백업 파일을 받아 두고, 설정 → [백업 파일에서 복원].',
      ],
    ),
    _Block(
      heading: '주의',
      items: [
        '백업 파일에는 환자 이름 · 전화번호 · 메모가 그대로 들어 있어요. 단체방이나 다른 사람에게 보내지 마세요.',
        '[전체 삭제]는 되돌릴 수 없어요. 지우기 전에 꼭 백업하세요.',
      ],
    ),
  ]),
  const _Section(Icons.insights_outlined, '16. 진료과 · 경영 통계', [
    _Block(
      heading: '진료과 넣기',
      steps: [
        '예약·내원 기록을 넣는 창 위쪽에서 진료과(1과~5과)를 눌러 고르세요.',
        '한 번 고르면 그 환자의 다음 기록에는 같은 과가 미리 골라져 있어요.',
        '고른 과는 환자 이름 옆에 색깔 테두리 배지로 보여요 (달력·환자·연락·검색 모두).',
        '과 이름(예: 침구과)은 관리자가 설정 → [관리자 설정]에서 바꿀 수 있어요.',
      ],
    ),
    _Block(
      heading: '경영 통계 보기',
      steps: [
        '설정 → [경영 통계]. 권한이 있는 계정에만 이 칸이 보여요.',
        '위쪽에서 기간을 고르세요: 이번 달 · 지난달 · 최근 3개월 · 올해 · 직접 선택.',
        '전체 요약 → 진료과별 비교 막대 → 진료과별 상세 → 월별 추이 → 요일·시간대별 내원 → 지금 상태 순서로 보여요.',
      ],
    ),
    _Block(
      heading: '숫자 읽는 법',
      items: [
        '초진 = 환자의 첫 내원(1회차), 재진 = 2회차 이후 내원. 회차는 취소·노쇼를 빼고 셉니다.',
        '재진율 = 기간 안에 초진한 환자 중 그 뒤 다시 온 환자 비율 (과별 환자를 붙잡는 힘).',
        '5회차 도달률 = 기간 안에 초진한 환자 중 5회차까지 온 비율 (치료 완주율).',
        '한약 비율 = 기간 안 내원 환자 중 그 기간에 한약을 시작한 환자 비율.',
        '노쇼율 · 1인당 내원 횟수 · 실환자수 · 신규 등록도 함께 보여요.',
        '최근 기간일수록 다시 올 시간이 부족해 재진율·5회차 도달률이 낮게 나올 수 있어요. 과끼리 비교할 땐 같은 기간으로 보세요.',
      ],
    ),
    _Block(
      heading: '권한 주기 (관리자)',
      text:
          '처음에는 master1 계정만 경영 통계를 볼 수 있어요. '
          'master1로 로그인 → 설정 → [관리자 설정] → "경영 통계 보기 권한"에서 직원 계정의 스위치를 켜면 그 계정도 볼 수 있어요. 끄면 바로 막혀요.',
    ),
  ]),
  const _Section(Icons.help_outline, '17. 자주 묻는 질문', [
    _Block(
      heading: '여러 사람이 같이 쓸 수 있나요?',
      text:
          '네. 접수 PC와 직원 휴대폰이 각자 직원 계정으로 로그인하면 같은 데이터를 봐요. '
          '한 곳에서 예약을 넣거나 [연락함]을 누르면 다른 기기에도 바로 반영돼요. 병원 밖에서도 인터넷만 되면 볼 수 있어요.\n'
          '인터넷이 끊기면 화면 위에 회색 안내가 뜨고 마지막으로 받은 내용을 보여줘요. 저장은 연결된 뒤에 해 주세요.\n'
          '로그아웃: 설정 → 맨 위 계정 칸의 [로그아웃]. 계정 추가·삭제는 원장님이 Supabase 관리 화면에서 해요.',
    ),
    _Block(
      heading: '새 버전으로 업데이트하면 데이터가 지워지나요?',
      text: '아니요. 새 APK를 덮어 설치하면 데이터는 그대로예요. 앱을 \'삭제\'하면 지워지니 주의하세요.',
    ),
    _Block(
      heading: '한약 환자인데 에너지바가 안 보여요.',
      text:
          '에너지바는 비급여한약 환자에게만 보여요. 건보첩약은 10일치씩 나가서 에너지바를 쓰지 않아요.\n'
          '비급여한약인데 안 보이면, 복약 기간 기능이 생기기 전에 시작한 환자라 기간이 비어 있는 거예요. '
          '환자 화면 → [일정 수정]에서 1·2·3개월을 고르면 나타나요. '
          '(예전 한약 환자는 모두 비급여로 들어가 있으니 건보첩약이면 종류도 바꿔 주세요)',
    ),
    _Block(
      heading: '[연락함]을 실수로 눌렀어요.',
      text: '그 환자는 이번 연락 기한에서는 처리된 것으로 봐요. 다음 예약·내원 기록을 넣으면 그 날짜 기준으로 다시 계산돼요.',
    ),
    _Block(
      heading: '알림이 안 와요.',
      items: [
        '휴대폰 설정에서 이 앱의 알림이 켜져 있는지 확인하세요.',
        '설정 탭 "정확한 시간에 알림 받기"를 허용하세요.',
        '배터리 설정을 \'제한 없음\'으로 바꾸세요.',
        '연락할 환자가 없는 날은 알림이 오지 않아요.',
      ],
    ),
    _Block(
      heading: '글자를 어떤 키보드로 입력하나요?',
      text: '휴대폰에 설정된 키보드를 그대로 써요. 천지인 · 두벌식 · 나랏글 모두 돼요. 전화번호 칸은 숫자 키패드가 떠요.',
    ),
  ]),
  _Section(Icons.history, '18. 업데이트 내역', [
    for (final (title, items) in _changelog)
      _Block(heading: title, items: items),
  ]),
];

/// 지금까지 추가된 기능 (최신이 위).
const _changelog = <(String, List<String>)>[
  (
    '진료과 · 경영 통계',
    [
      '예약 넣을 때 진료과(5개 과) 선택, 환자 이름 옆에 과 배지.',
      '경영 통계: 기간별 과별 초진·재진·재진율·한약 비율·5회차 도달률·노쇼율, 월별 추이, 요일·시간대별 내원.',
      '통계는 처음엔 master1만 보고, 관리자 설정에서 다른 계정에 권한을 줄 수 있어요.',
    ],
  ),
  (
    '접수 PC(윈도우) 버전',
    [
      '윈도우 PC용 프로그램. 같은 직원 계정으로 로그인해 휴대폰과 같은 데이터를 봐요.',
      'PC에서는 📞 버튼이 번호를 크게 보여주고 복사해 줘요. 아침 요약은 윈도우 알림으로 와요.',
    ],
  ),
  (
    '여러 기기 공유 (공유 서버)',
    [
      '접수 PC·직원 휴대폰이 직원 계정으로 로그인해 같은 데이터를 실시간으로 공유.',
      '데이터는 일본(도쿄) 서버에 저장, 로그인한 직원만 볼 수 있음.',
      '인터넷이 끊겨도 마지막 내용은 보임. 예전 휴대폰 데이터 서버로 옮기기.',
    ],
  ),
  ('건보첩약 에너지바 없앰', ['건보첩약은 10일치씩 나가서 복약 기간·에너지바를 쓰지 않아요. 비급여한약만 표시.']),
  ('초진 표시', ['오늘 예약 명단에서 초진 환자는 파란 줄 + [초진] 배지, 재진은 "N회차".']),
  (
    '복약 기간 · 에너지바',
    [
      '한약 처방 때 1·2·3개월 복약 기간 선택.',
      '이름 옆 에너지바 (한 달 = 한 묶음, 1칸 = 15일). 일정 미루기만큼 다시 채워짐.',
    ],
  ),
  ('5회차 표시', ['5회차 예약·내원에 반짝이는 분홍 ⑤.']),
  ('이 날 메모', ['일정 추가·수정 창에 그 날 메모. 기록 아래 노란 칸, 달력 명단에 📝.']),
  ('한약 종류 구분', ['건보첩약(10일, 🌿 건, 청록) / 비급여한약(15·25일, 🌿 비급, 보라).']),
  (
    '예약 시간 · 반짝이는 이름',
    ['예약 시간 입력, 달력 명단 시간 순 정렬.', '연락해야 할 환자 이름이 금색/빨강으로 반짝임.'],
  ),
  (
    '알림 개선',
    [
      '아침 요약 알림 1회, 알림을 누르면 연락 탭으로.',
      '알림 시간 설정, 처리할 때까지 최대 7일 반복, 놓친 연락 보관함.',
      '앱 사용법 페이지.',
    ],
  ),
  ('백업 · 아이콘', ['백업 보내기·저장·복원, 백업 안내. 새 앱 아이콘.']),
  ('한약 복약 관리', ['복약 시작, 확인 전화 알림(최대 10개), 일정 미루기, 확인 완료, 복약 종료.']),
  ('달력 첫 화면 · 특이사항 메모', ['첫 화면을 달력으로, 날짜별 인원 표시, 환자 특이사항 메모.']),
  ('첫 버전', ['환자 등록, 예약·내원 기록, 달력.', '마지막 방문 후 2주간 재예약이 없으면 연락 필요 알림.']),
];
