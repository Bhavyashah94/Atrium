import 'package:core_models/core_models.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../generated/generated.dart';
import '../../../lidarr_api.dart';
import '../../../lidarr_providers.dart';
import '../../albums/album_detail_screen.dart';
import '../../search/interactive_search_screen.dart';
import '../widgets/wanted_album_card.dart';

/// Missing wanted albums view with infinite scrolling, sorting, filtering, and batch selection.
class MissingView extends ConsumerStatefulWidget {
  const MissingView({required this.instance, super.key});

  final Instance instance;

  @override
  ConsumerState<MissingView> createState() => _MissingViewState();
}

class _MissingViewState extends ConsumerState<MissingView> {
  final ScrollController _scrollController = ScrollController();
  final List<AlbumResource> _albums = <AlbumResource>[];

  int _page = 1;
  static const int _pageSize = 40;
  int _totalRecords = 0;
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchInitial();
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  int _fetchGeneration = 0;

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final double maxScroll = _scrollController.position.maxScrollExtent;
    final double currentScroll = _scrollController.position.pixels;
    if (maxScroll - currentScroll <= 300) {
      if (!_isLoading && !_isLoadingMore && _hasMore) {
        _fetchMore();
      }
    }
  }

  Future<void> _fetchInitial() async {
    if (!mounted) return;
    final int gen = ++_fetchGeneration;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _page = 1;
      _albums.clear();
      _hasMore = true;
    });

    final bool monitored =
        ref.read(lidarrWantedMonitoredOnlyProvider(widget.instance));
    final WantedSortKey sortKey =
        ref.read(lidarrWantedSortKeyProvider(widget.instance));
    final bool sortAsc =
        ref.read(lidarrWantedSortAscendingProvider(widget.instance));

    try {
      final LidarrApi api =
          await ref.read(lidarrApiProvider(widget.instance).future);
      final ApiResponse<AlbumResourcePagingResource> resp =
          await api.missing.getWantedMissing(
        page: 1,
        pageSize: _pageSize,
        includeArtist: true,
        monitored: monitored ? true : null,
        sortKey: sortKey.value,
        sortDirection:
            sortAsc ? SortDirection.ascending : SortDirection.descending,
      );

      if (gen != _fetchGeneration || !mounted) return;

      final AlbumResourcePagingResource data =
          unwrapLidarrApiResponse(resp, 'Failed to load missing albums');

      final List<AlbumResource> items = data.records ?? <AlbumResource>[];
      _totalRecords = data.totalRecords ?? items.length;

      setState(() {
        _albums.addAll(items);
        _isLoading = false;
        _hasMore = _albums.length < _totalRecords && items.isNotEmpty;
      });
    } catch (e) {
      if (gen != _fetchGeneration || !mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  Future<void> _fetchMore() async {
    if (_isLoadingMore || !_hasMore) return;
    final int gen = _fetchGeneration;
    setState(() {
      _isLoadingMore = true;
    });

    final int nextPage = _page + 1;
    final bool monitored =
        ref.read(lidarrWantedMonitoredOnlyProvider(widget.instance));
    final WantedSortKey sortKey =
        ref.read(lidarrWantedSortKeyProvider(widget.instance));
    final bool sortAsc =
        ref.read(lidarrWantedSortAscendingProvider(widget.instance));

    try {
      final LidarrApi api =
          await ref.read(lidarrApiProvider(widget.instance).future);
      final ApiResponse<AlbumResourcePagingResource> resp =
          await api.missing.getWantedMissing(
        page: nextPage,
        pageSize: _pageSize,
        includeArtist: true,
        monitored: monitored ? true : null,
        sortKey: sortKey.value,
        sortDirection:
            sortAsc ? SortDirection.ascending : SortDirection.descending,
      );

      if (gen != _fetchGeneration || !mounted) return;

      final AlbumResourcePagingResource data =
          unwrapLidarrApiResponse(resp, 'Failed to load missing albums');

      final List<AlbumResource> items = data.records ?? <AlbumResource>[];
      _totalRecords = data.totalRecords ?? _totalRecords;

      setState(() {
        _page = nextPage;
        _albums.addAll(items);
        _isLoadingMore = false;
        _hasMore = _albums.length < _totalRecords && items.isNotEmpty;
      });
    } catch (e) {
      if (gen != _fetchGeneration || !mounted) return;
      setState(() {
        _isLoadingMore = false;
      });
    }
  }

  void _toggleSelection(int? id) {
    if (id == null) return;
    final Set<int> current =
        ref.read(lidarrWantedSelectionProvider(widget.instance));
    final Set<int> updated = Set<int>.from(current);
    if (updated.contains(id)) {
      updated.remove(id);
    } else {
      updated.add(id);
    }
    ref.read(lidarrWantedSelectionProvider(widget.instance).notifier).state =
        updated;
  }

  Future<void> _searchSingle(AlbumResource album) async {
    final int? id = album.id;
    if (id == null) return;

    try {
      final LidarrApi api =
          await ref.read(lidarrApiProvider(widget.instance).future);
      final ApiResponse<CommandResource> resp =
          await api.executeCommand('AlbumSearch', <String, dynamic>{
        'albumIds': <int>[id],
      });

      if (!resp.isSuccess) {
        throw Exception(resp.error?.message ?? 'Failed to start search');
      }

      ref.invalidate(lidarrQueueProvider(widget.instance));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Search started for "${album.title}".'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Search failed: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _toggleAlbumMonitoring(AlbumResource album) async {
    final int? id = album.id;
    if (id == null) return;

    final bool newMonitored = !(album.monitored ?? true);

    try {
      final LidarrApi api =
          await ref.read(lidarrApiProvider(widget.instance).future);
      final ApiResponse<void> resp = await api.album.putAlbumMonitor(
        body: AlbumsMonitoredResource(
          albumIds: <int>[id],
          monitored: newMonitored,
        ),
      );

      if (!resp.isSuccess) {
        throw Exception(
          resp.error?.message ?? 'Failed to update album monitoring',
        );
      }

      final int index = _albums.indexWhere((AlbumResource a) => a.id == id);
      if (index != -1 && mounted) {
        setState(() {
          _albums[index] = album.copyWith(monitored: newMonitored);
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              newMonitored
                  ? 'Monitoring enabled for "${album.title}"'
                  : 'Monitoring disabled for "${album.title}"',
            ),
            duration: const Duration(seconds: 2),
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

    // Listen for filter/sort changes from Header or Sheet
    ref.listen(
      lidarrWantedMonitoredOnlyProvider(widget.instance),
      (_, __) => _fetchInitial(),
    );
    ref.listen(
      lidarrWantedSortKeyProvider(widget.instance),
      (_, __) => _fetchInitial(),
    );
    ref.listen(
      lidarrWantedSortAscendingProvider(widget.instance),
      (_, __) => _fetchInitial(),
    );

    final String searchQuery =
        ref.watch(lidarrWantedSearchQueryProvider(widget.instance));
    final Set<int> selectedIds =
        ref.watch(lidarrWantedSelectionProvider(widget.instance));
    final bool isSelectionMode = selectedIds.isNotEmpty;

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(Icons.error_outline, size: 48, color: cs.error),
            const SizedBox(height: 12),
            Text(
              'Failed to load missing albums',
              style: theme.textTheme.titleMedium?.copyWith(color: cs.error),
            ),
            const SizedBox(height: 8),
            FilledButton.tonal(
              onPressed: _fetchInitial,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    // Filter displayed list by search query in-memory
    List<AlbumResource> displayed = _albums;
    if (searchQuery.trim().isNotEmpty) {
      final String q = searchQuery.trim().toLowerCase();
      displayed = displayed.where((AlbumResource a) {
        final String title = (a.title ?? '').toLowerCase();
        final String artist = (a.artist?.artistName ?? '').toLowerCase();
        return title.contains(q) || artist.contains(q);
      }).toList();
    }

    if (displayed.isEmpty) {
      return EasyRefresh(
        onRefresh: _fetchInitial,
        child: ListView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          children: <Widget>[
            SizedBox(height: MediaQuery.of(context).size.height * 0.25),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Icon(
                    Icons.album_outlined,
                    size: 48,
                    color: cs.outlineVariant,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    searchQuery.trim().isNotEmpty
                        ? 'No missing albums match "$searchQuery"'
                        : 'No missing albums found',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return EasyRefresh(
      onRefresh: _fetchInitial,
      child: ListView.builder(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(top: 8, bottom: 80),
        itemCount: displayed.length + (_hasMore ? 1 : 0),
        itemBuilder: (BuildContext context, int index) {
          if (index == displayed.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                ),
              ),
            );
          }

          final AlbumResource album = displayed[index];
          final bool isSelected = selectedIds.contains(album.id);

          return WantedAlbumCard(
            instance: widget.instance,
            album: album,
            isSelected: isSelected,
            isSelectionMode: isSelectionMode,
            onToggleSelected: () => _toggleSelection(album.id),
            onToggleMonitored: () => _toggleAlbumMonitoring(album),
            onSearch: () => _searchSingle(album),
            onInteractiveSearch: () {
              if (album.id == null) return;
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => LidarrInteractiveSearchScreen(
                    instance: widget.instance,
                    albumId: album.id,
                    title: album.title ?? 'Album',
                  ),
                ),
              );
            },
            onTap: () {
              if (album.id == null || album.artistId == null) return;
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => AlbumDetailScreen(
                    instance: widget.instance,
                    artistId: album.artistId!,
                    albumId: album.id!,
                    initialAlbum: album,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
