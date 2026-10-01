// 앱 아이콘 원본(assets/icon/app_icon_source.webp)을 런처 아이콘용 PNG 로 다듬습니다.
//
//  1. 초록 둥근 사각형 바깥의 흰 여백을 잘라냅니다.
//  2. 남은 네 귀퉁이의 흰 부분을 가까운 초록색으로 채웁니다.
//     (안드로이드가 아이콘을 원·둥근사각형으로 잘라도 흰 모서리가 보이지 않게)
//  3. 1024x1024 정사각형 PNG(assets/icon/app_icon.png)로 저장합니다.
//
// 실행: dart run tool/prepare_icon.dart
// 그다음: dart run flutter_launcher_icons
import 'dart:collection';
import 'dart:io';

import 'package:image/image.dart' as img;

const _source = 'assets/icon/app_icon_source.webp';
const _output = 'assets/icon/app_icon.png';

/// 바탕(흰색·투명)으로 볼 픽셀인지.
bool _isBackground(img.Pixel p) {
  if (p.a < 128) return true;
  final r = p.r, g = p.g, b = p.b;
  final max = [r, g, b].reduce((a, c) => a > c ? a : c);
  final min = [r, g, b].reduce((a, c) => a < c ? a : c);
  // 밝고 채도가 낮으면 흰 여백(그림자·안티앨리어싱 포함)
  return min > 200 && max - min < 40;
}

void main() {
  final decoded = img.decodeImage(File(_source).readAsBytesSync());
  if (decoded == null) {
    stderr.writeln('이미지를 읽을 수 없어요: $_source');
    exit(1);
  }
  final src = decoded.convert(numChannels: 4);

  // 1. 흰 여백을 뺀 영역 찾기
  var left = src.width, top = src.height, right = 0, bottom = 0;
  for (final p in src) {
    if (_isBackground(p)) continue;
    if (p.x < left) left = p.x;
    if (p.x > right) right = p.x;
    if (p.y < top) top = p.y;
    if (p.y > bottom) bottom = p.y;
  }
  final size = (right - left + 1) > (bottom - top + 1)
      ? right - left + 1
      : bottom - top + 1;
  final cropped = img.copyCrop(src, x: left, y: top, width: size, height: size);

  // 2. 네 귀퉁이에서 흰 부분을 따라가며 그 귀퉁이 쪽 초록색으로 채우기
  final w = cropped.width, h = cropped.height;
  final inset = (w * 0.08).round();
  final corners = [
    (0, 0, inset, inset),
    (w - 1, 0, w - 1 - inset, inset),
    (0, h - 1, inset, h - 1 - inset),
    (w - 1, h - 1, w - 1 - inset, h - 1 - inset),
  ];
  final visited = List.filled(w * h, false);
  for (final (cx, cy, sx, sy) in corners) {
    final fill = cropped.getPixel(sx, sy);
    final color = img.ColorRgba8(
      fill.r.toInt(),
      fill.g.toInt(),
      fill.b.toInt(),
      255,
    );
    final queue = Queue<(int, int)>()..add((cx, cy));
    while (queue.isNotEmpty) {
      final (x, y) = queue.removeFirst();
      if (x < 0 || y < 0 || x >= w || y >= h) continue;
      final i = y * w + x;
      if (visited[i]) continue;
      visited[i] = true;
      if (!_isBackground(cropped.getPixel(x, y))) continue;
      cropped.setPixel(x, y, color);
      queue
        ..add((x + 1, y))
        ..add((x - 1, y))
        ..add((x, y + 1))
        ..add((x, y - 1));
    }
  }

  // 3. 1024 정사각형으로 저장
  final out = img.copyResize(
    cropped,
    width: 1024,
    height: 1024,
    interpolation: img.Interpolation.cubic,
  );
  File(_output).writeAsBytesSync(img.encodePng(out));

  final edge = out.getPixel(20, 512);
  stdout.writeln(
    '저장: $_output (원본 ${src.width}x${src.height} → 잘라낸 영역 ${size}px, '
    '가장자리 색 #${_hex(edge.r)}${_hex(edge.g)}${_hex(edge.b)})',
  );
}

String _hex(num v) => v.toInt().toRadixString(16).padLeft(2, '0');
