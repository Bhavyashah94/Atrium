import 'package:core_models/core_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../generated/generated.dart';
import '../../lidarr_providers.dart';
import '../track_files/manual_import_dialog.dart';
import 'providers/activity_providers.dart';
import 'views/blocklist_view.dart';
import 'views/history_view.dart';
import 'views/queue_view.dart';
import 'widgets/activity_bulk_actions_bar.dart';

/// Activity tab coordinating Queue, History, and Blocklist views with unified header search, grouping toggle, and bulk selection.
class ActivityTab extends ConsumerStatefulWidget {
  const ActivityTab({required this.instance, super.key});

  final Instance instance;

  @override
  ConsumerState<ActivityTab> createState() => _ActivityTabState();
}

class _ActivityTabState extends ConsumerState<ActivityTab>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  late final TabController _subTabController;
  late final TextEditingController _searchController;
  late final FocusNode _searchFocusNode;
  late final ScrollController _scrollController;
  double _lastBottomInset = 0.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scrollController = ScrollController();
    _searchController = TextEditingController();
    _searchFocusNode = FocusNode()..addListener(_onFocusChange);
    _subTabController = TabController(length: 3, vsync: this);
    _subTabController.addListener(_onTabChange);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _searchFocusNode.removeListener(_onFocusChange);
    _subTabController.removeListener(_onTabChange);
    _subTabController.dispose();
    _searchFocusNode.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onTabChange() {
    ref.read(lidarrQueueSelectionProvider(widget.instance).notifier).state =
        <int>{};
    ref.read(lidarrBlocklistSelectionProvider(widget.instance).notifier).state =
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
    ref.read(lidarrQueueSelectionProvider(widget.instance).notifier).state =
        <int>{};
    ref.read(lidarrBlocklistSelectionProvider(widget.instance).notifier).state =
        <int>{};
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;
    final bool grouped =
        ref.watch(lidarrActivityGroupedProvider(widget.instance));
    final Set<int> queueSelection =
        ref.watch(lidarrQueueSelectionProvider(widget.instance));
    final Set<int> blocklistSelection =
        ref.watch(lidarrBlocklistSelectionProvider(widget.instance));

    final Set<int> activeSelection = _subTabController.index == 0
        ? queueSelection
        : _subTabController.index == 2
            ? blocklistSelection
            : <int>{};
    final bool inSelectionMode = activeSelection.isNotEmpty;

    // Listen for external search query clear
    ref.listen<String>(
      lidarrActivitySearchQueryProvider(widget.instance),
      (String? previous, String next) {
        if (next.isEmpty && _searchController.text.isNotEmpty) {
          setState(() {
            _searchController.clear();
          });
          _searchFocusNode.unfocus();
        }
      },
    );

    return Scaffold(
      backgroundColor: cs.surface,
      bottomNavigationBar: inSelectionMode
          ? ActivityBulkActionsBar(
              instance: widget.instance,
              selectedIds: activeSelection,
              isQueue: _subTabController.index == 0,
              onClear: _clearSelection,
            )
          : null,
      body: NestedScrollView(
        controller: _scrollController,
        headerSliverBuilder:
            (BuildContext innerContext, bool innerBoxIsScrolled) {
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
                                      lidarrActivitySearchQueryProvider(
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
                        '${activeSelection.length} selected',
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
                        padding: const EdgeInsets.only(left: 24, right: 8),
                        child: Row(
                          children: <Widget>[
                            Expanded(
                              child: TextField(
                                controller: _searchController,
                                focusNode: _searchFocusNode,
                                style: theme.textTheme.bodyLarge,
                                decoration: InputDecoration(
                                  hintText: 'Search activity...',
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
                                        lidarrActivitySearchQueryProvider(
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
                                        lidarrActivitySearchQueryProvider(
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
                  ? <Widget>[
                      TextButton(
                        onPressed: () {
                          if (_subTabController.index == 0) {
                            final raw = ref
                                    .read(
                                      lidarrQueueProvider(widget.instance),
                                    )
                                    .value ??
                                <QueueResource>[];
                            ref
                                    .read(
                                      lidarrQueueSelectionProvider(
                                        widget.instance,
                                      ).notifier,
                                    )
                                    .state =
                                raw
                                    .where((QueueResource q) => q.id != null)
                                    .map((QueueResource q) => q.id!)
                                    .toSet();
                          } else if (_subTabController.index == 2) {
                            final raw = ref
                                    .read(
                                      lidarrBlocklistProvider(
                                        widget.instance,
                                      ),
                                    )
                                    .value ??
                                <BlocklistResource>[];
                            ref
                                .read(
                                  lidarrBlocklistSelectionProvider(
                                    widget.instance,
                                  ).notifier,
                                )
                                .state = raw
                                .where(
                                  (BlocklistResource b) => b.id != null,
                                )
                                .map((BlocklistResource b) => b.id!)
                                .toSet();
                          }
                        },
                        child: const Text('Select All'),
                      ),
                      TextButton(
                        onPressed: () {
                          if (_subTabController.index == 0) {
                            final raw = ref
                                    .read(
                                      lidarrQueueProvider(widget.instance),
                                    )
                                    .value ??
                                <QueueResource>[];
                            final Set<int> all = raw
                                .where((QueueResource q) => q.id != null)
                                .map((QueueResource q) => q.id!)
                                .toSet();
                            final Set<int> inverted =
                                all.difference(activeSelection);
                            ref
                                .read(
                                  lidarrQueueSelectionProvider(
                                    widget.instance,
                                  ).notifier,
                                )
                                .state = inverted;
                          } else if (_subTabController.index == 2) {
                            final raw = ref
                                    .read(
                                      lidarrBlocklistProvider(
                                        widget.instance,
                                      ),
                                    )
                                    .value ??
                                <BlocklistResource>[];
                            final Set<int> all = raw
                                .where((BlocklistResource b) => b.id != null)
                                .map((BlocklistResource b) => b.id!)
                                .toSet();
                            final Set<int> inverted =
                                all.difference(activeSelection);
                            ref
                                .read(
                                  lidarrBlocklistSelectionProvider(
                                    widget.instance,
                                  ).notifier,
                                )
                                .state = inverted;
                          }
                        },
                        child: const Text('Invert'),
                      ),
                      const SizedBox(width: 4),
                    ]
                  : <Widget>[
                      IconButton(
                        icon: Icon(
                          grouped
                              ? Icons.format_list_bulleted
                              : Icons.group_work_outlined,
                        ),
                        tooltip: grouped
                            ? 'Switch to plain list'
                            : 'Switch to grouped view',
                        onPressed: () {
                          ref
                              .read(
                                lidarrActivityGroupedProvider(
                                  widget.instance,
                                ).notifier,
                              )
                              .toggle();
                        },
                      ),
                      const SizedBox(width: 8),
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
                  Tab(text: 'Queue'),
                  Tab(text: 'History'),
                  Tab(text: 'Blocklist'),
                ],
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _subTabController,
          children: <Widget>[
            QueueView(instance: widget.instance),
            HistoryView(instance: widget.instance),
            BlocklistView(instance: widget.instance),
          ],
        ),
      ),
      floatingActionButton: !inSelectionMode
          ? AnimatedBuilder(
              animation: _subTabController,
              builder: (BuildContext context, Widget? child) {
                return _buildFab(context, theme, cs, grouped) ??
                    const SizedBox.shrink();
              },
            )
          : null,
    );
  }

  Widget? _buildFab(
    BuildContext context,
    ThemeData theme,
    ColorScheme cs,
    bool grouped,
  ) {
    if (_subTabController.index == 1) {
      final EntityHistoryEventType? historyFilter =
          ref.watch(lidarrHistoryEventTypeFilterProvider(widget.instance));
      final bool hasFilter = historyFilter != null;

      return FloatingActionButton(
        heroTag: 'lidarr_activity_history_filter_fab',
        backgroundColor: cs.primaryContainer,
        foregroundColor: cs.onPrimaryContainer,
        tooltip: 'Filter & Group History',
        onPressed: () => HistoryFilterBottomSheet.show(
          context,
          widget.instance,
        ),
        child: Badge(
          isLabelVisible: hasFilter,
          child: const Icon(Icons.tune),
        ),
      );
    }

    if (_subTabController.index == 0) {
      return FloatingActionButton(
        heroTag: 'lidarr_activity_manual_import_fab',
        backgroundColor: cs.primaryContainer,
        foregroundColor: cs.onPrimaryContainer,
        tooltip: 'Manual Import',
        onPressed: () => showLidarrManualImportFlow(
          context,
          ref,
          widget.instance,
        ),
        child: const Icon(Icons.drive_folder_upload_outlined),
      );
    }

    return null;
  }
}
