import 'package:core_models/core_models.dart';
import 'package:core_networking/core_networking.dart';
import 'package:core_storage/core_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../generated/generated.dart';
import '../../../lidarr_api.dart';
import '../../../state/api_providers.dart';
import '../models/artist_filter_sort.dart';

export '../models/artist_filter_sort.dart';

/// All artists for an instance, sorted by name. Polls every 60s while watched.
final lidarrArtistsProvider =
    FutureProvider.autoDispose.family<List<ArtistResource>, Instance>((
  Ref ref,
  Instance instance,
) async {
  ref.pollEvery(lidarrLibraryPollInterval);
  final LidarrApi api = await ref.watch(lidarrApiProvider(instance).future);
  final ApiResponse<List<ArtistResource>> resp = await api.artist.getArtist();
  final List<ArtistResource> artists = List<ArtistResource>.from(
    unwrapLidarrApiResponse(resp, 'Failed to load artists'),
  );
  artists.sort(
    (ArtistResource a, ArtistResource b) => (a.sortName ?? a.artistName ?? '')
        .toLowerCase()
        .compareTo((b.sortName ?? b.artistName ?? '').toLowerCase()),
  );
  return artists;
});

/// Detailed information for a single artist.
final lidarrArtistDetailProvider = FutureProvider.autoDispose
    .family<ArtistResource, (Instance, int)>((Ref ref, (Instance, int) key) async {
  final (Instance instance, int artistId) = key;
  final LidarrApi api = await ref.watch(lidarrApiProvider(instance).future);
  final ApiResponse<ArtistResource> resp =
      await api.artist.getArtistById(id: artistId);
  return unwrapLidarrApiResponse(
    resp,
    'Failed to load artist details for $artistId',
  );
});

/// Alias for [lidarrArtistDetailProvider].
final lidarrArtistByIdProvider = lidarrArtistDetailProvider;

/// All albums for a specific artist.
final lidarrArtistAlbumsProvider = FutureProvider.autoDispose
    .family<List<AlbumResource>, (Instance, int)>(
        (Ref ref, (Instance, int) key) async {
  final (Instance instance, int artistId) = key;
  final LidarrApi api = await ref.watch(lidarrApiProvider(instance).future);
  final ApiResponse<List<AlbumResource>> resp =
      await api.album.getAlbum(artistId: artistId);
  final List<AlbumResource> albums = List<AlbumResource>.from(
    unwrapLidarrApiResponse(resp, 'Failed to load albums for artist $artistId'),
  );
  albums.sort((AlbumResource a, AlbumResource b) {
    final String dateA = a.releaseDate ?? '';
    final String dateB = b.releaseDate ?? '';
    return dateB.compareTo(dateA); // Newest first
  });
  return albums;
});

/// Alias for [lidarrArtistAlbumsProvider].
final lidarrAlbumsForArtistProvider = lidarrArtistAlbumsProvider;

/// All track files belonging to an artist.
final lidarrArtistTrackFilesProvider = FutureProvider.autoDispose
    .family<List<TrackFileResource>, (Instance, int)>(
        (Ref ref, (Instance, int) key) async {
  final (Instance instance, int artistId) = key;
  final LidarrApi api = await ref.watch(lidarrApiProvider(instance).future);
  final ApiResponse<List<TrackFileResource>> resp =
      await api.trackFile.getTrackfile(artistId: artistId);
  return unwrapLidarrApiResponse(
    resp,
    'Failed to load track files for artist $artistId',
  );
});

/// All unmapped track files belonging to an artist.
final lidarrArtistUnmappedTrackFilesProvider = FutureProvider.autoDispose
    .family<List<TrackFileResource>, (Instance, int)>(
        (Ref ref, (Instance, int) key) async {
  final (Instance instance, int artistId) = key;
  final LidarrApi api = await ref.watch(lidarrApiProvider(instance).future);
  final ApiResponse<List<TrackFileResource>> resp =
      await api.trackFile.getTrackfile(artistId: artistId, unmapped: true);
  return unwrapLidarrApiResponse(
    resp,
    'Failed to load unmapped track files for artist $artistId',
  );
});

/// Persistent view mode preference for Lidarr artists (Grid vs List).
final lidarrViewModeProvider =
    NotifierProvider.family<LidarrViewModeNotifier, LidarrViewMode, Instance>(
  LidarrViewModeNotifier.new,
);

class LidarrViewModeNotifier extends Notifier<LidarrViewMode> {
  LidarrViewModeNotifier(this.instance);

  final Instance instance;

  static String _keyFor(String instanceId) => 'lidarr.viewMode.$instanceId';

  Box<String>? get _box => Hive.isBoxOpen(AtriumBoxes.settings)
      ? Hive.box<String>(AtriumBoxes.settings)
      : null;

  @override
  LidarrViewMode build() {
    final String? raw = _box?.get(_keyFor(instance.id));
    if (raw == 'list') return LidarrViewMode.list;
    if (raw == 'grid') return LidarrViewMode.grid;
    return LidarrViewMode.grid;
  }

