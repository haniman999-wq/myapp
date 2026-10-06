import 'package:flutter/material.dart';

import '../models/customer.dart';
import '../models/customer_overview.dart';
import '../theme.dart';

/// 지금 연락해야 하는 환자면 이름을 빛나게 할 색. 아니면 null.
/// 복약 확인 → 금색, 재방문 연락 → 빨강.
Color? alertGlowOf(CustomerOverview? o) {
  if (o == null) return null;
  if (o.needsHerbCheck) return kGlowGold;
  if (o.revisitPending) return kNoShowRed;
  return null;
}

/// 환자 이름. 한약 복용 환자는 보라색 · 아주 굵게 + '🌿 한약' 배지로 확실히 구분합니다.
/// [glow] 가 있으면 (연락해야 하는 환자) 이름 둘레가 반짝반짝 빛납니다.
class CustomerName extends StatelessWidget {
  const CustomerName({
    super.key,
    required this.customer,
    this.fontSize,
    this.color,
    this.strike = false,
    this.glow,
  });

  final Customer customer;
  final double? fontSize;

  /// 한약 환자가 아닐 때의 이름 색. (예: 연락 필요 → 빨강)
  final Color? color;

  /// 취소된 예약 등에 취소선.
  final bool strike;

  /// 빛나게 할 색. [alertGlowOf] 로 정합니다.
  final Color? glow;

  @override
  Widget build(BuildContext context) {
    final herbal = customer.isHerbal;
    final glow = this.glow;
    final name = Text(
      customer.name,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: fontSize,
        color: herbal ? kHerbPurple : color,
        fontWeight: herbal ? FontWeight.w900 : FontWeight.bold,
        decoration: strike ? TextDecoration.lineThrough : null,
      ),
    );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: glow == null || strike
              ? name
              : _GlowingName(color: glow, child: name),
        ),
        if (herbal) ...[const SizedBox(width: 6), const HerbBadge()],
      ],
    );
  }
}

/// '🌿 한약' 배지.
class HerbBadge extends StatelessWidget {
  const HerbBadge({super.key, this.label = '한약'});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: kHerbPurple,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '🌿 $label',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

/// 이름 둘레를 반짝반짝 빛나게 하는 효과.
///
/// 색 배경이 숨쉬듯 밝아졌다 어두워지고, 테두리와 빛 번짐이 함께 커졌다 작아집니다.
class _GlowingName extends StatefulWidget {
  const _GlowingName({required this.color, required this.child});

  final Color color;
  final Widget child;

  @override
  State<_GlowingName> createState() => _GlowingNameState();
}

class _GlowingNameState extends State<_GlowingName>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 750),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.color;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = Curves.easeInOut.transform(_controller.value);
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
          decoration: BoxDecoration(
            color: c.withValues(alpha: 0.10 + 0.22 * t),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: c.withValues(alpha: 0.35 + 0.65 * t),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: c.withValues(alpha: 0.55 * t),
                blurRadius: 4 + 10 * t,
                spreadRadius: 1 * t,
              ),
            ],
          ),
          child: child,
        );
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.notifications_active, size: 14, color: c),
          const SizedBox(width: 3),
          Flexible(child: widget.child),
        ],
      ),
    );
  }
}
