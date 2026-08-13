import 'package:core_models/core_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:service_tracearr/src/cache/tracearr_artwork_cache.dart';
import 'package:service_tracearr/src/generated/api/raw_public_a_p_i_v2_api.dart';
import 'package:service_tracearr/src/models/tracearr_models.dart';
import 'package:service_tracearr/src/people/people_tab.dart';
import 'package:service_tracearr/src/people/screens/tracearr_user_dossier_screen.dart';
import 'package:service_tracearr/src/people/screens/widgets/user_genre_breakdown_card.dart';
import 'package:service_tracearr/src/people/screens/widgets/user_linked_accounts_card.dart';
import 'package:service_tracearr/src/people/widgets/user_directory_section.dart';
import 'package:service_tracearr/src/people/widgets/user_roster_card.dart';
import 'package:service_tracearr/src/providers/tracearr_providers.dart';
import 'package:service_tracearr/src/repository/tracearr_repository.dart';

class FakeV2ApiForPeople implements RawPublicAPIV2Api {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeTracearrPeopleRepository extends TracearrRepository {
  FakeTracearrPeopleRepository({
    this.users = const [],
  }) : super(
          apiV2: FakeV2ApiForPeople(),
          artworkCache: TracearrArtworkCache(),
          baseUrl: 'https://tr.example.com',
        );

  final List<TracearrUserSummary> users;

  @override
  Future<List<TracearrUserSummary>> getUsers({
    int maxConcurrency = 4,
  }) async {
    return users;
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

  final testUsers = [
    TracearrUserSummary(
      id: 'usr_1',
      username: 'Bhavya',
      email: 'bhavya@example.com',
      allTimePlays: 240,
      allTimeWatchTimeMs: 1440000000, // 400h
      lastActiveAt: DateTime.now().subtract(const Duration(hours: 2)),
      accounts: const [
        TracearrUserAccount(
          serverId: 'srv_1',
          serverType: 'plex',
          serverUserId: 'px_usr_1',
          externalUserId: 'ext_1',
          username: 'Bhavya',
        ),
        TracearrUserAccount(
          serverId: 'srv_2',
          serverType: 'jellyfin',
          serverUserId: 'jf_usr_1',
          externalUserId: 'ext_2',
          username: 'BhavyaJelly',
        ),
      ],
    ),
    TracearrUserSummary(
      id: 'usr_2',
      username: 'Alex',
      email: 'alex@example.com',
      allTimePlays: 110,
      allTimeWatchTimeMs: 720000000, // 200h
      lastActiveAt: DateTime.now().subtract(const Duration(days: 1)),
      accounts: const [
        TracearrUserAccount(
          serverId: 'srv_1',
          serverType: 'plex',
          serverUserId: 'px_usr_2',
          externalUserId: 'ext_3',
          username: 'Alex',
        ),
      ],
    ),
  ];

  const testUserDetail = TracearrUserDetail(
    id: 'usr_1',
    username: 'Bhavya',
    email: 'bhavya@example.com',
    plexAccountId: 'plex_acc_99',
    allTimePlays: 240,
    allTimeWatchTimeMs: 1440000000, // 400h
    last30DaysPlays: 32,
    last7DaysPlays: 8,
    accounts: [
      TracearrUserAccount(
        serverId: 'srv_1',
        serverType: 'plex',
        serverUserId: 'px_usr_1',
        externalUserId: 'ext_1',
        username: 'Bhavya',
      ),
      TracearrUserAccount(
        serverId: 'srv_2',
        serverType: 'jellyfin',
        serverUserId: 'jf_usr_1',
        externalUserId: 'ext_2',
        username: 'BhavyaJelly',
      ),
    ],
    topGenres: [
      TracearrGenreStat(genre: 'Sci-Fi', plays: 95),
      TracearrGenreStat(genre: 'Drama', plays: 60),
      TracearrGenreStat(genre: 'Action', plays: 45),
    ],
  );

  Widget createPeopleTabWidget({
    List<TracearrUserSummary>? users,
  }) {
    final fakeRepo = FakeTracearrPeopleRepository(
      users: users ?? testUsers,
    );

    return ProviderScope(
      overrides: [
        tracearrRepositoryProvider(testInstance)
            .overrideWith((ref) async => fakeRepo),
      ],
      child: const MaterialApp(
        home: PeopleTab(
          instance: testInstance,
        ),
      ),
    );
  }

  group('PeopleTab Destination', () {
    testWidgets('renders fleet user roster with accounts and telemetry',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createPeopleTabWidget());
      await tester.pumpAndSettle();

      expect(find.byType(UserDirectorySection), findsOneWidget);
      expect(find.text('FLEET USERS (2)'), findsOneWidget);
      expect(find.byType(UserRosterCard), findsNWidgets(2));

      expect(find.text('@Bhavya'), findsOneWidget);
      expect(find.text('bhavya@example.com'), findsOneWidget);
      expect(find.text('2 accts'), findsOneWidget);
      expect(find.text('240 plays'), findsOneWidget);

      expect(find.text('@Alex'), findsOneWidget);
      expect(find.text('alex@example.com'), findsOneWidget);
      expect(find.text('1 acct'), findsOneWidget);
      expect(find.text('110 plays'), findsOneWidget);
    });

    testWidgets('filters roster dynamically on live search input',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createPeopleTabWidget());
      await tester.pumpAndSettle();

      // Enter search query
      await tester.enterText(find.byType(TextField), 'Alex');
      await tester.pumpAndSettle();

      expect(find.byType(UserRosterCard), findsOneWidget);
      expect(find.text('@Alex'), findsOneWidget);
      expect(find.text('@Bhavya'), findsNothing);

      // Clear search
      await tester.tap(find.byIcon(Icons.clear));
      await tester.pumpAndSettle();

      expect(find.byType(UserRosterCard), findsNWidgets(2));
    });

