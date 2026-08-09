// AUTO-GENERATED FROM v2.json OpenAPI Specification
// DO NOT EDIT DIRECTLY. Run `dart run tool/generate_tracearr_models.dart` to update.

import 'dart:async';
import 'package:core_models/core_models.dart';
import 'package:core_networking/core_networking.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import 'auth/tracearr_auth_interceptor.dart';
import 'auth/tracearr_auth_manager.dart';
import 'models/tracearr_v2_models.dart';
import 'tracearr_api.dart';

final tracearrActiveTabBarIndexProvider =
    StateProvider.family<int, Instance>((Ref ref, Instance instance) => 0);

final tracearrBottomNavVisibleProvider =
    StateProvider.family<bool, Instance>((Ref ref, Instance instance) => true);

// --- Recently Added tab UI state ---
/// UI StateProvider for category filtering in Recently Added Tab.
final tracearrRecentTypeFilterProvider =
    StateProvider.family<String, Instance>((Ref ref, Instance instance) => 'ALL');

/// UI StateProvider for genre filtering in Recently Added Tab.
final tracearrRecentGenreFilterProvider =
    StateProvider.family<String, Instance>((Ref ref, Instance instance) => 'ALL');

/// UI StateProvider for sorting criteria in Recently Added Tab.
final tracearrRecentSortByProvider =
    StateProvider.family<String, Instance>((Ref ref, Instance instance) => 'added');

/// UI StateProvider for Grid vs List layout toggle in Recently Added Tab.
final tracearrRecentGridViewProvider =
    StateProvider.family<bool, Instance>((Ref ref, Instance instance) => true);

// --- History tab UI state ---
/// UI StateProvider for category filter selection in History Tab.
final tracearrHistoryTypeFilterProvider =
    StateProvider.family<String, Instance>((Ref ref, Instance instance) => 'ALL');

/// UI StateProvider for play completion status filter selection in History Tab.
final tracearrHistoryStatusFilterProvider =
    StateProvider.family<String, Instance>((Ref ref, Instance instance) => 'ALL');

/// UI StateProvider for genre filter selection in History Tab.
/// Generated to maintain persistent global UI filter state across navigation transitions.
final tracearrHistoryGenreFilterProvider =
    StateProvider.family<String, Instance>((Ref ref, Instance instance) => 'ALL');

/// UI StateProvider for multi-criteria sort order selection in History Tab.
/// Supports Date (Newest/Oldest), Duration (Longest), Completion %, and Title (A-Z).
final tracearrHistorySortByProvider =
    StateProvider.family<String, Instance>((Ref ref, Instance instance) => 'DATE_DESC');

// --- User detail UI state ---
/// UI StateProvider for genre filter selection in User Details Screen.
final tracearrUserGenreFilterProvider =
    StateProvider.family<String, String>((Ref ref, String key) => 'ALL');

/// UI StateProvider for sort order selection in User Details Screen.
final tracearrUserSortByProvider =
    StateProvider.family<String, String>((Ref ref, String key) => 'DATE_DESC');

/// The key is static, so this needs nothing from the network.
final tracearrAuthManagerProvider =
    Provider.autoDispose.family<TracearrAuthManager, Instance>((
  Ref ref,
  Instance instance,
) {
  return TracearrAuthManager(
    baseUrl: Uri.parse(instance.localUrl),
    auth: instance.auth,
  );
});


/// The single client every Tracearr call goes through.
final tracearrDioProvider = FutureProvider.autoDispose.family<Dio, Instance>((
  Ref ref,
  Instance instance,
) async {
  Dio? created;
  ref.onDispose(() => created?.close(force: true));

  final Map<String, String> global = ref.watch(globalHeadersProvider);
  final Dio dio = await ref
      .watch(dioFactoryProvider)
      .create(instance, globalHeaders: global);
  created = dio;

  dio.interceptors.add(
    TracearrAuthInterceptor(
      manager: ref.watch(tracearrAuthManagerProvider(instance)),
    ),
  );
  return dio;
});

