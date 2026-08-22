import 'package:flutter_test/flutter_test.dart';
import 'package:service_lidarr/service_lidarr.dart';

void main() {
  group('Lidarr Generated Specs & Models Test', () {
    test('ArtistResource serialization and deserialization with metadata', () {
      final json = {
        'id': 42,
        'artistName': 'Daft Punk',
        'foreignArtistId': 'a70445a7-2d5d-4775-b198-88ed3e3692ea',
        'monitored': true,
        'status': 'continuing',
        'qualityProfileId': 1,
        'genres': ['Electronic', 'House'],
      };

      final model = ArtistResource.fromJson(json);
      expect(model.id, equals(42));
      expect(model.artistName, equals('Daft Punk'));
      expect(model.monitored, equals(true));
      expect(model.status, equals(ArtistStatusType.continuing));
      expect(model.qualityProfileId, equals(1));
      expect(model.genres, contains('Electronic'));

      final toJsonResult = model.toJson();
      expect(toJsonResult['id'], equals(42));
      expect(toJsonResult['artistName'], equals('Daft Punk'));
      expect(toJsonResult['status'], equals('continuing'));
    });

    test('AlbumResource nested models and statistics roundtrip', () {
      final json = {
        'id': 101,
        'title': 'Discovery',
        'artistId': 42,
        'albumType': 'Studio',
        'duration': 3654,
        'statistics': {
          'trackFileCount': 14,
          'totalTrackCount': 14,
          'sizeOnDisk': 450000000,
          'percentOfTracks': 100.0,
        },
      };

      final album = AlbumResource.fromJson(json);
      expect(album.id, equals(101));
      expect(album.title, equals('Discovery'));
      expect(album.artistId, equals(42));
      expect(album.statistics?.trackFileCount, equals(14));
      expect(album.statistics?.percentOfTracks, equals(100.0));

      final albumJson = album.toJson();
      expect(albumJson['title'], equals('Discovery'));
      expect(album.statistics?.trackFileCount, equals(14));
    });

    test(
        'HistoryResource with typed additionalProperties map and nullable values',
        () {
      final json = {
        'id': 999,
        'sourceTitle': 'Daft.Punk.Discovery.FLAC',
        'eventType': 'grabbed',
        'date': '2026-08-14T20:00:00Z',
        'data': {
          'indexer': 'Prowlarr Tracker',
          'downloadClient': 'qBittorrent',
          'guid': 'release-guid-1234',
          'droppedPath': null,
          'releaseGroup': null,
        },
      };

      final history = HistoryResource.fromJson(json);
      expect(history.id, equals(999));
      expect(history.sourceTitle, equals('Daft.Punk.Discovery.FLAC'));
      expect(history.eventType, equals(EntityHistoryEventType.grabbed));
      expect(history.data, isA<Map<String, String?>>());
      expect(history.data?['indexer'], equals('Prowlarr Tracker'));
      expect(history.data?['downloadClient'], equals('qBittorrent'));
      expect(history.data?['droppedPath'], isNull);
      expect(history.data?['releaseGroup'], isNull);

      final historyJson = history.toJson();
      final dataMap = historyJson['data'] as Map<String, dynamic>?;
      expect(dataMap?['indexer'], equals('Prowlarr Tracker'));
      expect(dataMap?['droppedPath'], isNull);
    });

    test('LidarrError parses ASP.NET ValidationProblemDetails Map', () {
      final aspNetError = {
        'type': 'https://tools.ietf.org/html/rfc7231#section-6.5.1',
        'title': 'One or more validation errors occurred.',
        'status': 400,
        'traceId': '00-987654321',
        'errors': {
          'RootFolderPath': ['Path does not exist', 'Folder is not writable'],
          'ArtistName': ['Artist name cannot be blank'],
        },
      };

      final error = LidarrError.fromJson(aspNetError);
      expect(error.message, contains('RootFolderPath: Path does not exist'));
      expect(error.errors.length, equals(3));
      expect(error.errors, contains('RootFolderPath: Path does not exist'));
      expect(error.errors, contains('RootFolderPath: Folder is not writable'));
      expect(error.errors, contains('ArtistName: Artist name cannot be blank'));
    });

    test('LidarrError parses Lidarr FluentValidation List of objects', () {
      final fluentValidationList = [
        {
          'propertyName': 'ForeignArtistId',
          'errorMessage': 'This artist has already been added.',
          'attemptedValue': '20244d07-534f-4eff-b4d4-930878889970',
          'severity': 'error',
          'errorCode': 'ArtistExistsValidator',
        },
        {
          'propertyName': 'RootFolderPath',
          'errorMessage': 'Path is not configured.',
          'severity': 'error',
        }
      ];

      final error = LidarrError.fromJson(fluentValidationList);
      expect(error.message, equals('This artist has already been added.'));
      expect(error.errors.length, equals(2));
      expect(error.errors, contains('This artist has already been added.'));
      expect(error.errors, contains('Path is not configured.'));
    });

    test('LidarrError parses simple error map with message and description',
        () {
      final errorJson = {
        'message': 'Artist not found',
        'description': 'The requested artist ID does not exist',
        'status': 404,
      };

      final lidarrError = LidarrError.fromJson(errorJson);
      expect(
        lidarrError.description,
        equals('The requested artist ID does not exist'),
      );

      final exception = LidarrException(
        lidarrError.message!,
        statusCode: 404,
        error: lidarrError,
      );
      expect(exception.statusCode, equals(404));
      expect(exception.toString(), contains('Artist not found'));
    });

    test('LidarrError parses plain string and null payloads safely', () {
      final stringError = LidarrError.fromJson('Bad Gateway 502');
      expect(stringError.message, equals('Bad Gateway 502'));

      final nullError = LidarrError.fromJson(null);
      expect(nullError.message, isNull);
      expect(nullError.errors, isEmpty);
    });
  });
}
