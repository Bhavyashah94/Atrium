import 'dart:io';
import 'dart:ui' as ui;

import 'package:core_models/core_models.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:service_aria2/service_aria2.dart';

const String _outDir =
    r'C:\Users\bhavy\.gemini\antigravity\brain\e17bb2e9-c1e2-4c39-adb3-fda7246421d6\aria2_shots';
const String _fontDir =
    r'C:\Users\bhavy\development\flutter\bin\cache\artifacts\material_fonts';

const Key _shotKey = ValueKey<String>('shot');

Instance _instance() => const Instance(
  id: 'aria2-home',
  name: 'Seedbox',
  kind: ServiceKind.aria2,
  localUrl: 'http://127.0.0.1:6800',
  externalUrl: '',
  urlMode: UrlMode.forceLocal,
  auth: InstanceAuth.apiKey(apiKey: 'atrium-live-secret'),
);

Future<void> _loadFonts() async {
  final Map<String, List<String>> families = <String, List<String>>{
    'Roboto': <String>[
      'roboto-regular.ttf',
      'roboto-medium.ttf',
      'roboto-bold.ttf',
    ],
    'MaterialIcons': <String>['materialicons-regular.otf'],
  };
  for (final MapEntry<String, List<String>> entry in families.entries) {
    final FontLoader loader = FontLoader(entry.key);
    for (final String file in entry.value) {
      final File source = File('$_fontDir\\$file');
      if (source.existsSync()) {
        loader.addFont(
          Future<ByteData>.value(source.readAsBytesSync().buffer.asByteData()),
        );
      }
    }
    await loader.load();
  }
}

Future<void> _capture(WidgetTester tester, String name) async {
  final Finder finder = find.byKey(_shotKey);
  expect(finder, findsOneWidget, reason: 'shot target $name not found');
  final RenderRepaintBoundary boundary =
      tester.renderObject(finder) as RenderRepaintBoundary;
  await tester.runAsync(() async {
    final ui.Image image = await boundary.toImage(pixelRatio: 2.0);
    final ByteData? byteData = await image.toByteData(
      format: ui.ImageByteFormat.png,
    );
    if (byteData == null) return;
    final File file = File('$_outDir\\$name.png');
    file.parent.createSync(recursive: true);
    file.writeAsBytesSync(byteData.buffer.asUint8List());
  });
}

const Aria2Download mockActiveIso = Aria2Download(
  gid: 'live-gid-iso',
  status: 'active',
  totalLength: 2684354560,
  completedLength: 1879048192,
  downloadSpeed: 12582912,
  uploadSpeed: 524288,
  connections: 16,
  dir: '/downloads',
  files: <Aria2File>[
    Aria2File(
      index: 1,
      path: '/downloads/ubuntu-24.04-desktop-amd64.iso',
      length: 2684354560,
      completedLength: 1879048192,
    ),
  ],
);

const Aria2Download mockTorrent = Aria2Download(
  gid: 'live-gid-torrent',
  status: 'active',
  torrentName: 'Big Buck Bunny (4K UltraHD Remux)',
  totalLength: 5242880000,
  completedLength: 3670016000,
  downloadSpeed: 5242880,
  uploadSpeed: 1048576,
  uploadLength: 2097152000,
  numSeeders: 48,
  connections: 32,
  dir: '/downloads/torrents',
  files: <Aria2File>[
    Aria2File(
      index: 1,
      path: 'Big Buck Bunny (4K)/bunny_4k.mkv',
      length: 5042880000,
      completedLength: 3670016000,
      uris: <Aria2Uri>[
        Aria2Uri(
          uri: 'https://archive.org/download/bbb/bunny_4k.mkv',
          status: 'used',
        ),
        Aria2Uri(uri: 'https://mirror.nl/bbb/bunny_4k.mkv', status: 'waiting'),
      ],
    ),
    Aria2File(
      index: 2,
      path: 'Big Buck Bunny (4K)/subtitles_en.srt',
      length: 150000,
      completedLength: 150000,
    ),
    Aria2File(
      index: 3,
      path: 'Big Buck Bunny (4K)/sample_preview.mkv',
      length: 199850000,
      selected: false,
    ),
  ],
);

