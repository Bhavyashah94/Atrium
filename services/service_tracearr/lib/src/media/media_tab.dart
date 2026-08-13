import 'package:core_models/core_models.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/tracearr_providers.dart';
import 'widgets/media_storage_summary_bar.dart';
import 'widgets/recently_added_grid.dart';

/// Main Media destination for Tracearr in Atrium.
///
/// Features fleet storage capacity summary, resolution breakdown, library filter chips,
/// responsive multi-column poster catalog, grid/list view toggle, and pagination.
class MediaTab extends ConsumerWidget {
  const MediaTab({
    required this.instance,
    super.key,
  });

  final Instance instance;

  Future<void> _refreshAll(WidgetRef ref) async {
    ref.invalidate(tracearrLibrariesProvider(instance));
    await ref
        .read(tracearrRecentPaginatedProvider(instance).notifier)
        .refresh();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final librariesAsync = ref.watch(tracearrLibrariesProvider(instance));

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu),
          tooltip: 'Open menu',
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              instance.name,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              'Media',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
      body: EasyRefresh(
        header: const ClassicHeader(
          dragText: 'Pull to refresh',
          armedText: 'Release ready',
          readyText: 'Refreshing library catalog...',
          processingText: 'Refreshing library catalog...',
          processedText: 'Updated',
          failedText: 'Failed',
          messageText: 'Last updated at %T',
        ),
        onRefresh: () => _refreshAll(ref),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(
            horizontal: Insets.lg,
            vertical: Insets.md,
          ),
          children: [
            // 1. Storage & Resolution Summary Bar with Library Filters
            MediaStorageSummaryBar(
              instance: instance,
              librariesAsync: librariesAsync,
              onRetry: () =>
                  ref.invalidate(tracearrLibrariesProvider(instance)),
            ),
            const SizedBox(height: Insets.lg),

            // 2. Recently Added Media Grid / List Catalog
            RecentlyAddedGrid(
              instance: instance,
            ),
            const SizedBox(height: Insets.xl),
          ],
        ),
      ),
    );
  }
}
