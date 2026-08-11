import 'package:core_models/core_models.dart';
import 'package:core_networking/core_networking.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'beszel_api.dart';
import 'models/beszel_stats.dart';
import 'models/beszel_system.dart';
import 'models/beszel_container.dart';
import 'models/beszel_systemd_service.dart';

final beszelChartTimeProvider = StateProvider<ChartTime>((ref) => ChartTime.hour1);

Duration _getChartPollInterval(ChartTime chartTime) {
  switch (chartTime) {
    case ChartTime.hour1:
      return const Duration(minutes: 1);
    case ChartTime.hour12:
      return const Duration(minutes: 10);
    case ChartTime.hour24:
      return const Duration(minutes: 20);
    case ChartTime.week1:
      return const Duration(minutes: 120);
    case ChartTime.month1:
      return const Duration(minutes: 480);
  }
}

final beszelApiProvider = Provider.family<Future<BeszelApi>, Instance>(
    (Ref ref, Instance instance) async {
  final DioFactory factory = ref.watch(dioFactoryProvider);
  final dio = await factory.create(instance);
  
  if (instance.auth is InstanceAuthUserPass) {
    final creds = instance.auth as InstanceAuthUserPass;
    try {
      final loginResp = await dio.post<dynamic>(
        '/api/collections/users/auth-with-password',
        data: {
          'identity': creds.username,
          'password': creds.password,
        },
      );
      final token = loginResp.data['token'] as String?;
      if (token != null && token.isNotEmpty) {
        dio.options.headers['Authorization'] = 'Bearer $token';
      }
    } catch (_) {
      // Allow it to fail gracefully or let the next request 401
    }
  }

  return BeszelApi(dio);
});

final beszelSystemsProvider = FutureProvider.autoDispose
    .family<List<BeszelSystem>, Instance>((Ref ref, Instance instance) async {
  ref.pollEvery(Duration(seconds: instance.pollingIntervalSeconds));
  final BeszelApi api = await ref.watch(beszelApiProvider(instance));
  return api.getSystems();
});

final beszelSystemStatsProvider = FutureProvider.autoDispose
    .family<List<BeszelStats>, ({Instance instance, String systemId, ChartTime chartTime})>(
        (Ref ref, args) async {
  ref.pollEvery(_getChartPollInterval(args.chartTime));
  final BeszelApi api = await ref.watch(beszelApiProvider(args.instance));
  final systemStats = await api.getSystemStats(args.systemId, args.chartTime);
  final containerStatsRaw = await api.getAllContainerStats(args.systemId, args.chartTime);
  // Parse container stats into a structured list
  final parsedContainerStats = <({int createdTimeMs, double cpu, double mem, double netSent, double netRecv})>[];
  
  for (final data in containerStatsRaw) {
    if (data['created'] == null) continue;
    final createdTime = DateTime.tryParse(data['created'] as String);
    if (createdTime == null) continue;
    
    final statsList = data['stats'] as List<dynamic>? ?? [];
    
    double totalCpu = 0;
    double totalMem = 0;
    double totalNetSent = 0;
    double totalNetRecv = 0;

    for (final containerStat in statsList) {
      final s = containerStat as Map<String, dynamic>;
      totalCpu += (s['c'] as num?)?.toDouble() ?? 0.0;
      totalMem += (s['m'] as num?)?.toDouble() ?? 0.0;
      
      if (s['b'] != null) {
        final b = s['b'] as List<dynamic>;
        if (b.isNotEmpty) totalNetSent += (b[0] as num).toDouble();
        if (b.length > 1) totalNetRecv += (b[1] as num).toDouble();
      } else {
        totalNetSent += ((s['ns'] as num?)?.toDouble() ?? 0.0) * 1024 * 1024;
        totalNetRecv += ((s['nr'] as num?)?.toDouble() ?? 0.0) * 1024 * 1024;
      }
    }
    
    parsedContainerStats.add((
      createdTimeMs: createdTime.millisecondsSinceEpoch, 
      cpu: totalCpu, 
      mem: totalMem, 
      netSent: totalNetSent, 
      netRecv: totalNetRecv
    ));
  }

  // Merge the aggregate container stats into systemStats using a 10-second time window
  return systemStats.map((sys) {
    if (sys.created == null) return sys;
    final sysCreatedMs = sys.created!.millisecondsSinceEpoch;
    
    // Find closest container stat within 10 seconds
    var closestDiff = double.infinity;
    ({int createdTimeMs, double cpu, double mem, double netSent, double netRecv})? closestAgg;
    
    for (final agg in parsedContainerStats) {
      final diff = (agg.createdTimeMs - sysCreatedMs).abs().toDouble();
      if (diff < 10000 && diff < closestDiff) {
        closestDiff = diff;
        closestAgg = agg;
      }
    }

    if (closestAgg != null) {
      return sys.copyWith(
        dockerCpu: closestAgg.cpu,
        dockerMemory: closestAgg.mem,
        dockerNetSent: closestAgg.netSent,
        dockerNetRecv: closestAgg.netRecv,
      );
    }
    return sys;
  }).toList();
});

final beszelContainersProvider = FutureProvider.autoDispose
    .family<List<BeszelContainer>, ({Instance instance, String systemId})>(
        (Ref ref, args) async {
  ref.pollEvery(Duration(seconds: args.instance.pollingIntervalSeconds));
  final BeszelApi api = await ref.watch(beszelApiProvider(args.instance));
  return api.getContainers(args.systemId);
});

final beszelContainerStatsProvider = FutureProvider.autoDispose
    .family<List<BeszelStats>, ({Instance instance, String systemId, String containerName, ChartTime chartTime})>(
        (Ref ref, args) async {
  ref.pollEvery(_getChartPollInterval(args.chartTime));
  final BeszelApi api = await ref.watch(beszelApiProvider(args.instance));
  return api.getContainerStats(args.systemId, args.containerName, args.chartTime);
});

final beszelSystemdServicesProvider = FutureProvider.autoDispose
    .family<List<BeszelSystemdService>, ({Instance instance, String systemId})>(
        (Ref ref, args) async {
  ref.pollEvery(Duration(seconds: args.instance.pollingIntervalSeconds));
  final BeszelApi api = await ref.watch(beszelApiProvider(args.instance));
  return api.getSystemdServices(args.systemId);
});
