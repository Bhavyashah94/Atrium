import '../cache/tracearr_artwork_cache.dart';
import '../datasources/tracearr_remote_data_source.dart';
import '../generated/api/raw_public_a_p_i_api.dart';
import '../generated/api/raw_public_a_p_i_v2_api.dart';
import '../generated/models/active_stream.dart';
import '../generated/models/history_record.dart';
import '../generated/models/history_response.dart';
import '../generated/models/media_resource.dart';
import '../generated/models/recently_added_record.dart';
import '../generated/models/user_identity.dart';
import '../generated/models/user_stats_response.dart';
import '../generated/models/watcher.dart';
import '../mappers/mappers.dart';
import '../media/tracearr_media_url_resolver.dart';
import '../models/tracearr_models.dart';

/// Intermediate Repository for Tracearr.
///
/// Coordinates remote data sources, pure transformation mappers, in-flight request
/// deduplication, and non-blocking artwork caching into [TracearrArtworkCache].
class TracearrRepository {
  TracearrRepository({
    RawPublicAPIV2Api? apiV2,
    RawPublicAPIApi? apiV1,
    TracearrRemoteDataSource? remoteDataSource,
    TracearrArtworkCache? artworkCache,
    required String baseUrl,
  })  : _remoteDataSource = remoteDataSource ??
            TracearrRemoteDataSource(
              apiV2: apiV2!,
              apiV1: apiV1,
            ),
        _artworkCache = artworkCache ?? TracearrArtworkCache(),
        _baseUrl = baseUrl;

  final TracearrRemoteDataSource _remoteDataSource;
  final TracearrArtworkCache _artworkCache;
  final String _baseUrl;

  final Map<String, Future<dynamic>> _inFlightRequests =
      <String, Future<dynamic>>{};

  Future<T> _deduplicate<T>(String key, Future<T> Function() factory) {
    final existing = _inFlightRequests[key];
    if (existing != null) {
      return existing as Future<T>;
    }
    final future = factory().whenComplete(() {
      _inFlightRequests.remove(key);
    });
    _inFlightRequests[key] = future;
    return future;
  }

  Future<List<R>> _concurrencyLimit<T, R>(
    List<T> items,
    Future<R> Function(T item) worker, {
    int concurrency = 4,
  }) async {
    if (items.isEmpty) return const [];
    final results = List<R?>.filled(items.length, null);
    var nextIndex = 0;

    Future<void> runWorker() async {
      while (true) {
        final i = nextIndex++;
        if (i >= items.length) break;
        try {
          results[i] = await worker(items[i]);
        } catch (_) {
          results[i] = null;
        }
      }
    }

    final workerCount = items.length < concurrency ? items.length : concurrency;
    final workers = List.generate(workerCount, (_) => runWorker());
    await Future.wait(workers);
    return results.cast<R>();
  }

  void _harvestStreamArtwork(List<ActiveStream> data) {
    for (final item in data) {
      final sId = item.serverId ?? '';
      final rKey = item.ratingKey;
      final mId = item.mediaId;
      final tPath = item.thumbPath;
      final username = item.username;
      final avatarUrl = TracearrMediaUrlResolver.formatUrl(
        baseUrl: _baseUrl,
        rawUrl: item.userAvatarUrl,
      );

      if (sId.isNotEmpty && tPath != null && tPath.isNotEmpty) {
        _artworkCache.putThumbPath(
          serverId: sId,
          thumbPath: tPath,
          ratingKey: rKey,
          mediaId: mId,
        );
      }

      if (sId.isNotEmpty &&
          avatarUrl != null &&
          username != null &&
          username.isNotEmpty) {
        _artworkCache.putUserAvatarUrl(
          serverId: sId,
          username: username,
          avatarUrl: avatarUrl,
        );
      }
    }
  }

  void _harvestHistoryArtwork(List<HistoryRecord>? data) {
    if (data == null || data.isEmpty) return;
    for (final item in data) {
      final sId = item.serverId ?? '';
      final rKey = item.ratingKey;
      final mId = item.mediaId;
      final tPath = item.thumbPath;
      final username = item.user?.username;
      final userId = item.user?.id;
      final avatarUrl = TracearrMediaUrlResolver.formatUrl(
        baseUrl: _baseUrl,
        rawUrl: item.user?.avatarUrl,
      );

      if (sId.isNotEmpty && tPath != null && tPath.isNotEmpty) {
        _artworkCache.putThumbPath(
          serverId: sId,
          thumbPath: tPath,
          ratingKey: rKey,
          mediaId: mId,
        );
      }

      if (sId.isNotEmpty &&
          avatarUrl != null &&
          ((username != null && username.isNotEmpty) ||
              (userId != null && userId.isNotEmpty))) {
        _artworkCache.putUserAvatarUrl(
          serverId: sId,
          userId: userId,
          username: username,
          avatarUrl: avatarUrl,
        );
      }
    }
  }

