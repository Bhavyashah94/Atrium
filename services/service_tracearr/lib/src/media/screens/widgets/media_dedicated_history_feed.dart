import 'package:core_models/core_models.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../activity/widgets/history_item_card.dart';
import '../../../providers/tracearr_providers.dart';

/// Dedicated watch history feed for a specific media item.
class MediaDedicatedHistoryFeed extends ConsumerWidget {
  const MediaDedicatedHistoryFeed({
    required this.instance,
    required this.mediaRef,
    super.key,
  });

  final Instance instance;
  final String mediaRef;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final historyAsync =
        ref.watch(tracearrMediaHistoryProvider((instance, mediaRef)));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.history, size: 16, color: colorScheme.primary),
            const SizedBox(width: Insets.xs),
            Text(
              'PLAYBACK HISTORY',
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: colorScheme.primary,
                letterSpacing: 1.1,
              ),
            ),
          ],
        ),
        const SizedBox(height: Insets.md),
        historyAsync.when(
          loading: () => Container(
            height: 100,
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
                Icon(Icons.history_toggle_off, color: colorScheme.error),
                const SizedBox(width: Insets.md),
                Expanded(
                  child: Text(
                    'Failed to load media history',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () => ref.invalidate(
                    tracearrMediaHistoryProvider((instance, mediaRef)),
                  ),
                ),
              ],
            ),
          ),
          data: (historyPage) {
            final items = historyPage.items;

            if (items.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(Insets.lg),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(Radii.md),
                  border: Border.all(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                  ),
                ),
                child: Center(
                  child: Text(
                    'No watch sessions recorded for this item.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              );
            }

            return Column(
              children: items.map((item) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: Insets.sm),
                  child: HistoryItemCard(
                    item: item,
                    instance: instance,
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }
}
