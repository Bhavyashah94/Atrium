import 'package:core_models/core_models.dart';
import 'package:core_networking/core_networking.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth/tracearr_auth_interceptor.dart';
import 'auth/tracearr_auth_manager.dart';
import 'models/tracearr_active_sessions.dart';
import 'models/tracearr_v2_models.dart';
import 'tracearr_api.dart';

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
///
/// `onDispose` is registered **before** the first await, not after. This
/// provider is autoDispose, so with nothing listening it can be torn down
/// during that await, and registering afterwards throws
/// UnmountedRefException. That surfaced as "Could not reach the server" on
/// every Test connection, against servers that were answering perfectly.
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

/// Active playback streams provider (GET /api/v2/public/streams)
final tracearrActiveSessionsProvider =
    FutureProvider.autoDispose.family<TracearrActiveSessions, Instance>((
  Ref ref,
  Instance instance,
) async {
  final TracearrApi api = await ref.watch(tracearrApiProvider(instance).future);
  return api.getActiveSessions();
});

/// Global watch history provider (GET /api/v2/public/history)
final tracearrV2HistoryProvider = FutureProvider.autoDispose
    .family<TracearrV2HistoryResponse, Instance>((
  Ref ref,
  Instance instance,
) async {
  final TracearrApi api = await ref.watch(tracearrApiProvider(instance).future);
  return api.getV2History();
});

/// Users list provider (GET /api/v2/public/users)
final tracearrV2UsersProvider =
    FutureProvider.autoDispose.family<TracearrV2UsersResponse, Instance>((
  Ref ref,
  Instance instance,
) async {
  final TracearrApi api = await ref.watch(tracearrApiProvider(instance).future);
  return api.getV2Users();
});

/// Single user identity provider (GET /api/v2/public/users/{id})
final tracearrV2UserByIdProvider = FutureProvider.autoDispose
    .family<TracearrV2UserIdentity?, ({Instance instance, String id})>((
  Ref ref,
  ({Instance instance, String id}) args,
) async {
  final TracearrApi api =
      await ref.watch(tracearrApiProvider(args.instance).future);
  return api.getUserById(args.id);
});

/// User statistics provider (GET /api/v2/public/users/{id}/stats)
final tracearrV2UserStatsProvider = FutureProvider.autoDispose
    .family<TracearrV2UserStatsResponse?, ({Instance instance, String id})>((
  Ref ref,
  ({Instance instance, String id}) args,
) async {
  final TracearrApi api =
      await ref.watch(tracearrApiProvider(args.instance).future);
  return api.getUserStats(args.id);
});

/// Libraries list provider (GET /api/v2/public/libraries)
final tracearrV2LibrariesProvider = FutureProvider.autoDispose
    .family<TracearrV2LibrariesResponse, Instance>((
  Ref ref,
  Instance instance,
) async {
  final TracearrApi api = await ref.watch(tracearrApiProvider(instance).future);
  return api.getV2Libraries();
});

/// Recently added items provider (GET /api/v2/public/recently-added)
final tracearrV2RecentlyAddedProvider = FutureProvider.autoDispose
    .family<TracearrV2RecentlyAddedResponse, Instance>((
  Ref ref,
  Instance instance,
) async {
  final TracearrApi api = await ref.watch(tracearrApiProvider(instance).future);
  return api.getV2RecentlyAdded();
});

/// Media resource provider (GET /api/v2/public/media/{ref})
final tracearrV2MediaResourceProvider = FutureProvider.autoDispose
    .family<TracearrV2MediaResource?, ({Instance instance, String ref})>((
  Ref ref,
  ({Instance instance, String ref}) args,
) async {
  final TracearrApi api =
      await ref.watch(tracearrApiProvider(args.instance).future);
  return api.getMediaResource(args.ref);
});

/// Media children provider (GET /api/v2/public/media/{ref}/children)
final tracearrV2MediaChildrenProvider = FutureProvider.autoDispose
    .family<TracearrV2MediaChildrenResponse, ({Instance instance, String ref})>((
  Ref ref,
  ({Instance instance, String ref}) args,
) async {
  final TracearrApi api =
      await ref.watch(tracearrApiProvider(args.instance).future);
  return api.getMediaChildren(args.ref);
});

/// Media statistics provider (GET /api/v2/public/media/{ref}/stats)
final tracearrV2MediaStatsProvider = FutureProvider.autoDispose
    .family<TracearrV2MediaStatsResponse?, ({Instance instance, String ref})>((
  Ref ref,
  ({Instance instance, String ref}) args,
) async {
  final TracearrApi api =
      await ref.watch(tracearrApiProvider(args.instance).future);
  return api.getMediaStats(args.ref);
});

/// Media watchers provider (GET /api/v2/public/media/{ref}/watchers)
final tracearrV2MediaWatchersProvider = FutureProvider.autoDispose
    .family<TracearrV2MediaWatchersResponse, ({Instance instance, String ref})>((
  Ref ref,
  ({Instance instance, String ref}) args,
) async {
  final TracearrApi api =
      await ref.watch(tracearrApiProvider(args.instance).future);
  return api.getMediaWatchers(args.ref);
});
