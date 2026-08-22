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
class MediaTab extends ConsumerStatefulWidget {
  const MediaTab({
    required this.instance,
    super.key,
  });

  final Instance instance;

  @override
  ConsumerState<MediaTab> createState() => _MediaTabState();
}

class _MediaTabState extends ConsumerState<MediaTab> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _refreshAll() async {
    ref.invalidate(tracearrLibrariesProvider(widget.instance));
    await ref
        .read(tracearrRecentPaginatedProvider(widget.instance).notifier)
        .refresh();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    ref.listen<int>(
      tracearrHomeScrollToTopProvider((widget.instance, 2)),
      (previous, next) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
          );
        }
      },
    );

    final librariesAsync =
        ref.watch(tracearrLibrariesProvider(widget.instance));

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
              widget.instance.name,
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
        footer: const ClassicFooter(
          infiniteOffset: 200.0,
          dragText: 'Pull to load more',
          armedText: 'Release to load more',
          readyText: 'Loading more media...',
          processingText: 'Loading more media...',
          processedText: 'Loaded',
          failedText: 'Failed to load',
          noMoreText: 'All media loaded',
        ),
        onRefresh: _refreshAll,
        onLoad: () async {
          await ref
              .read(tracearrRecentPaginatedProvider(widget.instance).notifier)
              .loadMore();
          // Ask the state rather than loadMore's bool. That returns false for
          // three different reasons - exhausted, already loading, or failed -
          // so mapping it straight to noMore would end pagination for good on
          // a transient error. hasMore also stays true while the first page is
          // still in flight, which a bare cursor check would misread as the
          // end of the catalog.
          return ref
                  .read(tracearrRecentPaginatedProvider(widget.instance))
                  .hasMore
              ? IndicatorResult.success
              : IndicatorResult.noMore;
        },
        child: NotificationListener<ScrollNotification>(
          onNotification: (notification) {
            if (notification.metrics.pixels >=
                notification.metrics.maxScrollExtent - 250) {
              ref
                  .read(
                      tracearrRecentPaginatedProvider(widget.instance).notifier)
                  .loadMore();
            }
            return false;
          },
          child: ListView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(
              horizontal: Insets.lg,
              vertical: Insets.md,
            ),
            children: [
              // 1. Storage & Resolution Summary Bar with Library Filters
              RepaintBoundary(
                child: MediaStorageSummaryBar(
                  instance: widget.instance,
                  librariesAsync: librariesAsync,
                  onRetry: () => ref
                      .invalidate(tracearrLibrariesProvider(widget.instance)),
                ),
              ),
              const SizedBox(height: Insets.lg),

              // 2. Recently Added Media Grid / List Catalog
              RepaintBoundary(
                child: RecentlyAddedGrid(
                  instance: widget.instance,
                ),
              ),
              const SizedBox(height: Insets.xl),
            ],
          ),
        ),
      ),
    );
  }
}
