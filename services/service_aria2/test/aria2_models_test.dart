import 'package:flutter_test/flutter_test.dart';
import 'package:service_aria2/service_aria2.dart';

void main() {
  group('aria2Int', () {
    test('reads the string form aria2 sends', () {
      expect(aria2Int('1234'), 1234);
      expect(aria2Int('0'), 0);
      expect(aria2Int('-5'), -5);
    });

    test('accepts a real number too', () {
      expect(aria2Int(42), 42);
      expect(aria2Int(4.9), 4);
    });

    test('falls back to 0 for anything else', () {
      expect(aria2Int(null), 0);
      expect(aria2Int('not a number'), 0);
      expect(aria2Int(<String>[]), 0);
    });
  });

  group('aria2Bool', () {
    test('reads the string form aria2 sends', () {
      expect(aria2Bool('true'), isTrue);
      expect(aria2Bool('false'), isFalse);
    });

    test('accepts a real bool too', () {
      expect(aria2Bool(true), isTrue);
      expect(aria2Bool(false), isFalse);
    });

    test('anything else is false', () {
      expect(aria2Bool(null), isFalse);
      expect(aria2Bool('yes'), isFalse);
    });
  });

  test('aria2BaseName handles both path separators', () {
    expect(aria2BaseName('/downloads/big.iso'), 'big.iso');
    expect(aria2BaseName(r'C:\downloads\big.iso'), 'big.iso');
    expect(aria2BaseName('big.iso'), 'big.iso');
    expect(aria2BaseName(''), '');
  });

  test('Aria2Download reads the string numbers aria2 sends', () {
    final Aria2Download download = Aria2Download.fromJson(<String, dynamic>{
      'gid': '2089b05ecca3d829',
      'status': 'active',
      'totalLength': '1000',
      'completedLength': '250',
      'downloadSpeed': '100',
      'seeder': 'false',
    });

    expect(download.gid, '2089b05ecca3d829');
    expect(download.totalLength, 1000);
    expect(download.completedLength, 250);
    expect(download.downloadSpeed, 100);
    expect(download.seeder, isFalse);
    expect(download.progress, closeTo(0.25, 0.001));
    expect(download.remainingLength, 750);
    expect(download.isActive, isTrue);
    expect(download.isLive, isTrue);
    expect(download.isStopped, isFalse);
    expect(download.etaSeconds, 7);
  });

  test('a download with no length yet is not "done"', () {
    // A magnet that has not fetched its metadata reports a total of 0.
    final Aria2Download download = Aria2Download.fromJson(<String, dynamic>{
      'gid': 'abc',
      'status': 'waiting',
    });
    expect(download.progress, 0);
    expect(download.etaSeconds, isNull);
    expect(download.isWaiting, isTrue);
    expect(download.displayName, 'abc');
  });

  test('the display name prefers the torrent name, then the file name', () {
    final Aria2Download torrent = Aria2Download.fromJson(<String, dynamic>{
      'gid': 'abc',
      'bittorrent': <String, dynamic>{
        'info': <String, dynamic>{'name': 'Debian ISO'},
      },
      'files': <dynamic>[
        <String, dynamic>{'path': '/downloads/debian.iso'},
      ],
    });
    expect(torrent.displayName, 'Debian ISO');

    final Aria2Download http = Aria2Download.fromJson(<String, dynamic>{
      'gid': 'abc',
      'files': <dynamic>[
        <String, dynamic>{'path': '/downloads/big.iso'},
      ],
    });
    expect(http.displayName, 'big.iso');
  });

  test('aria2FmtBytes reads the sizes a daemon reports', () {
    expect(aria2FmtBytes(0), '0 B');
    expect(aria2FmtBytes(512), '512 B');
    expect(aria2FmtBytes(1536), '1.5 KB');
    expect(aria2FmtBytes(1024 * 1024), '1.0 MB');
    expect(aria2FmtBytes(3.2 * 1024 * 1024 * 1024), '3.2 GB');
  });

  test('aria2FormatEta reads as a human duration', () {
    expect(aria2FormatEta(0), '0s');
    expect(aria2FormatEta(45), '45s');
    expect(aria2FormatEta(200), '3m 20s');
    expect(aria2FormatEta(3600), '1h');
    expect(aria2FormatEta(7500), '2h 5m');
  });

  test('Aria2Peer clientName decodes Azureus prefix and handles binary IDs', () {
    const Aria2Peer qb = Aria2Peer(peerId: '-qB4650-abcdef123456');
    expect(qb.clientName, 'qBittorrent 4.6.5.0');

    const Aria2Peer tr = Aria2Peer(peerId: '-TR3000-xyz987654321');
    expect(tr.clientName, 'Transmission 3.0.0.0');

    // Binary peer ID with unescaped percent sign that would throw in Uri.decodeComponent
    const Aria2Peer binary = Aria2Peer(peerId: '%E4%B8%AD%stray%');
    expect(binary.clientName, isNotEmpty);
    expect(binary.clientName.contains('%stray%'), isTrue);

    const Aria2Peer unknown = Aria2Peer(ip: '192.168.1.50');
    expect(unknown.clientName, 'Unknown Peer');
  });

  test('aria2StatusLabel names the statuses the daemon sends', () {
    expect(aria2StatusLabel('active'), 'Downloading');
    expect(aria2StatusLabel('waiting'), 'Queued');
    expect(aria2StatusLabel('paused'), 'Paused');
    expect(aria2StatusLabel('complete'), 'Complete');
    expect(aria2StatusLabel('error'), 'Error');
    expect(aria2StatusLabel(''), 'Unknown');
  });
}
