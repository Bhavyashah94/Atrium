import 'package:core_models/core_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../generated/generated.dart';
import '../../../lidarr_api.dart';
import '../../../state/api_providers.dart';

/// Sort options for Wanted views.
enum WantedSortKey {
  releaseDate('releaseDate', 'Release Date'),
  artistName('artist.artistName', 'Artist Name'),
  title('title', 'Album Title');

  const WantedSortKey(this.value, this.label);
  final String value;
  final String label;
}

/// Global search query for Wanted tab.
final lidarrWantedSearchQueryProvider =
    StateProvider.family<String, Instance>((ref, instance) => '');

/// Monitored-only filter toggle for Wanted tab (default true).
final lidarrWantedMonitoredOnlyProvider =
    StateProvider.family<bool, Instance>((ref, instance) => true);

/// Sort field key for Wanted tab.
final lidarrWantedSortKeyProvider =
    StateProvider.family<WantedSortKey, Instance>(
  (ref, instance) => WantedSortKey.releaseDate,
);

/// Sort direction for Wanted tab (true = Ascending, false = Descending).
final lidarrWantedSortAscendingProvider =
    StateProvider.family<bool, Instance>((ref, instance) => false);

/// Wanted Missing albums page fetcher for an instance.
final lidarrWantedMissingProvider = FutureProvider.autoDispose.family<
    AlbumResourcePagingResource,
    (Instance, int, int, bool?, String, SortDirection)>(
  (Ref ref, (Instance, int, int, bool?, String, SortDirection) key) async {
    final (
      Instance instance,
      int page,
      int pageSize,
      bool? monitored,
      String sortKey,
      SortDirection sortDir,
    ) = key;
    final LidarrApi api = await ref.watch(lidarrApiProvider(instance).future);
    final ApiResponse<AlbumResourcePagingResource> resp =
        await api.missing.getWantedMissing(
      page: page,
      pageSize: pageSize,
      includeArtist: true,
      monitored: monitored,
      sortKey: sortKey,
      sortDirection: sortDir,
    );
    return unwrapLidarrApiResponse(resp, 'Failed to load missing albums');
  },
);

/// Wanted Cutoff Unmet albums page fetcher for an instance.
final lidarrWantedCutoffProvider = FutureProvider.autoDispose.family<
    AlbumResourcePagingResource,
    (Instance, int, int, bool?, String, SortDirection)>(
  (Ref ref, (Instance, int, int, bool?, String, SortDirection) key) async {
    final (
      Instance instance,
      int page,
      int pageSize,
      bool? monitored,
      String sortKey,
      SortDirection sortDir,
    ) = key;
    final LidarrApi api = await ref.watch(lidarrApiProvider(instance).future);
    final ApiResponse<AlbumResourcePagingResource> resp =
        await api.cutoff.getWantedCutoff(
      page: page,
      pageSize: pageSize,
      includeArtist: true,
      monitored: monitored,
      sortKey: sortKey,
      sortDirection: sortDir,
    );
    return unwrapLidarrApiResponse(
      resp,
      'Failed to load cutoff unmet albums',
    );
  },
);
