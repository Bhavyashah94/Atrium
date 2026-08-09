import 'package:cached_network_image/cached_network_image.dart';
import 'package:core_models/core_models.dart';
import 'package:easy_refresh/easy_refresh.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/tracearr_v2_models.dart';
import '../tracearr_api.dart';
import '../tracearr_providers.dart';
import '../utils/tracearr_formatters.dart';
import '../widgets/tracearr_session_detail_bottom_sheet.dart';
import '../widgets/tracearr_user_avatar.dart';

/// History tab with search bar, dual filters (Type & Status), relative timestamps, and Sonarr-style history cards.
class TracearrHistoryTab extends ConsumerStatefulWidget {
  const TracearrHistoryTab({
    required this.instance,
    super.key,
  });

  final Instance instance;

  @override
  ConsumerState<TracearrHistoryTab> createState() => _TracearrHistoryTabState();
}

class _TracearrHistoryTabState extends ConsumerState<TracearrHistoryTab>
    with WidgetsBindingObserver {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  double _lastBottomInset = 0;

  final List<TracearrV2HistoryRecord> _appendedRecords = <TracearrV2HistoryRecord>[];
  String? _nextCursor;
  bool _hasMore = true;
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    final double bottomInset =
        WidgetsBinding.instance.platformDispatcher.views.first.viewInsets.bottom;
    if (bottomInset == 0 && _lastBottomInset > 0) {
      if (_searchFocusNode.hasFocus) {
        _searchFocusNode.unfocus();
      }
    }
    _lastBottomInset = bottomInset;
  }

  void _onScroll() {
    if (_scrollController.hasClients &&
        _scrollController.position.userScrollDirection != ScrollDirection.idle) {
      if (_searchFocusNode.hasFocus) {
        _searchFocusNode.unfocus();
      }
    }
  }

  Future<void> _loadNextPage() async {
    if (_isLoadingMore || !_hasMore || _nextCursor == null || _nextCursor!.isEmpty) {
      return;
    }
    setState(() {
      _isLoadingMore = true;
    });

    try {
      final TracearrApi api =
          await ref.read(tracearrApiProvider(widget.instance).future);
      final TracearrV2HistoryResponse nextResp =
          await api.getHistory(cursor: _nextCursor, pageSize: 100);

      setState(() {
        _appendedRecords.addAll(nextResp.data);
        _nextCursor = nextResp.meta?.nextCursor;
        _hasMore = nextResp.meta?.nextCursor != null &&
            nextResp.meta!.nextCursor!.isNotEmpty;
        _isLoadingMore = false;
      });
    } catch (_) {
      setState(() {
        _isLoadingMore = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AsyncValue<TracearrV2HistoryResponse> asyncHistory =
        ref.watch(tracearrV2GetHistoryProvider(widget.instance));
    final String selectedTypeFilter =
        ref.watch(tracearrHistoryTypeFilterProvider(widget.instance));
    final String selectedStatusFilter =
        ref.watch(tracearrHistoryStatusFilterProvider(widget.instance));
    final String selectedGenreFilter =
        ref.watch(tracearrHistoryGenreFilterProvider(widget.instance));
    final String selectedSortBy =
        ref.watch(tracearrHistorySortByProvider(widget.instance));

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      behavior: HitTestBehavior.translucent,
      child: EasyRefresh(
      header: const ClassicHeader(
        position: IndicatorPosition.locator,
      ),
      footer: const ClassicFooter(
        position: IndicatorPosition.locator,
      ),
      onRefresh: () {
        setState(() {
          _appendedRecords.clear();
          _nextCursor = null;
          _hasMore = true;
        });
        return ref.refresh(tracearrV2GetHistoryProvider(widget.instance).future);
      },
      onLoad: _hasMore ? _loadNextPage : null,
      child: asyncHistory.when(
        data: (TracearrV2HistoryResponse history) {
          if (_appendedRecords.isEmpty) {
            _nextCursor = history.meta?.nextCursor;
            _hasMore = _nextCursor != null && _nextCursor!.isNotEmpty;
          }

          final List<TracearrV2HistoryRecord> allRecords = <TracearrV2HistoryRecord>[
            ...history.data,
            ..._appendedRecords,
          ];

          final List<TracearrV2HistoryRecord> filteredRecords =
              allRecords.where((TracearrV2HistoryRecord r) {
            final String type = (r.mediaType ?? '').toUpperCase();
            if (selectedTypeFilter != 'ALL' && type != selectedTypeFilter) {
              return false;
            }
            final bool isCompleted = r.effectiveCompleted;
            if (selectedStatusFilter == 'COMPLETED' && !isCompleted) {
              return false;
            }
            if (selectedStatusFilter == 'PARTIAL' && isCompleted) {
              return false;
            }
            if (selectedGenreFilter != 'ALL' &&
                !r.genres.any(
                    (String g) => g.toUpperCase() == selectedGenreFilter.toUpperCase(),
                )) {
              return false;
            }
            if (_searchQuery.isEmpty) return true;
            final String query = _searchQuery.toLowerCase();
            final String title =
                (r.mediaTitle ?? r.showTitle ?? '').toLowerCase();
            final String user = (r.effectiveUsername ?? '').toLowerCase();
            final String server = (r.serverName ?? '').toLowerCase();
            return title.contains(query) ||
                user.contains(query) ||
                server.contains(query);
          }).toList();

          // Apply multi-criteria sorting
          filteredRecords.sort((TracearrV2HistoryRecord a, TracearrV2HistoryRecord b) {
            switch (selectedSortBy) {
              case 'DATE_ASC':
                final String aTime = a.startedAt ?? a.stoppedAt ?? '';
                final String bTime = b.startedAt ?? b.stoppedAt ?? '';
                return aTime.compareTo(bTime);
              case 'DURATION_DESC':
                final int aDur = a.durationMs ?? 0;
                final int bDur = b.durationMs ?? 0;
                return bDur.compareTo(aDur);
              case 'PERCENT_DESC':
                final double aPct = a.percentComplete ?? (a.effectiveCompleted ? 100.0 : 0.0);
                final double bPct = b.percentComplete ?? (b.effectiveCompleted ? 100.0 : 0.0);
                return bPct.compareTo(aPct);
              case 'TITLE_ASC':
                final String aTitle = a.mediaTitle ?? a.showTitle ?? '';
                final String bTitle = b.mediaTitle ?? b.showTitle ?? '';
                return aTitle.compareTo(bTitle);
              case 'DATE_DESC':
              default:
                final String aTime = a.startedAt ?? a.stoppedAt ?? '';
                final String bTime = b.startedAt ?? b.stoppedAt ?? '';
                return bTime.compareTo(aTime);
            }
          });

          return CustomScrollView(
            controller: _scrollController,
            slivers: <Widget>[
              SliverAppBar(
                floating: true,
                snap: true,
                scrolledUnderElevation: 0.0,
                surfaceTintColor: Colors.transparent,
                backgroundColor: theme.colorScheme.surface,
                toolbarHeight: 72,
                titleSpacing: 0,
                leadingWidth: 56,
                leading: Builder(
                  builder: (BuildContext ctx) {
                    final ScaffoldState? scaffold =
                        Scaffold.maybeOf(ctx);
                    if (scaffold?.hasDrawer ?? false) {
                      return IconButton(
                        icon: const Icon(Icons.menu),
                        onPressed: () => scaffold?.openDrawer(),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
                title: SearchBar(
                  focusNode: _searchFocusNode,
                  controller: _searchController,
                  hintText: 'Search watch history...',
                  onTapOutside: (_) => FocusScope.of(context).unfocus(),
                  elevation: const WidgetStatePropertyAll<double>(0),
                  backgroundColor: WidgetStatePropertyAll<Color>(
                    theme.colorScheme.surfaceContainerHigh,
                  ),
                  trailing: <Widget>[
                    if (_searchQuery.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _searchFocusNode.unfocus();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      ),
                  ],
                  onChanged: (String val) {
                    setState(() {
                      _searchQuery = val;
                    });
                  },
                ),
                actions: <Widget>[
                  IconButton(
                    icon: const Icon(Icons.tune),
                    tooltip: 'Filter & Sort',
                    onPressed: () {
                      showModalBottomSheet<void>(
                        context: context,
                        showDragHandle: true,
                        useRootNavigator: true,
                        builder: (BuildContext context) =>
                            TracearrHistorySortFilterBottomSheet(instance: widget.instance),
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                ],
              ),
              const HeaderLocator.sliver(),
              if (filteredRecords.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Icon(
                          Icons.history_toggle_off,
                          size: 64,
                          color: Theme.of(context).colorScheme.outline,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          allRecords.isEmpty
                              ? 'No Watch History'
                              : 'No Matching History',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (BuildContext context, int index) {
                        return _HistoryRecordCard(
                          instance: widget.instance,
                          record: filteredRecords[index],
                        );
                      },
                      childCount: filteredRecords.length,
                    ),
                  ),
                ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (Object error, StackTrace stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 12),
              Text('Failed to load history: $error'),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => ref.invalidate(
                  tracearrV2GetHistoryProvider(widget.instance),
                ),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }
}

class _HistoryRecordCard extends ConsumerWidget {
  const _HistoryRecordCard({
    required this.instance,
    required this.record,
  });

  final Instance instance;
  final TracearrV2HistoryRecord record;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final TracearrApi? api = ref.watch(tracearrApiProvider(instance)).value;
    final Map<String, String> serverMap =
        ref.watch(tracearrServerNamesMapProvider(instance));
    final String? posterUrl = api?.imageUrl(record.posterUrl ?? record.thumbPath);

    final String displayTitle;
    final String? secondaryTitle;

    if (record.mediaType == 'episode' &&
        record.showTitle != null &&
        record.showTitle!.trim().isNotEmpty) {
      displayTitle = record.showTitle!.trim();
      final String epPrefix = (record.seasonNumber != null &&
              record.episodeNumber != null)
          ? 'S${record.seasonNumber}:E${record.episodeNumber}'
          : '';
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

    final String username =
        record.effectiveUsername ?? record.user?.username ?? 'User';
    final String? avatarUrl = api?.imageUrl(record.effectiveUserAvatar);
    final String serverDisplayName = resolveServerName(
      serverMap: serverMap,
      serverName: record.serverName,
      serverId: record.serverId,
      serverType: record.serverType,
    );
    final bool completed = record.effectiveCompleted;
    final String formattedTime =
        formatTracearrTimestamp(record.startedAt ?? record.stoppedAt);

    // Watch duration / percent formatting
    final int durationMs = record.durationMs ?? 0;
    final double percent = record.percentComplete ?? 0;
    final String durationText =
        durationMs > 0 ? '${(durationMs / 60000).toStringAsFixed(1)}m' : '';
    final String percentText =
        percent > 0 ? '${percent.toStringAsFixed(0)}%' : '';

    final String subtitleDetails = <String>[
      if (durationText.isNotEmpty) '$durationText watched',
      if (percentText.isNotEmpty) percentText,
      if (record.resolution != null && record.resolution!.isNotEmpty)
        record.resolution!,
    ].join(' • ');

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: posterUrl != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: SizedBox(
                  width: 44,
                  height: 66,
                  child: CachedNetworkImage(
                    imageUrl: posterUrl,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => Container(
                      color: Theme.of(context).colorScheme.surfaceContainerHigh,
                      child: const Icon(Icons.movie_outlined, size: 24),
                    ),
                  ),
                ),
              )
            : Container(
                width: 44,
                height: 66,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.play_circle_outline, size: 24),
              ),
        title: Text(
          displayTitle,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            if (secondaryTitle != null && secondaryTitle.isNotEmpty) ...<Widget>[
              const SizedBox(height: 1),
              Text(
                secondaryTitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 2),
            Row(
              children: <Widget>[
                TracearrUserAvatar(
                  username: username,
                  avatarUrl: avatarUrl,
                  radius: 8,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    <String>[
                      username,
                      serverDisplayName,
                      if (formattedTime.isNotEmpty) formattedTime,
                    ].join(' • '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
            if (subtitleDetails.isNotEmpty) ...<Widget>[
              const SizedBox(height: 2),
              Text(
                subtitleDetails,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
        trailing: Icon(
          completed ? Icons.check_circle : Icons.play_circle_filled,
          size: 20,
          color: completed
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.tertiary,
        ),
        onTap: () {
          TracearrSessionDetailBottomSheet.showHistory(
            context,
            instance: instance,
            record: record,
          );
        },
      ),
    );
  }
}

class TracearrHistorySortFilterBottomSheet extends ConsumerWidget {
  const TracearrHistorySortFilterBottomSheet({required this.instance, super.key});

  final Instance instance;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final selectedTypeFilter = ref.watch(tracearrHistoryTypeFilterProvider(instance));
    final selectedStatusFilter = ref.watch(tracearrHistoryStatusFilterProvider(instance));
    final selectedGenreFilter = ref.watch(tracearrHistoryGenreFilterProvider(instance));
    final selectedSortBy = ref.watch(tracearrHistorySortByProvider(instance));

    final AsyncValue<TracearrV2HistoryResponse> asyncHistory =
        ref.watch(tracearrV2GetHistoryProvider(instance));

    final Set<String> availableTypes = asyncHistory.asData?.value.data
            .map((TracearrV2HistoryRecord e) => (e.mediaType ?? '').toUpperCase())
            .where((String t) => t.isNotEmpty)
            .toSet() ??
        <String>{};

    final Set<String> availableGenres = asyncHistory.asData?.value.data
            .expand((TracearrV2HistoryRecord e) => e.genres)
            .where((String g) => g.trim().isNotEmpty)
            .toSet() ??
        <String>{};

    final List<String> typeFilterOptions = <String>[
      'ALL',
      ...availableTypes.toList()..sort(),
    ];

    final List<String> genreFilterOptions = <String>[
      'ALL',
      ...availableGenres.toList()..sort(),
    ];

    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Sort Order',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: <Map<String, String>>[
                  <String, String>{'id': 'DATE_DESC', 'label': 'Date (Newest First)'},
                  <String, String>{'id': 'DATE_ASC', 'label': 'Date (Oldest First)'},
                  <String, String>{'id': 'DURATION_DESC', 'label': 'Duration (Longest)'},
                  <String, String>{'id': 'PERCENT_DESC', 'label': 'Completion (Highest)'},
                  <String, String>{'id': 'TITLE_ASC', 'label': 'Title (A–Z)'},
                ].map((item) {
                  final String id = item['id']!;
                  final String label = item['label']!;
                  return ChoiceChip(
                    label: Text(label),
                    selected: selectedSortBy == id,
                    onSelected: (val) {
                      if (val) {
                        ref
                            .read(tracearrHistorySortByProvider(instance).notifier)
                            .state = id;
                      }
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              Text(
                'Filter Category',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: typeFilterOptions.map((f) {
                  final label = f == 'ALL'
                      ? 'All Categories'
                      : '${f[0]}${f.substring(1).toLowerCase()}s Only';
                  return ChoiceChip(
                    label: Text(label),
                    selected: selectedTypeFilter == f,
                    onSelected: (val) {
                      if (val) {
                        ref
                            .read(tracearrHistoryTypeFilterProvider(instance).notifier)
                            .state = f;
                      }
                    },
                  );
                }).toList(),
              ),
              if (genreFilterOptions.length > 1) ...[
                const SizedBox(height: 16),
                Text(
                  'Filter Genre',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: genreFilterOptions.map((g) {
                    final label = g == 'ALL' ? 'All Genres' : g;
                    return ChoiceChip(
                      label: Text(label),
                      selected: selectedGenreFilter.toUpperCase() == g.toUpperCase(),
                      onSelected: (val) {
                        if (val) {
                          ref
                              .read(tracearrHistoryGenreFilterProvider(instance).notifier)
                              .state = g;
                        }
                      },
                    );
                  }).toList(),
                ),
              ],
              const SizedBox(height: 16),
              Text(
                'Filter Play Status',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: <String>['ALL', 'COMPLETED', 'PARTIAL'].map((status) {
                  final label = switch (status) {
                    'COMPLETED' => 'Completed Only',
                    'PARTIAL' => 'Partial Only',
                    _ => 'All Play Statuses',
                  };
                  return ChoiceChip(
                    label: Text(label),
                    selected: selectedStatusFilter == status,
                    onSelected: (val) {
                      if (val) {
                        ref
                            .read(tracearrHistoryStatusFilterProvider(instance).notifier)
                            .state = status;
                      }
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
