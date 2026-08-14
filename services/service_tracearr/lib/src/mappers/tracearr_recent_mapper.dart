import '../generated/models/recently_added_record.dart';
import '../generated/models/recently_added_response.dart';
import '../models/tracearr_models.dart';

/// Pure transformation from raw [RecentlyAddedRecord] DTO to domain [TracearrRecentlyAddedItem].
class TracearrRecentMapper {
  const TracearrRecentMapper._();

  static TracearrRecentlyAddedItem fromDto(
    RecentlyAddedRecord item, {
    String? resolvedPosterUrl,
  }) {
    return TracearrRecentlyAddedItem(
      id: item.id ?? '',
      serverId: item.serverId ?? '',
      serverType: item.serverType,
      libraryId: item.libraryId ?? '',
      mediaType: item.mediaType ?? 'movie',
      title: item.title ?? '',
      year: item.year,
      addedAt: item.addedAt != null ? DateTime.tryParse(item.addedAt!) : null,
      removedAt:
          item.removedAt != null ? DateTime.tryParse(item.removedAt!) : null,
      mediaId: item.mediaId,
      imdbId: item.imdbId,
      tmdbId: item.tmdbId?.toString(),
      tvdbId: item.tvdbId?.toString(),
      ratingKey: item.ratingKey,
      parentRatingKey: item.parentRatingKey,
      grandparentRatingKey: item.grandparentRatingKey,
      resolvedPosterUrl: resolvedPosterUrl,
    );
  }

  static TracearrRecentlyAddedPage fromPageResponse(
    RecentlyAddedResponse response, {
    Map<String, String>? resolvedPostersByItemId,
  }) {
    final data = response.data ?? <RecentlyAddedRecord>[];
    final items = data.map((item) {
      final posterUrl = resolvedPostersByItemId?[item.id ?? ''];
      return fromDto(item, resolvedPosterUrl: posterUrl);
    }).toList();
    final nextCursor = response.meta?.nextCursor;
    return TracearrRecentlyAddedPage(items: items, nextCursor: nextCursor);
  }
}
