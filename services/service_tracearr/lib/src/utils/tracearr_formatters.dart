import 'package:core_models/core_models.dart';
import 'package:intl/intl.dart';

import '../generated/models/recently_added_record.dart';
import '../generated/models/user_identity.dart';

/// Helper utilities for formatting bytes, durations, dates, and resolving media/user image URLs in Tracearr.
abstract class TracearrFormatters {
  /// Formats byte counts into human-readable strings (e.g., 570.1 GB).
  static String formatBytes(int? bytes) {
    if (bytes == null || bytes <= 0) return '0 B';
    if (bytes < 1024) return '$bytes B';
    final kb = bytes / 1024;
    if (kb < 1024) return '${kb.toStringAsFixed(1)} KB';
    final mb = kb / 1024;
    if (mb < 1024) return '${mb.toStringAsFixed(1)} MB';
    final gb = mb / 1024;
    if (gb < 1024) return '${gb.toStringAsFixed(1)} GB';
    final tb = gb / 1024;
    return '${tb.toStringAsFixed(2)} TB';
  }

  /// Formats ISO date string into readable date (e.g., "Aug 11, 2026").
  static String formatDate(String? isoString) {
    if (isoString == null || isoString.isEmpty) return '';
    try {
      final dateTime = DateTime.parse(isoString).toLocal();
      return DateFormat('MMM d, yyyy • h:mm a').format(dateTime);
    } catch (_) {
      return isoString;
    }
  }

  /// Formats millisecond duration into "1h 45m" or "22m".
  static String formatDurationMs(int? durationMs) {
    if (durationMs == null || durationMs <= 0) return '0m';
    final seconds = durationMs ~/ 1000;
    final minutes = seconds ~/ 60;
    if (minutes < 60) return '${minutes}m';
    final hours = minutes ~/ 60;
    final remMinutes = minutes % 60;
    return '${hours}h ${remMinutes}m';
  }

  /// Resolves relative media poster or avatar URLs against instance base URL with authenticated apiKey query param.
  static String? resolveImageUrl(String? path, Instance instance) {
    if (path == null || path.isEmpty) return null;

    final String? token = switch (instance.auth) {
      InstanceAuthApiKey(:final String apiKey) => apiKey,
      _ => null,
    };

    String fullUrl;
    if (path.startsWith('http://') || path.startsWith('https://')) {
      fullUrl = path;
    } else {
      final baseUrlStr = instance.externalUrl.isNotEmpty
          ? instance.externalUrl
          : instance.localUrl;
      final baseUrl = baseUrlStr.replaceAll(RegExp(r'/$'), '');
      final cleanPath = path.startsWith('/') ? path : '/$path';
      fullUrl = '$baseUrl$cleanPath';
    }

    if (token != null && token.isNotEmpty) {
      final separator = fullUrl.contains('?') ? '&' : '?';
      if (!fullUrl.contains('apiKey=') && !fullUrl.contains('apikey=')) {
        fullUrl = '$fullUrl${separator}apiKey=$token';
      }
    }

    return fullUrl;
  }

  /// Resolves user avatar image URL for [UserIdentity]. Fallback to server account external/server user ID proxy URL if avatarUrl is null.
  /// Resolves user avatar image URL for [UserIdentity]. Fallback to server account external/server user ID proxy URL if avatarUrl is null.
  static String? resolveUserAvatarUrl(UserIdentity user, Instance instance) {
    final accounts = user.accounts ?? [];
    if (accounts.isNotEmpty) {
      final acc = accounts.first;
      final sid = acc.serverId;
      final uid = acc.externalUserId ?? acc.serverUserId;
      if (sid != null && uid != null) {
        final serverType = acc.serverType?.toLowerCase() ?? '';
        final innerPath = serverType == 'plex'
            ? '/users/$uid/avatar'
            : '/Users/$uid/Images/Primary';
        final encodedServer = Uri.encodeQueryComponent(sid);
        final encodedUrl = Uri.encodeQueryComponent(innerPath);
        final path =
            '/api/v1/images/proxy?server=$encodedServer&url=$encodedUrl&width=100&height=100&fallback=avatar';
        return resolveImageUrl(path, instance);
      }
    }
    return null;
  }

  /// Resolves media poster image URL for [RecentlyAddedRecord]. Construct server image proxy URL if posterUrl is null.
  static String? resolveRecentlyAddedPosterUrl(
    RecentlyAddedRecord item,
    Instance instance,
  ) {
    final sid = item.serverId;
    final ratingKey =
        item.grandparentRatingKey ?? item.parentRatingKey ?? item.ratingKey;
    if (sid != null && ratingKey != null) {
      final serverType = item.serverType?.toLowerCase() ?? '';
      final innerPath = serverType == 'plex'
          ? '/library/metadata/$ratingKey/thumb'
          : '/Items/$ratingKey/Images/Primary';
      final encodedServer = Uri.encodeQueryComponent(sid);
      final encodedUrl = Uri.encodeQueryComponent(innerPath);
      final path =
          '/api/v1/images/proxy?server=$encodedServer&url=$encodedUrl&width=300&height=450&fallback=poster';
      return resolveImageUrl(path, instance);
    }
    return null;
  }

  /// Gets HTTP headers required for requesting image proxy endpoints (Bearer authentication).
  static Map<String, String>? getImageHeaders(Instance instance) {
    final String? token = switch (instance.auth) {
      InstanceAuthApiKey(:final String apiKey) => apiKey,
      _ => null,
    };
    if (token != null && token.isNotEmpty) {
      return {
        'Authorization': 'Bearer $token',
      };
    }
    return null;
  }

  /// Formats DateTime to relative string (e.g. "12m ago", "2h ago", "Yesterday", "MMM d").
  static String formatRelativeTime(DateTime? date) {
    if (date == null) return '';
    final now = DateTime.now();
    final diff = now.difference(date.toLocal());
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('MMM d').format(date.toLocal());
  }
}
