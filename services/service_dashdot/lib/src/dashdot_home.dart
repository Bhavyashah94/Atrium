import 'package:core_models/core_models.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:progress_indicator_m3e/progress_indicator_m3e.dart';

import 'dashdot_history_providers.dart';
import 'dashdot_providers.dart';
import 'widgets/dashdot_chart.dart';

class DashdotHome extends ConsumerWidget {
  const DashdotHome({required this.instance, super.key});
  final Instance instance;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          const TabBar(
            tabs: [
              Tab(text: 'Live Metrics'),
              Tab(text: 'System Info'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildMetricsTab(context, ref),
                _buildInfoTab(context, ref),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTab(BuildContext context, WidgetRef ref) {
    final infoAsync = ref.watch(dashdotInfoProvider(instance));
    return infoAsync.when(
      data: (info) {
        if (info == null) {
          return const Center(child: Text('Failed to load Dashdot info.'));
        }

        final cpu = info.cpu;
        final ram = info.ram;
        final storageList = info.storage ?? [];
        final network = info.network;

        return EasyRefresh(
          header: const ClassicHeader(
            dragText: 'Pull to refresh',
            armedText: 'Release ready',
            readyText: 'Refreshing...',
            processingText: 'Refreshing...',
            processedText: 'Succeeded',
            noMoreText: 'No more',
            failedText: 'Failed',
            messageText: 'Last updated at %T',
          ),
          onRefresh: () async {
            ref.invalidate(dashdotInfoProvider(instance));
            ref.invalidate(dashdotConfigProvider(instance));
          },
          child: ListView(
            padding: Insets.page,
            children: [
              _InfoBox(
                title: 'CPU',
                subtitle: cpu?.cpuBrand ?? 'Unknown',
                details: '${cpu?.cores ?? '?'} Cores / ${cpu?.threads ?? '?'} Threads\n${cpu?.freq ?? '?'} GHz',
                icon: Icons.memory,
              ),
              const SizedBox(height: Insets.md),
              _InfoBox(
                title: 'RAM',
                subtitle: ram != null && ram.totalCapacity != null ? '${ram.totalCapacity} GB' : 'Unknown',
                details: (ram?.sticks?.isNotEmpty ?? false)
                    ? '${ram!.sticks!.first.type ?? ''} @ ${ram.sticks!.first.frequency ?? '?'} MHz'
                    : '',
                icon: Icons.developer_board,
              ),
              const SizedBox(height: Insets.md),
              _InfoBox(
                title: 'Network',
                subtitle: network?.type ?? 'Unknown',
                details: 'Speed: ${network?.interfaceSpeed ?? '?'} Mbps' +
                    (network != null && ((network.downMBps ?? 0) > 0 || (network.upMBps ?? 0) > 0)
                        ? '\n⬇ ${network.downMBps} Mbps  ⬆ ${network.upMBps} Mbps' 
                        : ''),
                icon: Icons.network_check,
              ),
              const SizedBox(height: Insets.md),
              if (storageList.isNotEmpty)
                _InfoBox(
                  title: 'Storage',
                  subtitle: storageList.first.type ?? 'Disk',
                  details: '${storageList.first.capacity} GB',
                  icon: Icons.storage,
                )
              else
                const _InfoBox(
                  title: 'Storage',
                  subtitle: 'Unknown',
                  details: '',
                  icon: Icons.storage,
                ),
              if (info.gpu != null && info.gpu!.isNotEmpty) ...[
                const SizedBox(height: Insets.md),
                ...info.gpu!.map((g) => Padding(
                      padding: const EdgeInsets.only(bottom: Insets.md),
                      child: _InfoBox(
                        title: 'GPU',
                        subtitle: g['name'] ?? 'GPU',
                        details: '${g['memory']} MB',
                        icon: Icons.monitor,
                      ),
                    )),
              ],
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicatorM3E()),
      error: (e, st) => Center(child: Text('Error: $e')),
    );
  }

  Widget _buildMetricsTab(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: const EdgeInsets.all(Insets.md),
      children: [
        DashdotCpuCard(instance: instance),
        const SizedBox(height: Insets.md),
        _buildRamLoadCard(context, ref),
        const SizedBox(height: Insets.md),
        _buildStorageLoadCard(context, ref),
        const SizedBox(height: Insets.md),
        _buildNetworkLoadCard(context, ref),
      ],
    );
  }

  Widget _buildRamLoadCard(BuildContext context, WidgetRef ref) {
    final history = ref.watch(dashdotRamHistoryProvider(instance));
    final currentLoad = history.values.isNotEmpty ? history.values.last : 0.0;
    
    return Consumer(builder: (context, ref, _) {
      final info = ref.read(dashdotInfoProvider(instance)).value;
      final num totalGb = (info?.ram?.totalCapacity as num?) ?? 0;
      final double pct = totalGb > 0 ? (currentLoad / totalGb * 100) : 0.0;
      
      return DashdotMetricCard(
        title: 'Memory',
        subtitle: '${pct.toStringAsFixed(0)}% in use',
        chart: DashdotLineChart(
          values: history.values,
          maxY: totalGb.toDouble(),
          lineColor: Colors.purple,
        ),
        details: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            DashdotSubMetric(label: 'In use', value: '${currentLoad.toStringAsFixed(1)} GB'),
            DashdotSubMetric(label: 'Available', value: '${(totalGb - currentLoad).clamp(0, totalGb).toStringAsFixed(1)} GB'),
            DashdotSubMetric(label: 'Speed', value: (info?.ram?.sticks?.isNotEmpty ?? false) ? '${info!.ram!.sticks!.first.frequency} MHz' : 'Unknown'),
          ],
        ),
      );
    });
  }

  Widget _buildStorageLoadCard(BuildContext context, WidgetRef ref) {
    final history = ref.watch(dashdotStorageHistoryProvider(instance));
    final currentLoad = history.values.isNotEmpty ? history.values.last : 0.0;
    
    return Consumer(builder: (context, ref, _) {
      final info = ref.read(dashdotInfoProvider(instance)).value;
      double totalGb = 0;
      for (var disk in info?.storage ?? []) {
        totalGb += (disk.capacity as num?)?.toDouble() ?? 0;
      }
      final double pct = totalGb > 0 ? (currentLoad / totalGb * 100) : 0.0;
      
      return DashdotMetricCard(
        title: 'Disk',
        subtitle: '${pct.toStringAsFixed(0)}% used',
        chart: DashdotLineChart(
          values: history.values,
          maxY: totalGb,
          lineColor: Colors.green,
        ),
        details: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            DashdotSubMetric(label: 'Capacity', value: '${totalGb.toStringAsFixed(1)} GB'),
            DashdotSubMetric(label: 'Used', value: '${currentLoad.toStringAsFixed(1)} GB'),
            DashdotSubMetric(label: 'Free', value: '${(totalGb - currentLoad).clamp(0, totalGb).toStringAsFixed(1)} GB'),
          ],
        ),
      );
    });
  }

  Widget _buildNetworkLoadCard(BuildContext context, WidgetRef ref) {
    final history = ref.watch(dashdotNetworkHistoryProvider(instance));
    final currentDown = history.down.isNotEmpty ? history.down.last : 0.0;
    final currentUp = history.up.isNotEmpty ? history.up.last : 0.0;
    
    return Consumer(builder: (context, ref, _) {
      final info = ref.read(dashdotInfoProvider(instance)).value;
      final num interfaceSpeedMbps = info?.network?.interfaceSpeed as num? ?? 0;
      final num interfaceSpeedMBps = interfaceSpeedMbps / 8;
      
      return DashdotMetricCard(
        title: 'Network',
        subtitle: 'S: ${currentDown.toStringAsFixed(1)} R: ${currentUp.toStringAsFixed(1)} Mbps',
        chart: DashdotLineChart(
          values: history.down, // R/down
          secondaryValues: history.up, // S/up
          maxY: interfaceSpeedMBps.toDouble() > 0 ? interfaceSpeedMBps.toDouble() : 100.0,
          lineColor: Colors.orange, // Receive
          secondaryLineColor: Colors.orange.withOpacity(0.5), // Send
        ),
        details: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            DashdotSubMetric(label: 'Send', value: '${currentUp.toStringAsFixed(1)} MB/s', color: Colors.orange.withOpacity(0.5)),
            DashdotSubMetric(label: 'Receive', value: '${currentDown.toStringAsFixed(1)} MB/s', color: Colors.orange),
            DashdotSubMetric(label: 'Interface', value: '${interfaceSpeedMbps.toStringAsFixed(0)} Mbps'),
          ],
        ),
      );
    });
  }

}

