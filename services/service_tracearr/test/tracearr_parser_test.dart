import 'package:flutter_test/flutter_test.dart';
import 'package:service_tracearr/src/generated/models/health_response.dart';
import 'package:service_tracearr/src/generated/responses/tracearr_error.dart';
import 'package:service_tracearr/src/generated/responses/tracearr_exception.dart';

void main() {
  group('Tracearr Generated Specs & Models Test', () {
    test('HealthResponse serialization and deserialization', () {
      final json = {
        'status': 'ok',
        'version': '1.4.22',
        'timestamp': '2024-01-15T12:00:00.000Z',
        'servers': [],
      };

      final model = HealthResponse.fromJson(json);
      expect(model.status, equals('ok'));
      expect(model.version, equals('1.4.22'));

      final toJsonResult = model.toJson();
      expect(toJsonResult['status'], equals('ok'));
      expect(toJsonResult['version'], equals('1.4.22'));
    });

    test('TracearrError and Exception parsing', () {
      final errorJson = {
        'message': 'Unauthorized token',
        'description': 'Token expired or invalid',
      };

      final error = TracearrError.fromJson(errorJson);
      expect(error.message, equals('Unauthorized token'));

      final exception = TracearrException(
        error.message!,
        statusCode: 401,
        error: error,
      );
      expect(exception.statusCode, equals(401));
      expect(exception.toString(), contains('Unauthorized token'));
    });
  });
}