  void setViewMode(LidarrViewMode mode) {
    state = mode;
    _box?.put(_keyFor(instance.id), mode.name);
  }
}

/// Single album by ID. Refreshed on demand.
final lidarrAlbumByIdProvider =
    FutureProvider.autoDispose.family<AlbumResource, (Instance, int)>((
  Ref ref,
  (Instance, int) key,
) async {
  final (Instance instance, int id) = key;
  final LidarrApi api = await ref.watch(lidarrApiProvider(instance).future);
  final ApiResponse<AlbumResource> resp = await api.album.getAlbumById(id: id);
  return unwrapLidarrApiResponse(resp, 'Failed to load album $id');
});

/// All tracks for an album. Refreshed on demand.
final lidarrTracksForAlbumProvider = FutureProvider.autoDispose
    .family<List<TrackResource>, (Instance, int, int)>((
  Ref ref,
  (Instance, int, int) key,
) async {
  final (Instance instance, int artistId, int albumId) = key;
  final LidarrApi api = await ref.watch(lidarrApiProvider(instance).future);
  final ApiResponse<List<TrackResource>> resp = await api.track.getTrack(
    artistId: artistId,
    albumId: albumId,
  );
  final List<TrackResource> tracks = List<TrackResource>.from(
    unwrapLidarrApiResponse(resp, 'Failed to load tracks for album $albumId'),
  );
  // Sort tracks by track number
  tracks.sort((a, b) {
    final int numA =
        int.tryParse(a.trackNumber ?? '') ?? a.absoluteTrackNumber ?? 0;
    final int numB =
        int.tryParse(b.trackNumber ?? '') ?? b.absoluteTrackNumber ?? 0;
    return numA.compareTo(numB);
  });
  return tracks;
});

/// Track files for a specific album, exposing media info and file details.
final lidarrTrackFilesForAlbumProvider =
    FutureProvider.autoDispose.family<List<TrackFileResource>, (Instance, int)>(
  (Ref ref, (Instance, int) key) async {
    final (Instance instance, int albumId) = key;
    final LidarrApi api = await ref.watch(lidarrApiProvider(instance).future);
    final ApiResponse<List<TrackFileResource>> resp =
        await api.trackFile.getTrackfile(albumId: <int>[albumId]);
    return unwrapLidarrApiResponse(
      resp,
      'Failed to load track files for album $albumId',
    );
  },
);

/// Track files for a specific artist, exposing all managed audio files.
final lidarrTrackFilesForArtistProvider =
    FutureProvider.autoDispose.family<List<TrackFileResource>, (Instance, int)>(
  (Ref ref, (Instance, int) key) async {
    final (Instance instance, int artistId) = key;
    final LidarrApi api = await ref.watch(lidarrApiProvider(instance).future);
    final ApiResponse<List<TrackFileResource>> resp =
        await api.trackFile.getTrackfile(artistId: artistId);
    return unwrapLidarrApiResponse(
      resp,
      'Failed to load track files for artist $artistId',
    );
  },
);

/// Unmapped track files for a specific artist.
final lidarrUnmappedTrackFilesForArtistProvider =
    FutureProvider.autoDispose.family<List<TrackFileResource>, (Instance, int)>(
  (Ref ref, (Instance, int) key) async {
    final (Instance instance, int artistId) = key;
    final LidarrApi api = await ref.watch(lidarrApiProvider(instance).future);
    final ApiResponse<List<TrackFileResource>> resp =
        await api.trackFile.getTrackfile(artistId: artistId, unmapped: true);
    return unwrapLidarrApiResponse(
      resp,
      'Failed to load unmapped track files for artist $artistId',
    );
  },
);

/// Active artist sort option.
final lidarrArtistSortProvider =
    StateProvider.family<LidarrArtistSort, Instance>((ref, instance) {
  return LidarrArtistSort.name;
});

/// Active artist sort direction (true = ascending, false = descending).
final lidarrArtistSortAscendingProvider =
    StateProvider.family<bool, Instance>((ref, instance) {
  return true;
});

/// Active artist filter option.
final lidarrArtistFilterProvider =
    StateProvider.family<LidarrArtistFilter, Instance>((ref, instance) {
  return LidarrArtistFilter.all;
});

/// Active search query in Artists tab.
final lidarrSearchQueryProvider =
    StateProvider.family<String, Instance>((ref, instance) {
  return '';
});

/// Online search for artists on MusicBrainz via Lidarr.
final lidarrArtistLookupProvider = FutureProvider.autoDispose
    .family<List<ArtistResource>, (Instance, String)>((
  Ref ref,
  (Instance, String) key,
) async {
  final (Instance instance, String term) = key;
  if (term.trim().isEmpty) return <ArtistResource>[];
  final LidarrApi api = await ref.watch(lidarrApiProvider(instance).future);
  final ApiResponse<List<ArtistResource>> resp =
      await api.artistLookup.getArtistLookup(term: term.trim());
  return unwrapLidarrApiResponse(
    resp,
    'Failed to look up artists for "$term"',
  );
});