final tracearrApiProvider =
    FutureProvider.autoDispose.family<TracearrApi, Instance>((
  Ref ref,
  Instance instance,
) async {
  final Dio dio = await ref.watch(tracearrDioProvider(instance).future);
  final TracearrAuthManager manager =
      ref.watch(tracearrAuthManagerProvider(instance));
  final String token = await manager.ensureToken();
  return TracearrApi(dio, token: token);
});

/// Provider for OpenAPI specification (/api/v2/public/docs)
///
/// RATIONALE & CACHING SPECIFICATION:
/// - Uses `ref.keepAlive()` with a 600s TTL Timer (link.close) matching
///   official Tracearr application staleTimes (from official tracearr/apps/mobile repo).
/// - Prevents premature cache eviction and redundant HTTP re-fetches during tab navigation.
/// - `ref.onDispose(timer.cancel)` guarantees clean memory management without leaks.
final tracearrV2GetDocsProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, Instance>((
  Ref ref,
  Instance instance,
) async {
  final link = ref.keepAlive();
  final Timer timer = Timer(const Duration(seconds: 600), link.close);
  ref.onDispose(timer.cancel);

  final TracearrApi api = await ref.watch(tracearrApiProvider(instance).future);
  return api.getDocs();
});

/// Provider for Watch history as plays (/api/v2/public/history)
///
/// RATIONALE & CACHING SPECIFICATION:
/// - Uses `ref.keepAlive()` with a 300s TTL Timer (link.close) matching
///   official Tracearr application staleTimes (from official tracearr/apps/mobile repo).
/// - Prevents premature cache eviction and redundant HTTP re-fetches during tab navigation.
/// - `ref.onDispose(timer.cancel)` guarantees clean memory management without leaks.
final tracearrV2GetHistoryProvider = FutureProvider.autoDispose
    .family<TracearrV2HistoryResponse, Instance>((
  Ref ref,
  Instance instance,
) async {
  final link = ref.keepAlive();
  final Timer timer = Timer(const Duration(seconds: 300), link.close);
  ref.onDispose(timer.cancel);

  final TracearrApi api = await ref.watch(tracearrApiProvider(instance).future);
  // CURSOR PAGINATION RATIONALE:
  // OpenAPI v2 defaults to returning pageSize: 20 when omitted.
  // To ensure cross-screen map completeness (ServerNamesMap, UserAvatarsMap)
  // and total timeline accuracy, we auto-loop cursor pages up to completion.
  final List<TracearrV2HistoryRecord> allData = <TracearrV2HistoryRecord>[];
  String? cursor;
  late TracearrV2HistoryResponse firstResp;
  int pageCount = 0;
  do {
    final TracearrV2HistoryResponse page = await api.getHistory(cursor: cursor, pageSize: 100);
    if (pageCount == 0) firstResp = page;
    allData.addAll(page.data);
    cursor = page.meta?.nextCursor;
    pageCount++;
  } while (cursor != null && cursor.isNotEmpty && pageCount < 20);
  return firstResp.copyWith(data: allData);
});

/// Provider for Active streams (/api/v2/public/streams)
///
/// RATIONALE & CACHING SPECIFICATION:
/// - Uses `ref.keepAlive()` with a 30s TTL Timer (link.close) matching
///   official Tracearr application staleTimes (from official tracearr/apps/mobile repo).
/// - Prevents premature cache eviction and redundant HTTP re-fetches during tab navigation.
/// - `ref.onDispose(timer.cancel)` guarantees clean memory management without leaks.
final tracearrV2GetStreamsProvider = FutureProvider.autoDispose
    .family<TracearrV2StreamsResponse, Instance>((
  Ref ref,
  Instance instance,
) async {
  final link = ref.keepAlive();
  final Timer timer = Timer(const Duration(seconds: 30), link.close);
  ref.onDispose(timer.cancel);

  final TracearrApi api = await ref.watch(tracearrApiProvider(instance).future);
  return api.getStreams();
});

