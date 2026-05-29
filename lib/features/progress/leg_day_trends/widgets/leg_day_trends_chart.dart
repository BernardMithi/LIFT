import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:lift/features/progress/leg_day_trends/leg_day_trends_models.dart';

class LegDayTrendChart extends StatelessWidget {
  const LegDayTrendChart({
    super.key,
    required this.series,
    required this.metric,
    required this.accentColor,
  });

  final MetricTrendSeries series;
  final LegDayTrendMetric metric;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final points = series.points;
    if (points.isEmpty) {
      return const SizedBox.shrink();
    }

    final spots = <FlSpot>[
      for (var index = 0; index < points.length; index += 1)
        FlSpot(index.toDouble(), points[index].value),
    ];

    final values = points.map((point) => point.value).toList(growable: false);
    final minValue = values.reduce(math.min);
    final maxValue = values.reduce(math.max);
    final span = maxValue - minValue;
    final padding =
        (span == 0 ? math.max(1.0, maxValue * 0.12) : span * 0.18).toDouble();
    final minY = math.max(0.0, minValue - padding).toDouble();
    final maxY = (maxValue + padding).toDouble();
    final yInterval = _niceInterval((maxY - minY) / 4);
    final xLabelStep = math.max(1, (points.length / 4).ceil());

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: (points.length - 1).toDouble(),
        minY: minY,
        maxY: maxY,
        borderData: FlBorderData(show: false),
        lineTouchData: LineTouchData(
          handleBuiltInTouches: true,
          touchTooltipData: LineTouchTooltipData(
            fitInsideHorizontally: true,
            fitInsideVertically: true,
            tooltipBorderRadius: BorderRadius.circular(14),
            tooltipPadding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 8,
            ),
            getTooltipColor: (_) => Colors.white.withValues(alpha: 0.96),
            getTooltipItems:
                (spots) => spots
                    .map((spot) {
                      final point = points[spot.x.toInt()];
                      return LineTooltipItem(
                        '${point.label}\n${_tooltipValue(spot.y)}',
                        const TextStyle(
                          color: Color(0xFF171717),
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          height: 1.35,
                        ),
                      );
                    })
                    .toList(growable: false),
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: yInterval,
          getDrawingHorizontalLine:
              (_) => FlLine(
                color: const Color(0xFF171717).withValues(alpha: 0.08),
                strokeWidth: 1,
              ),
        ),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 42,
              interval: yInterval,
              getTitlesWidget:
                  (value, meta) => SideTitleWidget(
                    meta: meta,
                    space: 10,
                    child: Text(
                      _axisValue(value),
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= points.length) {
                  return const SizedBox.shrink();
                }
                final isLast = index == points.length - 1;
                if (!isLast && index % xLabelStep != 0) {
                  return const SizedBox.shrink();
                }
                return SideTitleWidget(
                  meta: meta,
                  space: 10,
                  child: Text(
                    points[index].label,
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.24,
            preventCurveOverShooting: true,
            color: accentColor,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              checkToShowDot: (spot, _) => spot.x == spots.last.x,
              getDotPainter:
                  (_, __, ___, ____) => FlDotCirclePainter(
                    radius: 4.5,
                    color: accentColor,
                    strokeWidth: 2,
                    strokeColor: Colors.white,
                  ),
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  accentColor.withValues(alpha: 0.16),
                  accentColor.withValues(alpha: 0.02),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _axisValue(double value) {
    switch (metric) {
      case LegDayTrendMetric.volume:
        if (value >= 1000) {
          return '${(value / 1000).toStringAsFixed(1)}k';
        }
        return value.round().toString();
      case LegDayTrendMetric.reps:
        return value.round().toString();
      case LegDayTrendMetric.topSet:
        return '${value.round()}kg';
    }
  }

  String _tooltipValue(double value) {
    switch (metric) {
      case LegDayTrendMetric.volume:
        return '${value.toStringAsFixed(0)}kg volume';
      case LegDayTrendMetric.reps:
        return '${value.toStringAsFixed(0)} reps';
      case LegDayTrendMetric.topSet:
        return '${value.toStringAsFixed(0)}kg top set';
    }
  }

  double _niceInterval(double raw) {
    if (raw <= 0) return 1;
    final exponent =
        math.pow(10, (math.log(raw) / math.ln10).floor()).toDouble();
    final fraction = raw / exponent;
    final niceFraction =
        fraction <= 1
            ? 1
            : fraction <= 2
            ? 2
            : fraction <= 5
            ? 5
            : 10;
    return (niceFraction * exponent).toDouble();
  }
}
