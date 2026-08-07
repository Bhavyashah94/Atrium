import 'package:cached_network_image/cached_network_image.dart';
import 'package:core_models/core_models.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'models/tracearr_active_sessions.dart';
import 'models/tracearr_session.dart';
import 'models/tracearr_v2_models.dart';
import 'tracearr_api.dart';
import 'tracearr_media_detail_screen.dart';
import 'tracearr_providers.dart';
import 'tracearr_user_detail_screen.dart';

/// Tracearr's per-instance UI: Activity (live streams), History, Users, and
/// Libraries tabs - all poster-rich and aligned with Atrium standards.
class TracearrHome extends StatelessWidget {
  const TracearrHome({required this.instance, super.key});

  final Instance instance;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Column(
        children: <Widget>[
          const TabBar(
            tabs: <Widget>[
              Tab(icon: Icon(Icons.play_circle_outline), text: 'Activity'),
              Tab(icon: Icon(Icons.history), text: 'History'),
              Tab(icon: Icon(Icons.people_alt_outlined), text: 'Users'),
              Tab(icon: Icon(Icons.video_library_outlined), text: 'Libraries'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: <Widget>[
                _ActivityTab(instance: instance),
                _HistoryTab(instance: instance),
                _UsersTab(instance: instance),
                _LibrariesTab(instance: instance),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Activity / Live Streams
// ---------------------------------------------------------------------------

class _ActivityTab extends ConsumerWidget {
  const _ActivityTab({required this.instance});

  final Instance instance;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<TracearrActiveSessions> activeVal =
        ref.watch(tracearrActiveSessionsProvider(instance));
    final TracearrApi? api = ref.watch(tracearrApiProvider(instance)).value;

    return AsyncValueView<TracearrActiveSessions>(
      value: activeVal,
      onRetry: () => ref.invalidate(tracearrActiveSessionsProvider(instance)),
      data: (TracearrActiveSessions active) {
        final List<TracearrSession> sessions = active.sessions;

        if (sessions.isEmpty) {
          return EasyRefresh(
            header: const ClassicHeader(
              dragText: 'Pull to refresh',
              armedText: 'Release ready',
              readyText: 'Refreshing...',
              processingText: 'Refreshing...',
              processedText: 'Succeeded',
              failedText: 'Failed',
              messageText: 'Last updated at %T',
            ),
            onRefresh: () async =>
                ref.invalidate(tracearrActiveSessionsProvider(instance)),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const <Widget>[
                SizedBox(height: 100),
                EmptyView(
                  icon: Icons.podcasts_outlined,
                  title: 'Nothing playing',
                  message: 'No active streams right now.',
                ),
              ],
            ),
          );
        }

        return EasyRefresh(
          header: const ClassicHeader(
            dragText: 'Pull to refresh',
            armedText: 'Release ready',
            readyText: 'Refreshing...',
            processingText: 'Refreshing...',
            processedText: 'Succeeded',
            failedText: 'Failed',
            messageText: 'Last updated at %T',
          ),
          onRefresh: () async =>
              ref.invalidate(tracearrActiveSessionsProvider(instance)),
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: sessions.length,
            itemBuilder: (BuildContext context, int index) {
              final TracearrSession session = sessions[index];
              final double progress =
                  (session.progressMs / 100000).clamp(0.0, 1.0);
              final String? posterUrl = api?.imageUrl(session.thumbPath);

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      if (posterUrl != null && posterUrl.isNotEmpty)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: CachedNetworkImage(
                            imageUrl: posterUrl,
                            width: 65,
                            height: 95,
                            fit: BoxFit.cover,
                            errorWidget: (_, __, ___) => Container(
                              width: 65,
                              height: 95,
                              color: Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHigh,
                              child: const Icon(Icons.movie, size: 32),
                            ),
                          ),
                        )
                      else
                        Container(
                          width: 65,
                          height: 95,
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .surfaceContainerHigh,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(Icons.movie, size: 32),
                        ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              session.mediaTitle,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (session.grandparentTitle != null &&
                                session.grandparentTitle!.isNotEmpty) ...<Widget>[
                              const SizedBox(height: 2),
                              Text(
                                session.grandparentTitle!,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                    ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                            const SizedBox(height: 6),
                            Row(
                              children: <Widget>[
                                Icon(
                                  Icons.person_outline,
                                  size: 14,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  session.userName ?? 'User',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${session.playerName} • ${session.platform}',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: Colors.grey),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            LinearProgressIndicator(
                              value: progress,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Watch History
// ---------------------------------------------------------------------------

class _HistoryTab extends ConsumerWidget {
  const _HistoryTab({required this.instance});

  final Instance instance;

  String _formatDuration(int? seconds) {
    if (seconds == null || seconds <= 0) return '0m';
    final int hours = seconds ~/ 3600;
    final int minutes = (seconds % 3600) ~/ 60;
    if (hours > 0) return '${hours}h ${minutes}m';
    return '${minutes}m';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<TracearrV2HistoryResponse> historyVal =
        ref.watch(tracearrV2HistoryProvider(instance));
    final TracearrApi? api = ref.watch(tracearrApiProvider(instance)).value;

    return AsyncValueView<TracearrV2HistoryResponse>(
      value: historyVal,
      onRetry: () => ref.invalidate(tracearrV2HistoryProvider(instance)),
      data: (TracearrV2HistoryResponse history) {
        final List<TracearrV2HistoryRecord> items = history.data;

        if (items.isEmpty) {
          return EasyRefresh(
            header: const ClassicHeader(
              dragText: 'Pull to refresh',
              armedText: 'Release ready',
              readyText: 'Refreshing...',
              processingText: 'Refreshing...',
              processedText: 'Succeeded',
              failedText: 'Failed',
              messageText: 'Last updated at %T',
            ),
            onRefresh: () async =>
                ref.invalidate(tracearrV2HistoryProvider(instance)),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const <Widget>[
                SizedBox(height: 100),
                EmptyView(
                  icon: Icons.history,
                  title: 'No watch history',
                  message: 'No completed or logged streams yet.',
                ),
              ],
            ),
          );
        }

        return EasyRefresh(
          header: const ClassicHeader(
            dragText: 'Pull to refresh',
            armedText: 'Release ready',
            readyText: 'Refreshing...',
            processingText: 'Refreshing...',
            processedText: 'Succeeded',
            failedText: 'Failed',
            messageText: 'Last updated at %T',
          ),
          onRefresh: () async =>
              ref.invalidate(tracearrV2HistoryProvider(instance)),
          child: ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: items.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (BuildContext context, int index) {
              final TracearrV2HistoryRecord record = items[index];
              final String? posterUrl = api?.imageUrl(record.posterUrl);

              return ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                onTap: () {
                  final String mediaRef = record.mediaId != null &&
                          record.mediaId!.isNotEmpty
                      ? record.mediaId!
                      : (record.tmdbId != null
                          ? '${record.mediaType ?? "movie"}:tmdb:${record.tmdbId}'
                          : (record.imdbId != null && record.imdbId!.isNotEmpty
                              ? '${record.mediaType ?? "movie"}:imdb:${record.imdbId}'
                              : (record.tvdbId != null
                                  ? '${record.mediaType ?? "movie"}:tvdb:${record.tvdbId}'
                                  : record.id)));
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => TracearrMediaDetailScreen(
                        instance: instance,
                        mediaRef: mediaRef,
                        title: record.mediaTitle ?? 'Media Details',
                        posterUrl: record.posterUrl,
                      ),
                    ),
                  );
                },
                leading: posterUrl != null && posterUrl.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: CachedNetworkImage(
                          imageUrl: posterUrl,
                          width: 44,
                          height: 66,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) =>
                              const Icon(Icons.movie, size: 28),
                        ),
                      )
                    : const Icon(Icons.movie, size: 28),
                title: Text(
                  record.mediaTitle ?? 'Unknown Title',
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const SizedBox(height: 2),
                    Text(
                      '${record.userName ?? "User"} • ${_formatDuration(record.durationSeconds)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    if (record.serverName != null) ...<Widget>[
                      const SizedBox(height: 2),
                      Text(
                        record.serverName!,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: Colors.grey),
                      ),
                    ],
                  ],
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
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// User Roster
// ---------------------------------------------------------------------------

class _UsersTab extends ConsumerWidget {
  const _UsersTab({required this.instance});

  final Instance instance;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<TracearrV2UsersResponse> usersVal =
        ref.watch(tracearrV2UsersProvider(instance));

    return AsyncValueView<TracearrV2UsersResponse>(
      value: usersVal,
      onRetry: () => ref.invalidate(tracearrV2UsersProvider(instance)),
      data: (TracearrV2UsersResponse resp) {
        final List<TracearrV2UserIdentity> users = resp.data;

        if (users.isEmpty) {
          return EasyRefresh(
            header: const ClassicHeader(
              dragText: 'Pull to refresh',
              armedText: 'Release ready',
              readyText: 'Refreshing...',
              processingText: 'Refreshing...',
              processedText: 'Succeeded',
              failedText: 'Failed',
              messageText: 'Last updated at %T',
            ),
            onRefresh: () async =>
                ref.invalidate(tracearrV2UsersProvider(instance)),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const <Widget>[
                SizedBox(height: 100),
                EmptyView(
                  icon: Icons.people_outline,
                  title: 'No users found',
                  message: 'No users registered on this server.',
                ),
              ],
            ),
          );
        }

        return EasyRefresh(
          header: const ClassicHeader(
            dragText: 'Pull to refresh',
            armedText: 'Release ready',
            readyText: 'Refreshing...',
            processingText: 'Refreshing...',
            processedText: 'Succeeded',
            failedText: 'Failed',
            messageText: 'Last updated at %T',
          ),
          onRefresh: () async =>
              ref.invalidate(tracearrV2UsersProvider(instance)),
          child: ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: users.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (BuildContext context, int index) {
              final TracearrV2UserIdentity user = users[index];
              final String subtitleText = user.email != null && user.email!.isNotEmpty
                  ? user.email!
                  : '${user.accounts.length} linked account${user.accounts.length == 1 ? "" : "s"}';

              return ListTile(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => TracearrUserDetailScreen(
                        instance: instance,
                        userId: user.id,
                        username: user.username,
                      ),
                    ),
                  );
                },
                leading: CircleAvatar(
                  backgroundColor:
                      Theme.of(context).colorScheme.primaryContainer,
                  child: Text(
                    user.username.isNotEmpty
                        ? user.username[0].toUpperCase()
                        : '?',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(
                  user.username,
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  subtitleText,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                trailing: const Icon(Icons.chevron_right),
              );
            },
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Libraries & Recently Added
// ---------------------------------------------------------------------------

class _LibrariesTab extends ConsumerWidget {
  const _LibrariesTab({required this.instance});

  final Instance instance;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<TracearrV2LibrariesResponse> librariesVal =
        ref.watch(tracearrV2LibrariesProvider(instance));
    final AsyncValue<TracearrV2RecentlyAddedResponse> recentVal =
        ref.watch(tracearrV2RecentlyAddedProvider(instance));
    final TracearrApi? api = ref.watch(tracearrApiProvider(instance)).value;

    final bool libsEmpty = librariesVal.value?.data.isEmpty ?? true;
    final bool recentEmpty = recentVal.value?.data.isEmpty ?? true;

    if (libsEmpty &&
        recentEmpty &&
        !librariesVal.isLoading &&
        !recentVal.isLoading) {
      return EasyRefresh(
        header: const ClassicHeader(
          dragText: 'Pull to refresh',
          armedText: 'Release ready',
          readyText: 'Refreshing...',
          processingText: 'Refreshing...',
          processedText: 'Succeeded',
          failedText: 'Failed',
          messageText: 'Last updated at %T',
        ),
        onRefresh: () async {
          ref.invalidate(tracearrV2LibrariesProvider(instance));
          ref.invalidate(tracearrV2RecentlyAddedProvider(instance));
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const <Widget>[
            SizedBox(height: 100),
            EmptyView(
              icon: Icons.video_library_outlined,
              title: 'No media libraries',
              message:
                  'Connect a media server in Tracearr to sync libraries and items.',
            ),
          ],
        ),
      );
    }

    return EasyRefresh(
      header: const ClassicHeader(
        dragText: 'Pull to refresh',
        armedText: 'Release ready',
        readyText: 'Refreshing...',
        processingText: 'Refreshing...',
        processedText: 'Succeeded',
        failedText: 'Failed',
        messageText: 'Last updated at %T',
      ),
      onRefresh: () async {
        ref.invalidate(tracearrV2LibrariesProvider(instance));
        ref.invalidate(tracearrV2RecentlyAddedProvider(instance));
      },
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: <Widget>[
          Text(
            'Libraries',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          AsyncValueView<TracearrV2LibrariesResponse>(
            value: librariesVal,
            onRetry: () =>
                ref.invalidate(tracearrV2LibrariesProvider(instance)),
            data: (TracearrV2LibrariesResponse resp) {
              final List<TracearrV2Library> libs = resp.data;
              if (libs.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'No libraries configured.',
                    style: TextStyle(color: Colors.grey),
                  ),
                );
              }
              return Column(
                children: libs.map((TracearrV2Library lib) {
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      lib.type.toLowerCase() == 'movie'
                          ? Icons.movie_outlined
                          : Icons.tv_outlined,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    title: Text(
                      lib.name,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text('${lib.type} • ${lib.itemCount ?? 0} items'),
                  );
                }).toList(),
              );
            },
          ),
          const SizedBox(height: 20),
          Text(
            'Recently Added',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          AsyncValueView<TracearrV2RecentlyAddedResponse>(
            value: recentVal,
            onRetry: () =>
                ref.invalidate(tracearrV2RecentlyAddedProvider(instance)),
            data: (TracearrV2RecentlyAddedResponse resp) {
              final List<TracearrV2RecentlyAddedItem> recent = resp.data;
              if (recent.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'No recently added media.',
                    style: TextStyle(color: Colors.grey),
                  ),
                );
              }
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 0.67,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: recent.length,
                itemBuilder: (BuildContext context, int index) {
                  final TracearrV2RecentlyAddedItem item = recent[index];
                  final String? posterUrl = api?.imageUrl(item.posterUrl);
                  return GestureDetector(
                    onTap: () {
                      final String mediaRef = item.mediaId != null &&
                              item.mediaId!.isNotEmpty
                          ? item.mediaId!
                          : (item.tmdbId != null
                              ? '${item.type}:tmdb:${item.tmdbId}'
                              : (item.imdbId != null && item.imdbId!.isNotEmpty
                                  ? '${item.type}:imdb:${item.imdbId}'
                                  : (item.tvdbId != null
                                      ? '${item.type}:tvdb:${item.tvdbId}'
                                      : item.id)));
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => TracearrMediaDetailScreen(
                            instance: instance,
                            mediaRef: mediaRef,
                            title: item.title,
                            posterUrl: item.posterUrl,
                          ),
                        ),
                      );
                    },
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: posterUrl != null && posterUrl.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: posterUrl,
                              fit: BoxFit.cover,
                              errorWidget: (_, __, ___) => Container(
                                color: Theme.of(context)
                                    .colorScheme
                                    .surfaceContainerHigh,
                                child: Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(4),
                                    child: Text(
                                      item.title,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(fontSize: 10),
                                    ),
                                  ),
                                ),
                              ),
                            )
                          : Container(
                              color: Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHigh,
                              child: Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(4),
                                  child: Text(
                                    item.title,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(fontSize: 10),
                                  ),
                                ),
                              ),
                            ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
