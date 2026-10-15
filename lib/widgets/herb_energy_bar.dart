import 'package:flutter/material.dart';

import '../models/customer.dart';
import '../models/herb_alert.dart';

/// 한약 복약 에너지바.
///
/// 최대 3개월(90일)을 6칸으로 나눠, 한 칸 = 15일입니다.
/// - 처방한 기간만큼 칸이 있고 (1개월 2칸, 2개월 4칸, 3개월 6칸),
///   남은 복약 일수만큼 칸이 채워져 있습니다.
/// - 15일이 지날 때마다 한 칸씩 줄어듭니다.
/// - 한 달(2칸)씩 테두리로 묶어 띄우고, 처방 기간 밖의 달은 흐린 테두리로 보여 3개월 기준을 알 수 있게 합니다.
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

    // 한 달(2칸)씩 테두리로 묶고 묶음 사이를 넓게 띄워, "몇 달 남았는지" 바로 보이게 합니다.
    const cellsPerMonth = 2;
    const months = kHerbBarCells ~/ cellsPerMonth;
    Widget cell(int i) => Container(
      width: cellWidth,
      height: cellHeight,
      margin: EdgeInsets.only(left: i % cellsPerMonth == 0 ? 0 : 1.5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(1.5),
        color: i < filled
            ? color
            : i < planCells
            ? Colors.grey.shade300
            : Colors.transparent,
      ),
    );

    final bar = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var m = 0; m < months; m++)
          Container(
            margin: EdgeInsets.only(left: m == 0 ? 0 : cellWidth * 0.6),
            padding: const EdgeInsets.all(1.5),
            decoration: BoxDecoration(
              // 처방 기간 밖의 달은 흐린 테두리로만
              border: Border.all(
                color: m * cellsPerMonth < planCells
                    ? Colors.grey.shade600
                    : Colors.grey.shade300,
                width: 1,
              ),
              borderRadius: BorderRadius.circular(3),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var c = 0; c < cellsPerMonth; c++)
                  cell(m * cellsPerMonth + c),
              ],
            ),
          ),
      ],
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