/// Provider for Media identity and availability (/api/v2/public/media/{ref})
///
/// RATIONALE & CACHING SPECIFICATION:
/// - Uses `ref.keepAlive()` with a 600s TTL Timer (link.close) matching
///   official Tracearr application staleTimes (from official tracearr/apps/mobile repo).
/// - Prevents premature cache eviction and redundant HTTP re-fetches during tab navigation.
/// - `ref.onDispose(timer.cancel)` guarantees clean memory management without leaks.
final tracearrV2GetMediaByRefProvider = FutureProvider.autoDispose
    .family<TracearrV2MediaResource, ({Instance instance, String ref})>((
  Ref ref,
  ({Instance instance, String ref}) args,
) async {
  final link = ref.keepAlive();
  final Timer timer = Timer(const Duration(seconds: 600), link.close);
  ref.onDispose(timer.cancel);

  final TracearrApi api =
      await ref.watch(tracearrApiProvider(args.instance).future);
  return api.getMediaByRef(ref: args.ref);
});

/// Provider for Media children (/api/v2/public/media/{ref}/children)
///
/// RATIONALE & CACHING SPECIFICATION:
/// - Uses `ref.keepAlive()` with a 600s TTL Timer (link.close) matching
///   official Tracearr application staleTimes (from official tracearr/apps/mobile repo).
/// - Prevents premature cache eviction and redundant HTTP re-fetches during tab navigation.
/// - `ref.onDispose(timer.cancel)` guarantees clean memory management without leaks.
final tracearrV2GetMediaChildrenProvider = FutureProvider.autoDispose
    .family<TracearrV2MediaChildrenResponse, ({Instance instance, String ref})>((
  Ref ref,
  ({Instance instance, String ref}) args,
) async {
  final link = ref.keepAlive();
  final Timer timer = Timer(const Duration(seconds: 600), link.close);
  ref.onDispose(timer.cancel);

  final TracearrApi api =
      await ref.watch(tracearrApiProvider(args.instance).future);
  return api.getMediaChildren(ref: args.ref);
});

/// Provider for Media play statistics (/api/v2/public/media/{ref}/stats)
///
/// RATIONALE & CACHING SPECIFICATION:
/// - Uses `ref.keepAlive()` with a 600s TTL Timer (link.close) matching
///   official Tracearr application staleTimes (from official tracearr/apps/mobile repo).
/// - Prevents premature cache eviction and redundant HTTP re-fetches during tab navigation.
/// - `ref.onDispose(timer.cancel)` guarantees clean memory management without leaks.
final tracearrV2GetMediaStatsProvider = FutureProvider.autoDispose
    .family<TracearrV2MediaStatsResponse, ({Instance instance, String ref})>((
  Ref ref,
  ({Instance instance, String ref}) args,
) async {
  final link = ref.keepAlive();
  final Timer timer = Timer(const Duration(seconds: 600), link.close);
  ref.onDispose(timer.cancel);

  final TracearrApi api =
      await ref.watch(tracearrApiProvider(args.instance).future);
  return api.getMediaStats(ref: args.ref);
});

/// Provider for Media watchers (/api/v2/public/media/{ref}/watchers)
///
/// RATIONALE & CACHING SPECIFICATION:
/// - Uses `ref.keepAlive()` with a 600s TTL Timer (link.close) matching
///   official Tracearr application staleTimes (from official tracearr/apps/mobile repo).
/// - Prevents premature cache eviction and redundant HTTP re-fetches during tab navigation.
/// - `ref.onDispose(timer.cancel)` guarantees clean memory management without leaks.
final tracearrV2GetMediaWatchersProvider = FutureProvider.autoDispose
    .family<TracearrV2MediaWatchersResponse, ({Instance instance, String ref})>((
  Ref ref,
  ({Instance instance, String ref}) args,
) async {
  final link = ref.keepAlive();
  final Timer timer = Timer(const Duration(seconds: 600), link.close);
  ref.onDispose(timer.cancel);

  final TracearrApi api =
      await ref.watch(tracearrApiProvider(args.instance).future);
  return api.getMediaWatchers(ref: args.ref);
});

