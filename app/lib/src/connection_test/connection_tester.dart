import 'package:core_models/core_models.dart';
import 'package:core_networking/core_networking.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:service_emby/service_emby.dart';
import 'package:service_jellyfin/service_jellyfin.dart';
import 'package:service_plex/service_plex.dart';
import 'package:service_qbittorrent/service_qbittorrent.dart';

import 'connection_test_result.dart';

/// Tests one URL of a not-yet-saved [Instance] and reports whether it is
/// reachable and whether its credentials are valid.
///
/// The URL under test is chosen by forcing [UrlMode]: `forceLocal` tests the
/// LAN URL, `forceExternal` tests the WAN URL. The form calls this once per
/// filled-in URL.
///
/// Key and token services (the *arr family, Seerr, Tautulli, SABnzbd, Glances,
/// Speedtest) are verified by [HealthProbe], whose authed endpoints already
/// return 401/403 on a bad key. The session services log in for real, since
/// that is the only way to check their credentials: Jellyfin and Emby each
/// expose `login()`, and Plex is verified against its token-gated
/// `getLibraries()`. qBittorrent logs in for cookie auth, but an API key is
/// stateless (Authorization: Bearer) and cannot use the login endpoint, so it
/// is verified against an authed endpoint instead.
class ConnectionTester {
  ConnectionTester(this._ref);

  final Ref _ref;

  Future<ConnectionTestResult> test({
    required Instance candidate,
    required UrlMode url,
  }) async {
    final Instance forced = candidate.copyWith(urlMode: url);
    switch (forced.kind) {
      case ServiceKind.qbittorrent:
        return _verify(() async {
          final QbittorrentClient client =
              await _ref.read(qbittorrentClientProvider(forced).future);
          // qBit 5.2+ API keys are stateless (Authorization: Bearer) and cannot
          // use the cookie login endpoint, so an empty-credential login() would
          // always report the key as rejected. Verify it against an authed
          // endpoint instead; a bad key 403s there just the same.
          if (forced.auth is InstanceAuthApiKey) {
            await client.getTransferInfo();
          } else {
            await client.login();
          }
        });
      case ServiceKind.jellyfin:
        return _verify(() async {
          final JellyfinClient client =
              await _ref.read(jellyfinClientProvider(forced).future);
          await client.login();
        });
      case ServiceKind.emby:
        return _verify(() async {
          final EmbyClient client =
              await _ref.read(embyClientProvider(forced).future);
          await client.login();
        });
      case ServiceKind.plex:
        return _verify(() async {
          final PlexApi api = await _ref.read(plexApiProvider(forced).future);
          await api.getLibraries();
        });
      default:
        final HealthProbe probe =
            HealthProbe(dioFactory: _ref.read(dioFactoryProvider));
        return connectionResultFromHealth(await probe.check(forced));
    }
  }

  Future<ConnectionTestResult> _verify(Future<void> Function() action) async {
    try {
      await action();
      return const ConnectionTestResult(
        ConnectionOutcome.connected,
        'Connected',
      );
    } on Object catch (error) {
      return connectionResultFromError(error);
    }
  }
}

final Provider<ConnectionTester> connectionTesterProvider =
    Provider<ConnectionTester>((Ref ref) => ConnectionTester(ref));
