import 'package:flutter_test/flutter_test.dart';
import 'package:service_tracearr/src/datasources/tracearr_remote_data_source.dart';
import 'package:service_tracearr/src/generated/api/raw_public_a_p_i_api.dart';
import 'package:service_tracearr/src/generated/api/raw_public_a_p_i_v2_api.dart';
import 'package:service_tracearr/src/generated/models/active_stream.dart';
import 'package:service_tracearr/src/generated/models/activity_response.dart';
import 'package:service_tracearr/src/generated/models/health_response.dart';
import 'package:service_tracearr/src/generated/models/history_record.dart';
import 'package:service_tracearr/src/generated/models/history_response.dart';
import 'package:service_tracearr/src/generated/models/libraries_response.dart';
import 'package:service_tracearr/src/generated/models/library_rollup.dart';
import 'package:service_tracearr/src/generated/models/media_availability.dart';
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
import 'package:service_tracearr/src/generated/models/terminate_stream_response.dart';
import 'package:service_tracearr/src/generated/models/user_identity.dart';
import 'package:service_tracearr/src/generated/models/user_stats_response.dart';
import 'package:service_tracearr/src/generated/models/users_response.dart';
import 'package:service_tracearr/src/generated/models/violation.dart';
import 'package:service_tracearr/src/generated/models/violations_response.dart';
import 'package:service_tracearr/src/generated/models/watcher.dart';
import 'package:service_tracearr/src/generated/responses/api_response.dart';
import 'package:service_tracearr/src/generated/responses/tracearr_error.dart';
import 'package:service_tracearr/src/generated/responses/tracearr_exception.dart';

class FakeV2Api implements RawPublicAPIV2Api {
  bool shouldFail = false;

  @override
  Future<ApiResponse<StreamsResponse>> getPublicStreams({
    String? serverId,
    String? summary,
  }) async {
    if (shouldFail) {
      return const ApiResponse.error(
        TracearrError(message: 'Server error fetching streams'),
        statusCode: 500,
      );
    }
    const stream = ActiveStream(id: 'st_1', mediaTitle: 'Movie 1');
    return const ApiResponse.success(
      StreamsResponse(data: [stream]),
      statusCode: 200,
    );
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
    if (shouldFail) {
      return const ApiResponse.error(
        TracearrError(message: 'Failed to fetch history'),
        statusCode: 500,
      );
    }
    return const ApiResponse.success(
      HistoryResponse(data: [HistoryRecord(id: 'h_1', mediaTitle: 'Movie 1')]),
      statusCode: 200,
    );
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
    return const ApiResponse.success(
      RecentlyAddedResponse(
        data: [RecentlyAddedRecord(id: 'rec_1', title: 'New Item')],
      ),
      statusCode: 200,
    );
  }

  @override
  Future<ApiResponse<UsersResponse>> getPublicUsers({
    String? cursor,
    String? includeRemoved,
    String? pageSize,
  }) async {
    return const ApiResponse.success(
      UsersResponse(data: [UserIdentity(id: 'u_1', username: 'User1')]),
      statusCode: 200,
    );
  }

  @override
  Future<ApiResponse<UserIdentity>> getPublicUsersById({
    required String id,
  }) async {
    return ApiResponse.success(
      UserIdentity(id: id, username: 'User1'),
      statusCode: 200,
    );
  }

  @override
  Future<ApiResponse<UserStatsResponse>> getPublicUsersStatsById({
    required String id,
  }) async {
    return ApiResponse.success(
      UserStatsResponse(
        userId: id,
        windows: <String, dynamic>{
          'all_time': <String, dynamic>{'plays': 100},
        },
      ),
      statusCode: 200,
    );
  }

  @override
  Future<ApiResponse<HistoryResponse>> getPublicUsersHistoryById({
    required String id,
    String? cursor,
    String? pageSize,
  }) async {
    return const ApiResponse.success(
      HistoryResponse(data: [HistoryRecord(id: 'h_user_1')]),
      statusCode: 200,
    );
  }

