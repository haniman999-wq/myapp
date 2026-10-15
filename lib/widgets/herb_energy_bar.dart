import 'package:flutter/material.dart';

import '../models/customer.dart';
import '../models/herb_alert.dart';

/// 한약 복약 에너지바.
///
/// 최대 3개월(90일)을 6칸으로 나눠, 한 칸 = 15일입니다.
/// - 처방한 기간만큼 칸이 있고 (1개월 2칸, 2개월 4칸, 3개월 6칸),
///   남은 복약 일수만큼 칸이 채워져 있습니다.
/// - 15일이 지날 때마다 한 칸씩 줄어듭니다.
/// - 처방 기간 밖의 칸은 흐린 점선 칸으로 보여 3개월 기준을 알 수 있게 합니다.
/// - 일정 미루기로 시작일이 뒤로 가면 그만큼 다시 채워집니다.
class HerbEnergyBar extends StatelessWidget {
  const HerbEnergyBar({
    super.key,
    required this.customer,
    this.cellWidth = 7,
    this.cellHeight = 12,
    this.showDays = false,
  });

  final Customer customer;
  final double cellWidth;
  final double cellHeight;

  /// 막대 옆에 '남은 45일' 글자도 보여줄지.
  final bool showDays;

  /// 남은 일수 → 채워진 칸 수. (90일 남으면 6칸, 75일 남으면 5칸 …)
  static int filledCells(int remainingDays) =>
      (remainingDays / kHerbBarCellDays).ceil().clamp(0, kHerbBarCells);

  /// 남은 비율에 따라 초록 → 주황 → 빨강.
  static Color colorFor(double ratio) {
    if (ratio > 0.5) return const Color(0xFF43A047);
    if (ratio > 0.2) return const Color(0xFFFFA000);
    return const Color(0xFFE53935);
  }

  @override
  Widget build(BuildContext context) {
    final total = customer.herbDays;
    final remaining = customer.herbRemainingDays;
    if (total == null || remaining == null) return const SizedBox.shrink();

    final planCells = (total / kHerbBarCellDays).ceil().clamp(1, kHerbBarCells);
    final filled = filledCells(remaining);
    final color = colorFor(remaining / total);

    final bar = Container(
      padding: const EdgeInsets.all(1.5),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade500, width: 1),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < kHerbBarCells; i++)
            Container(
              width: cellWidth,
              height: cellHeight,
              margin: EdgeInsets.only(left: i == 0 ? 0 : 1.5),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(1.5),
                color: i < filled
                    ? color
                    : i < planCells
                    ? Colors.grey.shade300
                    : Colors.transparent,
                border: i >= planCells
                    ? Border.all(color: Colors.grey.shade300, width: 0.8)
                    : null,
              ),
            ),
        ],
      ),
    );

    final tooltip = remaining == 0
        ? '복약 기간 끝 (${herbDurationLabel(total)})'
        : '남은 복약 $remaining일 / ${herbDurationLabel(total)}';

    return Tooltip(
      message: tooltip,
      child: showDays
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                bar,
                const SizedBox(width: 6),
                Text(
                  remaining == 0 ? '복약 기간 끝' : '남은 $remaining일',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            )
          : bar,
    );
  }
}
