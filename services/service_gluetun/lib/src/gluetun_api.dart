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
  ///
  /// Throws when Gluetun refuses, and when the answer is not Gluetun's JSON.
  /// That exception keeps the response, so a login page answering 200 can be
  /// told apart from a server that never answered.
  Future<GluetunVpnStatus> getVpnStatus() async {
    final Response<dynamic> resp = await _dio.get<dynamic>('v1/vpn/status');
    final Map<String, dynamic>? map = _toMap(resp.data);
    if (map != null) {
      return GluetunVpnStatus.fromJson(map);
    }
    throw DioException(
      requestOptions: resp.requestOptions,
      response: resp,
      type: DioExceptionType.badResponse,
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
  ///
  /// Throws when Gluetun refuses; see [_getMap].
  Future<GluetunPublicIp?> getPublicIp() async {
    final Map<String, dynamic>? map = await _getMap('v1/publicip/ip');
    return map == null ? null : GluetunPublicIp.fromJson(map);
  }

  /// Fetches port forwarding info.
  ///
  /// Throws when Gluetun refuses; see [_getMap].
  Future<GluetunPortForward?> getPortForward() async {
    final Map<String, dynamic>? map = await _getMap('v1/portforward');
    return map == null ? null : GluetunPortForward.fromJson(map);
  }

  /// Fetches DNS server status.
  ///
  /// Throws when Gluetun refuses; see [_getMap].
  Future<GluetunDnsStatus?> getDnsStatus() async {
    final Map<String, dynamic>? map = await _getMap('v1/dns/status');
    return map == null ? null : GluetunDnsStatus.fromJson(map);
  }

  /// Starts or stops Gluetun's DNS server.
  ///
  /// Throws when Gluetun refuses; see [_put].
  Future<GluetunDnsStatus> setDnsStatus({required bool run}) async {
    await _put('v1/dns/status', run: run);
    return GluetunDnsStatus(status: run ? 'running' : 'stopped');
  }

  /// Fetches server database updater status.
  ///
  /// Throws when Gluetun refuses; see [_getMap].
  Future<GluetunUpdaterStatus?> getUpdaterStatus() async {
    final Map<String, dynamic>? map = await _getMap('v1/updater/status');
    return map == null ? null : GluetunUpdaterStatus.fromJson(map);
  }

  /// Starts or stops the server list updater.
  ///
  /// Throws when Gluetun refuses; see [_put].
  Future<GluetunUpdaterStatus> setUpdaterStatus({required bool run}) async {
    await _put('v1/updater/status', run: run);
    return GluetunUpdaterStatus(status: run ? 'running' : 'stopped');
  }

  /// Reads one of Gluetun's endpoints as a JSON object, or null if it is not.
  ///
  /// A refusal or an unreachable server throws. Catching those here used to
  /// show a route the API key's role does not grant as a DNS server in state
  /// UNKNOWN, an IDLE updater, or a public IP check that was switched off,
  /// when Gluetun had simply said no.
  Future<Map<String, dynamic>?> _getMap(String path) async {
    final Response<dynamic> resp = await _dio.get<dynamic>(path);
    return _toMap(resp.data);
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
