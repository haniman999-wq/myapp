// 앱 사용법 화면에 넣을 캡처 이미지를 만듭니다.
//
// 에뮬레이터에서 찍은 원본 캡처(1080x2400 PNG)가 들어 있는 폴더를 넘기면
// 필요한 부분만 잘라 가로 540px JPG 로 줄여 assets/help/ 에 저장합니다.
//
// 실행: dart run tool/make_help_images.dart <원본 캡처 폴더>
import 'dart:io';

import 'package:image/image.dart' as img;

/// 저장 이름 → (원본 파일, 잘라낼 세로 범위 top~bottom, 가로 범위 left~right)
/// 좌표는 1080x2400 원본 기준. 상태 표시줄(위 130px)은 빼고 자릅니다.
const _crops = <String, (String, int, int, int, int)>{
  'calendar': ('calendar', 130, 2330, 0, 1080),
  'calendar_today': ('calendar', 1600, 1980, 0, 1080),
  'patients': ('patients', 130, 2330, 0, 1080),
  'detail_herb': ('detail_kim_top', 130, 2330, 0, 1080),
  'detail_visits': ('detail_han', 130, 2330, 0, 1080),
  'sheet': ('sheet_add', 1230, 2340, 0, 1080),
  'herb_plan': ('herb_plan', 130, 2330, 0, 1080),
  'postpone': ('postpone', 700, 1760, 100, 980),
  'contact': ('contact', 130, 1640, 0, 1080),
  'missed': ('missed', 130, 1240, 0, 1080),
  'search': ('search', 130, 1090, 0, 1080),
  'form': ('form', 130, 1470, 0, 1080),
  'settings_backup': ('settings_bottom', 130, 1140, 0, 1080),
  'settings_notify': ('settings_bottom', 1180, 1930, 0, 1080),
  'settings_help': ('settings_top', 330, 930, 0, 1080),
};

void main(List<String> args) {
  if (args.isEmpty) {
    stderr.writeln('사용법: dart run tool/make_help_images.dart <원본 캡처 폴더>');
    exit(1);
  }
  final src = args.first;
  final out = Directory('assets/help')..createSync(recursive: true);

  for (final MapEntry(key: name, value: (file, top, bottom, left, right))
      in _crops.entries) {
    final path = '$src/$file.png';
    final decoded = img.decodePng(File(path).readAsBytesSync());
    if (decoded == null) {
      stderr.writeln('읽을 수 없어요: $path');
      continue;
    }
    final cropped = img.copyCrop(
      decoded,
      x: left,
      y: top,
      width: right - left,
      height: bottom - top,
    );
    final resized = img.copyResize(
      cropped,
      width: ((right - left) / 2).round(),
      interpolation: img.Interpolation.average,
    );
    final dest = '${out.path}/$name.jpg';
    File(dest).writeAsBytesSync(img.encodeJpg(resized, quality: 82));
    stdout.writeln('$dest  ${resized.width}x${resized.height}');
  }
}
