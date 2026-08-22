import 'package:core_models/core_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:service_sonarr/service_sonarr.dart';

void main() {
  const instance = Instance(
    id: 'sonarr-1',
    name: 'Sonarr Test',
    kind: ServiceKind.sonarr,
    localUrl: 'http://localhost:8989',
    externalUrl: '',
    urlMode: UrlMode.auto,
    auth: InstanceAuthApiKey(apiKey: 'dummy-api-key'),
  );

  const episode = SonarrEpisode(
    id: 101,
    seriesId: 1,
    episodeFileId: 0,
    seasonNumber: 1,
    episodeNumber: 1,
    title: 'Pilot Episode',
  );

  final mockReleases = [
    <String, dynamic>{
      'guid': 'release-low-score',
      'title': 'Show.S01E01.720p.HDTV.x264',
      'indexer': 'Indexer A',
      'size': 1000000000,
      'seeders': 50,
      'leechers': 5,
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
      'ageMinutes': 120,
    },
    <String, dynamic>{
      'guid': 'release-high-score',
      'title': 'Show.S01E01.1080p.Remux.HDR10.TrueHD',
      'indexer': 'Indexer B',
      'size': 5000000000,
      'seeders': 20,
      'leechers': 2,
      'protocol': 'torrent',
      'rejections': <String>[],
      'customFormatScore': 1500,
      'customFormats': <dynamic>[
        <String, dynamic>{'id': 1, 'name': 'HDR10'},
        <String, dynamic>{'id': 2, 'name': 'TrueHD Atmos'},
      ],
      'quality': <String, dynamic>{
        'quality': <String, dynamic>{'name': 'Bluray-1080p Remux'},
      },
      'languages': <dynamic>[
        <String, dynamic>{'name': 'English'},
      ],
      'ageMinutes': 240,
    },
  ];

  testWidgets(
    'SonarrReleaseSearchScreen defaults to Score descending and renders format badges',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sonarrReleasesProvider((instance, episode.id)).overrideWith(
              (ref) async => mockReleases,
            ),
          ],
          child: const MaterialApp(
            home: SonarrReleaseSearchScreen(
              instance: instance,
              episode: episode,
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
          tester.getTopLeft(find.textContaining('1080p.Remux'));
      final lowScorePos = tester.getTopLeft(find.textContaining('720p.HDTV'));
      expect(highScorePos.dy, lessThan(lowScorePos.dy));

      // Verify Score badges and Custom Format pills are rendered
      expect(find.text('Score: +1500'), findsOneWidget);
      // A zero score with no matched formats carries no information, so the
      // badge is suppressed rather than putting "Score: 0" on every row of
      // every profile that has no custom formats configured.
      expect(find.text('Score: 0'), findsNothing);
      expect(find.text('HDR10'), findsOneWidget);
      expect(find.text('TrueHD Atmos'), findsOneWidget);
    },
  );

  testWidgets(
    'SonarrReleaseSearchScreen safely handles null and malformed custom format data',
    (tester) async {
      final malformedReleases = [
        <String, dynamic>{
          'guid': 'release-null-data',
          'title': 'Show.S01E01.NullData',
          'indexer': 'Indexer Null',
          'size': 1000,
          'seeders': 10,
          'protocol': 'torrent',
          'customFormatScore': null,
          'customFormats': null,
        },
        <String, dynamic>{
          'guid': 'release-malformed-data',
          'title': 'Show.S01E01.MalformedData',
          'indexer': 'Indexer Malformed',
          'size': 2000,
          'seeders': 5,
          'protocol': 'torrent',
          'customFormatScore': 'invalid_number',
          'customFormats': 'not_a_list',
        },
        <String, dynamic>{
          'guid': 'release-string-score-and-invalid-items',
          'title': 'Show.S01E01.StringScore',
          'indexer': 'Indexer String',
          'size': 3000,
          'seeders': 1,
          'protocol': 'torrent',
          'customFormatScore': '500',
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
            sonarrReleasesProvider((instance, episode.id)).overrideWith(
              (ref) async => malformedReleases,
            ),
          ],
          child: const MaterialApp(
            home: SonarrReleaseSearchScreen(
              instance: instance,
              episode: episode,
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pumpAndSettle();

      // Ensure all 3 releases render without throwing exceptions
      expect(find.byType(ExpansionTile), findsNWidgets(3));

      // String score '500' parsed correctly and renders score badge
      expect(find.text('Score: +500'), findsOneWidget);
      // The null and 'invalid_number' releases both fall back to 0 with no
      // formats, so their badges are suppressed. The rows still render (see
      // the ExpansionTile count above), which is what proves the malformed
      // payloads were absorbed rather than thrown on.
      expect(find.text('Score: 0'), findsNothing);
      expect(find.text('ValidFormat'), findsOneWidget);
    },
  );
}
