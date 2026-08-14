import 'package:flutter_test/flutter_test.dart';
import 'package:service_tracearr/src/cache/tracearr_artwork_cache.dart';
import 'package:service_tracearr/src/generated/api/raw_public_a_p_i_api.dart';
import 'package:service_tracearr/src/generated/api/raw_public_a_p_i_v2_api.dart';
import 'package:service_tracearr/src/generated/models/active_stream.dart';
import 'package:service_tracearr/src/generated/models/activity_response.dart';
import 'package:service_tracearr/src/generated/models/health_response.dart';
import 'package:service_tracearr/src/generated/models/history_record.dart';
import 'package:service_tracearr/src/generated/models/history_response.dart';
import 'package:service_tracearr/src/generated/models/history_user.dart';
import 'package:service_tracearr/src/generated/models/media_child.dart';
import 'package:service_tracearr/src/generated/models/media_children_response.dart';
import 'package:service_tracearr/src/generated/models/media_resource.dart';
import 'package:service_tracearr/src/generated/models/media_stats_response.dart';
import 'package:service_tracearr/src/generated/models/media_watchers_response.dart';
import 'package:service_tracearr/src/generated/models/recently_added_record.dart';
import 'package:service_tracearr/src/generated/models/recently_added_response.dart';
import 'package:service_tracearr/src/generated/models/server_status.dart';
import 'package:service_tracearr/src/generated/models/stats_response.dart';
import 'package:service_tracearr/src/generated/models/stats_today_response.dart';
import 'package:service_tracearr/src/generated/models/streams_response.dart';
import 'package:service_tracearr/src/generated/models/user_account.dart';
import 'package:service_tracearr/src/generated/models/user_genre.dart';
import 'package:service_tracearr/src/generated/models/user_identity.dart';
import 'package:service_tracearr/src/generated/models/user_stats_response.dart';
import 'package:service_tracearr/src/generated/models/users_response.dart';
import 'package:service_tracearr/src/generated/models/watcher.dart';
import 'package:service_tracearr/src/generated/responses/api_response.dart';
import 'package:service_tracearr/src/generated/responses/tracearr_error.dart';
import 'package:service_tracearr/src/generated/responses/tracearr_exception.dart';
import 'package:service_tracearr/src/repository/tracearr_repository.dart';

class FakeRawPublicAPIV2Api implements RawPublicAPIV2Api {
  FakeRawPublicAPIV2Api({this.customRecentlyAdded});
  final RecentlyAddedResponse? customRecentlyAdded;
  int getPublicUsersByIdCalls = 0;

  @override
  Future<ApiResponse<StreamsResponse>> getPublicStreams({
    String? serverId,
    String? summary,
  }) async {
    const stream = ActiveStream(
      id: 'stream_1',
      serverId: 'server_1',
      serverName: 'Plex Server',
      serverType: 'plex',
      mediaTitle: 'Inception',
      thumbPath: '/library/metadata/100/thumb/200',
      posterUrl:
          '/api/v1/images/proxy?server=server_1&url=%2Flibrary%2Fmetadata%2F100%2Fthumb%2F200',
      ratingKey: '100',
      mediaId: 'media_100',
      bitrate: 12500,
      username: 'Bhavyashah',
      userAvatarUrl:
          '/api/v1/images/proxy?server=server_1&url=%2Fusers%2Favatar.jpg',
    );
    const response = StreamsResponse(data: [stream]);
    return const ApiResponse.success(response, statusCode: 200);
  }

