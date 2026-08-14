import '../generated/api/raw_public_a_p_i_api.dart';
import '../generated/api/raw_public_a_p_i_v2_api.dart';
import '../generated/models/active_stream.dart';
import '../generated/models/activity_response.dart';
import '../generated/models/health_response.dart';
import '../generated/models/history_response.dart';
import '../generated/models/library_rollup.dart';
import '../generated/models/media_child.dart';
import '../generated/models/media_resource.dart';
import '../generated/models/recently_added_response.dart';
import '../generated/models/stats_response.dart';
import '../generated/models/stats_today_response.dart';
import '../generated/models/user_identity.dart';
import '../generated/models/user_stats_response.dart';
import '../generated/models/violation.dart';
import '../generated/models/watcher.dart';
import '../generated/responses/tracearr_exception.dart';

/// Low-level remote data source encapsulating all HTTP and OpenAPI SDK operations
/// for Tracearr v1 and v2 APIs.
class TracearrRemoteDataSource {
  TracearrRemoteDataSource({
    required RawPublicAPIV2Api apiV2,
    RawPublicAPIApi? apiV1,
  })  : _apiV2 = apiV2,
        _apiV1 = apiV1;

  final RawPublicAPIV2Api _apiV2;
  final RawPublicAPIApi? _apiV1;

  /// Fetch active playback streams from v2 API.
  Future<List<ActiveStream>> getStreams({
    String? serverId,
  }) async {
    final response = await _apiV2.getPublicStreams(serverId: serverId);
    if (!response.isSuccess || response.data == null) {
      throw TracearrException(
        response.error?.message ?? 'Failed to fetch active streams',
        statusCode: response.statusCode,
        error: response.error,
      );
    }
    return response.data?.data ?? const <ActiveStream>[];
  }

  /// Terminate an active stream session via v1 API.
  Future<bool> terminateStream({
    required String streamId,
    String? message,
  }) async {
    if (_apiV1 == null) {
      throw const TracearrException(
        'Stream termination requires v1 API support.',
      );
    }
    final response = await _apiV1.postPublicStreamsTerminateById(
      id: streamId,
      body: message != null && message.isNotEmpty ? {'reason': message} : null,
    );
    if (!response.isSuccess) {
      throw TracearrException(
        response.error?.message ?? 'Failed to terminate stream',
        statusCode: response.statusCode,
        error: response.error,
      );
    }
    return response.data?.success ?? true;
  }

  /// Fetch paginated watch history from v2 API.
  Future<HistoryResponse> getHistory({
    String? cursor,
    String? pageSize = '25',
    String? userId,
    String? serverId,
  }) async {
    final response = await _apiV2.getPublicHistory(
      cursor: cursor,
      pageSize: pageSize,
      userId: userId,
      serverId: serverId,
    );
    if (!response.isSuccess || response.data == null) {
      throw TracearrException(
        response.error?.message ?? 'Failed to fetch watch history',
        statusCode: response.statusCode,
        error: response.error,
      );
    }
    return response.data!;
  }

  /// Fetch paginated recently added items from v2 API.
  Future<RecentlyAddedResponse> getRecentlyAdded({
    String? cursor,
    String? pageSize = '25',
    String? serverId,
    String? libraryId,
  }) async {
    final response = await _apiV2.getPublicRecentlyAdded(
      cursor: cursor,
      pageSize: pageSize,
      serverId: serverId,
      libraryId: libraryId,
    );
    if (!response.isSuccess || response.data == null) {
      throw TracearrException(
        response.error?.message ?? 'Failed to fetch recently added items',
        statusCode: response.statusCode,
        error: response.error,
      );
    }
    return response.data!;
  }

  /// Fetch registered user identities from v2 API.
  Future<List<UserIdentity>> getUsers() async {
    final response = await _apiV2.getPublicUsers();
    if (!response.isSuccess || response.data == null) {
      throw TracearrException(
        response.error?.message ?? 'Failed to fetch user list',
        statusCode: response.statusCode,
        error: response.error,
      );
    }
    return response.data?.data ?? const <UserIdentity>[];
  }

  /// Fetch a single user identity by ID.
  Future<UserIdentity> getUserById({
    required String id,
  }) async {
    final response = await _apiV2.getPublicUsersById(id: id);
    if (!response.isSuccess || response.data == null) {
      throw TracearrException(
        response.error?.message ?? 'Failed to fetch user profile',
        statusCode: response.statusCode,
        error: response.error,
      );
    }
    return response.data!;
  }

  /// Fetch user statistics by user ID.
  Future<UserStatsResponse?> getUserStatsById({
    required String id,
  }) async {
    try {
      final response = await _apiV2.getPublicUsersStatsById(id: id);
      return response.data;
    } catch (_) {
      return null;
    }
  }

  /// Fetch watch history for a specific user ID.
  Future<HistoryResponse?> getUserHistoryById({
    required String id,
    String? cursor,
    String? pageSize = '10',
  }) async {
    try {
      final response = await _apiV2.getPublicUsersHistoryById(
        id: id,
        cursor: cursor,
        pageSize: pageSize,
      );
      return response.data;
    } catch (_) {
      return null;
    }
  }

