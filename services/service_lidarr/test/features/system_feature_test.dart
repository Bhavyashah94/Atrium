import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:service_lidarr/service_lidarr.dart';
import 'package:service_lidarr/src/features/system/views/log_file_reader_screen.dart';

import 'test_helpers.dart';

void main() {
  group('Lidarr System Feature Widget Tests', () {
    testWidgets(
        'SystemTab renders Status, Disk Space, Tasks, Backups and triggers maintenance actions',
        (tester) async {
      String? commandDispatched;

      final Dio dio = Dio(
        BaseOptions(
          baseUrl: 'http://127.0.0.1:8686',
          headers: {'X-Api-Key': 'mock-key'},
        ),
      );

      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            if (options.method == 'POST' && options.path == '/api/v1/command') {
              final body = options.data as Map<String, dynamic>;
              commandDispatched = body['name'] as String?;
              return handler.resolve(
                Response<dynamic>(
                  requestOptions: options,
                  data: {
                    'name': commandDispatched,
                    'status': 'queued',
                    'id': 1001,
                  },
                  statusCode: 201,
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
                .overrideWith((ref) => LidarrApi(dio)),
            lidarrSystemStatusProvider(testInstance).overrideWith(
              (ref) async => const SystemResource(
                version: '3.1.0.4875',
                branch: 'master',
                osName: 'alpine',
                runtimeVersion: '8.0.1',
                appData: '/config',
              ),
            ),
            lidarrHealthProvider(testInstance).overrideWith(
              (ref) async => [
                const HealthResource(
                  id: 1,
                  type: HealthCheckResult.warning,
                  message: 'Indexers unavailable due to failure',
                ),
              ],
            ),
            lidarrDiskSpaceProvider(testInstance).overrideWith(
              (ref) async => [
                const DiskSpaceResource(
                  path: '/data/media/music',
                  freeSpace: 400000000000,
                  totalSpace: 1000000000000,
                ),
              ],
            ),
            lidarrSystemTasksProvider(testInstance).overrideWith(
              (ref) async => [
                const TaskResource(
                  id: 1,
                  name: 'Rescan Folders',
                  interval: 360,
                  lastExecution: '2026-08-15T09:00:00Z',
                ),
              ],
            ),
            lidarrSystemBackupsProvider(testInstance).overrideWith(
              (ref) async => [
                const BackupResource(
                  id: 1,
                  name: 'lidarr_backup_2026.08.15.zip',
                  type: BackupType.scheduled,
                  time: '2026-08-15T00:00:00Z',
                  size: 50000000,
                ),
              ],
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: SystemTab(instance: testInstance),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 1. Status Sub-tab
      expect(find.text('Status'), findsOneWidget);
      expect(find.text('3.1.0.4875'), findsOneWidget);
      expect(find.text('alpine'), findsOneWidget);
      expect(find.text('Indexers unavailable due to failure'), findsOneWidget);

      // 2. Disk Space Sub-tab
      await tester.tap(find.text('Disk Space'));
      await tester.pumpAndSettle();

      expect(find.text('/data/media/music'), findsOneWidget);

      // 3. Tasks Sub-tab & Maintenance Action
      await tester.tap(find.text('Tasks'));
      await tester.pumpAndSettle();

      expect(find.text('Rescan Folders'), findsWidgets);

      // Trigger Maintenance command
      await tester.tap(find.text('Check Health'));
      await tester.pumpAndSettle();

      expect(commandDispatched, equals('CheckHealth'));

      // 4. Backups Sub-tab
      await tester.tap(find.text('Backups'));
      await tester.pumpAndSettle();

      expect(find.text('lidarr_backup_2026.08.15.zip'), findsOneWidget);
    });

    testWidgets(
      'SystemTab Logs and Log Files views support level filtering, log detail view, and file details view',
      (WidgetTester tester) async {
        String? lastQueryLevel;

        final dio = Dio(
          BaseOptions(
            baseUrl: 'http://localhost:8686',
            headers: {'X-Api-Key': 'mock-key'},
          ),
        );

        dio.interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) {
              if (options.method == 'GET' &&
                  options.path == '/api/v1/system/status') {
                return handler.resolve(
                  Response<dynamic>(
                    requestOptions: options,
                    data: {'version': '3.1.0'},
                    statusCode: 200,
                  ),
                );
              }
              if (options.method == 'GET' && options.path == '/api/v1/health') {
                return handler.resolve(
                  Response<dynamic>(
                    requestOptions: options,
                    data: <dynamic>[],
                    statusCode: 200,
                  ),
                );
              }
              if (options.method == 'GET' &&
                  options.path == '/api/v1/diskspace') {
                return handler.resolve(
                  Response<dynamic>(
                    requestOptions: options,
                    data: <dynamic>[],
                    statusCode: 200,
                  ),
                );
              }
              if (options.method == 'GET' &&
                  options.path == '/api/v1/system/task') {
                return handler.resolve(
                  Response<dynamic>(
                    requestOptions: options,
                    data: <dynamic>[],
                    statusCode: 200,
                  ),
                );
              }
              if (options.method == 'GET' &&
                  options.path == '/api/v1/system/backup') {
                return handler.resolve(
                  Response<dynamic>(
                    requestOptions: options,
                    data: <dynamic>[],
                    statusCode: 200,
                  ),
                );
              }
              if (options.method == 'GET' && options.path == '/api/v1/log') {
                lastQueryLevel = options.queryParameters['level'] as String?;

                if (lastQueryLevel == 'error') {
                  return handler.resolve(
                    Response<dynamic>(
                      requestOptions: options,
                      data: {
                        'page': 1,
                        'pageSize': 50,
                        'totalRecords': 1,
                        'records': [
                          {
                            'id': 2,
                            'level': 'error',
                            'logger': 'DownloadService',
                            'message': 'Download failed: connection timeout',
                            'exception': 'SocketException: timeout',
                            'time': '2026-08-15T12:05:00Z',
                          },
                        ],
                      },
                      statusCode: 200,
                    ),
                  );
                }

                return handler.resolve(
                  Response<dynamic>(
                    requestOptions: options,
                    data: {
                      'page': 1,
                      'pageSize': 50,
                      'totalRecords': 1,
                      'records': [
                        {
                          'id': 1,
                          'level': 'info',
                          'logger': 'MediaCoverService',
                          'message': 'Artwork downloaded',
                          'time': '2026-08-15T12:00:00Z',
                        },
                      ],
                    },
                    statusCode: 200,
                  ),
                );
              }
              if (options.method == 'GET' &&
                  options.path == '/api/v1/log/file/lidarr.txt') {
                return handler.resolve(
                  Response<String>(
                    requestOptions: options,
                    data:
                        '[Info] Lidarr.Core: Service started\n[Warn] Indexer: Retry scheduled\n[Error] Database: Lock error',
                    statusCode: 200,
                  ),
                );
              }
              if (options.method == 'GET' &&
                  options.path == '/api/v1/log/file') {
                return handler.resolve(
                  Response<dynamic>(
                    requestOptions: options,
                    data: [
                      {
                        'id': 1,
                        'filename': 'lidarr.txt',
                        'lastWriteTime': '2026-08-15T12:00:00Z',
                        'contentsUrl': '/api/v1/log/file/lidarr.txt',
                        'downloadUrl': '/api/v1/log/file/lidarr.txt',
                      },
                    ],
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
                  .overrideWith((ref) => LidarrApi(dio)),
            ],
            child: const MaterialApp(
              home: Scaffold(
                body: SystemTab(instance: testInstance),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // 1. Navigate to Logs Tab
        await tester.tap(find.text('Logs'));
        await tester.pumpAndSettle();

        expect(find.text('MediaCoverService'), findsOneWidget);
        expect(find.text('Artwork downloaded'), findsOneWidget);

        // Tap log entry to open detail dialog
        await tester.tap(find.text('Artwork downloaded'));
        await tester.pumpAndSettle();

        expect(find.text('Copy'), findsOneWidget);
        expect(find.text('Close'), findsOneWidget);

        await tester.tap(find.text('Copy'));
        await tester.pumpAndSettle();

        // Clear snackbar and Filter logs by Error
        await tester.pump(const Duration(seconds: 4));
        await tester.pumpAndSettle();
        await tester.tap(find.byTooltip('Filter Logs'), warnIfMissed: false);
        await tester.pumpAndSettle();

        expect(find.text('Filter Logs'), findsOneWidget);
        expect(find.text('Error'), findsOneWidget);

        await tester.tap(find.text('Error'));
        await tester.pumpAndSettle();

        expect(lastQueryLevel, equals('error'));
        expect(find.text('DownloadService'), findsOneWidget);
        expect(
          find.text('Download failed: connection timeout'),
          findsOneWidget,
        );

        // 2. Navigate to Log Files Tab
        await tester.tap(find.text('Log Files'));
        await tester.pumpAndSettle();

        expect(find.text('lidarr.txt'), findsOneWidget);

        // Tap Details icon to open details dialog
        await tester.tap(find.byTooltip('Details'));
        await tester.pumpAndSettle();

        expect(find.text('Contents URL'), findsOneWidget);
        expect(find.text('Download URL'), findsOneWidget);
        expect(find.text('Copy Name'), findsOneWidget);
        expect(find.text('Download'), findsOneWidget);
        expect(find.text('Read Log'), findsOneWidget);

        // Tap Read Log inside dialog to navigate to reader screen
        await tester.tap(find.text('Read Log'));
        await tester.pumpAndSettle();

        // Verify reader screen rendered and read contents
        expect(find.byType(LogFileReaderScreen), findsOneWidget);
        expect(
          find.textContaining('Lidarr.Core: Service started'),
          findsOneWidget,
        );
        expect(find.textContaining('Database: Lock error'), findsOneWidget);

        // Test search in reader
        await tester.tap(find.byTooltip('Search in log'));
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextField), 'started');
        await tester.pumpAndSettle();

        expect(find.text('1/1'), findsOneWidget);

        // Test copy in reader
        await tester.tap(find.byTooltip('Close search'));
        await tester.pumpAndSettle();

        await tester.tap(find.byTooltip('Copy all to clipboard'));
        await tester.pumpAndSettle();

        // Pop back to SystemTab
        await tester.tap(find.byType(BackButton));
        await tester.pumpAndSettle();
      },
    );

    testWidgets(
      'SystemTab Updates view renders changelog items and release metadata',
      (tester) async {
        final Dio dio = Dio(
          BaseOptions(
            baseUrl: 'http://127.0.0.1:8686',
            headers: {'X-Api-Key': 'mock-key'},
          ),
        );

        dio.interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) {
              if (options.path == '/api/v1/update') {
                return handler.resolve(
                  Response<dynamic>(
                    requestOptions: options,
                    statusCode: 200,
                    data: [
                      {
                        'id': 1,
                        'version': '2.4.3.4248',
                        'branch': 'master',
                        'releaseDate': '2026-08-10T12:00:00Z',
                        'installed': true,
                        'changes': {
                          'new': ['Added album studio matrix mode'],
                          'fixed': ['Fixed flac parsing logic'],
                        },
                      },
                    ],
                  ),
                );
              }
              if (options.path == '/api/v1/system/status') {
                return handler.resolve(
                  Response<dynamic>(
                    requestOptions: options,
                    statusCode: 200,
                    data: {
                      'version': '2.4.3.4248',
                      'branch': 'master',
                      'appName': 'Lidarr',
                    },
                  ),
                );
              }
              if (options.path == '/api/v1/health') {
                return handler.resolve(
                  Response<dynamic>(
                    requestOptions: options,
                    statusCode: 200,
                    data: <Map<String, dynamic>>[],
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
                  .overrideWith((ref) => LidarrApi(dio)),
            ],
            child: const MaterialApp(
              home: Scaffold(
                body: SystemTab(instance: testInstance),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Switch to Updates sub-tab
        await tester.ensureVisible(find.text('Updates'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Updates'));
        await tester.pumpAndSettle();

        expect(find.text('v2.4.3.4248'), findsOneWidget);
        expect(find.text('Installed'), findsOneWidget);
        expect(find.text('Added album studio matrix mode'), findsOneWidget);
        expect(find.text('Fixed flac parsing logic'), findsOneWidget);
      },
    );
  });
}