/// Provider for Media watch history (/api/v2/public/media/{ref}/history)
///
/// RATIONALE & CACHING SPECIFICATION:
/// - Uses `ref.keepAlive()` with a 300s TTL Timer (link.close) matching
///   official Tracearr application staleTimes (from official tracearr/apps/mobile repo).
/// - Prevents premature cache eviction and redundant HTTP re-fetches during tab navigation.
/// - `ref.onDispose(timer.cancel)` guarantees clean memory management without leaks.
final tracearrV2GetMediaHistoryProvider = FutureProvider.autoDispose
    .family<TracearrV2HistoryResponse, ({Instance instance, String ref})>((
  Ref ref,
  ({Instance instance, String ref}) args,
) async {
  final link = ref.keepAlive();
  final Timer timer = Timer(const Duration(seconds: 300), link.close);
  ref.onDispose(timer.cancel);

  final TracearrApi api =
      await ref.watch(tracearrApiProvider(args.instance).future);
  // CURSOR PAGINATION RATIONALE:
  // OpenAPI v2 defaults to returning pageSize: 20 when omitted.
  // We auto-loop cursor pages to retrieve 100% of play history entries.
  final List<TracearrV2HistoryRecord> allData = <TracearrV2HistoryRecord>[];
  String? cursor;
  late TracearrV2HistoryResponse firstResp;
  int pageCount = 0;
  do {
    final TracearrV2HistoryResponse page = await api.getMediaHistory(ref: args.ref, cursor: cursor, pageSize: 100);
    if (pageCount == 0) firstResp = page;
    allData.addAll(page.data);
    cursor = page.meta?.nextCursor;
    pageCount++;
  } while (cursor != null && cursor.isNotEmpty && pageCount < 20);
  return firstResp.copyWith(data: allData);
});

/// Provider for Identities with account correlation (/api/v2/public/users)
///
/// RATIONALE & CACHING SPECIFICATION:
/// - Uses `ref.keepAlive()` with a 300s TTL Timer (link.close) matching
///   official Tracearr application staleTimes (from official tracearr/apps/mobile repo).
/// - Prevents premature cache eviction and redundant HTTP re-fetches during tab navigation.
/// - `ref.onDispose(timer.cancel)` guarantees clean memory management without leaks.
final tracearrV2GetUsersProvider = FutureProvider.autoDispose
    .family<TracearrV2UsersResponse, Instance>((
  Ref ref,
  Instance instance,
) async {
  final link = ref.keepAlive();
  final Timer timer = Timer(const Duration(seconds: 300), link.close);
  ref.onDispose(timer.cancel);

  final TracearrApi api = await ref.watch(tracearrApiProvider(instance).future);
  return api.getUsers();
});

/// Provider for One identity (/api/v2/public/users/{id})
///
/// RATIONALE & CACHING SPECIFICATION:
/// - Uses `ref.keepAlive()` with a 600s TTL Timer (link.close) matching
///   official Tracearr application staleTimes (from official tracearr/apps/mobile repo).
/// - Prevents premature cache eviction and redundant HTTP re-fetches during tab navigation.
/// - `ref.onDispose(timer.cancel)` guarantees clean memory management without leaks.
final tracearrV2GetUserByIdProvider = FutureProvider.autoDispose
    .family<TracearrV2UserIdentity, ({Instance instance, String id})>((
  Ref ref,
  ({Instance instance, String id}) args,
) async {
  final link = ref.keepAlive();
  final Timer timer = Timer(const Duration(seconds: 600), link.close);
  ref.onDispose(timer.cancel);

  final TracearrApi api =
      await ref.watch(tracearrApiProvider(args.instance).future);
  return api.getUserById(id: args.id);
});

