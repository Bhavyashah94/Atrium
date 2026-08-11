import 'package:core_models/core_models.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../beszel_providers.dart';
import '../models/beszel_container.dart';
import '../models/beszel_stats.dart';
import '../models/beszel_system.dart';
import '../models/beszel_systemd_service.dart';
import '../widgets/beszel_system_card.dart';

class BeszelSystemDetailScreen extends ConsumerStatefulWidget {
  const BeszelSystemDetailScreen({
    required this.instance,
    required this.system,
    super.key,
  });

  final Instance instance;
  final BeszelSystem system;

  @override
  ConsumerState<BeszelSystemDetailScreen> createState() => _BeszelSystemDetailScreenState();
}

class _BeszelSystemDetailScreenState extends ConsumerState<BeszelSystemDetailScreen> {
  int _currentIndex = 0;

  String _getChartTimeLabel(ChartTime time) {
    switch (time) {
      case ChartTime.hour1: return '1h';
      case ChartTime.hour12: return '12h';
      case ChartTime.hour24: return '24h';
      case ChartTime.week1: return '1w';
      case ChartTime.month1: return '30d';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.system.name),
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildSystemStatsTab(ref),
          _buildContainerStatsTab(ref),
          _buildSystemdStatsTab(ref),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.analytics_outlined),
            selectedIcon: Icon(Icons.analytics),
            label: 'System Stats',
          ),
          NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon: Icon(Icons.inventory_2),
            label: 'Containers',
          ),
          NavigationDestination(
            icon: Icon(Icons.miscellaneous_services_outlined),
            selectedIcon: Icon(Icons.miscellaneous_services),
            label: 'Systemd',
          ),
        ],
      ),
    );
  }

  Widget _buildSystemStatsTab(WidgetRef ref) {
    final ChartTime chartTime = ref.watch(beszelChartTimeProvider);
    final args = (instance: widget.instance, systemId: widget.system.id, chartTime: chartTime);
    final statsAsync = ref.watch(beszelSystemStatsProvider(args));

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(Insets.md, Insets.md, Insets.md, 0),
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Calculate widths to emulate animated flex
                final availableWidth = constraints.maxWidth - (8.0 * ChartTime.values.length);
                final totalFlex = (ChartTime.values.length - 1) * 1.0 + 1.5;
                final baseWidth = availableWidth / totalFlex;

                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: ChartTime.values.map((time) {
                    final isSelected = time == chartTime;
                    final targetWidth = baseWidth * (isSelected ? 1.5 : 1.0);

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeOutCubic,
                        width: targetWidth,
                        decoration: BoxDecoration(
                          color: isSelected 
                              ? Theme.of(ref.context).colorScheme.primaryContainer 
                              : Theme.of(ref.context).colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () {
                            ref.read(beszelChartTimeProvider.notifier).state = time;
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            alignment: Alignment.center,
                            child: AnimatedDefaultTextStyle(
                              duration: const Duration(milliseconds: 400),
                              curve: Curves.easeOutCubic,
                              style: TextStyle(
                                color: isSelected 
                                    ? Theme.of(ref.context).colorScheme.onPrimaryContainer
                                    : Theme.of(ref.context).colorScheme.onSurfaceVariant,
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                                fontSize: 13,
                              ),
                              child: Text(
                                _getChartTimeLabel(time),
                                maxLines: 1,
                                overflow: TextOverflow.visible,
                                softWrap: false,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.all(Insets.md),
          sliver: statsAsync.when(
            skipLoadingOnReload: true,
            skipLoadingOnRefresh: true,
            data: (statsList) {
              if (statsList.isEmpty) {
                return const SliverToBoxAdapter(
                  child: Center(child: Text('No historical data')),
                );
              }
              final reversed = statsList.reversed.toList();
              final latest = statsList.first;
              final colorScheme = Theme.of(ref.context).colorScheme;

              return SliverList(
                delegate: SliverChildListDelegate([
                  _buildLargeStatCard(
                    ref.context,
                    'CPU Usage (${latest.cpuUsage.toStringAsFixed(1)}%)',
                    BeszelSystemCard.buildChart(
                      reversed,
                      (s) => s.cpuUsage,
                        colorScheme.primary,
                        colorScheme.primary.withValues(alpha: 0.7),
                      showLabels: true,
                      chartTime: chartTime,
                      maxY: 100,
                    ),
                  ),
                  _buildLargeStatCard(
                    ref.context,
                    'Memory Usage (${latest.memoryUsage.toStringAsFixed(1)}%)',
                    BeszelSystemCard.buildChart(
                      reversed,
                      (s) => s.memoryUsage,
                        colorScheme.secondary,
                        colorScheme.secondary.withValues(alpha: 0.7),
                      showLabels: true,
                      chartTime: chartTime,
                      maxY: 100,
                    ),
                  ),
                  _buildLargeStatCard(
                    ref.context,
                    'Disk Usage (${latest.diskUsage.toStringAsFixed(1)}%)',
                    BeszelSystemCard.buildChart(
                      reversed,
                      (s) => s.diskUsage,
                        colorScheme.tertiary,
                        colorScheme.tertiary.withValues(alpha: 0.7),
                      showLabels: true,
                      chartTime: chartTime,
                    ),
                  ),
                  _buildLargeStatCard(
                    ref.context,
                    'Swap Usage (${latest.swapUsage.toStringAsFixed(2)} GB)',
                    BeszelSystemCard.buildChart(
                      reversed,
                      (s) => s.swapUsage,
                        colorScheme.primary,
                        colorScheme.primary.withValues(alpha: 0.7),
                      showLabels: true,
                      chartTime: chartTime,
                      tooltipSuffix: ' GB',
                    ),
                  ),
                  _buildLargeStatCard(
                    ref.context,
                    'Load Average (1m: ${latest.loadAverage1m.toStringAsFixed(2)})',
                    BeszelSystemCard.buildChart(
                      reversed,
                      (s) => s.loadAverage1m,
                        colorScheme.secondary,
                        colorScheme.secondary.withValues(alpha: 0.7),
                      showLabels: true,
                      chartTime: chartTime,
                      tooltipSuffix: '',
                    ),
                  ),
                  if (latest.temperature > 0)
                    _buildLargeStatCard(
                      ref.context,
                      'Temperature (${latest.temperature.toStringAsFixed(1)} °C)',
                      BeszelSystemCard.buildChart(
                        reversed,
                        (s) => s.temperature,
                          colorScheme.error,
                          colorScheme.error.withValues(alpha: 0.7),
                        showLabels: true,
                        chartTime: chartTime,
                        tooltipSuffix: ' °C',
                      ),
                    ),
                  _buildLargeStatCard(
                    ref.context,
                    'Disk I/O (Read vs Write)',
                    BeszelSystemCard.buildChart(
                      reversed,
                      (s) => s.diskReadIo / (1024 * 1024),
                        colorScheme.primary,
                        colorScheme.primary.withValues(alpha: 0.7),
                        secondarySelector: (s) => s.diskWriteIo / (1024 * 1024),
                        secondaryStartColor: colorScheme.tertiary,
                        secondaryEndColor: colorScheme.tertiary.withValues(alpha: 0.7),
                      showLabels: true,
                      chartTime: chartTime,
                      tooltipSuffix: ' MB',
                    ),
                  ),
                  _buildLargeStatCard(
                    ref.context,
                    'Bandwidth (Sent vs Recv)',
                    BeszelSystemCard.buildChart(
                      reversed,
                      (s) => s.networkSent / (1024 * 1024),
                        colorScheme.secondary,
                        colorScheme.secondary.withValues(alpha: 0.7),
                        secondarySelector: (s) => s.networkRecv / (1024 * 1024),
                        secondaryStartColor: colorScheme.tertiary,
                        secondaryEndColor: colorScheme.tertiary.withValues(alpha: 0.7),
                      showLabels: true,
                      chartTime: chartTime,
                      tooltipSuffix: ' MB',
                    ),
                  ),
                  _buildLargeStatCard(
                    ref.context,
                    'Docker CPU Usage (${latest.dockerCpu.toStringAsFixed(1)}%)',
                    BeszelSystemCard.buildChart(
                      reversed,
                      (s) => s.dockerCpu,
                        colorScheme.primary,
                        colorScheme.primary.withValues(alpha: 0.7),
                      showLabels: true,
                      chartTime: chartTime,
                    ),
                  ),
                  _buildLargeStatCard(
                    ref.context,
                    'Docker Memory Usage (${latest.dockerMemory.toStringAsFixed(1)} MB)',
                    BeszelSystemCard.buildChart(
                      reversed,
                      (s) => s.dockerMemory,
                        colorScheme.secondary,
                        colorScheme.secondary.withValues(alpha: 0.7),
                      showLabels: true,
                      chartTime: chartTime,
                      tooltipSuffix: ' MB',
                    ),
                  ),
                  _buildLargeStatCard(
                    ref.context,
                    'Docker Network I/O (Sent vs Recv)',
                    BeszelSystemCard.buildChart(
                      reversed,
                      (s) => s.dockerNetSent / (1024 * 1024),
                        colorScheme.secondary,
                        colorScheme.secondary.withValues(alpha: 0.7),
                        secondarySelector: (s) => s.dockerNetRecv / (1024 * 1024),
                        secondaryStartColor: colorScheme.tertiary,
                        secondaryEndColor: colorScheme.tertiary.withValues(alpha: 0.7),
                      showLabels: true,
                      chartTime: chartTime,
                      tooltipSuffix: ' MB',
                    ),
                  ),
                ]),
              );
            },
            loading: () => const SliverToBoxAdapter(
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, st) => SliverToBoxAdapter(
              child: Center(child: Text('Error: $e')),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLargeStatCard(BuildContext context, String title, Widget chart) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: Insets.md),
      shape: RoundedRectangleBorder(
        borderRadius: Radii.card,
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(Insets.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: Insets.md),
            AspectRatio(
              aspectRatio: 1.70,
              child: chart,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContainerStatsTab(WidgetRef ref) {
    final asyncContainers = ref.watch(beszelContainersProvider((instance: widget.instance, systemId: widget.system.id)));

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(Insets.md),
          sliver: asyncContainers.when(
            skipLoadingOnReload: true,
            skipLoadingOnRefresh: true,
            data: (containers) {
              if (containers.isEmpty) {
                return const SliverToBoxAdapter(
                  child: Center(child: Text('No containers found')),
                );
              }
              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final container = containers[index];
                    return _BeszelContainerCard(
                      container: container,
                    );
                  },
                  childCount: containers.length,
                ),
              );
            },
            loading: () => const SliverToBoxAdapter(
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, st) => SliverToBoxAdapter(
              child: Center(child: Text('Error: $e')),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSystemdStatsTab(WidgetRef ref) {
    final args = (instance: widget.instance, systemId: widget.system.id);
    final asyncSystemd = ref.watch(beszelSystemdServicesProvider(args));

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(Insets.md),
          sliver: asyncSystemd.when(
            skipLoadingOnReload: true,
            skipLoadingOnRefresh: true,
            data: (services) {
              if (services.isEmpty) {
                return SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 48.0, horizontal: 24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.info_outline, size: 48, color: Theme.of(context).colorScheme.primary),
                        const SizedBox(height: 16),
                        Text(
                          'No systemd services found.',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ],
                    ),
                  ),
                );
              }
              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final service = services[index];
                    return _BeszelSystemdServiceCard(service: service);
                  },
                  childCount: services.length,
                ),
              );
            },
            loading: () => const SliverToBoxAdapter(
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, st) => SliverToBoxAdapter(
              child: Center(child: Text('Error: $e')),
            ),
          ),
        ),
      ],
    );
  }
}

