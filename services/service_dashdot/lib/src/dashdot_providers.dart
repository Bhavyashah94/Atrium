import 'package:core_models/core_models.dart';
import 'package:core_networking/core_networking.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'dashdot_api.dart';
import 'models/dashdot_models.dart';

final dashdotApiProvider = Provider.family<Future<DashdotApi>, Instance>((ref, instance) async {
  final factory = ref.watch(dioFactoryProvider);
  return DashdotApi(await factory.create(instance));
});

final dashdotInfoProvider = FutureProvider.family<DashdotInfo?, Instance>((ref, instance) async {
  final api = await ref.watch(dashdotApiProvider(instance));
  return api.getInfo();
});

final dashdotConfigProvider = FutureProvider.family<DashdotConfig?, Instance>((ref, instance) async {
  final api = await ref.watch(dashdotApiProvider(instance));
  return api.getConfig();
});

final dashdotCpuLoadProvider = StreamProvider.family<dynamic, Instance>((ref, instance) async* {
  final api = await ref.watch(dashdotApiProvider(instance));
  while (true) {
    yield await api.getCpuLoad();
    await Future<void>.delayed(const Duration(seconds: 2));
  }
});

final dashdotRamLoadProvider = StreamProvider.family<dynamic, Instance>((ref, instance) async* {
  final api = await ref.watch(dashdotApiProvider(instance));
  while (true) {
    yield await api.getRamLoad();
    await Future<void>.delayed(const Duration(seconds: 2));
  }
});

final dashdotStorageLoadProvider = StreamProvider.family<dynamic, Instance>((ref, instance) async* {
  final api = await ref.watch(dashdotApiProvider(instance));
  while (true) {
    yield await api.getStorageLoad();
    await Future<void>.delayed(const Duration(seconds: 2));
  }
});

final dashdotNetworkLoadProvider = StreamProvider.family<dynamic, Instance>((ref, instance) async* {
  final api = await ref.watch(dashdotApiProvider(instance));
  while (true) {
    yield await api.getNetworkLoad();
    await Future<void>.delayed(const Duration(seconds: 2));
  }
});

final dashdotGpuLoadProvider = StreamProvider.family<dynamic, Instance>((ref, instance) async* {
  final api = await ref.watch(dashdotApiProvider(instance));
  while (true) {
    yield await api.getGpuLoad();
    await Future<void>.delayed(const Duration(seconds: 2));
  }
});
