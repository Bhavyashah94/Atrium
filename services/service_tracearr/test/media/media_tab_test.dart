import 'package:core_models/core_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:service_tracearr/src/cache/tracearr_artwork_cache.dart';
import 'package:service_tracearr/src/generated/api/raw_public_a_p_i_v2_api.dart';
import 'package:service_tracearr/src/media/media_tab.dart';
import 'package:service_tracearr/src/media/screens/tracearr_media_detail_screen.dart';
import 'package:service_tracearr/src/media/screens/widgets/media_availability_card.dart';
import 'package:service_tracearr/src/media/screens/widgets/media_tv_hierarchy_view.dart';
import 'package:service_tracearr/src/media/screens/widgets/media_watchers_leaderboard.dart';
import 'package:service_tracearr/src/media/widgets/media_storage_summary_bar.dart';
import 'package:service_tracearr/src/media/widgets/recently_added_card.dart';
import 'package:service_tracearr/src/media/widgets/recently_added_grid.dart';
import 'package:service_tracearr/src/media/widgets/recently_added_poster_tile.dart';
import 'package:service_tracearr/src/models/tracearr_models.dart';
import 'package:service_tracearr/src/providers/tracearr_providers.dart';
import 'package:service_tracearr/src/repository/tracearr_repository.dart';

class FakeV2ApiForMedia implements RawPublicAPIV2Api {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeTracearrMediaRepository extends TracearrRepository {
  FakeTracearrMediaRepository({
    this.recentlyAdded = const [],
    this.libraries = const [],
  }) : super(
          apiV2: FakeV2ApiForMedia(),
          artworkCache: TracearrArtworkCache(),
          baseUrl: 'https://tr.example.com',
        );

  final List<TracearrRecentlyAddedItem> recentlyAdded;
  final List<TracearrLibrary> libraries;

  @override
  Future<TracearrRecentlyAddedPage> getRecentlyAddedPage({
    String? cursor,
    String? pageSize = '25',
    String? serverId,
    String? libraryId,
  }) async {
    return TracearrRecentlyAddedPage(items: recentlyAdded);
  }

