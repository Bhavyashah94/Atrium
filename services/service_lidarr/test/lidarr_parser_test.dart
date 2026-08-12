import 'package:flutter_test/flutter_test.dart';
import 'package:service_lidarr/service_lidarr.dart';

void main() {
  group('Lidarr Generated Specs & Models Test', () {
    test('ArtistResource serialization and deserialization', () {
      final json = {
        'id': 42,
        'artistName': 'Daft Punk',
        'foreignArtistId': 'a70445a7-2d5d-4775-b198-88ed3e3692ea',
        'monitored': true,
      };

      final model = ArtistResource.fromJson(json);
      expect(model.id, equals(42));
      expect(model.artistName, equals('Daft Punk'));
      expect(model.monitored, equals(true));

      final toJsonResult = model.toJson();
      expect(toJsonResult['id'], equals(42));
      expect(toJsonResult['artistName'], equals('Daft Punk'));
    });

    test('LidarrError and Exception parsing', () {
      final errorJson = {
        'message': 'Artist not found',
        'description': 'The requested artist ID does not exist',
        'status': 404,
      };

      final lidarrError = LidarrError.fromJson(errorJson);
      expect(lidarrError.message, equals('Artist not found'));

      final exception = LidarrException(
        lidarrError.message!,
        statusCode: 404,
        error: lidarrError,
      );
      expect(exception.statusCode, equals(404));
      expect(exception.toString(), contains('Artist not found'));
    });

    test('LidarrClient initialization', () {
      final client = LidarrClient(
        baseUrl: 'http://localhost:8686',
        apiKey: 'test-lidarr-api-key',
      );

      expect(client.baseUrl, equals('http://localhost:8686'));
      expect(client.dio.options.baseUrl, equals('http://localhost:8686/'));
      expect(client.apiKey, equals('test-lidarr-api-key'));
    });
  });
}
