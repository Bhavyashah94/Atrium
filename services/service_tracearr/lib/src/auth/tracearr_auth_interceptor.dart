import 'package:dio/dio.dart';

import 'tracearr_auth_manager.dart';

/// Attaches the Tracearr API key to every request.
///
/// There is deliberately no refresh-and-retry here. The key is static, issued
/// from Tracearr's settings screen, so a 401 means the key is wrong or has
/// been regenerated. Replaying the same key would double every failed request
/// and still fail, and it would delay the error the user actually needs to
/// see. This also removes the reason the module used to keep a second Dio
/// purely to replay requests off.
class TracearrAuthInterceptor extends QueuedInterceptor {
  TracearrAuthInterceptor({required this.manager});

  final TracearrAuthManager manager;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    try {
      final String token = await manager.ensureToken();
      options.headers['Authorization'] = 'Bearer $token';
      options.headers['x-api-key'] = token;
      return handler.next(options);
    } catch (e, st) {
      return handler.reject(
        DioException(requestOptions: options, error: e, stackTrace: st),
      );
    }
  }
}
