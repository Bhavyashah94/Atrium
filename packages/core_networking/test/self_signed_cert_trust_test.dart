import 'dart:io';

import 'package:core_models/core_models.dart';
import 'package:core_networking/core_networking.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  tearDown(SelfSignedCertTrust.reset);

  Instance createInstance({
    required String id,
    required String localUrl,
    String externalUrl = '',
    bool allowSelfSignedCerts = false,
  }) =>
      Instance(
        id: id,
        name: id,
        kind: ServiceKind.sonarr,
        localUrl: localUrl,
        externalUrl: externalUrl,
        urlMode: UrlMode.auto,
        auth: const InstanceAuth.apiKey(apiKey: 'key'),
        allowSelfSignedCerts: allowSelfSignedCerts,
      );

  group('SelfSignedCertTrust', () {
    test('rejects all hosts when registry is empty', () {
      expect(SelfSignedCertTrust.allows(host: 'radarr.lan'), isFalse);
      expect(SelfSignedCertTrust.allows(host: '192.168.1.100', port: 7878), isFalse);
      expect(SelfSignedCertTrust.allowsUrl('https://radarr.lan/MediaCover/1.jpg'), isFalse);
    });

    test('ignores instances without allowSelfSignedCerts', () {
      final Instance inst = createInstance(
        id: 'sonarr',
        localUrl: 'https://sonarr.lan:8989',
      );

      SelfSignedCertTrust.update(<Instance>[inst]);

      expect(SelfSignedCertTrust.allows(host: 'sonarr.lan'), isFalse);
      expect(SelfSignedCertTrust.allows(host: 'sonarr.lan', port: 8989), isFalse);
      expect(SelfSignedCertTrust.allowsUrl('https://sonarr.lan:8989/MediaCover/1.jpg'), isFalse);
    });

    test('registers both local and external URLs for self-signed instances', () {
      final Instance inst = createInstance(
        id: 'radarr',
        localUrl: 'https://192.168.0.173:7878',
        externalUrl: 'https://radarr.home.net',
        allowSelfSignedCerts: true,
      );

      SelfSignedCertTrust.update(<Instance>[inst]);

      // Local IP and port
      expect(SelfSignedCertTrust.allows(host: '192.168.0.173'), isTrue);
      expect(SelfSignedCertTrust.allows(host: '192.168.0.173', port: 7878), isTrue);
      expect(SelfSignedCertTrust.allowsUrl('https://192.168.0.173:7878/MediaCover/1.jpg'), isTrue);

      // External hostname
      expect(SelfSignedCertTrust.allows(host: 'radarr.home.net'), isTrue);
      expect(SelfSignedCertTrust.allowsUrl('https://radarr.home.net/MediaCover/1.jpg'), isTrue);

      // Third-party hosts are never permitted
      expect(SelfSignedCertTrust.allows(host: 'image.tmdb.org'), isFalse);
      expect(SelfSignedCertTrust.allowsUrl('https://image.tmdb.org/t/p/w500/abc.jpg'), isFalse);
    });

    test('host matching is case-insensitive', () {
      final Instance inst = createInstance(
        id: 'jellyfin',
        localUrl: 'https://Jellyfin.Local:8096',
        allowSelfSignedCerts: true,
      );

      SelfSignedCertTrust.update(<Instance>[inst]);

      expect(SelfSignedCertTrust.allows(host: 'jellyfin.local'), isTrue);
      expect(SelfSignedCertTrust.allows(host: 'JELLYFIN.LOCAL'), isTrue);
      expect(SelfSignedCertTrust.allows(host: 'Jellyfin.Local', port: 8096), isTrue);
    });

    test('handles URLs without an explicit scheme', () {
      final Instance inst = createInstance(
        id: 'lidarr',
        localUrl: '10.0.0.5:8686',
        allowSelfSignedCerts: true,
      );

      SelfSignedCertTrust.update(<Instance>[inst]);

      expect(SelfSignedCertTrust.allows(host: '10.0.0.5'), isTrue);
      expect(SelfSignedCertTrust.allows(host: '10.0.0.5', port: 8686), isTrue);
      expect(SelfSignedCertTrust.allowsUrl('https://10.0.0.5:8686/api/v1/image'), isTrue);
    });

    test('reset clears all registered hosts', () {
      final Instance inst = createInstance(
        id: 'radarr',
        localUrl: 'https://radarr.lan',
        allowSelfSignedCerts: true,
      );

      SelfSignedCertTrust.update(<Instance>[inst]);
      expect(SelfSignedCertTrust.allows(host: 'radarr.lan'), isTrue);

      SelfSignedCertTrust.reset();
      expect(SelfSignedCertTrust.allows(host: 'radarr.lan'), isFalse);
    });
  });

  group('AtriumHttpOverrides', () {
    test('createHttpClient instantiates client configured with trust registry', () {
      final Instance inst = createInstance(
        id: 'radarr',
        localUrl: 'https://radarr.lan:7878',
        allowSelfSignedCerts: true,
      );
      SelfSignedCertTrust.update(<Instance>[inst]);

      final AtriumHttpOverrides overrides = AtriumHttpOverrides();
      final HttpClient client = overrides.createHttpClient(null);

      // Verify that createHttpClient produces an operational HttpClient instance
      expect(client, isA<HttpClient>());
      client.close();
    });
  });
}
