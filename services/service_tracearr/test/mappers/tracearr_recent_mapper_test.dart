import 'package:flutter_test/flutter_test.dart';
import 'package:service_tracearr/src/generated/models/cursor_meta.dart';
import 'package:service_tracearr/src/generated/models/recently_added_record.dart';
import 'package:service_tracearr/src/generated/models/recently_added_response.dart';
import 'package:service_tracearr/src/mappers/tracearr_recent_mapper.dart';

void main() {
  group('TracearrRecentMapper', () {
    test('maps RecentlyAddedRecord correctly with pre-resolved poster', () {
      const dto = RecentlyAddedRecord(
        id: 'rec_1',
        serverId: 'srv_1',
        libraryId: 'lib_1',
        mediaType: 'movie',
        title: 'Dune: Part Two',
        year: 2024,
        addedAt: '2026-01-01T12:00:00.000Z',
        mediaId: 'med_dune',
        imdbId: 'tt15239678',
        tmdbId: 693134,
        tvdbId: 89432,
        ratingKey: 'rk_123',
      );

      final domain = TracearrRecentMapper.fromDto(
        dto,
        resolvedPosterUrl: 'https://proxy.example.com/poster.jpg',
      );

      expect(domain.id, equals('rec_1'));
      expect(domain.title, equals('Dune: Part Two'));
      expect(domain.year, equals(2024));
      expect(domain.tmdbId, equals('693134'));
      expect(domain.tvdbId, equals('89432'));
      expect(
        domain.resolvedPosterUrl,
        equals('https://proxy.example.com/poster.jpg'),
      );
    });

    test('maps RecentlyAddedResponse to page with poster lookup map', () {
      const response = RecentlyAddedResponse(
        data: [
          RecentlyAddedRecord(id: 'rec_1', title: 'Item 1'),
          RecentlyAddedRecord(id: 'rec_2', title: 'Item 2'),
        ],
        meta: CursorMeta(nextCursor: 'next_rec_cursor'),
      );

      final page = TracearrRecentMapper.fromPageResponse(
        response,
        resolvedPostersByItemId: {
          'rec_1': 'https://example.com/item1.jpg',
        },
      );

      expect(page.items.length, equals(2));
      expect(
        page.items[0].resolvedPosterUrl,
        equals('https://example.com/item1.jpg'),
      );
      expect(page.items[1].resolvedPosterUrl, isNull);
      expect(page.nextCursor, equals('next_rec_cursor'));
    });
  });
}
