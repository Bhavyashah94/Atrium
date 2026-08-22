import 'package:collection/collection.dart';
import 'package:core_models/core_models.dart';

import 'generated/models/media_cover.dart';
import 'generated/models/media_cover_types.dart';

/// Artwork helpers for Lidarr items.
abstract final class LidarrArtwork {
  static const String _apiBase = '/api/v1';

  /// Builds an absolute, authenticated image URL for an item's [MediaCover].
  static String? imageUrl({
    required Instance instance,
    required List<MediaCover>? images,
    required MediaCoverTypes coverType,
    int? width,
    bool preferRemote = false,
  }) {
    if (images == null || images.isEmpty) return null;

    final MediaCover? cover = images.firstWhereOrNull(
      (c) => c.coverType == coverType,
    );
    if (cover == null) return null;

    final bool isProxy = cover.url != null &&
        cover.url!.toLowerCase().startsWith('/mediacoverproxy/');

    if ((preferRemote || isProxy) &&
        cover.remoteUrl != null &&
        cover.remoteUrl!.isNotEmpty &&
        cover.remoteUrl!.startsWith('http')) {
      return cover.remoteUrl;
    }

    final String? localUrl = cover.url;
    if (localUrl == null || localUrl.isEmpty) {
      if (cover.remoteUrl != null &&
          cover.remoteUrl!.isNotEmpty &&
          cover.remoteUrl!.startsWith('http')) {
        return cover.remoteUrl;
      }
      return null;
    }

    final String rawBase =
        instance.localUrl.isNotEmpty ? instance.localUrl : instance.externalUrl;
    if (rawBase.isEmpty) {
      if (cover.remoteUrl != null &&
          cover.remoteUrl!.isNotEmpty &&
          cover.remoteUrl!.startsWith('http')) {
        return cover.remoteUrl;
      }
      return null;
    }

    String pathOrUrl = localUrl;

    // Width suffix handling (e.g. poster.jpg -> poster-250.jpg)
    // Only apply width suffixes to local /MediaCover/ paths, never /MediaCoverProxy/
    if (width != null && !isProxy) {
      final int queryIdx = pathOrUrl.indexOf('?');
      final String pathPart =
          queryIdx == -1 ? pathOrUrl : pathOrUrl.substring(0, queryIdx);
      final String queryPart =
          queryIdx == -1 ? '' : pathOrUrl.substring(queryIdx);

      final int dotIdx = pathPart.lastIndexOf('.');
      if (dotIdx != -1) {
        final String basePart = pathPart.substring(0, dotIdx);
        final String extPart = pathPart.substring(dotIdx);
        if (!basePart.endsWith('-$width')) {
          pathOrUrl = '$basePart-$width$extPart$queryPart';
        }
      }
    }

    // Rewrite internal /MediaCover/ paths to official Lidarr /api/v1/mediacover/ routes
    final String lower = pathOrUrl.toLowerCase();
    if (lower.startsWith('/mediacover/albums/')) {
      pathOrUrl =
          '$_apiBase/mediacover/album/${pathOrUrl.substring('/MediaCover/Albums/'.length)}';
    } else if (lower.startsWith('/mediacover/album/')) {
      pathOrUrl =
          '$_apiBase/mediacover/album/${pathOrUrl.substring('/MediaCover/album/'.length)}';
    } else if (lower.startsWith('/mediacover/artists/') ||
        lower.startsWith('/mediacover/artist/')) {
      final int prefixLen = lower.startsWith('/mediacover/artists/')
          ? '/MediaCover/artists/'.length
          : '/MediaCover/artist/'.length;
      pathOrUrl =
          '$_apiBase/mediacover/artist/${pathOrUrl.substring(prefixLen)}';
    } else if (lower.startsWith('/mediacover/')) {
      pathOrUrl =
          '$_apiBase/mediacover/artist/${pathOrUrl.substring('/MediaCover/'.length)}';
    }

    final String? apiKey = switch (instance.auth) {
      InstanceAuthApiKey(:final String apiKey) => apiKey,
      _ => null,
    };

    final String cleanPath =
        pathOrUrl.startsWith('/') ? pathOrUrl.substring(1) : pathOrUrl;
    final String separator = cleanPath.contains('?') ? '&' : '?';
    final String resolvedPath = apiKey != null && apiKey.isNotEmpty
        ? '$cleanPath${separator}apikey=$apiKey'
        : cleanPath;

    final Uri base = Uri.parse(rawBase.endsWith('/') ? rawBase : '$rawBase/');
    return base.resolve(resolvedPath).toString();
  }

  /// Poster / artwork image for an artist. Defaults to optimized 250px thumbnail.
  static String? artistPosterUrl(
    Instance instance,
    List<MediaCover>? images, {
    int? width = 250,
    bool preferRemote = false,
  }) =>
      imageUrl(
        instance: instance,
        images: images,
        coverType: MediaCoverTypes.poster,
        width: width,
        preferRemote: preferRemote,
      ) ??
      imageUrl(
        instance: instance,
        images: images,
        coverType: MediaCoverTypes.cover,
        width: width,
        preferRemote: preferRemote,
      );

  /// Fanart / backdrop image for an artist with progressive fallback.
  static String? artistFanartUrl(
    Instance instance,
    List<MediaCover>? images, {
    int? width,
    bool preferRemote = false,
  }) =>
      imageUrl(
        instance: instance,
        images: images,
        coverType: MediaCoverTypes.fanart,
        width: width,
        preferRemote: preferRemote,
      ) ??
      imageUrl(
        instance: instance,
        images: images,
        coverType: MediaCoverTypes.banner,
        width: width,
        preferRemote: preferRemote,
      ) ??
      imageUrl(
        instance: instance,
        images: images,
        coverType: MediaCoverTypes.poster,
        width: width,
        preferRemote: preferRemote,
      ) ??
      imageUrl(
        instance: instance,
        images: images,
        coverType: MediaCoverTypes.cover,
        width: width,
        preferRemote: preferRemote,
      );

  /// Cover artwork for an album. Defaults to optimized 250px thumbnail.
  static String? albumCoverUrl(
    Instance instance,
    List<MediaCover>? images, {
    int? width = 250,
    bool preferRemote = false,
  }) =>
      imageUrl(
        instance: instance,
        images: images,
        coverType: MediaCoverTypes.cover,
        width: width,
        preferRemote: preferRemote,
      ) ??
      imageUrl(
        instance: instance,
        images: images,
        coverType: MediaCoverTypes.poster,
        width: width,
        preferRemote: preferRemote,
      );
}