const Aria2Download mockQueued = Aria2Download(
  gid: 'live-gid-queued',
  status: 'waiting',
  totalLength: 1073741824,
  dir: '/downloads',
  files: <Aria2File>[
    Aria2File(
      index: 1,
      path: '/downloads/debian-12.5.0-amd64-netinst.iso',
      length: 1073741824,
    ),
  ],
);

const Aria2Download mockCompleted = Aria2Download(
  gid: 'live-gid-complete',
  status: 'complete',
  totalLength: 943718400,
  completedLength: 943718400,
  uploadLength: 1887436800,
  dir: '/downloads',
  files: <Aria2File>[
    Aria2File(
      index: 1,
      path: '/downloads/archlinux-2026.iso',
      length: 943718400,
      completedLength: 943718400,
    ),
  ],
);

const Aria2Snapshot snapshot = Aria2Snapshot(
  stat: Aria2GlobalStat(
    downloadSpeed: 17825792,
    uploadSpeed: 1572864,
    numActive: 2,
    numWaiting: 1,
    numStopped: 1,
  ),
  version: Aria2Version(
    version: '1.37.0',
    enabledFeatures: <String>[
      'Async DNS',
      'BitTorrent',
      'Firefox3 Cookie',
      'GZip',
      'HTTPS',
      'Message Digest',
      'Metalink',
      'XML-RPC',
    ],
  ),
  active: <Aria2Download>[mockActiveIso, mockTorrent],
  waiting: <Aria2Download>[mockQueued],
  stopped: <Aria2Download>[mockCompleted],
);

final Map<String, String> globalOptions = <String, String>{
  'max-overall-download-limit': '20971520',
  'max-overall-upload-limit': '5242880',
  'max-download-limit': '0',
  'max-upload-limit': '0',
  'max-concurrent-downloads': '8',
  'max-connection-per-server': '16',
  'split': '8',
  'min-split-size': '20M',
  'connect-timeout': '60',
  'dir': 'C:\\Users\\bhavy\\Downloads',
  'disk-cache': '32M',
  'file-allocation': 'falloc',
  'auto-file-renaming': 'true',
  'conditional-get': 'true',
  'seed-ratio': '2.0',
  'enable-dht': 'true',
  'bt-max-peers': '60',
  'listen-port': '6881-6999',
};

const List<Aria2Peer> peers = <Aria2Peer>[
  Aria2Peer(
    peerId: 'qBittorrent/4.6.5',
    ip: '192.168.1.105',
    port: 51413,
    downloadSpeed: 3145728,
    uploadSpeed: 524288,
    seeder: true,
  ),
  Aria2Peer(
    peerId: 'Transmission/4.0.4',
    ip: '84.112.55.19',
    port: 6881,
    downloadSpeed: 1572864,
    uploadSpeed: 262144,
  ),
  Aria2Peer(
    peerId: 'Deluge/2.1.1',
    ip: '142.250.180.3',
    port: 52199,
    downloadSpeed: 524288,
    uploadSpeed: 262144,
    seeder: true,
  ),
];

Future<void> _pumpScreen(
  WidgetTester tester,
  Widget child,
  ThemeData theme, {
  List<Override> overrides = const <Override>[],
}) async {
  tester.view.physicalSize = const Size(1080, 2340);
  tester.view.devicePixelRatio = 2.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final Instance inst = _instance();

  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        aria2SnapshotProvider(inst).overrideWith((ref) => snapshot),
        aria2GlobalOptionsProvider(inst).overrideWith((ref) => globalOptions),
        aria2PeersProvider((
          inst,
          mockTorrent.gid,
        )).overrideWith((ref) => peers),
        aria2DownloadProvider((
          inst,
          mockTorrent.gid,
        )).overrideWith((ref) => mockTorrent),
        aria2DownloadOptionProvider((inst, mockTorrent.gid)).overrideWith(
          (ref) => <String, String>{
            'max-download-limit': '10485760',
            'max-upload-limit': '1048576',
          },
        ),
        ...overrides,
      ],
      child: MaterialApp(
        theme: theme,
        debugShowCheckedModeBanner: false,
        builder: (BuildContext context, Widget? rootChild) =>
            RepaintBoundary(key: _shotKey, child: rootChild!),
        home: child,
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}

