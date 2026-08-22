import 'package:core_models/core_models.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/lidarr_formatters.dart';
import '../../../generated/generated.dart';
import '../../../lidarr_providers.dart';

/// Disk partitions & storage space view.
class DiskSpaceView extends ConsumerWidget {
  const DiskSpaceView({required this.instance, super.key});

  final Instance instance;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final asyncDiskSpace = ref.watch(lidarrDiskSpaceProvider(instance));

    return EasyRefresh(
      onRefresh: () async {
        ref.invalidate(lidarrDiskSpaceProvider(instance));
      },
      child: AsyncValueView<List<DiskSpaceResource>>(
        value: asyncDiskSpace,
        data: (diskSpaces) {
          if (diskSpaces.isEmpty) {
            return const Center(
              child: EmptyView(
                icon: Icons.storage_outlined,
                title: 'No Disk Mounts',
                message: 'No storage disks detected by Lidarr.',
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(Insets.md),
            itemCount: diskSpaces.length,
            separatorBuilder: (_, __) => const SizedBox(height: Insets.sm),
            itemBuilder: (context, index) {
              final DiskSpaceResource disk = diskSpaces[index];
              final double free = (disk.freeSpace ?? 0).toDouble();
              final double total = (disk.totalSpace ?? 0).toDouble();
              final double used = total > free ? total - free : 0;
              final double percent = total > 0 ? (used / total) : 0;

              return Card(
                elevation: 0,
                color: cs.surfaceContainerLow,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: cs.outlineVariant.withValues(alpha: 0.3),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(Insets.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: cs.primaryContainer,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.storage_outlined,
                              color: cs.onPrimaryContainer,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: Insets.sm),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  disk.path ?? 'Unknown Path',
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (disk.label != null &&
                                    disk.label!.isNotEmpty)
                                  Text(
                                    disk.label!,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: cs.onSurfaceVariant,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: Insets.md),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: percent.clamp(0.0, 1.0),
                          minHeight: 8,
                          backgroundColor: cs.surfaceContainerHighest,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            percent > 0.9
                                ? cs.error
                                : (percent > 0.8 ? cs.tertiary : cs.primary),
                          ),
                        ),
                      ),
                      const SizedBox(height: Insets.sm),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Free: ${LidarrFormatters.formatBytes(free)}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            'Total: ${LidarrFormatters.formatBytes(total)} (${(percent * 100).toStringAsFixed(1)}% used)',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
