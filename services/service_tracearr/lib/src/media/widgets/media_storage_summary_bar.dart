import 'package:core_models/core_models.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/tracearr_models.dart';
import '../../providers/tracearr_providers.dart';

/// Storage summary card with fleet capacity, resolution breakdown, and library filter chips.
class MediaStorageSummaryBar extends StatelessWidget {
  const MediaStorageSummaryBar({
    required this.instance,
    required this.librariesAsync,
    this.onRetry,
    super.key,
  });

  final Instance instance;
  final AsyncValue<List<TracearrLibrary>> librariesAsync;
  final VoidCallback? onRetry;

  String _formatBytes(int bytes) {
    if (bytes <= 0) return '0 GB';
    final double gigabytes = bytes / (1024 * 1024 * 1024);
    if (gigabytes >= 1000) {
      final double terabytes = gigabytes / 1024;
      return '${terabytes.toStringAsFixed(1)} TB';
    }
    return '${gigabytes.toStringAsFixed(1)} GB';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return librariesAsync.when(
      loading: () => Container(
        height: 90,
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(Radii.md),
        ),
        child: const Center(child: ExpressiveProgressIndicator()),
      ),
      error: (err, _) => Container(
        padding: const EdgeInsets.all(Insets.md),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(Radii.md),
        ),
        child: Row(
          children: [
            Icon(Icons.storage, color: colorScheme.error),
            const SizedBox(width: Insets.md),
            Expanded(
              child: Text(
                'Failed to load library storage telemetry',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface,
                ),
              ),
            ),
            if (onRetry != null)
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: onRetry,
              ),
          ],
        ),
      ),
      data: (libraries) {
        if (libraries.isEmpty) {
          return const SizedBox.shrink();
        }

        final int totalBytes =
            libraries.fold(0, (sum, lib) => sum + lib.totalFileSize);
        final int totalItems =
            libraries.fold(0, (sum, lib) => sum + lib.itemCount);

        final String formattedStorage = _formatBytes(totalBytes);

        // Aggregate verified resolution breakdown from API
        final Map<String, int> aggregateResolutions = {};
        for (final lib in libraries) {
          lib.resolutions.forEach((res, count) {
            final key = res.toUpperCase();
            aggregateResolutions[key] =
                (aggregateResolutions[key] ?? 0) + count;
          });
        }

        return Consumer(
          builder: (context, ref, child) {
            final selectedFilter =
                ref.watch(tracearrSelectedLibraryFilterProvider(instance));

            return Container(
              padding: const EdgeInsets.all(Insets.md),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(Radii.md),
                border: Border.all(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.pie_chart_outline,
                        size: 18,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(width: Insets.xs),
                      Text(
                        'FLEET STORAGE',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          letterSpacing: 1.1,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '$formattedStorage across ${libraries.length} Libraries',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: Insets.xs),
                  Text(
                    '${totalItems.toString()} total catalog items in fleet',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),

                  // Resolution Breakdown Chips (if present in API)
                  if (aggregateResolutions.isNotEmpty) ...[
                    const SizedBox(height: Insets.sm),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: aggregateResolutions.entries.map((entry) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerHighest
                                .withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(Radii.sm),
                          ),
                          child: Text(
                            '${entry.key}: ${entry.value}',
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],

                  const SizedBox(height: Insets.md),
                  // Library Filter Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        FilterChip(
                          label: const Text('All Libraries'),
                          selected:
                              selectedFilter == 'all' || selectedFilter.isEmpty,
                          onSelected: (selected) {
                            ref
                                .read(
                                  tracearrSelectedLibraryFilterProvider(
                                    instance,
                                  ).notifier,
                                )
                                .state = 'all';
                          },
                        ),
                        ...libraries.map((lib) {
                          final isSelected = selectedFilter == lib.libraryId;
                          final String label =
                              '${lib.serverType.toUpperCase()} (${lib.itemCount})';

                          return Padding(
                            padding: const EdgeInsets.only(left: Insets.xs),
                            child: FilterChip(
                              label: Text(label),
                              selected: isSelected,
                              onSelected: (selected) {
                                ref
                                    .read(
                                      tracearrSelectedLibraryFilterProvider(
                                        instance,
                                      ).notifier,
                                    )
                                    .state = selected ? lib.libraryId : 'all';
                              },
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
