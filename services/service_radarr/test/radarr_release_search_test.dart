import 'package:core_models/core_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:service_radarr/service_radarr.dart';

void main() {
  const instance = Instance(
    id: 'radarr-1',
    name: 'Radarr Test',
    kind: ServiceKind.radarr,
    localUrl: 'http://localhost:7878',
    externalUrl: '',
    urlMode: UrlMode.auto,
    auth: InstanceAuthApiKey(apiKey: 'dummy-api-key'),
  );

  const movie = RadarrMovie(
    id: 42,
    title: 'Inception',
    year: 2010,
  );

  final mockReleases = [
    <String, dynamic>{
      'guid': 'release-low-score',
      'title': 'Inception.2010.720p.HDTV.x264',
      'indexer': 'Indexer A',
      'size': 1500000000,
      'seeders': 40,
      'leechers': 3,
      'protocol': 'torrent',
      'rejections': <String>[],
      'customFormatScore': 0,
      'customFormats': <dynamic>[],
      'quality': <String, dynamic>{
        'quality': <String, dynamic>{'name': 'HDTV-720p'},
      },
      'languages': <dynamic>[
        <String, dynamic>{'name': 'English'},
      ],
      'ageMinutes': 100,
    },
    <String, dynamic>{
      'guid': 'release-high-score',
      'title': 'Inception.2010.2160p.UHD.Remux.HDR10.DV.TrueHD',
      'indexer': 'Indexer B',
      'size': 45000000000,
      'seeders': 15,
      'leechers': 1,
      'protocol': 'torrent',
      'rejections': <String>[],
      'customFormatScore': 2500,
      'customFormats': <dynamic>[
        <String, dynamic>{'id': 1, 'name': 'HDR10'},
        <String, dynamic>{'id': 2, 'name': 'Dolby Vision'},
      ],
      'quality': <String, dynamic>{
        'quality': <String, dynamic>{'name': 'Bluray-2160p Remux'},
      },
      'languages': <dynamic>[
        <String, dynamic>{'name': 'English'},
      ],
      'ageMinutes': 300,
    },
  ];

  testWidgets(
    'RadarrReleaseSearchScreen defaults to Score descending and renders format badges',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            radarrReleasesProvider((instance, movie.id)).overrideWith(
              (ref) async => mockReleases,
            ),
          ],
          child: const MaterialApp(
            home: RadarrReleaseSearchScreen(
              instance: instance,
              movie: movie,
            ),
          ),
        ),
      );

      // Initial loading
      await tester.pump();
      await tester.pumpAndSettle();

      // Verify Score is the default selected sort option
      expect(find.text('Score'), findsWidgets);

      // Verify the high score release appears first by default (Score descending)
      final titleFinders = find.byType(ExpansionTile);
      expect(titleFinders, findsNWidgets(2));

      final highScorePos =
          tester.getTopLeft(find.textContaining('2160p.UHD.Remux'));
      final lowScorePos = tester.getTopLeft(find.textContaining('720p.HDTV'));
      expect(highScorePos.dy, lessThan(lowScorePos.dy));

      // Verify Score badges and Custom Format pills are rendered
      expect(find.text('Score: +2500'), findsOneWidget);
      // A zero score with no matched formats carries no information, so the
      // badge is suppressed rather than putting "Score: 0" on every row of
      // every profile that has no custom formats configured.
      expect(find.text('Score: 0'), findsNothing);
      expect(find.text('HDR10'), findsOneWidget);
      expect(find.text('Dolby Vision'), findsOneWidget);
    },
  );

  testWidgets(
    'RadarrReleaseSearchScreen safely handles null and malformed custom format data',
    (tester) async {
      final malformedReleases = [
        <String, dynamic>{
          'guid': 'release-null-data',
          'title': 'Inception.2010.NullData',
          'indexer': 'Indexer Null',
          'size': 1000,
          'seeders': 10,
          'protocol': 'torrent',
          'customFormatScore': null,
          'customFormats': null,
        },
        <String, dynamic>{
          'guid': 'release-malformed-data',
          'title': 'Inception.2010.MalformedData',
          'indexer': 'Indexer Malformed',
          'size': 2000,
          'seeders': 5,
          'protocol': 'torrent',
          'customFormatScore': 'invalid_number',
          'customFormats': 'not_a_list',
        },
        <String, dynamic>{
          'guid': 'release-string-score-and-invalid-items',
          'title': 'Inception.2010.StringScore',
          'indexer': 'Indexer String',
          'size': 3000,
          'seeders': 1,
          'protocol': 'torrent',
          'customFormatScore': '750',
          'customFormats': <dynamic>[
            123,
            null,
            <String, dynamic>{'name': ''},
            <String, dynamic>{'name': 'ValidFormat'},
          ],
        },
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            radarrReleasesProvider((instance, movie.id)).overrideWith(
              (ref) async => malformedReleases,
            ),
          ],
          child: const MaterialApp(
            home: RadarrReleaseSearchScreen(
              instance: instance,
              movie: movie,
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pumpAndSettle();

      // Ensure all 3 releases render without throwing exceptions
      expect(find.byType(ExpansionTile), findsNWidgets(3));

      // String score '750' parsed correctly and renders score badge
      expect(find.text('Score: +750'), findsOneWidget);
      // The null and 'invalid_number' releases both fall back to 0 with no
      // formats, so their badges are suppressed. The rows still render, which
      // is what proves the malformed payloads were absorbed, not thrown on.
      expect(find.text('Score: 0'), findsNothing);
      expect(find.text('ValidFormat'), findsOneWidget);
    },
  );
}
