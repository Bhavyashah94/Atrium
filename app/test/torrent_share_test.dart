import 'dart:typed_data';

import 'package:core_models/core_models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:atrium/src/share_intake/torrent_share.dart';
import 'package:atrium/src/share_intake/torrent_share_listener.dart';

Instance _instance(ServiceKind kind, {String? name}) => Instance(
      id: 'test-${kind.name}',
      name: name ?? 'Test ${kind.displayName}',
      kind: kind,
      localUrl: 'http://localhost',
      externalUrl: '',
      urlMode: UrlMode.auto,
      auth: const InstanceAuth.apiKey(apiKey: 'k'),
    );

void main() {
  group('extractTorrentUri', () {
    test('finds a bare magnet', () {
      expect(
        extractTorrentUri('magnet:?xt=urn:btih:abc123'),
        'magnet:?xt=urn:btih:abc123',
      );
    });

    test('finds a magnet buried in shared text', () {
      // What a browser or tracker app actually sends: a title, then the link.
      expect(
        extractTorrentUri('Some Release Name\nmagnet:?xt=urn:btih:abc123'),
        'magnet:?xt=urn:btih:abc123',
      );
    });

    test('stops the magnet at whitespace', () {
      expect(
        extractTorrentUri('magnet:?xt=urn:btih:abc123 shared via Example'),
        'magnet:?xt=urn:btih:abc123',
      );
    });

    test('finds an http link to a .torrent', () {
      expect(
        extractTorrentUri('Grab it: https://example.org/files/x.torrent'),
        'https://example.org/files/x.torrent',
      );
    });

    test('prefers a magnet over a .torrent link', () {
      expect(
        extractTorrentUri(
          'https://example.org/x.torrent magnet:?xt=urn:btih:abc',
        ),
        'magnet:?xt=urn:btih:abc',
      );
    });

    test('takes the first of several magnets in one blob', () {
      // Documented behaviour, not an accident: sharing several at once is rare,
      // and sharing them one at a time queues and adds each in turn.
      expect(
        extractTorrentUri(
          'magnet:?xt=urn:btih:aaa\nmagnet:?xt=urn:btih:bbb',
        ),
        'magnet:?xt=urn:btih:aaa',
      );
    });

    test('rejects a page link that is not a torrent', () {
      expect(extractTorrentUri('https://example.org/browse/1234'), isNull);
    });

    test('rejects plain text and empty input', () {
      expect(extractTorrentUri('just some words'), isNull);
      expect(extractTorrentUri('   '), isNull);
    });
  });

  group('decodeTorrentShare', () {
    test('decodes a magnet payload', () {
      final TorrentShare? share = decodeTorrentShare(
        <Object?, Object?>{'kind': 'magnet', 'uri': 'magnet:?xt=urn:btih:a'},
      );
      expect(share, isA<TorrentShareLink>());
      expect((share! as TorrentShareLink).uri, 'magnet:?xt=urn:btih:a');
      expect((share as TorrentShareLink).isMagnet, isTrue);
    });

    test('decodes a file payload with its name', () {
      final TorrentShare? share = decodeTorrentShare(<Object?, Object?>{
        'kind': 'file',
        'name': 'ubuntu.torrent',
        'bytes': Uint8List.fromList(<int>[1, 2, 3]),
      });
      expect(share, isA<TorrentShareFile>());
      final TorrentShareFile file = share! as TorrentShareFile;
      expect(file.name, 'ubuntu.torrent');
      expect(file.bytes, <int>[1, 2, 3]);
    });

    test('turns shared text into a link', () {
      expect(
        decodeTorrentShare(<Object?, Object?>{
          'kind': 'text',
          'value': 'look: magnet:?xt=urn:btih:z',
        }),
        const TorrentShareLink('magnet:?xt=urn:btih:z'),
      );
    });

    test('reports text that holds no torrent', () {
      expect(
        decodeTorrentShare(
          <Object?, Object?>{'kind': 'text', 'value': 'hello there'},
        ),
        isA<TorrentShareProblem>(),
      );
    });

    test('reports the empty and oversized cases', () {
      expect(
        decodeTorrentShare(<Object?, Object?>{'kind': 'empty'}),
        isA<TorrentShareProblem>(),
      );
      expect(
        decodeTorrentShare(<Object?, Object?>{'kind': 'tooLarge'}),
        isA<TorrentShareProblem>(),
      );
    });

    test('reports a file it was not allowed to read', () {
      // A share whose read grant did not cover the URI must say so. Silently
      // dropping it left the user watching Atrium open and do nothing.
      expect(
        decodeTorrentShare(<Object?, Object?>{'kind': 'unreadable'}),
        isA<TorrentShareProblem>(),
      );
    });

    test('returns null for a plain launch and for malformed payloads', () {
      // A launcher tap must raise nothing at all in the UI.
      expect(decodeTorrentShare(null), isNull);
      expect(decodeTorrentShare('not a map'), isNull);
      expect(decodeTorrentShare(<Object?, Object?>{'kind': 'nonsense'}), isNull);
      expect(decodeTorrentShare(<Object?, Object?>{'kind': 'magnet'}), isNull);
      expect(
        decodeTorrentShare(<Object?, Object?>{'kind': 'magnet', 'uri': '  '}),
        isNull,
      );
      expect(
        decodeTorrentShare(<Object?, Object?>{
          'kind': 'file',
          'bytes': Uint8List(0),
        }),
        isNull,
      );
    });
  });

  group('torrentTargets', () {
    test('keeps the four torrent clients', () {
      final List<Instance> targets = torrentTargets(<Instance>[
        _instance(ServiceKind.qbittorrent),
        _instance(ServiceKind.deluge),
        _instance(ServiceKind.transmission),
        _instance(ServiceKind.rtorrent),
      ]);
      expect(targets, hasLength(4));
    });

    test('drops the Usenet downloaders and everything else', () {
      // SABnzbd and NZBGet share ServiceRole.downloader but take .nzb, so
      // offering them as a torrent target would be a dead end.
      final List<Instance> targets = torrentTargets(<Instance>[
        _instance(ServiceKind.sabnzbd),
        _instance(ServiceKind.nzbget),
        _instance(ServiceKind.sonarr),
        _instance(ServiceKind.plex),
        _instance(ServiceKind.qbittorrent),
      ]);
      expect(targets, hasLength(1));
      expect(targets.single.kind, ServiceKind.qbittorrent);
    });

    test('is empty when nothing can take a torrent', () {
      expect(
        torrentTargets(<Instance>[
          _instance(ServiceKind.sonarr),
          _instance(ServiceKind.sabnzbd),
        ]),
        isEmpty,
      );
    });
  });

  group('ServiceKind.acceptsTorrents', () {
    test('is true for exactly the torrent clients', () {
      final Set<ServiceKind> accepting = ServiceKind.values
          .where((ServiceKind k) => k.acceptsTorrents)
          .toSet();
      expect(accepting, <ServiceKind>{
        ServiceKind.qbittorrent,
        ServiceKind.deluge,
        ServiceKind.transmission,
        ServiceKind.rtorrent,
      });
    });
  });
}
