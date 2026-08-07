import 'package:core_models/core_models.dart';
import 'package:core_networking/core_networking.dart';

/// Supplies the bearer token for Tracearr's public v2 API.
///
/// Tracearr issues an API key from its own settings screen, and that key is
/// what every `api/v2/public/*` call carries. Atrium used to sign in with the
/// user's actual Tracearr username and password and drive the internal v1
/// endpoints with the resulting session token; that is gone. The key works
/// whether the account signs in with a password, with Plex or through OIDC,
/// and it means Atrium no longer holds anybody's Tracearr password.
class TracearrAuthManager {
  TracearrAuthManager({required this.baseUrl, required this.auth});

  final Uri baseUrl;
  final InstanceAuth auth;

  /// The key to send, or null once cleared after a 401 so it is re-read.
  String? _token;

  /// Returns the API key to authenticate with.
  ///
  /// Throws rather than returning an empty string when the instance carries
  /// the wrong kind of credential: an empty bearer token would be sent
  /// anyway and come back as a puzzling 401, which is exactly the sort of
  /// misreported failure that made the previous auth bug so hard to find.
  Future<String> ensureToken() async {
    final String? cached = _token;
    if (cached != null) {
      return cached;
    }

    final InstanceAuth current = auth;
    if (current is! InstanceAuthApiKey) {
      throw NetworkAuthException(
        'Tracearr needs an API key. Generate one in Tracearr under Settings, '
        'then paste it into this instance. (Got ${current.runtimeType}.)',
      );
    }

    final String key = current.apiKey.trim();
    if (key.isEmpty) {
      throw const NetworkAuthException(
        'This Tracearr instance has no API key set. Generate one in Tracearr '
        'under Settings and paste it in.',
      );
    }

    _token = key;
    return key;
  }

  void clearToken() {
    _token = null;
  }
}
