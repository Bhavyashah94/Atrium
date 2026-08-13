import '../media/tracearr_media_url_resolver.dart';
import 'tracearr_memory_cache.dart';

/// Client-side artwork and avatar cache for Tracearr.
///
/// Stores `(serverId, ratingKey) -> thumbPath` and `(serverId, userId) -> avatarUrl`
/// mappings in a bounded in-memory LRU cache to eliminate N+1 API waterfalls
/// when rendering Recently Added grids or user feeds.
class TracearrArtworkCache {
  TracearrArtworkCache({
    int maxEntries = 500,
    // ignore: avoid_unused_constructor_parameters
    dynamic box,
  }) : _memCache = TracearrMemoryCache<String, String>(maxEntries: maxEntries);

  static const String boxName = 'service.tracearr.artwork_cache';

  final TracearrMemoryCache<String, String> _memCache;

  /// Compute cache key for media items.
  static String makeMediaKey(String serverId, String ratingKey) =>
      '${serverId}_media_$ratingKey';

  /// Compute cache key for canonical media IDs.
  static String makeMediaIdKey(String serverId, String mediaId) =>
      '${serverId}_media_id_$mediaId';

  /// Compute cache key for user avatars.
  static String makeUserKey(String serverId, String userId) =>
      '${serverId}_user_$userId';

  /// Retrieve cached poster/thumb path for a media rating key.
  String? getThumbPath(String serverId, String ratingKey) {
    final key = makeMediaKey(serverId, ratingKey);
    return _memCache.get(key);
  }

  /// Retrieve cached poster/thumb path by media UUID.
  String? getThumbPathByMediaId(String serverId, String mediaId) {
    final key = makeMediaIdKey(serverId, mediaId);
    return _memCache.get(key);
  }

  /// Retrieve cached avatar URL for a user.
  String? getUserAvatarUrl(String serverId, String userId) {
    final key = makeUserKey(serverId, userId);
    return _memCache.get(key);
  }

  /// Put a poster/thumb path into the cache.
  Future<void> putThumbPath({
    required String serverId,
    required String thumbPath,
    String? ratingKey,
    String? mediaId,
  }) async {
    if (thumbPath.isEmpty) return;

    if (ratingKey != null && ratingKey.isNotEmpty) {
      final key = makeMediaKey(serverId, ratingKey);
      _memCache.put(key, thumbPath);
    }

    if (mediaId != null && mediaId.isNotEmpty) {
      final key = makeMediaIdKey(serverId, mediaId);
      _memCache.put(key, thumbPath);
    }
  }

  /// Put a user avatar URL into the cache under userId (UUID) and/or username.
  Future<void> putUserAvatarUrl({
    required String serverId,
    required String avatarUrl,
    String? userId,
    String? username,
  }) async {
    if (avatarUrl.isEmpty) return;

    if (userId != null && userId.isNotEmpty) {
      final key = makeUserKey(serverId, userId);
      _memCache.put(key, avatarUrl);
    }

    if (username != null && username.isNotEmpty) {
      final key = makeUserKey(serverId, username);
      _memCache.put(key, avatarUrl);
    }
  }

  /// Build an unauthenticated Tracearr image proxy URL client-side.
  ///
  /// Verified against `apps/server/src/routes/images.ts:69` (`GET /api/v1/images/proxy`).
  static String buildProxyPosterUrl({
    required String baseUrl,
    required String serverId,
    required String thumbPath,
    int width = 300,
    int height = 450,
    String fallback = 'poster',
  }) {
    return TracearrMediaUrlResolver.buildProxyPosterUrl(
      baseUrl: baseUrl,
      serverId: serverId,
      thumbPath: thumbPath,
      width: width,
      height: height,
      fallback: fallback,
    );
  }
}
