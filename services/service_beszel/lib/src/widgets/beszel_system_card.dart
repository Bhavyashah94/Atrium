import 'package:core_models/core_models.dart';
import 'package:core_ui/core_ui.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../beszel_providers.dart';
import '../models/beszel_stats.dart';
import '../models/beszel_system.dart';

class BeszelSystemCard extends ConsumerWidget {
  const BeszelSystemCard({
    required this.instance,
    required this.system,
    super.key,
  });

  final Instance instance;
  final BeszelSystem system;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final args = (instance: instance, systemId: system.id, chartTime: ChartTime.hour1);
    final statsAsync = ref.watch(beszelSystemStatsProvider(args));

    final bool isUp = system.status == 'up';
    final colorScheme = Theme.of(context).colorScheme;

    final card = Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: Insets.md),
      shape: RoundedRectangleBorder(
        borderRadius: Radii.card,
        side: BorderSide(
          color: colorScheme.outlineVariant,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(Insets.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  isUp ? Icons.check_circle : Icons.error,
                  color: isUp ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.error,
                  size: 20,
                ),
                const SizedBox(width: Insets.sm),
                Expanded(
                  child: Text(
                    system.name,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Text(
                  system.host,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: Insets.md),
            statsAsync.when(
              data: (statsList) {
                if (statsList.isEmpty) {
                  return const Center(child: Text('No historical data'));
                }
                final latest = statsList.first;
                
                return GridView.count(
                  crossAxisCount: 3,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: 1.7,
                  mainAxisSpacing: Insets.sm,
                  crossAxisSpacing: Insets.sm,
                  children: [
                    _buildTextStat(context, 'CPU', '${latest.cpuUsage.toStringAsFixed(1)}%', Icons.memory),
                    _buildTextStat(context, 'Memory', '${latest.memoryUsage.toStringAsFixed(1)}%', Icons.storage),
                    _buildTextStat(context, 'Disk', '${latest.diskUsage.toStringAsFixed(1)}%', Icons.pie_chart),
                    if (system.info['g'] != null || latest.gpuUsage >= 0)
                      _buildTextStat(context, 'GPU', '${(latest.gpuUsage >= 0 ? latest.gpuUsage : (system.info['g'] is num ? (system.info['g'] as num).toDouble() : 0.0)).toStringAsFixed(1)}%', Icons.developer_board),
                    _buildTextStat(context, 'Load Avg', latest.loadAverage1m.toStringAsFixed(2), Icons.hourglass_empty),
                    _buildTextStat(context, 'Net', _formatNetworkTraffic(latest.networkSent + latest.networkRecv), Icons.network_check),
                    if (latest.temperature > 0)
                      _buildTextStat(context, 'Temp', '${latest.temperature.toStringAsFixed(1)}°C', Icons.thermostat),
                    if (system.info['bat'] != null && (system.info['bat'] as List).isNotEmpty)
                      _buildTextStat(context, 'Bat', '${((system.info['bat'] as List)[0] as num).toStringAsFixed(1)}%', Icons.battery_full),
                    if (system.info['sv'] != null && (system.info['sv'] as List).isNotEmpty)
                      _buildTextStat(context, 'Services', '${(system.info['sv'] as List)[0]}', Icons.miscellaneous_services),
                    if (system.info['u'] != null)
                      _buildTextStat(context, 'Uptime', _formatUptime((system.info['u'] as num).toInt()), Icons.timer),
                  ],
                );
              },
              loading: () => const SizedBox(
                height: 100,
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, st) => Text('Error: $e'),
            ),
          ],
        ),
      ),
    );

    return card;
  }

  Widget _buildTextStat(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(Insets.sm),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: Radii.card,
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 4),
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }

  String _formatNetworkTraffic(double? bytesPerSec) {
    if (bytesPerSec == null || bytesPerSec == 0) return '0.0 KB/s';
    if (bytesPerSec < 1024) return '${bytesPerSec.toStringAsFixed(1)} B/s';
    final kb = bytesPerSec / 1024;
    if (kb < 1024) return '${kb.toStringAsFixed(1)} KB/s';
    final mb = kb / 1024;
    if (mb < 1024) return '${mb.toStringAsFixed(1)} MB/s';
    final gb = mb / 1024;
    return '${gb.toStringAsFixed(1)} GB/s';
  }

  String _formatUptime(int seconds) {
    if (seconds < 60) return '${seconds}s';
    final minutes = seconds ~/ 60;
    if (minutes < 60) return '${minutes}m';
    final hours = minutes ~/ 60;
    if (hours < 24) return '${hours}h ${minutes % 60}m';
    final days = hours ~/ 24;
    return '${days}d ${hours % 24}h';
  }

  static Widget buildChart(
    List<BeszelStats> statsList,
    double Function(BeszelStats) selector,
    Color startColor,
    Color endColor, {
    double Function(BeszelStats)? secondarySelector,
    Color? secondaryStartColor,
    Color? secondaryEndColor,
    bool showLabels = false,
    ChartTime? chartTime,
    double? maxY,
    String tooltipSuffix = '%',
  }) {
    final spots = <FlSpot>[];
    final secondarySpots = <FlSpot>[];
    double minX = double.infinity;
    double maxX = double.negativeInfinity;
    double actualMaxY = double.negativeInfinity;

    for (int i = 0; i < statsList.length; i++) {
      final stat = statsList[i];
      final double xValue = stat.created != null 
          ? stat.created!.millisecondsSinceEpoch.toDouble() 
          : i.toDouble();
          
      if (xValue < minX) minX = xValue;
      if (xValue > maxX) maxX = xValue;
      
      final yValue = selector(stat);
      if (yValue > actualMaxY) actualMaxY = yValue;
      spots.add(FlSpot(xValue, yValue));

      if (secondarySelector != null) {
        final secondaryYValue = secondarySelector(stat);
        if (secondaryYValue > actualMaxY) actualMaxY = secondaryYValue;
        secondarySpots.add(FlSpot(xValue, secondaryYValue));
      }
    }

    if (minX == double.infinity) minX = 0.0;
    if (maxX == double.negativeInfinity) maxX = 1.0;
    if (minX == maxX) maxX += 1.0;
    if (actualMaxY == double.negativeInfinity) actualMaxY = 0.0;

    final resolvedMaxY = maxY ?? (actualMaxY > 0 ? actualMaxY * 1.2 : 10);
    final intervalY = resolvedMaxY > 0 ? resolvedMaxY / 4 : 1.0;
    final intervalX = (maxX > minX) ? (maxX - minX) / 4 : 1.0;

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          horizontalInterval: intervalY,
          getDrawingHorizontalLine: (value) => FlLine(
            color: Colors.grey.withValues(alpha: 0.2),
            strokeWidth: 1,
          ),
          getDrawingVerticalLine: (value) => FlLine(
            color: Colors.grey.withValues(alpha: 0.2),
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          show: showLabels,
          topTitles: const AxisTitles(),
          rightTitles: const AxisTitles(),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: showLabels,
              reservedSize: 30,
              interval: intervalX,
              getTitlesWidget: (value, meta) {
                if (value == minX || value == maxX) {
                  return const SizedBox();
                }
                
                final date = DateTime.fromMillisecondsSinceEpoch(value.toInt());
                String label;
                if (chartTime == ChartTime.week1 || chartTime == ChartTime.month1) {
                  label = '${date.month}/${date.day}';
                } else {
                  label = '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
                }
                
                return SideTitleWidget(
                  meta: meta,
                  fitInside: SideTitleFitInsideData.fromTitleMeta(meta, distanceFromEdge: 0),
                  child: Text(
                    label,
                    style: const TextStyle(fontSize: 10),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: showLabels,
              reservedSize: 40,
              interval: intervalY,
              getTitlesWidget: (value, meta) {
                return SideTitleWidget(
                  meta: meta,
                  child: Text(
                    '${value.toInt()}',
                    style: const TextStyle(fontSize: 10),
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        minX: minX,
        maxX: maxX,
        minY: 0,
        maxY: resolvedMaxY,
        lineTouchData: LineTouchData(
          enabled: showLabels,
          touchTooltipData: LineTouchTooltipData(
            fitInsideHorizontally: true,
            fitInsideVertically: true,
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((touchedSpot) {
                final isFirst = touchedSpots.first == touchedSpot;
                final date = DateTime.fromMillisecondsSinceEpoch(touchedSpot.x.toInt());
                final timeStr = '${date.month}/${date.day} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
                return LineTooltipItem(
                  '${isFirst ? '$timeStr\n' : ''}${touchedSpot.y.toStringAsFixed(1)}$tooltipSuffix',
                  TextStyle(color: touchedSpot.bar.gradient?.colors.first ?? Colors.white, fontWeight: FontWeight.bold),
                );
              }).toList();
            },
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            gradient: LinearGradient(
              colors: [startColor, endColor],
            ),
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  startColor.withValues(alpha: 0.3),
                  endColor.withValues(alpha: 0.0),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          if (secondarySelector != null && secondarySpots.isNotEmpty && secondaryStartColor != null && secondaryEndColor != null)
            LineChartBarData(
              spots: secondarySpots,
              isCurved: true,
              gradient: LinearGradient(
                colors: [secondaryStartColor, secondaryEndColor],
              ),
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    secondaryStartColor.withValues(alpha: 0.3),
                    secondaryEndColor.withValues(alpha: 0.0),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
