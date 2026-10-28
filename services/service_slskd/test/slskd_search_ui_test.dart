import 'dart:io';
import 'dart:ui' as ui;

import 'package:core_models/core_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:service_slskd/service_slskd.dart';

const String _fontDir =
    r'C:\Users\bhavy\development\flutter\bin\cache\artifacts\material_fonts';
const String screenshotDir =
    r'C:\Users\bhavy\.gemini\antigravity\brain\e17bb2e9-c1e2-4c39-adb3-fda7246421d6';

const Instance testInstance = Instance(
  id: 'test-slskd-search',
  name: 'Soulseek Daemon',
  kind: ServiceKind.slskd,
  localUrl: 'http://127.0.0.1:5030/',
  externalUrl: '',
  urlMode: UrlMode.auto,
  auth: InstanceAuthApiKey(apiKey: 'secret-key'),
);

Future<void> _loadFonts() async {
  final FontLoader roboto = FontLoader('Roboto');
  for (final String font in ['roboto-regular.ttf', 'roboto-medium.ttf', 'roboto-bold.ttf']) {
    final File f = File('$_fontDir\\$font');
    if (f.existsSync()) {
      roboto.addFont(Future.value(ByteData.view(f.readAsBytesSync().buffer)));
    }
  }
  await roboto.load();

  final File icons = File('$_fontDir\\materialicons-regular.otf');
  if (icons.existsSync()) {
    final FontLoader materialIcons = FontLoader('MaterialIcons');
    materialIcons.addFont(Future.value(ByteData.view(icons.readAsBytesSync().buffer)));
    await materialIcons.load();
  }
}

