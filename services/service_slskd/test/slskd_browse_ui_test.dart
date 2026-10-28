import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:core_models/core_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:service_slskd/service_slskd.dart';

final String? _fontDir = () {
  final String? flutterRoot = Platform.environment['FLUTTER_ROOT'];
  if (flutterRoot == null || flutterRoot.isEmpty) {
    return null;
  }
  return '$flutterRoot/bin/cache/artifacts/material_fonts';
}();

final String screenshotDir = Platform.environment['SLSKD_SHOTS_DIR'] ??
    'build/screenshots/service_slskd';

const Instance testInstance = Instance(
  id: 'test-slskd-browse',
  name: 'Soulseek Daemon',
  kind: ServiceKind.slskd,
  localUrl: 'http://127.0.0.1:5030/',
  externalUrl: '',
  urlMode: UrlMode.auto,
  auth: InstanceAuthApiKey(apiKey: 'secret-key'),
);

Future<void> _loadFonts() async {
  if (_fontDir == null) {
    return;
  }
  final Directory dir = Directory(_fontDir!);
  if (!dir.existsSync()) {
    return;
  }

  File? findFontFile(String filename) {
    final File direct = File('$_fontDir/$filename');
    if (direct.existsSync()) {
      return direct;
    }
    final String lower = filename.toLowerCase();
    try {
      for (final FileSystemEntity entity in dir.listSync()) {
        if (entity is File &&
            entity.path.split(RegExp(r'[/\\]')).last.toLowerCase() == lower) {
          return entity;
        }
      }
    } catch (_) {}
    return null;
  }

  final FontLoader roboto = FontLoader('Roboto');
  for (final String font in <String>[
    'Roboto-Regular.ttf',
    'Roboto-Medium.ttf',
    'Roboto-Bold.ttf',
  ]) {
    final File? f = findFontFile(font);
    if (f != null && f.existsSync()) {
      roboto.addFont(Future.value(ByteData.view(f.readAsBytesSync().buffer)));
    }
  }
  await roboto.load();

  final File? icons = findFontFile('MaterialIcons-Regular.otf');
  if (icons != null && icons.existsSync()) {
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
  final Directory dir = Directory(screenshotDir);
  if (!dir.existsSync()) {
    dir.createSync(recursive: true);
  }
  final File outFile = File('$screenshotDir/$fileName');
  outFile.writeAsBytesSync(pngBytes!);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await _loadFonts();
  });

  final mockDirectories = <SlskdDirectory>[
    const SlskdDirectory(
      name: r'Music\Electronic\Daft Punk\Discovery (2001) [FLAC]',
      files: <SlskdSearchFile>[
        SlskdSearchFile(
          filename: r'Music\Electronic\Daft Punk\Discovery (2001) [FLAC]\01 - One More Time.flac',
          size: 38500000,
          extension: 'flac',
          bitDepth: 24,
          bitRate: 1411,
          length: 320,
        ),
        SlskdSearchFile(
          filename: r'Music\Electronic\Daft Punk\Discovery (2001) [FLAC]\02 - Aerodynamic.flac',
          size: 24200000,
          extension: 'flac',
          bitDepth: 24,
          bitRate: 1411,
          length: 207,
        ),
        SlskdSearchFile(
          filename: r'Music\Electronic\Daft Punk\Discovery (2001) [FLAC]\03 - Digital Love.flac',
          size: 32100000,
          extension: 'flac',
          bitDepth: 24,
          bitRate: 1411,
          length: 298,
        ),
        SlskdSearchFile(
          filename: r'Music\Electronic\Daft Punk\Discovery (2001) [FLAC]\04 - Harder Better Faster.flac',
          size: 27800000,
          extension: 'flac',
          bitDepth: 24,
          bitRate: 1411,
          length: 224,
        ),
      ],
    ),
    const SlskdDirectory(
      name: r'Music\Electronic\Daft Punk\Homework (1997) [320k]',
      files: <SlskdSearchFile>[
        SlskdSearchFile(
          filename: r'Music\Electronic\Daft Punk\Homework (1997) [320k]\01 Daftendirekt.mp3',
          size: 6800000,
          extension: 'mp3',
          bitRate: 320,
          length: 164,
        ),
        SlskdSearchFile(
          filename: r'Music\Electronic\Daft Punk\Homework (1997) [320k]\02 WDPK 83.7 FM.mp3',
          size: 1900000,
          extension: 'mp3',
          bitRate: 320,
          length: 28,
        ),
      ],
    ),
    const SlskdDirectory(
      name: r'Music\Rock\Radiohead\In Rainbows',
      files: <SlskdSearchFile>[
        SlskdSearchFile(
          filename: r'Music\Rock\Radiohead\In Rainbows\01 15 Step.flac',
          size: 28400000,
          extension: 'flac',
          bitDepth: 24,
          bitRate: 1411,
          length: 238,
        ),
      ],
    ),
    const SlskdDirectory(
      name: r'Music\VIP Locked Archive',
      files: <SlskdSearchFile>[
        SlskdSearchFile(
          filename: r'Music\VIP Locked Archive\Exclusive_Master.flac',
          size: 55000000,
          extension: 'flac',
          bitDepth: 24,
          bitRate: 1411,
          length: 310,
        ),
      ],
      isLocked: true,
    ),
  ];

  const mockUserInfo = SlskdUserInfo(
    description:
        'Audiophile and electronic music archivist. Sharing lossless vinyl rips, Japanese CD editions, and 24-bit studio masters. Please limit queued folders to 2 at a time.',
    hasFreeUploadSlot: true,
    uploadSlots: 5,
  );

  const mockUserStatus = SlskdUserStatus(
    isPrivileged: true,
    presence: 'Online',
  );

  group('SlskdBrowseTab Widget & Screenshot Tests', () {
    testWidgets('renders initial peer lookup and navigates user shares hierarchy',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1179, 2556);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final GlobalKey repaintKey = GlobalKey();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            slskdActiveTabProvider(testInstance).overrideWith((ref) => 2),
            slskdUserDirectoriesProvider((testInstance, 'AudioPhile99')).overrideWith(
              (ref) => mockDirectories,
            ),
            slskdUserInfoProvider((testInstance, 'AudioPhile99')).overrideWith(
              (ref) => mockUserInfo,
            ),
            slskdUserStatusProvider((testInstance, 'AudioPhile99')).overrideWith(
              (ref) => mockUserStatus,
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

      // 1. Initial Empty Peer Lookup View
      expect(find.text('Peer Library Explorer'), findsOneWidget);
      expect(find.text('Browse Peer Shares'), findsOneWidget);
      expect(find.text('AudioPhile99'), findsOneWidget);
      expect(find.text('GrooveMaster'), findsOneWidget);

      await capture(tester, repaintKey, 'slskd_browse_empty.png');

      // 2. Tap on suggested peer "AudioPhile99"
      await tester.tap(find.text('AudioPhile99'));
      await tester.pumpAndSettle();

      // Verify Peer Card & Root shares
      expect(find.text('AudioPhile99'), findsWidgets);
      expect(find.text('Free Slot'), findsOneWidget);
      expect(find.text('SUPPORTER'), findsOneWidget);
      expect(find.text('Root'), findsOneWidget);
      expect(find.text('Music'), findsOneWidget);

      await capture(tester, repaintKey, 'slskd_browse_root.png');

      // 3. Drill down: Music -> Electronic -> Daft Punk -> Discovery (2001) [FLAC]
      await tester.tap(find.text('Music'));
      await tester.pumpAndSettle();

      expect(find.text('Electronic'), findsOneWidget);
      expect(find.text('Rock'), findsOneWidget);
      expect(find.text('VIP Locked Archive'), findsOneWidget);
      expect(find.text('LOCKED'), findsOneWidget);

      await capture(tester, repaintKey, 'slskd_browse_locked.png');

      await tester.tap(find.text('Electronic'));
      await tester.pumpAndSettle();

      expect(find.text('Daft Punk'), findsOneWidget);

      await tester.tap(find.text('Daft Punk'));
      await tester.pumpAndSettle();

      expect(find.text('Discovery (2001) [FLAC]'), findsOneWidget);
      expect(find.text('Homework (1997) [320k]'), findsOneWidget);

      await tester.tap(find.text('Discovery (2001) [FLAC]'));
      await tester.pumpAndSettle();

      // Inside Discovery album folder:
      expect(find.text('01 - One More Time.flac'), findsOneWidget);
      expect(find.text('02 - Aerodynamic.flac'), findsOneWidget);
      expect(find.text('03 - Digital Love.flac'), findsOneWidget);
      expect(find.text('04 - Harder Better Faster.flac'), findsOneWidget);
      expect(find.text('Download Folder'), findsOneWidget);

      await capture(tester, repaintKey, 'slskd_browse_folder.png');

      // 4. Open User Profile & Bio Modal Sheet
      await tester.tap(find.byIcon(Icons.info_outline_rounded));
      await tester.pumpAndSettle();

      expect(find.text('User Bio'), findsOneWidget);
      expect(find.text('Supporter'), findsOneWidget);
      expect(find.text('Free Upload Slot'), findsOneWidget);
      expect(find.text('Slots: 5'), findsOneWidget);
      expect(
        find.textContaining('Audiophile and electronic music archivist'),
        findsOneWidget,
      );

      await capture(tester, repaintKey, 'slskd_browse_bio_sheet.png');

      // Close Bio Sheet
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();

      // 5. Navigate back using breadcrumb: tap "Root" in ribbon
      await tester.tap(find.text('Root'), warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(find.text('Music'), findsOneWidget);
    });

    testWidgets('renders browse status progress bar when loading peer shares',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1179, 2556);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final GlobalKey repaintKey = GlobalKey();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            slskdActiveTabProvider(testInstance).overrideWith((ref) => 2),
            slskdBrowseUsernameProvider(testInstance).overrideWith((ref) => 'SpeedyPeer'),
            slskdUserDirectoriesProvider((testInstance, 'SpeedyPeer')).overrideWith(
              (ref) => Completer<List<SlskdDirectory>>().future,
            ),
            slskdBrowseStatusProvider((testInstance, 'SpeedyPeer')).overrideWith(
              (ref) => 68.0,
            ),
            slskdUserInfoProvider((testInstance, 'SpeedyPeer')).overrideWith(
              (ref) => mockUserInfo,
            ),
            slskdUserStatusProvider((testInstance, 'SpeedyPeer')).overrideWith(
              (ref) => mockUserStatus,
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
      await tester.pump();

      expect(find.text('Retrieving shares (68% complete)...'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);

      await capture(tester, repaintKey, 'slskd_browse_progress.png');
    });

    testWidgets('hardware back button pops breadcrumb folder before unwinding user',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1179, 2556);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            slskdActiveTabProvider(testInstance).overrideWith((ref) => 2),
            slskdBrowseUsernameProvider(testInstance).overrideWith((ref) => 'AudioPhile99'),
            slskdUserDirectoriesProvider((testInstance, 'AudioPhile99')).overrideWith(
              (ref) => mockDirectories,
            ),
            slskdUserInfoProvider((testInstance, 'AudioPhile99')).overrideWith(
              (ref) => mockUserInfo,
            ),
            slskdUserStatusProvider((testInstance, 'AudioPhile99')).overrideWith(
              (ref) => mockUserStatus,
            ),
          ],
          child: MaterialApp(
            theme: ThemeData(
              useMaterial3: true,
              colorSchemeSeed: const Color(0xFF007ACC),
              brightness: Brightness.dark,
              fontFamily: 'Roboto',
            ),
            home: const SlskdHome(instance: testInstance),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap into Music folder
      await tester.tap(find.text('Music'));
      await tester.pumpAndSettle();

      expect(find.text('Electronic'), findsOneWidget);

      // Tap into Electronic folder
      await tester.tap(find.text('Electronic'));
      await tester.pumpAndSettle();

      expect(find.text('Daft Punk'), findsOneWidget);

      // Simulate hardware back press 1: pops 'Electronic' -> now back at 'Music'
      await WidgetsBinding.instance.handlePopRoute();
      await tester.pumpAndSettle();

      expect(find.text('Electronic'), findsOneWidget);
      expect(find.text('Rock'), findsOneWidget);

      // Simulate hardware back press 2: pops 'Music' -> now back at 'Root'
      await WidgetsBinding.instance.handlePopRoute();
      await tester.pumpAndSettle();

      expect(find.text('Music'), findsOneWidget);

      // Simulate hardware back press 3: unwinds peer -> back at initial peer lookup
      await WidgetsBinding.instance.handlePopRoute();
      await tester.pumpAndSettle();

      expect(find.text('Peer Library Explorer'), findsOneWidget);
    });
  });
}
