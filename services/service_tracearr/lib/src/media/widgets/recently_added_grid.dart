import 'package:core_models/core_models.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/tracearr_providers.dart';
import 'recently_added_card.dart';
import 'recently_added_poster_tile.dart';

/// Container for recently added fleet media with Grid / List view toggle and pagination.
class RecentlyAddedGrid extends ConsumerStatefulWidget {
  const RecentlyAddedGrid({
    required this.instance,
    super.key,
  });

  final Instance instance;

  @override
  ConsumerState<RecentlyAddedGrid> createState() => _RecentlyAddedGridState();
}

class _RecentlyAddedGridState extends ConsumerState<RecentlyAddedGrid> {
  bool _isGridView = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final recentState =
        ref.watch(tracearrRecentPaginatedProvider(widget.instance));
    final notifier =
        ref.read(tracearrRecentPaginatedProvider(widget.instance).notifier);

    final isTablet = MediaQuery.sizeOf(context).width > 600;
    final crossAxisCount = isTablet ? 5 : 3;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header with View Toggle
        Row(
          children: [
            Icon(
              Icons.video_library_outlined,
              size: 18,
              color: colorScheme.primary,
            ),
            const SizedBox(width: Insets.xs),
            Text(
              'RECENTLY ADDED',
              style: theme.textTheme.labelMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                letterSpacing: 1.1,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Spacer(),
            IconButton(
              icon: Icon(
                _isGridView
                    ? Icons.view_list_outlined
                    : Icons.grid_view_outlined,
                size: 20,
              ),
              tooltip:
                  _isGridView ? 'Switch to List View' : 'Switch to Grid View',
              onPressed: () => setState(() => _isGridView = !_isGridView),
            ),
          ],
        ),
        const SizedBox(height: Insets.sm),

        // Body States
        if (recentState.isLoadingInitial) ...[
          Container(
            height: 180,
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(Radii.md),
            ),
            child: const Center(child: ExpressiveProgressIndicator()),
          ),
        ] else if (recentState.error != null && recentState.items.isEmpty) ...[
          Container(
            padding: const EdgeInsets.all(Insets.md),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(Radii.md),
            ),
            child: Row(
              children: [
                Icon(Icons.error_outline, color: colorScheme.error),
                const SizedBox(width: Insets.md),
                Expanded(
                  child: Text(
                    recentState.error.toString(),
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
        ] else if (recentState.items.isEmpty) ...[
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
                'No recently added media found.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ] else ...[
          if (_isGridView)
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: Insets.sm,
                mainAxisSpacing: Insets.md,
                childAspectRatio: 0.52,
              ),
              itemCount: recentState.items.length,
              itemBuilder: (context, index) {
                final item = recentState.items[index];
                return RecentlyAddedPosterTile(
                  instance: widget.instance,
                  item: item,
                );
              },
            )
          else
            Column(
              children: recentState.items.map((item) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: Insets.sm),
                  child: RecentlyAddedCard(
                    instance: widget.instance,
                    item: item,
                  ),
                );
              }).toList(),
            ),
        ],
      ],
    );
  }
}
