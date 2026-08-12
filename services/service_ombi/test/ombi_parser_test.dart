import 'package:flutter_test/flutter_test.dart';
import 'package:service_ombi/service_ombi.dart';

void main() {
  group('Ombi Generated Specs & Models Test', () {
    test('CalendarViewModel serialization and deserialization', () {
      final json = {
        'title': 'Inception',
        'start': '2010-07-16T00:00:00Z',
        'backgroundColor': '#000000',
      };

      final model = CalendarViewModel.fromJson(json);
      expect(model.title, equals('Inception'));
      expect(model.start, equals('2010-07-16T00:00:00Z'));

      final toJsonResult = model.toJson();
      expect(toJsonResult['title'], equals('Inception'));
      expect(toJsonResult['backgroundColor'], equals('#000000'));
    });

    test('OmbiError and Exception parsing', () {
      final errorJson = {
        'message': 'Invalid movie ID specified.',
        'description': 'Bad Request',
      };

      final ombiError = OmbiError.fromJson(errorJson);
      expect(ombiError.message, equals('Invalid movie ID specified.'));
      expect(ombiError.description, equals('Bad Request'));

      final exception = OmbiException(
        ombiError.message!,
        statusCode: 400,
        error: ombiError,
      );
      expect(exception.statusCode, equals(400));
      expect(exception.toString(), contains('Invalid movie ID specified.'));
    });

    test('Enum serialization', () {
      expect(ErrorCode.alreadyRequested.name, equals('alreadyRequested'));
    });

    test('OmbiClient initialization', () {
      final client = OmbiClient(
        baseUrl: 'https://ombi.example.com',
        apiKey: 'test-api-key-123',
      );

      expect(client.baseUrl, equals('https://ombi.example.com'));
      expect(client.dio.options.baseUrl, equals('https://ombi.example.com/'));
      expect(client.apiKey, equals('test-api-key-123'));
    });
  });
}