  @override
  Future<ApiResponse<HistoryResponse>> getPublicHistory({
    String? cursor,
    String? pageSize,
    String? userId,
    String? serverId,
    String? mediaId,
    String? ratingKey,
    String? imdbId,
    String? tmdbId,
    String? tvdbId,
    String? mediaType,
    String? watched,
    String? since,
    String? until,
  }) async {
    const historyRecord = HistoryRecord(
      id: 'hist_1',
      serverId: 'server_1',
      serverName: 'Plex Server',
      serverType: 'plex',
      mediaTitle: 'Interstellar',
      thumbPath: '/library/metadata/300/thumb/400',
      posterUrl:
          '/api/v1/images/proxy?server=server_1&url=%2Flibrary%2Fmetadata%2F300%2Fthumb%2F400',
      ratingKey: '300',
      mediaId: 'media_300',
      watched: true,
      user: HistoryUser(
        id: 'user_1',
        serverUserId: 'server_user_1',
        username: 'Bhavyashah',
        avatarUrl:
            '/api/v1/images/proxy?server=server_1&url=%2Fusers%2Fbhavyashah.jpg',
      ),
    );
    const response = HistoryResponse(data: [historyRecord]);
    return const ApiResponse.success(response, statusCode: 200);
  }

  @override
  Future<ApiResponse<RecentlyAddedResponse>> getPublicRecentlyAdded({
    String? cursor,
    String? pageSize,
    String? serverId,
    String? libraryId,
    String? mediaType,
    String? includeRemoved,
  }) async {
    if (customRecentlyAdded != null) {
      return ApiResponse.success(customRecentlyAdded!, statusCode: 200);
    }
    const item = RecentlyAddedRecord(
      id: 'rec_1',
      serverId: 'server_1',
      serverType: 'plex',
      libraryId: 'lib_1',
      mediaType: 'movie',
      title: 'Inception',
      year: 2010,
      ratingKey: '100',
      mediaId: 'media_100',
    );
    const response = RecentlyAddedResponse(data: [item]);
    return const ApiResponse.success(response, statusCode: 200);
  }

  @override
  Future<ApiResponse<UsersResponse>> getPublicUsers({
    String? cursor,
    String? pageSize,
    String? includeRemoved,
  }) async {
    const identities = [
      UserIdentity(
        id: 'user_1',
        username: 'Bhavyashah',
        email: 'bhavya@example.com',
        accounts: [
          UserAccount(
            serverId: 'server_1',
            serverType: 'plex',
            externalUserId: 'ext_1',
          ),
        ],
      ),
      UserIdentity(
        id: 'user_2',
        username: 'User2',
        email: 'user2@example.com',
      ),
    ];
    return const ApiResponse.success(
      UsersResponse(data: identities),
      statusCode: 200,
    );
  }

  @override
  Future<ApiResponse<UserIdentity>> getPublicUsersById({
    required String id,
  }) async {
    getPublicUsersByIdCalls++;
    if (id == 'user_1') {
      const identity = UserIdentity(
        id: 'user_1',
        username: 'Bhavyashah',
        email: 'bhavya@example.com',
        accounts: [
          UserAccount(
            serverId: 'server_1',
            serverType: 'plex',
            serverUserId: 'su_1',
            externalUserId: 'ext_1',
            username: 'BhavyashahPlex',
          ),
        ],
      );
      return const ApiResponse.success(identity, statusCode: 200);
    } else if (id == 'user_2') {
      const identity = UserIdentity(
        id: 'user_2',
        username: 'User2',
        email: 'user2@example.com',
      );
      return const ApiResponse.success(identity, statusCode: 200);
    }
    return const ApiResponse.error(
      TracearrError(message: 'User not found'),
      statusCode: 404,
    );
  }

  @override
  Future<ApiResponse<UserStatsResponse>> getPublicUsersStatsById({
    required String id,
  }) async {
    final stats = UserStatsResponse(
      userId: id,
      windows: <String, dynamic>{
        'all_time': <String, dynamic>{'plays': 150, 'watch_time_ms': 450000000},
        'last_30': <String, dynamic>{'plays': 20, 'watch_time_ms': 60000000},
        'last_7': <String, dynamic>{'plays': 5, 'watch_time_ms': 15000000},
      },
      topGenres: [
        const UserGenre(genre: 'Sci-Fi', plays: 80),
        const UserGenre(genre: 'Action', plays: 40),
      ],
    );
    return ApiResponse.success(stats, statusCode: 200);
  }

  @override
  Future<ApiResponse<HistoryResponse>> getPublicUsersHistoryById({
    required String id,
    String? cursor,
    String? pageSize,
  }) async {
    return getPublicHistory(userId: id, cursor: cursor, pageSize: pageSize);
  }

