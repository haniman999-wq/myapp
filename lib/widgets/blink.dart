import 'package:flutter/material.dart';

/// 자식 위젯을 은은하게 깜빡이게 합니다. (연락 필요 · 복약 확인 표시용)
///
/// 완전히 사라지지 않고 [minOpacity] 까지만 흐려졌다가 돌아옵니다.
class Blink extends StatefulWidget {
  const Blink({
    super.key,
    required this.child,
    this.enabled = true,
    this.minOpacity = 0.3,
    this.period = const Duration(milliseconds: 900),
  });

  final Widget child;

  /// false 면 깜빡이지 않고 그대로 보여줍니다.
  final bool enabled;
  final double minOpacity;

  /// 흐려졌다가 돌아오는 데 걸리는 시간의 절반.
  final Duration period;

  @override
  State<Blink> createState() => _BlinkState();
}

class _BlinkState extends State<Blink> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.period,
  );
  late final Animation<double> _opacity = Tween<double>(
    begin: 1,
    end: widget.minOpacity,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

  @override
  void initState() {
    super.initState();
    _sync();
  }

  @override
  void didUpdateWidget(Blink oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.enabled != widget.enabled) _sync();
  }

  void _sync() {
    if (widget.enabled) {
      _controller.repeat(reverse: true);
    } else {
      _controller
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;
    return FadeTransition(opacity: _opacity, child: widget.child);
  }
}
