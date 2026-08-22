import 'dart:async';
import 'package:core_models/core_models.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../generated/generated.dart';
import '../../lidarr_api.dart';
import '../../lidarr_providers.dart';
import '../calendar/calendar_feed_dialog.dart';
import 'add_artist_search_screen.dart';
import 'album_studio_screen.dart';
import 'widgets/artist_bulk_actions_bar.dart';
import 'widgets/artist_grid.dart';
import 'widgets/artist_list.dart';

/// Artists library tab displaying artist grid or list with pristine M3E search app bar,
/// thumb-zone Tune/Sort/Filter modal sheet, stacked FABs, and contextual selection toolbar.
class ArtistsTab extends ConsumerStatefulWidget {
  const ArtistsTab({required this.instance, super.key});

  final Instance instance;

  @override
  ConsumerState<ArtistsTab> createState() => _ArtistsTabState();
}

class _ArtistsTabState extends ConsumerState<ArtistsTab>
    with WidgetsBindingObserver {
  final TextEditingController _searchController = TextEditingController();
  late final FocusNode _searchFocusNode;
  late final ScrollController _scrollController;
  double _lastBottomInset = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final String current = ref.read(lidarrSearchQueryProvider(widget.instance));
    _searchController.text = current;
    _searchFocusNode = FocusNode()..addListener(_onFocusChange);
    _scrollController = ScrollController()..addListener(_onScroll);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _searchFocusNode.removeListener(_onFocusChange);
    _searchFocusNode.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    final double bottomInset = WidgetsBinding
        .instance.platformDispatcher.views.first.viewInsets.bottom;
    if (bottomInset == 0 && _lastBottomInset > 0) {
      if (_searchFocusNode.hasFocus) {
        _searchFocusNode.unfocus();
      }
    }
    _lastBottomInset = bottomInset;
  }

  void _onFocusChange() {
    setState(() {});
  }

  void _onScroll() {
    if (_scrollController.hasClients &&
        _scrollController.position.userScrollDirection !=
            ScrollDirection.idle) {
      if (_searchFocusNode.hasFocus) {
        _searchFocusNode.unfocus();
      }
    }
  }

  void _showSortFilterBottomSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      useRootNavigator: true,
      builder: (BuildContext ctx) =>
          _SortFilterBottomSheet(instance: widget.instance),
    );
  }

  Future<void> _refreshAllArtists(BuildContext context) async {
    try {
      final LidarrApi api =
          await ref.read(lidarrApiProvider(widget.instance).future);
      final ApiResponse<CommandResource> resp =
          await api.executeCommand('RefreshArtist');
      if (!resp.isSuccess) {
        throw Exception(resp.error?.message ?? 'Failed to refresh artists');
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Refreshing all artists in library...'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to refresh artists: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  void _handleMoreOption(BuildContext context, String value) {
    switch (value) {
      case 'refresh_all':
        _refreshAllArtists(context);
      case 'album_studio':
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => LidarrAlbumStudioScreen(instance: widget.instance),
          ),
        );
      case 'calendar_feed':
        showLidarrCalendarFeedDialog(
          context,
          instance: widget.instance,
        );
    }
  }

  void _toggleSelection(int artistId) {
    final Set<int> current =
        Set<int>.from(ref.read(lidarrArtistSelectionProvider(widget.instance)));
    if (current.contains(artistId)) {
      current.remove(artistId);
    } else {
      current.add(artistId);
    }
    ref.read(lidarrArtistSelectionProvider(widget.instance).notifier).state =
        current;
  }

  @override
  Widget build(BuildContext context) {
    final Instance instance = widget.instance;
    final ThemeData theme = Theme.of(context);
    final AsyncValue<List<ArtistResource>> asyncArtists =
        ref.watch(lidarrArtistsProvider(instance));
    final String query =
        ref.watch(lidarrSearchQueryProvider(instance)).trim().toLowerCase();
    final LidarrViewMode viewMode = ref.watch(lidarrViewModeProvider(instance));
    final LidarrArtistFilter activeFilter =
        ref.watch(lidarrArtistFilterProvider(instance));
    final LidarrArtistSort activeSort =
        ref.watch(lidarrArtistSortProvider(instance));
    final bool isAscending =
        ref.watch(lidarrArtistSortAscendingProvider(instance));
    final Set<int> selectedIds =
        ref.watch(lidarrArtistSelectionProvider(instance));
    final bool inSelectionMode = selectedIds.isNotEmpty;

    // Scroll to top listener
    ref.listen<int>(lidarrHomeScrollToTopProvider((instance, 0)),
        (previous, next) {
      if (next > 0 && _scrollController.hasClients) {
        _scrollController.animateTo(
          0.0,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
        );
      }
    });

    // Sync external clears to local search controller
    ref.listen<String>(lidarrSearchQueryProvider(instance), (previous, next) {
      if (next.isEmpty && _searchController.text.isNotEmpty) {
        setState(_searchController.clear);
        if (_searchFocusNode.hasFocus) {
          _searchFocusNode.unfocus();
        }
      }
    });

    return Scaffold(
      body: AsyncValueView<List<ArtistResource>>(
        value: asyncArtists,
        onRetry: () => ref.invalidate(lidarrArtistsProvider(instance)),
        data: (List<ArtistResource> artists) {
          var filtered = query.isEmpty
              ? List<ArtistResource>.from(artists)
              : artists
                  .where(
                    (a) => (a.artistName ?? '').toLowerCase().contains(query),
                  )
                  .toList();

          if (activeFilter != LidarrArtistFilter.all) {
            filtered = filtered.where((a) {
              return switch (activeFilter) {
                LidarrArtistFilter.monitored => a.monitored == true,
                LidarrArtistFilter.unmonitored => a.monitored != true,
                LidarrArtistFilter.completed =>
                  (a.statistics?.trackFileCount ?? 0) >=
                          (a.statistics?.totalTrackCount ??
                              a.statistics?.trackCount ??
                              0) &&
                      (a.statistics?.totalTrackCount ??
                              a.statistics?.trackCount ??
                              0) >
                          0,
                LidarrArtistFilter.missingTracks =>
                  (a.statistics?.trackFileCount ?? 0) <
                      (a.statistics?.totalTrackCount ??
                          a.statistics?.trackCount ??
                          0),
                LidarrArtistFilter.continuing =>
                  a.status?.value != 'ended' && a.ended != true,
                LidarrArtistFilter.ended =>
                  a.status?.value == 'ended' || a.ended == true,
                LidarrArtistFilter.all => true,
              };
            }).toList();
          }

          filtered.sort((a, b) {
            int comp;
            switch (activeSort) {
              case LidarrArtistSort.name:
                comp = (a.sortName ?? a.artistName ?? '')
                    .compareTo(b.sortName ?? b.artistName ?? '');
              case LidarrArtistSort.sizeOnDisk:
                comp = (a.statistics?.sizeOnDisk ?? 0)
                    .compareTo(b.statistics?.sizeOnDisk ?? 0);
              case LidarrArtistSort.dateAdded:
                comp = (a.added ?? '').compareTo(b.added ?? '');
              case LidarrArtistSort.albumCount:
                comp = (a.statistics?.albumCount ?? 0)
                    .compareTo(b.statistics?.albumCount ?? 0);
              case LidarrArtistSort.progress:
                comp = (a.statistics?.percentOfTracks ?? 0.0)
                    .compareTo(b.statistics?.percentOfTracks ?? 0.0);
              case LidarrArtistSort.rating:
                comp = (a.ratings?.value ?? 0.0)
                    .compareTo(b.ratings?.value ?? 0.0);
            }
            return isAscending ? comp : -comp;
          });

          return EasyRefresh(
            header: const ClassicHeader(
              position: IndicatorPosition.locator,
              dragText: 'Pull to refresh',
              armedText: 'Release ready',
              readyText: 'Refreshing...',
              processingText: 'Refreshing...',
              processedText: 'Succeeded',
              failedText: 'Failed',
              messageText: 'Last updated at %T',
            ),
            onRefresh: () async {
              ref.invalidate(lidarrArtistsProvider(instance));
              await ref.read(lidarrArtistsProvider(instance).future);
            },
            child: CustomScrollView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverAppBar(
                  floating: true,
                  snap: true,
                  scrolledUnderElevation: 0.0,
                  surfaceTintColor: Colors.transparent,
                  backgroundColor: theme.colorScheme.surface,
                  toolbarHeight: 64,
                  titleSpacing: 0,
                  leadingWidth: inSelectionMode ? 56 : 52,
                  automaticallyImplyLeading: false,
                  leading: inSelectionMode
                      ? IconButton(
                          icon: const Icon(Icons.close),
                          tooltip: 'Clear selection',
                          onPressed: () {
                            ref
                                .read(
                                  lidarrArtistSelectionProvider(instance)
                                      .notifier,
                                )
                                .state = <int>{};
                          },
                        )
                      : Padding(
                          padding: const EdgeInsets.only(left: 4),
                          child: (_searchController.text.isNotEmpty ||
                                  _searchFocusNode.hasFocus)
                              ? IconButton(
                                  icon: const Icon(Icons.arrow_back),
                                  tooltip: 'Back',
                                  onPressed: () {
                                    _searchFocusNode.unfocus();
                                    _searchController.clear();
                                    ref
                                        .read(
                                          lidarrSearchQueryProvider(instance)
                                              .notifier,
                                        )
                                        .state = '';
                                  },
                                )
                              : IconButton(
                                  icon: const Icon(Icons.menu),
                                  tooltip: 'Open drawer',
                                  onPressed: () =>
                                      Scaffold.of(context).openDrawer(),
                                ),
                        ),
                  title: inSelectionMode
                      ? Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            '${selectedIds.length} selected',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      : Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Container(
                            height: 56,
                            decoration: ShapeDecoration(
                              color: theme.colorScheme.surfaceContainerHigh,
                              shape: const StadiumBorder(),
                            ),
                            padding: const EdgeInsets.only(
                              left: 24,
                              right: 8,
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _searchController,
                                    focusNode: _searchFocusNode,
                                    style: theme.textTheme.bodyLarge,
                                    decoration: InputDecoration(
                                      hintText: 'Search artists...',
                                      hintStyle:
                                          theme.textTheme.bodyLarge?.copyWith(
                                        color:
                                            theme.colorScheme.onSurfaceVariant,
                                      ),
                                      border: InputBorder.none,
                                      enabledBorder: InputBorder.none,
                                      focusedBorder: InputBorder.none,
                                      filled: false,
                                      isDense: true,
                                      contentPadding: EdgeInsets.zero,
                                    ),
                                    onChanged: (val) {
                                      ref
                                          .read(
                                            lidarrSearchQueryProvider(
                                              instance,
                                            ).notifier,
                                          )
                                          .state = val;
                                    },
                                  ),
                                ),
                                if (_searchController.text.isNotEmpty)
                                  IconButton(
                                    icon: const Icon(Icons.clear, size: 22),
                                    tooltip: 'Clear search',
                                    visualDensity: VisualDensity.compact,
                                    onPressed: () {
                                      _searchController.clear();
                                      ref
                                          .read(
                                            lidarrSearchQueryProvider(
                                              instance,
                                            ).notifier,
                                          )
                                          .state = '';
                                    },
                                  ),
                              ],
                            ),
                          ),
                        ),
                  actions: inSelectionMode
                      ? [
                          TextButton(
                            onPressed: () {
                              ref
                                      .read(
                                        lidarrArtistSelectionProvider(
                                          instance,
                                        ).notifier,
                                      )
                                      .state =
                                  filtered
                                      .where((a) => a.id != null)
                                      .map((a) => a.id!)
                                      .toSet();
                            },
                            child: const Text('Select All'),
                          ),
                          TextButton(
                            onPressed: () {
                              final Set<int> all = filtered
                                  .where((a) => a.id != null)
                                  .map((a) => a.id!)
                                  .toSet();
                              final Set<int> inverted =
                                  all.difference(selectedIds);
                              ref
                                  .read(
                                    lidarrArtistSelectionProvider(instance)
                                        .notifier,
                                  )
                                  .state = inverted;
                            },
                            child: const Text('Invert'),
                          ),
                          const SizedBox(width: 4),
                        ]
                      : [
                          PopupMenuButton<String>(
                            tooltip: 'More options',
                            icon: const Icon(Icons.more_vert),
                            onSelected: (val) =>
                                _handleMoreOption(context, val),
                            itemBuilder: (ctx) => [
                              const PopupMenuItem(
                                value: 'album_studio',
                                child: ListTile(
                                  leading: Icon(Icons.grid_on_outlined),
                                  title: Text('Album Studio'),
                                  contentPadding: EdgeInsets.zero,
                                  dense: true,
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'calendar_feed',
                                child: ListTile(
                                  leading: Icon(Icons.calendar_month_outlined),
                                  title: Text('iCal Calendar Feed'),
                                  contentPadding: EdgeInsets.zero,
                                  dense: true,
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'refresh_all',
                                child: ListTile(
                                  leading: Icon(Icons.refresh),
                                  title: Text('Refresh All Artists'),
                                  contentPadding: EdgeInsets.zero,
                                  dense: true,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 4),
                        ],
                ),
                if (activeFilter != LidarrArtistFilter.all ||
                    activeSort != LidarrArtistSort.name)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      child: Row(
                        children: [
                          if (activeFilter != LidarrArtistFilter.all)
                            InputChip(
                              visualDensity: VisualDensity.compact,
                              label: Text(
                                switch (activeFilter) {
                                  LidarrArtistFilter.monitored => 'Monitored',
                                  LidarrArtistFilter.unmonitored =>
                                    'Unmonitored',
                                  LidarrArtistFilter.completed => 'Completed',
                                  LidarrArtistFilter.missingTracks =>
                                    'Missing Tracks',
                                  LidarrArtistFilter.continuing => 'Continuing',
                                  LidarrArtistFilter.ended => 'Ended',
                                  LidarrArtistFilter.all => '',
                                },
                                style: const TextStyle(fontSize: 12),
                              ),
                              onDeleted: () {
                                ref
                                    .read(
                                      lidarrArtistFilterProvider(instance)
                                          .notifier,
                                    )
                                    .state = LidarrArtistFilter.all;
                              },
                            ),
                          if (activeFilter != LidarrArtistFilter.all &&
                              activeSort != LidarrArtistSort.name)
                            const SizedBox(width: 8),
                          if (activeSort != LidarrArtistSort.name)
                            InputChip(
                              visualDensity: VisualDensity.compact,
                              label: Text(
                                'Sorted by: ${activeSort.name}',
                                style: const TextStyle(fontSize: 12),
                              ),
                              onDeleted: () {
                                ref
                                    .read(
                                      lidarrArtistSortProvider(instance)
                                          .notifier,
                                    )
                                    .state = LidarrArtistSort.name;
                              },
                            ),
                        ],
                      ),
                    ),
                  ),
                const HeaderLocator.sliver(),
                if (filtered.isEmpty)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: EmptyView(
                        icon: Icons.music_off_outlined,
                        title: 'No artists found',
                        message:
                            'Try adjusting your search query or active filters.',
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
                    sliver: viewMode == LidarrViewMode.grid
                        ? ArtistGrid(
                            key: const PageStorageKey('lidarr_artist_grid'),
                            instance: instance,
                            artists: filtered,
                            selectedIds: selectedIds,
                            inSelectionMode: inSelectionMode,
                            onToggleSelection: _toggleSelection,
                          )
                        : ArtistList(
                            key: const PageStorageKey('lidarr_artist_list'),
                            instance: instance,
                            artists: filtered,
                            selectedIds: selectedIds,
                            inSelectionMode: inSelectionMode,
                            onToggleSelection: _toggleSelection,
                          ),
                  ),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: inSelectionMode
          ? ArtistBulkActionsBar(
              instance: instance,
              selectedIds: selectedIds,
              onClear: () {
                ref
                    .read(lidarrArtistSelectionProvider(instance).notifier)
                    .state = <int>{};
              },
            )
          : null,
      floatingActionButton: !inSelectionMode &&
              ref.watch(lidarrActiveTabBarIndexProvider(instance)) == 0
          ? Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                FloatingActionButton.small(
                  heroTag: 'lidarr_sort_filter_fab',
                  backgroundColor: theme.colorScheme.secondaryContainer,
                  foregroundColor: theme.colorScheme.onSecondaryContainer,
                  tooltip: 'Sort & Filter',
                  onPressed: () => _showSortFilterBottomSheet(context),
                  child: const Icon(Icons.tune),
                ),
                const SizedBox(height: 12),
                FloatingActionButton(
                  heroTag: 'lidarr_add_artist_fab',
                  backgroundColor: theme.colorScheme.primaryContainer,
                  foregroundColor: theme.colorScheme.onPrimaryContainer,
                  tooltip: 'Add Artist',
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) =>
                            LidarrAddArtistSearchScreen(instance: instance),
                      ),
                    );
                  },
                  child: const Icon(Icons.add),
                ),
              ],
            )
          : null,
    );
  }
}