  /// Fetch active streams and harvest artwork paths into cache.
  Future<List<TracearrStream>> getStreams({String? serverId}) async {
    final rawStreams = await _remoteDataSource.getStreams(serverId: serverId);
    _harvestStreamArtwork(rawStreams);
    return TracearrStreamMapper.fromDtoList(rawStreams, baseUrl: _baseUrl);
  }

  /// Terminate an active stream session.
  Future<bool> terminateStream({
    required String streamId,
    String? message,
  }) async {
    return _remoteDataSource.terminateStream(
      streamId: streamId,
      message: message,
    );
  }

  /// Fetch paginated watch history.
  Future<TracearrHistoryPage> getHistoryPage({
    String? cursor,
    String? pageSize = '25',
    String? userId,
    String? serverId,
  }) async {
    final response = await _remoteDataSource.getHistory(
      cursor: cursor,
      pageSize: pageSize,
      userId: userId,
      serverId: serverId,
    );
    _harvestHistoryArtwork(response.data);
    return TracearrHistoryMapper.fromPageResponse(
      response,
      baseUrl: _baseUrl,
    );
  }

  /// Backward-compatible method returning history items list.
  Future<List<TracearrHistoryItem>> getHistory({
    String? cursor,
    String? pageSize = '25',
    String? userId,
    String? serverId,
  }) async {
    final page = await getHistoryPage(
      cursor: cursor,
      pageSize: pageSize,
      userId: userId,
      serverId: serverId,
    );
    return page.items;
  }

  /// Fetch paginated recently added items.
  Future<TracearrRecentlyAddedPage> getRecentlyAddedPage({
    String? cursor,
    String? pageSize = '25',
    String? serverId,
    String? libraryId,
  }) async {
    final response = await _remoteDataSource.getRecentlyAdded(
      cursor: cursor,
      pageSize: pageSize,
      serverId: serverId,
      libraryId: libraryId,
    );

    final posterMap = <String, String>{};
    for (final item in response.data ?? <RecentlyAddedRecord>[]) {
      final sId = item.serverId ?? '';
      final rKey = item.ratingKey;
      final mId = item.mediaId;

      String? cachedPath = _artworkCache.getThumbPath(sId, rKey ?? '');
      if (cachedPath == null && mId != null) {
        cachedPath = _artworkCache.getThumbPathByMediaId(sId, mId);
      }

      final thumbPath = cachedPath ??
          (rKey != null && rKey.isNotEmpty
              ? TracearrMediaUrlResolver.buildFallbackPosterPath(
                  item.serverType,
                  rKey,
                )
              : null);

      if (sId.isNotEmpty && thumbPath != null) {
        final proxyUrl = TracearrMediaUrlResolver.buildProxyPosterUrl(
          baseUrl: _baseUrl,
          serverId: sId,
          thumbPath: thumbPath,
        );
        final formatted = TracearrMediaUrlResolver.formatUrl(
          baseUrl: _baseUrl,
          rawUrl: proxyUrl,
        );
        if (formatted != null) {
          posterMap[item.id ?? ''] = formatted;
        }
      }
    }

    return TracearrRecentMapper.fromPageResponse(
      response,
      resolvedPostersByItemId: posterMap,
    );
  }

  /// Backward-compatible method returning recently added items list.
  Future<List<TracearrRecentlyAddedItem>> getRecentlyAdded({
    String? cursor,
    String? pageSize = '25',
    String? serverId,
    String? libraryId,
  }) async {
    final page = await getRecentlyAddedPage(
      cursor: cursor,
      pageSize: pageSize,
      serverId: serverId,
      libraryId: libraryId,
    );
    return page.items;
  }

  /// Fetch registered user profiles and user summaries with stats rollups.
  Future<List<TracearrUserSummary>> getUsers({int maxConcurrency = 4}) {
    return _deduplicate('users', () async {
      final identities = await _remoteDataSource.getUsers();
      if (identities.isEmpty) return const <TracearrUserSummary>[];

      final statsList =
          await _concurrencyLimit<UserIdentity, UserStatsResponse?>(
        identities,
        (u) {
          final uId = u.id;
          if (uId == null || uId.isEmpty) {
            return Future<UserStatsResponse?>.value();
          }
          return _remoteDataSource.getUserStatsById(id: uId);
        },
        concurrency: maxConcurrency,
      );

      final summaries = <TracearrUserSummary>[];
      for (var i = 0; i < identities.length; i++) {
        summaries.add(
          TracearrUserMapper.summaryFromDto(
            identity: identities[i],
            stats: statsList[i],
            baseUrl: _baseUrl,
          ),
        );
      }
      return summaries;
    });
  }

