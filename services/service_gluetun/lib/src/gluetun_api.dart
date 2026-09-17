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

  /// Starts or stops the VPN.
  ///
  /// Throws when Gluetun refuses; see [_put].
  Future<GluetunVpnStatus> setVpnStatus({required bool run}) async {
    await _put('v1/vpn/status', run: run);
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

  /// Starts or stops Gluetun's DNS server.
  ///
  /// Throws when Gluetun refuses; see [_put].
  Future<GluetunDnsStatus> setDnsStatus({required bool run}) async {
    await _put('v1/dns/status', run: run);
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

  /// Starts or stops the server list updater.
  ///
  /// Throws when Gluetun refuses; see [_put].
  Future<GluetunUpdaterStatus> setUpdaterStatus({required bool run}) async {
    await _put('v1/updater/status', run: run);
    return GluetunUpdaterStatus(status: run ? 'running' : 'stopped');
  }

  /// Sends a status change to one of Gluetun's control endpoints.
  ///
  /// Two things about these endpoints shape this. A refusal has to reach the
  /// caller: current Gluetun refuses any route its auth config does not grant,
  /// and catching that here used to turn a 401 into a success message on
  /// screen. And a successful change answers `{"outcome": "..."}`, not the
  /// status object the matching GET returns, so the reply carries nothing the
  /// status models can read; callers get back the state they asked for.
  Future<void> _put(String path, {required bool run}) =>
      _dio.put<dynamic>(
        path,
        data: <String, String>{'status': run ? 'running' : 'stopped'},
      );
}
