import 'package:core_models/core_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../generated/generated.dart';
import '../../../lidarr_api.dart';
import '../../../state/api_providers.dart';

/// Releases found for an album during interactive search.
final lidarrReleasesForAlbumProvider =
    FutureProvider.autoDispose.family<List<ReleaseResource>, (Instance, int)>(
  (Ref ref, (Instance, int) key) async {
    final (Instance instance, int albumId) = key;
    final LidarrApi api = await ref.watch(lidarrApiProvider(instance).future);
    final ApiResponse<List<ReleaseResource>> resp =
        await api.release.getRelease(albumId: albumId);
    return unwrapLidarrApiResponse(
      resp,
      'Failed to fetch releases for album $albumId',
    );
  },
);

/// Releases found for an artist during interactive search.
final lidarrReleasesForArtistProvider =
    FutureProvider.autoDispose.family<List<ReleaseResource>, (Instance, int)>(
  (Ref ref, (Instance, int) key) async {
    final (Instance instance, int artistId) = key;
    final LidarrApi api = await ref.watch(lidarrApiProvider(instance).future);
    final ApiResponse<List<ReleaseResource>> resp =
        await api.release.getRelease(artistId: artistId);
    return unwrapLidarrApiResponse(
      resp,
      'Failed to fetch releases for artist $artistId',
    );
  },
);
