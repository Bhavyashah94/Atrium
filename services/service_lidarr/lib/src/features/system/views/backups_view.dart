import 'package:core_models/core_models.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/lidarr_formatters.dart';
import '../../../generated/generated.dart';
import '../../../lidarr_api.dart';
import '../../../lidarr_providers.dart';

/// System backups list view.
class BackupsView extends ConsumerWidget {
  const BackupsView({required this.instance, super.key});

  final Instance instance;

  Future<void> _triggerBackup(BuildContext context, WidgetRef ref) async {
    try {
      final LidarrApi api = await ref.read(lidarrApiProvider(instance).future);
      final ApiResponse<CommandResource> resp =
          await api.executeCommand('Backup');
      if (!resp.isSuccess) {
        throw Exception(resp.error?.message ?? 'Backup command failed');
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Database backup started!')),
        );
      }
      await Future<void>.delayed(const Duration(seconds: 2));
      ref.invalidate(lidarrSystemBackupsProvider(instance));
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to trigger backup: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final asyncBackups = ref.watch(lidarrSystemBackupsProvider(instance));

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _triggerBackup(context, ref),
        icon: const Icon(Icons.backup_outlined),
        label: const Text('Backup Now'),
      ),
      body: EasyRefresh(
        onRefresh: () async {
          ref.invalidate(lidarrSystemBackupsProvider(instance));
        },
        child: AsyncValueView<List<BackupResource>>(
          value: asyncBackups,
          data: (backups) {
            if (backups.isEmpty) {
              return const Center(
                child: EmptyView(
                  icon: Icons.backup_outlined,
                  title: 'No Backups',
                  message: 'No system backups found.',
                ),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(
                Insets.md,
                Insets.md,
                Insets.md,
                80,
              ),
              itemCount: backups.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final BackupResource backup = backups[index];
                final num sizeBytes = backup.size ?? 0;

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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: cs.primaryContainer,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.save_outlined,
                            size: 20,
                            color: cs.onPrimaryContainer,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                backup.name ?? 'Backup File',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13.5,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                [
                                  if (backup.time != null)
                                    LidarrFormatters.formatDate(backup.time),
                                  LidarrFormatters.formatBytes(sizeBytes),
                                ].join(' • '),
                                style: TextStyle(
                                  color: cs.onSurfaceVariant,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (backup.type != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: cs.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              backup.type!.name,
                              style: TextStyle(
                                color: cs.onSurfaceVariant,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
