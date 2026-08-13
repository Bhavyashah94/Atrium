import '../generated/models/activity_response.dart';
import '../models/tracearr_models.dart';

/// Pure transformation for activity trends time-series.
class TracearrActivityMapper {
  const TracearrActivityMapper._();

  static TracearrActivityBucket _mapBucket(dynamic item) {
    if (item is! Map<String, dynamic>) {
      return const TracearrActivityBucket();
    }
    final dateStr = item['date']?.toString();
    final count = item['count'] is num
        ? (item['count'] as num).toInt()
        : int.tryParse(item['count']?.toString() ?? '') ?? 0;
    final durationMs = item['durationMs'] is num
        ? (item['durationMs'] as num).toInt()
        : int.tryParse(item['durationMs']?.toString() ?? '') ?? 0;

    return TracearrActivityBucket(
      date: dateStr != null ? DateTime.tryParse(dateStr) : null,
      count: count,
      durationMs: durationMs,
    );
  }

  static TracearrActivityTrend fromDto(ActivityResponse response) {
    DateTime? start;
    DateTime? end;

    if (response.range is Map<String, dynamic>) {
      final rangeMap = response.range as Map<String, dynamic>;
      final startStr = rangeMap['start']?.toString();
      final endStr = rangeMap['end']?.toString();
      if (startStr != null) start = DateTime.tryParse(startStr);
      if (endStr != null) end = DateTime.tryParse(endStr);
    }

    final buckets = response.plays?.map(_mapBucket).toList() ??
        const <TracearrActivityBucket>[];

    return TracearrActivityTrend(
      period: response.period ?? 'week',
      rangeStart: start,
      rangeEnd: end,
      plays: buckets,
    );
  }
}
