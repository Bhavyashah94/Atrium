import 'package:core_networking/core_networking.dart';
import 'package:dio/dio.dart';

import 'models/tracearr_active_sessions.dart';
import 'models/tracearr_session.dart';
import 'models/tracearr_v2_models.dart';

/// The `data` array out of a Tracearr response envelope, as maps.
List<Map<String, dynamic>> _envelopeList(Object? body) {
  if (body is! Map<String, dynamic>) return const <Map<String, dynamic>>[];
  final Object? data = body['data'];
  if (data is! List) return const <Map<String, dynamic>>[];
  return data.whereType<Map<String, dynamic>>().toList();
}

/// Typed client for Tracearr 2.0 Public API (v2 primary, v1 health fallback).
class TracearrApi {
  TracearrApi(this._dio, {this.token});

  final Dio _dio;
  final String? token;

  String? imageUrl(String? path) {
    if (path == null || path.isEmpty) return null;
    if (path.startsWith('http')) return path;
    final String base = _dio.options.baseUrl.replaceAll(RegExp(r'/+$'), '');
    final String cleanPath = path.startsWith('/') ? path : '/$path';
    if (token == null || token!.isEmpty) return '$base$cleanPath';
    final String sep = cleanPath.contains('?') ? '&' : '?';
    return '$base$cleanPath${sep}token=$token';
  }

  /// Image URL helper for artwork/posters.
  String? proxyImageUrl({
    required String? path,
    String? serverId,
    int? width,
    int? height,
    String? fallback,
  }) {
    return imageUrl(path);
  }

  // ---------------------------------------------------------------------------
  // Endpoint 1: GET /api/v2/public/docs - OpenAPI Specification & Health
  // ---------------------------------------------------------------------------

  /// Verifies server health via public API endpoint (GET /api/v2/public/docs).
  Future<bool> getHealth() async {
    try {
      final Response<dynamic> resp =
          await _dio.get<dynamic>('api/v2/public/docs');
      return resp.statusCode == 200;
    } on DioException catch (e) {
      if (e.response?.statusCode == 401 || e.response?.statusCode == 403) {
        throw const NetworkAuthException('Tracearr rejected API key');
      }
      throw NetworkException.fromDio(e);
    }
  }

  // ---------------------------------------------------------------------------
  // Endpoint 2: GET /api/v2/public/history - Watch history as plays
  // ---------------------------------------------------------------------------

  /// Retrieves global watch history (GET /api/v2/public/history).
  Future<TracearrV2HistoryResponse> getV2History({
    String? cursor,
    int pageSize = 25,
    String? userId,
    String? serverId,
    String? mediaId,
    String? ratingKey,
    String? imdbId,
    int? tmdbId,
    int? tvdbId,
    String? mediaType,
    bool? watched,
    String? since,
    String? until,
  }) async {
    try {
      final Map<String, dynamic> query = <String, dynamic>{
        'pageSize': pageSize,
        if (cursor != null && cursor.isNotEmpty) 'cursor': cursor,
        if (userId != null && userId.isNotEmpty) 'user_id': userId,
        if (serverId != null && serverId.isNotEmpty) 'server_id': serverId,
        if (mediaId != null && mediaId.isNotEmpty) 'media_id': mediaId,
        if (ratingKey != null && ratingKey.isNotEmpty) 'rating_key': ratingKey,
        if (imdbId != null && imdbId.isNotEmpty) 'imdb_id': imdbId,
        if (tmdbId != null) 'tmdb_id': tmdbId,
        if (tvdbId != null) 'tvdb_id': tvdbId,
        if (mediaType != null && mediaType.isNotEmpty) 'media_type': mediaType,
        if (watched != null) 'watched': watched,
        if (since != null && since.isNotEmpty) 'since': since,
        if (until != null && until.isNotEmpty) 'until': until,
      };
      final Response<dynamic> resp = await _dio.get<dynamic>(
        'api/v2/public/history',
        queryParameters: query,
      );
      if (resp.data is Map<String, dynamic>) {
        return TracearrV2HistoryResponse.fromJson(
            resp.data as Map<String, dynamic>,);
      }
      return const TracearrV2HistoryResponse();
    } on DioException catch (e) {
      throw NetworkException.fromDio(e);
    }
  }

  // ---------------------------------------------------------------------------
  // Endpoint 3: GET /api/v2/public/streams - Active streams
  // ---------------------------------------------------------------------------

