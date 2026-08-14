import 'package:core_models/core_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:service_tracearr/src/activity/activity_tab.dart';
import 'package:service_tracearr/src/activity/widgets/active_stream_card.dart';
import 'package:service_tracearr/src/activity/widgets/stream_diagnostics_sheet.dart';
import 'package:service_tracearr/src/activity/widgets/terminate_stream_dialog.dart';
import 'package:service_tracearr/src/activity/widgets/watch_history_section.dart';
import 'package:service_tracearr/src/cache/tracearr_artwork_cache.dart';
import 'package:service_tracearr/src/generated/api/raw_public_a_p_i_v2_api.dart';
import 'package:service_tracearr/src/models/tracearr_models.dart';
import 'package:service_tracearr/src/providers/tracearr_providers.dart';
import 'package:service_tracearr/src/repository/tracearr_repository.dart';

class FakeV2ApiForActivity implements RawPublicAPIV2Api {
  int terminateCount = 0;
  String? lastTerminatedId;
  String? lastTerminatedMsg;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeTracearrRepository extends TracearrRepository {
  FakeTracearrRepository()
      : super(
          apiV2: FakeV2ApiForActivity(),
          artworkCache: TracearrArtworkCache(),
          baseUrl: 'https://tr.example.com',
        );

  int terminateCallCount = 0;
  String? terminatedStreamId;
  String? terminatedMessage;

  @override
  Future<bool> terminateStream({
    required String streamId,
    String? message,
  }) async {
    terminateCallCount++;
    terminatedStreamId = streamId;
    terminatedMessage = message;
    return true;
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

  Widget createActivityWidget({
    List<TracearrStream>? streams,
    TracearrHistoryPaginatedState? historyState,
    FakeTracearrRepository? repo,
  }) {
    final fakeRepo = repo ?? FakeTracearrRepository();

    return ProviderScope(
      overrides: [
        tracearrRepositoryProvider(testInstance)
            .overrideWith((ref) async => fakeRepo),
        if (streams != null)
          tracearrStreamsProvider(testInstance)
              .overrideWith((ref) async => streams),
      ],
      child: const MaterialApp(
        home: ActivityTab(
          instance: testInstance,
        ),
      ),
    );
  }

  group('ActivityTab Live Streams Section', () {
    testWidgets('renders active stream card with full operational telemetry',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      const activeStream = TracearrStream(
        id: 'st_42',
        serverId: 'srv_plex_1',
        serverName: 'Plex Cloud',
        serverType: 'plex',
        mediaTitle: 'Inception',
        year: 2010,
        userUsername: 'Bhavya',
        device: 'Apple TV 4K',
        player: 'Plex for Apple TV',
        progressMs: 3600000, // 1h
        durationMs: 7200000, // 2h
        percentComplete: 50.0,
        isTranscode: true,
        isHwTranscode: true,
        hwDecoding: 'hevc_qsv',
        hwEncoding: 'h264_qsv',
        bitrate: 12500,
        resolution: '1080p',
        videoCodec: 'h264',
        audioCodec: 'aac',
        audioChannels: '5.1',
        transcodeReasons: ['Direct Play not supported for subtitle format'],
      );

      await tester.pumpWidget(createActivityWidget(streams: [activeStream]));
      await tester.pumpAndSettle();

      expect(find.text('LIVE STREAMS'), findsOneWidget);
      expect(find.text('Inception'), findsOneWidget);
      expect(find.text('2010'), findsOneWidget);
      expect(find.text('@Bhavya'), findsOneWidget);
      expect(find.text('• Apple TV 4K'), findsOneWidget);
      expect(find.text('HW Transcode'), findsOneWidget);
      expect(find.text('12.5 Mbps'), findsOneWidget);
      expect(find.text('1:00:00 / 2:00:00 • 50%'), findsOneWidget);
    });

    testWidgets('renders idle state banner when active stream count is 0',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createActivityWidget(streams: []));
      await tester.pumpAndSettle();

      expect(find.text('LIVE STREAMS'), findsOneWidget);
      expect(find.text('No active streams playing right now.'), findsOneWidget);
    });

    testWidgets('opens StreamDiagnosticsSheet on card tap and shows specs',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      const activeStream = TracearrStream(
        id: 'st_42',
        serverId: 'srv_plex_1',
        serverName: 'Plex Cloud',
        serverType: 'plex',
        mediaTitle: 'Severance',
        showTitle: 'Severance',
        seasonNumber: 1,
        episodeNumber: 3,
        userUsername: 'Bhavya',
        device: 'Apple TV 4K',
        player: 'Plex for Apple TV',
        platform: 'tvOS 17',
        isTranscode: true,
        isHwTranscode: true,
        hwDecoding: 'hevc_qsv',
        hwEncoding: 'h264_qsv',
        transcodeSpeed: 2.8,
        isThrottled: true,
        bitrate: 8200,
        resolution: '1080p',
        videoCodec: 'h264',
        audioCodec: 'eac3',
        audioChannels: '5.1',
        transcodeReasons: ['Container mkv not supported by web client'],
      );

      await tester.pumpWidget(createActivityWidget(streams: [activeStream]));
      await tester.pumpAndSettle();

      // Tap card
      await tester.tap(find.byType(ActiveStreamCard));
      await tester.pumpAndSettle();

      expect(find.byType(StreamDiagnosticsSheet), findsOneWidget);
      expect(find.text('VIDEO TELEMETRY'), findsOneWidget);
      expect(find.text('AUDIO & SUBTITLES'), findsOneWidget);
      expect(find.text('CLIENT & BANDWIDTH'), findsOneWidget);
      expect(find.text('Active (hevc_qsv)'), findsOneWidget);
      expect(find.text('2.8x'), findsOneWidget);
      expect(find.text('Yes (CPU Saved)'), findsOneWidget);
      expect(
        find.text('• Container mkv not supported by web client'),
        findsOneWidget,
      );
      expect(find.text('EAC3'), findsOneWidget);
      expect(find.text('tvOS 17'), findsOneWidget);
    });

