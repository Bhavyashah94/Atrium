import 'package:core_models/core_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:service_tracearr/src/models/tracearr_models.dart';
import 'package:service_tracearr/src/providers/tracearr_providers.dart';
import 'package:service_tracearr/src/tracearr_home.dart';

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

  Widget createTestWidget({
    List<TracearrStream> streams = const [],
    List<TracearrViolationItem> violations = const [],
  }) {
    return ProviderScope(
      overrides: [
        tracearrStreamsProvider(testInstance)
            .overrideWith((ref) async => streams),
        tracearrViolationsProvider(testInstance)
            .overrideWith((ref) async => violations),
        tracearrUsersProvider(testInstance).overrideWith((ref) async => []),
        tracearrLibrariesProvider(testInstance).overrideWith((ref) async => []),
      ],
      child: const MaterialApp(
        home: TracearrHomeScreen(
          instance: testInstance,
        ),
      ),
    );
  }

  group('TracearrHomeScreen Navigation Foundation', () {
    testWidgets('renders all 5 destinations in NavigationBar', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Overview'), findsWidgets);
      expect(find.text('Activity'), findsWidgets);
      expect(find.text('Media'), findsWidgets);
      expect(find.text('People'), findsWidgets);
      expect(find.text('Security'), findsWidgets);

      // Initially on Overview destination
      expect(
        find.text('LIVE OPERATIONS'),
        findsOneWidget,
      );
    });

    testWidgets('switches destinations correctly on tap', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Tap Activity
      await tester.tap(find.text('Activity'));
      await tester.pumpAndSettle();

      expect(
        find.text('LIVE STREAMS'),
        findsOneWidget,
      );

      // Tap Media
      await tester.tap(find.text('Media'));
      await tester.pumpAndSettle();

      expect(
        find.text('RECENTLY ADDED'),
        findsOneWidget,
      );

      // Tap People
      await tester.tap(find.text('People'));
      await tester.pumpAndSettle();

      expect(
        find.text('FLEET USERS (0)'),
        findsOneWidget,
      );

      // Tap Security
      await tester.tap(find.text('Security'));
      await tester.pumpAndSettle();

      expect(
        find.text('All Clear'),
        findsOneWidget,
      );
    });

    testWidgets('renders badge counts when active streams and violations exist',
        (tester) async {
      const activeStream = TracearrStream(
        id: 's1',
        serverId: 'srv1',
        serverName: 'Plex',
        serverType: 'plex',
        mediaTitle: 'Test Movie',
        userUsername: 'Bhavya',
      );

      const violation = TracearrViolationItem(
        id: 'v1',
        serverId: 'srv1',
        serverName: 'Plex',
        severity: 'critical',
        rule: 'Rate Limit',
        username: 'Bhavya',
      );

      await tester.pumpWidget(
        createTestWidget(
          streams: [activeStream],
          violations: [violation],
        ),
      );
      await tester.pumpAndSettle();

      // Badge widgets rendered in the NavigationBar for Activity and Security destinations
      expect(find.byType(Badge), findsNWidgets(2));
    });
  });
}
