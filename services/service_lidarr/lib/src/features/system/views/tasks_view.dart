import 'package:core_models/core_models.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/lidarr_formatters.dart';
import '../../../generated/generated.dart';
import '../../../lidarr_api.dart';
import '../../../lidarr_providers.dart';

/// Scheduled tasks and maintenance commands view.
class TasksAndMaintenanceView extends ConsumerWidget {
  const TasksAndMaintenanceView({required this.instance, super.key});

  final Instance instance;

  Future<void> _executeCommand(
    BuildContext context,
    WidgetRef ref,
    String name,
    String label,
  ) async {
    try {
      final LidarrApi api = await ref.read(lidarrApiProvider(instance).future);
      final ApiResponse<CommandResource> resp = await api.executeCommand(name);
      if (!resp.isSuccess) {
        throw Exception(resp.error?.message ?? 'Command failed');
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Started $label')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to run $label: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final asyncTasks = ref.watch(lidarrSystemTasksProvider(instance));

    return EasyRefresh(
      onRefresh: () async {
        ref.invalidate(lidarrSystemTasksProvider(instance));
      },
      child: ListView(
        padding: const EdgeInsets.all(Insets.md),
        children: [
          // Quick Maintenance Actions
          Text(
            'Maintenance Actions',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: Insets.sm),
          Wrap(
            spacing: Insets.sm,
            runSpacing: Insets.sm,
            children: [
              ActionChip(
                avatar: const Icon(Icons.health_and_safety_outlined, size: 18),
                label: const Text('Check Health'),
                onPressed: () => _executeCommand(
                  context,
                  ref,
                  'CheckHealth',
                  'Health Check',
                ),
              ),
              ActionChip(
                avatar: const Icon(Icons.sync_outlined, size: 18),
                label: const Text('Rescan Folders'),
                onPressed: () => _executeCommand(
                  context,
                  ref,
                  'RescanFolders',
                  'Rescan Folders',
                ),
              ),
              ActionChip(
                avatar: const Icon(Icons.backup_outlined, size: 18),
                label: const Text('Backup DB'),
                onPressed: () => _executeCommand(
                  context,
                  ref,
                  'Backup',
                  'Database Backup',
                ),
              ),
              ActionChip(
                avatar: const Icon(Icons.cleaning_services_outlined, size: 18),
                label: const Text('Housekeeping'),
                onPressed: () => _executeCommand(
                  context,
                  ref,
                  'Housekeeping',
                  'Housekeeping Task',
                ),
              ),
              ActionChip(
                avatar: const Icon(Icons.system_update_alt_outlined, size: 18),
                label: const Text('Check Update'),
                onPressed: () => _executeCommand(
                  context,
                  ref,
                  'ApplicationUpdateCheck',
                  'Update Check',
                ),
              ),
            ],
          ),
          const SizedBox(height: Insets.lg),

          // Scheduled Tasks List
          Text(
            'Scheduled Tasks',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: Insets.sm),
          AsyncValueView<List<TaskResource>>(
            value: asyncTasks,
            data: (tasks) {
              if (tasks.isEmpty) {
                return const Text('No scheduled tasks registered.');
              }

              return Column(
                children: tasks.map((TaskResource t) {
                  return Card(
                    elevation: 0,
                    margin: const EdgeInsets.only(bottom: 8),
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
                              Icons.schedule,
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
                                  t.name ?? 'Task',
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  [
                                    '${t.interval ?? 0}m interval',
                                    'Last: ${LidarrFormatters.formatDate(t.lastExecution)}',
                                  ].join(' • '),
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: cs.onSurfaceVariant,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.play_arrow_outlined),
                            tooltip: 'Run task now',
                            onPressed: t.taskName != null
                                ? () => _executeCommand(
                                      context,
                                      ref,
                                      t.taskName!,
                                      t.name ?? t.taskName!,
                                    )
                                : null,
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}
