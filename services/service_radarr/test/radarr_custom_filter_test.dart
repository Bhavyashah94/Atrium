import 'package:core_models/core_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:service_radarr/service_radarr.dart';
import 'package:service_radarr/src/radarr_custom_filter_evaluator.dart';

void main() {
  group('RadarrCustomFilter deserialization', () {
    test('parses custom filter JSON correctly', () {
      final json = <String, dynamic>{
        'id': 1,
        'type': 'movies',
        'label': 'With Downloads',
        'filters': [
          {'key': 'hasFile', 'value': true, 'type': 'equal'},
        ],
      };

      final filter = RadarrCustomFilter.fromJson(json);
      expect(filter.id, 1);
      expect(filter.type, 'movies');
      expect(filter.label, 'With Downloads');
      expect(filter.filters, hasLength(1));
    });
  });

  group('matchesRadarrCustomFilter', () {
    const movieWithFile = RadarrMovie(
      id: 1,
      title: 'Gladiator II',
      hasFile: true,
      monitored: true,
      year: 2024,
      genres: ['Action', 'Drama'],
      status: 'released',
      sizeOnDisk: 5000000000,
    );

    const movieWithoutFile = RadarrMovie(
      id: 2,
      title: 'Avatar 3',
      year: 2025,
      genres: ['Sci-Fi', 'Adventure'],
      status: 'announced',
    );

    test('matches With Downloads (hasFile == true)', () {
      final filter = RadarrCustomFilter.fromJson(<String, dynamic>{
        'id': 10,
        'type': 'movies',
        'label': 'With Downloads',
        'filters': [
          {'key': 'hasFile', 'value': true, 'type': 'equal'},
        ],
      });

      expect(matchesRadarrCustomFilter(movieWithFile, filter), isTrue);
      expect(matchesRadarrCustomFilter(movieWithoutFile, filter), isFalse);
    });

    test('matches Without Downloads (hasFile == false)', () {
      final filter = RadarrCustomFilter.fromJson(<String, dynamic>{
        'id': 11,
        'type': 'movies',
        'label': 'Without Downloads',
        'filters': [
          {'key': 'hasFile', 'value': false, 'type': 'equal'},
        ],
      });

      expect(matchesRadarrCustomFilter(movieWithFile, filter), isFalse);
      expect(matchesRadarrCustomFilter(movieWithoutFile, filter), isTrue);
    });

    test('matches year greaterThan and genres contains', () {
      final filter = RadarrCustomFilter.fromJson(<String, dynamic>{
        'id': 12,
        'type': 'movies',
        'label': 'Recent Action',
        'filters': [
          {'key': 'year', 'value': 2020, 'type': 'greaterThan'},
          {'key': 'genres', 'value': 'Action', 'type': 'contains'},
        ],
      });

      expect(matchesRadarrCustomFilter(movieWithFile, filter), isTrue);
      expect(matchesRadarrCustomFilter(movieWithoutFile, filter), isFalse);
    });

    test('handles array filter values with any/every', () {
      final filter = RadarrCustomFilter.fromJson(<String, dynamic>{
        'id': 13,
        'type': 'movies',
        'label': 'Action or Comedy',
        'filters': [
          {
            'key': 'genres',
            'value': ['Action', 'Comedy'],
            'type': 'contains',
          },
        ],
      });

      expect(matchesRadarrCustomFilter(movieWithFile, filter), isTrue);
      expect(matchesRadarrCustomFilter(movieWithoutFile, filter), isFalse);
    });
  });

  group('radarrFilteredMoviesProvider with custom filter', () {
    const instance = Instance(
      id: 'test-radarr',
      name: 'Radarr',
      kind: ServiceKind.radarr,
      localUrl: 'http://localhost:7878',
      externalUrl: '',
      urlMode: UrlMode.auto,
      auth: InstanceAuthApiKey(apiKey: 'dummy'),
    );

    test('filters list using active custom filter', () {
      const movie1 = RadarrMovie(
        id: 1,
        title: 'Movie A',
        hasFile: true,
      );
      const movie2 = RadarrMovie(
        id: 2,
        title: 'Movie B',
      );

      final customFilter = RadarrCustomFilter.fromJson(<String, dynamic>{
        'id': 99,
        'type': 'movies',
        'label': 'Downloaded Only Custom',
        'filters': [
          {'key': 'hasFile', 'value': true, 'type': 'equal'},
        ],
      });

      final container = ProviderContainer(
        overrides: [
          radarrMoviesProvider(instance).overrideWith(
            (ref) => [movie1, movie2],
          ),
        ],
      );
      addTearDown(container.dispose);

      // Initially with default filter
      final initial = container.read(radarrFilteredMoviesProvider(instance));
      expect(initial.value, hasLength(2));

      // Activate custom filter
      container
          .read(radarrActiveCustomFilterProvider(instance).notifier)
          .state = customFilter;

      final filtered = container.read(radarrFilteredMoviesProvider(instance));
      expect(filtered.value, hasLength(1));
      expect(filtered.value!.first.title, 'Movie A');
    });

    test('supports array-wrapped filter values as sent by Servarr API', () {
      const movieRecent = RadarrMovie(
        id: 1,
        title: 'Recent Movie',
        year: 2024,
      );
      const movieOld = RadarrMovie(
        id: 2,
        title: 'Old Movie',
        year: 2010,
      );

      final customFilter = RadarrCustomFilter.fromJson(<String, dynamic>{
        'id': 100,
        'type': 'movies',
        'label': 'Recent Movies',
        'filters': [
          {
            'key': 'year',
            'value': [2020],
            'type': 'greaterThan',
          },
        ],
      });

      expect(matchesRadarrCustomFilter(movieRecent, customFilter), isTrue);
      expect(matchesRadarrCustomFilter(movieOld, customFilter), isFalse);
    });
  });
}
