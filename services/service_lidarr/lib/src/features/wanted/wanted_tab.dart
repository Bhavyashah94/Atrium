import 'package:core_models/core_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../generated/generated.dart';
import '../../lidarr_api.dart';
import '../../lidarr_providers.dart';
import 'views/cutoff_view.dart';
import 'views/missing_view.dart';
import 'widgets/wanted_bulk_actions_bar.dart';
import 'widgets/wanted_sort_filter_bottom_sheet.dart';

/// Wanted tab coordinating Missing albums and Cutoff Unmet albums views with unified
/// header search, sort & filter modal, infinite scroll, and batch operations.
class WantedTab extends ConsumerStatefulWidget {
  const WantedTab({required this.instance, super.key});

  final Instance instance;

  @override
  ConsumerState<WantedTab> createState() => _WantedTabState();
}

class _WantedTabState extends ConsumerState<WantedTab>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final TabController _subTabController;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  double _lastBottomInset = 0.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _subTabController = TabController(length: 2, vsync: this);
    _subTabController.addListener(_onTabChange);
    _searchFocusNode.addListener(_onFocusChange);
    _searchController.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _subTabController.removeListener(_onTabChange);
    _subTabController.dispose();
    _searchController.removeListener(_onFocusChange);
    _searchFocusNode.removeListener(_onFocusChange);
    _searchFocusNode.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onTabChange() {
    ref.read(lidarrWantedSelectionProvider(widget.instance).notifier).state =
        <int>{};
    setState(() {});
  }

  void _onFocusChange() {
    setState(() {});
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

  void _clearSelection() {
    ref.read(lidarrWantedSelectionProvider(widget.instance).notifier).state =
        <int>{};
  }

  Future<void> _searchAllMissing() async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Search All Missing?'),
        content: const Text(
          'Initiate automated searches for all missing albums across configured indexers?',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Search All'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      final LidarrApi api =
          await ref.read(lidarrApiProvider(widget.instance).future);
      final ApiResponse<CommandResource> resp =
          await api.executeCommand('MissingAlbumSearch');

      if (!resp.isSuccess) {
        throw Exception(resp.error?.message ?? 'Failed to trigger search');
      }

      ref.invalidate(lidarrQueueProvider(widget.instance));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Missing albums search initiated successfully.'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _searchAllCutoff() async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Search All Cutoff Unmet?'),
        content: const Text(
          'Initiate automated quality upgrade searches for all cutoff unmet albums?',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Search All'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      final LidarrApi api =
          await ref.read(lidarrApiProvider(widget.instance).future);
      final ApiResponse<CommandResource> resp =
          await api.executeCommand('CutoffUnmetAlbumSearch');

      if (!resp.isSuccess) {
        throw Exception(resp.error?.message ?? 'Failed to trigger search');
      }

      ref.invalidate(lidarrQueueProvider(widget.instance));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cutoff unmet search initiated successfully.'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _searchBulk(Set<int> ids) async {
    if (ids.isEmpty) return;
    final List<int> idList = ids.toList();
    _clearSelection();

    try {
      final LidarrApi api =
          await ref.read(lidarrApiProvider(widget.instance).future);
      final ApiResponse<CommandResource> resp =
          await api.executeCommand('AlbumSearch', <String, dynamic>{
        'albumIds': idList,
      });

      if (!resp.isSuccess) {
        throw Exception(resp.error?.message ?? 'Failed to start bulk search');
      }

      ref.invalidate(lidarrQueueProvider(widget.instance));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Search started for ${idList.length} selected albums.'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Bulk search failed: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _setMonitoredBulk(Set<int> ids, bool monitored) async {
    if (ids.isEmpty) return;
    final List<int> idList = ids.toList();
    _clearSelection();

    try {
      final LidarrApi api =
          await ref.read(lidarrApiProvider(widget.instance).future);
      final ApiResponse<void> resp = await api.album.putAlbumMonitor(
        body: AlbumsMonitoredResource(
          albumIds: idList,
          monitored: monitored,
        ),
      );

      if (!resp.isSuccess) {
        throw Exception(resp.error?.message ?? 'Failed to update monitoring');
      }

      ref.invalidate(lidarrWantedMissingProvider);
      ref.invalidate(lidarrWantedCutoffProvider);
      ref.invalidate(lidarrArtistsProvider(widget.instance));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              monitored
                  ? 'Enabled monitoring for ${idList.length} albums.'
                  : 'Disabled monitoring for ${idList.length} albums.',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update monitoring: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;
    final Set<int> selectedIds =
        ref.watch(lidarrWantedSelectionProvider(widget.instance));
    final bool inSelectionMode = selectedIds.isNotEmpty;

    final bool monitoredOnly =
        ref.watch(lidarrWantedMonitoredOnlyProvider(widget.instance));
    final WantedSortKey sortKey =
        ref.watch(lidarrWantedSortKeyProvider(widget.instance));
    final bool sortAscending =
        ref.watch(lidarrWantedSortAscendingProvider(widget.instance));
    final bool isFilterActive =
        !monitoredOnly || sortKey != WantedSortKey.releaseDate || sortAscending;

    return Scaffold(
      body: NestedScrollView(
        controller: _scrollController,
        headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
          return <Widget>[
            SliverAppBar(
              floating: true,
              snap: true,
              pinned: true,
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
                      onPressed: _clearSelection,
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
                                      lidarrWantedSearchQueryProvider(
                                        widget.instance,
                                      ).notifier,
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
                          children: <Widget>[
                            Expanded(
                              child: TextField(
                                controller: _searchController,
                                focusNode: _searchFocusNode,
                                style: theme.textTheme.bodyLarge,
                                decoration: InputDecoration(
                                  hintText: 'Search wanted albums...',
                                  hintStyle:
                                      theme.textTheme.bodyLarge?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  filled: false,
                                  isDense: true,
                                  contentPadding: EdgeInsets.zero,
                                ),
                                onChanged: (String val) {
                                  ref
                                      .read(
                                        lidarrWantedSearchQueryProvider(
                                          widget.instance,
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
                                        lidarrWantedSearchQueryProvider(
                                          widget.instance,
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
                  ? null
                  : <Widget>[
                      AnimatedBuilder(
                        animation: _subTabController,
                        builder: (BuildContext context, Widget? child) {
                          final bool isMissingTab =
                              _subTabController.index == 0;
                          return IconButton(
                            icon: const Icon(Icons.travel_explore),
                            tooltip: isMissingTab
                                ? 'Search All Missing'
                                : 'Search All Cutoff',
                            onPressed: isMissingTab
                                ? _searchAllMissing
                                : _searchAllCutoff,
                          );
                        },
                      ),
                      const SizedBox(width: 4),
                    ],
              bottom: TabBar(
                controller: _subTabController,
                dividerColor: Colors.transparent,
                indicatorColor: cs.primary,
                labelColor: cs.primary,
                unselectedLabelColor: cs.onSurfaceVariant,
                indicatorSize: TabBarIndicatorSize.tab,
                labelStyle: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                unselectedLabelStyle: theme.textTheme.titleSmall,
                tabs: const <Widget>[
                  Tab(text: 'Missing'),
                  Tab(text: 'Cutoff Unmet'),
                ],
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _subTabController,
          children: <Widget>[
            MissingView(instance: widget.instance),
            CutoffView(instance: widget.instance),
          ],
        ),
      ),
      floatingActionButton: !inSelectionMode
          ? FloatingActionButton(
              heroTag: 'lidarr_wanted_filter_fab',
              backgroundColor: cs.primaryContainer,
              foregroundColor: cs.onPrimaryContainer,
              tooltip: 'Sort & Filter',
              onPressed: () => WantedSortFilterBottomSheet.show(
                context,
                widget.instance,
              ),
              child: Badge(
                isLabelVisible: isFilterActive,
                child: const Icon(Icons.tune),
              ),
            )
          : null,
      bottomNavigationBar: inSelectionMode
          ? WantedBulkActionsBar(
              selectedCount: selectedIds.length,
              onSearch: () => _searchBulk(selectedIds),
              onMonitor: () => _setMonitoredBulk(selectedIds, true),
              onUnmonitor: () => _setMonitoredBulk(selectedIds, false),
            )
          : null,
    );
  }
}