  /// Retrieves active playback streams transformed for UI (GET /api/v2/public/streams).
  Future<TracearrActiveSessions> getActiveSessions() async {
    try {
      final Response<dynamic> resp =
          await _dio.get<dynamic>('api/v2/public/streams');
      final List<Map<String, dynamic>> data = _envelopeList(resp.data);
      final List<TracearrSession> sessions = data.map((Map<String, dynamic> item) {
        final int progress = (item['progress_ms'] as num?)?.toInt() ?? 0;
        final int duration = (item['duration_ms'] as num?)?.toInt() ?? 100000;
        return TracearrSession.fromJson(<String, dynamic>{
          'id': item['id']?.toString() ?? '',
          'serverId': item['server_id']?.toString() ?? '',
          'state': item['state']?.toString() ?? 'playing',
          'mediaType': item['media_type']?.toString() ?? 'movie',
          'mediaTitle': item['media_title']?.toString() ?? '',
          'grandparentTitle': item['grandparent_title']?.toString() ??
              item['show_title']?.toString(),
          'parentTitle': item['parent_title']?.toString(),
          'progressMs': progress,
          'totalDurationMs': duration > 0 ? duration : 100000,
          'ipAddress': '',
          'playerName': item['player_name']?.toString() ??
              item['player']?.toString() ??
              '',
          'product': item['product']?.toString() ??
              item['platform_name']?.toString() ??
              '',
          'device': item['device_name']?.toString() ??
              item['device']?.toString() ??
              '',
          'platform': item['platform_name']?.toString() ??
              item['platform']?.toString() ??
              '',
          'quality': item['resolution']?.toString() ?? '',
          'isTranscode': item['is_transcode'] == true ||
              item['stream_decision'] == 'transcode' ||
              item['video_decision'] == 'transcode',
          'userName': item['username']?.toString() ??
              item['user_name']?.toString(),
          'avatarUrl': item['user_avatar_url']?.toString() ??
              item['user_thumb']?.toString() ??
              item['user_avatar']?.toString(),
          'thumbPath': item['poster_url']?.toString() ??
              item['thumb_path']?.toString(),
        });
      }).toList();
      return TracearrActiveSessions(sessions: sessions);
    } on DioException catch (e) {
      throw NetworkException.fromDio(e);
    }
  }

  /// Retrieves active streams typed response (GET /api/v2/public/streams).
  Future<TracearrV2StreamsResponse> getV2Streams({
    String? serverId,
    bool? summary,
  }) async {
    try {
      final Map<String, dynamic> query = <String, dynamic>{
        if (serverId != null && serverId.isNotEmpty) 'server_id': serverId,
        if (summary != null) 'summary': summary,
      };
      final Response<dynamic> resp = await _dio.get<dynamic>(
        'api/v2/public/streams',
        queryParameters: query,
      );
      if (resp.data is Map<String, dynamic>) {
        return TracearrV2StreamsResponse.fromJson(
            resp.data as Map<String, dynamic>,);
      }
      return const TracearrV2StreamsResponse();
    } on DioException catch (e) {
      throw NetworkException.fromDio(e);
    }
  }

  // ---------------------------------------------------------------------------
  // Endpoint 4: GET /api/v2/public/media/{ref} - Media identity & availability
  // ---------------------------------------------------------------------------

  /// Retrieves media details by ref (GET /api/v2/public/media/{ref}).
  Future<TracearrV2MediaDetails?> getMediaByRef(String ref) async {
    try {
      final Response<dynamic> resp =
          await _dio.get<dynamic>('api/v2/public/media/$ref');
      if (resp.data is Map<String, dynamic>) {
        return TracearrV2MediaDetails.fromJson(resp.data as Map<String, dynamic>,);
      }
      return null;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      throw NetworkException.fromDio(e);
    }
  }

  /// Retrieves full media resource model by ref (GET /api/v2/public/media/{ref}).
  Future<TracearrV2MediaResource?> getMediaResource(String ref) async {
    try {
      final Response<dynamic> resp =
          await _dio.get<dynamic>('api/v2/public/media/$ref');
      if (resp.data is Map<String, dynamic>) {
        return TracearrV2MediaResource.fromJson(
            resp.data as Map<String, dynamic>,);
      }
      return null;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      throw NetworkException.fromDio(e);
    }
  }

  // ---------------------------------------------------------------------------
  // Endpoint 5: GET /api/v2/public/media/{ref}/children - Media children
  // ---------------------------------------------------------------------------

