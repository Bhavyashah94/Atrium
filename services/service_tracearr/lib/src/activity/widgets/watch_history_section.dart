import 'package:core_models/core_models.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/tracearr_providers.dart';
import 'history_item_card.dart';

enum HistoryFilter { all, completed, partial }

/// Section displaying continuous, paginated playback history with client-side filters.
class WatchHistorySection extends StatefulWidget {
  const WatchHistorySection({
    required this.instance,
    super.key,
  });

  final Instance instance;

  @override
  State<WatchHistorySection> createState() => _WatchHistorySectionState();
}

class _WatchHistorySectionState extends State<WatchHistorySection> {
  HistoryFilter _selectedFilter = HistoryFilter.all;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Consumer(
      builder: (context, ref, child) {
        final historyState =
            ref.watch(tracearrHistoryPaginatedProvider(widget.instance));
        final notifier = ref
            .read(tracearrHistoryPaginatedProvider(widget.instance).notifier);

        final allItems = historyState.items;
        final filteredItems = allItems.where((item) {
          switch (_selectedFilter) {
            case HistoryFilter.all:
              return true;
            case HistoryFilter.completed:
              return item.watched;
            case HistoryFilter.partial:
              return !item.watched;
          }
        }).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header & Filter Row
            Row(
              children: [
                Text(
                  'WATCH HISTORY',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    letterSpacing: 1.1,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                SegmentedButton<HistoryFilter>(
                  showSelectedIcon: false,
                  style: const ButtonStyle(
                    visualDensity: VisualDensity.compact,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  segments: const [
                    ButtonSegment(
                      value: HistoryFilter.all,
                      label: Text('All', style: TextStyle(fontSize: 11)),
                    ),
                    ButtonSegment(
                      value: HistoryFilter.completed,
                      label: Text('Completed', style: TextStyle(fontSize: 11)),
                    ),
                    ButtonSegment(
                      value: HistoryFilter.partial,
                      label: Text('Partial', style: TextStyle(fontSize: 11)),
                    ),
                  ],
                  selected: {_selectedFilter},
                  onSelectionChanged: (newSelection) {
                    setState(() {
                      _selectedFilter = newSelection.first;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: Insets.md),

            // Content
            if (historyState.isLoadingInitial) ...[
              Container(
                height: 140,
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(Radii.md),
                ),
                child: const Center(child: ExpressiveProgressIndicator()),
              ),
            ] else if (historyState.error != null && allItems.isEmpty) ...[
              Container(
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
                        'Failed to load watch history',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      tooltip: 'Retry',
                      onPressed: notifier.refresh,
                    ),
                  ],
                ),
              ),
            ] else if (filteredItems.isEmpty) ...[
              Container(
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
                    _selectedFilter == HistoryFilter.all
                        ? 'No watch history recorded yet.'
                        : 'No ${_selectedFilter.name} history matches filter.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ] else ...[
              ...filteredItems.map((item) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: Insets.sm),
                  child: HistoryItemCard(
                    item: item,
                    instance: widget.instance,
                  ),
                );
              }),
              const SizedBox(height: Insets.xs),

              // Pagination Load More Trigger
              if (historyState.hasMore)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: Insets.sm),
                    child: historyState.isLoadingMore
                        ? const ExpressiveProgressIndicator()
                        : OutlinedButton.icon(
                            icon: const Icon(Icons.expand_more, size: 18),
                            label: const Text('Load More History'),
                            onPressed: notifier.loadMore,
                          ),
                  ),
                ),
            ],
          ],
        );
      },
    );
  }
}