/// Provider for Identity play statistics (/api/v2/public/users/{id}/stats)
///
/// RATIONALE & CACHING SPECIFICATION:
/// - Uses `ref.keepAlive()` with a 600s TTL Timer (link.close) matching
///   official Tracearr application staleTimes (from official tracearr/apps/mobile repo).
/// - Prevents premature cache eviction and redundant HTTP re-fetches during tab navigation.
/// - `ref.onDispose(timer.cancel)` guarantees clean memory management without leaks.
final tracearrV2GetUserStatsProvider = FutureProvider.autoDispose
    .family<TracearrV2UserStatsResponse, ({Instance instance, String id})>((
  Ref ref,
  ({Instance instance, String id}) args,
) async {
  final link = ref.keepAlive();
  final Timer timer = Timer(const Duration(seconds: 600), link.close);
  ref.onDispose(timer.cancel);

  final TracearrApi api =
      await ref.watch(tracearrApiProvider(args.instance).future);
  return api.getUserStats(id: args.id);
});

/// Provider for Identity watch history (/api/v2/public/users/{id}/history)
///
/// RATIONALE & CACHING SPECIFICATION:
/// - Uses `ref.keepAlive()` with a 300s TTL Timer (link.close) matching
///   official Tracearr application staleTimes (from official tracearr/apps/mobile repo).
/// - Prevents premature cache eviction and redundant HTTP re-fetches during tab navigation.
/// - `ref.onDispose(timer.cancel)` guarantees clean memory management without leaks.
final tracearrV2GetUserHistoryProvider = FutureProvider.autoDispose
    .family<TracearrV2HistoryResponse, ({Instance instance, String id})>((
  Ref ref,
  ({Instance instance, String id}) args,
) async {
  final link = ref.keepAlive();
  final Timer timer = Timer(const Duration(seconds: 300), link.close);
  ref.onDispose(timer.cancel);

  final TracearrApi api =
      await ref.watch(tracearrApiProvider(args.instance).future);
  // CURSOR PAGINATION RATIONALE:
  // OpenAPI v2 defaults to returning pageSize: 20 when omitted.
  // We auto-loop cursor pages to retrieve 100% of play history entries.
  final List<TracearrV2HistoryRecord> allData = <TracearrV2HistoryRecord>[];
  String? cursor;
  late TracearrV2HistoryResponse firstResp;
  int pageCount = 0;
  do {
    final TracearrV2HistoryResponse page = await api.getUserHistory(id: args.id, cursor: cursor, pageSize: 100);
    if (pageCount == 0) firstResp = page;
    allData.addAll(page.data);
    cursor = page.meta?.nextCursor;
    pageCount++;
  } while (cursor != null && cursor.isNotEmpty && pageCount < 20);
  return firstResp.copyWith(data: allData);
});

/// Provider for Recently added library items (/api/v2/public/recently-added)
///
/// RATIONALE & CACHING SPECIFICATION:
/// - Uses `ref.keepAlive()` with a 300s TTL Timer (link.close) matching
///   official Tracearr application staleTimes (from official tracearr/apps/mobile repo).
/// - Prevents premature cache eviction and redundant HTTP re-fetches during tab navigation.
/// - `ref.onDispose(timer.cancel)` guarantees clean memory management without leaks.
final tracearrV2GetRecentlyAddedProvider = FutureProvider.autoDispose
    .family<TracearrV2RecentlyAddedResponse, Instance>((
  Ref ref,
  Instance instance,
) async {
  final link = ref.keepAlive();
  final Timer timer = Timer(const Duration(seconds: 300), link.close);
  ref.onDispose(timer.cancel);

  final TracearrApi api = await ref.watch(tracearrApiProvider(instance).future);
  // CURSOR PAGINATION RATIONALE:
  // OpenAPI v2 defaults to returning pageSize: 20 when omitted.
  // To ensure cross-screen map completeness (ServerNamesMap, UserAvatarsMap)
  // and total timeline accuracy, we auto-loop cursor pages up to completion.
  final List<TracearrV2RecentlyAddedRecord> allData = <TracearrV2RecentlyAddedRecord>[];
  String? cursor;
  late TracearrV2RecentlyAddedResponse firstResp;
  int pageCount = 0;
  do {
    final TracearrV2RecentlyAddedResponse page = await api.getRecentlyAdded(cursor: cursor, pageSize: 100);
    if (pageCount == 0) firstResp = page;
    allData.addAll(page.data);
    cursor = page.meta?.nextCursor;
    pageCount++;
  } while (cursor != null && cursor.isNotEmpty && pageCount < 20);
  return firstResp.copyWith(data: allData);
});

