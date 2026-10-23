import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:service_cleanuparr/service_cleanuparr.dart';

void main() {
  group('CleanuparrStatus.fromJson', () {
    test('parses status response correctly', () {
      final status = CleanuparrStatus.fromJson(<String, dynamic>{
        'application': <String, dynamic>{
          'version': '2.4.0',
          'appName': 'Cleanuparr',
          'branch': 'master',
          'memoryUsageMB': 142.5,
          'startTime': '2026-10-23T10:00:00Z',
        },
        'mediaManagers': <dynamic>[
          <String, dynamic>{
            'name': 'Sonarr',
            'type': 'Sonarr',
            'enabled': true,
            'health': 'Healthy',
          },
        ],
        'downloadClients': <dynamic>[
          <String, dynamic>{
            'name': 'qBittorrent',
            'type': 'qBittorrent',
            'enabled': true,
            'health': 'Healthy',
          },
        ],
      });

      expect(status.version, '2.4.0');
      expect(status.appName, 'Cleanuparr');
      expect(status.branch, 'master');
      expect(status.memoryUsageMB, 142.5);
      expect(status.mediaManagers.length, 1);
      expect(status.mediaManagers.first.name, 'Sonarr');
      expect(status.downloadClients.length, 1);
      expect(status.downloadClients.first.name, 'qBittorrent');
    });

    test('handles empty or fallback payloads safely', () {
      final status = CleanuparrStatus.fromJson(<String, dynamic>{});
      expect(status.version, 'Unknown');
      expect(status.appName, 'Cleanuparr');
      expect(status.mediaManagers, isEmpty);
      expect(status.downloadClients, isEmpty);
    });
  });

  group('CleanuparrStats.fromJson', () {
    test('parses operational stats correctly', () {
      final stats = CleanuparrStats.fromJson(<String, dynamic>{
        'events': <String, dynamic>{
          'total': 42,
          'warning': 8,
          'error': 4,
        },
        'strikes': <String, dynamic>{
          'totalIssued': 15,
          'totalRecovered': 6,
          'active': 2,
          'byType': <String, dynamic>{
            'StalledStrike': 8,
            'FailedImportStrike': 4,
          },
        },
        'removals': <String, dynamic>{
          'total': 5,
          'allFilesBlocked': 2,
          'atLeastOneFileBlocked': 1,
        },
        'cleaned': <String, dynamic>{
          'total': 12,
        },
        'searches': <String, dynamic>{
          'triggers': 9,
          'grabbed': 4,
        },
      },
      hours: 72,
    );

    expect(stats.hours, 72);
      expect(stats.totalEvents, 42);
      expect(stats.eventsWarning, 8);
      expect(stats.eventsError, 4);
      expect(stats.strikesIssued, 15);
      expect(stats.strikesRecovered, 6);
      expect(stats.activeStrikes, 2);
      expect(stats.malwareBlocked, 3); // 2 + 1
      expect(stats.totalCleaned, 12);
      expect(stats.seekerTriggers, 9);
      expect(stats.seekerGrabbed, 4);
      expect(stats.strikesByType['StalledStrike'], 8);
    });
  });

  group('CleanuparrStrikeItem.fromJson', () {
    test('parses strike item and nested strike details', () {
      final item = CleanuparrStrikeItem.fromJson(<String, dynamic>{
        'downloadItemId': 'hash123',
        'title': 'Test.Movie.2026.1080p',
        'downloadClientName': 'qBittorrent',
        'strikeCount': 2,
        'maxStrikes': 3,
        'strikes': <dynamic>[
          <String, dynamic>{
            'type': 'StalledStrike',
            'reason': 'Stalled for > 15m',
            'createdAt': '2026-10-23T10:15:00Z',
          },
        ],
      });

      expect(item.id, 'hash123');
      expect(item.title, 'Test.Movie.2026.1080p');
      expect(item.downloadClientName, 'qBittorrent');
      expect(item.strikeCount, 2);
      expect(item.maxStrikes, 3);
      expect(item.isMaxed, isFalse);
      expect(item.strikes.length, 1);
      expect(item.strikes.first.type, 'StalledStrike');
    });
  });

  group('CleanuparrEvent.fromJson', () {
    test('parses malware event correctly', () {
      final event = CleanuparrEvent.fromJson(<String, dynamic>{
        'id': 'ev-1',
        'timestamp': '2026-10-23T10:14:00Z',
        'eventType': 'MalwareBlocked',
        'severity': 'Critical',
        'message': 'Blocked release with malicious payload',
        'downloadItemTitle': 'Bad.File.exe',
      });

      expect(event.id, 'ev-1');
      expect(event.eventType, 'MalwareBlocked');
      expect(event.severity, 'Critical');
      expect(event.isMalware, isTrue);
      expect(event.isStrike, isFalse);
    });
  });

  group('CleanuparrJob.fromJson', () {
    test('parses job correctly and formats display name', () {
      final job = CleanuparrJob.fromJson(<String, dynamic>{
        'jobType': 'MalwareBlocker',
        'status': 'Idle',
        'interval': '00:05:00',
      });

      expect(job.jobType, 'MalwareBlocker');
      expect(job.displayName, 'Malware Blocker');
      expect(job.status, 'Idle');
      expect(job.isRunning, isFalse);
    });
  });

  group('CleanuparrApi Client', () {
    test('getStatus calls api/status', () async {
      final dio = Dio();
      dio.httpClientAdapter = _FakeAdapter(
        handler: (options) {
          expect(options.path, 'api/status');
          return ResponseBody.fromString(
            '{"application": {"version": "2.4.0", "appName": "Cleanuparr"}}',
            200,
            headers: <String, List<String>>{
              Headers.contentTypeHeader: <String>[Headers.jsonContentType],
            },
          );
        },
      );

      final api = CleanuparrApi(dio);
      final status = await api.getStatus();
      expect(status.version, '2.4.0');
    });

    test('getStats calls api/v2/stats with hours query param', () async {
      final dio = Dio();
      dio.httpClientAdapter = _FakeAdapter(
        handler: (options) {
          expect(options.path, 'api/v2/stats');
          expect(options.queryParameters['hours'], 72);
          return ResponseBody.fromString(
            '{"events": {"total": 10}, "strikes": {"active": 1}}',
            200,
            headers: <String, List<String>>{
              Headers.contentTypeHeader: <String>[Headers.jsonContentType],
            },
          );
        },
      );

      final api = CleanuparrApi(dio);
      final stats = await api.getStats(hours: 72);
      expect(stats.totalEvents, 10);
      expect(stats.activeStrikes, 1);
    });

    test('deleteStrike calls DELETE api/strikes/{id}', () async {
      final dio = Dio();
      dio.httpClientAdapter = _FakeAdapter(
        handler: (options) {
          expect(options.method, 'DELETE');
          expect(options.path, 'api/strikes/item-123');
          return ResponseBody.fromString('', 204);
        },
      );

      final api = CleanuparrApi(dio);
      await expectLater(api.deleteStrike('item-123'), completes);
    });

    test('triggerJob calls POST api/jobs/{jobType}/trigger', () async {
      final dio = Dio();
      dio.httpClientAdapter = _FakeAdapter(
        handler: (options) {
          expect(options.method, 'POST');
          expect(options.path, 'api/jobs/QueueCleaner/trigger');
          return ResponseBody.fromString('', 200);
        },
      );

      final api = CleanuparrApi(dio);
      await expectLater(api.triggerJob('QueueCleaner'), completes);
    });
  });
}

class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter({required this.handler});

  final ResponseBody Function(RequestOptions options) handler;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return handler(options);
  }

  @override
  void close({bool force = false}) {}
}
