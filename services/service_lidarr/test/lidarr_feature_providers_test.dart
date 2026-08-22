import 'package:core_models/core_models.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:service_lidarr/service_lidarr.dart';

void main() {
  group('Lidarr Feature Providers Tests', () {
    const testInstance = Instance(
      id: 'test-lidarr-instance',
      name: 'Test Lidarr',
      kind: ServiceKind.lidarr,
      localUrl: 'http://localhost:8686',
      externalUrl: '',
      urlMode: UrlMode.auto,
      auth: InstanceAuthApiKey(apiKey: 'test-api-key'),
    );

    test('lidarrArtistsProvider sorts artists alphabetically', () async {
      final dio = Dio(BaseOptions(baseUrl: 'http://localhost:8686/'));
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            if (options.path == '/api/v1/artist') {
              return handler.resolve(
                Response<dynamic>(
                  requestOptions: options,
                  statusCode: 200,
                  data: [
                    {'id': 1, 'artistName': 'Radiohead'},
                    {'id': 2, 'artistName': 'Arcade Fire'},
                    {'id': 3, 'artistName': 'Bjork'},
                  ],
                ),
              );
            }
            return handler.next(options);
          },
        ),
      );

      final container = ProviderContainer(
        overrides: [
          lidarrApiProvider(testInstance).overrideWith((ref) => LidarrApi(dio)),
        ],
      );
      addTearDown(container.dispose);

      final artists =
          await container.read(lidarrArtistsProvider(testInstance).future);

      expect(artists.length, equals(3));
      expect(artists[0].artistName, equals('Arcade Fire'));
      expect(artists[1].artistName, equals('Bjork'));
      expect(artists[2].artistName, equals('Radiohead'));
    });

    test(
        'lidarrAlbumsForArtistProvider fetches albums and sorts by releaseDate descending',
        () async {
      final dio = Dio(BaseOptions(baseUrl: 'http://localhost:8686/'));
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            if (options.path == '/api/v1/album' &&
                options.queryParameters['artistId'] == 1) {
              return handler.resolve(
                Response<dynamic>(
                  requestOptions: options,
                  statusCode: 200,
                  data: [
                    {
                      'id': 10,
                      'title': 'OK Computer',
                      'releaseDate': '1997-05-21T00:00:00Z',
                      'albumType': 'Studio',
                    },
                    {
                      'id': 11,
                      'title': 'In Rainbows',
                      'releaseDate': '2007-10-10T00:00:00Z',
                      'albumType': 'Studio',
                    },
                    {
                      'id': 12,
                      'title': 'Kid A',
                      'releaseDate': '2000-10-02T00:00:00Z',
                      'albumType': 'Studio',
                    },
                  ],
                ),
              );
            }
            return handler.next(options);
          },
        ),
      );

      final container = ProviderContainer(
        overrides: [
          lidarrApiProvider(testInstance).overrideWith((ref) => LidarrApi(dio)),
        ],
      );
      addTearDown(container.dispose);

      final albums = await container
          .read(lidarrAlbumsForArtistProvider((testInstance, 1)).future);

      expect(albums.length, equals(3));
      expect(albums[0].title, equals('In Rainbows'));
      expect(albums[1].title, equals('Kid A'));
      expect(albums[2].title, equals('OK Computer'));
    });

    test('lidarrTracksForAlbumProvider fetches tracks and sorts by trackNumber',
        () async {
      final dio = Dio(BaseOptions(baseUrl: 'http://localhost:8686/'));
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            if (options.path == '/api/v1/track' &&
                options.queryParameters['artistId'] == 1 &&
                options.queryParameters['albumId'] == 10) {
              return handler.resolve(
                Response<dynamic>(
                  requestOptions: options,
                  statusCode: 200,
                  data: [
                    {
                      'id': 102,
                      'title': 'Paranoid Android',
                      'trackNumber': '2',
                      'duration': 383000,
                    },
                    {
                      'id': 101,
                      'title': 'Airbag',
                      'trackNumber': '1',
                      'duration': 284000,
                    },
                    {
                      'id': 103,
                      'title': 'Subterranean Homesick Alien',
                      'trackNumber': '3',
                      'duration': 267000,
                    },
                  ],
                ),
              );
            }
            return handler.next(options);
          },
        ),
      );

      final container = ProviderContainer(
        overrides: [
          lidarrApiProvider(testInstance).overrideWith((ref) => LidarrApi(dio)),
        ],
      );
      addTearDown(container.dispose);

      final tracks = await container
          .read(lidarrTracksForAlbumProvider((testInstance, 1, 10)).future);

      expect(tracks.length, equals(3));
      expect(tracks[0].title, equals('Airbag'));
      expect(tracks[1].title, equals('Paranoid Android'));
      expect(tracks[2].title, equals('Subterranean Homesick Alien'));
    });

    test('lidarrQueueProvider extracts records from paging response', () async {
      final dio = Dio(BaseOptions(baseUrl: 'http://localhost:8686/'));
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            if (options.path == '/api/v1/queue') {
              return handler.resolve(
                Response<dynamic>(
                  requestOptions: options,
                  statusCode: 200,
                  data: {
                    'page': 1,
                    'pageSize': 10,
                    'totalRecords': 1,
                    'records': [
                      {
                        'id': 501,
                        'title': 'Radiohead - OK Computer (1997) FLAC',
                        'size': 350000000.0,
                        'sizeleft': 100000000.0,
                        'status': 'downloading',
                      },
                    ],
                  },
                ),
              );
            }
            return handler.next(options);
          },
        ),
      );

      final container = ProviderContainer(
        overrides: [
          lidarrApiProvider(testInstance).overrideWith((ref) => LidarrApi(dio)),
        ],
      );
      addTearDown(container.dispose);

      final queue =
          await container.read(lidarrQueueProvider(testInstance).future);

      expect(queue.length, equals(1));
      expect(queue[0].title, equals('Radiohead - OK Computer (1997) FLAC'));
    });

    test('Provider throws LidarrException on error response', () async {
      final dio = Dio(BaseOptions(baseUrl: 'http://localhost:8686/'));
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            if (options.path == '/api/v1/artist') {
              return handler.reject(
                DioException(
                  requestOptions: options,
                  response: Response<dynamic>(
                    requestOptions: options,
                    statusCode: 401,
                    data: {'message': 'Unauthorized - Invalid API Key'},
                  ),
                  type: DioExceptionType.badResponse,
                ),
              );
            }
            return handler.next(options);
          },
        ),
      );

      final container = ProviderContainer(
        overrides: [
          lidarrApiProvider(testInstance).overrideWith((ref) => LidarrApi(dio)),
        ],
      );
      addTearDown(container.dispose);

      expect(
        () => container.read(lidarrArtistsProvider(testInstance).future),
        throwsA(isA<LidarrException>()),
      );
    });

    test(
        'lidarrArtistLookupProvider fetches search results and handles empty query',
        () async {
      final dio = Dio(BaseOptions(baseUrl: 'http://localhost:8686/'));
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            if (options.path == '/api/v1/artist/lookup' &&
                options.queryParameters['term'] == 'Radiohead') {
              return handler.resolve(
                Response<dynamic>(
                  requestOptions: options,
                  statusCode: 200,
                  data: [
                    {
                      'artistName': 'Radiohead',
                      'foreignArtistId': 'a74b1b7f-71a5-4011-9441-d0b5e4122711',
                      'overview': 'English rock band.',
                      'status': 'continuing',
                    },
                  ],
                ),
              );
            }
            return handler.next(options);
          },
        ),
      );

      final container = ProviderContainer(
        overrides: [
          lidarrApiProvider(testInstance).overrideWith((ref) => LidarrApi(dio)),
        ],
      );
      addTearDown(container.dispose);

      // Empty query returns empty list without error
      final emptyResults = await container
          .read(lidarrArtistLookupProvider((testInstance, '   ')).future);
      expect(emptyResults, isEmpty);

      // Term lookup returns parsed results
      final results = await container
          .read(lidarrArtistLookupProvider((testInstance, 'Radiohead')).future);
      expect(results.length, equals(1));
      expect(results[0].artistName, equals('Radiohead'));
      expect(
        results[0].foreignArtistId,
        equals('a74b1b7f-71a5-4011-9441-d0b5e4122711'),
      );
      expect(results[0].status, equals(ArtistStatusType.continuing));
    });

    test('lidarrRootFoldersProvider fetches root folders', () async {
      final dio = Dio(BaseOptions(baseUrl: 'http://localhost:8686/'));
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            if (options.path == '/api/v1/rootfolder') {
              return handler.resolve(
                Response<dynamic>(
                  requestOptions: options,
                  statusCode: 200,
                  data: [
                    {
                      'id': 1,
                      'name': 'Music Root',
                      'path': '/data/media/music',
                      'freeSpace': 536870912000,
                      'defaultQualityProfileId': 1,
                      'defaultMetadataProfileId': 1,
                    },
                  ],
                ),
              );
            }
            return handler.next(options);
          },
        ),
      );

      final container = ProviderContainer(
        overrides: [
          lidarrApiProvider(testInstance).overrideWith((ref) => LidarrApi(dio)),
        ],
      );
      addTearDown(container.dispose);

      final folders =
          await container.read(lidarrRootFoldersProvider(testInstance).future);
      expect(folders.length, equals(1));
      expect(folders[0].path, equals('/data/media/music'));
      expect(folders[0].freeSpace, equals(536870912000));
    });

    test('lidarrQualityProfilesProvider fetches quality profiles', () async {
      final dio = Dio(BaseOptions(baseUrl: 'http://localhost:8686/'));
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            if (options.path == '/api/v1/qualityprofile') {
              return handler.resolve(
                Response<dynamic>(
                  requestOptions: options,
                  statusCode: 200,
                  data: [
                    {
                      'id': 1,
                      'name': 'Lossless (FLAC)',
                      'upgradeAllowed': true,
                    },
                    {
                      'id': 2,
                      'name': 'High Quality (MP3-320)',
                      'upgradeAllowed': false,
                    },
                  ],
                ),
              );
            }
            return handler.next(options);
          },
        ),
      );

      final container = ProviderContainer(
        overrides: [
          lidarrApiProvider(testInstance).overrideWith((ref) => LidarrApi(dio)),
        ],
      );
      addTearDown(container.dispose);

      final profiles = await container
          .read(lidarrQualityProfilesProvider(testInstance).future);
      expect(profiles.length, equals(2));
      expect(profiles[0].name, equals('Lossless (FLAC)'));
      expect(profiles[1].name, equals('High Quality (MP3-320)'));
    });

    test('lidarrMetadataProfilesProvider fetches metadata profiles', () async {
      final dio = Dio(BaseOptions(baseUrl: 'http://localhost:8686/'));
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            if (options.path == '/api/v1/metadataprofile') {
              return handler.resolve(
                Response<dynamic>(
                  requestOptions: options,
                  statusCode: 200,
                  data: [
                    {'id': 1, 'name': 'Standard'},
                    {'id': 2, 'name': 'Singles & EPs'},
                  ],
                ),
              );
            }
            return handler.next(options);
          },
        ),
      );

      final container = ProviderContainer(
        overrides: [
          lidarrApiProvider(testInstance).overrideWith((ref) => LidarrApi(dio)),
        ],
      );
      addTearDown(container.dispose);

      final metadataProfiles = await container
          .read(lidarrMetadataProfilesProvider(testInstance).future);
      expect(metadataProfiles.length, equals(2));
      expect(metadataProfiles[0].name, equals('Standard'));
      expect(metadataProfiles[1].name, equals('Singles & EPs'));
    });

    test('lidarrTagsProvider fetches tags', () async {
      final dio = Dio(BaseOptions(baseUrl: 'http://localhost:8686/'));
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            if (options.path == '/api/v1/tag') {
              return handler.resolve(
                Response<dynamic>(
                  requestOptions: options,
                  statusCode: 200,
                  data: [
                    {'id': 10, 'label': 'electronic'},
                    {'id': 20, 'label': 'favorite'},
                  ],
                ),
              );
            }
            return handler.next(options);
          },
        ),
      );

      final container = ProviderContainer(
        overrides: [
          lidarrApiProvider(testInstance).overrideWith((ref) => LidarrApi(dio)),
        ],
      );
      addTearDown(container.dispose);

      final tags =
          await container.read(lidarrTagsProvider(testInstance).future);
      expect(tags.length, equals(2));
      expect(tags[0].label, equals('electronic'));
      expect(tags[1].label, equals('favorite'));
    });

    test('lidarrCalendarProvider fetches and parses calendar albums', () async {
      final dio = Dio(BaseOptions(baseUrl: 'http://localhost:8686/'));
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            if (options.path == '/api/v1/calendar') {
              expect(options.queryParameters['includeArtist'], isTrue);
              expect(options.queryParameters['unmonitored'], isTrue);
              expect(options.queryParameters['start'], isNotNull);
              expect(options.queryParameters['end'], isNotNull);
              return handler.resolve(
                Response<dynamic>(
                  requestOptions: options,
                  statusCode: 200,
                  data: [
                    {
                      'id': 101,
                      'title': 'A Moon Shaped Pool',
                      'releaseDate': '2016-05-08T00:00:00Z',
                      'albumType': 'Studio',
                      'monitored': true,
                      'artistId': 1,
                      'artist': {
                        'id': 1,
                        'artistName': 'Radiohead',
                      },
                      'statistics': {
                        'trackFileCount': 11,
                        'percentOfTracks': 100.0,
                      },
                    },
                  ],
                ),
              );
            }
            return handler.next(options);
          },
        ),
      );

      final container = ProviderContainer(
        overrides: [
          lidarrApiProvider(testInstance).overrideWith((ref) => LidarrApi(dio)),
        ],
      );
      addTearDown(container.dispose);

      final month = DateTime(2016, 5);
      final albums = await container
          .read(lidarrCalendarProvider((testInstance, month)).future);

      expect(albums.length, equals(1));
      expect(albums[0].title, equals('A Moon Shaped Pool'));
      expect(albums[0].artist?.artistName, equals('Radiohead'));
      expect(albums[0].statistics?.percentOfTracks, equals(100.0));
    });

    test('lidarrTracksForAlbumProvider fetches and parses tracks for album',
        () async {
      final dio = Dio();
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            if (options.path == '/api/v1/track') {
              expect(options.queryParameters['artistId'], equals(1));
              expect(options.queryParameters['albumId'], equals(101));
              return handler.resolve(
                Response<dynamic>(
                  requestOptions: options,
                  statusCode: 200,
                  data: [
                    {
                      'id': 501,
                      'title': 'Burn the Witch',
                      'trackNumber': '1',
                      'duration': 220000,
                      'hasFile': true,
                    },
                    {
                      'id': 502,
                      'title': 'Daydreaming',
                      'trackNumber': '2',
                      'duration': 384000,
                      'hasFile': true,
                    },
                  ],
                ),
              );
            }
            return handler.next(options);
          },
        ),
      );

      final container = ProviderContainer(
        overrides: [
          lidarrApiProvider(testInstance).overrideWith((ref) => LidarrApi(dio)),
        ],
      );
      addTearDown(container.dispose);

      final tracks = await container
          .read(lidarrTracksForAlbumProvider((testInstance, 1, 101)).future);

      expect(tracks.length, equals(2));
      expect(tracks[0].title, equals('Burn the Witch'));
      expect(tracks[0].trackNumber, equals('1'));
      expect(tracks[1].title, equals('Daydreaming'));
    });

    test('lidarrRenamePreviewProvider fetches and parses rename preview list',
        () async {
      final dio = Dio();
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            if (options.path == '/api/v1/rename') {
              expect(options.queryParameters['artistId'], equals(1));
              expect(options.queryParameters['albumId'], equals(101));
              return handler.resolve(
                Response<dynamic>(
                  requestOptions: options,
                  statusCode: 200,
                  data: [
                    {
                      'id': 1,
                      'artistId': 1,
                      'albumId': 101,
                      'trackNumbers': [1],
                      'trackFileId': 901,
                      'existingPath':
                          '/music/Radiohead/A Moon Shaped Pool/01.flac',
                      'newPath':
                          '/music/Radiohead/A Moon Shaped Pool/01 - Burn the Witch.flac',
                    },
                  ],
                ),
              );
            }
            return handler.next(options);
          },
        ),
      );

      final container = ProviderContainer(
        overrides: [
          lidarrApiProvider(testInstance).overrideWith((ref) => LidarrApi(dio)),
        ],
      );
      addTearDown(container.dispose);

      final files = await container
          .read(lidarrRenamePreviewProvider((testInstance, 1, 101)).future);

      expect(files.length, equals(1));
      expect(files[0].trackFileId, equals(901));
      expect(files[0].existingPath, contains('01.flac'));
      expect(files[0].newPath, contains('01 - Burn the Witch.flac'));
    });

    test('lidarrRetagPreviewProvider fetches and parses retag preview list',
        () async {
      final dio = Dio();
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            if (options.path == '/api/v1/retag') {
              expect(options.queryParameters['artistId'], equals(1));
              expect(options.queryParameters['albumId'], equals(101));
              return handler.resolve(
                Response<dynamic>(
                  requestOptions: options,
                  statusCode: 200,
                  data: [
                    {
                      'id': 1,
                      'artistId': 1,
                      'albumId': 101,
                      'trackNumbers': [1],
                      'trackFileId': 901,
                      'path':
                          '/music/Radiohead/A Moon Shaped Pool/01 - Burn the Witch.flac',
                      'changes': [
                        {
                          'field': 'Title',
                          'oldValue': 'Burn the Witch (Live)',
                          'newValue': 'Burn the Witch',
                        },
                        {
                          'field': 'Artist',
                          'oldValue': 'Radiohead feat. London Orchestra',
                          'newValue': 'Radiohead',
                        },
                      ],
                    },
                  ],
                ),
              );
            }
            return handler.next(options);
          },
        ),
      );

      final container = ProviderContainer(
        overrides: [
          lidarrApiProvider(testInstance).overrideWith((ref) => LidarrApi(dio)),
        ],
      );
      addTearDown(container.dispose);

      final files = await container
          .read(lidarrRetagPreviewProvider((testInstance, 1, 101)).future);

      expect(files.length, equals(1));
      expect(files[0].trackFileId, equals(901));
      expect(files[0].path, contains('01 - Burn the Witch.flac'));
      expect(files[0].changes?.length, equals(2));
      expect(files[0].changes?[0].field, equals('Title'));
      expect(files[0].changes?[0].oldValue, equals('Burn the Witch (Live)'));
      expect(files[0].changes?[0].newValue, equals('Burn the Witch'));
    });
  });
}