  @override
  Future<ApiResponse<MediaResource>> getPublicMediaByRef({
    required String ref,
  }) async {
    if (ref == 'show_1') {
      return const ApiResponse.success(
        MediaResource(
          id: 'show_1',
          mediaType: 'show',
          title: 'Breaking Bad',
        ),
        statusCode: 200,
      );
    }
    return const ApiResponse.success(
      MediaResource(
        id: 'med_1',
        mediaType: 'movie',
        title: 'Inception',
      ),
      statusCode: 200,
    );
  }

  @override
  Future<ApiResponse<MediaStatsResponse>> getPublicMediaStatsByRef({
    required String ref,
  }) async {
    return const ApiResponse.success(
      MediaStatsResponse(
        windows: <String, dynamic>{
          'all_time': <String, dynamic>{
            'combined': <String, dynamic>{'plays': 100, 'watch_time_ms': 360000000},
          },
        },
      ),
      statusCode: 200,
    );
  }

  @override
  Future<ApiResponse<MediaWatchersResponse>> getPublicMediaWatchersByRef({
    required String ref,
    String? serverId,
    String? window,
  }) async {
    return const ApiResponse.success(
      MediaWatchersResponse(
        mediaId: 'med_1',
        mediaType: 'movie',
        window: 'all_time',
        watchers: <Watcher>[],
      ),
      statusCode: 200,
    );
  }

  int getPublicMediaChildrenByRefCalls = 0;

  @override
  Future<ApiResponse<MediaChildrenResponse>> getPublicMediaChildrenByRef({
    required String ref,
  }) async {
    getPublicMediaChildrenByRefCalls++;
    return const ApiResponse.success(
      MediaChildrenResponse(
        data: [
          MediaChild(
            id: 'ep_1',
            mediaType: 'episode',
            title: 'Pilot',
            seasonNumber: 1,
            episodeNumber: 1,
          ),
        ],
      ),
      statusCode: 200,
    );
  }

