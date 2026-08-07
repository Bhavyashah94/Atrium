import 'package:cached_network_image/cached_network_image.dart';
import 'package:core_models/core_models.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'models/tracearr_v2_models.dart';
import 'tracearr_api.dart';
import 'tracearr_providers.dart';

/// Screen displaying media details, per-server availability, children hierarchy,
/// play statistics (All Time / 30 Days / 7 Days), top watchers, and watch history.
class TracearrMediaDetailScreen extends ConsumerStatefulWidget {
  const TracearrMediaDetailScreen({
    required this.instance,
    required this.mediaRef,
    required this.title,
    this.posterUrl,
    super.key,
  });

  final Instance instance;
  final String mediaRef;
  final String title;
  final String? posterUrl;

  @override
  ConsumerState<TracearrMediaDetailScreen> createState() =>
      _TracearrMediaDetailScreenState();
}

class _TracearrMediaDetailScreenState
    extends ConsumerState<TracearrMediaDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _formatDuration(int? seconds) {
    if (seconds == null || seconds <= 0) return '0h';
    final int hours = (seconds / 3600).round();
    if (hours >= 24) {
      final double days = hours / 24;
      return '${days.toStringAsFixed(1)}d';
    }
    return '${hours}h';
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<TracearrV2MediaResource?> mediaVal = ref.watch(
      tracearrV2MediaResourceProvider(
        (instance: widget.instance, ref: widget.mediaRef),
      ),
    );
    final TracearrApi? api = ref.watch(tracearrApiProvider(widget.instance)).value;
    final String? fullPosterUrl = api?.imageUrl(widget.posterUrl);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const <Widget>[
            Tab(icon: Icon(Icons.info_outline), text: 'Details'),
            Tab(icon: Icon(Icons.account_tree_outlined), text: 'Hierarchy'),
            Tab(icon: Icon(Icons.people_outline), text: 'Watchers'),
            Tab(icon: Icon(Icons.history), text: 'History'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: <Widget>[
          _MediaDetailsTab(
            instance: widget.instance,
            mediaRef: widget.mediaRef,
            title: widget.title,
            posterUrl: fullPosterUrl,
            mediaVal: mediaVal,
            formatDuration: _formatDuration,
          ),
          _MediaChildrenTab(
            instance: widget.instance,
            mediaRef: widget.mediaRef,
          ),
          _MediaWatchersTab(
            instance: widget.instance,
            mediaRef: widget.mediaRef,
            formatDuration: _formatDuration,
          ),
          _MediaHistoryTab(
            instance: widget.instance,
            mediaRef: widget.mediaRef,
            formatDuration: _formatDuration,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Details Tab
// ---------------------------------------------------------------------------

class _MediaDetailsTab extends ConsumerWidget {
  const _MediaDetailsTab({
    required this.instance,
    required this.mediaRef,
    required this.title,
    required this.posterUrl,
    required this.mediaVal,
    required this.formatDuration,
  });

  final Instance instance;
  final String mediaRef;
  final String title;
  final String? posterUrl;
  final AsyncValue<TracearrV2MediaResource?> mediaVal;
  final String Function(int? seconds) formatDuration;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<TracearrV2MediaStatsResponse?> statsVal = ref.watch(
      tracearrV2MediaStatsProvider(
        (instance: instance, ref: mediaRef),
      ),
    );

    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            if (posterUrl != null && posterUrl!.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: posterUrl!,
                  width: 100,
                  height: 150,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => Container(
                    width: 100,
                    height: 150,
                    color: Theme.of(context).colorScheme.surfaceContainerHigh,
                    child: const Icon(Icons.movie, size: 40),
                  ),
                ),
              )
            else
              Container(
                width: 100,
                height: 150,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.movie, size: 40),
              ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    title,
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  mediaVal.when(
                    data: (TracearrV2MediaResource? res) {
                      if (res == null) return const SizedBox.shrink();
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          if (res.year != null)
                            Text(
                              'Year: ${res.year}',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          Text(
                            'Type: ${res.mediaType.toUpperCase()}',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          if (res.genres.isNotEmpty) ...<Widget>[
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 4,
                              runSpacing: 4,
                              children: res.genres.map((g) {
                                return Chip(
                                  visualDensity: VisualDensity.compact,
                                  label: Text(g, style: const TextStyle(fontSize: 10)),
                                );
                              }).toList(),
                            ),
                          ],
                        ],
                      );
                    },
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),

        // Play Statistics Windows
        Text(
          'Play Statistics',
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),

        statsVal.when(
          data: (TracearrV2MediaStatsResponse? stats) {
            if (stats == null) {
              return const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('No stats recorded for this media item.'),
                ),
              );
            }

            final Map<String, dynamic>? windows = stats.windows;
            final Map<String, dynamic>? allTimeWindow =
                windows?['all_time'] as Map<String, dynamic>?;
            final Map<String, dynamic>? allTime =
                allTimeWindow?['combined'] as Map<String, dynamic>?;

            final Map<String, dynamic>? last30Window =
                windows?['last_30'] as Map<String, dynamic>?;
            final Map<String, dynamic>? last30 =
                last30Window?['combined'] as Map<String, dynamic>?;

            final Map<String, dynamic>? last7Window =
                windows?['last_7'] as Map<String, dynamic>?;
            final Map<String, dynamic>? last7 =
                last7Window?['combined'] as Map<String, dynamic>?;

            final int allTimePlays = (allTime?['plays'] as num?)?.toInt() ?? 0;
            final int allTimeWatchMs =
                (allTime?['watch_time_ms'] as num?)?.toInt() ?? 0;
            final int last30Plays = (last30?['plays'] as num?)?.toInt() ?? 0;
            final int last30WatchMs =
                (last30?['watch_time_ms'] as num?)?.toInt() ?? 0;
            final int last7Plays = (last7?['plays'] as num?)?.toInt() ?? 0;
            final int last7WatchMs =
                (last7?['watch_time_ms'] as num?)?.toInt() ?? 0;

            return Row(
              children: <Widget>[
                Expanded(
                  child: _MediaStatCard(
                    title: 'All Time',
                    plays: allTimePlays,
                    watchTime: formatDuration(allTimeWatchMs ~/ 1000),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _MediaStatCard(
                    title: '30 Days',
                    plays: last30Plays,
                    watchTime: formatDuration(last30WatchMs ~/ 1000),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _MediaStatCard(
                    title: '7 Days',
                    plays: last7Plays,
                    watchTime: formatDuration(last7WatchMs ~/ 1000),
                  ),
                ),
              ],
            );
          },
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (Object e, _) => Text('Error loading stats: $e'),
        ),

        const SizedBox(height: 20),

        // Server Availability
        mediaVal.when(
          data: (TracearrV2MediaResource? res) {
            if (res == null || res.availability.isEmpty) {
              return const SizedBox.shrink();
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Server Availability',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...res.availability.map((TracearrV2MediaAvailability avail) {
                  final String sizeStr = avail.fileSize != null
                      ? (avail.fileSize! / (1024 * 1024)).toStringAsFixed(0)
                      : '0';
                  return Card(
                    child: ListTile(
                      leading: Icon(
                        Icons.dns_outlined,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      title: Text(
                        'Server: ${avail.serverId}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        'Resolution: ${avail.videoResolution ?? "N/A"} • Size: $sizeStr MB',
                      ),
                    ),
                  );
                }),
              ],
            );
          },
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        ),
      ],
    );
  }
}

