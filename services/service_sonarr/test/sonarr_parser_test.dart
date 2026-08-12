import 'package:flutter_test/flutter_test.dart';
import 'package:service_sonarr/service_sonarr.dart';

void main() {
  group('Sonarr Generated Specs & Models Test', () {
    test('SeriesResource serialization and deserialization', () {
      final json = {
        'id': 10,
        'title': 'Breaking Bad',
        'tvdbId': 81189,
        'monitored': true,
      };

      final model = SeriesResource.fromJson(json);
      expect(model.id, equals(10));
      expect(model.title, equals('Breaking Bad'));
      expect(model.tvdbId, equals(81189));
      expect(model.monitored, equals(true));

      final toJsonResult = model.toJson();
      expect(toJsonResult['id'], equals(10));
      expect(toJsonResult['title'], equals('Breaking Bad'));
    });

    test('SonarrError and Exception parsing', () {
      final errorJson = {
        'message': 'Series not found',
        'description': 'The requested series ID does not exist',
        'status': 404,
      };

      final sonarrError = SonarrError.fromJson(errorJson);
      expect(sonarrError.message, equals('Series not found'));

      final exception = SonarrException(
        sonarrError.message!,
        statusCode: 404,
        error: sonarrError,
      );
      expect(exception.statusCode, equals(404));
      expect(exception.toString(), contains('Series not found'));
    });

    test('SonarrClient initialization', () {
      final client = SonarrClient(
        baseUrl: 'http://localhost:8989',
        apiKey: 'test-sonarr-api-key',
      );

      expect(client.baseUrl, equals('http://localhost:8989'));
      expect(client.dio.options.baseUrl, equals('http://localhost:8989/'));
      expect(client.apiKey, equals('test-sonarr-api-key'));
    });
  });
}
