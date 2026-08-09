// AUTO-GENERATED FROM v2.json OpenAPI Specification
// DO NOT EDIT DIRECTLY. Run `dart run tool/generate_tracearr_models.dart` to update.

import 'package:core_networking/core_networking.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'models/tracearr_v2_models.dart';

/// 100% Spec-compliant API client for Tracearr 2.0 OpenAPI v2 specification.
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

  String? proxyImageUrl({
    required String? path,
    String? serverId,
    int? width,
    int? height,
    String? fallback,
  }) {
    return imageUrl(path);
  }

  /// Verifies server health via public API endpoint (GET /api/v2/public/docs).
  Future<bool> getHealth() async {
    try {
      final Response<dynamic> resp = await _dio.get<dynamic>('api/v2/public/docs');
      return resp.statusCode == 200;
    } on DioException catch (e) {
      if (e.response?.statusCode == 401 || e.response?.statusCode == 403) {
        throw const NetworkAuthException('Tracearr rejected API key');
      }
      throw NetworkException.fromDio(e);
    }
  }

  /// OpenAPI specification (GET /api/v2/public/docs).
  Future<Map<String, dynamic>> getDocs() async {
    try {
      final Response<dynamic> resp = await _dio.get<dynamic>(
        'api/v2/public/docs',
      );
      if (resp.data is! Map<String, dynamic>) {
        debugPrint('[Tracearr API Warning] Non-JSON payload received from api/v2/public/docs: ${resp.data}');
        throw NetworkUnknownException('Unexpected server response format: ${resp.data}');
      }
      try {
        return resp.data as Map<String, dynamic>;
      } catch (err) {
        debugPrint('[Tracearr API Parsing Error] Endpoint api/v2/public/docs failed deserialization into Map<String, dynamic>: $err\nRaw Payload: ${resp.data}');
        rethrow;
      }
    } on DioException catch (e) {
      debugPrint('[Tracearr API Network Error] Endpoint api/v2/public/docs failed with DioException: ${e.message}');
      throw NetworkException.fromDio(e);
    }
  }

  /// Watch history as plays (GET /api/v2/public/history).
  Future<TracearrV2HistoryResponse> getHistory({
    String? cursor,
    int? pageSize,
    String? userId,
    String? serverId,
    String? mediaId,
    String? ratingKey,
    String? imdbId,
    int? tmdbId,
    int? tvdbId,
    String? mediaType,
    String? watched,
    String? since,
    String? until,
  }) async {
    try {
      final Map<String, dynamic> query = <String, dynamic>{
        if (cursor != null) 'cursor': cursor,
        if (pageSize != null) 'pageSize': pageSize,
        if (userId != null) 'user_id': userId,
        if (serverId != null) 'server_id': serverId,
        if (mediaId != null) 'media_id': mediaId,
        if (ratingKey != null) 'rating_key': ratingKey,
        if (imdbId != null) 'imdb_id': imdbId,
        if (tmdbId != null) 'tmdb_id': tmdbId,
        if (tvdbId != null) 'tvdb_id': tvdbId,
        if (mediaType != null) 'media_type': mediaType,
        if (watched != null) 'watched': watched,
        if (since != null) 'since': since,
        if (until != null) 'until': until,
      };
      final Response<dynamic> resp = await _dio.get<dynamic>(
        'api/v2/public/history',
        queryParameters: query,
      );
      if (resp.data is! Map<String, dynamic>) {
        debugPrint('[Tracearr API Warning] Non-JSON payload received from api/v2/public/history: ${resp.data}');
        throw NetworkUnknownException('Unexpected server response format: ${resp.data}');
      }
      try {
        return TracearrV2HistoryResponse.fromJson(
          resp.data as Map<String, dynamic>,
        );
      } catch (err) {
        debugPrint('[Tracearr API Parsing Error] Endpoint api/v2/public/history failed deserialization into TracearrV2HistoryResponse: $err\nRaw Payload: ${resp.data}');
        rethrow;
      }
    } on DioException catch (e) {
      debugPrint('[Tracearr API Network Error] Endpoint api/v2/public/history failed with DioException: ${e.message}');
      throw NetworkException.fromDio(e);
    }
  }

  /// Active streams (GET /api/v2/public/streams).
  Future<TracearrV2StreamsResponse> getStreams({
    String? serverId,
    String? summary,
  }) async {
    try {
      final Map<String, dynamic> query = <String, dynamic>{
        if (serverId != null) 'server_id': serverId,
        if (summary != null) 'summary': summary,
      };
      final Response<dynamic> resp = await _dio.get<dynamic>(
        'api/v2/public/streams',
        queryParameters: query,
      );
      if (resp.data is! Map<String, dynamic>) {
        debugPrint('[Tracearr API Warning] Non-JSON payload received from api/v2/public/streams: ${resp.data}');
        throw NetworkUnknownException('Unexpected server response format: ${resp.data}');
      }
      try {
        return TracearrV2StreamsResponse.fromJson(
          resp.data as Map<String, dynamic>,
        );
      } catch (err) {
        debugPrint('[Tracearr API Parsing Error] Endpoint api/v2/public/streams failed deserialization into TracearrV2StreamsResponse: $err\nRaw Payload: ${resp.data}');
        rethrow;
      }
    } on DioException catch (e) {
      debugPrint('[Tracearr API Network Error] Endpoint api/v2/public/streams failed with DioException: ${e.message}');
      throw NetworkException.fromDio(e);
    }
  }

  /// Media identity and availability (GET /api/v2/public/media/{ref}).
  Future<TracearrV2MediaResource> getMediaByRef({
    required String ref,
  }) async {
    try {
      final Response<dynamic> resp = await _dio.get<dynamic>(
        'api/v2/public/media/$ref',
      );
      if (resp.data is! Map<String, dynamic>) {
        debugPrint('[Tracearr API Warning] Non-JSON payload received from api/v2/public/media/$ref: ${resp.data}');
        throw NetworkUnknownException('Unexpected server response format: ${resp.data}');
      }
      try {
        return TracearrV2MediaResource.fromJson(
          resp.data as Map<String, dynamic>,
        );
      } catch (err) {
        debugPrint('[Tracearr API Parsing Error] Endpoint api/v2/public/media/$ref failed deserialization into TracearrV2MediaResource: $err\nRaw Payload: ${resp.data}');
        rethrow;
      }
    } on DioException catch (e) {
      debugPrint('[Tracearr API Network Error] Endpoint api/v2/public/media/$ref failed with DioException: ${e.message}');
      throw NetworkException.fromDio(e);
    }
  }

  /// Media children (GET /api/v2/public/media/{ref}/children).
  Future<TracearrV2MediaChildrenResponse> getMediaChildren({
    required String ref,
  }) async {
    try {
      final Response<dynamic> resp = await _dio.get<dynamic>(
        'api/v2/public/media/$ref/children',
      );
      if (resp.data is! Map<String, dynamic>) {
        debugPrint('[Tracearr API Warning] Non-JSON payload received from api/v2/public/media/$ref/children: ${resp.data}');
        throw NetworkUnknownException('Unexpected server response format: ${resp.data}');
      }
      try {
        return TracearrV2MediaChildrenResponse.fromJson(
          resp.data as Map<String, dynamic>,
        );
      } catch (err) {
        debugPrint('[Tracearr API Parsing Error] Endpoint api/v2/public/media/$ref/children failed deserialization into TracearrV2MediaChildrenResponse: $err\nRaw Payload: ${resp.data}');
        rethrow;
      }
    } on DioException catch (e) {
      debugPrint('[Tracearr API Network Error] Endpoint api/v2/public/media/$ref/children failed with DioException: ${e.message}');
      throw NetworkException.fromDio(e);
    }
  }

  /// Media play statistics (GET /api/v2/public/media/{ref}/stats).
  Future<TracearrV2MediaStatsResponse> getMediaStats({
    required String ref,
  }) async {
    try {
      final Response<dynamic> resp = await _dio.get<dynamic>(
        'api/v2/public/media/$ref/stats',
      );
      if (resp.data is! Map<String, dynamic>) {
        debugPrint('[Tracearr API Warning] Non-JSON payload received from api/v2/public/media/$ref/stats: ${resp.data}');
        throw NetworkUnknownException('Unexpected server response format: ${resp.data}');
      }
      try {
        return TracearrV2MediaStatsResponse.fromJson(
          resp.data as Map<String, dynamic>,
        );
      } catch (err) {
        debugPrint('[Tracearr API Parsing Error] Endpoint api/v2/public/media/$ref/stats failed deserialization into TracearrV2MediaStatsResponse: $err\nRaw Payload: ${resp.data}');
        rethrow;
      }
    } on DioException catch (e) {
      debugPrint('[Tracearr API Network Error] Endpoint api/v2/public/media/$ref/stats failed with DioException: ${e.message}');
      throw NetworkException.fromDio(e);
    }
  }

  /// Media watchers (GET /api/v2/public/media/{ref}/watchers).
  Future<TracearrV2MediaWatchersResponse> getMediaWatchers({
    required String ref,
    String? window,
    String? serverId,
  }) async {
    try {
      final Map<String, dynamic> query = <String, dynamic>{
        if (window != null) 'window': window,
        if (serverId != null) 'server_id': serverId,
      };
      final Response<dynamic> resp = await _dio.get<dynamic>(
        'api/v2/public/media/$ref/watchers',
        queryParameters: query,
      );
      if (resp.data is! Map<String, dynamic>) {
        debugPrint('[Tracearr API Warning] Non-JSON payload received from api/v2/public/media/$ref/watchers: ${resp.data}');
        throw NetworkUnknownException('Unexpected server response format: ${resp.data}');
      }
      try {
        return TracearrV2MediaWatchersResponse.fromJson(
          resp.data as Map<String, dynamic>,
        );
      } catch (err) {
        debugPrint('[Tracearr API Parsing Error] Endpoint api/v2/public/media/$ref/watchers failed deserialization into TracearrV2MediaWatchersResponse: $err\nRaw Payload: ${resp.data}');
        rethrow;
      }
    } on DioException catch (e) {
      debugPrint('[Tracearr API Network Error] Endpoint api/v2/public/media/$ref/watchers failed with DioException: ${e.message}');
      throw NetworkException.fromDio(e);
    }
  }

  /// Media watch history (GET /api/v2/public/media/{ref}/history).
  Future<TracearrV2HistoryResponse> getMediaHistory({
    required String ref,
    String? cursor,
    int? pageSize,
  }) async {
    try {
      final Map<String, dynamic> query = <String, dynamic>{
        if (cursor != null) 'cursor': cursor,
        if (pageSize != null) 'pageSize': pageSize,
      };
      final Response<dynamic> resp = await _dio.get<dynamic>(
        'api/v2/public/media/$ref/history',
        queryParameters: query,
      );
      if (resp.data is! Map<String, dynamic>) {
        debugPrint('[Tracearr API Warning] Non-JSON payload received from api/v2/public/media/$ref/history: ${resp.data}');
        throw NetworkUnknownException('Unexpected server response format: ${resp.data}');
      }
      try {
        return TracearrV2HistoryResponse.fromJson(
          resp.data as Map<String, dynamic>,
        );
      } catch (err) {
        debugPrint('[Tracearr API Parsing Error] Endpoint api/v2/public/media/$ref/history failed deserialization into TracearrV2HistoryResponse: $err\nRaw Payload: ${resp.data}');
        rethrow;
      }
    } on DioException catch (e) {
      debugPrint('[Tracearr API Network Error] Endpoint api/v2/public/media/$ref/history failed with DioException: ${e.message}');
      throw NetworkException.fromDio(e);
    }
  }

  /// Identities with account correlation (GET /api/v2/public/users).
  Future<TracearrV2UsersResponse> getUsers({
    String? cursor,
    int? pageSize,
    String? includeRemoved,
  }) async {
    try {
      final Map<String, dynamic> query = <String, dynamic>{
        if (cursor != null) 'cursor': cursor,
        if (pageSize != null) 'pageSize': pageSize,
        if (includeRemoved != null) 'include_removed': includeRemoved,
      };
      final Response<dynamic> resp = await _dio.get<dynamic>(
        'api/v2/public/users',
        queryParameters: query,
      );
      if (resp.data is! Map<String, dynamic>) {
        debugPrint('[Tracearr API Warning] Non-JSON payload received from api/v2/public/users: ${resp.data}');
        throw NetworkUnknownException('Unexpected server response format: ${resp.data}');
      }
      try {
        return TracearrV2UsersResponse.fromJson(
          resp.data as Map<String, dynamic>,
        );
      } catch (err) {
        debugPrint('[Tracearr API Parsing Error] Endpoint api/v2/public/users failed deserialization into TracearrV2UsersResponse: $err\nRaw Payload: ${resp.data}');
        rethrow;
      }
    } on DioException catch (e) {
      debugPrint('[Tracearr API Network Error] Endpoint api/v2/public/users failed with DioException: ${e.message}');
      throw NetworkException.fromDio(e);
    }
  }

  /// One identity (GET /api/v2/public/users/{id}).
  Future<TracearrV2UserIdentity> getUserById({
    required String id,
  }) async {
    try {
      final Response<dynamic> resp = await _dio.get<dynamic>(
        'api/v2/public/users/$id',
      );
      if (resp.data is! Map<String, dynamic>) {
        debugPrint('[Tracearr API Warning] Non-JSON payload received from api/v2/public/users/$id: ${resp.data}');
        throw NetworkUnknownException('Unexpected server response format: ${resp.data}');
      }
      try {
        return TracearrV2UserIdentity.fromJson(
          resp.data as Map<String, dynamic>,
        );
      } catch (err) {
        debugPrint('[Tracearr API Parsing Error] Endpoint api/v2/public/users/$id failed deserialization into TracearrV2UserIdentity: $err\nRaw Payload: ${resp.data}');
        rethrow;
      }
    } on DioException catch (e) {
      debugPrint('[Tracearr API Network Error] Endpoint api/v2/public/users/$id failed with DioException: ${e.message}');
      throw NetworkException.fromDio(e);
    }
  }

  /// Identity play statistics (GET /api/v2/public/users/{id}/stats).
  Future<TracearrV2UserStatsResponse> getUserStats({
    required String id,
  }) async {
    try {
      final Response<dynamic> resp = await _dio.get<dynamic>(
        'api/v2/public/users/$id/stats',
      );
      if (resp.data is! Map<String, dynamic>) {
        debugPrint('[Tracearr API Warning] Non-JSON payload received from api/v2/public/users/$id/stats: ${resp.data}');
        throw NetworkUnknownException('Unexpected server response format: ${resp.data}');
      }
      try {
        return TracearrV2UserStatsResponse.fromJson(
          resp.data as Map<String, dynamic>,
        );
      } catch (err) {
        debugPrint('[Tracearr API Parsing Error] Endpoint api/v2/public/users/$id/stats failed deserialization into TracearrV2UserStatsResponse: $err\nRaw Payload: ${resp.data}');
        rethrow;
      }
    } on DioException catch (e) {
      debugPrint('[Tracearr API Network Error] Endpoint api/v2/public/users/$id/stats failed with DioException: ${e.message}');
      throw NetworkException.fromDio(e);
    }
  }

  /// Identity watch history (GET /api/v2/public/users/{id}/history).
  Future<TracearrV2HistoryResponse> getUserHistory({
    required String id,
    String? cursor,
    int? pageSize,
  }) async {
    try {
      final Map<String, dynamic> query = <String, dynamic>{
        if (cursor != null) 'cursor': cursor,
        if (pageSize != null) 'pageSize': pageSize,
      };
      final Response<dynamic> resp = await _dio.get<dynamic>(
        'api/v2/public/users/$id/history',
        queryParameters: query,
      );
      if (resp.data is! Map<String, dynamic>) {
        debugPrint('[Tracearr API Warning] Non-JSON payload received from api/v2/public/users/$id/history: ${resp.data}');
        throw NetworkUnknownException('Unexpected server response format: ${resp.data}');
      }
      try {
        return TracearrV2HistoryResponse.fromJson(
          resp.data as Map<String, dynamic>,
        );
      } catch (err) {
        debugPrint('[Tracearr API Parsing Error] Endpoint api/v2/public/users/$id/history failed deserialization into TracearrV2HistoryResponse: $err\nRaw Payload: ${resp.data}');
        rethrow;
      }
    } on DioException catch (e) {
      debugPrint('[Tracearr API Network Error] Endpoint api/v2/public/users/$id/history failed with DioException: ${e.message}');
      throw NetworkException.fromDio(e);
    }
  }

  /// Recently added library items (GET /api/v2/public/recently-added).
  Future<TracearrV2RecentlyAddedResponse> getRecentlyAdded({
    String? cursor,
    int? pageSize,
    String? serverId,
    String? libraryId,
    String? mediaType,
    String? includeRemoved,
  }) async {
    try {
      final Map<String, dynamic> query = <String, dynamic>{
        if (cursor != null) 'cursor': cursor,
        if (pageSize != null) 'pageSize': pageSize,
        if (serverId != null) 'server_id': serverId,
        if (libraryId != null) 'library_id': libraryId,
        if (mediaType != null) 'media_type': mediaType,
        if (includeRemoved != null) 'include_removed': includeRemoved,
      };
      final Response<dynamic> resp = await _dio.get<dynamic>(
        'api/v2/public/recently-added',
        queryParameters: query,
      );
      if (resp.data is! Map<String, dynamic>) {
        debugPrint('[Tracearr API Warning] Non-JSON payload received from api/v2/public/recently-added: ${resp.data}');
        throw NetworkUnknownException('Unexpected server response format: ${resp.data}');
      }
      try {
        return TracearrV2RecentlyAddedResponse.fromJson(
          resp.data as Map<String, dynamic>,
        );
      } catch (err) {
        debugPrint('[Tracearr API Parsing Error] Endpoint api/v2/public/recently-added failed deserialization into TracearrV2RecentlyAddedResponse: $err\nRaw Payload: ${resp.data}');
        rethrow;
      }
    } on DioException catch (e) {
      debugPrint('[Tracearr API Network Error] Endpoint api/v2/public/recently-added failed with DioException: ${e.message}');
      throw NetworkException.fromDio(e);
    }
  }

  /// Per-library rollups (GET /api/v2/public/libraries).
  Future<TracearrV2LibrariesResponse> getLibraries() async {
    try {
      final Response<dynamic> resp = await _dio.get<dynamic>(
        'api/v2/public/libraries',
      );
      if (resp.data is! Map<String, dynamic>) {
        debugPrint('[Tracearr API Warning] Non-JSON payload received from api/v2/public/libraries: ${resp.data}');
        throw NetworkUnknownException('Unexpected server response format: ${resp.data}');
      }
      try {
        return TracearrV2LibrariesResponse.fromJson(
          resp.data as Map<String, dynamic>,
        );
      } catch (err) {
        debugPrint('[Tracearr API Parsing Error] Endpoint api/v2/public/libraries failed deserialization into TracearrV2LibrariesResponse: $err\nRaw Payload: ${resp.data}');
        rethrow;
      }
    } on DioException catch (e) {
      debugPrint('[Tracearr API Network Error] Endpoint api/v2/public/libraries failed with DioException: ${e.message}');
      throw NetworkException.fromDio(e);
    }
  }

}

