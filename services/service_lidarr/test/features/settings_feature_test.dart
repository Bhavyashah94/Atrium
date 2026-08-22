import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:service_lidarr/service_lidarr.dart';

import 'test_helpers.dart';

void main() {
  group('Lidarr Settings Feature Widget Tests', () {
    testWidgets(
        'SettingsTab renders Profiles, Root Folders, Tags, Indexers, and Download Clients',
        (tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            lidarrQualityProfilesProvider(testInstance).overrideWith(
              (ref) async => [
                const QualityProfileResource(
                  id: 1,
                  name: 'Lossless Audio',
                  upgradeAllowed: true,
                  cutoff: 1005,
                ),
              ],
            ),
            lidarrMetadataProfilesProvider(testInstance).overrideWith(
              (ref) async => [
                const MetadataProfileResource(
                  id: 1,
                  name: 'Standard Music',
                ),
              ],
            ),
            lidarrRootFoldersProvider(testInstance).overrideWith(
              (ref) async => [
                const RootFolderResource(
                  id: 1,
                  path: '/data/media/music',
                  freeSpace: 500000000000,
                  accessible: true,
                ),
              ],
            ),
            lidarrTagsProvider(testInstance).overrideWith(
              (ref) async => [
                const TagResource(id: 1, label: 'favorites'),
              ],
            ),
            lidarrIndexersProvider(testInstance).overrideWith(
              (ref) async => [
                const IndexerResource(
                  id: 1,
                  name: 'Nyaa.si',
                  protocol: DownloadProtocol.torrent,
                  enableAutomaticSearch: true,
                  enableRss: true,
                ),
              ],
            ),
            lidarrDownloadClientsProvider(testInstance).overrideWith(
              (ref) async => [
                const DownloadClientResource(
                  id: 1,
                  name: 'qBittorrent',
                  protocol: DownloadProtocol.torrent,
                  enable: true,
                  implementationName: 'qBittorrent',
                ),
              ],
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: SettingsTab(instance: testInstance),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 1. Profiles Card
      expect(find.text('Profiles'), findsOneWidget);
      await tester.tap(find.text('Profiles'));
      await tester.pumpAndSettle();

      expect(find.text('Lossless Audio'), findsOneWidget);
      expect(find.text('Standard Music'), findsOneWidget);

      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      // 2. Root Folders Card
      await tester.tap(find.text('Root Folders'));
      await tester.pumpAndSettle();

      expect(find.text('/data/media/music'), findsOneWidget);

      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      // 3. Tags Card
      await tester.tap(find.text('Tags'));
      await tester.pumpAndSettle();

      expect(find.text('favorites'), findsOneWidget);

      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      // 4. Indexers Card
      await tester.tap(find.text('Indexers'));
      await tester.pumpAndSettle();

      expect(find.text('Nyaa.si'), findsOneWidget);

      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      // 5. Download Clients Card
      await tester.tap(find.text('Download Clients'));
      await tester.pumpAndSettle();

      expect(find.text('qBittorrent'), findsWidgets);
    });

    testWidgets(
      'SettingsTab Indexers section supports adding via preset, schema editing, connection testing, updating, and deleting',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(1200, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        bool postTestCalled = false;
        bool postIndexerCalled = false;
        bool putIndexerCalled = false;
        bool deleteIndexerCalled = false;

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
                  options.path == '/api/v1/qualityprofile') {
                return handler.resolve(
                  Response<dynamic>(
                    requestOptions: options,
                    data: <dynamic>[],
                    statusCode: 200,
                  ),
                );
              }
              if (options.method == 'GET' &&
                  options.path == '/api/v1/metadataprofile') {
                return handler.resolve(
                  Response<dynamic>(
                    requestOptions: options,
                    data: <dynamic>[],
                    statusCode: 200,
                  ),
                );
              }
              if (options.method == 'GET' &&
                  options.path == '/api/v1/indexer') {
                return handler.resolve(
                  Response<dynamic>(
                    requestOptions: options,
                    data: [
                      {
                        'id': 1,
                        'name': 'Existing Indexer',
                        'protocol': 'torrent',
                        'enableRss': true,
                        'enableAutomaticSearch': true,
                        'enableInteractiveSearch': true,
                        'fields': [
                          {
                            'name': 'baseUrl',
                            'label': 'URL',
                            'type': 'textbox',
                            'value': 'https://existing.indexer',
                          },
                        ],
                      },
                    ],
                    statusCode: 200,
                  ),
                );
              }
              if (options.method == 'GET' &&
                  options.path == '/api/v1/indexer/schema') {
                return handler.resolve(
                  Response<dynamic>(
                    requestOptions: options,
                    data: [
                      {
                        'name': 'Torznab',
                        'implementationName': 'Torznab',
                        'protocol': 'torrent',
                        'fields': [
                          {
                            'name': 'baseUrl',
                            'label': 'URL',
                            'type': 'textbox',
                            'value': 'https://torznab.site',
                          },
                          {
                            'name': 'apiKey',
                            'label': 'API Key',
                            'type': 'password',
                            'value': 'secret-key',
                          },
                        ],
                      },
                    ],
                    statusCode: 200,
                  ),
                );
              }
              if (options.method == 'POST' &&
                  options.path == '/api/v1/indexer/test') {
                postTestCalled = true;
                return handler.resolve(
                  Response<dynamic>(
                    requestOptions: options,
                    statusCode: 200,
                  ),
                );
              }
              if (options.method == 'POST' &&
                  options.path == '/api/v1/indexer') {
                postIndexerCalled = true;
                return handler.resolve(
                  Response<dynamic>(
                    requestOptions: options,
                    data: {'id': 2, 'name': 'Torznab'},
                    statusCode: 201,
                  ),
                );
              }
              if (options.method == 'PUT' &&
                  options.path.startsWith('/api/v1/indexer/1')) {
                putIndexerCalled = true;
                return handler.resolve(
                  Response<dynamic>(
                    requestOptions: options,
                    data: {'id': 1, 'name': 'Existing Indexer'},
                    statusCode: 200,
                  ),
                );
              }
              if (options.method == 'DELETE' &&
                  options.path.startsWith('/api/v1/indexer/1')) {
                deleteIndexerCalled = true;
                return handler.resolve(
                  Response<dynamic>(
                    requestOptions: options,
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
                body: SettingsTab(instance: testInstance),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Navigate to Indexers sub-page
        await tester.tap(find.text('Indexers'));
        await tester.pumpAndSettle();

        expect(find.text('Existing Indexer'), findsOneWidget);
        expect(find.byTooltip('Add Indexer'), findsOneWidget);

        // 1. Add Indexer flow
        await tester.tap(find.byTooltip('Add Indexer'));
        await tester.pumpAndSettle();

        expect(find.text('Add Indexer'), findsOneWidget);
        expect(find.text('Torznab'), findsWidgets);

        await tester.tap(find.text('Torznab').first);
        await tester.pumpAndSettle();

        expect(find.text('Add Torznab'), findsOneWidget);
        expect(find.text('Test'), findsOneWidget);
        expect(find.text('Save'), findsOneWidget);

        // Test connection
        await tester.tap(find.text('Test'));
        await tester.pumpAndSettle();
        expect(postTestCalled, isTrue);
        expect(find.text('Connection Test Successful!'), findsOneWidget);

        // Save new indexer
        await tester.tap(find.text('Save'));
        await tester.pumpAndSettle();
        expect(postIndexerCalled, isTrue);

        // Clear SnackBars
        tester
            .state<ScaffoldMessengerState>(find.byType(ScaffoldMessenger))
            .clearSnackBars();
        await tester.pumpAndSettle();

        // 2. Edit existing indexer flow
        await tester.tap(find.text('Existing Indexer'));
        await tester.pumpAndSettle();

        expect(find.text('Edit Existing Indexer'), findsOneWidget);
        await tester.tap(find.text('Save'));
        await tester.pumpAndSettle();
        expect(putIndexerCalled, isTrue);

        // Clear SnackBars
        tester
            .state<ScaffoldMessengerState>(find.byType(ScaffoldMessenger))
            .clearSnackBars();
        await tester.pumpAndSettle();

        // 3. Delete existing indexer flow
        await tester.tap(find.byTooltip('Delete Indexer'));
        await tester.pumpAndSettle();

        expect(find.text('Delete Existing Indexer?'), findsOneWidget);
        await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
        await tester.pumpAndSettle();

        expect(deleteIndexerCalled, isTrue);
      },
    );

    testWidgets(
      'SettingsTab Download Clients section supports adding via preset, schema editing, connection testing, updating, and deleting',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(1200, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        bool postTestCalled = false;
        bool postClientCalled = false;
        bool putClientCalled = false;
        bool deleteClientCalled = false;

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
                  options.path == '/api/v1/qualityprofile') {
                return handler.resolve(
                  Response<dynamic>(
                    requestOptions: options,
                    data: <dynamic>[],
                    statusCode: 200,
                  ),
                );
              }
              if (options.method == 'GET' &&
                  options.path == '/api/v1/metadataprofile') {
                return handler.resolve(
                  Response<dynamic>(
                    requestOptions: options,
                    data: <dynamic>[],
                    statusCode: 200,
                  ),
                );
              }
              if (options.method == 'GET' &&
                  options.path == '/api/v1/downloadclient') {
                return handler.resolve(
                  Response<dynamic>(
                    requestOptions: options,
                    data: [
                      {
                        'id': 1,
                        'name': 'Existing qBittorrent',
                        'implementationName': 'qBittorrent',
                        'protocol': 'torrent',
                        'enable': true,
                        'fields': [
                          {
                            'name': 'host',
                            'label': 'Host',
                            'type': 'textbox',
                            'value': 'localhost',
                          },
                        ],
                      },
                    ],
                    statusCode: 200,
                  ),
                );
              }
              if (options.method == 'GET' &&
                  options.path == '/api/v1/downloadclient/schema') {
                return handler.resolve(
                  Response<dynamic>(
                    requestOptions: options,
                    data: [
                      {
                        'name': 'SABnzbd',
                        'implementationName': 'SABnzbd',
                        'protocol': 'usenet',
                        'fields': [
                          {
                            'name': 'host',
                            'label': 'Host',
                            'type': 'textbox',
                            'value': 'localhost',
                          },
                          {
                            'name': 'apiKey',
                            'label': 'API Key',
                            'type': 'password',
                            'value': 'sab-secret',
                          },
                        ],
                      },
                    ],
                    statusCode: 200,
                  ),
                );
              }
              if (options.method == 'POST' &&
                  options.path == '/api/v1/downloadclient/test') {
                postTestCalled = true;
                return handler.resolve(
                  Response<dynamic>(
                    requestOptions: options,
                    statusCode: 200,
                  ),
                );
              }
              if (options.method == 'POST' &&
                  options.path == '/api/v1/downloadclient') {
                postClientCalled = true;
                return handler.resolve(
                  Response<dynamic>(
                    requestOptions: options,
                    data: {'id': 2, 'name': 'SABnzbd'},
                    statusCode: 201,
                  ),
                );
              }
              if (options.method == 'PUT' &&
                  options.path.startsWith('/api/v1/downloadclient/1')) {
                putClientCalled = true;
                return handler.resolve(
                  Response<dynamic>(
                    requestOptions: options,
                    data: {'id': 1, 'name': 'Existing qBittorrent'},
                    statusCode: 200,
                  ),
                );
              }
              if (options.method == 'DELETE' &&
                  options.path.startsWith('/api/v1/downloadclient/1')) {
                deleteClientCalled = true;
                return handler.resolve(
                  Response<dynamic>(
                    requestOptions: options,
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
                body: SettingsTab(instance: testInstance),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Navigate to Download Clients sub-page
        await tester.tap(find.text('Download Clients'));
        await tester.pumpAndSettle();

        expect(find.text('Existing qBittorrent'), findsOneWidget);
        expect(find.byTooltip('Add Download Client'), findsOneWidget);

        // 1. Add Download Client flow
        await tester.tap(find.byTooltip('Add Download Client'));
        await tester.pumpAndSettle();

        expect(find.text('Add Download Client'), findsOneWidget);
        expect(find.text('SABnzbd'), findsWidgets);

        await tester.tap(find.text('SABnzbd').first);
        await tester.pumpAndSettle();

        expect(find.text('Add SABnzbd'), findsOneWidget);
        expect(find.text('Test'), findsOneWidget);
        expect(find.text('Save'), findsOneWidget);

        // Test connection
        await tester.tap(find.text('Test'));
        await tester.pumpAndSettle();
        expect(postTestCalled, isTrue);
        expect(find.text('Connection Test Successful!'), findsOneWidget);

        // Save new client
        await tester.tap(find.text('Save'));
        await tester.pumpAndSettle();
        expect(postClientCalled, isTrue);

        // Clear SnackBars
        tester
            .state<ScaffoldMessengerState>(find.byType(ScaffoldMessenger))
            .clearSnackBars();
        await tester.pumpAndSettle();

        // 2. Edit existing client flow
        await tester.tap(find.text('Existing qBittorrent'));
        await tester.pumpAndSettle();

        expect(find.text('Edit Existing qBittorrent'), findsOneWidget);
        await tester.tap(find.text('Save'));
        await tester.pumpAndSettle();
        expect(putClientCalled, isTrue);

        // Clear SnackBars
        tester
            .state<ScaffoldMessengerState>(find.byType(ScaffoldMessenger))
            .clearSnackBars();
        await tester.pumpAndSettle();

        // 3. Delete existing client flow
        await tester.tap(find.byTooltip('Delete Client'));
        await tester.pumpAndSettle();

        expect(find.text('Delete Existing qBittorrent?'), findsOneWidget);
        await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
        await tester.pumpAndSettle();

        expect(deleteClientCalled, isTrue);
      },
    );

    testWidgets(
      'SettingsTab renders Connect notifications, adds from preset, and deletes',
      (tester) async {
        tester.view.physicalSize = const Size(1400, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        bool postNotificationCalled = false;
        bool testNotificationCalled = false;
        bool deleteNotificationCalled = false;

        final dio = Dio(BaseOptions(baseUrl: 'http://localhost:8686/'));
        dio.interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) {
              if (options.path == '/api/v1/qualityprofile') {
                return handler.resolve(
                  Response<dynamic>(
                    requestOptions: options,
                    data: [
                      {'id': 1, 'name': 'Any', 'upgradeAllowed': true},
                    ],
                    statusCode: 200,
                  ),
                );
              }
              if (options.path == '/api/v1/metadataprofile') {
                return handler.resolve(
                  Response<dynamic>(
                    requestOptions: options,
                    data: [
                      {'id': 1, 'name': 'Standard'},
                    ],
                    statusCode: 200,
                  ),
                );
              }
              if (options.path == '/api/v1/rootfolder') {
                return handler.resolve(
                  Response<dynamic>(
                    requestOptions: options,
                    data: [
                      {'id': 1, 'path': '/data/music', 'freeSpace': 500000000},
                    ],
                    statusCode: 200,
                  ),
                );
              }
              if (options.path == '/api/v1/tag') {
                return handler.resolve(
                  Response<dynamic>(
                    requestOptions: options,
                    data: [
                      {'id': 1, 'label': 'flac'},
                    ],
                    statusCode: 200,
                  ),
                );
              }
              if (options.path == '/api/v1/indexer') {
                return handler.resolve(
                  Response<dynamic>(
                    requestOptions: options,
                    data: <Map<String, dynamic>>[],
                    statusCode: 200,
                  ),
                );
              }
              if (options.path == '/api/v1/downloadclient') {
                return handler.resolve(
                  Response<dynamic>(
                    requestOptions: options,
                    data: <Map<String, dynamic>>[],
                    statusCode: 200,
                  ),
                );
              }
              if (options.path == '/api/v1/notification/schema') {
                return handler.resolve(
                  Response<dynamic>(
                    requestOptions: options,
                    data: [
                      {
                        'id': 0,
                        'name': 'Discord',
                        'implementationName': 'Discord Webhook',
                        'implementation': 'Discord',
                        'configContract': 'DiscordSettings',
                        'fields': [
                          {
                            'name': 'webHookUrl',
                            'label': 'Webhook URL',
                            'type': 'textbox',
                            'value': '',
                          },
                        ],
                      },
                      {
                        'id': 0,
                        'name': 'Telegram',
                        'implementationName': 'Telegram Bot',
                        'implementation': 'Telegram',
                        'configContract': 'TelegramSettings',
                        'fields': [
                          {
                            'name': 'botToken',
                            'label': 'Bot Token',
                            'type': 'textbox',
                            'value': '',
                          },
                          {
                            'name': 'chatId',
                            'label': 'Chat ID',
                            'type': 'textbox',
                            'value': '',
                          },
                        ],
                      },
                    ],
                    statusCode: 200,
                  ),
                );
              }
              if (options.method == 'GET' &&
                  options.path == '/api/v1/notification') {
                return handler.resolve(
                  Response<dynamic>(
                    requestOptions: options,
                    data: [
                      {
                        'id': 1,
                        'name': 'My Discord Alerts',
                        'implementationName': 'Discord Webhook',
                        'implementation': 'Discord',
                        'configContract': 'DiscordSettings',
                        'onGrab': true,
                        'onReleaseImport': true,
                        'onUpgrade': true,
                        'onHealthIssue': true,
                        'fields': [
                          {
                            'name': 'webHookUrl',
                            'label': 'Webhook URL',
                            'type': 'textbox',
                            'value': 'https://discord.com/api/webhooks/123/abc',
                          },
                        ],
                      },
                    ],
                    statusCode: 200,
                  ),
                );
              }
              if (options.method == 'POST' &&
                  options.path == '/api/v1/notification/test') {
                testNotificationCalled = true;
                return handler.resolve(
                  Response<dynamic>(
                    requestOptions: options,
                    statusCode: 200,
                  ),
                );
              }
              if (options.method == 'POST' &&
                  options.path == '/api/v1/notification') {
                postNotificationCalled = true;
                return handler.resolve(
                  Response<dynamic>(
                    requestOptions: options,
                    data: options.data,
                    statusCode: 201,
                  ),
                );
              }
              if (options.method == 'DELETE' &&
                  options.path == '/api/v1/notification/1') {
                deleteNotificationCalled = true;
                return handler.resolve(
                  Response<dynamic>(
                    requestOptions: options,
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
                body: SettingsTab(instance: testInstance),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Navigate to Connect sub-page
        await tester.tap(find.text('Connect'));
        await tester.pumpAndSettle();

        expect(
          find.text('Discord Webhook • Grab, Import, Upgrade, Health'),
          findsOneWidget,
        );

        // Test connection in editor
        await tester.tap(find.text('My Discord Alerts'));
        await tester.pumpAndSettle();

        expect(find.text('Edit My Discord Alerts'), findsOneWidget);
        expect(find.text('Trigger Events'), findsOneWidget);
        expect(find.text('Test'), findsOneWidget);

        await tester.tap(find.text('Test'));
        await tester.pumpAndSettle();

        expect(testNotificationCalled, isTrue);

        // Close editor
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();

        // Add Telegram notification
        await tester.tap(find.byTooltip('Add Notification'));
        await tester.pumpAndSettle();

        expect(find.text('Add Notification Integration'), findsOneWidget);
        expect(find.text('Telegram'), findsOneWidget);

        await tester.tap(find.text('Telegram'));
        await tester.pumpAndSettle();

        expect(find.text('Add Telegram'), findsOneWidget);

        // Save
        await tester.tap(find.text('Save'));
        await tester.pumpAndSettle();

        expect(postNotificationCalled, isTrue);

        // Delete notification
        await tester.tap(find.byTooltip('Delete Notification'));
        await tester.pumpAndSettle();

        expect(find.text('Delete My Discord Alerts?'), findsOneWidget);
        await tester.tap(find.text('Delete'));
        await tester.pumpAndSettle();

        expect(deleteNotificationCalled, isTrue);
      },
    );

    testWidgets(
      'SettingsTab Profiles section supports Quality Profiles CRUD and Metadata Profiles CRUD',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        bool postQualityCalled = false;
        bool putQualityCalled = false;
        bool deleteQualityCalled = false;
        bool postMetadataCalled = false;
        bool putMetadataCalled = false;
        bool deleteMetadataCalled = false;
        bool postDelayCalled = false;
        bool putDelayCalled = false;
        bool deleteDelayCalled = false;
        bool postReleaseCalled = false;
        bool putReleaseCalled = false;
        bool deleteReleaseCalled = false;

        final dio = Dio(BaseOptions(baseUrl: 'http://localhost:8686/'));
        dio.interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) {
              if (options.path == '/api/v1/qualityprofile/schema') {
                return handler.resolve(
                  Response<dynamic>(
                    requestOptions: options,
                    data: {
                      'id': 0,
                      'name': '',
                      'upgradeAllowed': true,
                      'cutoff': 1,
                      'items': [
                        {
                          'id': 1,
                          'name': 'FLAC',
                          'quality': {'id': 1, 'name': 'FLAC'},
                          'allowed': true,
                        },
                        {
                          'id': 2,
                          'name': 'MP3',
                          'quality': {'id': 2, 'name': 'MP3'},
                          'allowed': true,
                        },
                      ],
                    },
                    statusCode: 200,
                  ),
                );
              }
              if (options.path == '/api/v1/metadataprofile/schema') {
                return handler.resolve(
                  Response<dynamic>(
                    requestOptions: options,
                    data: {
                      'id': 0,
                      'name': '',
                      'primaryAlbumTypes': [
                        {
                          'id': 1,
                          'albumType': {'id': 1, 'name': 'Studio'},
                          'allowed': true,
                        },
                        {
                          'id': 2,
                          'albumType': {'id': 2, 'name': 'Live'},
                          'allowed': false,
                        },
                      ],
                      'secondaryAlbumTypes': [
                        {
                          'id': 1,
                          'albumType': {'id': 1, 'name': 'Remix'},
                          'allowed': false,
                        },
                      ],
                      'releaseStatuses': [
                        {
                          'id': 1,
                          'releaseStatus': {'id': 1, 'name': 'Official'},
                          'allowed': true,
                        },
                      ],
                    },
                    statusCode: 200,
                  ),
                );
              }
              if (options.method == 'GET' &&
                  options.path == '/api/v1/qualityprofile') {
                return handler.resolve(
                  Response<dynamic>(
                    requestOptions: options,
                    data: [
                      {
                        'id': 1,
                        'name': 'Standard Lossless',
                        'upgradeAllowed': true,
                        'cutoff': 1,
                        'items': [
                          {
                            'id': 1,
                            'name': 'FLAC',
                            'quality': {'id': 1, 'name': 'FLAC'},
                            'allowed': true,
                          },
                        ],
                      },
                    ],
                    statusCode: 200,
                  ),
                );
              }
              if (options.method == 'GET' &&
                  options.path == '/api/v1/metadataprofile') {
                return handler.resolve(
                  Response<dynamic>(
                    requestOptions: options,
                    data: [
                      {
                        'id': 1,
                        'name': 'Standard Discography',
                        'primaryAlbumTypes': [
                          {
                            'id': 1,
                            'albumType': {'id': 1, 'name': 'Studio'},
                            'allowed': true,
                          },
                        ],
                        'secondaryAlbumTypes': <Map<String, dynamic>>[],
                        'releaseStatuses': [
                          {
                            'id': 1,
                            'releaseStatus': {'id': 1, 'name': 'Official'},
                            'allowed': true,
                          },
                        ],
                      },
                    ],
                    statusCode: 200,
                  ),
                );
              }
              if (options.method == 'POST' &&
                  options.path == '/api/v1/qualityprofile') {
                postQualityCalled = true;
                return handler.resolve(
                  Response<dynamic>(
                    requestOptions: options,
                    data: options.data,
                    statusCode: 201,
                  ),
                );
              }
              if (options.method == 'PUT' &&
                  options.path == '/api/v1/qualityprofile/1') {
                putQualityCalled = true;
                return handler.resolve(
                  Response<dynamic>(
                    requestOptions: options,
                    data: options.data,
                    statusCode: 200,
                  ),
                );
              }
              if (options.method == 'DELETE' &&
                  options.path == '/api/v1/qualityprofile/1') {
                deleteQualityCalled = true;
                return handler.resolve(
                  Response<dynamic>(
                    requestOptions: options,
                    statusCode: 200,
                  ),
                );
              }
              if (options.method == 'POST' &&
                  options.path == '/api/v1/metadataprofile') {
                postMetadataCalled = true;
                return handler.resolve(
                  Response<dynamic>(
                    requestOptions: options,
                    data: options.data,
                    statusCode: 201,
                  ),
                );
              }
              if (options.method == 'PUT' &&
                  options.path == '/api/v1/metadataprofile/1') {
                putMetadataCalled = true;
                return handler.resolve(
                  Response<dynamic>(
                    requestOptions: options,
                    data: options.data,
                    statusCode: 200,
                  ),
                );
              }
              if (options.method == 'DELETE' &&
                  options.path == '/api/v1/metadataprofile/1') {
                deleteMetadataCalled = true;
                return handler.resolve(
                  Response<dynamic>(
                    requestOptions: options,
                    statusCode: 200,
                  ),
                );
              }
              if (options.path == '/api/v1/delayprofile') {
                if (options.method == 'GET') {
                  return handler.resolve(
                    Response<dynamic>(
                      requestOptions: options,
                      data: [
                        {
                          'id': 1,
                          'enableUsenet': true,
                          'enableTorrent': true,
                          'preferredProtocol': 'usenet',
                          'usenetDelay': 0,
                          'torrentDelay': 120,
                          'bypassIfHighestQuality': true,
                          'bypassIfAboveCustomFormatScore': false,
                          'minimumCustomFormatScore': 0,
                          'tags': <int>[],
                        },
                      ],
                      statusCode: 200,
                    ),
                  );
                }
                if (options.method == 'POST') {
                  postDelayCalled = true;
                  return handler.resolve(
                    Response<dynamic>(
                      requestOptions: options,
                      data: options.data,
                      statusCode: 201,
                    ),
                  );
                }
              }
              if (options.method == 'PUT' &&
                  options.path == '/api/v1/delayprofile/1') {
                putDelayCalled = true;
                return handler.resolve(
                  Response<dynamic>(
                    requestOptions: options,
                    data: options.data,
                    statusCode: 200,
                  ),
                );
              }
              if (options.method == 'DELETE' &&
                  options.path == '/api/v1/delayprofile/1') {
                deleteDelayCalled = true;
                return handler.resolve(
                  Response<dynamic>(
                    requestOptions: options,
                    statusCode: 200,
                  ),
                );
              }
              if (options.path == '/api/v1/releaseprofile') {
                if (options.method == 'GET') {
                  return handler.resolve(
                    Response<dynamic>(
                      requestOptions: options,
                      data: [
                        {
                          'id': 1,
                          'enabled': true,
                          'required': ['FLAC'],
                          'ignored': ['Live'],
                          'indexerId': 0,
                          'tags': <int>[],
                        },
                      ],
                      statusCode: 200,
                    ),
                  );
                }
                if (options.method == 'POST') {
                  postReleaseCalled = true;
                  return handler.resolve(
                    Response<dynamic>(
                      requestOptions: options,
                      data: options.data,
                      statusCode: 201,
                    ),
                  );
                }
              }
              if (options.method == 'PUT' &&
                  options.path == '/api/v1/releaseprofile/1') {
                putReleaseCalled = true;
                return handler.resolve(
                  Response<dynamic>(
                    requestOptions: options,
                    data: options.data,
                    statusCode: 200,
                  ),
                );
              }
              if (options.method == 'DELETE' &&
                  options.path == '/api/v1/releaseprofile/1') {
                deleteReleaseCalled = true;
                return handler.resolve(
                  Response<dynamic>(
                    requestOptions: options,
                    statusCode: 200,
                  ),
                );
              }
              if (options.path == '/api/v1/rootfolder') {
                return handler.resolve(
                  Response<dynamic>(
                    requestOptions: options,
                    data: <Map<String, dynamic>>[],
                    statusCode: 200,
                  ),
                );
              }
              if (options.path == '/api/v1/tag') {
                return handler.resolve(
                  Response<dynamic>(
                    requestOptions: options,
                    data: <Map<String, dynamic>>[],
                    statusCode: 200,
                  ),
                );
              }
              if (options.path == '/api/v1/indexer') {
                return handler.resolve(
                  Response<dynamic>(
                    requestOptions: options,
                    data: <Map<String, dynamic>>[],
                    statusCode: 200,
                  ),
                );
              }
              if (options.path == '/api/v1/downloadclient') {
                return handler.resolve(
                  Response<dynamic>(
                    requestOptions: options,
                    data: <Map<String, dynamic>>[],
                    statusCode: 200,
                  ),
                );
              }
              if (options.path == '/api/v1/notification') {
                return handler.resolve(
                  Response<dynamic>(
                    requestOptions: options,
                    data: <Map<String, dynamic>>[],
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
                body: SettingsTab(instance: testInstance),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Navigate to Profiles sub-page
        await tester.tap(find.text('Profiles'));
        await tester.pumpAndSettle();

        // 1. Verify Quality Profiles overview
        expect(find.text('Standard Lossless'), findsOneWidget);
        expect(find.text('1 qualities'), findsOneWidget);

        // 2. Edit existing Quality Profile
        await tester.tap(find.text('Standard Lossless'));
        await tester.pumpAndSettle();

        expect(find.text('Edit Quality Profile'), findsOneWidget);
        expect(find.text('Qualities (Allowed)'), findsOneWidget);

        await tester.tap(find.text('Save'));
        await tester.pumpAndSettle();

        expect(putQualityCalled, isTrue);

        // 3. Add new Quality Profile
        await tester.tap(find.byTooltip('Add Quality Profile'));
        await tester.pumpAndSettle();

        expect(find.text('Add Quality Profile'), findsOneWidget);
        await tester.enterText(
          find.widgetWithText(TextField, 'Profile Name'),
          'Ultra Hi-Res',
        );
        await tester.tap(find.text('Save'));
        await tester.pumpAndSettle();

        expect(postQualityCalled, isTrue);

        // 4. Delete Quality Profile
        await tester.tap(find.byTooltip('Delete Quality Profile'));
        await tester.pumpAndSettle();

        expect(find.text('Delete Standard Lossless?'), findsOneWidget);
        await tester.tap(find.text('Delete'));
        await tester.pumpAndSettle();

        expect(deleteQualityCalled, isTrue);

        // 5. Edit existing Metadata Profile
        expect(find.text('Standard Discography'), findsOneWidget);
        await tester.tap(find.text('Standard Discography'));
        await tester.pumpAndSettle();

        expect(find.text('Edit Metadata Profile'), findsOneWidget);
        expect(find.text('Primary Album Types'), findsOneWidget);

        await tester.tap(find.text('Save'));
        await tester.pumpAndSettle();

        expect(putMetadataCalled, isTrue);

        // 6. Add new Metadata Profile
        await tester.tap(find.byTooltip('Add Metadata Profile'));
        await tester.pumpAndSettle();

        expect(find.text('Add Metadata Profile'), findsOneWidget);
        await tester.enterText(
          find.widgetWithText(TextField, 'Profile Name'),
          'All Releases',
        );
        await tester.tap(find.text('Save'));
        await tester.pumpAndSettle();

        expect(postMetadataCalled, isTrue);

        // 7. Delete Metadata Profile
        await tester.tap(find.byTooltip('Delete Metadata Profile'));
        await tester.pumpAndSettle();

        expect(find.text('Delete Standard Discography?'), findsOneWidget);
        await tester.tap(find.text('Delete'));
        await tester.pumpAndSettle();

        expect(deleteMetadataCalled, isTrue);

        // 8. Delay Profiles CRUD
        expect(find.text('Preferred: USENET'), findsOneWidget);
        await tester.tap(find.text('Preferred: USENET'));
        await tester.pumpAndSettle();
        expect(find.text('Edit Delay Profile'), findsOneWidget);
        await tester.tap(find.text('Save'));
        await tester.pumpAndSettle();
        expect(putDelayCalled, isTrue);

        await tester.tap(find.byTooltip('Add Delay Profile'));
        await tester.pumpAndSettle();
        expect(find.text('Add Delay Profile'), findsOneWidget);
        await tester.tap(find.text('Save'));
        await tester.pumpAndSettle();
        expect(postDelayCalled, isTrue);

        await tester.tap(find.byTooltip('Delete Delay Profile'));
        await tester.pumpAndSettle();
        expect(find.text('Delete Delay Profile?'), findsOneWidget);
        await tester.tap(find.text('Delete'));
        await tester.pumpAndSettle();
        expect(deleteDelayCalled, isTrue);

        // 9. Release Profiles CRUD
        expect(find.text('Release Filter (Active)'), findsOneWidget);
        await tester.tap(find.text('Release Filter (Active)'));
        await tester.pumpAndSettle();
        expect(find.text('Edit Release Profile'), findsOneWidget);
        await tester.tap(find.text('Save'));
        await tester.pumpAndSettle();
        expect(putReleaseCalled, isTrue);

        await tester.tap(find.byTooltip('Add Release Profile'));
        await tester.pumpAndSettle();
        expect(find.text('Add Release Profile'), findsOneWidget);
        await tester.tap(find.text('Save'));
        await tester.pumpAndSettle();
        expect(postReleaseCalled, isTrue);

        await tester.tap(find.byTooltip('Delete Release Profile'));
        await tester.pumpAndSettle();
        expect(find.text('Delete Release Profile?'), findsOneWidget);
        await tester.tap(find.text('Delete'));
        await tester.pumpAndSettle();
        expect(deleteReleaseCalled, isTrue);
      },
    );

    testWidgets(
      'SettingsTab Import Lists section supports adding via preset, schema editing, connection testing, updating, and deleting',
      (tester) async {
        tester.view.physicalSize = const Size(1400, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        bool postListCalled = false;
        bool putListCalled = false;
        bool deleteListCalled = false;
        bool testListCalled = false;

        final dio = Dio(BaseOptions(baseUrl: 'http://localhost:8686/'));
        dio.interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) {
              if (options.path == '/api/v1/importlist/schema') {
                return handler.resolve(
                  Response<dynamic>(
                    requestOptions: options,
                    data: [
                      {
                        'id': 0,
                        'name': 'Spotify Playlist',
                        'implementationName': 'Spotify',
                        'enableAutomaticAdd': true,
                        'fields': [
                          {
                            'name': 'playlistId',
                            'value': '',
                            'type': 'textbox',
                            'advanced': false,
                          },
                        ],
                      },
                      {
                        'id': 0,
                        'name': 'Last.fm User Library',
                        'implementationName': 'Last.fm',
                        'enableAutomaticAdd': true,
                        'fields': [
                          {
                            'name': 'username',
                            'value': '',
                            'type': 'textbox',
                            'advanced': false,
                          },
                        ],
                      },
                    ],
                    statusCode: 200,
                  ),
                );
              }
              if (options.method == 'GET' &&
                  options.path == '/api/v1/importlist') {
                return handler.resolve(
                  Response<dynamic>(
                    requestOptions: options,
                    data: [
                      {
                        'id': 1,
                        'name': 'My Spotify Top',
                        'implementationName': 'Spotify',
                        'enableAutomaticAdd': true,
                        'fields': [
                          {
                            'name': 'playlistId',
                            'value': '37i9dQZF1DXcBWIGoYBM5M',
                            'type': 'textbox',
                            'advanced': false,
                          },
                        ],
                      },
                    ],
                    statusCode: 200,
                  ),
                );
              }
              if (options.method == 'POST' &&
                  options.path == '/api/v1/importlist/test') {
                testListCalled = true;
                return handler.resolve(
                  Response<dynamic>(
                    requestOptions: options,
                    statusCode: 200,
                  ),
                );
              }
              if (options.method == 'POST' &&
                  options.path == '/api/v1/importlist') {
                postListCalled = true;
                return handler.resolve(
                  Response<dynamic>(
                    requestOptions: options,
                    data: options.data,
                    statusCode: 201,
                  ),
                );
              }
              if (options.method == 'PUT' &&
                  options.path == '/api/v1/importlist/1') {
                putListCalled = true;
                return handler.resolve(
                  Response<dynamic>(
                    requestOptions: options,
                    data: options.data,
                    statusCode: 200,
                  ),
                );
              }
              if (options.method == 'DELETE' &&
                  options.path == '/api/v1/importlist/1') {
                deleteListCalled = true;
                return handler.resolve(
                  Response<dynamic>(
                    requestOptions: options,
                    statusCode: 200,
                  ),
                );
              }
              if (options.path == '/api/v1/qualityprofile') {
                return handler.resolve(
                  Response<dynamic>(
                    requestOptions: options,
                    data: <Map<String, dynamic>>[],
                    statusCode: 200,
                  ),
                );
              }
              if (options.path == '/api/v1/metadataprofile') {
                return handler.resolve(
                  Response<dynamic>(
                    requestOptions: options,
                    data: <Map<String, dynamic>>[],
                    statusCode: 200,
                  ),
                );
              }
              if (options.path == '/api/v1/qualityprofile/schema') {
                return handler.resolve(
                  Response<dynamic>(
                    requestOptions: options,
                    data: {
                      'id': 0,
                      'name': '',
                      'items': <Map<String, dynamic>>[],
                    },
                    statusCode: 200,
                  ),
                );
              }
              if (options.path == '/api/v1/metadataprofile/schema') {
                return handler.resolve(
                  Response<dynamic>(
                    requestOptions: options,
                    data: {
                      'id': 0,
                      'name': '',
                      'primaryAlbumTypes': <Map<String, dynamic>>[],
                    },
                    statusCode: 200,
                  ),
                );
              }
              if (options.path == '/api/v1/rootfolder') {
                return handler.resolve(
                  Response<dynamic>(
                    requestOptions: options,
                    data: <Map<String, dynamic>>[],
                    statusCode: 200,
                  ),
                );
              }
              if (options.path == '/api/v1/tag') {
                return handler.resolve(
                  Response<dynamic>(
                    requestOptions: options,
                    data: <Map<String, dynamic>>[],
                    statusCode: 200,
                  ),
                );
              }
              if (options.path == '/api/v1/indexer') {
                return handler.resolve(
                  Response<dynamic>(
                    requestOptions: options,
                    data: <Map<String, dynamic>>[],
                    statusCode: 200,
                  ),
                );
              }
              if (options.path == '/api/v1/downloadclient') {
                return handler.resolve(
                  Response<dynamic>(
                    requestOptions: options,
                    data: <Map<String, dynamic>>[],
                    statusCode: 200,
                  ),
                );
              }
              if (options.path == '/api/v1/notification') {
                return handler.resolve(
                  Response<dynamic>(
                    requestOptions: options,
                    data: <Map<String, dynamic>>[],
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
                body: SettingsTab(instance: testInstance),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Navigate to Import Lists sub-page
        await tester.tap(find.text('Import Lists'));
        await tester.pumpAndSettle();

        expect(find.text('My Spotify Top'), findsOneWidget);
        expect(find.text('Spotify • Auto-Add Enabled'), findsOneWidget);

        // 1. Add from preset flow
        await tester.tap(find.byTooltip('Add Import List'));
        await tester.pumpAndSettle();

        expect(find.text('Add Import List'), findsOneWidget);
        expect(find.text('Last.fm User Library'), findsOneWidget);

        await tester.tap(find.text('Last.fm User Library'));
        await tester.pumpAndSettle();

        expect(find.text('Add Last.fm User Library'), findsOneWidget);

        await tester.tap(find.text('Save'));
        await tester.pumpAndSettle();

        expect(postListCalled, isTrue);

        tester
            .state<ScaffoldMessengerState>(find.byType(ScaffoldMessenger))
            .clearSnackBars();
        await tester.pumpAndSettle();

        // 2. Edit existing list flow
        await tester.tap(find.text('My Spotify Top'));
        await tester.pumpAndSettle();

        expect(find.text('Edit My Spotify Top'), findsOneWidget);
        expect(find.text('Provider Settings'), findsOneWidget);

        await tester.tap(find.text('Test'));
        await tester.pumpAndSettle();

        expect(testListCalled, isTrue);

        await tester.tap(find.text('Save'));
        await tester.pumpAndSettle();

        expect(putListCalled, isTrue);

        tester
            .state<ScaffoldMessengerState>(find.byType(ScaffoldMessenger))
            .clearSnackBars();
        await tester.pumpAndSettle();

        // 3. Delete import list flow
        await tester.tap(find.byTooltip('Delete Import List'));
        await tester.pumpAndSettle();

        expect(find.text('Delete My Spotify Top?'), findsOneWidget);
        await tester.tap(find.text('Delete'));
        await tester.pumpAndSettle();

        expect(deleteListCalled, isTrue);
      },
    );

    testWidgets(
      'SettingsTab Custom Formats section supports adding, editing conditions, and deleting',
      (tester) async {
        bool postFormatCalled = false;
        bool putFormatCalled = false;
        bool deleteFormatCalled = false;

        final Dio dio = Dio(BaseOptions(baseUrl: 'http://localhost:8686'));
        dio.interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) {
              if (options.path == '/api/v1/qualityprofile') {
                return handler.resolve(
                  Response<dynamic>(
                    requestOptions: options,
                    data: <Map<String, dynamic>>[],
                    statusCode: 200,
                  ),
                );
              }
              if (options.path == '/api/v1/metadataprofile') {
                return handler.resolve(
                  Response<dynamic>(
                    requestOptions: options,
                    data: <Map<String, dynamic>>[],
                    statusCode: 200,
                  ),
                );
              }
              if (options.path == '/api/v1/rootfolder') {
                return handler.resolve(
                  Response<dynamic>(
                    requestOptions: options,
                    data: <Map<String, dynamic>>[],
                    statusCode: 200,
                  ),
                );
              }
              if (options.path == '/api/v1/tag') {
                return handler.resolve(
                  Response<dynamic>(
                    requestOptions: options,
                    data: <Map<String, dynamic>>[],
                    statusCode: 200,
                  ),
                );
              }
              if (options.path == '/api/v1/indexer') {
                return handler.resolve(
                  Response<dynamic>(
                    requestOptions: options,
                    data: <Map<String, dynamic>>[],
                    statusCode: 200,
                  ),
                );
              }
              if (options.path == '/api/v1/downloadclient') {
                return handler.resolve(
                  Response<dynamic>(
                    requestOptions: options,
                    data: <Map<String, dynamic>>[],
                    statusCode: 200,
                  ),
                );
              }
              if (options.path == '/api/v1/importlist') {
                return handler.resolve(
                  Response<dynamic>(
                    requestOptions: options,
                    data: <Map<String, dynamic>>[],
                    statusCode: 200,
                  ),
                );
              }
              if (options.path == '/api/v1/notification') {
                return handler.resolve(
                  Response<dynamic>(
                    requestOptions: options,
                    data: <Map<String, dynamic>>[],
                    statusCode: 200,
                  ),
                );
              }
              if (options.path == '/api/v1/customformat' &&
                  options.method == 'GET') {
                return handler.resolve(
                  Response<dynamic>(
                    requestOptions: options,
                    data: <Map<String, dynamic>>[
                      {
                        'id': 1,
                        'name': 'Lossless 24-bit',
                        'includeCustomFormatWhenRenaming': true,
                        'specifications': [
                          {
                            'id': 1,
                            'name': 'Release Title Specification',
                            'implementation': 'ReleaseTitleSpecification',
                            'implementationName': 'Release Title',
                            'negate': false,
                            'required': true,
                            'fields': [
                              {
                                'name': 'value',
                                'label': 'Regular Expression',
                                'value': '24-bit',
                              },
                            ],
                          },
                        ],
                      },
                    ],
                    statusCode: 200,
                  ),
                );
              }
              if (options.path == '/api/v1/customformat/schema' &&
                  options.method == 'GET') {
                return handler.resolve(
                  Response<dynamic>(
                    requestOptions: options,
                    data: <Map<String, dynamic>>[
                      {
                        'id': 1,
                        'name': 'Size Specification',
                        'implementation': 'SizeSpecification',
                        'implementationName': 'Size',
                        'negate': false,
                        'required': false,
                        'fields': [
                          {
                            'name': 'min',
                            'label': 'Minimum Size',
                            'value': 100,
                          },
                        ],
                      },
                    ],
                    statusCode: 200,
                  ),
                );
              }
              if (options.path == '/api/v1/customformat' &&
                  options.method == 'POST') {
                postFormatCalled = true;
                return handler.resolve(
                  Response<dynamic>(
                    requestOptions: options,
                    data: <String, dynamic>{
                      'id': 2,
                      'name': 'Vinyl Rip',
                      'includeCustomFormatWhenRenaming': false,
                      'specifications': <Map<String, dynamic>>[],
                    },
                    statusCode: 201,
                  ),
                );
              }
              if (options.path == '/api/v1/customformat/1' &&
                  options.method == 'PUT') {
                putFormatCalled = true;
                return handler.resolve(
                  Response<dynamic>(
                    requestOptions: options,
                    data: <String, dynamic>{
                      'id': 1,
                      'name': 'Lossless 24-bit',
                      'includeCustomFormatWhenRenaming': true,
                    },
                    statusCode: 200,
                  ),
                );
              }
              if (options.path == '/api/v1/customformat/1' &&
                  options.method == 'DELETE') {
                deleteFormatCalled = true;
                return handler.resolve(
                  Response<dynamic>(
                    requestOptions: options,
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
                body: SettingsTab(instance: testInstance),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Navigate to Custom Formats sub-page
        await tester.tap(find.text('Custom Formats'));
        await tester.pumpAndSettle();

        expect(find.text('Lossless 24-bit'), findsOneWidget);
        expect(find.text('Rename Tag'), findsOneWidget);
        expect(find.text('1 Conditions'), findsOneWidget);

        // 1. Add custom format flow
        await tester.tap(find.byTooltip('Add Custom Format'));
        await tester.pumpAndSettle();

        expect(find.text('Add Custom Format'), findsOneWidget);
        await tester.enterText(
          find.widgetWithText(TextField, 'Custom Format Name'),
          'Vinyl Rip',
        );
        await tester.pumpAndSettle();

        // Add a condition from schema bottom sheet
        await tester.tap(find.text('Add Condition'));
        await tester.pumpAndSettle();

        expect(find.text('Select Specification Type'), findsOneWidget);
        expect(find.text('Size Specification'), findsOneWidget);

        await tester.tap(find.text('Size Specification'));
        await tester.pumpAndSettle();

        expect(find.text('Specifications (1)'), findsOneWidget);

        await tester.tap(find.text('Save'));
        await tester.pumpAndSettle();

        expect(postFormatCalled, isTrue);

        tester
            .state<ScaffoldMessengerState>(find.byType(ScaffoldMessenger))
            .clearSnackBars();
        await tester.pumpAndSettle();

        // 2. Edit existing custom format flow
        await tester.tap(find.text('Lossless 24-bit'));
        await tester.pumpAndSettle();

        expect(find.text('Edit Custom Format'), findsOneWidget);
        await tester.tap(find.text('Negate'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Save'));
        await tester.pumpAndSettle();

        expect(putFormatCalled, isTrue);

        tester
            .state<ScaffoldMessengerState>(find.byType(ScaffoldMessenger))
            .clearSnackBars();
        await tester.pumpAndSettle();

        // 3. Delete custom format flow
        await tester.tap(find.byTooltip('Delete Custom Format'));
        await tester.pumpAndSettle();

        expect(find.text('Delete Lossless 24-bit?'), findsOneWidget);
        await tester.tap(find.text('Delete'));
        await tester.pumpAndSettle();

        expect(deleteFormatCalled, isTrue);
      },
    );

    testWidgets(
      'SettingsTab Quality, Media Management, Metadata Consumers, and General sections support full configuration and updates',
      (tester) async {
        tester.view.physicalSize = const Size(1200, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        bool qualityPutCalled = false;
        bool namingPutCalled = false;
        bool mmPutCalled = false;
        bool hostPutCalled = false;

        final Dio dio = Dio(
          BaseOptions(
            baseUrl: 'http://127.0.0.1:8686',
            headers: {'X-Api-Key': 'mock-key'},
          ),
        );

        dio.interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) {
              if (options.path.startsWith('/api/v1/qualitydefinition')) {
                if (options.method == 'PUT') {
                  qualityPutCalled = true;
                  return handler.resolve(
                    Response<dynamic>(
                      requestOptions: options,
                      statusCode: 200,
                      data: options.data,
                    ),
                  );
                }
                return handler.resolve(
                  Response<dynamic>(
                    requestOptions: options,
                    statusCode: 200,
                    data: [
                      {
                        'id': 1,
                        'title': 'FLAC',
                        'minSize': 10.0,
                        'maxSize': 100.0,
                        'preferredSize': 50.0,
                      },
                    ],
                  ),
                );
              }
              if (options.path.startsWith('/api/v1/config/naming')) {
                if (options.method == 'PUT') {
                  namingPutCalled = true;
                  return handler.resolve(
                    Response<dynamic>(
                      requestOptions: options,
                      statusCode: 200,
                      data: options.data,
                    ),
                  );
                }
                return handler.resolve(
                  Response<dynamic>(
                    requestOptions: options,
                    statusCode: 200,
                    data: {
                      'id': 1,
                      'renameTracks': true,
                      'standardTrackFormat': '{Track Title}',
                    },
                  ),
                );
              }
              if (options.path.startsWith('/api/v1/config/mediamanagement')) {
                if (options.method == 'PUT') {
                  mmPutCalled = true;
                  return handler.resolve(
                    Response<dynamic>(
                      requestOptions: options,
                      statusCode: 200,
                      data: options.data,
                    ),
                  );
                }
                return handler.resolve(
                  Response<dynamic>(
                    requestOptions: options,
                    statusCode: 200,
                    data: {
                      'id': 1,
                      'autoUnmonitorPreviouslyDownloadedTracks': false,
                      'createEmptyArtistFolders': true,
                    },
                  ),
                );
              }
              if (options.path.startsWith('/api/v1/metadata/schema')) {
                return handler.resolve(
                  Response<dynamic>(
                    requestOptions: options,
                    statusCode: 200,
                    data: [
                      {
                        'id': 100,
                        'name': 'Kodi (XBMC) / Emby',
                        'implementation': 'Kodi',
                        'fields': <Map<String, dynamic>>[],
                      },
                    ],
                  ),
                );
              }
              if (options.path.startsWith('/api/v1/metadata')) {
                return handler.resolve(
                  Response<dynamic>(
                    requestOptions: options,
                    statusCode: 200,
                    data: [
                      {
                        'id': 1,
                        'name': 'Kodi Metadata',
                        'enable': true,
                        'implementationName': 'Kodi',
                        'fields': <Map<String, dynamic>>[],
                      },
                    ],
                  ),
                );
              }
              if (options.path.startsWith('/api/v1/config/host')) {
                if (options.method == 'PUT') {
                  hostPutCalled = true;
                  return handler.resolve(
                    Response<dynamic>(
                      requestOptions: options,
                      statusCode: 200,
                      data: options.data,
                    ),
                  );
                }
                return handler.resolve(
                  Response<dynamic>(
                    requestOptions: options,
                    statusCode: 200,
                    data: {
                      'id': 1,
                      'port': 8686,
                      'sslPort': 6969,
                      'instanceName': 'Test Lidarr',
                      'apiKey': 'mock-api-key-12345',
                    },
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
                body: SettingsTab(instance: testInstance),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // 1. Quality Definitions Card
        await tester.tap(find.text('Quality Definitions'));
        await tester.pumpAndSettle();

        expect(find.text('FLAC'), findsOneWidget);
        await tester.tap(find.text('FLAC'));
        await tester.pumpAndSettle();

        expect(find.text('Edit FLAC'), findsOneWidget);
        await tester.tap(find.text('Save'));
        await tester.pumpAndSettle();

        expect(qualityPutCalled, isTrue);

        tester
            .state<ScaffoldMessengerState>(find.byType(ScaffoldMessenger))
            .clearSnackBars();
        await tester.pumpAndSettle();

        await tester.tap(find.byType(BackButton));
        await tester.pumpAndSettle();

        // 2. Media Management Card
        await tester.tap(find.text('Media Management'));
        await tester.pumpAndSettle();

        expect(find.text('Track Naming Formats'), findsOneWidget);
        expect(find.text('Media Management Options'), findsOneWidget);

        await tester.ensureVisible(find.text('Save Naming Formats'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Save Naming Formats'));
        await tester.pumpAndSettle();
        expect(namingPutCalled, isTrue);

        tester
            .state<ScaffoldMessengerState>(find.byType(ScaffoldMessenger))
            .clearSnackBars();
        await tester.pumpAndSettle();

        await tester.ensureVisible(find.text('Save Media Management'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Save Media Management'));
        await tester.pumpAndSettle();
        expect(mmPutCalled, isTrue);

        tester
            .state<ScaffoldMessengerState>(find.byType(ScaffoldMessenger))
            .clearSnackBars();
        await tester.pumpAndSettle();

        await tester.tap(find.byType(BackButton));
        await tester.pumpAndSettle();

        // 3. Metadata Consumers Card
        await tester.tap(find.text('Metadata Consumers'));
        await tester.pumpAndSettle();

        expect(find.text('Kodi Metadata'), findsOneWidget);

        await tester.tap(find.byType(BackButton));
        await tester.pumpAndSettle();

        // 4. General Card
        await tester.tap(find.text('General'));
        await tester.pumpAndSettle();

        expect(find.text('Host & Network Settings'), findsOneWidget);
        expect(find.text('API Key: mock-api-key-12345'), findsOneWidget);

        await tester.ensureVisible(find.text('Save Host Settings'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Save Host Settings'));
        await tester.pumpAndSettle();
        expect(hostPutCalled, isTrue);
      },
    );
  });
}
