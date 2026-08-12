import 'dart:convert';
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
              _buildStreamCard(context, ref, 'CPU Load', dashdotCpuLoadProvider(instance)),
              const SizedBox(height: Insets.md),
              _buildStreamCard(context, ref, 'RAM Load', dashdotRamLoadProvider(instance)),
              const SizedBox(height: Insets.md),
              _buildStreamCard(context, ref, 'Storage Load', dashdotStorageLoadProvider(instance)),
              const SizedBox(height: Insets.md),
              _buildStreamCard(context, ref, 'Network Load', dashdotNetworkLoadProvider(instance)),
              const SizedBox(height: Insets.md),
              _buildStreamCard(context, ref, 'GPU Load', dashdotGpuLoadProvider(instance)),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildStreamCard(
    BuildContext context,
    WidgetRef ref,
    String title,
    StreamProvider<dynamic> provider,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(Insets.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: Insets.sm),
            Consumer(
              builder: (context, ref, child) {
                final asyncValue = ref.watch(provider);
                return asyncValue.when(
                  data: (dynamic data) {
                    if (data == null) return const Text('No data');
                    return Text(
                      const JsonEncoder.withIndent('  ').convert(data),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontFamily: 'monospace',
                      ),
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (Object e, StackTrace st) => Text('Error: $e'),
                );
              },
            ),
          ],
        ),
      ),
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
