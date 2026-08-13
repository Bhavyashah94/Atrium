import 'package:flutter_test/flutter_test.dart';
import 'package:service_tracearr/src/generated/models/stats_response.dart';
import 'package:service_tracearr/src/generated/models/stats_today_response.dart';
import 'package:service_tracearr/src/mappers/tracearr_stats_mapper.dart';

void main() {
  group('TracearrStatsMapper', () {
    test('maps today stats response correctly', () {
      const response = StatsTodayResponse(
        activeStreams: 4,
        todayPlays: 42,
        watchTimeHours: 12.5,
        alertsLast24h: 1,
        activeUsersToday: 8,
        timestamp: '2026-08-14T02:00:00Z',
      );

      final domain = TracearrStatsMapper.todayFromDto(response);

      expect(domain.activeStreams, 4);
      expect(domain.todayPlays, 42);
      expect(domain.watchTimeHours, 12.5);
      expect(domain.alertsLast24h, 1);
      expect(domain.activeUsersToday, 8);
      expect(domain.timestamp, DateTime.parse('2026-08-14T02:00:00Z'));
    });

    test('maps 30-day aggregate stats response correctly', () {
      const response = StatsResponse(
        activeStreams: 2,
        totalUsers: 25,
        totalSessions: 1450,
        recentViolations: 3,
        timestamp: '2026-08-14T02:00:00Z',
      );

      final domain = TracearrStatsMapper.aggregateFromDto(response);

      expect(domain.activeStreams, 2);
      expect(domain.totalUsers, 25);
      expect(domain.totalSessions, 1450);
      expect(domain.recentViolations, 3);
      expect(domain.timestamp, DateTime.parse('2026-08-14T02:00:00Z'));
    });

    test('handles empty or null fields with safe defaults', () {
      const today = StatsTodayResponse();
      final todayDomain = TracearrStatsMapper.todayFromDto(today);

      expect(todayDomain.activeStreams, 0);
      expect(todayDomain.todayPlays, 0);
      expect(todayDomain.watchTimeHours, 0.0);
      expect(todayDomain.alertsLast24h, 0);
      expect(todayDomain.activeUsersToday, 0);
      expect(todayDomain.timestamp, isNull);

      const aggregate = StatsResponse();
      final aggDomain = TracearrStatsMapper.aggregateFromDto(aggregate);

      expect(aggDomain.activeStreams, 0);
      expect(aggDomain.totalUsers, 0);
      expect(aggDomain.totalSessions, 0);
      expect(aggDomain.recentViolations, 0);
      expect(aggDomain.timestamp, isNull);
    });
  });
}
