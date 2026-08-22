import 'package:core_models/core_models.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../generated/generated.dart';
import '../../../lidarr_providers.dart';

/// System runtime status & health checks view.
class StatusAndHealthView extends ConsumerWidget {
  const StatusAndHealthView({required this.instance, super.key});

  final Instance instance;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final asyncStatus = ref.watch(lidarrSystemStatusProvider(instance));
    final asyncHealth = ref.watch(lidarrHealthProvider(instance));

    return EasyRefresh(
      onRefresh: () async {
        ref.invalidate(lidarrSystemStatusProvider(instance));
        ref.invalidate(lidarrHealthProvider(instance));
      },
      child: ListView(
        padding: const EdgeInsets.all(Insets.md),
        children: [
          // Health Checks Section
          Text(
            'Health Checks',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: Insets.sm),
          AsyncValueView<List<HealthResource>>(
            value: asyncHealth,
            data: (healthItems) {
              if (healthItems.isEmpty) {
                return Card(
                  elevation: 0,
                  color: cs.tertiaryContainer.withValues(alpha: 0.25),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: cs.tertiary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: cs.tertiary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.check_circle,
                            color: cs.tertiary,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'All Health Checks Passing',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'No system issues or warnings detected.',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: cs.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return Column(
                children: healthItems.map((HealthResource h) {
                  final bool isError = h.type == HealthCheckResult.error;
                  final Color iconColor = isError ? cs.error : cs.tertiary;

                  return Card(
                    elevation: 0,
                    margin: const EdgeInsets.only(bottom: 8),
                    color: isError
                        ? cs.errorContainer.withValues(alpha: 0.25)
                        : cs.tertiaryContainer.withValues(alpha: 0.25),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: iconColor.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: iconColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              isError
                                  ? Icons.error_outline
                                  : Icons.warning_amber,
                              color: iconColor,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  h.source ?? 'Health Issue',
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  h.message ?? 'No details provided',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: cs.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
          const SizedBox(height: Insets.lg),

          // System Info Section
          Text(
            'System Information',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: Insets.sm),
          AsyncValueView<SystemResource>(
            value: asyncStatus,
            data: (SystemResource status) {
              return Card(
                elevation: 0,
                color: cs.surfaceContainerLow,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: cs.outlineVariant.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  children: [
                    _infoTile(
                      context,
                      'Version',
                      status.version ?? '--',
                      Icons.info_outline,
                      theme,
                    ),
                    const Divider(height: 1),
                    if (status.packageVersion != null) ...[
                      _infoTile(
                        context,
                        'Package Version',
                        status.packageVersion!,
                        Icons.inventory_2_outlined,
                        theme,
                      ),
                      const Divider(height: 1),
                    ],
                    _infoTile(
                      context,
                      'Branch',
                      status.branch ?? 'master',
                      Icons.alt_route,
                      theme,
                    ),
                    const Divider(height: 1),
                    _infoTile(
                      context,
                      'Operating System',
                      status.osVersion != null && status.osVersion!.isNotEmpty
                          ? '${status.osName ?? 'Unknown OS'} (${status.osVersion})'
                          : status.osName ?? 'Unknown OS',
                      Icons.computer,
                      theme,
                    ),
                    const Divider(height: 1),
                    _infoTile(
                      context,
                      '.NET Runtime',
                      status.runtimeVersion ?? '--',
                      Icons.code,
                      theme,
                    ),
                    const Divider(height: 1),
                    _infoTile(
                      context,
                      'AppData Directory',
                      status.appData ?? '--',
                      Icons.folder_open,
                      theme,
                    ),
                    const Divider(height: 1),
                    _infoTile(
                      context,
                      'Startup Path',
                      status.startupPath ?? '--',
                      Icons.launch,
                      theme,
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _infoTile(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    ThemeData theme,
  ) {
    final cs = theme.colorScheme;
    return InkWell(
      onTap: () {
        Clipboard.setData(ClipboardData(text: value));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$title copied to clipboard!'),
            duration: const Duration(seconds: 1),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(icon, size: 18, color: cs.onSurfaceVariant),
            const SizedBox(width: 12),
            Text(
              title,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                value,
                textAlign: TextAlign.end,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