Future<void> capture(
  WidgetTester tester,
  GlobalKey key,
  String fileName,
) async {
  final RenderRepaintBoundary boundary =
      key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  final Uint8List? pngBytes = await tester.runAsync<Uint8List?>(() async {
    final ui.Image image = await boundary.toImage(pixelRatio: 2.0);
    final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    return byteData?.buffer.asUint8List();
  });
  final File outFile = File('$screenshotDir\\$fileName');
  outFile.writeAsBytesSync(pngBytes!);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await _loadFonts();
  });

  final mockSearches = <SlskdSearch>[
    SlskdSearch(
      id: 'search-1',
      searchText: 'Daft Punk',
      state: 'Completed',
      isComplete: true,
      fileCount: 7,
      responseCount: 2,
      startedAt: DateTime.now().subtract(const Duration(minutes: 2)),
    ),
    SlskdSearch(
      id: 'search-2',
      searchText: 'Radiohead',
      state: 'Completed',
      isComplete: true,
      fileCount: 3,
      responseCount: 1,
      startedAt: DateTime.now().subtract(const Duration(seconds: 40)),
    ),
  ];

  final mockResponses = <SlskdSearchResponse>[
    const SlskdSearchResponse(
      username: 'AudioPhile99',
      fileCount: 4,
      lockedFileCount: 0,
      hasFreeUploadSlot: true,
      queueLength: 0,
      uploadSpeed: 2800000, // 2.8 MB/s
      token: 101,
      files: <SlskdSearchFile>[
        SlskdSearchFile(
          filename: r'Music\Daft Punk\Discovery (2001) [FLAC]\01 - One More Time.flac',
          size: 38500000,
          extension: 'flac',
          bitDepth: 24,
          bitRate: 1411,
          length: 320,
        ),
        SlskdSearchFile(
          filename: r'Music\Daft Punk\Discovery (2001) [FLAC]\02 - Aerodynamic.flac',
          size: 24200000,
          extension: 'flac',
          bitDepth: 24,
          bitRate: 1411,
          length: 207,
        ),
        SlskdSearchFile(
          filename: r'Music\Daft Punk\Discovery (2001) [FLAC]\03 - Digital Love.flac',
          size: 32100000,
          extension: 'flac',
          bitDepth: 24,
          bitRate: 1411,
          length: 298,
        ),
        SlskdSearchFile(
          filename: r'Music\Daft Punk\Discovery (2001) [FLAC]\04 - Harder Better Faster.flac',
          size: 27800000,
          extension: 'flac',
          bitDepth: 24,
          bitRate: 1411,
          length: 224,
        ),
      ],
    ),
    const SlskdSearchResponse(
      username: 'GrooveMaster',
      fileCount: 3,
      lockedFileCount: 0,
      hasFreeUploadSlot: true,
      queueLength: 0,
      uploadSpeed: 1950000, // 1.95 MB/s
      token: 102,
      files: <SlskdSearchFile>[
        SlskdSearchFile(
          filename: r'MP3\Daft Punk\Homework (1997) [320k]\01 Daftendirekt.mp3',
          size: 6800000,
          extension: 'mp3',
          bitRate: 320,
          length: 164,
        ),
        SlskdSearchFile(
          filename: r'MP3\Daft Punk\Homework (1997) [320k]\02 WDPK 83.7 FM.mp3',
          size: 1900000,
          extension: 'mp3',
          bitRate: 320,
          length: 28,
        ),
        SlskdSearchFile(
          filename: r'MP3\Daft Punk\Homework (1997) [320k]\03 Revolution 909.mp3',
          size: 13200000,
          extension: 'mp3',
          bitRate: 320,
          length: 326,
        ),
      ],
    ),
  ];

  group('SlskdSearchTab Widget & Screenshot Tests', () {
    testWidgets('renders search tab, toggles views, tests filter bottom sheet, and captures screenshots',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1179, 2556);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final GlobalKey repaintKey = GlobalKey();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            slskdActiveTabProvider(testInstance).overrideWith((ref) => 1),
            slskdSearchesProvider(testInstance).overrideWith((ref) => mockSearches),
            slskdSearchResponsesProvider((testInstance, 'search-1')).overrideWith(
              (ref) => mockResponses,
            ),
          ],
          child: MaterialApp(
            theme: ThemeData(
              useMaterial3: true,
              colorSchemeSeed: const Color(0xFF007ACC),
              brightness: Brightness.dark,
              fontFamily: 'Roboto',
            ),
            builder: (BuildContext context, Widget? child) {
              return RepaintBoundary(
                key: repaintKey,
                child: child!,
              );
            },
            home: const SlskdHome(instance: testInstance),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify AppBar: SearchBar and View Toggle button
      expect(find.byType(SearchBar), findsOneWidget);
      expect(find.byIcon(Icons.format_list_bulleted_rounded), findsOneWidget);

      // Verify Active Searches Ribbon
      expect(find.text('Daft Punk (7)'), findsOneWidget);
      expect(find.text('Radiohead (3)'), findsOneWidget);

      // Verify Grouped Album cards
      expect(find.text('Discovery (2001) [FLAC]'), findsOneWidget);
      expect(find.text('Homework (1997) [320k]'), findsOneWidget);
      expect(find.text('AudioPhile99'), findsOneWidget);
      expect(find.text('GrooveMaster'), findsOneWidget);
      expect(find.text('Download Album'), findsNWidgets(2));
      expect(find.text('01 - One More Time.flac'), findsOneWidget);

      // 1. Capture Screenshot: Album Grouped View (Default)
      await capture(tester, repaintKey, 'slskd_search_grouped.png');

      // 2. Toggle to Flat View
      await tester.tap(find.byIcon(Icons.format_list_bulleted_rounded));
      await tester.pumpAndSettle();

      // Verify Flat View icon switched
      expect(find.byIcon(Icons.album_outlined), findsOneWidget);
      expect(find.text('01 - One More Time.flac'), findsOneWidget);
      expect(find.text('01 Daftendirekt.mp3'), findsOneWidget);

      // Capture Screenshot: Flat List View
      await capture(tester, repaintKey, 'slskd_search_flat.png');

      // Toggle back to Grouped View
      await tester.tap(find.byIcon(Icons.album_outlined));
      await tester.pumpAndSettle();

      // 3. Open Sort & Filter Modal Bottom Sheet via Mini FAB
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      expect(find.text('Sort & Filter Results'), findsOneWidget);
      expect(find.text('Audio Format'), findsOneWidget);
      expect(find.text('FLAC Only'), findsOneWidget);
      expect(find.text('MP3 Only'), findsOneWidget);
      expect(find.text('Free Slot Only (Instant)'), findsOneWidget);
      expect(find.text('Fastest Speed'), findsOneWidget);

      // Capture Screenshot: Modal Bottom Sheet
      await capture(tester, repaintKey, 'slskd_search_filter_sheet.png');

      // 4. Select FLAC Only filter and tap Done
      await tester.tap(find.text('FLAC Only'));
      await tester.pump();
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();

      // Verify filtered state: Discovery is present, Homework (MP3) is filtered out
      expect(find.text('Discovery (2001) [FLAC]'), findsOneWidget);
      expect(find.text('Homework (1997) [320k]'), findsNothing);
      expect(find.text('Filters active:'), findsOneWidget);

      // Capture Screenshot: Filtered State
      await capture(tester, repaintKey, 'slskd_search_filtered.png');

      // 5. Reset filters via active filters pill
      await tester.tap(find.text('Reset'));
      await tester.pumpAndSettle();
      expect(find.text('Homework (1997) [320k]'), findsOneWidget);
    });

    testWidgets('renders initial empty search view when no searches exist',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1179, 2556);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final GlobalKey repaintKey = GlobalKey();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            slskdActiveTabProvider(testInstance).overrideWith((ref) => 1),
            slskdSearchesProvider(testInstance).overrideWith((ref) => const []),
          ],
          child: MaterialApp(
            theme: ThemeData(
              useMaterial3: true,
              colorSchemeSeed: const Color(0xFF007ACC),
              brightness: Brightness.dark,
              fontFamily: 'Roboto',
            ),
            builder: (BuildContext context, Widget? child) {
              return RepaintBoundary(
                key: repaintKey,
                child: child!,
              );
            },
            home: const SlskdHome(instance: testInstance),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('P2P Music Search'), findsOneWidget);
      expect(
        find.text('Search artists, albums, or tracks across millions of Soulseek peer shares.'),
        findsOneWidget,
      );

      // Capture Screenshot: Initial Empty State
      await capture(tester, repaintKey, 'slskd_search_empty.png');
    });
  });
}
