/// Pure URL builder and deep link resolver for Tracearr media items and avatars.
///
/// Implements deep linking formats verified against Tracearr backend
/// (`packages/shared/src/mediaServerLinks.ts`) and image proxy endpoints
/// (`apps/server/src/routes/images.ts`).
class TracearrMediaUrlResolver {
  const TracearrMediaUrlResolver._();

  static const String _plexAppBase = 'https://app.plex.tv/desktop';

  /// Format a relative or absolute URL with the provided [baseUrl].
  static String? formatUrl({
    required String baseUrl,
    String? rawUrl,
  }) {
    if (rawUrl == null || rawUrl.isEmpty) return null;
    if (rawUrl.startsWith('http://') || rawUrl.startsWith('https://')) {
      return rawUrl;
    }
    final cleanBase = baseUrl.replaceAll(RegExp(r'/+$'), '');
    final cleanPath = rawUrl.startsWith('/') ? rawUrl : '/$rawUrl';
    return '$cleanBase$cleanPath';
  }

  /// Build an unauthenticated Tracearr image proxy URL.
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
    final cleanBase = baseUrl.replaceAll(RegExp(r'/+$'), '');
    final encodedServer = Uri.encodeQueryComponent(serverId);
    final encodedUrl = Uri.encodeQueryComponent(thumbPath);
    return '$cleanBase/api/v1/images/proxy?server=$encodedServer&url=$encodedUrl&width=$width&height=$height&fallback=$fallback';
  }

  /// Return the standard media server poster path when no custom thumbnail is cached.
  static String buildFallbackPosterPath(String? serverType, String ratingKey) {
    if (serverType?.toLowerCase() == 'plex') {
      return '/library/metadata/$ratingKey/thumb';
    }
    return '/Items/$ratingKey/Images/Primary';
  }

  /// Return the standard media server user avatar path.
  static String buildUserAvatarPath(String? serverType, String externalUserId) {
    if (serverType?.toLowerCase() == 'plex') {
      return '/users/$externalUserId/avatar';
    }
    return '/Users/$externalUserId/Images/Primary';
  }

  /// Deep link to a single item in a media server's own web client.
  ///
  /// Verified against Tracearr backend `packages/shared/src/mediaServerLinks.ts`.
  /// Returns `null` if required identifiers (e.g. `machineIdentifier` for Plex/Emby) are missing.
  static String? buildMediaServerItemUrl({
    required String serverType,
    required String baseUrl,
    required String ratingKey,
    String? machineIdentifier,
  }) {
    if (ratingKey.isEmpty) return null;

    switch (serverType.toLowerCase()) {
      case 'plex':
        if (machineIdentifier == null || machineIdentifier.isEmpty) {
          return null;
        }
        final key = Uri.encodeComponent('/library/metadata/$ratingKey');
        final encodedMachine = Uri.encodeComponent(machineIdentifier);
        return '$_plexAppBase/#!/server/$encodedMachine/details?key=$key';

      case 'emby':
        if (machineIdentifier == null || machineIdentifier.isEmpty) {
          return null;
        }
        final root = baseUrl.replaceAll(RegExp(r'/+$'), '');
        if (root.isEmpty) return null;
        final encodedKey = Uri.encodeComponent(ratingKey);
        final encodedServerId = Uri.encodeComponent(machineIdentifier);
        return '$root/web/index.html#!/item?id=$encodedKey&serverId=$encodedServerId';

      case 'jellyfin':
        final root = baseUrl.replaceAll(RegExp(r'/+$'), '');
        if (root.isEmpty) return null;
        final encodedKey = Uri.encodeComponent(ratingKey);
        return '$root/web/index.html#/details?id=$encodedKey';

      default:
        return null;
    }
  }
}