void main() {
  setUpAll(() async {
    await _loadFonts();
  });

  // 1. Unified Downloads Hub (Light Mode)
  testWidgets('01 Hub Light', (WidgetTester tester) async {
    await _pumpScreen(
      tester,
      Aria2Home(instance: _instance()),
      AtriumTheme.light(null),
    );
    await _capture(tester, '01_hub_all_light');
  });

  // 2. Unified Downloads Hub (Dark Mode)
  testWidgets('02 Hub Dark', (WidgetTester tester) async {
    await _pumpScreen(
      tester,
      Aria2Home(instance: _instance()),
      AtriumTheme.dark(null),
    );
    await _capture(tester, '02_hub_all_dark');
  });

  // 3. Multi-Select Mode (batch actions bar)
  testWidgets('03 Hub Multi-Select', (WidgetTester tester) async {
    final Instance inst = _instance();
    await _pumpScreen(
      tester,
      Aria2Home(instance: inst),
      AtriumTheme.light(null),
      overrides: [
        aria2SelectionProvider(
          inst,
        ).overrideWith((ref) => <String>{mockActiveIso.gid, mockTorrent.gid}),
      ],
    );
    await _capture(tester, '03_hub_multiselect');
  });

  // 4. Search Filter
  testWidgets('04 Hub Search', (WidgetTester tester) async {
    final Instance inst = _instance();
    await _pumpScreen(
      tester,
      Aria2Home(instance: inst),
      AtriumTheme.light(null),
      overrides: [
        aria2SearchQueryProvider(inst).overrideWith((ref) => 'ubuntu'),
      ],
    );
    await tester.tap(find.byIcon(Icons.search));
    await tester.pump(const Duration(milliseconds: 50));
    await _capture(tester, '04_hub_search');
  });

  // 5. Sort Menu
  testWidgets('05 Hub Sort Menu', (WidgetTester tester) async {
    await _pumpScreen(
      tester,
      Aria2Home(instance: _instance()),
      AtriumTheme.light(null),
    );
    await tester.tap(find.byIcon(Icons.sort));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));
    await _capture(tester, '05_hub_sort_menu');
  });

  // 6. Settings Tab: Bandwidth Limits & Concurrency
  testWidgets('06 Settings Bandwidth & Concurrency', (
    WidgetTester tester,
  ) async {
    final Instance inst = _instance();
    await _pumpScreen(
      tester,
      Aria2Home(instance: inst),
      AtriumTheme.light(null),
      overrides: [aria2ActiveTabProvider(inst).overrideWith((ref) => 1)],
    );
    await _capture(tester, '06_settings_bandwidth');
  });

  // 7. Settings Tab: Storage & BitTorrent (Scrolled)
  testWidgets('07 Settings Storage & BitTorrent', (WidgetTester tester) async {
    final Instance inst = _instance();
    await _pumpScreen(
      tester,
      Aria2Home(instance: inst),
      AtriumTheme.light(null),
      overrides: [aria2ActiveTabProvider(inst).overrideWith((ref) => 1)],
    );
    await tester.drag(find.byType(ListView).first, const Offset(0, -600));
    await tester.pump(const Duration(milliseconds: 100));
    await _capture(tester, '07_settings_storage_bittorrent');
  });

  // 8. Settings Edit Dialog
  testWidgets('08 Settings Edit Dialog', (WidgetTester tester) async {
    final Instance inst = _instance();
    await _pumpScreen(
      tester,
      Aria2Home(instance: inst),
      AtriumTheme.light(null),
      overrides: [aria2ActiveTabProvider(inst).overrideWith((ref) => 1)],
    );
    await tester.tap(find.text('Max concurrent downloads'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));
    await _capture(tester, '08_settings_edit_dialog');
  });

  // 9. System Tab: Daemon Status & Maintenance
  testWidgets('09 System Tab', (WidgetTester tester) async {
    final Instance inst = _instance();
    await _pumpScreen(
      tester,
      Aria2Home(instance: inst),
      AtriumTheme.light(null),
      overrides: [aria2ActiveTabProvider(inst).overrideWith((ref) => 2)],
    );
    await _capture(tester, '09_system_tab');
  });

  // 10. System Tab: Shutdown Dialog
  testWidgets('10 System Shutdown Dialog', (WidgetTester tester) async {
    final Instance inst = _instance();
    await _pumpScreen(
      tester,
      Aria2Home(instance: inst),
      AtriumTheme.light(null),
      overrides: [aria2ActiveTabProvider(inst).overrideWith((ref) => 2)],
    );
    await tester.drag(find.byType(ListView).first, const Offset(0, -600));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.widgetWithText(FilledButton, 'Shutdown'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));
    await _capture(tester, '10_system_shutdown_dialog');
  });

  // 11. Download Detail Screen (Header, Files, Checkboxes)
  testWidgets('11 Download Detail Screen', (WidgetTester tester) async {
    final Instance inst = _instance();
    await _pumpScreen(
      tester,
      Aria2DownloadDetailScreen(
        instance: inst,
        gid: mockTorrent.gid,
        initialName: mockTorrent.displayName,
      ),
      AtriumTheme.light(null),
    );
    await _capture(tester, '11_detail_screen');
  });

  // 12. Per-Download Speed Limits Dialog
  testWidgets('12 Download Detail Speed Dialog', (WidgetTester tester) async {
    final Instance inst = _instance();
    await _pumpScreen(
      tester,
      Aria2DownloadDetailScreen(
        instance: inst,
        gid: mockTorrent.gid,
        initialName: mockTorrent.displayName,
      ),
      AtriumTheme.light(null),
    );
    await tester.tap(find.text('Speed limit'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));
    await _capture(tester, '12_detail_speed_dialog');
  });

  // 13. Download Detail Screen: Connected Peers (Scrolled)
  testWidgets('13 Download Detail Peers', (WidgetTester tester) async {
    final Instance inst = _instance();
    await _pumpScreen(
      tester,
      Aria2DownloadDetailScreen(
        instance: inst,
        gid: mockTorrent.gid,
        initialName: mockTorrent.displayName,
      ),
      AtriumTheme.light(null),
    );
    await tester.drag(find.byType(ListView).first, const Offset(0, -600));
    await tester.pump(const Duration(milliseconds: 100));
    await _capture(tester, '13_detail_peers');
  });

  // 14. Download Detail Screen: Add Mirror Dialog
  testWidgets('14 Download Detail Add Mirror Dialog', (
    WidgetTester tester,
  ) async {
    final Instance inst = _instance();
    await _pumpScreen(
      tester,
      Aria2DownloadDetailScreen(
        instance: inst,
        gid: mockTorrent.gid,
        initialName: mockTorrent.displayName,
      ),
      AtriumTheme.light(null),
    );
    await tester.drag(find.byType(ListView).first, const Offset(0, -1000));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.text('Add Mirror'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));
    await _capture(tester, '14_detail_add_mirror_dialog');
  });

  // 15. Add Download Sheet
  testWidgets('15 Add Download Sheet', (WidgetTester tester) async {
    await _pumpScreen(
      tester,
      Aria2Home(instance: _instance()),
      AtriumTheme.light(null),
    );
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
    await _capture(tester, '15_add_sheet_initial');
  });

  // 16. Add Download Sheet Advanced Options
  testWidgets('16 Add Download Sheet Advanced Options', (
    WidgetTester tester,
  ) async {
    await _pumpScreen(
      tester,
      Aria2Home(instance: _instance()),
      AtriumTheme.light(null),
    );
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
    await tester.tap(find.text('Advanced Options'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
    await _capture(tester, '16_add_sheet_advanced');
  });
}
