import 'package:core_models/core_models.dart';
import 'package:core_networking/core_networking.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'aria2_api.dart';
import 'models/aria2_download.dart';
import 'models/aria2_snapshot.dart';

/// How often the download lists refresh while a screen is visible.
const Duration aria2PollInterval = Duration(seconds: 3);

/// The detail screen refreshes a little slower than the list.
const Duration aria2DetailPollInterval = Duration(seconds: 5);

/// An [Aria2Api] for an instance, over the shared `instanceDioProvider`.
///
/// The daemon's secret token is read from the instance's api key: aria2
/// calls it `--rpc-secret`, and it is the one credential the RPC interface
/// takes. An instance with no secret gets a client that sends no token, which
/// is what an aria2 with no `--rpc-secret` expects.
final aria2ApiProvider = FutureProvider.family<Aria2Api, Instance>((
  Ref ref,
  Instance instance,
) async {
  final dio = await ref.watch(instanceDioProvider(instance).future);
  final String secret = switch (instance.auth) {
    InstanceAuthApiKey(:final String apiKey) => apiKey,
    InstanceAuthUserPass() || InstanceAuthPlex() || InstanceAuthCookie() => '',
  };
  return Aria2Api(dio, secret: secret);
});

/// The whole daemon in one poll: the three download lists, the global
/// counters and the version.
final aria2SnapshotProvider = FutureProvider.autoDispose
    .family<Aria2Snapshot, Instance>((Ref ref, Instance instance) async {
      ref.pollEvery(aria2PollInterval);
      final Aria2Api api = await ref.watch(aria2ApiProvider(instance).future);
      return api.getSnapshot();
    });

/// One download's own status, for the detail screen.
///
/// Null when the daemon no longer knows the download - it was removed and
/// its result purged, which is what happens when the user clears the list.
final aria2DownloadProvider = FutureProvider.autoDispose
    .family<Aria2Download?, (Instance, String)>((
      Ref ref,
      (Instance, String) key,
    ) async {
      ref.pollEvery(aria2DetailPollInterval);
      final (Instance instance, String gid) = key;
      final Aria2Api api = await ref.watch(aria2ApiProvider(instance).future);
      try {
        return await api.tellStatus(gid);
      } on Aria2RpcException {
        // The daemon answers "no such download" for a GID it has forgotten.
        return null;
      }
    });

/// The daemon's global options, read on demand.
///
/// Not polled: the answer carries every option the daemon has, and only the
/// speed limits are ever shown.
final aria2GlobalOptionsProvider = FutureProvider.autoDispose
    .family<Map<String, String>, Instance>((Ref ref, Instance instance) async {
      final Aria2Api api = await ref.watch(aria2ApiProvider(instance).future);
      return api.getGlobalOption();
    });
