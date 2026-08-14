import 'package:core_models/core_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:service_tracearr/src/activity/widgets/history_item_card.dart';
import 'package:service_tracearr/src/activity/widgets/history_session_diagnostics_sheet.dart';
import 'package:service_tracearr/src/cache/tracearr_artwork_cache.dart';
import 'package:service_tracearr/src/generated/api/raw_public_a_p_i_v2_api.dart';
import 'package:service_tracearr/src/media/screens/tracearr_media_detail_screen.dart';
import 'package:service_tracearr/src/models/tracearr_models.dart';
import 'package:service_tracearr/src/people/screens/tracearr_user_dossier_screen.dart';
import 'package:service_tracearr/src/providers/tracearr_providers.dart';
import 'package:service_tracearr/src/repository/tracearr_repository.dart';

class FakeV2ApiForHistoryCard implements RawPublicAPIV2Api {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeTracearrRepositoryForCard extends TracearrRepository {
  FakeTracearrRepositoryForCard()
      : super(
          apiV2: FakeV2ApiForHistoryCard(),
          artworkCache: TracearrArtworkCache(),
          baseUrl: 'https://tr.example.com',
        );

  @override
  Future<TracearrMediaDetail> getMediaDetail(String refKey) async {
    return TracearrMediaDetail(
      id: refKey,
      title: 'Oppenheimer',
      year: 2023,
    );
  }

  @override
  Future<List<TracearrMediaChild>> getMediaChildren(String refKey) async {
    return const [];
  }

  @override
  Future<TracearrUserDetail> getUserDetail(String userId) async {
    return TracearrUserDetail(
      id: userId,
      username: 'Bhavya',
      allTimePlays: 1,
      allTimeWatchTimeMs: 10800000,
    );
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

  const testHistoryItem = TracearrHistoryItem(
    id: 'hist_99',
    serverId: 'srv_1',
    serverName: 'Plex Cloud',
    serverType: 'plex',
    mediaTitle: 'Oppenheimer',
    ratingKey: 'rating_key_oppenheimer',
    userUsername: 'Bhavya',
    userId: 'user_uuid_bhavya',
    serverUserId: 'server_user_1',
    watched: true,
    percentComplete: 100.0,
    durationMs: 10800000,
    isTranscode: false,
    resolution: '4K',
  );

  Widget createCardWidget([TracearrHistoryItem item = testHistoryItem]) {
    final fakeRepo = FakeTracearrRepositoryForCard();
    return ProviderScope(
      overrides: [
        tracearrRepositoryProvider(testInstance)
            .overrideWith((ref) async => fakeRepo),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: HistoryItemCard(
            item: item,
            instance: testInstance,
          ),
        ),
      ),
    );
  }