class _BeszelSystemdServiceCard extends StatelessWidget {
  const _BeszelSystemdServiceCard({required this.service});

  final BeszelSystemdService service;

  @override
  Widget build(BuildContext context) {
    final bool isRunning = service.state == 0 || service.sub == 1; // 0=Active, 1=Running
    final colorScheme = Theme.of(context).colorScheme;
    final statusColor = isRunning ? colorScheme.primary : colorScheme.error;
    final statusIcon = isRunning ? Icons.play_circle : Icons.stop_circle;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: Insets.md),
      shape: RoundedRectangleBorder(
        borderRadius: Radii.card,
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(Insets.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(statusIcon, color: statusColor, size: 20),
                const SizedBox(width: Insets.sm),
                Expanded(
                  child: Text(
                    service.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${service.stateStr} (${service.subStr})',
                    style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: Insets.sm),
            const Divider(),
            const SizedBox(height: Insets.sm),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 2.5,
              mainAxisSpacing: Insets.sm,
              crossAxisSpacing: Insets.sm,
              children: [
                _buildStatItem(context, Icons.memory, 'CPU', '${service.cpu.toStringAsFixed(1)}%'),
                _buildStatItem(context, Icons.storage, 'Memory', _formatBytes(service.memory)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BeszelContainerCard extends StatelessWidget {
  const _BeszelContainerCard({
    required this.container,
  });

  final BeszelContainer container;

  String _extractImageName(String image) {
    var name = image.split(':').first;
    name = name.split('/').last;
    return name.toLowerCase();
  }

  Widget _buildContainerIcon(String image) {
    final name = _extractImageName(image);
    return Padding(
      padding: const EdgeInsets.only(right: Insets.sm),
      child: Image.network(
        'https://cdn.jsdelivr.net/gh/walkxcode/dashboard-icons/png/$name.png',
        width: 24,
        height: 24,
        errorBuilder: (context, error, stackTrace) => const SizedBox(width: 0, height: 0),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    final status = container.status?.toLowerCase() ?? '';
    final isRunning = status.startsWith('up') || status == 'running';
    final isPaused = status.contains('paused');
    
    final statusColor = isRunning
        ? colorScheme.primary
        : (isPaused ? colorScheme.tertiary : colorScheme.error);
        
    final statusIcon = isRunning 
        ? Icons.play_circle 
        : (isPaused ? Icons.pause_circle : Icons.stop_circle);

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: Insets.md),
      shape: RoundedRectangleBorder(
        borderRadius: Radii.card,
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(Insets.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                if (container.image != null && container.image!.isNotEmpty)
                  _buildContainerIcon(container.image!),
                Icon(statusIcon, color: statusColor, size: 20),
                const SizedBox(width: Insets.sm),
                Expanded(
                  child: Text(
                    container.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    container.status ?? 'Unknown',
                    style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: Insets.sm),
            const Divider(),
            const SizedBox(height: Insets.sm),
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 1.7,
              mainAxisSpacing: Insets.sm,
              crossAxisSpacing: Insets.sm,
              children: [
                _buildStatItem(context, Icons.memory, 'CPU', '${(container.cpu ?? 0.0).toStringAsFixed(1)}%'),
                _buildStatItem(context, Icons.storage, 'Memory', '${(container.memory ?? 0.0).toStringAsFixed(1)} MB'),
                _buildStatItem(context, Icons.network_check, 'Net', _formatNetworkTraffic(container.net)),
              ],
            ),
            if (container.image != null && container.image!.isNotEmpty) ...[
              const SizedBox(height: Insets.sm),
              const Divider(),
              const SizedBox(height: Insets.sm),
              _buildStatItem(context, Icons.inventory_2_outlined, 'Image', container.image!),
            ],
            if (container.ports != null && container.ports!.isNotEmpty) ...[
              const SizedBox(height: Insets.sm),
              _buildStatItem(context, Icons.settings_ethernet, 'Ports', container.ports!),
            ],
          ],
        ),
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

}

Widget _buildStatItem(BuildContext context, IconData icon, String label, String value) {
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

String _formatBytes(double bytes) {
  if (bytes == 0) return '0.0 KB';
  if (bytes < 1024) return '${bytes.toStringAsFixed(1)} B';
  final kb = bytes / 1024;
  if (kb < 1024) return '${kb.toStringAsFixed(1)} KB';
  final mb = kb / 1024;
  if (mb < 1024) return '${mb.toStringAsFixed(1)} MB';
  final gb = mb / 1024;
  return '${gb.toStringAsFixed(1)} GB';
}

