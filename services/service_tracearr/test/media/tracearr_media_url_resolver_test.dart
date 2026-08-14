import 'package:flutter_test/flutter_test.dart';
import 'package:service_tracearr/src/media/tracearr_media_url_resolver.dart';

void main() {
  group('TracearrMediaUrlResolver', () {
    test('formatUrl normalizes relative and absolute URLs', () {
      const baseUrl = 'https://tr.example.com///';

      expect(
        TracearrMediaUrlResolver.formatUrl(
          baseUrl: baseUrl,
          rawUrl: 'https://cdn.example.com/art.jpg',
        ),
        equals('https://cdn.example.com/art.jpg'),
      );

      expect(
        TracearrMediaUrlResolver.formatUrl(
          baseUrl: baseUrl,
          rawUrl: '/api/v1/images/proxy?server=s1',
        ),
        equals('https://tr.example.com/api/v1/images/proxy?server=s1'),
      );

      expect(
        TracearrMediaUrlResolver.formatUrl(
          baseUrl: baseUrl,
          rawUrl: 'images/poster.jpg',
        ),
        equals('https://tr.example.com/images/poster.jpg'),
      );

      expect(
        TracearrMediaUrlResolver.formatUrl(
          baseUrl: baseUrl,
          rawUrl: '',
        ),
        isNull,
      );

      expect(
        TracearrMediaUrlResolver.formatUrl(
          baseUrl: baseUrl,
        ),
        isNull,
      );
    });

    test('buildProxyPosterUrl builds correct unauthenticated proxy URL', () {
      final proxyUrl = TracearrMediaUrlResolver.buildProxyPosterUrl(
        baseUrl: 'https://tr.example.com/',
        serverId: 'server-uuid-1',
        thumbPath: '/library/metadata/123/thumb/456',
        width: 400,
        height: 600,
        fallback: 'avatar',
      );

      expect(
        proxyUrl,
        equals(
          'https://tr.example.com/api/v1/images/proxy?server=server-uuid-1&url=%2Flibrary%2Fmetadata%2F123%2Fthumb%2F456&width=400&height=600&fallback=avatar',
        ),
      );
    });

    test('buildFallbackPosterPath returns correct server type paths', () {
      expect(
        TracearrMediaUrlResolver.buildFallbackPosterPath('plex', '500'),
        equals('/library/metadata/500/thumb'),
      );

      expect(
        TracearrMediaUrlResolver.buildFallbackPosterPath('Plex', '500'),
        equals('/library/metadata/500/thumb'),
      );

      expect(
        TracearrMediaUrlResolver.buildFallbackPosterPath('jellyfin', 'item_1'),
        equals('/Items/item_1/Images/Primary'),
      );

      expect(
        TracearrMediaUrlResolver.buildFallbackPosterPath('emby', 'item_2'),
        equals('/Items/item_2/Images/Primary'),
      );
    });

    test('buildUserAvatarPath returns correct server user avatar paths', () {
      expect(
        TracearrMediaUrlResolver.buildUserAvatarPath('plex', 'user_plex_1'),
        equals('/users/user_plex_1/avatar'),
      );

      expect(
        TracearrMediaUrlResolver.buildUserAvatarPath('jellyfin', 'user_jf_1'),
        equals('/Users/user_jf_1/Images/Primary'),
      );

      expect(
        TracearrMediaUrlResolver.buildUserAvatarPath('emby', 'user_emby_1'),
        equals('/Users/user_emby_1/Images/Primary'),
      );
    });

    group('buildMediaServerItemUrl deep links', () {
      test('Plex deep link routes through app.plex.tv with machineIdentifier',
          () {
        final link = TracearrMediaUrlResolver.buildMediaServerItemUrl(
          serverType: 'plex',
          baseUrl: 'http://192.168.1.50:32400',
          ratingKey: '45678',
          machineIdentifier: 'machine_abc_123',
        );

        expect(
          link,
          equals(
            'https://app.plex.tv/desktop/#!/server/machine_abc_123/details?key=%2Flibrary%2Fmetadata%2F45678',
          ),
        );
      });

      test('Plex deep link returns null if machineIdentifier is missing', () {
        final link = TracearrMediaUrlResolver.buildMediaServerItemUrl(
          serverType: 'plex',
          baseUrl: 'http://192.168.1.50:32400',
          ratingKey: '45678',
        );

        expect(link, isNull);
      });

      test('Emby deep link formats with server root and serverId', () {
        final link = TracearrMediaUrlResolver.buildMediaServerItemUrl(
          serverType: 'emby',
          baseUrl: 'https://emby.example.com/',
          ratingKey: '9876',
          machineIdentifier: 'emby_server_id',
        );

        expect(
          link,
          equals(
            'https://emby.example.com/web/index.html#!/item?id=9876&serverId=emby_server_id',
          ),
        );
      });

      test('Jellyfin deep link formats with server root and item id', () {
        final link = TracearrMediaUrlResolver.buildMediaServerItemUrl(
          serverType: 'jellyfin',
          baseUrl: 'https://jellyfin.example.com///',
          ratingKey: 'jf_item_123',
        );

        expect(
          link,
          equals(
            'https://jellyfin.example.com/web/index.html#/details?id=jf_item_123',
          ),
        );
      });

      test('returns null for unknown server type or empty ratingKey', () {
        expect(
          TracearrMediaUrlResolver.buildMediaServerItemUrl(
            serverType: 'unknown',
            baseUrl: 'https://example.com',
            ratingKey: '123',
          ),
          isNull,
        );

        expect(
          TracearrMediaUrlResolver.buildMediaServerItemUrl(
            serverType: 'plex',
            baseUrl: 'https://example.com',
            ratingKey: '',
          ),
          isNull,
        );
      });
    });
  });
}
