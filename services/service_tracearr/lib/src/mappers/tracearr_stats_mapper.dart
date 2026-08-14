import '../generated/models/stats_response.dart';
import '../generated/models/stats_today_response.dart';
import '../models/tracearr_models.dart';

/// Pure transformation for 24h today and 30d aggregate fleet stats.
class TracearrStatsMapper {
  const TracearrStatsMapper._();

  static TracearrTodayStats todayFromDto(StatsTodayResponse response) {
    return TracearrTodayStats(
      activeStreams: response.activeStreams ?? 0,
      todayPlays: response.todayPlays ?? 0,
      watchTimeHours: response.watchTimeHours ?? 0.0,
      alertsLast24h: response.alertsLast24h ?? 0,
      activeUsersToday: response.activeUsersToday ?? 0,
      timestamp: response.timestamp != null
          ? DateTime.tryParse(response.timestamp!)
          : null,
    );
  }

  static TracearrAggregateStats aggregateFromDto(StatsResponse response) {
    return TracearrAggregateStats(
      activeStreams: response.activeStreams ?? 0,
      totalUsers: response.totalUsers ?? 0,
      totalSessions: response.totalSessions ?? 0,
      recentViolations: response.recentViolations ?? 0,
      timestamp: response.timestamp != null
          ? DateTime.tryParse(response.timestamp!)
          : null,
    );
  }
}
