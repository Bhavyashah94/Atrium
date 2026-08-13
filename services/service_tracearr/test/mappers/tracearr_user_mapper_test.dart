import 'package:flutter_test/flutter_test.dart';
import 'package:service_tracearr/src/generated/models/history_record.dart';
import 'package:service_tracearr/src/generated/models/user_account.dart';
import 'package:service_tracearr/src/generated/models/user_identity.dart';
import 'package:service_tracearr/src/generated/models/user_stats_response.dart';
import 'package:service_tracearr/src/mappers/tracearr_user_mapper.dart';

void main() {
  group('TracearrUserMapper', () {
    const baseUrl = 'https://tr.example.com';

    test('summaryFromDto maps identity and stats windows correctly', () {
      const identity = UserIdentity(
        id: 'user_uuid_1',
        username: 'Bhavyashah',
        email: 'bhavya@example.com',
        accounts: [
          UserAccount(
            serverId: 'srv_1',
            serverType: 'plex',
            serverUserId: 'su_1',
            externalUserId: 'plex_user_100',
            username: 'BhavyashahPlex',
          ),
        ],
      );

      const stats = UserStatsResponse(
        userId: 'user_uuid_1',
        windows: <String, dynamic>{
          'all_time': <String, dynamic>{
            'plays': 250,
            'watch_time_ms': 500000000,
          },
        },
      );

      final summary = TracearrUserMapper.summaryFromDto(
        identity: identity,
        stats: stats,
        baseUrl: baseUrl,
      );

      expect(summary.id, equals('user_uuid_1'));
      expect(summary.username, equals('Bhavyashah'));
      expect(summary.email, equals('bhavya@example.com'));
      expect(summary.allTimePlays, equals(250));
      expect(summary.allTimeWatchTimeMs, equals(500000000));
      expect(summary.accounts.length, equals(1));
      expect(summary.accounts.first.serverType, equals('plex'));
      expect(
        summary.avatarUrl,
        equals(
          'https://tr.example.com/api/v1/images/proxy?server=srv_1&url=%2Fusers%2Fplex_user_100%2Favatar&width=300&height=450&fallback=poster',
        ),
      );
    });

    test('detailFromDto parses multi-window stats and recent history', () {
      const identity = UserIdentity(
        id: 'user_uuid_1',
        username: 'Bhavyashah',
        email: 'bhavya@example.com',
        plexAccountId: 'plex_acc_99',
        accounts: [
          UserAccount(
            serverId: 'srv_1',
            serverType: 'jellyfin',
            serverUserId: 'jf_su_1',
            externalUserId: 'jf_ext_1',
            username: 'JFUser',
          ),
        ],
      );

      const stats = UserStatsResponse(
        userId: 'user_uuid_1',
        windows: <String, dynamic>{
          'all_time': <String, dynamic>{
            'plays': 100,
            'watch_time_ms': 200000000,
          },
          'last_30': <String, dynamic>{'plays': 30},
          'last_7': <String, dynamic>{'plays': 10},
          'top_genres': <dynamic>[
            <String, dynamic>{'genre': 'Sci-Fi', 'plays': 60},
            <String, dynamic>{'genre': 'Drama', 'plays': 40},
          ],
        },
      );

      const historyRecords = [
        HistoryRecord(id: 'h1', mediaTitle: 'Movie A'),
      ];

      final detail = TracearrUserMapper.detailFromDto(
        identity: identity,
        stats: stats,
        recentHistoryRecords: historyRecords,
        baseUrl: baseUrl,
      );

      expect(detail.id, equals('user_uuid_1'));
      expect(detail.plexAccountId, equals('plex_acc_99'));
      expect(detail.allTimePlays, equals(100));
      expect(detail.last30DaysPlays, equals(30));
      expect(detail.last7DaysPlays, equals(10));
      expect(detail.topGenres.length, equals(2));
      expect(detail.topGenres.first.genre, equals('Sci-Fi'));
      expect(detail.topGenres.first.plays, equals(60));
      expect(detail.recentHistory.length, equals(1));
      expect(detail.recentHistory.first.mediaTitle, equals('Movie A'));
    });
  });
}
