import 'package:cached_network_image/cached_network_image.dart';
import 'package:core_models/core_models.dart';
import 'package:core_ui/core_ui.dart' hide EasyRefresh, ClassicHeader, HeaderLocator;
import 'package:easy_refresh/easy_refresh.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'models/tracearr_v2_models.dart';
import 'tracearr_api.dart';
import 'tracearr_media_detail_screen.dart';
import 'tracearr_providers.dart';
import 'utils/tracearr_formatters.dart';
import 'widgets/tracearr_user_avatar.dart';

/// Gold-standard Tracearr 2.0 user detail screen matching Sonarr/Radarr Atrium design architecture.
/// Features a hero profile card, executive watch metrics bar, connected server accounts matrix,
/// top genres preference chips, dynamically generated media category filters, zero-lag skeleton history,
/// and full inter-screen navigation.
class TracearrV2UserDetailScreen extends ConsumerStatefulWidget {
  const TracearrV2UserDetailScreen({
    required this.instance,
    required this.userId,
    super.key,
  });

  final Instance instance;
  final String userId;

  @override
  ConsumerState<TracearrV2UserDetailScreen> createState() =>
      _TracearrV2UserDetailScreenState();
}

class _TracearrV2UserDetailScreenState
    extends ConsumerState<TracearrV2UserDetailScreen> {
  final ScrollController _scrollController = ScrollController();
  final ValueNotifier<bool> _showBackToTop = ValueNotifier<bool>(false);
  String _selectedCategoryFilter = 'ALL';
  String _selectedGenreFilter = 'ALL';

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
  }

  void _scrollListener() {
    final double threshold = MediaQuery.sizeOf(context).height * 0.4;
    if (_scrollController.hasClients &&
        _scrollController.offset >= threshold) {
      if (!_showBackToTop.value) {
        _showBackToTop.value = true;
      }
    } else {
      if (_showBackToTop.value) {
        _showBackToTop.value = false;
      }
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    _showBackToTop.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    ref.invalidate(
      tracearrV2GetUserByIdProvider(
        (instance: widget.instance, id: widget.userId),
      ),
    );
    ref.invalidate(
      tracearrV2GetUserStatsProvider(
        (instance: widget.instance, id: widget.userId),
      ),
    );
    ref.invalidate(
      tracearrV2GetUserHistoryProvider(
        (instance: widget.instance, id: widget.userId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AsyncValue<TracearrV2UserIdentity?> asyncUser = ref.watch(
      tracearrV2GetUserByIdProvider(
        (instance: widget.instance, id: widget.userId),
      ),
    );
    final AsyncValue<TracearrV2UserStatsResponse?> asyncStats = ref.watch(
      tracearrV2GetUserStatsProvider(
        (instance: widget.instance, id: widget.userId),
      ),
    );
    final AsyncValue<TracearrV2HistoryResponse> asyncHistory = ref.watch(
      tracearrV2GetUserHistoryProvider(
        (instance: widget.instance, id: widget.userId),
      ),
    );

    return asyncUser.when(
      data: (TracearrV2UserIdentity? user) {
        if (user == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('User Details')),
            body: const Center(child: Text('User identity not found.')),
          );
        }

        final Map<String, String> serverMap =
            ref.watch(tracearrServerNamesMapProvider(widget.instance));
        final Map<String, String> avatarMap =
            ref.watch(tracearrUserAvatarsMapProvider(widget.instance));
        final TracearrApi? api =
            ref.watch(tracearrApiProvider(widget.instance)).value;
        final String username = user.username ?? 'Unknown User';
        final String? rawAvatarPath = user.id != null ? avatarMap[user.id!] : null;
        final String? avatarUrl = api?.imageUrl(rawAvatarPath);

        // Derive dynamic categories from actual history records
        final Set<String> availableTypes = asyncHistory.maybeWhen(
          data: (TracearrV2HistoryResponse h) => h.data
              .map((TracearrV2HistoryRecord r) => (r.mediaType ?? '').toUpperCase())
              .where((String t) => t.isNotEmpty)
              .toSet(),
          orElse: () => <String>{},
        );

        final List<({String key, String label})> filterOptions = <({String key, String label})>[
          (key: 'ALL', label: 'All Categories'),
          if (availableTypes.contains('MOVIE')) (key: 'MOVIE', label: 'Movies'),
          if (availableTypes.contains('SHOW') || availableTypes.contains('EPISODE'))
            (key: 'SHOW', label: 'Shows'),
          if (availableTypes.contains('TRACK')) (key: 'TRACK', label: 'Music'),
        ];

        // Derive dynamic genres from actual history records
        final Set<String> availableGenres = asyncHistory.maybeWhen(
          data: (TracearrV2HistoryResponse h) => h.data
              .expand((TracearrV2HistoryRecord r) => r.genres)
              .where((String g) => g.trim().isNotEmpty)
              .toSet(),
          orElse: () => <String>{},
        );

        final List<String> genreOptions = <String>[
          'ALL',
          ...availableGenres.toList()..sort(),
        ];

        return Scaffold(
          floatingActionButton: ValueListenableBuilder<bool>(
            valueListenable: _showBackToTop,
            builder: (BuildContext context, bool show, Widget? child) {
              return AnimatedOpacity(
                opacity: show ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                child: Visibility(
                  visible: show,
                  child: FloatingActionButton.small(
                    heroTag: 'tracearr_user_detail_back_to_top',
                    onPressed: () {
                      _scrollController.animateTo(
                        0.0,
                        duration: const Duration(milliseconds: 350),
                        curve: Curves.easeOutCubic,
                      );
                    },
                    child: const Icon(Icons.arrow_upward),
                  ),
                ),
              );
            },
          ),
          body: EasyRefresh(
            header: const ClassicHeader(
              position: IndicatorPosition.locator,
            ),
            onRefresh: _refresh,
            child: CustomScrollView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: <Widget>[
                // Minimal Sliver Header
                SliverAppBar(
                  expandedHeight: 200.0,
                  pinned: true,
                  title: CollapsedTitle(
                    controller: _scrollController,
                    title: username,
                  ),
                  flexibleSpace: FlexibleSpaceBar(
                    background: _UserProfileHeader(
                      username: username,
                      email: user.email,
                      avatarUrl: avatarUrl,
                      accountCount: user.accounts.length,
                    ),
                  ),
                  actions: <Widget>[
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      tooltip: 'Refresh',
                      onPressed: _refresh,
                    ),
                  ],
                ),
                const HeaderLocator.sliver(),
                SliverPadding(
                  padding: const EdgeInsets.all(16.0),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate(
                      <Widget>[
                        // Overview Metrics Bar & Top Genres
                        _UserStatsCard(
                          asyncStats: asyncStats,
                          accountCount: user.accounts.length,
                        ),
                        const SizedBox(height: 20),

                        // Connected Server Accounts Matrix
                        _ConnectedAccountsSection(
                          accounts: user.accounts,
                          serverMap: serverMap,
                        ),
                        const SizedBox(height: 24),

                        // Watch History Section Header
                        Text(
                          'Watch History',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Dynamic Category Filter Chips
                        if (filterOptions.length > 1) ...<Widget>[
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: filterOptions.map((({String key, String label}) filter) {
                                final bool isSelected =
                                    _selectedCategoryFilter == filter.key;
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8.0),
                                  child: ChoiceChip(
                                    visualDensity: VisualDensity.compact,
                                    label: Text(filter.label),
                                    selected: isSelected,
                                    onSelected: (bool selected) {
                                      if (selected) {
                                        setState(() {
                                          _selectedCategoryFilter = filter.key;
                                        });
                                      }
                                    },
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],

                        // Genre Filter Chips
                        if (genreOptions.length > 1) ...<Widget>[
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: genreOptions.map((String genre) {
                                final bool isSelected =
                                    _selectedGenreFilter.toUpperCase() ==
                                        genre.toUpperCase();
                                final String label =
                                    genre == 'ALL' ? 'All Genres' : genre;
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8.0),
                                  child: ChoiceChip(
                                    visualDensity: VisualDensity.compact,
                                    backgroundColor:
                                        theme.colorScheme.surfaceContainerHigh,
                                    label: Text(label),
                                    selected: isSelected,
                                    onSelected: (bool selected) {
                                      if (selected) {
                                        setState(() {
                                          _selectedGenreFilter = genre;
                                        });
                                      }
                                    },
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],

                        // Watch History List with Skeleton Loader
                        _UserWatchHistorySection(
                          instance: widget.instance,
                          asyncHistory: asyncHistory,
                          serverMap: serverMap,
                          api: api,
                          categoryFilter: _selectedCategoryFilter,
                          genreFilter: _selectedGenreFilter,
                        ),
                        const SizedBox(height: 80),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('Loading User...')),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (Object e, StackTrace s) => Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(
                Icons.error_outline,
                size: 56,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(e.toString()),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _refresh,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// User Profile Header Widget
// ---------------------------------------------------------------------------

class _UserProfileHeader extends StatelessWidget {
  const _UserProfileHeader({
    required this.username,
    required this.email,
    required this.avatarUrl,
    required this.accountCount,
  });

  final String username;
  final String? email;
  final String? avatarUrl;
  final int accountCount;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            theme.colorScheme.primaryContainer.withValues(alpha: 0.6),
            theme.colorScheme.surface,
          ],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              TracearrUserAvatar(
                username: username,
                avatarUrl: avatarUrl,
                radius: 36,
                fontSize: 26,
              ),
              const SizedBox(height: 8),
              Text(
                username,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (email != null && email!.trim().isNotEmpty) ...<Widget>[
                const SizedBox(height: 2),
                Text(
                  email!.trim(),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// User Stats & Top Genres Card
// ---------------------------------------------------------------------------

class _UserStatsCard extends StatelessWidget {
  const _UserStatsCard({
    required this.asyncStats,
    required this.accountCount,
  });

  final AsyncValue<TracearrV2UserStatsResponse?> asyncStats;
  final int accountCount;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return asyncStats.when(
      data: (TracearrV2UserStatsResponse? stats) {
        final int genreCount = stats?.topGenres.length ?? 0;

        return Card(
          elevation: 0,
          color: theme.colorScheme.surfaceContainerHigh,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Watch Overview',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: <Widget>[
                    Column(
                      children: <Widget>[
                        Icon(
                          Icons.category_outlined,
                          size: 22,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$genreCount',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          'Top Genres',
                          style: theme.textTheme.bodySmall?.copyWith(fontSize: 11),
                        ),
                      ],
                    ),
                    Column(
                      children: <Widget>[
                        Icon(
                          Icons.dns_outlined,
                          size: 22,
                          color: theme.colorScheme.secondary,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$accountCount',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          'Linked Servers',
                          style: theme.textTheme.bodySmall?.copyWith(fontSize: 11),
                        ),
                      ],
                    ),
                  ],
                ),
                if (stats != null && stats.topGenres.isNotEmpty) ...<Widget>[
                  const Divider(height: 24),
                  Text(
                    'Top Genres Preference',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: stats.topGenres.map((TracearrV2UserGenre g) {
                      final String label = g.genre ?? 'Genre';
                      final int? count = g.plays;
                      return Chip(
                        visualDensity: VisualDensity.compact,
                        backgroundColor: theme.colorScheme.surfaceContainerHighest,
                        label: Text(
                          count != null ? '$label ($count plays)' : label,
                          style: const TextStyle(fontSize: 11),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
        );
      },
      loading: () => Card(
        elevation: 0,
        color: theme.colorScheme.surfaceContainerHigh.withValues(alpha: 0.4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const SizedBox(
          height: 80,
          child: Center(
            child: SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

// ---------------------------------------------------------------------------
// Connected Accounts Matrix Section
// ---------------------------------------------------------------------------

class _ConnectedAccountsSection extends StatelessWidget {
  const _ConnectedAccountsSection({
    required this.accounts,
    required this.serverMap,
  });

  final List<TracearrV2UserAccount> accounts;
  final Map<String, String> serverMap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    if (accounts.isEmpty) {
      return Card(
        elevation: 0,
        color: theme.colorScheme.surfaceContainerHigh,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: const Padding(
          padding: EdgeInsets.all(16.0),
          child: Row(
            children: <Widget>[
              Icon(Icons.info_outline, size: 20),
              SizedBox(width: 12),
              Text('No connected server accounts found.'),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Connected Accounts (${accounts.length})',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        ...accounts.map((TracearrV2UserAccount account) {
          final String accountServer = resolveServerName(
            serverMap: serverMap,
            serverId: account.serverId,
            serverType: account.serverType,
          );
          return Card(
            elevation: 0,
            margin: const EdgeInsets.only(bottom: 8),
            color: theme.colorScheme.surfaceContainerHigh,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: const CircleAvatar(
                child: Icon(Icons.dns_outlined, size: 18),
              ),
              title: Text(
                account.username ?? 'Account',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text('Server: $accountServer'),
              trailing: Chip(
                visualDensity: VisualDensity.compact,
                backgroundColor: theme.colorScheme.primaryContainer,
                label: Text(
                  (account.serverType ?? 'Media Server').toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// User Watch History Section with Skeleton Loader & Inter-Screen Navigation
// ---------------------------------------------------------------------------

class _UserWatchHistorySection extends StatelessWidget {
  const _UserWatchHistorySection({
    required this.instance,
    required this.asyncHistory,
    required this.serverMap,
    required this.api,
    required this.categoryFilter,
    required this.genreFilter,
  });

  final Instance instance;
  final AsyncValue<TracearrV2HistoryResponse> asyncHistory;
  final Map<String, String> serverMap;
  final TracearrApi? api;
  final String categoryFilter;
  final String genreFilter;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return asyncHistory.when(
      data: (TracearrV2HistoryResponse history) {
        final List<TracearrV2HistoryRecord> allItems = history.data;

        final List<TracearrV2HistoryRecord> items = allItems.where((TracearrV2HistoryRecord r) {
          if (categoryFilter != 'ALL') {
            final String type = (r.mediaType ?? '').toUpperCase();
            if (categoryFilter == 'SHOW' && type != 'SHOW' && type != 'EPISODE') {
              return false;
            }
            if (categoryFilter != 'SHOW' && type != categoryFilter) {
              return false;
            }
          }
          if (genreFilter != 'ALL' &&
              !r.genres.any((String g) => g.toUpperCase() == genreFilter.toUpperCase())) {
            return false;
          }
          return true;
        }).toList();

        if (items.isEmpty) {
          return Card(
            elevation: 0,
            color: theme.colorScheme.surfaceContainerHigh,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: const Padding(
              padding: EdgeInsets.all(24.0),
              child: Center(child: Text('No watch history recorded for this category.')),
            ),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          itemBuilder: (BuildContext context, int index) {
            final TracearrV2HistoryRecord record = items[index];
            final String displayTitle;
            final String? secondaryTitle;

            if (record.mediaType == 'episode' &&
                record.showTitle != null &&
                record.showTitle!.trim().isNotEmpty) {
              displayTitle = record.showTitle!.trim();
              final String epPrefix = formatTracearrSeasonEpisode(
                record.seasonNumber,
                record.episodeNumber,
              );
              final String epName = record.mediaTitle ?? '';
              secondaryTitle = epPrefix.isNotEmpty && epName.isNotEmpty
                  ? '$epPrefix • $epName'
                  : (epPrefix.isNotEmpty ? epPrefix : epName);
            } else if (record.mediaType == 'track' &&
                record.artistName != null &&
                record.artistName!.trim().isNotEmpty) {
              displayTitle = record.mediaTitle ?? 'Untitled Track';
              secondaryTitle = record.albumName != null
                  ? '${record.artistName} • ${record.albumName}'
                  : record.artistName;
            } else {
              displayTitle = record.mediaTitle ?? record.showTitle ?? 'Untitled';
              secondaryTitle = null;
            }

            final String? posterUrl = api?.imageUrl(
              record.posterUrl ?? record.thumbPath,
            );
            final String? mediaRef =
                record.mediaId ?? record.ratingKey ?? record.id;
            final bool completed = record.effectiveCompleted;
            final String serverDisplayName = resolveServerName(
              serverMap: serverMap,
              serverName: record.serverName,
              serverId: record.serverId,
              serverType: record.serverType,
            );

            final String formattedTime = formatTracearrTimestamp(
              record.startedAt ?? record.stoppedAt,
            );
            final int durationMs = record.durationMs ?? 0;
            final double percent = record.percentComplete ??
                ((record.progressMs != null &&
                        record.totalDurationMs != null &&
                        record.totalDurationMs! > 0)
                    ? (record.progressMs! / record.totalDurationMs! * 100)
                    : (record.effectiveCompleted ? 100.0 : 0.0));
            final String durationText = durationMs > 0
                ? '${(durationMs / 60000).toStringAsFixed(1)}m'
                : '';
            final String percentText =
                percent > 0 ? '${percent.toStringAsFixed(0)}%' : '';

            final String subtitleDetails = <String>[
              serverDisplayName,
              if (formattedTime.isNotEmpty) formattedTime,
              if (durationText.isNotEmpty) '$durationText watched',
              if (percentText.isNotEmpty) percentText,
            ].join(' • ');

            return Card(
              elevation: 0,
              margin: const EdgeInsets.only(bottom: 8),
              color: theme.colorScheme.surfaceContainerHigh,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                leading: posterUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: SizedBox(
                          width: 44,
                          height: 66,
                          child: CachedNetworkImage(
                            imageUrl: posterUrl,
                            fit: BoxFit.cover,
                            errorWidget: (_, __, ___) =>
                                const Icon(Icons.movie_outlined),
                          ),
                        ),
                      )
                    : Container(
                        width: 44,
                        height: 66,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(
                          Icons.play_circle_outline,
                          size: 24,
                        ),
                      ),
                title: Text(
                  displayTitle,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    if (secondaryTitle != null &&
                        secondaryTitle.isNotEmpty) ...<Widget>[
                      const SizedBox(height: 1),
                      Text(
                        secondaryTitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 2),
                    Text(
                      subtitleDetails,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
                trailing: Icon(
                  completed
                      ? Icons.check_circle
                      : Icons.play_circle_filled,
                  size: 20,
                  color: completed
                      ? theme.colorScheme.primary
                      : theme.colorScheme.tertiary,
                ),
                onTap: mediaRef != null
                    ? () => Navigator.of(context, rootNavigator: true).push(
                          MaterialPageRoute<void>(
                            builder: (_) => TracearrV2MediaDetailScreen(
                              instance: instance,
                              mediaRef: mediaRef,
                            ),
                          ),
                        )
                    : null,
              ),
            );
          },
        );
      },
      loading: () => Column(
        children: List<Widget>.generate(3, (int i) {
          return Card(
            elevation: 0,
            margin: const EdgeInsets.only(bottom: 8),
            color: theme.colorScheme.surfaceContainerHigh.withValues(alpha: 0.4),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: const SizedBox(
              height: 72,
              child: Center(
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
          );
        }),
      ),
      error: (Object e, StackTrace s) => Center(child: Text(e.toString())),
    );
  }
}
