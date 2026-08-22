import 'package:core_models/core_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../generated/generated.dart';
import '../../../lidarr_api.dart';
import '../../../state/api_providers.dart';

/// Last used manual import path per instance.
final lidarrManualImportPathProvider =
    StateProvider.family<String, Instance>((Ref ref, Instance instance) => '');

/// Rename preview files for an artist or specific album.
final lidarrRenamePreviewProvider = FutureProvider.autoDispose
    .family<List<RenameTrackResource>, (Instance, int, int?)>(
  (Ref ref, (Instance, int, int?) key) async {
    final (Instance instance, int artistId, int? albumId) = key;
    final LidarrApi api = await ref.watch(lidarrApiProvider(instance).future);
    final ApiResponse<List<RenameTrackResource>> resp =
        await api.renameTrack.getRename(
      artistId: artistId,
      albumId: albumId,
    );
    return unwrapLidarrApiResponse(resp, 'Failed to load rename preview');
  },
);

/// Retag preview files for an artist or specific album.
final lidarrRetagPreviewProvider = FutureProvider.autoDispose
    .family<List<RetagTrackResource>, (Instance, int, int?)>(
  (Ref ref, (Instance, int, int?) key) async {
    final (Instance instance, int artistId, int? albumId) = key;
    final LidarrApi api = await ref.watch(lidarrApiProvider(instance).future);
    final ApiResponse<List<RetagTrackResource>> resp =
        await api.retagTrack.getRetag(
      artistId: artistId,
      albumId: albumId,
    );
    return unwrapLidarrApiResponse(resp, 'Failed to load retag preview');
  },
);