class DashdotMetricCard extends StatelessWidget {
  const DashdotMetricCard({
    required this.title,
    required this.subtitle,
    required this.chart,
    required this.details,
    this.onTap,
    super.key,
  });

  final String title;
  final String subtitle;
  final Widget chart;
  final Widget details;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Insets.md),
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.5)),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(Insets.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                  Text(subtitle, style: Theme.of(context).textTheme.titleLarge),
                ],
              ),
              const SizedBox(height: Insets.md),
              SizedBox(
                height: 120,
                width: double.infinity,
                child: chart,
              ),
              const SizedBox(height: Insets.md),
              details,
            ],
          ),
        ),
      ),
    );
  }
}

class DashdotSubMetric extends StatelessWidget {
  const DashdotSubMetric({
    required this.label,
    required this.value,
    this.color,
    super.key,
  });

  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
        Text(value, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: color)),
      ],
    );
  }
}

class DashdotCpuCard extends ConsumerStatefulWidget {
  const DashdotCpuCard({required this.instance, super.key});
  final Instance instance;

  @override
  ConsumerState<DashdotCpuCard> createState() => _DashdotCpuCardState();
}

class _DashdotCpuCardState extends ConsumerState<DashdotCpuCard> {
  bool _showLogicalCores = false;

  @override
  Widget build(BuildContext context) {
    final historyState = ref.watch(dashdotCpuHistoryProvider(widget.instance));
    final currentLoad = historyState.overall.values.isNotEmpty ? historyState.overall.values.last : 0.0;
    
    Widget chart;
    if (_showLogicalCores && historyState.cores.isNotEmpty) {
      chart = GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 80,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 1.0,
        ),
        itemCount: historyState.cores.length,
        itemBuilder: (context, index) {
          final coreHistory = historyState.cores[index];
          return Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.blue.withOpacity(0.2)),
            ),
            child: DashdotLineChart(
              values: coreHistory.values,
              maxY: 100,
              lineColor: Colors.blue,
            ),
          );
        },
      );
    } else {
      chart = DashdotLineChart(
        values: historyState.overall.values,
        maxY: 100,
        lineColor: Colors.blue,
      );
    }

    return DashdotMetricCard(
      title: 'CPU',
      subtitle: '${currentLoad.toStringAsFixed(0)}% utilization',
      chart: chart,
      onTap: () {
        setState(() {
          _showLogicalCores = !_showLogicalCores;
        });
      },
      details: Consumer(builder: (context, ref, _) {
        final info = ref.read(dashdotInfoProvider(widget.instance)).value;
        final cpu = info?.cpu;
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            DashdotSubMetric(label: 'Utilization', value: '${currentLoad.toStringAsFixed(1)}%'),
            DashdotSubMetric(label: 'Speed', value: '${cpu?.freq ?? '?'} GHz'),
            DashdotSubMetric(label: 'Cores', value: '${cpu?.cores ?? '?'}'),
            DashdotSubMetric(label: 'Logical', value: '${cpu?.threads ?? '?'}'),
          ],
        );
      }),
    );
  }
}

class _InfoBox extends StatelessWidget {
  const _InfoBox({
    required this.title,
    required this.subtitle,
    required this.details,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final String details;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Insets.sm),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(Insets.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: Insets.xs),
              Text(
                title,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: Insets.xs),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          if (details.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              details,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    height: 1.2,
                  ),
            ),
          ],
        ],
      ),
    );
  }
}