  /// Fetch detailed user profile aggregated with lifetime stats and watch history.
  Future<TracearrUserDetail> getUserDetail(String userId) {
    return _deduplicate('user_detail_$userId', () async {
      final identityFuture = _remoteDataSource.getUserById(id: userId);
      final statsFuture = _remoteDataSource.getUserStatsById(id: userId);
      final historyFuture = _remoteDataSource.getUserHistoryById(id: userId);

      final results = await Future.wait<dynamic>([
        identityFuture,
        statsFuture,
        historyFuture,
      ]);

      final identity = results[0] as UserIdentity;
      final stats = results[1] as UserStatsResponse?;
      final history = results[2] as HistoryResponse?;

      return TracearrUserMapper.detailFromDto(
        identity: identity,
        stats: stats,
        recentHistoryRecords: history?.data,
        baseUrl: _baseUrl,
      );
    });
  }

  /// Fetch detailed media item aggregated with stats and watchers leaderboard.
  Future<TracearrMediaDetail> getMediaDetail(String mediaRef) {
    return _deduplicate('media_detail_$mediaRef', () async {
      final mediaFuture = _remoteDataSource.getMediaByRef(ref: mediaRef);
      final statsFuture = _remoteDataSource.getMediaStatsByRef(ref: mediaRef);
      final watchersFuture =
          _remoteDataSource.getMediaWatchersByRef(ref: mediaRef);

      final results = await Future.wait<dynamic>([
        mediaFuture,
        statsFuture,
        watchersFuture,
      ]);

      final mediaRes = results[0] as MediaResource;
      final statsWindows = results[1] as Map<String, dynamic>?;
      final watchers = results[2] as List<Watcher>?;

      return TracearrMediaMapper.detailFromDto(
        item: mediaRes,
        statsWindows: statsWindows,
        watchersList: watchers,
        baseUrl: _baseUrl,
        mediaRef: mediaRef,
      );
    });
  }

  /// Fetch media children (seasons or episodes).
  Future<List<TracearrRecentlyAddedItem>> getMediaChildren(String mediaRef) {
    return _deduplicate('media_children_$mediaRef', () async {
      final rawChildren =
          await _remoteDataSource.getMediaChildrenByRef(ref: mediaRef);
      return TracearrMediaMapper.mapChildren(rawChildren);
    });
  }

  /// Fetch security policy violation incidents via v1 API.
  Future<List<TracearrViolationItem>> getViolations({String? severity}) async {
    final rawViolations =
        await _remoteDataSource.getViolations(severity: severity);
    return TracearrViolationMapper.fromDtoList(rawViolations);
  }

  /// Fetch library rollups.
  Future<List<TracearrLibrary>> getLibraries() async {
    final rawLibraries = await _remoteDataSource.getLibraries();
    return TracearrLibraryMapper.fromDtoList(rawLibraries);
  }

  /// Fetch server health and connectivity status via v1 API.
  Future<TracearrHealthResponse> getHealth() {
    return _deduplicate('health', () async {
      final raw = await _remoteDataSource.getHealth();
      return TracearrHealthMapper.fromDto(raw);
    });
  }

  /// Fetch today's fleet-wide statistics (24h pulse) via v1 API.
  Future<TracearrTodayStats> getStatsToday({
    String? serverId,
    String? timezone,
  }) {
    final key = 'stats_today_${serverId ?? ''}_${timezone ?? ''}';
    return _deduplicate(key, () async {
      final raw = await _remoteDataSource.getStatsToday(
        serverId: serverId,
        timezone: timezone,
      );
      return TracearrStatsMapper.todayFromDto(raw);
    });
  }

  /// Fetch playback activity trends via v1 API.
  Future<TracearrActivityTrend> getActivity({
    String? period = 'week',
    String? serverId,
    String? timezone,
  }) {
    final key = 'activity_${period ?? ''}_${serverId ?? ''}_${timezone ?? ''}';
    return _deduplicate(key, () async {
      final raw = await _remoteDataSource.getActivity(
        period: period,
        serverId: serverId,
        timezone: timezone,
      );
      return TracearrActivityMapper.fromDto(raw);
    });
  }

  /// Fetch 30-day aggregate fleet statistics via v1 API.
  Future<TracearrAggregateStats> getStats({String? serverId}) {
    final key = 'stats_${serverId ?? ''}';
    return _deduplicate(key, () async {
      final raw = await _remoteDataSource.getStats(serverId: serverId);
      return TracearrStatsMapper.aggregateFromDto(raw);
    });
  }

  /// Fetch watch history for a specific media item by reference key via v2 API.
  Future<TracearrHistoryPage> getMediaHistoryPage({
    required String ref,
    String? cursor,
    String? pageSize = '25',
  }) {
    final key = 'media_history_${ref}_${cursor ?? ''}';
    return _deduplicate(key, () async {
      final raw = await _remoteDataSource.getMediaHistory(
        ref: ref,
        cursor: cursor,
        pageSize: pageSize,
      );
      if (raw.data != null) {
        _harvestHistoryArtwork(raw.data!);
      }
      return TracearrHistoryMapper.fromPageResponse(raw, baseUrl: _baseUrl);
    });
  }
}
