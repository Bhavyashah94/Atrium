import 'package:cached_network_image/cached_network_image.dart';
import 'package:core_models/core_models.dart';
import 'package:easy_refresh/easy_refresh.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/tracearr_v2_models.dart';
import '../tracearr_api.dart';
import '../tracearr_media_detail_screen.dart';
import '../tracearr_providers.dart';
import '../utils/tracearr_formatters.dart';

/// Recently Added tab displaying responsive poster grid (Sonarr style).
class TracearrRecentlyAddedTab extends ConsumerStatefulWidget {
  const TracearrRecentlyAddedTab({
    required this.instance,
    super.key,
  });

  final Instance instance;

  @override
  ConsumerState<TracearrRecentlyAddedTab> createState() =>
      _TracearrRecentlyAddedTabState();
}

class _TracearrRecentlyAddedTabState
    extends ConsumerState<TracearrRecentlyAddedTab>
    with WidgetsBindingObserver {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  double _lastBottomInset = 0;

  final List<TracearrV2RecentlyAddedRecord> _appendedItems =
      <TracearrV2RecentlyAddedRecord>[];
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
      final TracearrV2RecentlyAddedResponse nextResp =
          await api.getRecentlyAdded(cursor: _nextCursor, pageSize: 100);

      setState(() {
        _appendedItems.addAll(nextResp.data);
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
    final AsyncValue<TracearrV2RecentlyAddedResponse> asyncRecentlyAdded =
        ref.watch(tracearrV2GetRecentlyAddedProvider(widget.instance));
    final String selectedTypeFilter =
        ref.watch(tracearrRecentTypeFilterProvider(widget.instance));
    final String sortBy =
        ref.watch(tracearrRecentSortByProvider(widget.instance));
    final bool isGridView =
        ref.watch(tracearrRecentGridViewProvider(widget.instance));

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
          _appendedItems.clear();
          _nextCursor = null;
          _hasMore = true;
        });
        return ref.refresh(tracearrV2GetRecentlyAddedProvider(widget.instance).future);
      },
      onLoad: _hasMore ? _loadNextPage : null,
      child: asyncRecentlyAdded.when(
        data: (TracearrV2RecentlyAddedResponse response) {
          if (_appendedItems.isEmpty) {
            _nextCursor = response.meta?.nextCursor;
            _hasMore = _nextCursor != null && _nextCursor!.isNotEmpty;
          }

          final List<TracearrV2RecentlyAddedRecord> allItems =
              <TracearrV2RecentlyAddedRecord>[
            ...response.data,
            ..._appendedItems,
          ];

          final List<TracearrV2RecentlyAddedRecord> filteredItems =
              allItems.where((TracearrV2RecentlyAddedRecord item) {
            final String type = item.type.toUpperCase();
            if (selectedTypeFilter != 'ALL' && type != selectedTypeFilter) {
              return false;
            }
            if (_searchQuery.isEmpty) return true;
            final String query = _searchQuery.toLowerCase();
            final String title = (item.title ?? '').toLowerCase();
            return title.contains(query);
          }).toList();

          // Sort items
          filteredItems.sort((TracearrV2RecentlyAddedRecord a, TracearrV2RecentlyAddedRecord b) {
            if (sortBy == 'title') {
              return (a.title ?? '').compareTo(b.title ?? '');
            } else if (sortBy == 'year') {
              return (b.year ?? 0).compareTo(a.year ?? 0);
            }
            // default: added
            return (b.addedAt ?? '').compareTo(a.addedAt ?? '');
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
                  hintText: 'Search recently added...',
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
                    icon: Icon(isGridView ? Icons.view_list : Icons.grid_view),
                    tooltip: isGridView ? 'Switch to List View' : 'Switch to Grid View',
                    onPressed: () {
                      ref
                          .read(tracearrRecentGridViewProvider(widget.instance).notifier)
                          .state = !isGridView;
                    },
                  ),
                  const SizedBox(width: 8),
                ],
              ),
              const HeaderLocator.sliver(),
              if (filteredItems.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Icon(
                          Icons.movie_filter_outlined,
                          size: 64,
                          color: Theme.of(context).colorScheme.outline,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          allItems.isEmpty
                              ? 'No Recently Added Media'
                              : 'No Matching Media',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                  ),
                )
              else if (isGridView)
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 150,
                      childAspectRatio: 0.54,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (BuildContext context, int index) {
                        return _RecentlyAddedPosterCard(
                          instance: widget.instance,
                          item: filteredItems[index],
                        );
                      },
                      childCount: filteredItems.length,
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (BuildContext context, int index) {
                        return _RecentlyAddedListTile(
                          instance: widget.instance,
                          item: filteredItems[index],
                        );
                      },
                      childCount: filteredItems.length,
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
              Text('Failed to load recently added: $error'),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => ref.invalidate(
                  tracearrV2GetRecentlyAddedProvider(widget.instance),
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

class _RecentlyAddedPosterCard extends ConsumerWidget {
  const _RecentlyAddedPosterCard({
    required this.instance,
    required this.item,
  });

  final Instance instance;
  final TracearrV2RecentlyAddedRecord item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final TracearrApi? api = ref.watch(tracearrApiProvider(instance)).value;
    final Map<String, String> serverMap =
        ref.watch(tracearrServerNamesMapProvider(instance));
    final String title = item.title ?? 'Untitled';
    final String type = item.type;
    final String? mediaRef = item.mediaId ?? item.ratingKey ?? item.id;
    final String serverDisplayName = resolveServerName(
      serverMap: serverMap,
      serverId: item.serverId,
      serverType: item.serverType,
    );

    // Reconstruct image proxy URL
    String? reconstructedPath;
    final String? serverType = item.serverType;
    final String? ratingKey = item.ratingKey;
    final String? serverId = item.serverId;

    if (ratingKey != null && ratingKey.isNotEmpty && serverId != null) {
      if (serverType == 'plex') {
        reconstructedPath =
            '/api/v1/images/proxy?server=$serverId&url=${Uri.encodeComponent('/library/metadata/$ratingKey/thumb')}';
      } else if (serverType == 'jellyfin' || serverType == 'emby') {
        reconstructedPath =
            '/api/v1/images/proxy?server=$serverId&url=${Uri.encodeComponent('/Items/$ratingKey/Images/Primary')}';
      }
    }

    final String? posterUrl = api?.imageUrl(reconstructedPath);

    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: <Widget>[
                  if (posterUrl != null)
                    CachedNetworkImage(
                      imageUrl: posterUrl,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) =>
                          _buildFallback(context, type),
                    )
                  else
                    _buildFallback(context, type),
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .surface
                            .withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        type.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.year != null
                        ? '${item.year} • $serverDisplayName'
                        : serverDisplayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFallback(BuildContext context, String type) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHigh,
        gradient: LinearGradient(
          colors: <Color>[
            Theme.of(context).colorScheme.surfaceContainerHighest,
            Theme.of(context).colorScheme.surfaceContainerHigh,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(
          type == 'show' || type == 'episode'
              ? Icons.tv_outlined
              : Icons.movie_outlined,
          size: 48,
          color: Theme.of(context).colorScheme.outline,
        ),
      ),
    );
  }
}

class _RecentlyAddedListTile extends ConsumerWidget {
  const _RecentlyAddedListTile({
    required this.instance,
    required this.item,
  });

  final Instance instance;
  final TracearrV2RecentlyAddedRecord item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final TracearrApi? api = ref.watch(tracearrApiProvider(instance)).value;
    final Map<String, String> serverMap =
        ref.watch(tracearrServerNamesMapProvider(instance));
    final String title = item.title ?? 'Untitled';
    final String type = item.type;
    final String? mediaRef = item.mediaId ?? item.ratingKey ?? item.id;
    final String serverDisplayName = resolveServerName(
      serverMap: serverMap,
      serverId: item.serverId,
      serverType: item.serverType,
    );

    String? reconstructedPath;
    final String? serverType = item.serverType;
    final String? ratingKey = item.ratingKey;
    final String? serverId = item.serverId;

    if (ratingKey != null && ratingKey.isNotEmpty && serverId != null) {
      if (serverType == 'plex') {
        reconstructedPath =
            '/api/v1/images/proxy?server=$serverId&url=${Uri.encodeComponent('/library/metadata/$ratingKey/thumb')}';
      } else if (serverType == 'jellyfin' || serverType == 'emby') {
        reconstructedPath =
            '/api/v1/images/proxy?server=$serverId&url=${Uri.encodeComponent('/Items/$ratingKey/Images/Primary')}';
      }
    }

    final String? posterUrl = api?.imageUrl(reconstructedPath);

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
                      child: Icon(
                        type == 'show' || type == 'episode'
                            ? Icons.tv_outlined
                            : Icons.movie_outlined,
                        size: 24,
                      ),
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
                child: Icon(
                  type == 'show' || type == 'episode'
                      ? Icons.tv_outlined
                      : Icons.movie_outlined,
                  size: 24,
                ),
              ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          <String>[
            type.toUpperCase(),
            if (item.year != null) '${item.year}',
            serverDisplayName,
          ].join(' • '),
          style: Theme.of(context).textTheme.bodySmall,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: const Icon(Icons.chevron_right),
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
  }
}

