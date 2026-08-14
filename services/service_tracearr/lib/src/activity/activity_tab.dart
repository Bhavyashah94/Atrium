import 'package:core_models/core_models.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/tracearr_providers.dart';
import 'widgets/active_streams_section.dart';
import 'widgets/watch_history_section.dart';

/// Main Activity destination for Tracearr service in Atrium.
///
/// Features live active stream telemetry, transcode triage, diagnostics, safe stream
/// termination flow, and continuous paginated watch history.
class ActivityTab extends ConsumerStatefulWidget {
  const ActivityTab({
    required this.instance,
    super.key,
  });

  final Instance instance;

  @override
  ConsumerState<ActivityTab> createState() => _ActivityTabState();
}

class _ActivityTabState extends ConsumerState<ActivityTab> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _refreshAll() async {
    ref.invalidate(tracearrStreamsProvider(widget.instance));
    await ref
        .read(tracearrHistoryPaginatedProvider(widget.instance).notifier)
        .refresh();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    ref.listen<int>(
      tracearrHomeScrollToTopProvider((widget.instance, 1)),
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

    final streamsAsync = ref.watch(tracearrStreamsProvider(widget.instance));

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
              'Activity',
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
          readyText: 'Refreshing playback telemetry...',
          processingText: 'Refreshing playback telemetry...',
          processedText: 'Updated',
          failedText: 'Failed',
          messageText: 'Last updated at %T',
        ),
        footer: const ClassicFooter(
          infiniteOffset: 200.0,
          dragText: 'Pull to load more',
          armedText: 'Release to load more',
          readyText: 'Loading more history...',
          processingText: 'Loading more history...',
          processedText: 'Loaded',
          failedText: 'Failed to load',
          noMoreText: 'All history loaded',
        ),
        onRefresh: _refreshAll,
        onLoad: () async {
          await ref
              .read(tracearrHistoryPaginatedProvider(widget.instance).notifier)
              .loadMore();
          // See media_tab: loadMore's bool conflates exhausted with no-op and
          // failed, so hasMore is the only trustworthy end-of-list signal.
          return ref.read(tracearrHistoryPaginatedProvider(widget.instance)).hasMore
              ? IndicatorResult.success
              : IndicatorResult.noMore;
        },
        child: NotificationListener<ScrollNotification>(
          onNotification: (notification) {
            if (notification.metrics.pixels >=
                notification.metrics.maxScrollExtent - 250) {
              ref
                  .read(tracearrHistoryPaginatedProvider(widget.instance).notifier)
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
              // 1. Live Active Streams Section
              RepaintBoundary(
                child: ActiveStreamsSection(
                  instance: widget.instance,
                  streamsAsync: streamsAsync,
                  onRetry: () =>
                      ref.invalidate(tracearrStreamsProvider(widget.instance)),
                ),
              ),
              const SizedBox(height: Insets.xl),

              // 2. Continuous Watch History Section
              RepaintBoundary(
                child: WatchHistorySection(
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
