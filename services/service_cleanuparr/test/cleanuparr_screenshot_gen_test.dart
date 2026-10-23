import 'dart:io';
import 'dart:ui' as ui;

import 'package:core_models/core_models.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:service_cleanuparr/service_cleanuparr.dart';

const String _fontDir =
    r'C:\Users\bhavy\development\flutter\bin\cache\artifacts\material_fonts';
const String _siteOutDir =
    r'C:\Users\bhavy\Documents\Projects\Atrium\site\public\assets\service_previews\cleanuparr';
const String _buildOutDir =
    r'C:\Users\bhavy\Documents\Projects\Atrium\services\service_cleanuparr\build\screenshots';
const String _artifactOutDir =
    r'C:\Users\bhavy\.gemini\antigravity\brain\e17bb2e9-c1e2-4c39-adb3-fda7246421d6\cleanuparr_shots';

const Instance testInstance = Instance(
  id: 'cleanuparr-1',
  name: 'Home Cleanuparr',
  kind: ServiceKind.cleanuparr,
  localUrl: 'http://cleanuparr.local:11011/',
  externalUrl: '',
  urlMode: UrlMode.auto,
  auth: InstanceAuthApiKey(apiKey: 'cleanuparr-secret-key'),
);

Future<void> _loadFonts() async {
  final FontLoader roboto = FontLoader('Roboto');
  for (final String font in ['roboto-regular.ttf', 'roboto-medium.ttf', 'roboto-bold.ttf']) {
    final File f = File('$_fontDir\\$font');
    if (f.existsSync()) {
      roboto.addFont(f.readAsBytes().then((b) => ByteData.view(b.buffer)));
    }
  }
  await roboto.load();

  final FontLoader icons = FontLoader('MaterialIcons');
  final File iconFile = File('$_fontDir\\materialicons-regular.otf');
  if (iconFile.existsSync()) {
    icons.addFont(iconFile.readAsBytes().then((b) => ByteData.view(b.buffer)));
    await icons.load();
  }
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await _loadFonts();
    Directory(_siteOutDir).createSync(recursive: true);
    Directory(_buildOutDir).createSync(recursive: true);
    Directory(_artifactOutDir).createSync(recursive: true);
  });

  const CleanuparrStatus sampleStatus = CleanuparrStatus(
    version: '2.4.0',
    appName: 'Cleanuparr',
    branch: 'master',
    memoryUsageMB: 142.5,
    mediaManagers: <CleanuparrManagerStatus>[
      CleanuparrManagerStatus(name: 'Sonarr', type: 'Sonarr'),
      CleanuparrManagerStatus(name: 'Radarr', type: 'Radarr'),
    ],
    downloadClients: <CleanuparrClientStatus>[
      CleanuparrClientStatus(name: 'qBittorrent', type: 'qBittorrent'),
    ],
  );

  const CleanuparrStats sampleStats = CleanuparrStats(
    hours: 168,
    totalEvents: 42,
    eventsWarning: 8,
    eventsError: 4,
    strikesIssued: 15,
    strikesRecovered: 6,
    activeStrikes: 2,
    malwareBlocked: 5,
    totalRemovals: 7,
    totalCleaned: 14,
    seekerTriggers: 9,
    seekerGrabbed: 4,
  );

  const List<CleanuparrJob> sampleJobs = <CleanuparrJob>[
    CleanuparrJob(
      jobType: 'MalwareBlocker',
      displayName: 'Malware Blocker',
      intervalDescription: 'Every 5m',
    ),
    CleanuparrJob(
      jobType: 'QueueCleaner',
      displayName: 'Queue Cleaner',
      intervalDescription: 'Every 15m',
    ),
    CleanuparrJob(
      jobType: 'DownloadCleaner',
      displayName: 'Download Cleaner',
      intervalDescription: 'Every 30m',
    ),
  ];

  const List<CleanuparrStrikeItem> sampleStrikes = <CleanuparrStrikeItem>[
    CleanuparrStrikeItem(
      id: 'hash1',
      title: 'Gladiator.II.2024.1080p.AMZN.WEB-DL.DDP5.1.Atmos',
      downloadClientName: 'qBittorrent',
      strikeCount: 2,
      strikes: <CleanuparrStrikeDetail>[
        CleanuparrStrikeDetail(
          type: 'StalledStrike',
          reason: 'Stalled at 42.1% for > 15m with 0 B/s',
        ),
      ],
    ),
    CleanuparrStrikeItem(
      id: 'hash2',
      title: 'Severance.S02E01.1080p.WEB-DL.DDP5.1',
      downloadClientName: 'qBittorrent',
      strikeCount: 3,
      strikes: <CleanuparrStrikeDetail>[
        CleanuparrStrikeDetail(
          type: 'FailedImportStrike',
          reason: 'Import failed: Destination path disk quota reached',
        ),
      ],
    ),
  ];

  final List<CleanuparrEvent> sampleEvents = <CleanuparrEvent>[
    CleanuparrEvent(
      id: 'ev-1',
      timestamp: DateTime.now().subtract(const Duration(minutes: 8)),
      eventType: 'MalwareBlocked',
      severity: 'Critical',
      message: 'Blocked malicious payload: detected disguised .exe executable inside archive contents',
      downloadItemTitle: 'Adobe.Photoshop.2025.Cracked.Payload.exe',
      downloadClientName: 'qBittorrent',
      hash: '9a8b7c6d5e4f3a2b1c',
      deleteReason: 'MalwarePayloadSignature',
    ),
    CleanuparrEvent(
      id: 'ev-2',
      timestamp: DateTime.now().subtract(const Duration(minutes: 32)),
      eventType: 'StalledStrike',
      severity: 'Warning',
      message: 'Recorded strike: Download stalled for more than 15 minutes with zero throughput',
      downloadItemTitle: 'Gladiator.II.2024.1080p.AMZN.WEB-DL',
      downloadClientName: 'qBittorrent',
      hash: '3f2e1d0c9b8a7f6e5d',
    ),
    CleanuparrEvent(
      id: 'ev-3',
      timestamp: DateTime.now().subtract(const Duration(hours: 2)),
      eventType: 'DownloadCleaned',
      severity: 'Info',
      message: 'Cleaned orphaned download item removed by Sonarr queue',
      downloadItemTitle: 'Slow.Horses.S04E06.1080p',
      downloadClientName: 'qBittorrent',
      hash: '1a2b3c4d5e6f7a8b9c',
      deleteReason: 'OrphanedQueueRemoval',
    ),
  ];

  Future<void> saveScreenshot(
    WidgetTester tester,
    GlobalKey key,
    String baseName,
  ) async {
    await tester.runAsync(() async {
      final RenderRepaintBoundary boundary =
          key.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final ui.Image image = await boundary.toImage(pixelRatio: 2.75);
      final ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      final Uint8List bytes = byteData!.buffer.asUint8List();

      File('$_siteOutDir\\$baseName.png').writeAsBytesSync(bytes);
      File('$_buildOutDir\\$baseName.png').writeAsBytesSync(bytes);
      File('$_artifactOutDir\\$baseName.png').writeAsBytesSync(bytes);
    });
  }

  void setupMobileView(WidgetTester tester) {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.75;
    tester.view.padding = const FakeViewPadding(top: 110.0, bottom: 66.0);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPadding);
  }

  Widget buildApp(GlobalKey shotKey, {int initialTab = 0}) {
    return ProviderScope(
      overrides: [
        cleanuparrStatusProvider(testInstance).overrideWith((ref) => sampleStatus),
        cleanuparrStatsProvider(testInstance).overrideWith((ref) => sampleStats),
        cleanuparrJobsProvider(testInstance).overrideWith((ref) => sampleJobs),
        cleanuparrStrikesProvider(testInstance).overrideWith((ref) => sampleStrikes),
        cleanuparrEventsProvider(testInstance).overrideWith((ref) => sampleEvents),
        cleanuparrTabProvider(testInstance).overrideWith((ref) => initialTab),
      ],
      child: MaterialApp(
        theme: AtriumTheme.dark(
          ColorScheme.fromSeed(
            seedColor: const Color(0xFF7C3AED),
            brightness: Brightness.dark,
          ),
        ),
        debugShowCheckedModeBanner: false,
        builder: (context, child) => RepaintBoundary(
          key: shotKey,
          child: child!,
        ),
        home: const CleanuparrHome(instance: testInstance),
      ),
    );
  }

  testWidgets('Shot 1: Overview Tab', (WidgetTester tester) async {
    setupMobileView(tester);

    final GlobalKey shotKey = GlobalKey();
    await tester.pumpWidget(buildApp(shotKey));
    await tester.pumpAndSettle();
    await saveScreenshot(tester, shotKey, 'cleanuparr_1');
  });

  testWidgets('Shot 2: Strikes Tab', (WidgetTester tester) async {
    setupMobileView(tester);

    final GlobalKey shotKey = GlobalKey();
    await tester.pumpWidget(buildApp(shotKey, initialTab: 1));
    await tester.pumpAndSettle();
    await saveScreenshot(tester, shotKey, 'cleanuparr_2');
  });

  testWidgets('Shot 3: Events Tab', (WidgetTester tester) async {
    setupMobileView(tester);

    final GlobalKey shotKey = GlobalKey();
    await tester.pumpWidget(buildApp(shotKey, initialTab: 2));
    await tester.pumpAndSettle();
    await saveScreenshot(tester, shotKey, 'cleanuparr_3');
  });

  testWidgets('Shot 4: Event Detail Sheet', (WidgetTester tester) async {
    setupMobileView(tester);

    final GlobalKey shotKey = GlobalKey();
    await tester.pumpWidget(buildApp(shotKey, initialTab: 2));
    await tester.pumpAndSettle();
    await tester.tap(find.text('MalwareBlocked'));
    await tester.pumpAndSettle();
    await saveScreenshot(tester, shotKey, 'cleanuparr_4');
  });
}