  /// Retrieves child media items (GET /api/v2/public/media/{ref}/children).
  Future<TracearrV2MediaChildrenResponse> getMediaChildren(String ref) async {
    try {
      final Response<dynamic> resp =
          await _dio.get<dynamic>('api/v2/public/media/$ref/children');
      if (resp.data is Map<String, dynamic>) {
        return TracearrV2MediaChildrenResponse.fromJson(
            resp.data as Map<String, dynamic>,);
      }
      return const TracearrV2MediaChildrenResponse();
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return const TracearrV2MediaChildrenResponse();
      }
      throw NetworkException.fromDio(e);
    }
  }

  // ---------------------------------------------------------------------------
  // Endpoint 6: GET /api/v2/public/media/{ref}/stats - Media play statistics
  // ---------------------------------------------------------------------------

  /// Retrieves play statistics for a media item (GET /api/v2/public/media/{ref}/stats).
  Future<TracearrV2MediaStatsResponse?> getMediaStats(String ref) async {
    try {
      final Response<dynamic> resp =
          await _dio.get<dynamic>('api/v2/public/media/$ref/stats');
      if (resp.data is Map<String, dynamic>) {
        return TracearrV2MediaStatsResponse.fromJson(
            resp.data as Map<String, dynamic>,);
      }
      return null;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      throw NetworkException.fromDio(e);
    }
  }

  // ---------------------------------------------------------------------------
  // Endpoint 7: GET /api/v2/public/media/{ref}/watchers - Media watchers
  // ---------------------------------------------------------------------------

  /// Retrieves media watchers (GET /api/v2/public/media/{ref}/watchers).
  Future<TracearrV2MediaWatchersResponse> getMediaWatchers(
    String ref, {
    String? window,
    String? serverId,
  }) async {
    try {
      final Map<String, dynamic> query = <String, dynamic>{
        if (window != null && window.isNotEmpty) 'window': window,
        if (serverId != null && serverId.isNotEmpty) 'server_id': serverId,
      };
      final Response<dynamic> resp = await _dio.get<dynamic>(
        'api/v2/public/media/$ref/watchers',
        queryParameters: query,
      );
      if (resp.data is Map<String, dynamic>) {
        return TracearrV2MediaWatchersResponse.fromJson(
            resp.data as Map<String, dynamic>,);
      }
      return TracearrV2MediaWatchersResponse(mediaId: ref, mediaType: 'movie');
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return TracearrV2MediaWatchersResponse(mediaId: ref, mediaType: 'movie');
      }
      throw NetworkException.fromDio(e);
    }
  }

  // ---------------------------------------------------------------------------
  // Endpoint 8: GET /api/v2/public/media/{ref}/history - Media watch history
  // ---------------------------------------------------------------------------

  /// Retrieves watch history for a single media item (GET /api/v2/public/media/{ref}/history).
  Future<TracearrV2HistoryResponse> getMediaHistory(
    String ref, {
    String? cursor,
    int pageSize = 25,
  }) async {
    try {
      final Map<String, dynamic> query = <String, dynamic>{
        'pageSize': pageSize,
        if (cursor != null && cursor.isNotEmpty) 'cursor': cursor,
      };
      final Response<dynamic> resp = await _dio.get<dynamic>(
        'api/v2/public/media/$ref/history',
        queryParameters: query,
      );
      if (resp.data is Map<String, dynamic>) {
        return TracearrV2HistoryResponse.fromJson(
            resp.data as Map<String, dynamic>,);
      }
      return const TracearrV2HistoryResponse();
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return const TracearrV2HistoryResponse();
      }
      throw NetworkException.fromDio(e);
    }
  }

  // ---------------------------------------------------------------------------
  // Endpoint 9: GET /api/v2/public/users - Identities with account correlation
  // ---------------------------------------------------------------------------

  /// Retrieves user list (GET /api/v2/public/users).
  Future<TracearrV2UsersResponse> getV2Users({
    String? cursor,
    int pageSize = 25,
    bool includeRemoved = false,
  }) async {
    try {
      final Map<String, dynamic> query = <String, dynamic>{
        'pageSize': pageSize,
        if (cursor != null && cursor.isNotEmpty) 'cursor': cursor,
        if (includeRemoved) 'include_removed': true,
      };
      final Response<dynamic> resp = await _dio.get<dynamic>(
        'api/v2/public/users',
        queryParameters: query,
      );
      if (resp.data is Map<String, dynamic>) {
        return TracearrV2UsersResponse.fromJson(
            resp.data as Map<String, dynamic>,);
      }
      return const TracearrV2UsersResponse();
    } on DioException catch (e) {
      throw NetworkException.fromDio(e);
    }
  }

  // ---------------------------------------------------------------------------
  // Endpoint 10: GET /api/v2/public/users/{id} - One identity
  // ---------------------------------------------------------------------------

  /// Resolves a single Tracearr identity by ID (GET /api/v2/public/users/{id}).
  Future<TracearrV2UserIdentity?> getUserById(String id) async {
    try {
      final Response<dynamic> resp =
          await _dio.get<dynamic>('api/v2/public/users/$id');
      if (resp.data is Map<String, dynamic>) {
        return TracearrV2UserIdentity.fromJson(
            resp.data as Map<String, dynamic>,);
      }
      return null;
    } on DioException catch (e) {
      throw NetworkException.fromDio(e);
    }
  }

  // ---------------------------------------------------------------------------
  // Endpoint 11: GET /api/v2/public/users/{id}/stats - Identity play statistics
  // ---------------------------------------------------------------------------

  /// Retrieves user stats (GET /api/v2/public/users/{id}/stats).
  Future<TracearrV2UserStatsResponse?> getUserStats(String userId) async {
    try {
      final Response<dynamic> resp =
          await _dio.get<dynamic>('api/v2/public/users/$userId/stats');
      if (resp.data is Map<String, dynamic>) {
        return TracearrV2UserStatsResponse.fromJson(
            resp.data as Map<String, dynamic>,);
      }
      return null;
    } on DioException catch (e) {
      throw NetworkException.fromDio(e);
    }
  }

  // ---------------------------------------------------------------------------
  // Endpoint 12: GET /api/v2/public/users/{id}/history - Identity watch history
  // ---------------------------------------------------------------------------

  /// Retrieves watch history for a single identity (GET /api/v2/public/users/{id}/history).
  Future<TracearrV2HistoryResponse> getUserHistory(
    String userId, {
    String? cursor,
    int pageSize = 25,
  }) async {
    try {
      final Map<String, dynamic> query = <String, dynamic>{
        'pageSize': pageSize,
        if (cursor != null && cursor.isNotEmpty) 'cursor': cursor,
      };
      final Response<dynamic> resp = await _dio.get<dynamic>(
        'api/v2/public/users/$userId/history',
        queryParameters: query,
      );
      if (resp.data is Map<String, dynamic>) {
        return TracearrV2HistoryResponse.fromJson(
            resp.data as Map<String, dynamic>,);
      }
      return const TracearrV2HistoryResponse();
    } on DioException catch (e) {
      throw NetworkException.fromDio(e);
    }
  }

  // ---------------------------------------------------------------------------
  // Endpoint 13: GET /api/v2/public/recently-added - Recently added items
  // ---------------------------------------------------------------------------

  /// Retrieves recently added media (GET /api/v2/public/recently-added).
  Future<TracearrV2RecentlyAddedResponse> getV2RecentlyAdded({
    int pageSize = 25,
    String? cursor,
    String? serverId,
    String? libraryId,
    String? mediaType,
    bool includeRemoved = false,
  }) async {
    try {
      final Map<String, dynamic> query = <String, dynamic>{
        'pageSize': pageSize,
        if (cursor != null && cursor.isNotEmpty) 'cursor': cursor,
        if (serverId != null && serverId.isNotEmpty) 'server_id': serverId,
        if (libraryId != null && libraryId.isNotEmpty) 'library_id': libraryId,
        if (mediaType != null && mediaType.isNotEmpty) 'media_type': mediaType,
        if (includeRemoved) 'include_removed': true,
      };
      final Response<dynamic> resp = await _dio.get<dynamic>(
        'api/v2/public/recently-added',
        queryParameters: query,
      );
      if (resp.data is Map<String, dynamic>) {
        return TracearrV2RecentlyAddedResponse.fromJson(
            resp.data as Map<String, dynamic>,);
      }
      return const TracearrV2RecentlyAddedResponse();
    } on DioException catch (e) {
      throw NetworkException.fromDio(e);
    }
  }

  // ---------------------------------------------------------------------------
  // Endpoint 14: GET /api/v2/public/libraries - Per-library rollups
  // ---------------------------------------------------------------------------

  /// Retrieves media libraries (GET /api/v2/public/libraries).
  Future<TracearrV2LibrariesResponse> getV2Libraries() async {
    try {
      final Response<dynamic> resp =
          await _dio.get<dynamic>('api/v2/public/libraries');
      if (resp.data is Map<String, dynamic>) {
        return TracearrV2LibrariesResponse.fromJson(
            resp.data as Map<String, dynamic>,);
      }
      return const TracearrV2LibrariesResponse();
    } on DioException catch (e) {
      throw NetworkException.fromDio(e);
    }
  }
}