    testWidgets('renders live WATCHING badge when user is streaming',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final List<TracearrStream> testStreams = [
        const TracearrStream(
          id: 'stream_1',
          serverId: 'srv_1',
          serverName: 'Plex Cloud',
          serverType: 'plex',
          mediaTitle: 'Inception',
          userUsername: 'Bhavya',
          userId: 'usr_1',
          percentComplete: 0.5,
          durationMs: 7200000,
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            tracearrRepositoryProvider(testInstance).overrideWith(
              (ref) async => FakeTracearrPeopleRepository(users: testUsers),
            ),
            tracearrStreamsProvider(testInstance).overrideWith(
              (ref) async => testStreams,
            ),
          ],
          child: const MaterialApp(
            home: PeopleTab(
              instance: testInstance,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('WATCHING'), findsOneWidget);
    });
  });

  group('TracearrUserDossierScreen', () {
    testWidgets(
        'renders user profile, lifetime stats, linked accounts, and genres',
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
            tracearrUserDetailProvider((testInstance, 'usr_1')).overrideWith(
              (ref) async => testUserDetail,
            ),
          ],
          child: const MaterialApp(
            home: TracearrUserDossierScreen(
              instance: testInstance,
              userId: 'usr_1',
              username: 'Bhavya',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('@Bhavya'), findsWidgets);
      expect(find.text('bhavya@example.com'), findsOneWidget);
      expect(find.text('Plex Account ID: plex_acc_99'), findsOneWidget);

      // Lifetime stats
      expect(find.text('TOTAL PLAYS'), findsOneWidget);
      expect(find.text('240'), findsOneWidget);
      expect(find.text('WATCH TIME'), findsOneWidget);
      expect(find.text('400.0h'), findsOneWidget);
      expect(find.text('30D PLAYS'), findsOneWidget);
      expect(find.text('32'), findsOneWidget);
      expect(find.text('7D PLAYS'), findsOneWidget);
      expect(find.text('8'), findsOneWidget);

      // Linked Server Identities
      expect(find.byType(UserLinkedAccountsCard), findsOneWidget);
      expect(find.text('LINKED SERVER IDENTITIES (2)'), findsOneWidget);
      expect(find.text('PLEX'), findsOneWidget);
      expect(find.text('JELLYFIN'), findsOneWidget);
      expect(find.text('BhavyaJelly'), findsOneWidget);

      // Top Genres
      expect(find.byType(UserGenreBreakdownCard), findsOneWidget);
      expect(find.text('TOP GENRES & HABITS'), findsOneWidget);
      expect(find.text('Sci-Fi'), findsOneWidget);
      expect(find.text('95 plays'), findsOneWidget);
      expect(find.text('Drama'), findsOneWidget);
      expect(find.text('60 plays'), findsOneWidget);
    });
  });
}
