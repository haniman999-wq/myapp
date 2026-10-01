import 'package:flutter/material.dart';

import '../models/customer.dart';
import '../theme.dart';

/// 고객 이름. 한약 복용 환자는 보라색 · 아주 굵게 + '🌿 한약' 배지로 확실히 구분합니다.
class CustomerName extends StatelessWidget {
  const CustomerName({
    super.key,
    required this.customer,
    this.fontSize,
    this.color,
    this.strike = false,
  });

  final Customer customer;
  final double? fontSize;

  /// 한약 환자가 아닐 때의 이름 색. (예: 연락 필요 → 빨강)
  final Color? color;

  /// 취소된 예약 등에 취소선.
  final bool strike;

  @override
  Widget build(BuildContext context) {
    final herbal = customer.isHerbal;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Text(
            customer.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: fontSize,
              color: herbal ? kHerbPurple : color,
              fontWeight: herbal ? FontWeight.w900 : FontWeight.bold,
              decoration: strike ? TextDecoration.lineThrough : null,
            ),
          ),
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
