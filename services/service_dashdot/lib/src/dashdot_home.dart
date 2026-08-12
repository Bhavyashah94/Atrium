import 'package:core_models/core_models.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'dashdot_providers.dart';

class DashdotHome extends ConsumerWidget {
  const DashdotHome({required this.instance, super.key});
  final Instance instance;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final infoAsync = ref.watch(dashdotInfoProvider(instance));

    return Scaffold(
      appBar: AppBar(
        title: Text(instance.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(dashdotInfoProvider(instance));
              ref.invalidate(dashdotConfigProvider(instance));
            },
          ),
        ],
      ),
      body: infoAsync.when(
        data: (info) {
          if (info == null) {
            return const Center(child: Text('Failed to load Dashdot info.'));
          }

          final cpu = info.cpu;
          final ram = info.ram;
          final storageList = info.storage ?? [];
          final network = info.network;

          return ListView(
            padding: Insets.page,
            children: [
              GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: Insets.md,
                mainAxisSpacing: Insets.md,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 1.5,
                children: [
                  _InfoBox(
                    title: 'CPU',
                    subtitle: cpu?.brand ?? 'Unknown',
                    details: '${cpu?.cores ?? '?'} Cores / ${cpu?.threads ?? '?'} Threads\n${cpu?.frequency ?? '?'} GHz',
                    icon: Icons.memory,
                  ),
                  _InfoBox(
                    title: 'RAM',
                    subtitle: ram != null && ram.size != null ? '${(ram.size! / 1024 / 1024 / 1024).toStringAsFixed(2)} GB' : 'Unknown',
                    details: (ram?.layout?.isNotEmpty ?? false)
                        ? '${ram!.layout!.first.type ?? ''} @ ${ram.layout!.first.frequency ?? '?'} MHz'
                        : '',
                    icon: Icons.developer_board,
                  ),
                  _InfoBox(
                    title: 'Network',
                    subtitle: network?.type ?? 'Unknown',
                    details: network != null 
                        ? '⬇ ${(network.speedDown is num ? network.speedDown : 0).toStringAsFixed(1)} Mbps\n⬆ ${(network.speedUp is num ? network.speedUp : 0).toStringAsFixed(1)} Mbps' 
                        : '',
                    icon: Icons.network_check,
                  ),
                  if (storageList.isNotEmpty)
                    _InfoBox(
                      title: 'Storage',
                      subtitle: storageList.first.disks?.firstOrNull?.type ?? 'Disk',
                      details: '${((storageList.first.size ?? 0) / 1024 / 1024 / 1024).toStringAsFixed(2)} GB',
                      icon: Icons.storage,
                    )
                  else
                    const _InfoBox(
                      title: 'Storage',
                      subtitle: 'Unknown',
                      details: '',
                      icon: Icons.storage,
                    ),
                ],
              ),
              const SizedBox(height: Insets.lg),
              Text('Live Metrics', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: Insets.md),
              _buildCpuLoadCard(context, ref),
              const SizedBox(height: Insets.md),
              _buildRamLoadCard(context, ref),
              const SizedBox(height: Insets.md),
              _buildStorageLoadCard(context, ref),
              const SizedBox(height: Insets.md),
              _buildNetworkLoadCard(context, ref),
              const SizedBox(height: Insets.md),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildMetricCard({
    required BuildContext context,
    required String title,
    required Widget child,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(Insets.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: Insets.md),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildCpuLoadCard(BuildContext context, WidgetRef ref) {
    return _buildMetricCard(
      context: context,
      title: 'CPU Load',
      child: Consumer(builder: (context, ref, _) {
        return ref.watch(dashdotCpuLoadProvider(instance)).when(
          data: (data) {
            if (data == null || data is! List) return const Text('No data');
            return Column(
              children: data.map((core) {
                if (core is! Map) return const SizedBox.shrink();
                final num load = core['load'] as num? ?? 0;
                final num temp = core['temp'] as num? ?? 0;
                return Padding(
                  padding: const EdgeInsets.only(bottom: Insets.sm),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 40,
                        child: Text('Core ${core['core']}'),
                      ),
                      const SizedBox(width: Insets.sm),
                      Expanded(
                        child: LinearProgressIndicator(
                          value: load / 100,
                          backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                          color: load > 80 ? Theme.of(context).colorScheme.error : Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: Insets.sm),
                      SizedBox(
                        width: 48,
                        child: Text('${load.toStringAsFixed(1)}%', textAlign: TextAlign.right),
                      ),
                      const SizedBox(width: Insets.sm),
                      SizedBox(
                        width: 40,
                        child: Text('${temp.toStringAsFixed(0)}°C', textAlign: TextAlign.right),
                      ),
                    ],
                  ),
                );
              }).toList(),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Text('Error: $e'),
        );
      }),
    );
  }

  Widget _buildRamLoadCard(BuildContext context, WidgetRef ref) {
    return _buildMetricCard(
      context: context,
      title: 'RAM Load',
      child: Consumer(builder: (context, ref, _) {
        return ref.watch(dashdotRamLoadProvider(instance)).when(
          data: (data) {
            if (data == null || data is! Map) return const Text('No data');
            final num loadBytes = data['load'] as num? ?? 0;
            final double loadGb = loadBytes / 1024 / 1024 / 1024;
            
            // To show percentage we need total capacity. We could watch infoProvider again.
            final info = ref.read(dashdotInfoProvider(instance)).value;
            final double totalGb = (info?.ram?.size ?? 0) / 1024 / 1024 / 1024;
            final double pct = totalGb > 0 ? (loadGb / totalGb) : 0;
            
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('${loadGb.toStringAsFixed(2)} GB Used'),
                    Text('${(pct * 100).toStringAsFixed(1)}%'),
                  ],
                ),
                const SizedBox(height: Insets.xs),
                LinearProgressIndicator(
                  value: totalGb > 0 ? pct : null,
                  backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                  color: pct > 0.8 ? Theme.of(context).colorScheme.error : Theme.of(context).colorScheme.primary,
                ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Text('Error: $e'),
        );
      }),
    );
  }

  Widget _buildStorageLoadCard(BuildContext context, WidgetRef ref) {
    return _buildMetricCard(
      context: context,
      title: 'Storage Load',
      child: Consumer(builder: (context, ref, _) {
        return ref.watch(dashdotStorageLoadProvider(instance)).when(
          data: (data) {
            if (data == null || data is! List) return const Text('No data');
            // Storage load returns an array of used bytes per disk, e.g. [-1, 577000000000] where -1 means unknown.
            final info = ref.read(dashdotInfoProvider(instance)).value;
            final storageList = info?.storage ?? [];
            
            return Column(
              children: List.generate(data.length, (index) {
                final num usedBytes = data[index] as num? ?? -1;
                if (usedBytes < 0) return const SizedBox.shrink();
                
                final double usedGb = usedBytes / 1024 / 1024 / 1024;
                final double totalGb = (index < storageList.length) 
                    ? ((storageList[index].size ?? 0) / 1024 / 1024 / 1024) 
                    : 0;
                
                final double pct = totalGb > 0 ? (usedGb / totalGb) : 0;
                final String diskName = (index < storageList.length && (storageList[index].disks?.isNotEmpty ?? false))
                    ? (storageList[index].disks!.first.device ?? 'Disk $index')
                    : 'Disk $index';

                return Padding(
                  padding: const EdgeInsets.only(bottom: Insets.sm),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(diskName, style: Theme.of(context).textTheme.labelLarge),
                          Text('${usedGb.toStringAsFixed(1)} GB / ${totalGb > 0 ? totalGb.toStringAsFixed(1) : '?'} GB'),
                        ],
                      ),
                      const SizedBox(height: Insets.xs),
                      LinearProgressIndicator(
                        value: totalGb > 0 ? pct : null,
                        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                        color: pct > 0.9 ? Theme.of(context).colorScheme.error : Theme.of(context).colorScheme.primary,
                      ),
                    ],
                  ),
                );
              }),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Text('Error: $e'),
        );
      }),
    );
  }

  Widget _buildNetworkLoadCard(BuildContext context, WidgetRef ref) {
    return _buildMetricCard(
      context: context,
      title: 'Network Traffic',
      child: Consumer(builder: (context, ref, _) {
        return ref.watch(dashdotNetworkLoadProvider(instance)).when(
          data: (data) {
            if (data == null || data is! Map) return const Text('No data');
            final num upBytes = data['up'] as num? ?? 0;
            final num downBytes = data['down'] as num? ?? 0;
            final double upMbps = upBytes / 1024 / 1024;
            final double downMbps = downBytes / 1024 / 1024;

            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Column(
                  children: [
                    const Icon(Icons.arrow_downward, color: Colors.green),
                    const SizedBox(height: Insets.xs),
                    Text('${downMbps.toStringAsFixed(2)} MB/s', style: Theme.of(context).textTheme.titleMedium),
                    Text('Download', style: Theme.of(context).textTheme.labelSmall),
                  ],
                ),
                Column(
                  children: [
                    const Icon(Icons.arrow_upward, color: Colors.blue),
                    const SizedBox(height: Insets.xs),
                    Text('${upMbps.toStringAsFixed(2)} MB/s', style: Theme.of(context).textTheme.titleMedium),
                    Text('Upload', style: Theme.of(context).textTheme.labelSmall),
                  ],
                ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Text('Error: $e'),
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
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          if (details.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              details,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
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
