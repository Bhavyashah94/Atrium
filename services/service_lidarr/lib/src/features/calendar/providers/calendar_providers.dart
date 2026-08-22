import 'package:core_models/core_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../generated/generated.dart';
import '../../../lidarr_api.dart';
import '../../../state/api_providers.dart';

/// The calendar entries for a Lidarr instance for a given month.
final lidarrCalendarProvider = FutureProvider.autoDispose
    .family<List<AlbumResource>, (Instance, DateTime)>((
  Ref ref,
  (Instance, DateTime) key,
) async {
  final (Instance instance, DateTime month) = key;
  final LidarrApi api = await ref.watch(lidarrApiProvider(instance).future);

  // Calculate local month boundaries
  final DateTime start = DateTime(month.year, month.month);
  final DateTime end = DateTime(month.year, month.month + 1)
      .subtract(const Duration(seconds: 1));

  final ApiResponse<List<AlbumResource>> resp = await api.calendar.getCalendar(
    start: start.toIso8601String(),
    end: end.toIso8601String(),
    includeArtist: true,
    unmonitored: true,
  );

  return unwrapLidarrApiResponse(resp, 'Failed to load calendar albums');
});
