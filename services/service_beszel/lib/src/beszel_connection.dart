import 'package:core_models/core_models.dart';
import 'package:core_networking/core_networking.dart';
import 'package:dio/dio.dart';

/// Verifies that [auth] is accepted by the Beszel (PocketBase) server reachable
/// through [dio], throwing when it is not.
///
/// Beszel authenticates with a PocketBase password login that mints a session
/// token, so - like the other login-based services - the only way to know the
/// credentials are valid is to perform that login. A lightweight health probe
/// cannot: `GET /api/health` is public and answers 200 for anyone, which is why
/// the plain reachability check reported success even with a wrong password.
///
/// The normal data path ([beszelApiProvider]) deliberately swallows a failed
/// login so the dashboard can degrade gracefully; connection testing needs the
/// opposite, so this performs its own login and lets the failure surface.
///
/// Returns normally when the credentials work. Throws [NetworkAuthException]
/// when the server rejects them - PocketBase answers a wrong identity/password
/// with HTTP 400 (a validation error) rather than 401, so that is treated as a
/// credential failure too - and a mapped [NetworkException] for transport or
/// server errors.
Future<void> verifyBeszelConnection(Dio dio, InstanceAuth auth) async {
  if (auth is! InstanceAuthUserPass) {
    // Beszel is always user/pass; if no credentials are configured, prove the
    // token requirement by hitting an auth-gated collection instead.
    final Response<dynamic> resp = await dio.get<dynamic>(
      '/api/collections/systems/records',
      options: Options(validateStatus: (int? _) => true),
    );
    final int status = resp.statusCode ?? 0;
    if (status == 401 || status == 403) {
      throw const NetworkAuthException('Beszel requires a valid login.');
    }
    if (status < 200 || status >= 300) {
      throw NetworkBadResponseException(
        'Unexpected response from Beszel (HTTP $status).',
        status: status,
      );
    }
    return;
  }

  try {
    final Response<Map<String, dynamic>> resp = await dio
        .post<Map<String, dynamic>>(
          '/api/collections/users/auth-with-password',
          data: <String, String>{
            'identity': auth.username,
            'password': auth.password,
          },
        );
    final String? token = resp.data?['token'] as String?;
    if (token == null || token.isEmpty) {
      throw const NetworkAuthException(
        'Beszel accepted the request but returned no session token.',
      );
    }
  } on DioException catch (e) {
    final int? status = e.response?.statusCode;
    // PocketBase rejects a wrong identity/password with 400, and gates other
    // resources with 401/403 - all three mean the login did not succeed.
    if (status == 400 || status == 401 || status == 403) {
      throw const NetworkAuthException(
        'Beszel rejected the email or password.',
      );
    }
    throw NetworkException.fromDio(e);
  }
}
