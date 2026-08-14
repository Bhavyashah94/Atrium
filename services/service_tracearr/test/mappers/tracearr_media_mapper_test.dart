import 'package:flutter_test/flutter_test.dart';
import 'package:service_tracearr/src/generated/models/media_availability.dart';
import 'package:service_tracearr/src/generated/models/media_child.dart';
import 'package:service_tracearr/src/generated/models/media_resource.dart';
import 'package:service_tracearr/src/generated/models/watcher.dart';
import 'package:service_tracearr/src/generated/models/watcher_user.dart';
import 'package:service_tracearr/src/mappers/tracearr_media_mapper.dart';

void main() {
  group('TracearrMediaMapper', () {
    const baseUrl = 'https://tr.example.com';

    test('detailFromDto maps media resource, stats, and watchers correctly',
        () {
      const resource = MediaResource(
        id: 'med_uuid_1',
        mediaType: 'movie',
        title: 'Oppenheimer',
        year: 2023,
        imdbId: 'tt15398776',
        genres: ['Biography', 'Drama', 'History'],
        availability: [
          MediaAvailability(
            serverId: 'srv_1',
            serverType: 'plex',
            ratingKey: '45000',
            videoResolution: '4k',
            fileSize: 45000000000,
          ),
        ],
      );

      final statsWindows = <String, dynamic>{
        'all_time': <String, dynamic>{
          'combined': <String, dynamic>{
            'plays': 80,
            'watch_time_ms': 800000000,
          },
        },
        'last_30': <String, dynamic>{
          'combined': <String, dynamic>{'plays': 25},
        },
        'last_7': <String, dynamic>{
          'combined': <String, dynamic>{'plays': 8},
        },
      };

      const watchers = [
        Watcher(
          user: WatcherUser(
            userId: 'user_u1',
            identityName: 'Bhavya',
            username: 'bhavyashah',
          ),
          plays: 5,
          watchTimeMs: 50000000,
          completionPct: 100.0,
        ),
      ];

      final detail = TracearrMediaMapper.detailFromDto(
        item: resource,
        statsWindows: statsWindows,
        watchersList: watchers,
        baseUrl: baseUrl,
      );

      expect(detail.id, equals('med_uuid_1'));
      expect(detail.title, equals('Oppenheimer'));
      expect(detail.year, equals(2023));
      expect(detail.genres, equals(['Biography', 'Drama', 'History']));
      expect(detail.allTimePlays, equals(80));
      expect(detail.allTimeWatchTimeMs, equals(800000000));
      expect(detail.last30DaysPlays, equals(25));
      expect(detail.last7DaysPlays, equals(8));
      expect(detail.availability.length, equals(1));
      expect(detail.availability.first.videoResolution, equals('4k'));
      expect(detail.watchers.length, equals(1));
      expect(detail.watchers.first.userId, equals('user_u1'));
      expect(detail.watchers.first.username, equals('Bhavya'));
      expect(detail.watchers.first.plays, equals(5));
      expect(
        detail.posterUrl,
        equals(
          'https://tr.example.com/api/v1/images/proxy?server=srv_1&url=%2Flibrary%2Fmetadata%2F45000%2Fthumb&width=300&height=450&fallback=poster',
        ),
      );
    });

    test('mapChildren maps MediaChild items correctly', () {
      const childrenDto = [
        MediaChild(
          id: 'child_1',
          title: 'Pilot',
          seasonNumber: 1,
          episodeNumber: 1,
          imdbId: 'tt123456',
        ),
      ];

      final children = TracearrMediaMapper.mapChildren(childrenDto);
      expect(children.length, equals(1));
      expect(children.first.title, equals('Pilot'));
      expect(children.first.seasonNumber, equals(1));
      expect(children.first.episodeNumber, equals(1));
      expect(children.first.imdbId, equals('tt123456'));
    });
  });
}
