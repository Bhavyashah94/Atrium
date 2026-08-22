import 'package:core_models/core_models.dart';
import 'package:core_networking/core_networking.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'dashdot_api.dart';
import 'models/dashdot_models.dart';

final dashdotApiProvider = Provider.family<Future<DashdotApi>, Instance>((
  ref,
  instance,
) async {
  final factory = ref.watch(dioFactoryProvider);
  return DashdotApi(await factory.create(instance));
});

final dashdotInfoProvider = FutureProvider.family<DashdotInfo?, Instance>((
  ref,
  instance,
) async {
  final api = await ref.watch(dashdotApiProvider(instance));
  return api.getInfo();
});

final dashdotConfigProvider = FutureProvider.family<DashdotConfig?, Instance>((
  ref,
  instance,
) async {
  final api = await ref.watch(dashdotApiProvider(instance));
  return api.getConfig();
});

// Live-load providers poll at the instance's configured interval and are
// autoDispose so the polling loop stops when the metrics view is left.
final dashdotCpuLoadProvider = StreamProvider.autoDispose
    .family<dynamic, Instance>((ref, instance) async* {
      final api = await ref.watch(dashdotApiProvider(instance));
      while (true) {
        yield await api.getCpuLoad();
        await Future<void>.delayed(
          Duration(seconds: instance.pollingIntervalSeconds),
        );
      }
    });

final dashdotRamLoadProvider = StreamProvider.autoDispose
    .family<dynamic, Instance>((ref, instance) async* {
      final api = await ref.watch(dashdotApiProvider(instance));
      while (true) {
        yield await api.getRamLoad();
        await Future<void>.delayed(
          Duration(seconds: instance.pollingIntervalSeconds),
        );
      }
    });

final dashdotStorageLoadProvider = StreamProvider.autoDispose
    .family<dynamic, Instance>((ref, instance) async* {
      final api = await ref.watch(dashdotApiProvider(instance));
      while (true) {
        yield await api.getStorageLoad();
        await Future<void>.delayed(
          Duration(seconds: instance.pollingIntervalSeconds),
        );
      }
    });

final dashdotNetworkLoadProvider = StreamProvider.autoDispose
    .family<dynamic, Instance>((ref, instance) async* {
      final api = await ref.watch(dashdotApiProvider(instance));
      while (true) {
        yield await api.getNetworkLoad();
        await Future<void>.delayed(
          Duration(seconds: instance.pollingIntervalSeconds),
        );
      }
    });

final dashdotGpuLoadProvider = StreamProvider.autoDispose
    .family<dynamic, Instance>((ref, instance) async* {
      final api = await ref.watch(dashdotApiProvider(instance));
      while (true) {
        yield await api.getGpuLoad();
        await Future<void>.delayed(
          Duration(seconds: instance.pollingIntervalSeconds),
        );
      }
    });
