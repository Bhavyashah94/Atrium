import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:service_lidarr/service_lidarr.dart';

import 'test_helpers.dart';

void main() {
  group('Lidarr Albums Feature Widget Tests', () {
    testWidgets(
        'AlbumDetailScreen renders compact hero, multi-disc tracklist, and dispatches album commands',
        (tester) async {
      final List<Map<String, dynamic>> dispatchedCommands = [];
      final List<Map<String, dynamic>> putCalls = [];

      final Dio dio = Dio(
        BaseOptions(
          baseUrl: 'http://127.0.0.1:8686',
          headers: {'X-Api-Key': 'mock-key'},
        ),
      );

      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            if (options.path.contains('/api/v1/command') &&
                options.method == 'POST') {
              dispatchedCommands.add(options.data as Map<String, dynamic>);
              return handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 201,
                  data: {
                    'id': 1,
                    'name': (options.data as Map<String, dynamic>)['name'],
                    'status': 'queued',
                  },
                ),
              );
            }
            if (options.path.contains('/api/v1/album/monitor') &&
                options.method == 'PUT') {
              putCalls.add(options.data as Map<String, dynamic>);
              return handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 200,
                  data: options.data,
                ),
              );
            }
            return handler.next(options);
          },
        ),
      );

      const album = AlbumResource(
        id: 10,
        artistId: 1,
        title: 'OK Computer (Collector Edition)',
        releaseDate: '1997-05-21',
        albumType: 'Studio',
        monitored: true,
        mediumCount: 2,
        artist: ArtistResource(id: 1, artistName: 'Radiohead'),
        statistics: AlbumStatisticsResource(
          trackFileCount: 14,
          totalTrackCount: 20,
          sizeOnDisk: 717221068,
        ),
      );

      const tracks = [
        TrackResource(
          id: 101,
          albumId: 10,
          artistId: 1,
          trackNumber: '1',
          mediumNumber: 1,
          title: 'Airbag',
          duration: 284000,
          hasFile: true,
          trackFileId: 501,
        ),
        TrackResource(
          id: 102,
          albumId: 10,
          artistId: 1,
          trackNumber: '2',
          mediumNumber: 1,
          title: 'Paranoid Android',
          duration: 383000,
          hasFile: true,
          trackFileId: 502,
        ),
        TrackResource(
          id: 201,
          albumId: 10,
          artistId: 1,
          trackNumber: '1',
          mediumNumber: 2,
          title: 'Polyethylene (Parts 1 & 2)',
          duration: 262000,
          hasFile: true,
          trackFileId: 503,
        ),
      ];

      const trackFiles = [
        TrackFileResource(
          id: 501,
          albumId: 10,
          path: '/music/Radiohead/OK Computer/01 - Airbag.flac',
          size: 32000000,
          quality: QualityModel(
            quality: Quality(id: 1, name: 'FLAC 16bit'),
          ),
          mediaInfo: MediaInfoResource(
            audioCodec: 'FLAC',
            audioBitRate: '950 kbps',
            audioChannels: 2.0,
            audioBits: '16',
            audioSampleRate: '44100',
          ),
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            lidarrApiProvider(testInstance)
                .overrideWith((ref) => LidarrApi(dio)),
            lidarrAlbumByIdProvider((testInstance, 10))
                .overrideWith((ref) async => album),
            lidarrTracksForAlbumProvider((testInstance, 1, 10))
                .overrideWith((ref) async => tracks),
            lidarrTrackFilesForAlbumProvider((testInstance, 10))
                .overrideWith((ref) async => trackFiles),
          ],
          child: const MaterialApp(
            home: AlbumDetailScreen(
              instance: testInstance,
              artistId: 1,
              albumId: 10,
              initialAlbum: album,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 1. Verify Compact Hero info & stats
      expect(find.text('OK Computer (Collector Edition)'), findsAtLeast(1));
      expect(find.text('Radiohead'), findsAtLeast(1));
      expect(find.textContaining('Studio'), findsAtLeast(1));
      expect(find.textContaining('14/20 tracks'), findsAtLeast(1));
      expect(find.textContaining('684.0 MB'), findsAtLeast(1));

      // 2. Discs and Tracks
      expect(find.text('Disc 1'), findsOneWidget);
      expect(find.text('Disc 2'), findsOneWidget);
      expect(find.text('Airbag'), findsOneWidget);
      expect(find.text('FLAC'), findsOneWidget);
      expect(find.text('Polyethylene (Parts 1 & 2)'), findsOneWidget);

      // 3. Trigger Auto Search
      await tester.tap(find.text('Auto Search'));
      await tester.pumpAndSettle();

      expect(dispatchedCommands, hasLength(1));
      expect(dispatchedCommands.first['name'], equals('AlbumSearch'));
      expect(dispatchedCommands.first['albumIds'], equals([10]));

      // 4. Toggle Monitored
      await tester.tap(find.text('Monitored').first);
      await tester.pumpAndSettle();

      expect(putCalls, hasLength(1));
      expect(putCalls.first['albumIds'], equals([10]));
      expect(putCalls.first['monitored'], equals(false));

      // 5. Open track details sheet
      await tester.tap(find.text('Airbag'));
      await tester.pumpAndSettle();

      expect(find.text('Media & File Information'), findsOneWidget);
      expect(find.text('FLAC 16bit'), findsOneWidget);
      expect(find.text('Delete Audio File'), findsOneWidget);
    });

    testWidgets(
      'LidarrEditAlbumSheet edits settings and submits PUT /api/v1/album/{id}',
      (WidgetTester tester) async {
        Map<String, dynamic>? lastPutPayload;

        final dio = Dio(
          BaseOptions(
            baseUrl: 'http://localhost:8686',
            headers: {'X-Api-Key': 'mock-key'},
          ),
        );

        dio.interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) {
              if (options.method == 'PUT' &&
                  options.path == '/api/v1/album/101') {
                lastPutPayload = options.data as Map<String, dynamic>?;
                return handler.resolve(
                  Response<dynamic>(
                    requestOptions: options,
                    data: {
                      'id': 101,
                      'title': 'A Moon Shaped Pool',
                      'monitored': false,
                      'anyReleaseOk': false,
                    },
                    statusCode: 200,
                  ),
                );
              }
              return handler.next(options);
            },
          ),
        );

        const album = AlbumResource(
          id: 101,
          artistId: 1,
          title: 'A Moon Shaped Pool',
          albumType: 'Album',
          monitored: true,
          anyReleaseOk: true,
          releases: [
            AlbumReleaseResource(
              id: 501,
              albumId: 101,
              title: 'Standard Digital Release',
              format: 'Digital',
              monitored: true,
            ),
            AlbumReleaseResource(
              id: 502,
              albumId: 101,
              title: 'Special Edition Vinyl',
              format: 'Vinyl',
              monitored: false,
            ),
          ],
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              lidarrApiProvider(testInstance)
                  .overrideWith((ref) => LidarrApi(dio)),
            ],
            child: MaterialApp(
              home: Scaffold(
                body: Builder(
                  builder: (context) {
                    return ElevatedButton(
                      onPressed: () => showLidarrEditAlbumSheet(
                        context,
                        instance: testInstance,
                        artistId: 1,
                        album: album,
                      ),
                      child: const Text('Open Edit Album Sheet'),
                    );
                  },
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Open Sheet
        await tester.tap(find.text('Open Edit Album Sheet'));
        await tester.pumpAndSettle();

        expect(find.text('Edit - A Moon Shaped Pool [Album]'), findsOneWidget);
        expect(find.text('Monitored'), findsOneWidget);
        expect(find.text('Automatically Switch Release'), findsOneWidget);
        expect(find.text('Standard Digital Release'), findsOneWidget);
        expect(find.text('Special Edition Vinyl'), findsOneWidget);

        // Toggle monitored
        await tester.tap(find.text('Monitored'));
        await tester.pumpAndSettle();

        // Toggle automatically switch release
        await tester.tap(find.text('Automatically Switch Release'));
        await tester.pumpAndSettle();

        // Select vinyl release
        await tester.ensureVisible(find.text('Special Edition Vinyl'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Special Edition Vinyl'));
        await tester.pumpAndSettle();

        // Save
        await tester.tap(find.text('Save Changes'));
        await tester.pumpAndSettle();

        expect(lastPutPayload?['monitored'], equals(false));
        expect(lastPutPayload?['anyReleaseOk'], equals(false));
        final releases = lastPutPayload?['releases'] as List<dynamic>?;
        expect(releases, isNotNull);
      },
    );

    testWidgets(
      'showLidarrDeleteAlbumDialog confirms deletion and submits DELETE /api/v1/album/{id}',
      (WidgetTester tester) async {
        int? deletedAlbumId;
        Map<String, dynamic>? queryParams;

        final dio = Dio(
          BaseOptions(
            baseUrl: 'http://localhost:8686',
            headers: {'X-Api-Key': 'mock-key'},
          ),
        );

        dio.interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) {
              if (options.method == 'DELETE' &&
                  options.path == '/api/v1/album/101') {
                deletedAlbumId = 101;
                queryParams = options.queryParameters;
                return handler.resolve(
                  Response<dynamic>(
                    requestOptions: options,
                  ),
                );
              }
              return handler.next(options);
            },
          ),
        );

        const album = AlbumResource(
          id: 101,
          artistId: 1,
          title: 'A Moon Shaped Pool',
          statistics: AlbumStatisticsResource(
            trackFileCount: 11,
            sizeOnDisk: 50000000,
          ),
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              lidarrApiProvider(testInstance)
                  .overrideWith((ref) => LidarrApi(dio)),
            ],
            child: MaterialApp(
              home: Scaffold(
                body: Consumer(
                  builder: (context, ref, _) {
                    return ElevatedButton(
                      onPressed: () => showLidarrDeleteAlbumDialog(
                        context,
                        instance: testInstance,
                        artistId: 1,
                        album: album,
                        ref: ref,
                      ),
                      child: const Text('Open Delete Album Dialog'),
                    );
                  },
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Open Dialog
        await tester.tap(find.text('Open Delete Album Dialog'));
        await tester.pumpAndSettle();

        expect(find.text('Delete A Moon Shaped Pool?'), findsOneWidget);
        expect(find.text('Delete files from disk'), findsOneWidget);
        expect(find.text('Add import list exclusion'), findsOneWidget);

        // Toggle delete files
        await tester.tap(find.text('Delete files from disk'));
        await tester.pumpAndSettle();

        // Submit Delete
        await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
        await tester.pumpAndSettle();

        expect(deletedAlbumId, equals(101));
        expect(queryParams?['deleteFiles'], equals(true));
        expect(queryParams?['addImportListExclusion'], equals(true));
      },
    );
  });
}
