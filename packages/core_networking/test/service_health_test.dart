import 'package:core_models/core_models.dart';
import 'package:core_networking/core_networking.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('proxy interception', _interceptionTests);
  group('Navidrome Subsonic health', _navidromeTests);
  group('Unraid GraphQL health', () {
    test('a query that actually ran is online', () {
      expect(
        interpretServiceHealthResponse(
          ServiceKind.unraid,
          200,
          <String, dynamic>{
            'data': <String, dynamic>{'__typename': 'Query'},
          },
        ),
        Health.ok,
      );
    });

    test('a refused key is a warning even though it answers 200', () {
      // The reason this case exists: GraphQL reports auth failures in the
      // body, so status alone would call a bad key healthy.
      expect(
        interpretServiceHealthResponse(
          ServiceKind.unraid,
          200,
          <String, dynamic>{
            'errors': <dynamic>[
              <String, dynamic>{'message': 'Unauthorized'},
            ],
          },
        ),
        Health.warning,
      );
    });

    test('a proxy or web page answering 200 is a warning, not online', () {
      for (final Object? body in <Object?>[
        '<html>Sign in</html>',
        <String, dynamic>{'data': <String, dynamic>{}},
        null,
      ]) {
        expect(
          interpretServiceHealthResponse(ServiceKind.unraid, 200, body),
          Health.warning,
          reason: 'body: $body',
        );
      }
    });
  });

  group('Speedtest Tracker authenticated health', () {
    test('recognizable results JSON is online', () {
      expect(
        interpretServiceHealthResponse(
          ServiceKind.speedtestTracker,
          200,
          <String, dynamic>{'data': <dynamic>[], 'meta': <String, dynamic>{}},
        ),
        Health.ok,
      );
    });

    test('HTML and malformed successful responses are warnings', () {
      for (final Object? body in <Object?>[
        '<html>Sign in</html>',
        <String, dynamic>{'message': 'Login required'},
        null,
      ]) {
        expect(
          interpretServiceHealthResponse(
            ServiceKind.speedtestTracker,
            200,
            body,
          ),
          Health.warning,
        );
      }
    });

    test('reachable API errors and redirects are warnings', () {
      for (final int status in <int>[301, 401, 403, 404, 422, 503]) {
        expect(
          interpretServiceHealthResponse(
            ServiceKind.speedtestTracker,
            status,
            'potentially sensitive response body',
          ),
          Health.warning,
        );
      }
    });
  });
}

// ---

/// A forward-auth proxy answering instead of the service.
///
/// Reproduced against real Authelia behind nginx: an unauthenticated probe is
/// redirected to the login portal, the client follows it, and the portal
/// answers 200 with text/html. Every health endpoint here speaks JSON or
/// XML-RPC, so a page is proof the service never saw the request.
void _interceptionTests() {
  const String html = 'text/html; charset=utf-8';
  const String json = 'application/json';

  test('a 200 page is not a healthy service', () {
    expect(
      interpretServiceHealthResponse(
        ServiceKind.sonarr, 200, '<!--SPDX--><!DOCTYPE html>',
        contentType: html,
      ),
      Health.warning,
    );
  });

  test('it applies to the public-endpoint services too', () {
    expect(
      interpretServiceHealthResponse(
        ServiceKind.jellyfin, 200, '<html>', contentType: html,
      ),
      Health.warning,
    );
  });

  test('and to the ones judged only on reachability', () {
    // qBittorrent is called healthy on any answer at all, which would happily
    // accept a login portal.
    expect(
      interpretServiceHealthResponse(
        ServiceKind.qbittorrent, 200, '<html>', contentType: html,
      ),
      Health.warning,
    );
  });

  test('a real json answer is still healthy', () {
    expect(
      interpretServiceHealthResponse(
        ServiceKind.sonarr, 200, <String, dynamic>{'version': '4.0'},
        contentType: json,
      ),
      Health.ok,
    );
  });

  test('transmission answering 409 with a page is left alone', () {
    // Its own conflict response is markup and means the daemon is up. Only
    // 2xx is treated as an interception for exactly this reason.
    expect(
      interpretServiceHealthResponse(
        ServiceKind.transmission, 409, '<h1>409: Conflict</h1>',
        contentType: html,
      ),
      Health.ok,
    );
  });

  test('rtorrent answering 502 with a page is left alone', () {
    expect(
      interpretServiceHealthResponse(
        ServiceKind.rtorrent, 502, '<html>502</html>', contentType: html,
      ),
      Health.warning,
    );
  });

  test('rtorrent xml-rpc is not mistaken for a page', () {
    // XML-RPC opens with a tag too, which is why this reads the content type
    // rather than sniffing the body.
    expect(
      interpretServiceHealthResponse(
        ServiceKind.rtorrent, 200,
        '<?xml version="1.0"?><methodResponse></methodResponse>',
        contentType: 'text/xml',
      ),
      Health.ok,
    );
  });

  test('no content type at all changes nothing', () {
    expect(
      interpretServiceHealthResponse(ServiceKind.sonarr, 200, <String, dynamic>{}),
      Health.ok,
    );
  });
}

/// Subsonic reports every error inside a 200, so the envelope is the only
/// thing that separates a working server from a rejected password.
///
/// The bodies below are real responses from Navidrome 0.64.0, captured while
/// reviewing the service: the app used to call all three of them Online.
void _navidromeTests() {
  Map<String, dynamic> envelope(Map<String, dynamic> extra) =>
      <String, dynamic>{
        'subsonic-response': <String, dynamic>{
          'version': '1.16.1',
          'type': 'navidrome',
          'serverVersion': '0.64.0',
          'openSubsonic': true,
          ...extra,
        },
      };

  test('a signed request that succeeded is online', () {
    expect(
      interpretServiceHealthResponse(
        ServiceKind.navidrome,
        200,
        envelope(<String, dynamic>{'status': 'ok'}),
      ),
      Health.ok,
    );
  });

  test('a rejected password is a warning, not online', () {
    expect(
      interpretServiceHealthResponse(
        ServiceKind.navidrome,
        200,
        envelope(<String, dynamic>{
          'status': 'failed',
          'error': <String, dynamic>{
            'code': 40,
            'message': 'Wrong username or password',
          },
        }),
      ),
      Health.warning,
    );
  });

  test('an unauthenticated probe is a warning, not online', () {
    // What the probe itself used to send before the interceptor learned to
    // sign Subsonic requests.
    expect(
      interpretServiceHealthResponse(
        ServiceKind.navidrome,
        200,
        envelope(<String, dynamic>{
          'status': 'failed',
          'error': <String, dynamic>{
            'code': 10,
            'message': "missing parameter: 'u'",
          },
        }),
      ),
      Health.warning,
    );
  });

  test('some other server answering json on that url is a warning', () {
    for (final Object? body in <Object?>[
      <String, dynamic>{'hello': 'world'},
      <String, dynamic>{'subsonic-response': 'not an object'},
      'plain text',
      null,
    ]) {
      expect(
        interpretServiceHealthResponse(ServiceKind.navidrome, 200, body),
        Health.warning,
        reason: 'body $body should not read as a healthy Navidrome',
      );
    }
  });

  test('an unreachable host is still offline', () {
    expect(
      interpretServiceHealthResponse(ServiceKind.navidrome, 0, null),
      Health.error,
    );
  });
}
