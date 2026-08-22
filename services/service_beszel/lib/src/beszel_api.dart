import 'package:dio/dio.dart';

import 'models/beszel_container.dart';
import 'models/beszel_stats.dart';
import 'models/beszel_system.dart';
import 'models/beszel_systemd_service.dart';

class BeszelApi {
  BeszelApi(this._dio);

  final Dio _dio;

  Future<List<BeszelSystem>> getSystems() async {
    try {
      final Response<Map<String, dynamic>> response = await _dio
          .get<Map<String, dynamic>>('/api/collections/systems/records');
      final items = (response.data?['items'] as List<dynamic>?) ?? [];
      return items
          .map((e) => BeszelSystem.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<BeszelStats>> getSystemStats(
    String systemId, [
    ChartTime chartTime = ChartTime.hour1,
  ]) async {
    try {
      final filter = _buildTimeFilter('system', systemId, chartTime);
      final Response<Map<String, dynamic>> response = await _dio
          .get<Map<String, dynamic>>(
            '/api/collections/system_stats/records',
            queryParameters: {
              'filter': filter,
              'sort': '-created',
              'perPage': 2000,
            },
          );
      final items = (response.data?['items'] as List<dynamic>?) ?? [];

      return items.map((e) {
        final data = e as Map<String, dynamic>;
        final stats = data['stats'] as Map<String, dynamic>? ?? {};

        DateTime? created;
        if (data['created'] != null) {
          created = DateTime.tryParse(data['created'] as String);
        }

        // Parse disk I/O
        double diskReadIo = 0.0;
        double diskWriteIo = 0.0;
        if (stats['dio'] != null) {
          final dio = stats['dio'] as List<dynamic>;
          if (dio.isNotEmpty) diskReadIo = (dio[0] as num).toDouble();
          if (dio.length > 1) diskWriteIo = (dio[1] as num).toDouble();
        } else {
          diskReadIo = ((stats['dr'] as num?)?.toDouble() ?? 0.0) * 1024 * 1024;
          diskWriteIo =
              ((stats['dw'] as num?)?.toDouble() ?? 0.0) * 1024 * 1024;
        }

        // Parse bandwidth
        double networkSent = 0.0;
        double networkRecv = 0.0;
        if (stats['b'] != null) {
          final b = stats['b'] as List<dynamic>;
          if (b.isNotEmpty) networkSent = (b[0] as num).toDouble();
          if (b.length > 1) networkRecv = (b[1] as num).toDouble();
        } else {
          networkSent =
              ((stats['ns'] as num?)?.toDouble() ?? 0.0) * 1024 * 1024;
          networkRecv =
              ((stats['nr'] as num?)?.toDouble() ?? 0.0) * 1024 * 1024;
        }

        // Parse load average
        double loadAverage1m = 0.0;
        if (stats['la'] != null) {
          final la = stats['la'] as List<dynamic>;
          if (la.isNotEmpty) loadAverage1m = (la[0] as num).toDouble();
        }

        // Parse temperature
        double temperature = 0.0;
        if (stats['t'] != null) {
          final tempMap = stats['t'] as Map<String, dynamic>;
          for (final temp in tempMap.values) {
            final t = (temp as num).toDouble();
            if (t > temperature) temperature = t;
          }
        }

        // Parse GPU usage
        double gpuUsage = 0.0;
        if (stats['g'] != null) {
          final gpus = stats['g'] as Map<String, dynamic>;
          for (final gpu in gpus.values) {
            final gpuObj = gpu as Map<String, dynamic>;
            if (gpuObj['u'] != null) {
              final u = (gpuObj['u'] as num).toDouble();
              if (u > gpuUsage) gpuUsage = u;
            }
          }
        }

        return BeszelStats(
          cpuUsage: (stats['cpu'] as num?)?.toDouble() ?? 0.0,
          memoryUsage: (stats['mp'] as num?)?.toDouble() ?? 0.0,
          gpuUsage: gpuUsage,
          diskUsage: (stats['dp'] as num?)?.toDouble() ?? 0.0,
          diskReadIo: diskReadIo,
          diskWriteIo: diskWriteIo,
          networkSent: networkSent,
          networkRecv: networkRecv,
          swapUsage: (stats['su'] as num?)?.toDouble() ?? 0.0,
          loadAverage1m: loadAverage1m,
          temperature: temperature,
          created: created,
        );
      }).toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<BeszelContainer>> getContainers(String systemId) async {
    try {
      final Response<Map<String, dynamic>> response = await _dio
          .get<Map<String, dynamic>>(
            '/api/collections/containers/records',
            queryParameters: {'filter': "system='$systemId'", 'perPage': 2000},
          );
      final items = (response.data?['items'] as List<dynamic>?) ?? [];
      return items
          .map((e) => BeszelContainer.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<BeszelStats>> getContainerStats(
    String systemId,
    String containerName, [
    ChartTime chartTime = ChartTime.hour1,
  ]) async {
    try {
      final filter = _buildTimeFilter('system', systemId, chartTime);
      final Response<Map<String, dynamic>> response = await _dio
          .get<Map<String, dynamic>>(
            '/api/collections/container_stats/records',
            queryParameters: {
              'filter': filter,
              'sort': '-created',
              'perPage': 2000,
            },
          );
      final items = (response.data?['items'] as List<dynamic>?) ?? [];

      final result = <BeszelStats>[];
      for (final e in items) {
        final data = e as Map<String, dynamic>;
        final statsList = data['stats'] as List<dynamic>? ?? [];

        final containerStatObj = statsList.firstWhere(
          (s) => (s as Map<String, dynamic>)['n'] == containerName,
          orElse: () => null,
        );

        if (containerStatObj == null) continue;

        final stats = containerStatObj as Map<String, dynamic>;

        DateTime? created;
        if (data['created'] != null) {
          created = DateTime.tryParse(data['created'] as String);
        }

        result.add(
          BeszelStats(
            cpuUsage: (stats['c'] as num?)?.toDouble() ?? 0.0,
            memoryUsage:
                ((stats['m'] as num?)?.toDouble() ?? 0.0) *
                1024, // Convert GB to MB
            created: created,
          ),
        );
      }
      return result;
    } catch (e) {
      return [];
    }
  }

  Future<List<BeszelSystemdService>> getSystemdServices(String systemId) async {
    try {
      final Response<Map<String, dynamic>> response = await _dio
          .get<Map<String, dynamic>>(
            '/api/collections/systemd_services/records',
            queryParameters: {'filter': "system='$systemId'", 'perPage': 2000},
          );
      final items = (response.data?['items'] as List<dynamic>?) ?? [];
      return items
          .map((e) => BeszelSystemdService.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getAllContainerStats(
    String systemId, [
    ChartTime chartTime = ChartTime.hour1,
  ]) async {
    try {
      final filter = _buildTimeFilter('system', systemId, chartTime);
      final Response<Map<String, dynamic>> response = await _dio
          .get<Map<String, dynamic>>(
            '/api/collections/container_stats/records',
            queryParameters: {
              'filter': filter,
              'sort': '-created',
              'perPage': 2000,
            },
          );
      final items = (response.data?['items'] as List<dynamic>?) ?? [];
      return items.map((e) => e as Map<String, dynamic>).toList();
    } catch (e) {
      return [];
    }
  }

  String _buildTimeFilter(
    String entityField,
    String entityId,
    ChartTime chartTime,
  ) {
    final now = DateTime.now().toUtc();
    late DateTime createdGt;
    late String type;

    switch (chartTime) {
      case ChartTime.hour1:
        createdGt = now.subtract(const Duration(hours: 1));
        type = '1m';
        break;
      case ChartTime.hour12:
        createdGt = now.subtract(const Duration(hours: 12));
        type = '10m';
        break;
      case ChartTime.hour24:
        createdGt = now.subtract(const Duration(hours: 24));
        type = '20m';
        break;
      case ChartTime.week1:
        createdGt = now.subtract(const Duration(days: 7));
        type = '120m';
        break;
      case ChartTime.month1:
        createdGt = now.subtract(const Duration(days: 30));
        type = '480m';
        break;
    }

    // Format for PocketBase filter: "yyyy-MM-dd HH:mm:ss.000Z"
    final createdStr = createdGt.toIso8601String().replaceFirst('T', ' ');
    return "$entityField='$entityId' && created > '$createdStr' && type='$type'";
  }
}
