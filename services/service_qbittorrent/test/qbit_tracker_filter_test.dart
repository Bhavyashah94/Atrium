import 'package:flutter_test/flutter_test.dart';
import 'package:service_qbittorrent/service_qbittorrent.dart';

QbitTorrent _t(String tracker) =>
    QbitTorrent(hash: 'h', name: 'n', state: 'downloading', tracker: tracker);

void main() {
  group('qbitTrackerHost', () {
    test('keeps only the host from an http announce URL', () {
      expect(
        qbitTrackerHost('https://tracker.example.org:443/announce'),
        'tracker.example.org',
      );
    });

    test('handles udp trackers', () {
      expect(
        qbitTrackerHost('udp://open.demonii.com:1337/announce'),
        'open.demonii.com',
      );
    });

    test('never leaks a private tracker passkey', () {
      const String url =
          'https://private.example.org/abcdef0123456789passkey/announce';
      final String host = qbitTrackerHost(url);
      expect(host, 'private.example.org');
      expect(host, isNot(contains('passkey')));
      expect(host, isNot(contains('abcdef0123456789')));
    });

    test('strips a passkey carried as a query parameter too', () {
      final String host = qbitTrackerHost(
        'https://private.example.org/announce?passkey=SECRETVALUE',
      );
      expect(host, 'private.example.org');
      expect(host, isNot(contains('SECRETVALUE')));
    });

    test('lowercases the host so one tracker is one bucket', () {
      expect(
        qbitTrackerHost('https://Tracker.EXAMPLE.org/announce'),
        'tracker.example.org',
      );
    });

    test('empty and unparseable values collapse to empty', () {
      expect(qbitTrackerHost(''), '');
      expect(qbitTrackerHost('   '), '');
      expect(qbitTrackerHost('not a url at all'), '');
    });
  });

  group('qbitTrackerMatches', () {
    test('matches a torrent to its own host', () {
      final QbitTorrent t = _t('https://tracker.example.org/announce');
      expect(qbitTrackerMatches('tracker.example.org', t), isTrue);
      expect(qbitTrackerMatches('other.example.org', t), isFalse);
    });

    test('the none bucket holds torrents with no working tracker', () {
      expect(qbitTrackerMatches('none', _t('')), isTrue);
      expect(
        qbitTrackerMatches('none', _t('https://tracker.example.org/announce')),
        isFalse,
      );
    });

    test('a torrent with no working tracker is in no host bucket', () {
      expect(qbitTrackerMatches('tracker.example.org', _t('')), isFalse);
    });
  });
}