class _MediaStatCard extends StatelessWidget {
  const _MediaStatCard({
    required this.title,
    required this.plays,
    required this.watchTime,
  });

  final String title;
  final int plays;
  final String watchTime;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: <Widget>[
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              '$plays plays',
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            Text(
              watchTime,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Children Hierarchy Tab
// ---------------------------------------------------------------------------

class _MediaChildrenTab extends ConsumerWidget {
  const _MediaChildrenTab({
    required this.instance,
    required this.mediaRef,
  });

  final Instance instance;
  final String mediaRef;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<TracearrV2MediaChildrenResponse> childrenVal = ref.watch(
      tracearrV2MediaChildrenProvider((instance: instance, ref: mediaRef)),
    );

    return AsyncValueView<TracearrV2MediaChildrenResponse>(
      value: childrenVal,
      onRetry: () => ref.invalidate(
        tracearrV2MediaChildrenProvider((instance: instance, ref: mediaRef)),
      ),
      data: (TracearrV2MediaChildrenResponse resp) {
        final List<TracearrV2MediaChild> children = resp.data;

        if (children.isEmpty) {
          return const EmptyView(
            icon: Icons.account_tree_outlined,
            title: 'No Hierarchy Children',
            message: 'This media item has no sub-seasons or episodes.',
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: children.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (BuildContext context, int index) {
            final TracearrV2MediaChild child = children[index];
            return ListTile(
              leading: Icon(
                child.mediaType.toLowerCase() == 'season'
                    ? Icons.folder_outlined
                    : Icons.movie_outlined,
                color: Theme.of(context).colorScheme.primary,
              ),
              title: Text(
                child.title,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                child.seasonNumber != null
                    ? 'Season ${child.seasonNumber}'
                    : child.mediaType.toUpperCase(),
              ),
              trailing: child.episodeCount != null
                  ? Chip(
                      label: Text(
                        '${child.episodeCount} eps',
                        style: const TextStyle(fontSize: 10),
                      ),
                    )
                  : null,
            );
          },
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Top Watchers Tab
// ---------------------------------------------------------------------------

class _MediaWatchersTab extends ConsumerWidget {
  const _MediaWatchersTab({
    required this.instance,
    required this.mediaRef,
    required this.formatDuration,
  });

  final Instance instance;
  final String mediaRef;
  final String Function(int? seconds) formatDuration;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<TracearrV2MediaWatchersResponse> watchersVal = ref.watch(
      tracearrV2MediaWatchersProvider((instance: instance, ref: mediaRef)),
    );

    return AsyncValueView<TracearrV2MediaWatchersResponse>(
      value: watchersVal,
      onRetry: () => ref.invalidate(
        tracearrV2MediaWatchersProvider((instance: instance, ref: mediaRef)),
      ),
      data: (TracearrV2MediaWatchersResponse resp) {
        final List<TracearrV2Watcher> watchers = resp.watchers;

        if (watchers.isEmpty) {
          return const EmptyView(
            icon: Icons.people_outline,
            title: 'No Watchers Found',
            message: 'No user plays recorded for this item.',
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: watchers.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (BuildContext context, int index) {
            final TracearrV2Watcher watcher = watchers[index];
            final String name = watcher.user?.username ??
                watcher.user?.identityName ??
                'User ${watcher.user?.userId ?? ""}';

            return ListTile(
              leading: CircleAvatar(
                backgroundColor:
                    Theme.of(context).colorScheme.primaryContainer,
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              title: Text(
                name,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                '${watcher.plays} plays • ${formatDuration(watcher.watchTimeMs ~/ 1000)}',
              ),
              trailing: watcher.completionPct != null
                  ? Chip(
                      label: Text(
                        '${watcher.completionPct!.toStringAsFixed(0)}% watched',
                        style: const TextStyle(fontSize: 10),
                      ),
                    )
                  : null,
            );
          },
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// History Tab
// ---------------------------------------------------------------------------

class _MediaHistoryTab extends ConsumerWidget {
  const _MediaHistoryTab({
    required this.instance,
    required this.mediaRef,
    required this.formatDuration,
  });

  final Instance instance;
  final String mediaRef;
  final String Function(int? seconds) formatDuration;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<TracearrApi> apiVal = ref.watch(tracearrApiProvider(instance));

    return apiVal.when(
      data: (TracearrApi api) {
        return FutureBuilder<TracearrV2HistoryResponse>(
          future: api.getMediaHistory(mediaRef),
          builder: (
            BuildContext context,
            AsyncSnapshot<TracearrV2HistoryResponse> snapshot,
          ) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }

            final List<TracearrV2HistoryRecord> items =
                snapshot.data?.data ?? <TracearrV2HistoryRecord>[];

            if (items.isEmpty) {
              return const EmptyView(
                icon: Icons.history,
                title: 'No Media History',
                message: 'No watch history records found for this media item.',
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: items.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (BuildContext context, int index) {
                final TracearrV2HistoryRecord record = items[index];
                return ListTile(
                  title: Text(
                    record.userName ?? 'Unknown User',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    '${record.serverName ?? "Server"} • ${formatDuration(record.durationSeconds)}',
                  ),
                  trailing: Chip(
                    visualDensity: VisualDensity.compact,
                    side: BorderSide.none,
                    backgroundColor: record.completed == true
                        ? Theme.of(context)
                            .colorScheme
                            .primaryContainer
                            .withValues(alpha: 0.6)
                        : Theme.of(context)
                            .colorScheme
                            .surfaceContainerHigh,
                    label: Text(
                      record.completed == true ? 'Completed' : 'Partial',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: record.completed == true
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (Object e, _) => Center(child: Text('Error loading client: $e'),),
    );
  }
}
