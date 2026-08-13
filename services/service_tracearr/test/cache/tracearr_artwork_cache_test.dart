import 'package:flutter_test/flutter_test.dart';
import 'package:service_tracearr/src/cache/tracearr_artwork_cache.dart';

void main() {
  group('TracearrArtworkCache', () {
    late TracearrArtworkCache cache;

    setUp(() {
      cache = TracearrArtworkCache();
    });

    test('stores and retrieves thumb path by ratingKey and mediaId in memory',
        () async {
      const serverId = 'be8aa256-17a1-4135-9044-b8f3cca268e0';
      const ratingKey = '21225';
      const mediaId = 'a0dbd8ff-19fb-4238-b578-d7eb6974dd9a';
      const thumbPath = '/Items/20374/Images/Primary';

      await cache.putThumbPath(
        serverId: serverId,
        thumbPath: thumbPath,
        ratingKey: ratingKey,
        mediaId: mediaId,
      );

      expect(cache.getThumbPath(serverId, ratingKey), equals(thumbPath));
      expect(cache.getThumbPathByMediaId(serverId, mediaId), equals(thumbPath));
      expect(cache.getThumbPath(serverId, 'unknown'), isNull);
    });

    test(
        'stores and retrieves user avatar URL in memory by userId and username',
        () async {
      const serverId = 'be8aa256-17a1-4135-9044-b8f3cca268e0';
      const userId = 'eee3851d-ff91-42b5-b962-d89822ded5bc';
      const username = 'Bhavyashah';
      const avatarUrl =
          '/api/v1/images/proxy?server=$serverId&url=%2FUsers%2Ffd07a86dc55940a7b01926fae84a8005%2FImages%2FPrimary';

      await cache.putUserAvatarUrl(
        serverId: serverId,
        userId: userId,
        username: username,
        avatarUrl: avatarUrl,
      );

      expect(cache.getUserAvatarUrl(serverId, userId), equals(avatarUrl));
      expect(cache.getUserAvatarUrl(serverId, username), equals(avatarUrl));
      expect(cache.getUserAvatarUrl(serverId, 'other_user'), isNull);
    });

    test('buildProxyPosterUrl builds correct unauthenticated proxy URL', () {
      const baseUrl = 'https://tr.betelgeuse.fun/';
      const serverId = 'be8aa256-17a1-4135-9044-b8f3cca268e0';
      const thumbPath = '/Items/20374/Images/Primary';

      final proxyUrl = TracearrArtworkCache.buildProxyPosterUrl(
        baseUrl: baseUrl,
        serverId: serverId,
        thumbPath: thumbPath,
      );

      expect(
        proxyUrl,
        equals(
          'https://tr.betelgeuse.fun/api/v1/images/proxy?server=be8aa256-17a1-4135-9044-b8f3cca268e0&url=%2FItems%2F20374%2FImages%2FPrimary&width=300&height=450&fallback=poster',
        ),
      );
    });
  });
}
