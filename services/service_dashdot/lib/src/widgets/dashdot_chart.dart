import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class DashdotLineChart extends StatelessWidget {
  const DashdotLineChart({
    required this.values,
    required this.maxY,
    required this.lineColor,
    this.secondaryValues,
    this.secondaryLineColor,
    super.key,
  });

  final List<double> values;
  final double maxY;
  final Color lineColor;
  final List<double>? secondaryValues;
  final Color? secondaryLineColor;

  @override
  Widget build(BuildContext context) {
    return LineChart(
      LineChartData(
        minX: 0,
        maxX: 59,
        minY: 0,
        maxY: maxY == 0 ? 1 : maxY,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          horizontalInterval: maxY > 0 ? maxY / 4 : 1,
          verticalInterval: 10,
          getDrawingHorizontalLine: (value) => FlLine(
            color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.3),
            strokeWidth: 1,
          ),
          getDrawingVerticalLine: (value) => FlLine(
            color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.3),
            strokeWidth: 1,
          ),
        ),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.5)),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: List.generate(
              values.length,
              (index) => FlSpot(index.toDouble(), values[index]),
            ),
            isCurved: false,
            color: lineColor,
            barWidth: 1.5,
            isStrokeCapRound: false,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: lineColor.withOpacity(0.15),
            ),
          ),
          if (secondaryValues != null && secondaryLineColor != null)
            LineChartBarData(
              spots: List.generate(
                secondaryValues!.length,
                (index) => FlSpot(index.toDouble(), secondaryValues![index]),
              ),
              isCurved: false,
              color: secondaryLineColor!,
              barWidth: 1.5,
              isStrokeCapRound: false,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: secondaryLineColor!.withOpacity(0.15),
              ),
            ),
        ],
      ),
      duration: Duration.zero,
    );
  }
}