  @override
  Future<ApiResponse<HistoryResponse>> getPublicMediaHistoryByRef({
    required String ref,
    String? cursor,
    String? pageSize,
  }) async {
    return const ApiResponse.success(
      HistoryResponse(
        data: [
          HistoryRecord(
            id: 'h_media_1',
            mediaTitle: 'Inception',
            user: HistoryUser(username: 'User1'),
          ),
        ],
      ),
      statusCode: 200,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeRawPublicAPIV1Api implements RawPublicAPIApi {
  @override
  Future<ApiResponse<HealthResponse>> getPublicHealth() async {
    return const ApiResponse.success(
      HealthResponse(
        status: 'healthy',
        servers: [ServerStatus(id: 's1', online: true, name: 'Server 1')],
      ),
      statusCode: 200,
    );
  }

  @override
  Future<ApiResponse<StatsTodayResponse>> getPublicStatsToday({
    String? serverId,
    String? timezone,
  }) async {
    return const ApiResponse.success(
      StatsTodayResponse(todayPlays: 25, activeStreams: 3),
      statusCode: 200,
    );
  }

  @override
  Future<ApiResponse<ActivityResponse>> getPublicActivity({
    String? period,
    String? serverId,
    String? timezone,
  }) async {
    return const ApiResponse.success(
      ActivityResponse(period: 'week'),
      statusCode: 200,
    );
  }

  @override
  Future<ApiResponse<StatsResponse>> getPublicStats({
    String? serverId,
  }) async {
    return const ApiResponse.success(
      StatsResponse(totalSessions: 1200, activeStreams: 2),
      statusCode: 200,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('TracearrRepository', () {
    late TracearrArtworkCache cache;
    late FakeRawPublicAPIV2Api api;
    late FakeRawPublicAPIV1Api apiV1;
    late TracearrRepository repository;

    setUp(() {
      cache = TracearrArtworkCache();
      api = FakeRawPublicAPIV2Api();
      apiV1 = FakeRawPublicAPIV1Api();
      repository = TracearrRepository(
        apiV2: api,
        apiV1: apiV1,
        artworkCache: cache,
        baseUrl: 'https://tr.betelgeuse.fun',
      );
    });

    test('getStreams maps items and harvests artwork into cache', () async {
      final streams = await repository.getStreams();
      expect(streams.length, equals(1));
      expect(streams.first.mediaTitle, equals('Inception'));
      expect(streams.first.bitrate, equals(12500));

      // Verify artwork harvesting
      expect(
        cache.getThumbPath('server_1', '100'),
        equals('/library/metadata/100/thumb/200'),
      );
    });

    test('getHistory maps items and harvests user avatar into cache', () async {
      final history = await repository.getHistory();
      expect(history.length, equals(1));
      expect(history.first.mediaTitle, equals('Interstellar'));
      expect(history.first.watched, isTrue);
      expect(history.first.userId, equals('user_1'));
      expect(history.first.serverUserId, equals('server_user_1'));

      // Verify user avatar harvesting
      expect(
        cache.getUserAvatarUrl('server_1', 'user_1'),
        equals(
          'https://tr.betelgeuse.fun/api/v1/images/proxy?server=server_1&url=%2Fusers%2Fbhavyashah.jpg',
        ),
      );
    });

    test('getRecentlyAdded resolves posterUrl from cache if present', () async {
      // Warm cache with item 100
      await cache.putThumbPath(
        serverId: 'server_1',
        ratingKey: '100',
        thumbPath: '/library/metadata/100/thumb/200',
      );

      final recentlyAdded = await repository.getRecentlyAdded();
      expect(recentlyAdded.length, equals(1));
      expect(recentlyAdded.first.title, equals('Inception'));
      expect(
        recentlyAdded.first.resolvedPosterUrl,
        equals(
          'https://tr.betelgeuse.fun/api/v1/images/proxy?server=server_1&url=%2Flibrary%2Fmetadata%2F100%2Fthumb%2F200&width=300&height=450&fallback=poster',
        ),
      );
    });

    test(
        'getUserDetail aggregates identity, stats, and history calls into single object',
        () async {
      final userDetail = await repository.getUserDetail('user_1');
      expect(userDetail.id, equals('user_1'));
      expect(userDetail.username, equals('Bhavyashah'));
      expect(userDetail.email, equals('bhavya@example.com'));
      expect(userDetail.allTimePlays, equals(150));
      expect(userDetail.topGenres.first.genre, equals('Sci-Fi'));
      expect(userDetail.accounts.length, equals(1));
      expect(userDetail.recentHistory.length, equals(1));
    });

    test('coalesces concurrent getUserDetail requests for the same userId',
        () async {
      final futures = await Future.wait([
        repository.getUserDetail('user_1'),
        repository.getUserDetail('user_1'),
      ]);

      expect(futures[0].id, equals('user_1'));
      expect(futures[1].id, equals('user_1'));
      expect(api.getPublicUsersByIdCalls, equals(1));
    });

    test('getUsers bounds concurrent requests and maps all users', () async {
      final users = await repository.getUsers(maxConcurrency: 2);
      expect(users.length, equals(2));
      expect(users[0].username, equals('Bhavyashah'));
      expect(users[0].allTimePlays, equals(150));
      expect(users[1].username, equals('User2'));
      expect(users[1].allTimePlays, equals(150));
    });

    test('getRecentlyAdded resolves fallback poster on cold empty cache',
        () async {
      final coldRepository = TracearrRepository(
        apiV2: api,
        artworkCache: TracearrArtworkCache(),
        baseUrl: 'https://tr.betelgeuse.fun',
      );

      final recentlyAdded = await coldRepository.getRecentlyAdded();
      expect(recentlyAdded.length, equals(1));
      expect(recentlyAdded.first.title, equals('Inception'));
      // Fallback poster computed directly from serverType (plex) and ratingKey (100)
      expect(
        recentlyAdded.first.resolvedPosterUrl,
        equals(
          'https://tr.betelgeuse.fun/api/v1/images/proxy?server=server_1&url=%2Flibrary%2Fmetadata%2F100%2Fthumb&width=300&height=450&fallback=poster',
        ),
      );
    });

    test(
        'getRecentlyAddedPage prioritizes grandparentRatingKey for episode artwork',
        () async {
      const episodeItem = RecentlyAddedRecord(
        id: 'rec_ep_1',
        serverId: 'server_1',
        serverType: 'plex',
        libraryId: 'lib_1',
        mediaType: 'episode',
        title: 'Celebration',
        ratingKey: '301',
        parentRatingKey: '201',
        grandparentRatingKey: '101',
      );
      final customApi = FakeRawPublicAPIV2Api(
        customRecentlyAdded: const RecentlyAddedResponse(data: [episodeItem]),
      );
      final repo = TracearrRepository(
        apiV2: customApi,
        apiV1: FakeRawPublicAPIV1Api(),
        artworkCache: TracearrArtworkCache(),
        baseUrl: 'https://tr.betelgeuse.fun',
      );

      final page = await repo.getRecentlyAddedPage();
      expect(page.items.length, equals(1));
      expect(page.items.first.title, equals('Celebration'));
      expect(page.items.first.parentRatingKey, equals('201'));
      expect(page.items.first.grandparentRatingKey, equals('101'));
      // Fallback poster computed using grandparentRatingKey (101) instead of episode ratingKey (301)
      expect(
        page.items.first.resolvedPosterUrl,
        equals(
          'https://tr.betelgeuse.fun/api/v1/images/proxy?server=server_1&url=%2Flibrary%2Fmetadata%2F101%2Fthumb&width=300&height=450&fallback=poster',
        ),
      );
    });

    test('getHealth returns mapped server status and health', () async {
      final health = await repository.getHealth();
      expect(health.status, equals('healthy'));
      expect(health.servers.length, equals(1));
      expect(health.servers.first.name, equals('Server 1'));
    });

    test('getStatsToday returns 24h dashboard pulse', () async {
      final today = await repository.getStatsToday();
      expect(today.todayPlays, equals(25));
      expect(today.activeStreams, equals(3));
    });

    test('getActivity returns mapped activity trends', () async {
      final activity = await repository.getActivity();
      expect(activity.period, equals('week'));
    });

    test('getStats returns 30d aggregate statistics', () async {
      final stats = await repository.getStats();
      expect(stats.totalSessions, equals(1200));
      expect(stats.activeStreams, equals(2));
    });

    test('getMediaHistoryPage returns paginated history for media item',
        () async {
      final page = await repository.getMediaHistoryPage(ref: 'med_1');
      expect(page.items.length, equals(1));
      expect(page.items.first.id, equals('h_media_1'));
    });

    test('getMediaDetail fetches and maps children for TV shows', () async {
      final detail = await repository.getMediaDetail('show_1');
      expect(detail.id, equals('show_1'));
      expect(detail.title, equals('Breaking Bad'));
      expect(detail.children.length, equals(1));
      expect(detail.children.first.title, equals('Pilot'));
      expect(detail.children.first.seasonNumber, equals(1));
      expect(api.getPublicMediaChildrenByRefCalls, greaterThanOrEqualTo(1));
    });

    test('getMediaDetail does not request children for movies', () async {
      final callsBefore = api.getPublicMediaChildrenByRefCalls;
      final detail = await repository.getMediaDetail('med_1');
      expect(detail.id, equals('med_1'));
      expect(detail.title, equals('Inception'));
      expect(detail.children, isEmpty);
      expect(api.getPublicMediaChildrenByRefCalls, equals(callsBefore));
    });

    test('getUserDetail with unknown username throws TracearrException',
        () async {
      expect(
        () => repository.getUserDetail('definitely_unknown_user_123'),
        throwsA(
          isA<TracearrException>().having(
            (e) => e.message,
            'message',
            contains('User not found: definitely_unknown_user_123'),
          ),
        ),
      );
    });

    test('getUserDetail with username resolves through user directory to UUID',
        () async {
      final userDetail = await repository.getUserDetail('Bhavyashah');
      expect(userDetail.id, equals('user_1'));
      expect(userDetail.username, equals('Bhavyashah'));
      expect(userDetail.email, equals('bhavya@example.com'));
    });
  });
}
