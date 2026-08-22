import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:service_lidarr/service_lidarr.dart';

import 'test_helpers.dart';

void main() {
  group('Lidarr Wanted Feature Widget Tests', () {
    testWidgets(
      'WantedTab renders Missing and Cutoff Unmet albums and dispatches search & monitoring',
      (WidgetTester tester) async {
        String? commandDispatched;
        Map<String, dynamic>? commandPayload;
        bool albumPutCalled = false;
        Map<String, dynamic>? putAlbumPayload;

        final Dio dio = Dio(
          BaseOptions(
            baseUrl: 'http://127.0.0.1:8686',
            headers: <String, dynamic>{'X-Api-Key': 'mock-key'},
          ),
        );

        dio.interceptors.add(
          InterceptorsWrapper(
            onRequest:
                (RequestOptions options, RequestInterceptorHandler handler) {
              if (options.method == 'GET' &&
                  options.path.startsWith('/api/v1/wanted/missing')) {
                return handler.resolve(
                  Response<dynamic>(
                    requestOptions: options,
                    data: <String, dynamic>{
                      'page': 1,
                      'pageSize': 40,
                      'totalRecords': 1,
                      'records': <Map<String, dynamic>>[
                        <String, dynamic>{
                          'id': 501,
                          'artistId': 1,
                          'title': 'OK Computer',
                          'albumType': 'Studio',
                          'releaseDate': '1997-05-21T00:00:00Z',
                          'monitored': true,
                          'artist': <String, dynamic>{
                            'id': 1,
                            'artistName': 'Radiohead',
                          },
                        },
                      ],
                    },
                    statusCode: 200,
                  ),
                );
              }
              if (options.method == 'GET' &&
                  options.path.startsWith('/api/v1/wanted/cutoff')) {
                return handler.resolve(
                  Response<dynamic>(
                    requestOptions: options,
                    data: <String, dynamic>{
                      'page': 1,
                      'pageSize': 40,
                      'totalRecords': 1,
                      'records': <Map<String, dynamic>>[
                        <String, dynamic>{
                          'id': 502,
                          'artistId': 2,
                          'title': 'Random Access Memories',
                          'albumType': 'Studio',
                          'releaseDate': '2013-05-17T00:00:00Z',
                          'monitored': true,
                          'artist': <String, dynamic>{
                            'id': 2,
                            'artistName': 'Daft Punk',
                          },
                        },
                      ],
                    },
                    statusCode: 200,
                  ),
                );
              }
              if (options.method == 'POST' &&
                  options.path == '/api/v1/command') {
                final Map<String, dynamic> body =
                    options.data as Map<String, dynamic>;
                commandDispatched = body['name'] as String?;
                commandPayload = body;
                return handler.resolve(
                  Response<dynamic>(
                    requestOptions: options,
                    data: <String, dynamic>{
                      'name': commandDispatched,
                      'status': 'queued',
                      'id': 999,
                    },
                    statusCode: 201,
                  ),
                );
              }
              if (options.method == 'PUT' &&
                  options.path.startsWith('/api/v1/album/monitor')) {
                albumPutCalled = true;
                putAlbumPayload = options.data as Map<String, dynamic>?;
                return handler.resolve(
                  Response<dynamic>(
                    requestOptions: options,
                    data: putAlbumPayload,
                    statusCode: 200,
                  ),
                );
              }
              return handler.next(options);
            },
          ),
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              lidarrApiProvider(testInstance)
                  .overrideWith((Ref ref) => LidarrApi(dio)),
            ],
            child: const MaterialApp(
              home: WantedTab(instance: testInstance),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // 1. Verify Missing Tab
        expect(find.text('Missing'), findsOneWidget);
        expect(find.text('Cutoff Unmet'), findsOneWidget);
        expect(find.text('OK Computer'), findsOneWidget);
        expect(find.text('Radiohead'), findsOneWidget);

        // Verify Top Stadium Header & Sort/Filter Button
        expect(find.text('Search wanted albums...'), findsOneWidget);
        expect(find.byTooltip('Sort & Filter'), findsOneWidget);

        // Open Sort & Filter Sheet
        await tester.tap(find.byTooltip('Sort & Filter'));
        await tester.pumpAndSettle();
        expect(find.text('Filter & Sort'), findsOneWidget);
        expect(find.text('Monitored Only'), findsOneWidget);

        // Close sheet
        await tester.tapAt(const Offset(100, 100));
        await tester.pumpAndSettle();

        // Search Single Album
        await tester.tap(find.byTooltip('Auto Search').first);
        await tester.pumpAndSettle();

        expect(commandDispatched, equals('AlbumSearch'));
        expect(commandPayload?['albumIds'], equals(<int>[501]));

        // Toggle Monitored
        await tester.tap(find.byTooltip('Monitored').first);
        await tester.pumpAndSettle();

        expect(albumPutCalled, isTrue);
        expect(putAlbumPayload?['monitored'], equals(false));

        // Search All Missing via Primary FAB
        commandDispatched = null;
        await tester.tap(find.byTooltip('Search All Missing'));
        await tester.pumpAndSettle();

        expect(find.text('Search All Missing?'), findsOneWidget);
        await tester.tap(find.widgetWithText(FilledButton, 'Search All'));
        await tester.pumpAndSettle();

        expect(commandDispatched, equals('MissingAlbumSearch'));

        // 2. Switch to Cutoff Unmet Tab
        await tester.tap(find.text('Cutoff Unmet'));
        await tester.pumpAndSettle();

        expect(find.text('Random Access Memories'), findsOneWidget);
        expect(find.text('Daft Punk'), findsOneWidget);

        // Search All Cutoff Unmet via Primary FAB
        commandDispatched = null;
        await tester.tap(find.byTooltip('Search All Cutoff'));
        await tester.pumpAndSettle();

        expect(find.text('Search All Cutoff Unmet?'), findsOneWidget);
        await tester.tap(find.widgetWithText(FilledButton, 'Search All'));
        await tester.pumpAndSettle();

        expect(commandDispatched, equals('CutoffUnmetAlbumSearch'));
      },
    );

    testWidgets(
      'WantedTab batch selection enters selection mode and executes batch search & monitoring',
      (WidgetTester tester) async {
        String? lastCommandName;
        Map<String, dynamic>? lastCommandBody;
        Map<String, dynamic>? lastPutMonitorBody;

        final Dio dio = Dio(
          BaseOptions(
            baseUrl: 'http://localhost:8686',
            headers: <String, dynamic>{'X-Api-Key': 'mock-key'},
          ),
        );

        dio.interceptors.add(
          InterceptorsWrapper(
            onRequest:
                (RequestOptions options, RequestInterceptorHandler handler) {
              if (options.method == 'GET' &&
                  options.path.startsWith('/api/v1/wanted/missing')) {
                return handler.resolve(
                  Response<dynamic>(
                    requestOptions: options,
                    data: <String, dynamic>{
                      'page': 1,
                      'pageSize': 40,
                      'totalRecords': 2,
                      'records': <Map<String, dynamic>>[
                        <String, dynamic>{
                          'id': 201,
                          'artistId': 1,
                          'title': 'OK Computer',
                          'albumType': 'Album',
                          'monitored': true,
                          'artist': <String, dynamic>{
                            'id': 1,
                            'artistName': 'Radiohead',
                          },
                        },
                        <String, dynamic>{
                          'id': 202,
                          'artistId': 1,
                          'title': 'Kid A',
                          'albumType': 'Album',
                          'monitored': false,
                          'artist': <String, dynamic>{
                            'id': 1,
                            'artistName': 'Radiohead',
                          },
                        },
                      ],
                    },
                    statusCode: 200,
                  ),
                );
              }
              if (options.method == 'POST' &&
                  options.path == '/api/v1/command') {
                final Map<String, dynamic> body =
                    options.data as Map<String, dynamic>;
                lastCommandName = body['name'] as String?;
                lastCommandBody = body;
                return handler.resolve(
                  Response<dynamic>(
                    requestOptions: options,
                    data: <String, dynamic>{'id': 99, 'name': lastCommandName},
                    statusCode: 201,
                  ),
                );
              }
              if (options.method == 'PUT' &&
                  options.path == '/api/v1/album/monitor') {
                lastPutMonitorBody = options.data as Map<String, dynamic>?;
                return handler.resolve(
                  Response<dynamic>(
                    requestOptions: options,
                    statusCode: 202,
                  ),
                );
              }
              return handler.next(options);
            },
          ),
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              lidarrApiProvider(testInstance)
                  .overrideWith((Ref ref) => LidarrApi(dio)),
            ],
            child: const MaterialApp(
              home: WantedTab(instance: testInstance),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('OK Computer'), findsOneWidget);
        expect(find.text('Kid A'), findsOneWidget);

        // 1. Long press on 'OK Computer' to enter multi-select mode
        await tester.longPress(find.text('OK Computer'));
        await tester.pumpAndSettle();

        expect(find.text('1 selected'), findsOneWidget);
        expect(find.text('Search (1)'), findsOneWidget);
        expect(find.text('Monitor'), findsOneWidget);
        expect(find.text('Unmonitor'), findsOneWidget);

        // 2. Select 'Kid A' by tapping it in selection mode
        await tester.tap(find.text('Kid A'));
        await tester.pumpAndSettle();

        expect(find.text('2 selected'), findsOneWidget);
        expect(find.text('Search (2)'), findsOneWidget);

        // 3. Trigger Search (2)
        await tester.tap(find.text('Search (2)'));
        await tester.pumpAndSettle();

        expect(lastCommandName, equals('AlbumSearch'));
        expect(lastCommandBody?['albumIds'], unorderedEquals(<int>[201, 202]));
        expect(find.text('2 selected'), findsNothing);

        // Clear SnackBars
        ScaffoldMessenger.of(tester.element(find.byType(WantedTab)))
            .clearSnackBars();
        await tester.pumpAndSettle();

        // 4. Re-select 'Kid A' and test Monitor
        await tester.longPress(find.text('Kid A'));
        await tester.pumpAndSettle();
        expect(find.text('1 selected'), findsOneWidget);

        await tester.tap(find.text('Monitor'));
        await tester.pumpAndSettle();

        expect(lastPutMonitorBody?['albumIds'], equals(<int>[202]));
        expect(lastPutMonitorBody?['monitored'], equals(true));
      },
    );
  });
}