  @override
  Future<ApiResponse<MediaResource>> getPublicMediaByRef({
    required String ref,
  }) async {
    return ApiResponse.success(
      MediaResource(
        id: ref,
        title: 'Media Title',
        availability: const [
          MediaAvailability(serverId: 's1', ratingKey: '100'),
        ],
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
            'combined': <String, dynamic>{'plays': 50},
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
      MediaWatchersResponse(watchers: [Watcher(plays: 10)]),
      statusCode: 200,
    );
  }

  @override
  Future<ApiResponse<MediaChildrenResponse>> getPublicMediaChildrenByRef({
    required String ref,
  }) async {
    return const ApiResponse.success(
      MediaChildrenResponse(data: [MediaChild(id: 'c_1', title: 'Episode 1')]),
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
      HistoryResponse(data: [HistoryRecord(id: 'h_media_1')]),
      statusCode: 200,
    );
  }

  @override
  Future<ApiResponse<LibrariesResponse>> getPublicLibraries() async {
    return const ApiResponse.success(
      LibrariesResponse(
        data: [LibraryRollup(serverId: 's1', libraryId: 'l1', itemCount: 100)],
      ),
      statusCode: 200,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeV1Api implements RawPublicAPIApi {
  @override
  Future<ApiResponse<TerminateStreamResponse>> postPublicStreamsTerminateById({
    required String id,
    dynamic body,
  }) async {
    return const ApiResponse.success(
      TerminateStreamResponse(success: true),
      statusCode: 200,
    );
  }

  @override
  Future<ApiResponse<ViolationsResponse>> getPublicViolations({
    String? acknowledged,
    String? page,
    String? pageSize,
    String? serverId,
    String? severity,
  }) async {
    return const ApiResponse.success(
      ViolationsResponse(data: [Violation(id: 'v_1', rule: 'Policy')]),
      statusCode: 200,
    );
  }

  @override
  Future<ApiResponse<HealthResponse>> getPublicHealth() async {
    return const ApiResponse.success(
      HealthResponse(
        status: 'healthy',
        servers: [ServerStatus(id: 's1', online: true)],
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
      StatsTodayResponse(todayPlays: 15, activeStreams: 2),
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
      StatsResponse(totalSessions: 500, activeStreams: 1),
      statusCode: 200,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('TracearrRemoteDataSource', () {
    late FakeV2Api v2Api;
    late FakeV1Api v1Api;
    late TracearrRemoteDataSource dataSource;

    setUp(() {
      v2Api = FakeV2Api();
      v1Api = FakeV1Api();
      dataSource = TracearrRemoteDataSource(
        apiV2: v2Api,
        apiV1: v1Api,
      );
    });

    test('getStreams returns stream list on success', () async {
      final streams = await dataSource.getStreams();
      expect(streams.length, equals(1));
      expect(streams.first.mediaTitle, equals('Movie 1'));
    });

    test('getStreams throws TracearrException on error', () async {
      v2Api.shouldFail = true;
      expect(
        () => dataSource.getStreams(),
        throwsA(isA<TracearrException>()),
      );
    });

    test('terminateStream sends request via v1 api', () async {
      final result = await dataSource.terminateStream(streamId: 'st_1');
      expect(result, isTrue);
    });

    test('getHistory and getRecentlyAdded return record lists', () async {
      final history = await dataSource.getHistory();
      expect(history.data?.length, equals(1));
      expect(history.data?.first.mediaTitle, equals('Movie 1'));

      final recent = await dataSource.getRecentlyAdded();
      expect(recent.data?.length, equals(1));
      expect(recent.data?.first.title, equals('New Item'));
    });

    test('getUsers and getUserById return user identities', () async {
      final users = await dataSource.getUsers();
      expect(users.length, equals(1));

      final user = await dataSource.getUserById(id: 'u_1');
      expect(user.username, equals('User1'));
    });

    test('getMedia details, stats, watchers, and children', () async {
      final media = await dataSource.getMediaByRef(ref: 'med_1');
      expect(media.title, equals('Media Title'));

      final stats = await dataSource.getMediaStatsByRef(ref: 'med_1');
      expect(stats, isNotNull);

      final watchers = await dataSource.getMediaWatchersByRef(ref: 'med_1');
      expect(watchers.length, equals(1));

      final children = await dataSource.getMediaChildrenByRef(ref: 'med_1');
      expect(children.length, equals(1));
    });

    test('getViolations returns violations list via v1', () async {
      final violations = await dataSource.getViolations();
      expect(violations.length, equals(1));
      expect(violations.first.rule, equals('Policy'));
    });

    test('getLibraries returns library rollups', () async {
      final libraries = await dataSource.getLibraries();
      expect(libraries.length, equals(1));
      expect(libraries.first.itemCount, equals(100));
    });

    test('getHealth returns health response via v1', () async {
      final health = await dataSource.getHealth();
      expect(health.status, equals('healthy'));
      expect(health.servers?.length, equals(1));
    });

    test('getStatsToday returns 24h fleet stats via v1', () async {
      final today = await dataSource.getStatsToday();
      expect(today.todayPlays, equals(15));
      expect(today.activeStreams, equals(2));
    });

    test('getActivity returns activity trend via v1', () async {
      final activity = await dataSource.getActivity();
      expect(activity.period, equals('week'));
    });

    test('getStats returns 30d aggregate stats via v1', () async {
      final stats = await dataSource.getStats();
      expect(stats.totalSessions, equals(500));
    });

    test('getMediaHistory returns history response via v2', () async {
      final history = await dataSource.getMediaHistory(ref: 'med_1');
      expect(history.data?.length, equals(1));
      expect(history.data?.first.id, equals('h_media_1'));
    });
  });
}
