import 'package:core_models/core_models.dart';
import 'package:easy_refresh/easy_refresh.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/tracearr_v2_models.dart';
import '../tracearr_providers.dart';
import '../utils/tracearr_formatters.dart';

/// Libraries tab displaying library rollup cards with item counts and server types.
class TracearrLibrariesTab extends ConsumerStatefulWidget {
  const TracearrLibrariesTab({
    required this.instance,
    super.key,
  });

  final Instance instance;

  @override
  ConsumerState<TracearrLibrariesTab> createState() => _TracearrLibrariesTabState();
}

class _TracearrLibrariesTabState extends ConsumerState<TracearrLibrariesTab> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AsyncValue<TracearrV2LibrariesResponse> asyncLibraries =
        ref.watch(tracearrV2GetLibrariesProvider(widget.instance));

    return EasyRefresh(
      header: const ClassicHeader(
        position: IndicatorPosition.locator,
      ),
      onRefresh: () =>
          ref.refresh(tracearrV2GetLibrariesProvider(widget.instance).future),
      child: asyncLibraries.when(
        data: (TracearrV2LibrariesResponse response) {
          final List<TracearrV2LibraryRollup> allLibraries = response.data;

          final List<TracearrV2LibraryRollup> filteredLibraries = allLibraries.where((TracearrV2LibraryRollup lib) {
            if (_searchQuery.isEmpty) return true;
            final String query = _searchQuery.toLowerCase();
            final String name = lib.name.toLowerCase();
            final String type = lib.type.toLowerCase();
            return name.contains(query) || type.contains(query);
          }).toList();

          return CustomScrollView(
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
                  hintText: 'Search libraries...',
                  onTapOutside: (_) {
                    if (_searchFocusNode.hasFocus) {
                      _searchFocusNode.unfocus();
                    }
                  },
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
                    icon: const Icon(Icons.refresh),
                    tooltip: 'Refresh Libraries',
                    onPressed: () =>
                        ref.refresh(tracearrV2GetLibrariesProvider(widget.instance).future),
                  ),
                  const SizedBox(width: 8),
                ],
              ),
              const HeaderLocator.sliver(),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: <Widget>[
                      _LibrariesSummaryBanner(libraries: allLibraries),
                    ],
                  ),
                ),
              ),
              if (filteredLibraries.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Icon(
                          Icons.video_library_outlined,
                          size: 64,
                          color: Theme.of(context).colorScheme.outline,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          allLibraries.isEmpty ? 'No Libraries Configured' : 'No Matching Libraries',
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
                        return _LibraryRollupCard(
                          library: filteredLibraries[index],
                          instance: widget.instance,
                        );
                      },
                      childCount: filteredLibraries.length,
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
              Text('Failed to load libraries: $error'),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => ref.invalidate(tracearrV2GetLibrariesProvider(widget.instance)),
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


class _LibrariesSummaryBanner extends StatelessWidget {
  const _LibrariesSummaryBanner({required this.libraries});

  final List<TracearrV2LibraryRollup> libraries;

  @override
  Widget build(BuildContext context) {
    int totalMovies = 0;
    int totalShows = 0;
    int totalBytes = 0;

    for (final TracearrV2LibraryRollup lib in libraries) {
      totalMovies += lib.movieCount ?? 0;
      totalShows += lib.showCount ?? 0;
      totalBytes += lib.totalFileSize ?? 0;
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: <Widget>[
          _LibStat(
            icon: Icons.video_library,
            label: 'Libraries',
            value: '${libraries.length}',
            color: Theme.of(context).colorScheme.primary,
          ),
          _LibStat(
            icon: Icons.movie_outlined,
            label: 'Movies',
            value: '$totalMovies',
            color: Theme.of(context).colorScheme.tertiary,
          ),
          _LibStat(
            icon: Icons.tv_outlined,
            label: 'Shows',
            value: '$totalShows',
            color: Theme.of(context).colorScheme.secondary,
          ),
          _LibStat(
            icon: Icons.sd_storage_outlined,
            label: 'Disk Usage',
            value: formatTracearrBytes(totalBytes),
            color: Theme.of(context).colorScheme.error,
          ),
        ],
      ),
    );
  }
}

class _LibStat extends StatelessWidget {
  const _LibStat({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _LibraryRollupCard extends ConsumerWidget {
  const _LibraryRollupCard({required this.library, required this.instance});

  final TracearrV2LibraryRollup library;
  final Instance instance;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Map<String, String> serverMap =
        ref.watch(tracearrServerNamesMapProvider(instance));
    final String serverDisplayName = resolveServerName(
      serverMap: serverMap,
      serverName: library.serverName,
      serverId: library.serverId,
      serverType: library.serverType,
    );
    final int items = library.itemCount ?? 0;
    final int movies = library.movieCount ?? 0;
    final int shows = library.showCount ?? 0;
    final int episodes = library.episodeCount ?? 0;
    final int tracks = library.trackCount ?? 0;
    final int fileSize = library.totalFileSize ?? 0;
    final Map<String, dynamic> resolutions =
        library.resolutions ?? <String, dynamic>{};

    final String libraryTitle = (library.name.isNotEmpty && !isUuid(library.name))
        ? library.name
        : (library.libraryId != null && library.libraryId!.isNotEmpty
            ? 'Library ${library.libraryId}'
            : 'Media Library');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                CircleAvatar(
                  radius: 20,
                  backgroundColor:
                      Theme.of(context).colorScheme.primaryContainer,
                  child: Icon(
                    movies > 0
                        ? Icons.movie_outlined
                        : shows > 0 || episodes > 0
                            ? Icons.tv_outlined
                            : Icons.library_music_outlined,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        libraryTitle,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Server: $serverDisplayName',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: <Widget>[
                    Text(
                      '$items items',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    if (fileSize > 0)
                      Text(
                        formatTracearrBytes(fileSize),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.tertiary,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: <Widget>[
                if (movies > 0)
                  Chip(
                    visualDensity: VisualDensity.compact,
                    label: Text('$movies movies', style: const TextStyle(fontSize: 11)),
                  ),
                if (shows > 0)
                  Chip(
                    visualDensity: VisualDensity.compact,
                    label: Text('$shows shows', style: const TextStyle(fontSize: 11)),
                  ),
                if (episodes > 0)
                  Chip(
                    visualDensity: VisualDensity.compact,
                    label: Text('$episodes episodes', style: const TextStyle(fontSize: 11)),
                  ),
                if (tracks > 0)
                  Chip(
                    visualDensity: VisualDensity.compact,
                    label: Text('$tracks tracks', style: const TextStyle(fontSize: 11)),
                  ),
                ...resolutions.entries.map((MapEntry<String, dynamic> entry) {
                  final String resLabel = entry.key;
                  final int resCount = entry.value as int? ?? 0;
                  if (resCount <= 0 || resLabel == 'unknown') {
                    return const SizedBox.shrink();
                  }
                  return Chip(
                    visualDensity: VisualDensity.compact,
                    backgroundColor:
                        Theme.of(context).colorScheme.secondaryContainer,
                    label: Text(
                      '$resLabel: $resCount',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSecondaryContainer,
                      ),
                    ),
                  );
                }),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