  group('HistoryItemCard Gesture and Navigation Contract', () {
    testWidgets('tapping title navigates to TracearrMediaDetailScreen',
        (tester) async {
      await tester.pumpWidget(createCardWidget());
      await tester.pumpAndSettle();

      // Tap on title text
      await tester.tap(find.text('Oppenheimer'));
      await tester.pumpAndSettle();

      expect(find.byType(TracearrMediaDetailScreen), findsOneWidget);
    });

    testWidgets('media navigation prioritizes mediaId over ratingKey and id',
        (tester) async {
      const itemWithMediaId = TracearrHistoryItem(
        id: 'session_row_id',
        serverId: 'srv_1',
        serverName: 'Plex Cloud',
        serverType: 'plex',
        userUsername: 'Bhavya',
        mediaId: 'canonical_media_uuid',
        ratingKey: 'plex_rating_key',
        mediaTitle: 'Dune',
      );

      await tester.pumpWidget(createCardWidget(itemWithMediaId));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Dune'));
      await tester.pumpAndSettle();

      final detailScreen =
          tester.widget<TracearrMediaDetailScreen>(find.byType(TracearrMediaDetailScreen));
      expect(detailScreen.mediaRef, equals('canonical_media_uuid'));
    });

    testWidgets('media navigation falls back to ratingKey when mediaId is null',
        (tester) async {
      const itemWithRatingKey = TracearrHistoryItem(
        id: 'session_row_id',
        serverId: 'srv_1',
        serverName: 'Plex Cloud',
        serverType: 'plex',
        userUsername: 'Bhavya',
        ratingKey: 'plex_rating_key',
        mediaTitle: 'Interstellar',
      );

      await tester.pumpWidget(createCardWidget(itemWithRatingKey));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Interstellar'));
      await tester.pumpAndSettle();

      final detailScreen =
          tester.widget<TracearrMediaDetailScreen>(find.byType(TracearrMediaDetailScreen));
      expect(detailScreen.mediaRef, equals('plex_rating_key'));
    });

    testWidgets('tapping username/avatar navigates to TracearrUserDossierScreen',
        (tester) async {
      await tester.pumpWidget(createCardWidget());
      await tester.pumpAndSettle();

      // Tap on username handle
      await tester.tap(find.text('@Bhavya'));
      await tester.pumpAndSettle();

      expect(find.byType(TracearrUserDossierScreen), findsOneWidget);
    });

    testWidgets('tapping card body opens HistorySessionDiagnosticsSheet',
        (tester) async {
      await tester.pumpWidget(createCardWidget());
      await tester.pumpAndSettle();

      // Tap on quality badge 'Direct Play'
      await tester.tap(find.text('Direct Play'));
      await tester.pumpAndSettle();

      expect(find.byType(HistorySessionDiagnosticsSheet), findsOneWidget);
      expect(find.text('SESSION & CHAIN HISTORY'), findsOneWidget);
      expect(find.text('VIDEO PIPELINE TELEMETRY'), findsOneWidget);
    });
  });

  group('HistoryItemCard Playback Quality Classification', () {
    testWidgets('labels video copy as Direct Stream even when isTranscode is true',
        (tester) async {
      const copyItem = TracearrHistoryItem(
        id: 'h1',
        serverId: 'srv_1',
        serverName: 'Plex Cloud',
        serverType: 'plex',
        userUsername: 'Bhavya',
        mediaTitle: 'Test Remux',
        isTranscode: true,
        videoDecision: 'copy',
        audioDecision: 'transcode',
      );

      await tester.pumpWidget(createCardWidget(copyItem));
      await tester.pumpAndSettle();

      expect(find.text('Direct Stream'), findsOneWidget);
    });

    testWidgets('labels video transcode with hardware acceleration as HW Transcode',
        (tester) async {
      const hwItem = TracearrHistoryItem(
        id: 'h2',
        serverId: 'srv_1',
        serverName: 'Plex Cloud',
        serverType: 'plex',
        userUsername: 'Bhavya',
        mediaTitle: 'Test HW',
        isTranscode: true,
        videoDecision: 'transcode',
        isHwTranscode: true,
      );

      await tester.pumpWidget(createCardWidget(hwItem));
      await tester.pumpAndSettle();

      expect(find.text('HW Transcode'), findsOneWidget);
    });

    testWidgets('labels video transcode without hardware acceleration as CPU Transcode',
        (tester) async {
      const cpuItem = TracearrHistoryItem(
        id: 'h3',
        serverId: 'srv_1',
        serverName: 'Plex Cloud',
        serverType: 'plex',
        userUsername: 'Bhavya',
        mediaTitle: 'Test CPU',
        isTranscode: true,
        videoDecision: 'transcode',
      );

      await tester.pumpWidget(createCardWidget(cpuItem));
      await tester.pumpAndSettle();

      expect(find.text('CPU Transcode'), findsOneWidget);
    });

    testWidgets('labels directplay as Direct Play',
        (tester) async {
      const dpItem = TracearrHistoryItem(
        id: 'h4',
        serverId: 'srv_1',
        serverName: 'Plex Cloud',
        serverType: 'plex',
        userUsername: 'Bhavya',
        mediaTitle: 'Test DP',
        isTranscode: false,
        videoDecision: 'directplay',
        audioDecision: 'directplay',
      );

      await tester.pumpWidget(createCardWidget(dpItem));
      await tester.pumpAndSettle();

      expect(find.text('Direct Play'), findsOneWidget);
    });
  });
}
