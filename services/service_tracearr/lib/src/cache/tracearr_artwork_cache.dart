import 'package:hive_ce/hive.dart';

import '../media/tracearr_media_url_resolver.dart';
import 'tracearr_memory_cache.dart';

/// Client-side artwork and avatar cache for Tracearr.
///
/// Stores `(serverId, ratingKey) -> thumbPath` and `(serverId, userId) -> avatarUrl`
/// mappings to eliminate N+1 API waterfalls when rendering Recently Added grids
/// or user feeds.
///
/// Two tiers: a bounded in-memory LRU in front of an optional Hive box. The box
/// is what makes a cold start cheap - without it the very first paint after
/// every launch walks the whole waterfall again. [box] stays optional so tests
/// (and any caller before Hive is ready) can use the memory tier alone.
class TracearrArtworkCache {
  TracearrArtworkCache({
    int maxEntries = 500,
    Box<String>? box,
  })  : _memCache = TracearrMemoryCache<String, String>(maxEntries: maxEntries),
        _box = box;

  static const String boxName = 'service.tracearr.artwork_cache';

  final TracearrMemoryCache<String, String> _memCache;
  final Box<String>? _box;

  /// Read through the memory tier, falling back to the persistent box.
  ///
  /// A box hit is promoted into memory so repeat lookups stay allocation-free.
  String? _read(String key) {
    final cached = _memCache.get(key);
    if (cached != null) return cached;

    final persisted = _box?.get(key);
    if (persisted != null && persisted.isNotEmpty) {
      _memCache.put(key, persisted);
      return persisted;
    }
    return null;
  }

  /// Write through both tiers, skipping the disk write when nothing changed.
  ///
  /// Artwork is harvested on every poll, so without this guard the same keys
  /// would be rewritten to disk on each tick.
  Future<void> _write(String key, String value) async {
    if (_memCache.get(key) == value) return;
    _memCache.put(key, value);
    try {
      await _box?.put(key, value);
    } catch (_) {
      // A failed persist must never break rendering; the memory tier still holds it.
    }
  }

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
    return _read(makeMediaKey(serverId, ratingKey));
  }

  /// Retrieve cached poster/thumb path by media UUID.
  String? getThumbPathByMediaId(String serverId, String mediaId) {
    return _read(makeMediaIdKey(serverId, mediaId));
  }

  /// Retrieve cached avatar URL for a user.
  String? getUserAvatarUrl(String serverId, String userId) {
    return _read(makeUserKey(serverId, userId));
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
      await _write(makeMediaKey(serverId, ratingKey), thumbPath);
    }

    if (mediaId != null && mediaId.isNotEmpty) {
      await _write(makeMediaIdKey(serverId, mediaId), thumbPath);
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
      await _write(makeUserKey(serverId, userId), avatarUrl);
    }

    if (username != null && username.isNotEmpty) {
      await _write(makeUserKey(serverId, username), avatarUrl);
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
