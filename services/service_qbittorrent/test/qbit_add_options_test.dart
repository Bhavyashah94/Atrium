import 'dart:typed_data';

import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:service_qbittorrent/service_qbittorrent.dart';

/// Captures the outgoing request instead of hitting a server.
class _RecordingAdapter implements HttpClientAdapter {
  RequestOptions? request;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    request = options;
    // Drain the multipart body so FormData finalizes exactly as it would live.
    if (requestStream != null) {
      await requestStream.drain<void>();
    }
    return ResponseBody.fromString('Ok.', 200);
  }

  @override
  void close({bool force = false}) {}
}

Map<String, String> _fields(RequestOptions o) => <String, String>{
      for (final MapEntry<String, String> e in (o.data as FormData).fields)
        e.key: e.value,
    };

void main() {
  late _RecordingAdapter adapter;
  late QbittorrentClient client;

  setUp(() {
    adapter = _RecordingAdapter();
    // An api key skips the cookie login, so the add call is the only request.
    client = QbittorrentClient(
      dio: Dio(BaseOptions(baseUrl: 'https://qbit.example.test/'))
        ..httpClientAdapter = adapter,
      cookies: CookieJar(),
      username: '',
      password: '',
      apiKey: 'qbt_placeholder_not_a_secret',
    );
  });

  group('skip hash check reaches /torrents/add', () {
    test('magnet add sends both parameter spellings when enabled', () async {
      await client.addUrls(
        <String>['magnet:?xt=urn:btih:0123456789abcdef'],
        skipHashCheck: true,
      );

      final Map<String, String> f = _fields(adapter.request!);
      expect(adapter.request!.path, 'api/v2/torrents/add');
      // Released qBittorrent up to 5.2 reads skip_checking; master renamed it.
      expect(f['skip_checking'], 'true');
      expect(f['seedMode'], 'true');
    });

    test('magnet add sends false when left off', () async {
      await client.addUrls(<String>['magnet:?xt=urn:btih:0123456789abcdef']);

      final Map<String, String> f = _fields(adapter.request!);
      expect(f['skip_checking'], 'false');
      expect(f['seedMode'], 'false');
    });

    test('file add carries it too', () async {
      await client.addTorrentFile(
        Uint8List.fromList(<int>[1, 2, 3]),
        filename: 'x.torrent',
        skipHashCheck: true,
      );

      final Map<String, String> f = _fields(adapter.request!);
      expect(adapter.request!.path, 'api/v2/torrents/add');
      expect(f['skip_checking'], 'true');
      expect(f['seedMode'], 'true');
    });

    test('the other add options are untouched by it', () async {
      await client.addUrls(
        <String>['magnet:?xt=urn:btih:0123456789abcdef'],
        paused: true,
        sequential: true,
        skipHashCheck: true,
      );

      final Map<String, String> f = _fields(adapter.request!);
      expect(f['paused'], 'true');
      expect(f['sequentialDownload'], 'true');
      expect(f['skip_checking'], 'true');
    });
  });
}