  @override
  Future<List<TracearrLibrary>> getLibraries() async {
    return libraries;
  }
}

void main() {
  const testInstance = Instance(
    id: 'inst_tracearr_1',
    name: 'Main Tracearr',
    kind: ServiceKind.tracearr,
    localUrl: 'https://tr.example.com',
    externalUrl: '',
    urlMode: UrlMode.auto,
    auth: InstanceAuthApiKey(apiKey: 'dummy'),
  );

  final testLibraries = [
    const TracearrLibrary(
      serverId: 'srv_1',
      serverType: 'plex',
      libraryId: 'lib_movies',
      movieCount: 1200,
      itemCount: 1200,
      totalFileSize: 10995116277760, // ~10 TB
      resolutions: {'4K': 120, '1080p': 1080},
    ),
    const TracearrLibrary(
      serverId: 'srv_2',
      serverType: 'jellyfin',
      libraryId: 'lib_shows',
      showCount: 450,
      itemCount: 450,
      totalFileSize: 4398046511104, // ~4 TB
      resolutions: {'1080p': 350, '720p': 100},
    ),
  ];

  final testRecentlyAdded = [
    const TracearrRecentlyAddedItem(
      id: 'rec_1',
      serverId: 'srv_1',
      serverType: 'plex',
      libraryId: 'lib_movies',
      mediaType: 'movie',
      title: 'Interstellar',
      year: 2014,
      ratingKey: 'rk_101',
    ),
    const TracearrRecentlyAddedItem(
      id: 'rec_2',
      serverId: 'srv_1',
      serverType: 'plex',
      libraryId: 'lib_shows',
      mediaType: 'show',
      title: 'Succession',
      year: 2018,
      ratingKey: 'rk_102',
    ),
    TracearrRecentlyAddedItem(
      id: 'rec_3',
      serverId: 'srv_1',
      serverType: 'plex',
      libraryId: 'lib_shows',
      mediaType: 'episode',
      title: 'Celebration',
      seasonNumber: 1,
      episodeNumber: 1,
      addedAt: DateTime.now().subtract(const Duration(hours: 2)),
      ratingKey: 'rk_103',
    ),
  ];

  const testMediaDetail = TracearrMediaDetail(
    id: 'med_101',
    title: 'Interstellar',
    year: 2014,
    imdbId: 'tt0816692',
    genres: ['Sci-Fi', 'Adventure', 'Drama'],
    allTimePlays: 84,
    last30DaysPlays: 12,
    last7DaysPlays: 4,
    allTimeWatchTimeMs: 604800000, // 168h
    availability: [
      TracearrMediaAvailability(
        serverId: 'srv_1',
        serverType: 'plex',
        videoResolution: '4K UHD',
        fileSize: 45000000000,
        ratingKey: 'rk_101',
      ),
    ],
    watchers: [
      TracearrMediaWatcher(
        userId: 'usr_1',
        username: 'Bhavya',
        plays: 14,
        watchTimeMs: 100800000, // 28h
      ),
      TracearrMediaWatcher(
        userId: 'usr_2',
        username: 'Alex',
        plays: 9,
        watchTimeMs: 64800000, // 18h
      ),
    ],
  );

  const testShowDetail = TracearrMediaDetail(
    id: 'med_102',
    title: 'Succession',
    mediaType: 'show',
    year: 2018,
    genres: ['Drama'],
    children: [
      TracearrMediaChild(
        id: 'ep_1',
        mediaType: 'episode',
        title: 'Celebration',
        seasonNumber: 1,
        episodeNumber: 1,
      ),
      TracearrMediaChild(
        id: 'ep_2',
        mediaType: 'episode',
        title: 'Shit Show at the Hit Factory',
        seasonNumber: 1,
        episodeNumber: 2,
      ),
    ],
  );

  Widget createMediaTabWidget({
    List<TracearrLibrary>? libraries,
    List<TracearrRecentlyAddedItem>? recentlyAdded,
  }) {
    final fakeRepo = FakeTracearrMediaRepository(
      libraries: libraries ?? testLibraries,
      recentlyAdded: recentlyAdded ?? testRecentlyAdded,
    );

    return ProviderScope(
      overrides: [
        tracearrRepositoryProvider(testInstance)
            .overrideWith((ref) async => fakeRepo),
        tracearrLibrariesProvider(testInstance).overrideWith(
          (ref) async => libraries ?? testLibraries,
        ),
      ],
      child: const MaterialApp(
        home: MediaTab(
          instance: testInstance,
        ),
      ),
    );
  }

  group('MediaTab Destination', () {
    testWidgets('renders fleet storage summary bar and library filter chips',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createMediaTabWidget());
      await tester.pumpAndSettle();

      expect(find.byType(MediaStorageSummaryBar), findsOneWidget);
      expect(find.text('FLEET STORAGE'), findsOneWidget);
      expect(find.text('14.0 TB across 2 Libraries'), findsOneWidget);
      expect(find.text('1650 total catalog items in fleet'), findsOneWidget);
      expect(find.text('4K: 120'), findsOneWidget);
      expect(find.text('1080P: 1430'), findsOneWidget);
      expect(find.text('720P: 100'), findsOneWidget);
      expect(find.text('All Libraries'), findsOneWidget);
      expect(find.text('PLEX Movies (1200)'), findsOneWidget);
      expect(find.text('JELLYFIN TV Shows (450)'), findsOneWidget);
    });

    testWidgets('renders recently added section with grid/list view toggle',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createMediaTabWidget());
      await tester.pumpAndSettle();

      expect(find.byType(RecentlyAddedGrid), findsOneWidget);
      expect(find.text('RECENTLY ADDED'), findsOneWidget);
      expect(find.byType(RecentlyAddedPosterTile), findsNWidgets(3));
      expect(find.text('Interstellar'), findsOneWidget);
      expect(find.text('Succession'), findsOneWidget);
      expect(find.text('S1:E1 • Celebration'), findsOneWidget);
      expect(find.text('Added 2h ago'), findsOneWidget);

      // Toggle to List View
      await tester.tap(find.byIcon(Icons.view_list_outlined));
      await tester.pumpAndSettle();

      expect(find.byType(RecentlyAddedCard), findsNWidgets(3));
      expect(find.byType(RecentlyAddedPosterTile), findsNothing);
      expect(find.text('S1:E1 • Celebration'), findsOneWidget);

      // Toggle back to Grid View
      await tester.tap(find.byIcon(Icons.grid_view_outlined));
      await tester.pumpAndSettle();

      expect(find.byType(RecentlyAddedPosterTile), findsNWidgets(3));
    });
  });

  group('TracearrMediaDetailScreen', () {
    testWidgets(
        'renders full movie metadata, telemetry, availability, and watchers',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            tracearrMediaDetailProvider((testInstance, 'rk_101')).overrideWith(
              (ref) async => testMediaDetail,
            ),
            tracearrMediaHistoryProvider((testInstance, 'rk_101')).overrideWith(
              (ref) async => const TracearrHistoryPage(items: []),
            ),
          ],
          child: const MaterialApp(
            home: TracearrMediaDetailScreen(
              instance: testInstance,
              mediaRef: 'rk_101',
              initialTitle: 'Interstellar',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Interstellar'), findsWidgets);
      expect(find.text('2014'), findsOneWidget);
      expect(find.text('MOVIE'), findsOneWidget);
      expect(find.text('Sci-Fi'), findsOneWidget);
      expect(find.text('Adventure'), findsOneWidget);
      expect(find.text('IMDb'), findsOneWidget);

      // Lifetime stats
      expect(find.text('TOTAL PLAYS'), findsOneWidget);
      expect(find.text('84'), findsOneWidget);
      expect(find.text('WATCH TIME'), findsOneWidget);
      expect(find.text('168.0h'), findsOneWidget);

      // Multi-Server Availability
      expect(find.byType(MediaAvailabilityCard), findsOneWidget);
      expect(find.text('CROSS-SERVER AVAILABILITY (1)'), findsOneWidget);
      expect(find.text('4K UHD'), findsOneWidget);

      // Top Watchers Leaderboard
      expect(find.byType(MediaWatchersLeaderboard), findsOneWidget);
      expect(find.text('TOP WATCHERS (2)'), findsOneWidget);
      expect(find.text('@Bhavya'), findsOneWidget);
      expect(find.text('14 plays'), findsOneWidget);
      expect(find.text('@Alex'), findsOneWidget);
      expect(find.text('9 plays'), findsOneWidget);
    });

    testWidgets('renders TV show hierarchy with season DTOs correctly',
        (tester) async {
      const testShowWithSeasons = TracearrMediaDetail(
        id: 'med_102',
        title: 'Succession',
        mediaType: 'show',
        year: 2018,
        genres: ['Drama'],
        children: [
          TracearrMediaChild(
            id: 'season_1',
            mediaType: 'season',
            title: 'Season 1',
            seasonNumber: 1,
            episodeCount: 10,
          ),
          TracearrMediaChild(
            id: 'season_2',
            mediaType: 'season',
            title: 'Season 2',
            seasonNumber: 2,
            episodeCount: 10,
          ),
        ],
      );

      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            tracearrMediaDetailProvider((testInstance, 'rk_102')).overrideWith(
              (ref) async => testShowWithSeasons,
            ),
            tracearrMediaHistoryProvider((testInstance, 'rk_102')).overrideWith(
              (ref) async => const TracearrHistoryPage(items: []),
            ),
            tracearrMediaDetailProvider((testInstance, 'ep_1')).overrideWith(
              (ref) async => const TracearrMediaDetail(
                id: 'ep_1',
                title: 'Celebration',
                mediaType: 'episode',
                showMediaId: 'rk_102',
              ),
            ),
            tracearrMediaHistoryProvider((testInstance, 'ep_1')).overrideWith(
              (ref) async => const TracearrHistoryPage(items: []),
            ),
            tracearrMediaChildrenProvider((testInstance, 'season_1'))
                .overrideWith(
              (ref) async => const [
                TracearrMediaChild(
                  id: 'ep_1',
                  mediaType: 'episode',
                  title: 'Celebration',
                  seasonNumber: 1,
                  episodeNumber: 1,
                ),
                TracearrMediaChild(
                  id: 'ep_2',
                  mediaType: 'episode',
                  title: 'Shit Show at the Hit Factory',
                  seasonNumber: 1,
                  episodeNumber: 2,
                ),
              ],
            ),
          ],
          child: const MaterialApp(
            home: TracearrMediaDetailScreen(
              instance: testInstance,
              mediaRef: 'rk_102',
              initialTitle: 'Succession',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(MediaTvHierarchyView), findsOneWidget);
      expect(find.text('SEASONS (2) · 20 EPISODES'), findsOneWidget);
      expect(find.text('Season 1'), findsOneWidget);
      expect(find.text('10 Episodes'), findsNWidgets(2));
      expect(find.text('S1'), findsOneWidget);
      expect(find.text('S2'), findsOneWidget);

      // Tap Season 1 ExpansionTile to fetch and reveal episodes
      await tester.tap(find.text('Season 1'));
      await tester.pumpAndSettle();

      expect(find.text('Celebration'), findsOneWidget);
      expect(find.text('Shit Show at the Hit Factory'), findsOneWidget);

      // Tap Celebration episode to navigate to episode media detail
      await tester.tap(find.text('Celebration'));
      await tester.pumpAndSettle();

      final detailScreens = tester
          .widgetList<TracearrMediaDetailScreen>(
            find.byType(TracearrMediaDetailScreen),
          )
          .toList();
      expect(detailScreens.last.mediaRef, equals('ep_1'));
    });

    testWidgets(
        'renders Series ActionChip on episode detail and navigates to show',
        (tester) async {
      const testEpisodeDetail = TracearrMediaDetail(
        id: 'ep_101',
        title: 'Celebration',
        mediaType: 'episode',
        showMediaId: 'show_uuid_succession',
        year: 2018,
      );

      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            tracearrMediaDetailProvider((testInstance, 'ep_101')).overrideWith(
              (ref) async => testEpisodeDetail,
            ),
            tracearrMediaDetailProvider(
              (testInstance, 'show_uuid_succession'),
            ).overrideWith(
              (ref) async => const TracearrMediaDetail(
                id: 'show_uuid_succession',
                title: 'Succession',
                mediaType: 'show',
              ),
            ),
            tracearrMediaHistoryProvider((testInstance, 'ep_101')).overrideWith(
              (ref) async => const TracearrHistoryPage(items: []),
            ),
            tracearrMediaHistoryProvider(
              (testInstance, 'show_uuid_succession'),
            ).overrideWith(
              (ref) async => const TracearrHistoryPage(items: []),
            ),
          ],
          child: const MaterialApp(
            home: TracearrMediaDetailScreen(
              instance: testInstance,
              mediaRef: 'ep_101',
              initialTitle: 'Celebration',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.tv_outlined), findsOneWidget);

      await tester.tap(find.byIcon(Icons.tv_outlined));
      await tester.pumpAndSettle();

      final detailScreens = tester
          .widgetList<TracearrMediaDetailScreen>(
            find.byType(TracearrMediaDetailScreen),
          )
          .toList();
      expect(detailScreens.last.mediaRef, equals('show_uuid_succession'));
    });

    testWidgets('renders TV show hierarchy accordion with episode DTOs',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            tracearrMediaDetailProvider((testInstance, 'rk_102')).overrideWith(
              (ref) async => testShowDetail,
            ),
            tracearrMediaHistoryProvider((testInstance, 'rk_102')).overrideWith(
              (ref) async => const TracearrHistoryPage(items: []),
            ),
          ],
          child: const MaterialApp(
            home: TracearrMediaDetailScreen(
              instance: testInstance,
              mediaRef: 'rk_102',
              initialTitle: 'Succession',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(MediaTvHierarchyView), findsOneWidget);
      expect(find.text('SEASONS & EPISODES (2)'), findsOneWidget);
      expect(find.text('Season 1'), findsOneWidget);
      expect(find.text('2 Episodes'), findsOneWidget);
    });

    testWidgets(
        'RecentlyAddedPosterTile prioritizes mediaId over ratingKey and id',
        (tester) async {
      const itemWithMediaId = TracearrRecentlyAddedItem(
        id: 'rec_db_row_1',
        serverId: 'srv_1',
        libraryId: 'lib_1',
        mediaType: 'movie',
        title: 'Oppenheimer',
        mediaId: 'canonical_media_uuid_opp',
        ratingKey: 'plex_rating_key_45000',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            tracearrMediaDetailProvider(
              (testInstance, 'canonical_media_uuid_opp'),
            ).overrideWith(
              (ref) async => testMediaDetail,
            ),
            tracearrMediaHistoryProvider(
              (testInstance, 'canonical_media_uuid_opp'),
            ).overrideWith(
              (ref) async => const TracearrHistoryPage(items: []),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 150,
                height: 250,
                child: RecentlyAddedPosterTile(
                  item: itemWithMediaId,
                  instance: testInstance,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Oppenheimer'));
      await tester.pumpAndSettle();

      final detailScreen = tester.widget<TracearrMediaDetailScreen>(
          find.byType(TracearrMediaDetailScreen));
      expect(detailScreen.mediaRef, equals('canonical_media_uuid_opp'));
    });

    testWidgets(
        'RecentlyAddedPosterTile falls back to ratingKey when mediaId is null',
        (tester) async {
      const itemWithRatingKey = TracearrRecentlyAddedItem(
        id: 'rec_db_row_2',
        serverId: 'srv_1',
        libraryId: 'lib_1',
        mediaType: 'movie',
        title: 'Barbie',
        ratingKey: 'plex_rating_key_46000',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            tracearrMediaDetailProvider(
              (testInstance, 'plex_rating_key_46000'),
            ).overrideWith(
              (ref) async => testMediaDetail,
            ),
            tracearrMediaHistoryProvider(
              (testInstance, 'plex_rating_key_46000'),
            ).overrideWith(
              (ref) async => const TracearrHistoryPage(items: []),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 150,
                height: 250,
                child: RecentlyAddedPosterTile(
                  item: itemWithRatingKey,
                  instance: testInstance,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Barbie'));
      await tester.pumpAndSettle();

      final detailScreen = tester.widget<TracearrMediaDetailScreen>(
          find.byType(TracearrMediaDetailScreen));
      expect(detailScreen.mediaRef, equals('plex_rating_key_46000'));
    });

    testWidgets(
        'Episode -> Series contextual navigation auto-expands matching season and highlights current episode',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      const testEpisodeDetail = TracearrMediaDetail(
        id: 'ep_107',
        title: 'Celebration',
        mediaType: 'episode',
        showMediaId: 'show_succ_1',
      );

      const testParentShowDetail = TracearrMediaDetail(
        id: 'show_succ_1',
        title: 'Succession',
        mediaType: 'show',
        children: [
          TracearrMediaChild(
            id: 'season_1',
            mediaType: 'season',
            title: 'Season 1',
            seasonNumber: 1,
            episodeCount: 10,
          ),
          TracearrMediaChild(
            id: 'season_2',
            mediaType: 'season',
            title: 'Season 2',
            seasonNumber: 2,
            episodeCount: 10,
          ),
        ],
      );

      const season2Episodes = [
        TracearrMediaChild(
          id: 'ep_206',
          mediaType: 'episode',
          title: 'Argestes',
          seasonNumber: 2,
          episodeNumber: 6,
        ),
        TracearrMediaChild(
          id: 'ep_207',
          mediaType: 'episode',
          title: 'Return',
          seasonNumber: 2,
          episodeNumber: 7,
        ),
        TracearrMediaChild(
          id: 'ep_208',
          mediaType: 'episode',
          title: 'Dundee',
          seasonNumber: 2,
          episodeNumber: 8,
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            tracearrMediaDetailProvider((testInstance, 'ep_107')).overrideWith(
              (ref) async => testEpisodeDetail,
            ),
            tracearrMediaDetailProvider((testInstance, 'show_succ_1'))
                .overrideWith(
              (ref) async => testParentShowDetail,
            ),
            tracearrMediaChildrenProvider((testInstance, 'season_2'))
                .overrideWith(
              (ref) async => season2Episodes,
            ),
            tracearrMediaHistoryProvider((testInstance, 'ep_107')).overrideWith(
              (ref) async => const TracearrHistoryPage(items: []),
            ),
            tracearrMediaHistoryProvider((testInstance, 'show_succ_1'))
                .overrideWith(
              (ref) async => const TracearrHistoryPage(items: []),
            ),
          ],
          child: const MaterialApp(
            home: TracearrMediaDetailScreen(
              instance: testInstance,
              mediaRef: 'ep_107',
              initialTitle: 'Celebration',
              initialSeasonNumber: 2,
              initialEpisodeNumber: 7,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Series ActionChip
      expect(find.byIcon(Icons.tv_outlined), findsOneWidget);
      await tester.tap(find.byIcon(Icons.tv_outlined));
      await tester.pumpAndSettle();

      // Parent show is opened with Season 2 auto-expanded
      expect(find.text('Succession'), findsWidgets);
      expect(find.text('Return'), findsOneWidget);
      expect(find.text('Dundee'), findsOneWidget);
      expect(find.text('CURRENT'), findsOneWidget);
    });

    testWidgets('TV hierarchy is rendered above availability on show detail',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      const testShowDetail = TracearrMediaDetail(
        id: 'show_1',
        title: 'Severance',
        mediaType: 'show',
        availability: [
          TracearrMediaAvailability(
            serverId: 'srv_1',
            serverType: 'plex',
            ratingKey: 'rk_1',
          ),
        ],
        children: [
          TracearrMediaChild(
            id: 'season_1',
            mediaType: 'season',
            title: 'Season 1',
            seasonNumber: 1,
            episodeCount: 9,
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            tracearrMediaDetailProvider((testInstance, 'show_1')).overrideWith(
              (ref) async => testShowDetail,
            ),
            tracearrMediaHistoryProvider((testInstance, 'show_1')).overrideWith(
              (ref) async => const TracearrHistoryPage(items: []),
            ),
          ],
          child: const MaterialApp(
            home: TracearrMediaDetailScreen(
              instance: testInstance,
              mediaRef: 'show_1',
              initialTitle: 'Severance',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final hierarchyFinder = find.byType(MediaTvHierarchyView);
      final availabilityFinder = find.byType(MediaAvailabilityCard);

      expect(hierarchyFinder, findsOneWidget);
      expect(availabilityFinder, findsOneWidget);

      final hierarchyTop = tester.getTopLeft(hierarchyFinder).dy;
      final availabilityTop = tester.getTopLeft(availabilityFinder).dy;

      expect(hierarchyTop, lessThan(availabilityTop));
    });

    testWidgets(
        'Non-Plex launcher displays clean notice without raw server IDs',
        (tester) async {
      const nonPlexAvailability = [
        TracearrMediaAvailability(
          serverId: '7c89f5a0-9b34-45e1-8899-abcdef012345',
          serverType: 'jellyfin',
          ratingKey: 'jf_item_99',
        ),
      ];

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MediaAvailabilityCard(
              instance: testInstance,
              availability: nonPlexAvailability,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('JELLYFIN'), findsOneWidget);
      await tester.tap(find.byIcon(Icons.open_in_new));
      await tester.pumpAndSettle();

      expect(
        find.text(
          'Direct web player launching is currently only supported for Plex servers.',
        ),
        findsOneWidget,
      );
      expect(
        find.textContaining('7c89f5a0-9b34-45e1-8899-abcdef012345'),
        findsNothing,
      );
    });
  });
}
