import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:service_cleanuparr/service_cleanuparr.dart';

/// Live HTTP test for [CleanuparrApi] using an active in-memory HTTP daemon server.
///
/// Proves that [CleanuparrApi] reliably conducts real HTTP calls over TCP, correctly
/// formats URLs, encodes query parameters, and defensive deserialization parses
/// actual wire responses.
void main() {
  late HttpServer server;
  late CleanuparrApi api;
  late String serverUrl;

  const String expectedApiKey = 'test-cleanuparr-key-999';

  setUpAll(() async {
    // Spin up a live HTTP server on a random loopback port
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    serverUrl = 'http://${server.address.address}:${server.port}/';

    final Dio dio = Dio(
      BaseOptions(
        baseUrl: serverUrl,
        headers: <String, dynamic>{
          'X-Api-Key': expectedApiKey,
        },
      ),
    );
    api = CleanuparrApi(dio);

    server.listen((HttpRequest request) async {
      final String path = request.uri.path;
      final String method = request.method;

      // Verify that the API Key header is present
      final String? providedKey = request.headers.value('x-api-key');
      if (providedKey != expectedApiKey) {
        request.response.statusCode = HttpStatus.unauthorized;
        request.response.write(jsonEncode(<String, dynamic>{'error': 'Unauthorized'}));
        await request.response.close();
        return;
      }

      request.response.headers.contentType = ContentType.json;

      if (path == '/api/status' && method == 'GET') {
        request.response.write(
          jsonEncode(<String, dynamic>{
            'version': '2.4.0',
            'appName': 'Cleanuparr',
            'branch': 'master',
            'memoryUsage': 134217728, // 128 MB
            'uptime': '3d 14h 22m',
            'mediaManagers': <Map<String, dynamic>>[
              <String, dynamic>{'name': 'Sonarr Main', 'type': 'Sonarr', 'enabled': true},
              <String, dynamic>{'name': 'Radarr 4K', 'type': 'Radarr', 'enabled': true},
            ],
            'downloadClients': <Map<String, dynamic>>[
              <String, dynamic>{'name': 'qBittorrent Seeder', 'type': 'qBittorrent', 'enabled': true},
            ],
          }),
        );
      } else if (path == '/api/v2/stats' && method == 'GET') {
        final int hours = int.tryParse(request.uri.queryParameters['hours'] ?? '168') ?? 168;
        request.response.write(
          jsonEncode(<String, dynamic>{
            'hours': hours,
            'totalEvents': 52,
            'eventsWarning': 11,
            'eventsError': 3,
            'strikesIssued': 19,
            'strikesRecovered': 7,
            'activeStrikes': 4,
            'malwareBlocked': 8,
            'totalRemovals': 12,
            'totalCleaned': 24,
            'seekerTriggers': 15,
            'seekerGrabbed': 6,
          }),
        );
      } else if (path == '/api/strikes' && method == 'GET') {
        final String? search = request.uri.queryParameters['search'];
        final List<Map<String, dynamic>> items = <Map<String, dynamic>>[
          <String, dynamic>{
            'id': 'strike-item-1',
            'title': 'Gladiator.II.2024.1080p.AMZN.WEB-DL',
            'downloadClientName': 'qBittorrent Seeder',
            'strikeCount': 2,
            'maxStrikes': 3,
            'strikes': <Map<String, dynamic>>[
              <String, dynamic>{
                'type': 'StalledStrike',
                'reason': 'Download stalled at 42.1% for > 15m with 0 B/s',
              },
            ],
          },
          <String, dynamic>{
            'id': 'strike-item-2',
            'title': 'Slow.Horses.S04E06.1080p',
            'downloadClientName': 'qBittorrent Seeder',
            'strikeCount': 3,
            'maxStrikes': 3,
            'strikes': <Map<String, dynamic>>[
              <String, dynamic>{
                'type': 'FailedImportStrike',
                'reason': 'Import destination disk quota exhausted',
              },
            ],
          },
        ];

        final List<Map<String, dynamic>> filtered = search != null && search.isNotEmpty
            ? items.where((it) => (it['title'] as String).toLowerCase().contains(search.toLowerCase())).toList()
            : items;

        request.response.write(jsonEncode(<String, dynamic>{'items': filtered}));
      } else if (path.startsWith('/api/strikes/') && method == 'DELETE') {
        final String strikeId = path.substring('/api/strikes/'.length);
        if (strikeId.isNotEmpty) {
          request.response.statusCode = HttpStatus.noContent;
        } else {
          request.response.statusCode = HttpStatus.badRequest;
        }
      } else if (path == '/api/events' && method == 'GET') {
        request.response.write(
          jsonEncode(<String, dynamic>{
            'items': <Map<String, dynamic>>[
              <String, dynamic>{
                'id': 'ev-live-1',
                'timestamp': '2026-10-23T11:00:00Z',
                'eventType': 'MalwareBlocked',
                'severity': 'Critical',
                'message': 'Blocked executable disguised payload inside archive',
                'downloadItemTitle': 'Photoshop.2025.Crack.Payload.exe',
                'downloadClientName': 'qBittorrent Seeder',
                'hash': 'fedcba9876543210',
                'deleteReason': 'MalwarePayloadSignature',
              },
              <String, dynamic>{
                'id': 'ev-live-2',
                'timestamp': '2026-10-23T10:30:00Z',
                'eventType': 'StalledStrike',
                'severity': 'Warning',
                'message': 'Download stalled exceeding 15m idle threshold',
                'downloadItemTitle': 'Gladiator.II.2024.1080p',
                'downloadClientName': 'qBittorrent Seeder',
                'hash': '0123456789abcdef',
              },
            ],
          }),
        );
      } else if (path == '/api/jobs' && method == 'GET') {
        request.response.write(
          jsonEncode(<String, dynamic>{
            'jobs': <Map<String, dynamic>>[
              <String, dynamic>{
                'jobType': 'MalwareBlocker',
                'displayName': 'Malware Blocker',
                'status': 'Idle',
                'interval': 'Every 5m',
              },
              <String, dynamic>{
                'jobType': 'QueueCleaner',
                'displayName': 'Queue Cleaner',
                'status': 'Idle',
                'interval': 'Every 15m',
              },
            ],
          }),
        );
      } else if (path.startsWith('/api/jobs/') && path.endsWith('/trigger') && method == 'POST') {
        request.response.statusCode = HttpStatus.accepted;
        request.response.write(jsonEncode(<String, dynamic>{'status': 'JobQueued'}));
      } else {
        request.response.statusCode = HttpStatus.notFound;
        request.response.write(jsonEncode(<String, dynamic>{'error': 'Not Found'}));
      }

      await request.response.close();
    });
  });

  tearDownAll(() async {
    await server.close(force: true);
  });

  test('Live HTTP GET /api/status returns valid CleanuparrStatus', () async {
    final CleanuparrStatus status = await api.getStatus();
    expect(status.version, equals('2.4.0'));
    expect(status.appName, equals('Cleanuparr'));
    expect(status.memoryUsageMB, equals(128.0));
    expect(status.mediaManagers.length, equals(2));
    expect(status.mediaManagers.first.name, equals('Sonarr Main'));
    expect(status.downloadClients.length, equals(1));
    expect(status.downloadClients.first.name, equals('qBittorrent Seeder'));
  });

  test('Live HTTP GET /api/v2/stats with timeframe query params returns CleanuparrStats', () async {
    final CleanuparrStats stats = await api.getStats();
    expect(stats.hours, equals(168));
    expect(stats.totalEvents, equals(52));
    expect(stats.malwareBlocked, equals(8));
    expect(stats.activeStrikes, equals(4));
    expect(stats.totalCleaned, equals(24));
  });

  test('Live HTTP GET /api/strikes returns parsed strikes ledger and handles search filter', () async {
    final List<CleanuparrStrikeItem> strikes = await api.getStrikes();
    expect(strikes.length, equals(2));
    expect(strikes.first.title, contains('Gladiator'));
    expect(strikes.first.strikeCount, equals(2));
    expect(strikes.first.maxStrikes, equals(3));
    expect(strikes.first.strikes.first.type, equals('StalledStrike'));

    final List<CleanuparrStrikeItem> filtered = await api.getStrikes(search: 'Slow');
    expect(filtered.length, equals(1));
    expect(filtered.first.title, contains('Slow.Horses'));
  });

  test('Live HTTP DELETE /api/strikes/{id} successfully resets strikes', () async {
    expect(api.deleteStrike('strike-item-1'), completes);
  });

  test('Live HTTP GET /api/events parses event logs and severities', () async {
    final List<CleanuparrEvent> events = await api.getEvents();
    expect(events.length, equals(2));
    expect(events.first.eventType, equals('MalwareBlocked'));
    expect(events.first.severity, equals('Critical'));
    expect(events.first.downloadItemTitle, contains('Photoshop'));
    expect(events.first.deleteReason, equals('MalwarePayloadSignature'));
  });

  test('Live HTTP GET /api/jobs and POST /api/jobs/{type}/trigger handles on-demand run', () async {
    final List<CleanuparrJob> jobs = await api.getJobs();
    expect(jobs.length, equals(2));
    expect(jobs.first.displayName, equals('Malware Blocker'));
    expect(jobs.first.jobType, equals('MalwareBlocker'));

    expect(api.triggerJob('MalwareBlocker'), completes);
  });
}
