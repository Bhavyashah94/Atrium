import 'package:flutter_test/flutter_test.dart';
import 'package:service_tracearr/src/generated/models/health_response.dart';
import 'package:service_tracearr/src/generated/models/history_record.dart';
import 'package:service_tracearr/src/generated/models/history_user.dart';
import 'package:service_tracearr/src/generated/responses/tracearr_error.dart';
import 'package:service_tracearr/src/generated/responses/tracearr_exception.dart';

void main() {
  group('Tracearr Generated Specs & Models Test', () {
    test('HealthResponse serialization and deserialization', () {
      final json = <String, dynamic>{
        'status': 'ok',
        'version': '1.4.22',
        'timestamp': '2024-01-15T12:00:00.000Z',
        'servers': <Map<String, dynamic>>[],
      };

      final model = HealthResponse.fromJson(json);
      expect(model.status, equals('ok'));
      expect(model.version, equals('1.4.22'));

      final toJsonResult = model.toJson();
      expect(toJsonResult['status'], equals('ok'));
      expect(toJsonResult['version'], equals('1.4.22'));
    });

    test('HistoryUser serialization and deserialization with server_user_id',
        () {
      final json = <String, dynamic>{
        'id': 'u100-identity-uuid',
        'server_user_id': 'su200-server-account-uuid',
        'username': 'bhavyashah',
        'thumb_url': '/users/100/thumb.jpg',
        'avatar_url': 'https://example.com/avatar.jpg',
      };

      final model = HistoryUser.fromJson(json);
      expect(model.id, equals('u100-identity-uuid'));
      expect(model.serverUserId, equals('su200-server-account-uuid'));
      expect(model.username, equals('bhavyashah'));
      expect(model.thumbUrl, equals('/users/100/thumb.jpg'));
      expect(model.avatarUrl, equals('https://example.com/avatar.jpg'));

      final toJsonResult = model.toJson();
      expect(toJsonResult['id'], equals('u100-identity-uuid'));
      expect(
        toJsonResult['server_user_id'],
        equals('su200-server-account-uuid'),
      );
      expect(toJsonResult['username'], equals('bhavyashah'));
    });

    test('HistoryRecord deserializes string-encoded integer fields safely', () {
      final json = <String, dynamic>{
        'id': 'f40031e0-ea9e-4183-9037-b3c5e499843d',
        'media_title': 'Welcome Home',
        'duration_ms': 1332314,
        'progress_ms': '1332330',
        'total_duration_ms': '1420045',
        'percent_complete': 93.8,
      };

      final model = HistoryRecord.fromJson(json);
      expect(model.mediaTitle, equals('Welcome Home'));
      expect(model.durationMs, equals(1332314));
      expect(model.progressMs, equals(1332330));
      expect(model.totalDurationMs, equals(1420045));
      expect(model.percentComplete, equals(93.8));
    });

    test('TracearrError and Exception parsing', () {
      final errorJson = <String, dynamic>{
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
