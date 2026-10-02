import 'package:core_networking/core_networking.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:service_navidrome/service_navidrome.dart';

import 'support/fake_navidrome.dart';

void main() {
  late FakeNavidrome fake;

  setUp(() => fake = FakeNavidrome());

  Future<void> open(WidgetTester tester, Widget screen) async {
    tester.view.physicalSize = const Size(411, 890);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        retry: (int _, Object __) => null,
        overrides: <Override>[
          instanceDioProvider(navidromeTestInstance)
              .overrideWith((Ref ref) async => fakeNavidromeDio(fake)),
        ],
        child: MaterialApp(theme: AtriumTheme.light(null), home: screen),
      ),
    );
    for (int i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  group('an album', () {
    // The banner behind the header and the cover beside the title are the
    // same picture, so where one fails to load both do, and a cover with
    // nothing to fall back on is an empty square that still pushes the
    // title aside. Asked of the widgets rather than by failing a fetch,
    // because the image cache needs plugins a test does not have.
    testWidgets('gives every cover something to show if it will not load',
        (WidgetTester tester) async {
      fake.on('getAlbum', albumJson(coverArt: 'al-1_0'));
      await open(
        tester,
        const NavidromeAlbumScreen(
          instance: navidromeTestInstance,
          albumId: 'al-1',
        ),
      );

      expect(find.text('The Dark Side of the Moon'), findsOneWidget);
      final List<AtriumNetworkImage> covers = tester
          .widgetList<AtriumNetworkImage>(find.byType(AtriumNetworkImage))
          .toList();
      // The banner, the cover beside the title, and the one track's own.
      expect(covers, hasLength(3));
      for (final AtriumNetworkImage cover in covers) {
        expect(cover.errorWidget, isNotNull);
      }
    });

    testWidgets('shows its whole title when the title is tapped',
        (WidgetTester tester) async {
      const String title =
          "Now That's What I Call a Ridiculously Long Compilation Title, "
          'Vol. 47 (Deluxe Anniversary Edition)';
      fake.on('getAlbum', albumJson(name: title));
      await open(
        tester,
        const NavidromeAlbumScreen(
          instance: navidromeTestInstance,
          albumId: 'al-1',
        ),
      );

      await tester.tap(find.text(title));
      await tester.tap(find.text(title));
      await tester.pump(const Duration(milliseconds: 500));

      // The title itself and one copy of it in full: not one copy queued
      // per tap.
      expect(find.text(title), findsNWidgets(2));
      expect(find.byType(SnackBar), findsNothing);
    });
  });
}
