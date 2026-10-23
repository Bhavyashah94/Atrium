import 'package:core_models/core_models.dart';
import 'package:core_networking/core_networking.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import 'cleanuparr_api.dart';
import 'models/cleanuparr_event.dart';
import 'models/cleanuparr_job.dart';
import 'models/cleanuparr_stats.dart';
import 'models/cleanuparr_status.dart';
import 'models/cleanuparr_strike.dart';

/// Active bottom navbar tab index for [instance] (0: Overview, 1: Strikes, 2: Events).
final cleanuparrTabProvider =
    StateProvider.autoDispose.family<int, Instance>((ref, instance) => 0);

/// Provides a [CleanuparrApi] configured with the instance's resolved base URL and API key.
final cleanuparrApiProvider =
    FutureProvider.autoDispose.family<CleanuparrApi, Instance>((
  Ref ref,
  Instance instance,
) async {
  final Dio dio = await ref.watch(instanceDioProvider(instance).future);
  return CleanuparrApi(dio);
});

/// Fetches system information, uptime, memory, and Arr/client connections.
final cleanuparrStatusProvider =
    FutureProvider.autoDispose.family<CleanuparrStatus, Instance>((
  Ref ref,
  Instance instance,
) async {
  final CleanuparrApi api =
      await ref.watch(cleanuparrApiProvider(instance).future);
  return api.getStatus();
});

/// Selected timeframe in hours for the Overview metrics (e.g. 24, 168, 720).
final cleanuparrTimeframeHoursProvider =
    StateProvider.autoDispose.family<int, Instance>((ref, instance) => 168);

/// Fetches aggregated operational metrics for the selected timeframe.
final cleanuparrStatsProvider =
    FutureProvider.autoDispose.family<CleanuparrStats, Instance>((
  Ref ref,
  Instance instance,
) async {
  final CleanuparrApi api =
      await ref.watch(cleanuparrApiProvider(instance).future);
  final int hours = ref.watch(cleanuparrTimeframeHoursProvider(instance));
  return api.getStats(hours: hours);
});

/// Fetches registered background jobs and their execution states.
final cleanuparrJobsProvider =
    FutureProvider.autoDispose.family<List<CleanuparrJob>, Instance>((
  Ref ref,
  Instance instance,
) async {
  final CleanuparrApi api =
      await ref.watch(cleanuparrApiProvider(instance).future);
  return api.getJobs();
});

/// Search query string for filtering the active strikes list.
final cleanuparrStrikesSearchProvider =
    StateProvider.autoDispose.family<String, Instance>((ref, instance) => '');

/// Fetches download items currently holding active strikes.
final cleanuparrStrikesProvider =
    FutureProvider.autoDispose.family<List<CleanuparrStrikeItem>, Instance>((
  Ref ref,
  Instance instance,
) async {
  final CleanuparrApi api =
      await ref.watch(cleanuparrApiProvider(instance).future);
  final String search = ref.watch(cleanuparrStrikesSearchProvider(instance));
  return api.getStrikes(search: search.isNotEmpty ? search : null);
});

/// Returns the number of items with active strikes (used for the tab badge).
final cleanuparrActiveStrikesCountProvider =
    Provider.autoDispose.family<int, Instance>((Ref ref, Instance instance) {
  final strikesAsync = ref.watch(cleanuparrStrikesProvider(instance));
  return strikesAsync.maybeWhen(
    data: (List<CleanuparrStrikeItem> items) => items.length,
    orElse: () => 0,
  );
});

/// Search query string for filtering audit events.
final cleanuparrEventsSearchProvider =
    StateProvider.autoDispose.family<String, Instance>((ref, instance) => '');

/// Active category filter for audit events (null = All, 'malware', 'strikes', 'deletions', 'cleaned').
final cleanuparrEventsFilterProvider =
    StateProvider.autoDispose.family<String?, Instance>((ref, instance) => null);

/// Fetches audit log events filtered by active search query and category filter.
final cleanuparrEventsProvider =
    FutureProvider.autoDispose.family<List<CleanuparrEvent>, Instance>((
  Ref ref,
  Instance instance,
) async {
  final CleanuparrApi api =
      await ref.watch(cleanuparrApiProvider(instance).future);
  final String search = ref.watch(cleanuparrEventsSearchProvider(instance));
  final String? filter = ref.watch(cleanuparrEventsFilterProvider(instance));

  final List<CleanuparrEvent> events = await api.getEvents(
    search: search.isNotEmpty ? search : null,
  );

  if (filter == null || filter.isEmpty) {
    return events;
  }

  final String f = filter.toLowerCase();
  switch (f) {
    case 'strikes':
    case 'strike':
      return events.where((CleanuparrEvent e) => e.isStrike).toList();
    case 'malware':
      return events.where((CleanuparrEvent e) => e.isMalware).toList();
    case 'deletions':
    case 'deletion':
    case 'delet':
      return events.where((CleanuparrEvent e) => e.isRemoval).toList();
    case 'cleaned':
    case 'clean':
      return events
          .where(
            (CleanuparrEvent e) =>
                e.eventType.toLowerCase().contains('clean') ||
                e.eventType == 'DownloadCleaned',
          )
          .toList();
    default:
      return events
          .where((CleanuparrEvent e) => e.eventType.toLowerCase() == f)
          .toList();
  }
});
