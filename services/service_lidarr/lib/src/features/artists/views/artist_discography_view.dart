import 'package:collection/collection.dart';
import 'package:core_models/core_models.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../generated/generated.dart';
import '../../../lidarr_api.dart';
import '../../../lidarr_providers.dart';
import '../widgets/album_card.dart';

/// Discography view presenting artist details overview, progress header, and categorized album slivers.
class ArtistDiscographyView extends ConsumerWidget {
  const ArtistDiscographyView({
    required this.instance,
    required this.artistId,
    required this.artist,
    required this.albums,
    super.key,
  });

  final Instance instance;
  final int artistId;
  final ArtistResource? artist;
  final List<AlbumResource> albums;

  Future<void> _toggleAlbumGroupMonitoring(
    BuildContext context,
    WidgetRef ref,
    List<AlbumResource> albums,
    bool monitored,
  ) async {
    final List<int> ids = albums.map((a) => a.id).whereType<int>().toList();
    if (ids.isEmpty) return;

    try {
      final LidarrApi api = await ref.read(lidarrApiProvider(instance).future);
      final ApiResponse<void> resp = await api.album.putAlbumMonitor(
        body: AlbumsMonitoredResource(
          albumIds: ids,
          monitored: monitored,
        ),
      );
      if (!resp.isSuccess) {
        throw Exception(resp.error?.message ?? 'Failed to update albums');
      }

      ref.invalidate(
        lidarrAlbumsForArtistProvider((instance, artistId)),
      );
      ref.invalidate(
        lidarrArtistByIdProvider((instance, artistId)),
      );
      ref.invalidate(lidarrArtistsProvider(instance));

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              monitored
                  ? 'Monitored ${ids.length} albums'
                  : 'Unmonitored ${ids.length} albums',
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update album monitoring: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  String _formatGroupTitle(String groupType) {
    return switch (groupType.toLowerCase()) {
      'studio' => 'Studio Albums',
      'album' => 'Albums',
      'ep' => 'EPs',
      'single' => 'Singles',
      'live' => 'Live Albums',
      'broadcast' => 'Broadcasts',
      'compilation' => 'Compilations',
      'soundtrack' => 'Soundtracks',
      _ => '$groupType Releases',
    };
  }

  List<Widget> _buildGroupedAlbumsSlivers(
    BuildContext context,
    WidgetRef ref,
    List<AlbumResource> albums,
  ) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;

    final Map<String, List<AlbumResource>> grouped = groupBy(
      albums,
      (AlbumResource a) => a.albumType ?? 'Other',
    );

    const List<String> canonicalOrder = [
      'Studio',
      'Album',
      'EP',
      'Single',
      'Live',
      'Broadcast',
      'Compilation',
      'Soundtrack',
      'Other',
    ];

    final List<MapEntry<String, List<AlbumResource>>> sortedEntries =
        grouped.entries.toList()
          ..sort((a, b) {
            final int indexA = canonicalOrder.indexOf(a.key);
            final int indexB = canonicalOrder.indexOf(b.key);
            final int rankA = indexA == -1 ? 999 : indexA;
            final int rankB = indexB == -1 ? 999 : indexB;
            if (rankA != rankB) return rankA.compareTo(rankB);
            return a.key.compareTo(b.key);
          });

    for (final entry in sortedEntries) {
      entry.value.sort((a, b) {
        final String dateA = a.releaseDate ?? '';
        final String dateB = b.releaseDate ?? '';
        return dateB.compareTo(dateA);
      });
    }

    final List<Widget> slivers = [];

    for (final MapEntry<String, List<AlbumResource>> entry in sortedEntries) {
      final String groupType = entry.key;
      final String groupTitle = _formatGroupTitle(groupType);
      final List<AlbumResource> groupAlbums = entry.value;
      final bool allMonitored = groupAlbums.every((a) => a.monitored == true);

      slivers.add(
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    '$groupTitle (${groupAlbums.length})',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: cs.primary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Tooltip(
                  message: allMonitored
                      ? 'Unmonitor all ${groupTitle.toLowerCase()}'
                      : 'Monitor all ${groupTitle.toLowerCase()}',
                  child: InkWell(
                    onTap: () => _toggleAlbumGroupMonitoring(
                      context,
                      ref,
                      groupAlbums,
                      !allMonitored,
                    ),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: allMonitored
                            ? cs.primaryContainer.withValues(alpha: 0.4)
                            : cs.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: allMonitored
                              ? cs.primary.withValues(alpha: 0.3)
                              : cs.outlineVariant.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            allMonitored
                                ? Icons.bookmark_added
                                : Icons.bookmark_add_outlined,
                            size: 15,
                            color:
                                allMonitored ? cs.primary : cs.onSurfaceVariant,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            allMonitored ? 'Monitored' : 'Unmonitored',
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: allMonitored
                                  ? cs.primary
                                  : cs.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      slivers.add(
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final AlbumResource album = groupAlbums[index];
                return AlbumCard(
                  instance: instance,
                  artistId: artistId,
                  album: album,
                );
              },
              childCount: groupAlbums.length,
            ),
          ),
        ),
      );
    }

    return slivers;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        if (albums.isEmpty)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: Center(
                child: EmptyView(
                  icon: Icons.album_outlined,
                  title: 'No Albums Found',
                  message: 'No albums available for this artist.',
                ),
              ),
            ),
          )
        else
          ..._buildGroupedAlbumsSlivers(context, ref, albums),
      ],
    );
  }
}
