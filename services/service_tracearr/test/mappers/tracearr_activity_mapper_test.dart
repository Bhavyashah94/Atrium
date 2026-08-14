import 'package:flutter_test/flutter_test.dart';
import 'package:service_tracearr/src/generated/models/activity_response.dart';
import 'package:service_tracearr/src/mappers/tracearr_activity_mapper.dart';

void main() {
  group('TracearrActivityMapper', () {
    test('maps activity trends with time buckets and range', () {
      const response = ActivityResponse(
        period: 'week',
        range: {
          'start': '2026-08-07T00:00:00Z',
          'end': '2026-08-14T00:00:00Z',
        },
        plays: [
          {
            'date': '2026-08-07T00:00:00Z',
            'count': 14,
          },
          {
            'date': '2026-08-08T00:00:00Z',
            'count': 22,
          },
        ],
      );

      final domain = TracearrActivityMapper.fromDto(response);

      expect(domain.period, 'week');
      expect(domain.rangeStart, DateTime.parse('2026-08-07T00:00:00Z'));
      expect(domain.rangeEnd, DateTime.parse('2026-08-14T00:00:00Z'));
      expect(domain.plays.length, 2);
      expect(domain.plays[0].count, 14);
      expect(domain.plays[0].date, DateTime.parse('2026-08-07T00:00:00Z'));
      expect(domain.plays[1].count, 22);
    });

    test('handles empty or null fields with safe defaults', () {
      const response = ActivityResponse();
      final domain = TracearrActivityMapper.fromDto(response);

      expect(domain.period, 'week');
      expect(domain.rangeStart, isNull);
      expect(domain.rangeEnd, isNull);
      expect(domain.plays, isEmpty);
    });
  });
}
