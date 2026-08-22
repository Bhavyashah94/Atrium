import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:service_lidarr/service_lidarr.dart';

import 'test_helpers.dart';

void main() {
  group('Lidarr Home Navigation Widget Tests', () {
    testWidgets('LidarrHome renders Artists and Activity tabs', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            lidarrArtistsProvider(testInstance).overrideWith(
              (ref) async => [
                const ArtistResource(
                  id: 1,
                  artistName: 'Radiohead',
                  overview: 'English rock band formed in Abingdon in 1985.',
                  monitored: true,
                  statistics: ArtistStatisticsResource(
                    albumCount: 9,
                    trackFileCount: 150,
                  ),
                ),
                const ArtistResource(
                  id: 2,
                  artistName: 'Daft Punk',
                  overview: 'French electronic music duo.',
                  monitored: true,
                  statistics: ArtistStatisticsResource(
                    albumCount: 4,
                    trackFileCount: 60,
                  ),
                ),
              ],
            ),
            lidarrQueueProvider(testInstance).overrideWith(
              (ref) async => [
                const QueueResource(
                  id: 101,
                  title: 'Daft Punk - Discovery FLAC',
                  status: 'downloading',
                  size: 300000000,
                  sizeleft: 150000000,
                ),
              ],
            ),
          ],
          child: const MaterialApp(
            home: LidarrHome(instance: testInstance),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check SearchBar and artist cards
      expect(find.text('Search artists...'), findsOneWidget);
      expect(find.text('Radiohead'), findsOneWidget);
      expect(find.text('Daft Punk'), findsOneWidget);
      expect(find.text('Artists'), findsOneWidget);
      expect(find.text('Activity'), findsOneWidget);

      // Switch to Activity tab
      await tester.tap(find.text('Activity'));
      await tester.pumpAndSettle();

      expect(find.text('Queue'), findsOneWidget);
      expect(find.text('History'), findsOneWidget);
      expect(find.text('Daft Punk - Discovery FLAC'), findsOneWidget);
    });

    testWidgets('LidarrHome FAB navigates to LidarrAddArtistSearchScreen',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            lidarrArtistsProvider(testInstance).overrideWith((ref) async => []),
          ],
          child: const MaterialApp(
            home: LidarrHome(instance: testInstance),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify FAB presence
      expect(find.byIcon(Icons.add), findsOneWidget);

      // Tap FAB
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      // Verify navigated to search screen
      expect(find.byType(SearchBar), findsOneWidget);
      expect(find.text('Search online artist catalog...'), findsOneWidget);
    });
  });
}
