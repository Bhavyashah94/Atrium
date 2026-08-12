import 'package:dio/dio.dart';
import 'models/dashdot_models.dart';

class DashdotApi {
  DashdotApi(this._dio);
  final Dio _dio;

  Future<DashdotInfo?> getInfo() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/info');
      if (response.data != null) {
        return DashdotInfo.fromJson(response.data!);
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

  Future<Map<String, dynamic>?> getCpuLoad() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/load/cpu');
      return response.data;
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> getRamLoad() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/load/ram');
      return response.data;
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> getStorageLoad() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/load/storage');
      return response.data;
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> getNetworkLoad() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/load/network');
      return response.data;
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> getGpuLoad() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/load/gpu');
      return response.data;
    } catch (e) {
      return null;
    }
  }
}