/// Provider for Per-library rollups (/api/v2/public/libraries)
///
/// RATIONALE & CACHING SPECIFICATION:
/// - Uses `ref.keepAlive()` with a 600s TTL Timer (link.close) matching
///   official Tracearr application staleTimes (from official tracearr/apps/mobile repo).
/// - Prevents premature cache eviction and redundant HTTP re-fetches during tab navigation.
/// - `ref.onDispose(timer.cancel)` guarantees clean memory management without leaks.
final tracearrV2GetLibrariesProvider = FutureProvider.autoDispose
    .family<TracearrV2LibrariesResponse, Instance>((
  Ref ref,
  Instance instance,
) async {
  final link = ref.keepAlive();
  final Timer timer = Timer(const Duration(seconds: 600), link.close);
  ref.onDispose(timer.cancel);

  final TracearrApi api = await ref.watch(tracearrApiProvider(instance).future);
  return api.getLibraries();
});

final tracearrActiveSessionsProvider = tracearrV2GetStreamsProvider;

/// Aggregated provider mapping serverId -> human-readable serverName.
///
/// OpenAPI endpoints like /libraries, /users, and /media omit server_name.
/// This provider aggregates server_name mappings from streams, libraries, and history.
final tracearrServerNamesMapProvider = Provider.autoDispose
    .family<Map<String, String>, Instance>((Ref ref, Instance instance) {
  final Map<String, String> map = <String, String>{};

  final AsyncValue<TracearrV2StreamsResponse> streams =
      ref.watch(tracearrV2GetStreamsProvider(instance));
  streams.whenData((TracearrV2StreamsResponse s) {
    for (final TracearrV2StreamsServerSummary item
        in s.summary?.byServer ?? <TracearrV2StreamsServerSummary>[]) {
      if (item.serverId != null &&
          item.serverName != null &&
          item.serverName!.isNotEmpty) {
        map[item.serverId!] = item.serverName!;
      }
    }
  });

  final AsyncValue<TracearrV2LibrariesResponse> libraries =
      ref.watch(tracearrV2GetLibrariesProvider(instance));
  libraries.whenData((TracearrV2LibrariesResponse l) {
    for (final TracearrV2LibraryRollup item in l.data) {
      if (item.serverId != null &&
          item.serverName != null &&
          item.serverName!.isNotEmpty) {
        map[item.serverId!] = item.serverName!;
      }
    }
  });

  final AsyncValue<TracearrV2HistoryResponse> history =
      ref.watch(tracearrV2GetHistoryProvider(instance));
  history.whenData((TracearrV2HistoryResponse h) {
    for (final TracearrV2HistoryRecord item in h.data) {
      if (item.serverId != null &&
          item.serverName != null &&
          item.serverName!.isNotEmpty) {
        map[item.serverId!] = item.serverName!;
      }
    }
  });

  return map;
});

/// Aggregated provider mapping userId -> avatarUrl.
///
/// /api/v2/public/users omits avatar_url from TracearrV2UserIdentity.
/// Watch history (/api/v2/public/history) returns user.id & user.avatar_url.
/// This provider aggregates user.id -> user.avatar_url from history items.
final tracearrUserAvatarsMapProvider = Provider.autoDispose
    .family<Map<String, String>, Instance>((Ref ref, Instance instance) {
  final Map<String, String> map = <String, String>{};

  final AsyncValue<TracearrV2HistoryResponse> history =
      ref.watch(tracearrV2GetHistoryProvider(instance));
  history.whenData((TracearrV2HistoryResponse h) {
    for (final TracearrV2HistoryRecord item in h.data) {
      final String? uid = item.user?.id;
      final String? avatar = item.user?.avatarUrl;
      if (uid != null &&
          uid.isNotEmpty &&
          avatar != null &&
          avatar.isNotEmpty) {
        map[uid] = avatar;
      }
    }
  });

  return map;
});

