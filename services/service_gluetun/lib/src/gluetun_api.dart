import 'dart:convert';

import 'package:dio/dio.dart';

import 'models/gluetun_models.dart';

/// REST client for the Gluetun HTTP control server API.
class GluetunApi {
  const GluetunApi(this._dio);

  final Dio _dio;

  Map<String, dynamic>? _toMap(dynamic data) {
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }
    if (data is String && data.trim().isNotEmpty) {
      try {
        final dynamic decoded = jsonDecode(data);
        if (decoded is Map) {
          return Map<String, dynamic>.from(decoded);
        }
      } catch (_) {}
    }
    return null;
  }

  /// Fetches the current VPN status (e.g. running, stopped).
  Future<GluetunVpnStatus> getVpnStatus() async {
    final Response<dynamic> resp = await _dio.get<dynamic>('v1/vpn/status');
    final Map<String, dynamic>? map = _toMap(resp.data);
    if (map != null) {
      return GluetunVpnStatus.fromJson(map);
    }
    throw DioException(
      requestOptions: resp.requestOptions,
      error: 'Invalid response from Gluetun VPN status endpoint',
    );
  }

  /// Updates the VPN status ('running' to start, 'stopped' to stop).
  Future<GluetunVpnStatus> setVpnStatus({required bool run}) async {
    final Response<dynamic> resp = await _dio.put<dynamic>(
      'v1/vpn/status',
      data: <String, String>{'status': run ? 'running' : 'stopped'},
    );
    final Map<String, dynamic>? map = _toMap(resp.data);
    if (map != null) {
      return GluetunVpnStatus.fromJson(map);
    }
    return GluetunVpnStatus(status: run ? 'running' : 'stopped');
  }

  /// Fetches public IP details.
  Future<GluetunPublicIp?> getPublicIp() async {
    try {
      final Response<dynamic> resp = await _dio.get<dynamic>('v1/publicip/ip');
      final Map<String, dynamic>? map = _toMap(resp.data);
      if (map != null) {
        return GluetunPublicIp.fromJson(map);
      }
    } on DioException {
      return null;
    }
    return null;
  }

  /// Fetches port forwarding info.
  Future<GluetunPortForward?> getPortForward() async {
    try {
      final Response<dynamic> resp = await _dio.get<dynamic>('v1/portforward');
      final Map<String, dynamic>? map = _toMap(resp.data);
      if (map != null) {
        return GluetunPortForward.fromJson(map);
      }
    } on DioException {
      return null;
    }
    return null;
  }

  /// Fetches DNS server status.
  Future<GluetunDnsStatus?> getDnsStatus() async {
    try {
      final Response<dynamic> resp = await _dio.get<dynamic>('v1/dns/status');
      final Map<String, dynamic>? map = _toMap(resp.data);
      if (map != null) {
        return GluetunDnsStatus.fromJson(map);
      }
    } on DioException {
      return null;
    }
    return null;
  }

  /// Toggles DNS server status ('running' or 'stopped').
  Future<GluetunDnsStatus?> setDnsStatus({required bool run}) async {
    try {
      final Response<dynamic> resp = await _dio.put<dynamic>(
        'v1/dns/status',
        data: <String, String>{'status': run ? 'running' : 'stopped'},
      );
      final Map<String, dynamic>? map = _toMap(resp.data);
      if (map != null) {
        return GluetunDnsStatus.fromJson(map);
      }
    } on DioException {
      return null;
    }
    return GluetunDnsStatus(status: run ? 'running' : 'stopped');
  }

  /// Fetches server database updater status.
  Future<GluetunUpdaterStatus?> getUpdaterStatus() async {
    try {
      final Response<dynamic> resp =
          await _dio.get<dynamic>('v1/updater/status');
      final Map<String, dynamic>? map = _toMap(resp.data);
      if (map != null) {
        return GluetunUpdaterStatus.fromJson(map);
      }
    } on DioException {
      return null;
    }
    return null;
  }

  /// Triggers the server database updater.
  Future<GluetunUpdaterStatus?> setUpdaterStatus({required bool run}) async {
    try {
      final Response<dynamic> resp = await _dio.put<dynamic>(
        'v1/updater/status',
        data: <String, String>{'status': run ? 'running' : 'stopped'},
      );
      final Map<String, dynamic>? map = _toMap(resp.data);
      if (map != null) {
        return GluetunUpdaterStatus.fromJson(map);
      }
    } on DioException {
      return null;
    }
    return GluetunUpdaterStatus(status: run ? 'running' : 'stopped');
  }
}