/// Modal bottom sheet for filtering and sorting Lidarr artists.
class _SortFilterBottomSheet extends ConsumerWidget {
  const _SortFilterBottomSheet({required this.instance});

  final Instance instance;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final LidarrViewMode viewMode = ref.watch(lidarrViewModeProvider(instance));
    final LidarrArtistFilter activeFilter =
        ref.watch(lidarrArtistFilterProvider(instance));
    final LidarrArtistSort activeSort =
        ref.watch(lidarrArtistSortProvider(instance));
    final bool isAscending =
        ref.watch(lidarrArtistSortAscendingProvider(instance));

    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'View Layout',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              SegmentedButton<LidarrViewMode>(
                segments: const [
                  ButtonSegment(
                    value: LidarrViewMode.grid,
                    icon: Icon(Icons.grid_view),
                    label: Text('Grid View'),
                  ),
                  ButtonSegment(
                    value: LidarrViewMode.list,
                    icon: Icon(Icons.view_list),
                    label: Text('List View'),
                  ),
                ],
                selected: <LidarrViewMode>{viewMode},
                onSelectionChanged: (newSelection) {
                  ref
                      .read(lidarrViewModeProvider(instance).notifier)
                      .setViewMode(newSelection.first);
                },
              ),
              const SizedBox(height: 16),
              Text(
                'Filter',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: LidarrArtistFilter.values.map((f) {
                  final String label = switch (f) {
                    LidarrArtistFilter.all => 'All',
                    LidarrArtistFilter.monitored => 'Monitored',
                    LidarrArtistFilter.unmonitored => 'Unmonitored',
                    LidarrArtistFilter.completed => 'Completed (100%)',
                    LidarrArtistFilter.missingTracks => 'Missing Tracks',
                    LidarrArtistFilter.continuing => 'Continuing',
                    LidarrArtistFilter.ended => 'Ended',
                  };
                  final bool selected = activeFilter == f;
                  return ChoiceChip(
                    label: Text(label),
                    selected: selected,
                    onSelected: (val) {
                      if (val) {
                        ref
                            .read(lidarrArtistFilterProvider(instance).notifier)
                            .state = f;
                      }
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Sort By',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton.icon(
                    icon: Icon(
                      isAscending ? Icons.arrow_upward : Icons.arrow_downward,
                      size: 18,
                    ),
                    label: Text(isAscending ? 'Ascending' : 'Descending'),
                    onPressed: () {
                      ref
                          .read(
                            lidarrArtistSortAscendingProvider(instance)
                                .notifier,
                          )
                          .state = !isAscending;
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: LidarrArtistSort.values.map((s) {
                  final String label = switch (s) {
                    LidarrArtistSort.name => 'Artist Name',
                    LidarrArtistSort.sizeOnDisk => 'Size on Disk',
                    LidarrArtistSort.dateAdded => 'Date Added',
                    LidarrArtistSort.albumCount => 'Album Count',
                    LidarrArtistSort.progress => 'Progress %',
                    LidarrArtistSort.rating => 'Rating',
                  };
                  final bool selected = activeSort == s;
                  return ChoiceChip(
                    label: Text(label),
                    selected: selected,
                    onSelected: (val) {
                      if (val) {
                        ref
                            .read(lidarrArtistSortProvider(instance).notifier)
                            .state = s;
                      }
                    },
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
