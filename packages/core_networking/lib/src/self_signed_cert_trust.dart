import 'dart:io';

import 'package:core_models/core_models.dart';

/// Registry of hosts whose self-signed TLS certificates are explicitly trusted.
///
/// Dio clients created through `DioFactory` configure their own certificate
/// callback per instance. Network images, posters and backdrops, however, are
/// fetched outside Dio (via `CachedNetworkImage` and `Image.network`) using
/// standard `HttpClient` instances. Behind an instance that uses a self-signed
/// certificate, those image requests fail TLS validation silently unless
/// intercepted.
///
/// [AtriumHttpOverrides] queries this registry to allow bad certificates only
/// for hosts explicitly configured with [Instance.allowSelfSignedCerts].
abstract final class SelfSignedCertTrust {
  static Set<String> _selfSignedHosts = const <String>{};

  /// Updates the trusted hosts from [instances].
  static void update(Iterable<Instance> instances) {
    final Set<String> hosts = <String>{};
    for (final Instance instance in instances) {
      if (!instance.allowSelfSignedCerts) {
        continue;
      }
      for (final String raw in <String>[
        instance.localUrl,
        instance.externalUrl,
      ]) {
        final Uri? uri = _tryParse(raw);
        if (uri != null && uri.host.isNotEmpty) {
          final String host = uri.host.toLowerCase();
          hosts.add(host);
          if (uri.hasPort) {
            hosts.add('$host:${uri.port}');
          }
        }
      }
    }
    _selfSignedHosts = hosts;
  }

  /// Checks whether [host] (and optionally [port]) is allowed to use a
  /// self-signed certificate.
  static bool allows({required String host, int? port}) {
    if (_selfSignedHosts.isEmpty) {
      return false;
    }
    final String normalizedHost = host.toLowerCase().trim();
    if (_selfSignedHosts.contains(normalizedHost)) {
      return true;
    }
    if (port != null && _selfSignedHosts.contains('$normalizedHost:$port')) {
      return true;
    }
    return false;
  }

  /// Checks whether the host of [url] is allowed to use a self-signed
  /// certificate.
  static bool allowsUrl(String? url) {
    if (url == null || url.trim().isEmpty) {
      return false;
    }
    final Uri? uri = _tryParse(url);
    if (uri == null || uri.host.isEmpty) {
      return false;
    }
    return allows(host: uri.host, port: uri.hasPort ? uri.port : null);
  }

  /// Clears the registry. Only for tests.
  static void reset() => _selfSignedHosts = const <String>{};

  static Uri? _tryParse(String raw) {
    String trimmed = raw.trim();
    if (trimmed.isEmpty) {
      return null;
    }
    if (!trimmed.contains('://')) {
      trimmed = 'https://$trimmed';
    }
    try {
      final Uri uri = Uri.parse(trimmed);
      if (uri.host.isEmpty) {
        return null;
      }
      return uri;
    } on FormatException {
      return null;
    }
  }
}

/// Global [HttpOverrides] that permits self-signed TLS certificates for hosts
/// registered in [SelfSignedCertTrust].
class AtriumHttpOverrides extends HttpOverrides {
  AtriumHttpOverrides();

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    final HttpClient client = super.createHttpClient(context);
    client.badCertificateCallback =
        (X509Certificate cert, String host, int port) {
      return SelfSignedCertTrust.allows(host: host, port: port);
    };
    return client;
  }
}
