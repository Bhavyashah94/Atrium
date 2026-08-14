import 'package:flutter_test/flutter_test.dart';
import 'package:service_tracearr/src/generated/models/violation.dart';
import 'package:service_tracearr/src/mappers/tracearr_violation_mapper.dart';

void main() {
  group('TracearrViolationMapper', () {
    test('maps Violation DTO with polymorphic rule, user, and data maps', () {
      const dto = Violation(
        id: 'viol_1',
        serverId: 'srv_1',
        serverName: 'Main Plex',
        severity: 'critical',
        rule: <String, dynamic>{'name': 'Concurrent Stream Limit'},
        user: <String, dynamic>{
          'id': 'user_uuid_1',
          'username': 'Bhavyashah',
        },
        data: <String, dynamic>{'description': 'Exceeded 3 concurrent streams'},
        acknowledged: false,
        createdAt: '2026-01-01T15:30:00.000Z',
      );

      final domain = TracearrViolationMapper.fromDto(dto);

      expect(domain.id, equals('viol_1'));
      expect(domain.serverId, equals('srv_1'));
      expect(domain.serverName, equals('Main Plex'));
      expect(domain.severity, equals('critical'));
      expect(domain.rule, equals('Concurrent Stream Limit'));
      expect(domain.username, equals('Bhavyashah'));
      expect(domain.userId, equals('user_uuid_1'));
      expect(domain.description, equals('Exceeded 3 concurrent streams'));
      expect(domain.acknowledged, isFalse);
      expect(
        domain.createdAt,
        equals(DateTime.parse('2026-01-01T15:30:00.000Z')),
      );
    });

    test('handles String-based polymorphic fields and defaults', () {
      const dto = Violation(
        id: 'viol_2',
        rule: 'Rate Limit',
        user: 'Anonymous',
        data: 'Too many login attempts',
        acknowledged: true,
      );

      final domain = TracearrViolationMapper.fromDto(dto);

      expect(domain.id, equals('viol_2'));
      expect(domain.severity, equals('info'));
      expect(domain.rule, equals('Rate Limit'));
      expect(domain.username, equals('Anonymous'));
      expect(domain.userId, isNull);
      expect(domain.description, equals('Too many login attempts'));
      expect(domain.acknowledged, isTrue);
    });
  });
}
