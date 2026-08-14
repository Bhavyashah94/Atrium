import 'package:flutter_test/flutter_test.dart';
import 'package:service_tracearr/src/generated/models/library_rollup.dart';
import 'package:service_tracearr/src/mappers/tracearr_library_mapper.dart';

void main() {
  group('TracearrLibraryMapper', () {
    test('maps LibraryRollup with resolution counts correctly', () {
      const dto = LibraryRollup(
        serverId: 'srv_1',
        serverType: 'plex',
        libraryId: 'lib_movies',
        itemCount: 1500,
        movieCount: 1500,
        showCount: 0,
        episodeCount: 0,
        trackCount: 0,
        totalFileSize: 8500000000000,
        resolutions: <String, dynamic>{
          '4k': 250,
          '1080p': 1000,
          '720p': 250,
        },
      );

      final domain = TracearrLibraryMapper.fromDto(dto);

      expect(domain, isNotNull);
      expect(domain!.serverId, equals('srv_1'));
      expect(domain.serverType, equals('plex'));
      expect(domain.libraryId, equals('lib_movies'));
      expect(domain.itemCount, equals(1500));
      expect(domain.movieCount, equals(1500));
      expect(domain.totalFileSize, equals(8500000000000));
      expect(domain.resolutions['4k'], equals(250));
      expect(domain.resolutions['1080p'], equals(1000));
      expect(domain.resolutions['720p'], equals(250));
    });

    test('returns null when serverId or libraryId is missing', () {
      const dto = LibraryRollup(
        serverId: '',
        libraryId: 'lib_1',
      );
      expect(TracearrLibraryMapper.fromDto(dto), isNull);
    });
  });
}
