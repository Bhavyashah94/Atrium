import '../generated/models/media_availability.dart';
import '../generated/models/media_child.dart';
import '../generated/models/media_resource.dart';
import '../generated/models/watcher.dart';
import '../media/tracearr_media_url_resolver.dart';
import '../models/tracearr_models.dart';

/// Pure transformation for media details, availability, watchers, and children.
class TracearrMediaMapper {
  const TracearrMediaMapper._();

  static TracearrMediaAvailability mapAvailability(MediaAvailability item) {
    return TracearrMediaAvailability(
      serverId: item.serverId ?? '',
      serverType: item.serverType ?? '',
      ratingKey: item.ratingKey,
      libraryId: item.libraryId,
      videoResolution: item.videoResolution,
      fileSize: item.fileSize,
      addedAt: item.addedAt != null ? DateTime.tryParse(item.addedAt!) : null,
      removedAt:
          item.removedAt != null ? DateTime.tryParse(item.removedAt!) : null,
    );
  }

  static List<TracearrMediaAvailability> mapAvailabilities(
    List<MediaAvailability>? list,
  ) {
    if (list == null || list.isEmpty) return const [];
    return list.map(mapAvailability).toList();
  }

  static TracearrMediaWatcher mapWatcher(Watcher item) {
    return TracearrMediaWatcher(
      userId: item.user?.userId ?? '',
      username: item.user?.identityName ?? item.user?.username ?? 'Unknown',
      plays: item.plays ?? 0,
      watchTimeMs: item.watchTimeMs ?? 0,
      completionPct: item.completionPct,
      lastWatchedDay: item.lastWatchedDay,
      distinctEpisodesWatched: item.distinctEpisodesWatched,
    );
  }

  static List<TracearrMediaWatcher> mapWatchers(List<Watcher>? list) {
    if (list == null || list.isEmpty) return const [];
    return list.map(mapWatcher).toList();
  }

  static TracearrMediaDetail detailFromDto({
    required MediaResource item,
    Map<String, dynamic>? statsWindows,
    List<Watcher>? watchersList,
    List<MediaChild>? childrenList,
    required String baseUrl,
    String? mediaRef,
  }) {
    String? sId;
    String? rKey;
    if (item.availability != null && item.availability!.isNotEmpty) {
      sId = item.availability!.first.serverId;
      rKey = item.availability!.first.ratingKey;
    }

    String? resolvedPosterUrl;
    if (sId != null && sId.isNotEmpty && rKey != null && rKey.isNotEmpty) {
      final sType = item.availability?.first.serverType;
      final fallbackPath =
          TracearrMediaUrlResolver.buildFallbackPosterPath(sType, rKey);
      resolvedPosterUrl = TracearrMediaUrlResolver.formatUrl(
        baseUrl: baseUrl,
        rawUrl: TracearrMediaUrlResolver.buildProxyPosterUrl(
          baseUrl: baseUrl,
          serverId: sId,
          thumbPath: fallbackPath,
        ),
      );
    }

    int allTimePlays = 0;
    int allTimeWatchTimeMs = 0;
    int last30DaysPlays = 0;
    int last7DaysPlays = 0;

    if (statsWindows != null) {
      if (statsWindows['all_time'] is Map<String, dynamic>) {
        final m =
            (statsWindows['all_time'] as Map<String, dynamic>)['combined'];
        if (m is Map<String, dynamic>) {
          allTimePlays = (m['plays'] as num?)?.toInt() ?? 0;
          allTimeWatchTimeMs = (m['watch_time_ms'] as num?)?.toInt() ?? 0;
        }
      }
      if (statsWindows['last_30'] is Map<String, dynamic>) {
        final m = (statsWindows['last_30'] as Map<String, dynamic>)['combined'];
        if (m is Map<String, dynamic>) {
          last30DaysPlays = (m['plays'] as num?)?.toInt() ?? 0;
        }
      }
      if (statsWindows['last_7'] is Map<String, dynamic>) {
        final m = (statsWindows['last_7'] as Map<String, dynamic>)['combined'];
        if (m is Map<String, dynamic>) {
          last7DaysPlays = (m['plays'] as num?)?.toInt() ?? 0;
        }
      }
    }

    return TracearrMediaDetail(
      id: item.id ?? mediaRef ?? '',
      mediaType: item.mediaType ?? 'movie',
      title: item.title ?? 'Unknown Media',
      year: item.year,
      showMediaId: item.showMediaId,
      imdbId: item.imdbId,
      tmdbId: item.tmdbId?.toString(),
      tvdbId: item.tvdbId?.toString(),
      genres: item.genres ?? const <String>[],
      posterUrl: resolvedPosterUrl,
      availability: mapAvailabilities(item.availability),
      children: mapChildren(childrenList),
      allTimePlays: allTimePlays,
      allTimeWatchTimeMs: allTimeWatchTimeMs,
      last30DaysPlays: last30DaysPlays,
      last7DaysPlays: last7DaysPlays,
      watchers: mapWatchers(watchersList),
    );
  }

  static TracearrMediaChild mapChild(MediaChild item) {
    return TracearrMediaChild(
      id: item.id ?? '',
      mediaType: item.mediaType ?? 'episode',
      title: item.title ?? '',
      showMediaId: item.showMediaId,
      seasonNumber: item.seasonNumber,
      episodeNumber: item.episodeNumber,
      episodeCount: item.episodeCount,
    );
  }

  static List<TracearrMediaChild> mapChildren(List<MediaChild>? list) {
    if (list == null || list.isEmpty) return const [];
    return list.map(mapChild).toList();
  }
}
