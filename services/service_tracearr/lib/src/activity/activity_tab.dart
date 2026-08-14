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
class ActivityTab extends ConsumerWidget {
  const ActivityTab({
    required this.instance,
    super.key,
  });

  final Instance instance;

  Future<void> _refreshAll(WidgetRef ref) async {
    ref.invalidate(tracearrStreamsProvider(instance));
    await ref
        .read(tracearrHistoryPaginatedProvider(instance).notifier)
        .refresh();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final streamsAsync = ref.watch(tracearrStreamsProvider(instance));

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
        onRefresh: () => _refreshAll(ref),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(
            horizontal: Insets.lg,
            vertical: Insets.md,
          ),
          children: [
            // 1. Live Active Streams Section
            ActiveStreamsSection(
              instance: instance,
              streamsAsync: streamsAsync,
              onRetry: () => ref.invalidate(tracearrStreamsProvider(instance)),
            ),
            const SizedBox(height: Insets.xl),

            // 2. Continuous Watch History Section
            WatchHistorySection(
              instance: instance,
            ),
            const SizedBox(height: Insets.xl),
          ],
        ),
      ),
    );
  }
}