  /// Fetch canonical media identity by reference/ID.
  Future<MediaResource> getMediaByRef({
    required String ref,
  }) async {
    final response = await _apiV2.getPublicMediaByRef(ref: ref);
    if (!response.isSuccess || response.data == null) {
      throw TracearrException(
        response.error?.message ?? 'Failed to fetch media details',
        statusCode: response.statusCode,
        error: response.error,
      );
    }
    return response.data!;
  }

  /// Fetch media statistics windows by reference/ID.
  Future<Map<String, dynamic>?> getMediaStatsByRef({
    required String ref,
  }) async {
    try {
      final response = await _apiV2.getPublicMediaStatsByRef(ref: ref);
      final statsData = response.data;
      if (statsData != null && statsData.windows is Map<String, dynamic>) {
        return statsData.windows as Map<String, dynamic>;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Fetch media watchers leaderboard by reference/ID.
  Future<List<Watcher>> getMediaWatchersByRef({
    required String ref,
  }) async {
    try {
      final response = await _apiV2.getPublicMediaWatchersByRef(ref: ref);
      return response.data?.watchers ?? const <Watcher>[];
    } catch (_) {
      return const <Watcher>[];
    }
  }

  /// Fetch media children (seasons/episodes) by reference/ID.
  Future<List<MediaChild>> getMediaChildrenByRef({
    required String ref,
  }) async {
    try {
      final response = await _apiV2.getPublicMediaChildrenByRef(ref: ref);
      return response.data?.data ?? const <MediaChild>[];
    } catch (_) {
      return const <MediaChild>[];
    }
  }

  /// Fetch security policy violations log via v1 API.
  Future<List<Violation>> getViolations({
    String? severity,
  }) async {
    if (_apiV1 == null) return const <Violation>[];
    final response = await _apiV1.getPublicViolations(severity: severity);
    if (!response.isSuccess || response.data == null) {
      throw TracearrException(
        response.error?.message ?? 'Failed to fetch rule violations',
        statusCode: response.statusCode,
        error: response.error,
      );
    }
    return response.data?.data ?? const <Violation>[];
  }

  /// Fetch library storage and item statistics from v2 API.
  Future<List<LibraryRollup>> getLibraries() async {
    final response = await _apiV2.getPublicLibraries();
    if (!response.isSuccess || response.data == null) {
      throw TracearrException(
        response.error?.message ?? 'Failed to fetch library statistics',
        statusCode: response.statusCode,
        error: response.error,
      );
    }
    return response.data?.data ?? const <LibraryRollup>[];
  }

  /// Fetch server health and status via v1 API.
  Future<HealthResponse> getHealth() async {
    if (_apiV1 == null) {
      throw const TracearrException('Endpoint requires v1 API support.');
    }
    final response = await _apiV1.getPublicHealth();
    if (!response.isSuccess || response.data == null) {
      throw TracearrException(
        response.error?.message ?? 'Failed to fetch health status',
        statusCode: response.statusCode,
        error: response.error,
      );
    }
    return response.data!;
  }

  /// Fetch today's fleet statistics via v1 API.
  Future<StatsTodayResponse> getStatsToday({
    String? serverId,
    String? timezone,
  }) async {
    if (_apiV1 == null) {
      throw const TracearrException('Endpoint requires v1 API support.');
    }
    final response = await _apiV1.getPublicStatsToday(
      serverId: serverId,
      timezone: timezone,
    );
    if (!response.isSuccess || response.data == null) {
      throw TracearrException(
        response.error?.message ?? 'Failed to fetch today stats',
        statusCode: response.statusCode,
        error: response.error,
      );
    }
    return response.data!;
  }

  /// Fetch playback activity trends via v1 API.
  Future<ActivityResponse> getActivity({
    String? period,
    String? serverId,
    String? timezone,
  }) async {
    if (_apiV1 == null) {
      throw const TracearrException('Endpoint requires v1 API support.');
    }
    final response = await _apiV1.getPublicActivity(
      period: period,
      serverId: serverId,
      timezone: timezone,
    );
    if (!response.isSuccess || response.data == null) {
      throw TracearrException(
        response.error?.message ?? 'Failed to fetch activity trends',
        statusCode: response.statusCode,
        error: response.error,
      );
    }
    return response.data!;
  }

  /// Fetch 30-day aggregate statistics via v1 API.
  Future<StatsResponse> getStats({
    String? serverId,
  }) async {
    if (_apiV1 == null) {
      throw const TracearrException('Endpoint requires v1 API support.');
    }
    final response = await _apiV1.getPublicStats(
      serverId: serverId,
    );
    if (!response.isSuccess || response.data == null) {
      throw TracearrException(
        response.error?.message ?? 'Failed to fetch aggregate stats',
        statusCode: response.statusCode,
        error: response.error,
      );
    }
    return response.data!;
  }

  /// Fetch watch history for a specific media item by reference key via v2 API.
  Future<HistoryResponse> getMediaHistory({
    required String ref,
    String? cursor,
    String? pageSize = '25',
  }) async {
    final response = await _apiV2.getPublicMediaHistoryByRef(
      ref: ref,
      cursor: cursor,
      pageSize: pageSize,
    );
    if (!response.isSuccess || response.data == null) {
      throw TracearrException(
        response.error?.message ?? 'Failed to fetch media history',
        statusCode: response.statusCode,
        error: response.error,
      );
    }
    return response.data!;
  }
}
