import 'package:core_models/core_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:service_sonarr/service_sonarr.dart';
import 'package:service_sonarr/src/sonarr_custom_filter_evaluator.dart';

void main() {
  group('CustomFilterResource deserialization', () {
    test('parses custom filter JSON correctly', () {
      final json = <String, dynamic>{
        'id': 1,
        'type': 'series',
        'label': 'With Downloads',
        'filters': [
          {'key': 'episodeFileCount', 'value': 0, 'type': 'greaterThan'},
        ],
      };

      final filter = CustomFilterResource.fromJson(json);
      expect(filter.id, 1);
      expect(filter.type, 'series');
      expect(filter.label, 'With Downloads');
      expect(filter.filters, hasLength(1));
    });
  });

  group('matchesSonarrCustomFilter', () {
    const seriesWithEpisodes = SonarrSeries(
      id: 1,
      title: 'Breaking Bad',
      monitored: true,
      status: 'ended',
      genres: ['Crime', 'Drama'],
      year: 2008,
      statistics: SonarrSeriesStatistics(
        seasonCount: 5,
        episodeCount: 62,
        episodeFileCount: 62,
        totalEpisodeCount: 62,
        sizeOnDisk: 50000000000,
      ),
    );

    const seriesMissingEpisodes = SonarrSeries(
      id: 2,
      title: 'Severance',
      monitored: true,
      status: 'continuing',
      genres: ['Sci-Fi', 'Thriller'],
      year: 2022,
      statistics: SonarrSeriesStatistics(
        seasonCount: 1,
        episodeCount: 9,
        totalEpisodeCount: 9,
      ),
    );

    test('matches With Downloads (episodeFileCount > 0)', () {
      final filter = CustomFilterResource.fromJson(<String, dynamic>{
        'id': 10,
        'type': 'series',
        'label': 'With Downloads',
        'filters': [
          {'key': 'episodeFileCount', 'value': 0, 'type': 'greaterThan'},
        ],
      });

      expect(matchesSonarrCustomFilter(seriesWithEpisodes, filter), isTrue);
      expect(matchesSonarrCustomFilter(seriesMissingEpisodes, filter), isFalse);
    });

    test('matches Without Downloads (episodeFileCount == 0)', () {
      final filter = CustomFilterResource.fromJson(<String, dynamic>{
        'id': 11,
        'type': 'series',
        'label': 'Without Downloads',
        'filters': [
          {'key': 'episodeFileCount', 'value': 0, 'type': 'equal'},
        ],
      });

      expect(matchesSonarrCustomFilter(seriesWithEpisodes, filter), isFalse);
      expect(matchesSonarrCustomFilter(seriesMissingEpisodes, filter), isTrue);
    });

    test('matches status and genres', () {
      final filter = CustomFilterResource.fromJson(<String, dynamic>{
        'id': 12,
        'type': 'series',
        'label': 'Continuing Sci-Fi',
        'filters': [
          {'key': 'status', 'value': 'continuing', 'type': 'equal'},
          {'key': 'genres', 'value': 'Sci-Fi', 'type': 'contains'},
        ],
      });

      expect(matchesSonarrCustomFilter(seriesWithEpisodes, filter), isFalse);
      expect(matchesSonarrCustomFilter(seriesMissingEpisodes, filter), isTrue);
    });

    test('matches missing helper key', () {
      final filter = CustomFilterResource.fromJson(<String, dynamic>{
        'id': 13,
        'type': 'series',
        'label': 'Missing Episodes',
        'filters': [
          {'key': 'missing', 'value': true, 'type': 'equal'},
        ],
      });

      expect(matchesSonarrCustomFilter(seriesWithEpisodes, filter), isFalse);
      expect(matchesSonarrCustomFilter(seriesMissingEpisodes, filter), isTrue);
    });
  });

  group('sonarrFilteredSeriesProvider with custom filter', () {
    const instance = Instance(
      id: 'test-sonarr',
      name: 'Sonarr',
      kind: ServiceKind.sonarr,
      localUrl: 'http://localhost:8989',
      externalUrl: '',
      urlMode: UrlMode.auto,
      auth: InstanceAuthApiKey(apiKey: 'dummy'),
    );

    test('filters list using active custom filter', () {
      const series1 = SonarrSeries(
        id: 1,
        title: 'Show A',
        statistics: SonarrSeriesStatistics(
          episodeFileCount: 10,
          episodeCount: 10,
        ),
      );
      const series2 = SonarrSeries(
        id: 2,
        title: 'Show B',
        statistics: SonarrSeriesStatistics(
          episodeCount: 10,
        ),
      );

      final customFilter = CustomFilterResource.fromJson(<String, dynamic>{
        'id': 99,
        'type': 'series',
        'label': 'With Downloads Custom',
        'filters': [
          {'key': 'episodeFileCount', 'value': 0, 'type': 'greaterThan'},
        ],
      });

      final container = ProviderContainer(
        overrides: [
          sonarrSeriesProvider(instance).overrideWith(
            (ref) => [series1, series2],
          ),
        ],
      );
      addTearDown(container.dispose);

      // Initially with default filter
      final initial = container.read(sonarrFilteredSeriesProvider(instance));
      expect(initial.value, hasLength(2));

      // Activate custom filter
      container
          .read(sonarrActiveCustomFilterProvider(instance).notifier)
          .state = customFilter;

      final filtered = container.read(sonarrFilteredSeriesProvider(instance));
      expect(filtered.value, hasLength(1));
      expect(filtered.value!.first.title, 'Show A');
    });
  });
}