class TracearrRecentlyAddedSortFilterBottomSheet extends ConsumerWidget {
  const TracearrRecentlyAddedSortFilterBottomSheet({required this.instance, super.key});

  final Instance instance;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final selectedTypeFilter = ref.watch(tracearrRecentTypeFilterProvider(instance));
    final sortBy = ref.watch(tracearrRecentSortByProvider(instance));
    final isGridView = ref.watch(tracearrRecentGridViewProvider(instance));

    final AsyncValue<TracearrV2RecentlyAddedResponse> asyncRecentlyAdded =
        ref.watch(tracearrV2GetRecentlyAddedProvider(instance));
    
    final Set<String> availableTypes = asyncRecentlyAdded.asData?.value.data
            .map((TracearrV2RecentlyAddedRecord e) => e.type.toUpperCase())
            .where((String t) => t.isNotEmpty)
            .toSet() ??
        <String>{};

    final List<String> typeFilterOptions = <String>[
      'ALL',
      ...availableTypes.toList()..sort(),
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
                            .read(tracearrRecentTypeFilterProvider(instance).notifier)
                            .state = f;
                      }
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              Text(
                'Sort By',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: <String>['added', 'title', 'year'].map((field) {
                  final label = switch (field) {
                    'title' => 'Title (A-Z)',
                    'year' => 'Year (Newest)',
                    _ => 'Date Added',
                  };
                  return ChoiceChip(
                    label: Text(label),
                    selected: sortBy == field,
                    onSelected: (val) {
                      if (val) {
                        ref
                            .read(tracearrRecentSortByProvider(instance).notifier)
                            .state = field;
                      }
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              Text(
                'View Mode',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              SegmentedButton<bool>(
                segments: const <ButtonSegment<bool>>[
                  ButtonSegment<bool>(
                    value: true,
                    label: Text('Grid View'),
                    icon: Icon(Icons.grid_view_rounded),
                  ),
                  ButtonSegment<bool>(
                    value: false,
                    label: Text('List View'),
                    icon: Icon(Icons.view_list_rounded),
                  ),
                ],
                selected: {isGridView},
                onSelectionChanged: (val) {
                  ref
                      .read(tracearrRecentGridViewProvider(instance).notifier)
                      .state = val.first;
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
