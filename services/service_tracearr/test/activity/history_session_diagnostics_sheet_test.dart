import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:service_tracearr/src/activity/widgets/history_session_diagnostics_sheet.dart';
import 'package:service_tracearr/src/models/tracearr_models.dart';

void main() {
  group('HistorySessionDiagnosticsSheet', () {
    testWidgets(
        'renders all diagnostic telemetry sections correctly with tone-mapping',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final historyItem = TracearrHistoryItem(
        id: 'hist_42',
        serverId: 'srv_1',
        serverName: 'Plex Cloud',
        serverType: 'plex',
        mediaTitle: 'Dune: Part Two',
        showTitle: 'Sci-Fi Showcase',
        seasonNumber: 1,
        episodeNumber: 2,
        userUsername: 'Bhavya',
        watched: true,
        percentComplete: 100.0,
        durationMs: 7200000,
        segmentCount: 3,
        startedAt: DateTime.parse('2026-08-10T14:30:00.000Z'),
        stoppedAt: DateTime.parse('2026-08-10T16:30:00.000Z'),
        isTranscode: true,
        isHwTranscode: true,
        hwDecoding: 'NVENC',
        videoDecision: 'transcode',
        audioDecision: 'directplay',
        videoCodec: 'HEVC',
        resolution: '1080p',
        sourceResolution: '3840x2160',
        streamResolution: '1920x1080',
        sourceDynamicRange: 'HDR10',
        streamDynamicRange: 'SDR',
        sourceContainer: 'mkv',
        streamContainer: 'mpegts',
        transcodeSpeed: 4.2,
        isThrottled: true,
        transcodeReasons: ['Container not supported by client'],
        audioCodec: 'EAC3',
        audioChannels: '5.1',
        subtitleLanguage: 'English',
        subtitleCodec: 'PGS',
        subtitleDecision: 'burn',
        player: 'Plex for Android',
        device: 'Pixel 8 Pro',
        product: 'Plex',
        platform: 'Android',
        bitrate: 15400,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HistorySessionDiagnosticsSheet(
              item: historyItem,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Header
      expect(find.text('Dune: Part Two'), findsOneWidget);
      expect(find.text('Sci-Fi Showcase • S1:E2'), findsOneWidget);
      expect(find.text('@Bhavya on Plex Cloud (PLEX)'), findsOneWidget);

      // Section 1: Session & Chain
      expect(find.text('SESSION & CHAIN HISTORY'), findsOneWidget);
      expect(find.text('Completed'), findsOneWidget);
      expect(find.text('2h'), findsOneWidget);
      expect(find.text('3 sessions merged'), findsOneWidget);

      // Section 2: Video Pipeline
      expect(find.text('VIDEO PIPELINE TELEMETRY'), findsOneWidget);
      expect(find.text('TRANSCODE'), findsOneWidget);
      expect(find.text('HEVC'), findsOneWidget);
      expect(find.text('3840x2160 → 1920x1080'), findsOneWidget);
      expect(find.text('Source Dynamic Range'), findsOneWidget);
      expect(find.text('HDR10'), findsOneWidget);
      expect(find.text('Stream Dynamic Range'), findsOneWidget);
      expect(find.text('SDR (Tone-Mapped)'), findsOneWidget);
      expect(find.text('MKV → MPEGTS'), findsOneWidget);
      expect(find.text('Active (NVENC)'), findsOneWidget);
      expect(find.text('4.2x'), findsOneWidget);
      expect(find.text('Yes (CPU Saved)'), findsOneWidget);
      expect(find.text('• Container not supported by client'), findsOneWidget);

      // Section 3: Audio & Subtitles
      expect(find.text('AUDIO & SUBTITLES'), findsOneWidget);
      expect(find.text('DIRECTPLAY'), findsOneWidget);
      expect(find.text('EAC3'), findsOneWidget);
      expect(find.text('5.1'), findsOneWidget);
      expect(find.text('English (PGS)'), findsOneWidget);
      expect(find.text('BURN'), findsOneWidget);

      // Section 4: Client & Environment
      expect(find.text('CLIENT & PLAYBACK ENVIRONMENT'), findsOneWidget);
      expect(find.text('Plex for Android'), findsOneWidget);
      expect(find.text('Pixel 8 Pro'), findsOneWidget);
      expect(find.text('Android'), findsOneWidget);
      expect(find.text('15.4 Mbps'), findsOneWidget);
    });

    testWidgets(
        'renders single dynamic range row when source and stream dynamic range match',
        (tester) async {
      const historyItem = TracearrHistoryItem(
        id: 'hist_single_dr',
        serverId: 'srv_1',
        serverName: 'Jellyfin',
        serverType: 'jellyfin',
        mediaTitle: 'Blade Runner 2049',
        userUsername: 'Bhavya',
        sourceDynamicRange: 'HDR10',
        streamDynamicRange: 'HDR10',
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HistorySessionDiagnosticsSheet(item: historyItem),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Dynamic Range'), findsOneWidget);
      expect(find.text('HDR10'), findsOneWidget);
      expect(find.text('Source Dynamic Range'), findsNothing);
      expect(find.text('Stream Dynamic Range'), findsNothing);
    });

    testWidgets(
        'renders gracefully when all optional telemetry fields are null (null-safety)',
        (tester) async {
      const minimalItem = TracearrHistoryItem(
        id: 'hist_min',
        serverId: 'srv_minimal',
        serverName: 'Local Server',
        serverType: 'emby',
        mediaTitle: 'Minimal Movie',
        userUsername: 'Bhavya',
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HistorySessionDiagnosticsSheet(item: minimalItem),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Basic required headers
      expect(find.text('Minimal Movie'), findsOneWidget);
      expect(find.text('@Bhavya on Local Server (EMBY)'), findsOneWidget);

      // Default non-crashing fallbacks
      expect(
        find.text('DIRECT PLAY'),
        findsNWidgets(2),
      ); // video & audio default

      // Optional rows MUST be absent
      expect(find.text('Watch Time'), findsNothing);
      expect(find.text('Resume Chain'), findsNothing);
      expect(find.text('Started At'), findsNothing);
      expect(find.text('Stopped At'), findsNothing);
      expect(find.text('Video Codec'), findsNothing);
      expect(find.text('Resolution'), findsNothing);
      expect(find.text('Dimensions'), findsNothing);
      expect(find.text('Dynamic Range'), findsNothing);
      expect(find.text('Source Dynamic Range'), findsNothing);
      expect(find.text('Stream Dynamic Range'), findsNothing);
      expect(find.text('Container'), findsNothing);
      expect(find.text('Hardware Acceleration'), findsNothing);
      expect(find.text('Transcode Speed'), findsNothing);
      expect(find.text('Throttled'), findsNothing);
      expect(find.text('Transcode Reasons:'), findsNothing);
      expect(find.text('Audio Codec'), findsNothing);
      expect(find.text('Audio Channels'), findsNothing);
      expect(find.text('Subtitles'), findsNothing);
      expect(find.text('Subtitle Mode'), findsNothing);
      expect(find.text('Player'), findsNothing);
      expect(find.text('Device'), findsNothing);
      expect(find.text('Product'), findsNothing);
      expect(find.text('Platform'), findsNothing);
      expect(find.text('Average Bitrate'), findsNothing);
    });
  });
}
