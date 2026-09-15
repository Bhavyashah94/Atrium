import 'package:core_models/core_models.dart';
import 'package:core_networking/core_networking.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'gluetun_api.dart';
import 'models/gluetun_models.dart';

final gluetunApiProvider =
    FutureProvider.family<GluetunApi, Instance>((ref, instance) async {
  final factory = ref.watch(dioFactoryProvider);
  final dio = await factory.create(instance);
  return GluetunApi(dio);
});

final gluetunVpnStatusProvider = FutureProvider.autoDispose
    .family<GluetunVpnStatus, Instance>((ref, instance) async {
  ref.pollEvery(Duration(seconds: instance.pollingIntervalSeconds));
  final api = await ref.watch(gluetunApiProvider(instance).future);
  return api.getVpnStatus();
});

final gluetunVpnSettingsProvider = FutureProvider.autoDispose
    .family<GluetunVpnSettings?, Instance>((ref, instance) async {
  ref.pollEvery(Duration(seconds: instance.pollingIntervalSeconds * 2));
  final api = await ref.watch(gluetunApiProvider(instance).future);
  return api.getVpnSettings();
});

final gluetunPublicIpProvider = FutureProvider.autoDispose
    .family<GluetunPublicIp?, Instance>((ref, instance) async {
  ref.pollEvery(Duration(seconds: instance.pollingIntervalSeconds));
  final api = await ref.watch(gluetunApiProvider(instance).future);
  return api.getPublicIp();
});

final gluetunPortForwardProvider = FutureProvider.autoDispose
    .family<GluetunPortForward?, Instance>((ref, instance) async {
  ref.pollEvery(Duration(seconds: instance.pollingIntervalSeconds));
  final api = await ref.watch(gluetunApiProvider(instance).future);
  return api.getPortForward();
});

final gluetunDnsStatusProvider = FutureProvider.autoDispose
    .family<GluetunDnsStatus?, Instance>((ref, instance) async {
  ref.pollEvery(Duration(seconds: instance.pollingIntervalSeconds));
  final api = await ref.watch(gluetunApiProvider(instance).future);
  return api.getDnsStatus();
});

final gluetunUpdaterStatusProvider = FutureProvider.autoDispose
    .family<GluetunUpdaterStatus?, Instance>((ref, instance) async {
  ref.pollEvery(Duration(seconds: instance.pollingIntervalSeconds * 2));
  final api = await ref.watch(gluetunApiProvider(instance).future);
  return api.getUpdaterStatus();
});
