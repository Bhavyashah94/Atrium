import 'package:dio/dio.dart';
import 'models/dashdot_models.dart';

class DashdotApi {
  DashdotApi(this._dio);
  final Dio _dio;

  Future<DashdotInfo?> getInfo() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/info');
      if (response.data != null) {
        final data = response.data!;

        final rawCpu = data['cpu'] as Map<String, dynamic>? ?? {};
        final rawRam = data['ram'] as Map<String, dynamic>? ?? {};
        final rawStorage = data['storage'] as List<dynamic>? ?? [];
        final rawNetwork = data['network'] as Map<String, dynamic>? ?? {};
        final rawGpu = data['gpu'] as Map<String, dynamic>? ?? {};
        final rawOs = data['os'] as Map<String, dynamic>? ?? {};

        final mappedData = <String, dynamic>{
          'os': {
            'distro': rawOs['distro'],
            'release': rawOs['release'],
            'arch': rawOs['arch'],
            'uptime': rawOs['uptime'],
          },
          'cpu': {
            'cpu_brand': '${rawCpu['brand'] ?? ''} ${rawCpu['model'] ?? ''}'
                .trim(),
            'cores': rawCpu['cores'],
            'threads': rawCpu['threads'],
            'freq': rawCpu['frequency'],
          },
          'ram': {
            'total_capacity': rawRam['size'] != null
                ? ((rawRam['size'] / 1024 / 1024 / 1024) * 100).truncate() / 100
                : 0,
            'sticks': (rawRam['layout'] as List<dynamic>? ?? [])
                .map(
                  (stick) => {
                    'ram_brand': stick['brand'],
                    'type': stick['type'],
                    'frequency': stick['frequency'],
                  },
                )
                .toList(),
          },
          'storage': rawStorage
              .map((s) {
                final size = s['size'];
                final disks = s['disks'] as List<dynamic>? ?? [];
                return disks.map(
                  (disk) => {
                    'storage_brand': disk['brand'],
                    'device': disk['device'],
                    'type': disk['type'],
                    'capacity': size != null
                        ? ((size / 1024 / 1024 / 1024) * 100).truncate() / 100
                        : 0,
                  },
                );
              })
              .expand((e) => e)
              .toList(),
          'network': {
            'type': rawNetwork['type'],
            'interface_speed': rawNetwork['interfaceSpeed'],
            'down_MBps': rawNetwork['speedDown'] != null
                ? ((rawNetwork['speedDown'] / 1024 / 1024) * 100).truncate() /
                      100
                : 0,
            'up_MBps': rawNetwork['speedUp'] != null
                ? ((rawNetwork['speedUp'] / 1024 / 1024) * 100).truncate() / 100
                : 0,
          },
          'gpu': (rawGpu['layout'] as List<dynamic>? ?? [])
              .map(
                (g) => {
                  'name': '${g['brand']} ${g['model']}',
                  'memory': g['memory'],
                },
              )
              .toList(),
        };

        return DashdotInfo.fromJson(mappedData);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<DashdotConfig?> getConfig() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/config');
      if (response.data != null) {
        return DashdotConfig.fromJson(response.data!);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<dynamic> getCpuLoad() async {
    try {
      final response = await _dio.get<dynamic>('/load/cpu');
      return response.data;
    } catch (e) {
      return null;
    }
  }

  Future<dynamic> getRamLoad() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/load/ram');
      if (response.data != null) {
        final load = response.data!['load'];
        if (load != null) {
          return {'load': ((load / 1024 / 1024 / 1024) * 100).truncate() / 100};
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<dynamic> getStorageLoad() async {
    try {
      final response = await _dio.get<List<dynamic>>('/load/storage');
      if (response.data != null) {
        return response.data!.map((e) {
          if (e is num) {
            return e < 0 ? e : ((e / 1073741824) * 100).truncate() / 100;
          }
          return e;
        }).toList();
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<dynamic> getNetworkLoad() async {
    try {
      final response = await _dio.get<dynamic>('/load/network');
      final data = response.data;
      if (data != null && data is Map) {
        return {
          'up': data['up'],
          'down': data['down'],
          'up_Bps': data['up'],
          'down_Bps': data['down'],
          'up_MBps': data['up'],
          'down_MBps': data['down'],
        };
      }
      return data;
    } catch (_) {
      return null;
    }
  }

  Future<dynamic> getGpuLoad() async {
    try {
      final response = await _dio.get<dynamic>('/load/gpu');
      return response.data;
    } catch (e) {
      return null;
    }
  }
}
