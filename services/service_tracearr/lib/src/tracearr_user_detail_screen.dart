import 'package:core_models/core_models.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'models/tracearr_v2_models.dart';
import 'tracearr_api.dart';
import 'tracearr_providers.dart';

/// Screen displaying correlated identity details, linked media server accounts,
/// play statistics (All Time / 30 Days / 7 Days), top genres, and watch history.
class TracearrUserDetailScreen extends ConsumerStatefulWidget {
  const TracearrUserDetailScreen({
    required this.instance,
    required this.userId,
    required this.username,
    super.key,
  });

  final Instance instance;
  final String userId;
  final String username;

  @override
  ConsumerState<TracearrUserDetailScreen> createState() =>
      _TracearrUserDetailScreenState();
}

class _TracearrUserDetailScreenState
    extends ConsumerState<TracearrUserDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
    final AsyncValue<TracearrV2UserIdentity?> identityVal = ref.watch(
      tracearrV2UserByIdProvider(
        (instance: widget.instance, id: widget.userId),
      ),
    );
    final AsyncValue<TracearrV2UserStatsResponse?> statsVal = ref.watch(
      tracearrV2UserStatsProvider(
        (instance: widget.instance, id: widget.userId),
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.username),
        bottom: TabBar(
          controller: _tabController,
          tabs: const <Widget>[
            Tab(icon: Icon(Icons.analytics_outlined), text: 'Overview'),
            Tab(icon: Icon(Icons.history), text: 'History'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: <Widget>[
          _UserOverviewTab(
            instance: widget.instance,
            userId: widget.userId,
            username: widget.username,
            identityVal: identityVal,
            statsVal: statsVal,
            formatDuration: _formatDuration,
          ),
          _UserHistoryTab(
            instance: widget.instance,
            userId: widget.userId,
            formatDuration: _formatDuration,
          ),
        ],
      ),
    );
  }
}

class _UserOverviewTab extends StatelessWidget {
  const _UserOverviewTab({
    required this.instance,
    required this.userId,
    required this.username,
    required this.identityVal,
    required this.statsVal,
    required this.formatDuration,
  });

  final Instance instance;
  final String userId;
  final String username;
  final AsyncValue<TracearrV2UserIdentity?> identityVal;
  final AsyncValue<TracearrV2UserStatsResponse?> statsVal;
  final String Function(int? seconds) formatDuration;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        // User Identity Card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: <Widget>[
                CircleAvatar(
                  radius: 28,
                  backgroundColor:
                      Theme.of(context).colorScheme.primaryContainer,
                  child: Text(
                    username.isNotEmpty ? username[0].toUpperCase() : '?',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        username,
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      identityVal.when(
                        data: (TracearrV2UserIdentity? identity) {
                          if (identity == null) return const SizedBox.shrink();
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              if (identity.email != null &&
                                  identity.email!.isNotEmpty)
                                Text(
                                  identity.email!,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(color: Colors.grey),
                                ),
                              const SizedBox(height: 4),
                              Text(
                                '${identity.accounts.length} Linked Account${identity.accounts.length == 1 ? "" : "s"}',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
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
          ),
        ),

        const SizedBox(height: 16),

        // Linked Accounts Breakdown
        identityVal.when(
          data: (TracearrV2UserIdentity? identity) {
            if (identity == null || identity.accounts.isEmpty) {
              return const SizedBox.shrink();
            }
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Linked Media Server Accounts',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    ...identity.accounts.map((TracearrV2UserAccount account) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: <Widget>[
                            Icon(
                              account.serverType.toLowerCase() == 'plex'
                                  ? Icons.play_circle_fill
                                  : Icons.dns_outlined,
                              size: 20,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '${account.username} (${account.serverType.toUpperCase()})',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            Text(
                              account.externalUserId,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: Colors.grey),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            );
          },
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        ),

        const SizedBox(height: 16),

        // Play Stats Overview
        Text(
          'Play Statistics',
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),

        statsVal.when(
          data: (TracearrV2UserStatsResponse? stats) {
            if (stats == null) {
              return const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('No play statistics available for this user.'),
                ),
              );
            }

            final Map<String, dynamic>? windows = stats.windows;
            final Map<String, dynamic>? allTimeRaw =
                windows?['all_time'] as Map<String, dynamic>?;
            final Map<String, dynamic>? allTime =
                (allTimeRaw?['combined'] as Map<String, dynamic>?) ??
                    allTimeRaw;

            final Map<String, dynamic>? last30Raw =
                windows?['last_30'] as Map<String, dynamic>?;
            final Map<String, dynamic>? last30 =
                (last30Raw?['combined'] as Map<String, dynamic>?) ?? last30Raw;

            final Map<String, dynamic>? last7Raw =
                windows?['last_7'] as Map<String, dynamic>?;
            final Map<String, dynamic>? last7 =
                (last7Raw?['combined'] as Map<String, dynamic>?) ?? last7Raw;

            final int allTimePlays = (allTime?['plays'] as num?)?.toInt() ?? 0;
            final int allTimeWatchMs =
                (allTime?['watch_time_ms'] as num?)?.toInt() ?? 0;
            final int last30Plays = (last30?['plays'] as num?)?.toInt() ?? 0;
            final int last30WatchMs =
                (last30?['watch_time_ms'] as num?)?.toInt() ?? 0;
            final int last7Plays = (last7?['plays'] as num?)?.toInt() ?? 0;
            final int last7WatchMs =
                (last7?['watch_time_ms'] as num?)?.toInt() ?? 0;

            return Column(
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: _StatCard(
                        title: 'All Time',
                        plays: allTimePlays,
                        watchTime: formatDuration(allTimeWatchMs ~/ 1000),
                        icon: Icons.all_inclusive,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _StatCard(
                        title: 'Last 30 Days',
                        plays: last30Plays,
                        watchTime: formatDuration(last30WatchMs ~/ 1000),
                        icon: Icons.calendar_month_outlined,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _StatCard(
                        title: 'Last 7 Days',
                        plays: last7Plays,
                        watchTime: formatDuration(last7WatchMs ~/ 1000),
                        icon: Icons.date_range_outlined,
                      ),
                    ),
                  ],
                ),
                if (stats.topGenres.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'Top Genres',
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: stats.topGenres.map((genreItem) {
                              return Chip(
                                avatar: CircleAvatar(
                                  backgroundColor: Theme.of(context)
                                      .colorScheme
                                      .primaryContainer,
                                  child: Text(
                                    '${genreItem.plays}',
                                    style: const TextStyle(fontSize: 10),
                                  ),
                                ),
                                label: Text(genreItem.genre),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            );
          },
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (Object e, _) => Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Error loading stats: $e'),
            ),
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.plays,
    required this.watchTime,
    required this.icon,
  });

  final String title;
  final int plays;
  final String watchTime;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: <Widget>[
            Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 4),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
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

class _UserHistoryTab extends ConsumerWidget {
  const _UserHistoryTab({
    required this.instance,
    required this.userId,
    required this.formatDuration,
  });

  final Instance instance;
  final String userId;
  final String Function(int? seconds) formatDuration;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<TracearrApi> apiVal = ref.watch(tracearrApiProvider(instance));

    return apiVal.when(
      data: (TracearrApi api) {
        return FutureBuilder<TracearrV2HistoryResponse>(
          future: api.getUserHistory(userId),
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
                title: 'No Watch History',
                message: 'No plays recorded for this user yet.',
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
                    record.mediaTitle ?? 'Unknown Title',
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