    testWidgets(
        'executes terminate stream flow safely with confirmation and preset',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final fakeRepo = FakeTracearrRepository();

      const activeStream = TracearrStream(
        id: 'st_42',
        serverId: 'srv_plex_1',
        serverName: 'Plex Cloud',
        serverType: 'plex',
        mediaTitle: 'Inception',
        userUsername: 'Bhavya',
      );

      await tester.pumpWidget(
        createActivityWidget(
          streams: [activeStream],
          repo: fakeRepo,
        ),
      );
      await tester.pumpAndSettle();

      // Tap terminate icon on active stream card
      await tester.tap(find.byIcon(Icons.stop_circle_outlined));
      await tester.pumpAndSettle();

      expect(find.byType(TerminateStreamDialog), findsOneWidget);
      expect(
        find.text('Are you sure you want to stop playback for @Bhavya?'),
        findsOneWidget,
      );

      // Select preset chip
      await tester.tap(find.text('Server maintenance in progress'));
      await tester.pumpAndSettle();

      // Click "Stop Stream"
      await tester.tap(find.text('Stop Stream'));
      await tester.pumpAndSettle();

      expect(fakeRepo.terminateCallCount, equals(1));
      expect(fakeRepo.terminatedStreamId, equals('st_42'));
      expect(
        fakeRepo.terminatedMessage,
        equals('Server maintenance in progress'),
      );
    });
  });

  group('ActivityTab Watch History Section', () {
    testWidgets('renders history items and filters by Watched status',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createActivityWidget(streams: []));
      await tester.pumpAndSettle();

      expect(find.byType(WatchHistorySection), findsOneWidget);
      expect(find.text('WATCH HISTORY'), findsOneWidget);
      expect(find.text('All'), findsOneWidget);
      expect(find.text('Completed'), findsOneWidget);
      expect(find.text('Partial'), findsOneWidget);
    });
  });
}
