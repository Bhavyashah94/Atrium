import 'package:core_models/core_models.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/lidarr_formatters.dart';
import '../../../generated/generated.dart';
import '../../../lidarr_providers.dart';

/// System update history & release notes view.
class UpdatesView extends ConsumerWidget {
  const UpdatesView({required this.instance, super.key});

  final Instance instance;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;
    final AsyncValue<List<UpdateResource>> asyncUpdates =
        ref.watch(lidarrUpdatesProvider(instance));

    return EasyRefresh(
      onRefresh: () async {
        ref.invalidate(lidarrUpdatesProvider(instance));
      },
      child: AsyncValueView<List<UpdateResource>>(
        value: asyncUpdates,
        data: (List<UpdateResource> updates) {
          if (updates.isEmpty) {
            return const Center(
              child: EmptyView(
                icon: Icons.system_update_outlined,
                title: 'No Updates Found',
                message: 'No update history available.',
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(Insets.md),
            itemCount: updates.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (BuildContext context, int index) {
              final UpdateResource update = updates[index];
              final bool isInstalled = update.installed == true;
              final bool isLatest = update.latest == true;

              final List<String> newItems =
                  update.changes?.newVal ?? <String>[];
              final List<String> fixedItems =
                  update.changes?.fixed ?? <String>[];

              return Card(
                elevation: 0,
                color: cs.surfaceContainerLow,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: isInstalled
                        ? cs.primary.withValues(alpha: 0.5)
                        : cs.outlineVariant.withValues(alpha: 0.3),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(Insets.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Text(
                                'v${update.version ?? 'Unknown'}',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: Insets.xs),
                              if (isInstalled)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: cs.primaryContainer,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'Installed',
                                    style: TextStyle(
                                      color: cs.onPrimaryContainer,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                )
                              else if (isLatest)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: cs.secondaryContainer,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'Latest',
                                    style: TextStyle(
                                      color: cs.onSecondaryContainer,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          Text(
                            LidarrFormatters.formatDate(update.releaseDate),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      if (update.branch != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Branch: ${update.branch}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ],
                      if (newItems.isNotEmpty) ...[
                        const SizedBox(height: Insets.sm),
                        Text(
                          'New Features:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: cs.primary,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 2),
                        ...newItems.map(
                          (String item) => Padding(
                            padding: const EdgeInsets.only(left: 8, top: 2),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('• '),
                                Expanded(child: Text(item)),
                              ],
                            ),
                          ),
                        ),
                      ],
                      if (fixedItems.isNotEmpty) ...[
                        const SizedBox(height: Insets.sm),
                        Text(
                          'Bug Fixes:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: cs.secondary,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 2),
                        ...fixedItems.map(
                          (String item) => Padding(
                            padding: const EdgeInsets.only(left: 8, top: 2),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('• '),
                                Expanded(child: Text(item)),
                              ],
                            ),
                          ),
                        ),
                      ],
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
