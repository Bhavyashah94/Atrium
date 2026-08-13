import 'package:core_models/core_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:service_tracearr/src/models/tracearr_models.dart';
import 'package:service_tracearr/src/providers/tracearr_providers.dart';
import 'package:service_tracearr/src/security/security_tab.dart';
import 'package:service_tracearr/src/security/widgets/security_incident_card.dart';
import 'package:service_tracearr/src/security/widgets/security_incident_ledger_section.dart';

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

  final testViolations = [
    TracearrViolationItem(
      id: 'viol_1',
      serverId: 'srv_1',
      serverName: 'Plex Cloud',
      severity: 'critical',
      rule: 'ConcurrentStreamLimit',
      username: 'Alex',
      description: 'Account exceeded maximum concurrent stream limit of 2.',
      createdAt: DateTime.now().subtract(const Duration(minutes: 15)),
    ),
    TracearrViolationItem(
      id: 'viol_2',
      serverId: 'srv_1',
      serverName: 'Plex Cloud',
      severity: 'medium',
      rule: 'GeoLocationMismatch',
      username: 'Bhavya',
      description: 'Stream initiated from unauthorized IP region (Germany).',
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    TracearrViolationItem(
      id: 'viol_3',
      serverId: 'srv_2',
      serverName: 'Jellyfin Backup',
      severity: 'low',
      rule: 'BandwidthExceeded',
      username: 'Sam',
      description: 'Bitrate peaked above 40 Mbps threshold.',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      acknowledged: true,
    ),
  ];

  Widget createSecurityTabWidget({
    List<TracearrViolationItem>? violations,
  }) {
    return ProviderScope(
      overrides: [
        tracearrViolationsProvider(testInstance).overrideWith(
          (ref) async => violations ?? testViolations,
        ),
      ],
      child: const MaterialApp(
        home: SecurityTab(
          instance: testInstance,
        ),
      ),
    );
  }

  group('SecurityTab Destination', () {
    testWidgets('renders Sentinel violation incidents and filter chips',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createSecurityTabWidget());
      await tester.pumpAndSettle();

      expect(find.byType(SecurityIncidentLedgerSection), findsOneWidget);
      expect(find.byType(SecurityIncidentCard), findsNWidgets(3));

      // Filter chips
      expect(find.text('All (3)'), findsOneWidget);
      expect(find.text('Unresolved (2)'), findsOneWidget);
      expect(find.text('Critical / High'), findsOneWidget);
      expect(find.text('Resolved'), findsOneWidget);

      // Incident 1
      expect(find.text('CRITICAL'), findsOneWidget);
      expect(find.text('ConcurrentStreamLimit'), findsOneWidget);
      expect(find.text('@Alex'), findsOneWidget);
      expect(find.text('Acknowledge'), findsNWidgets(2)); // 2 unacknowledged

      // Incident 3 (acknowledged)
      expect(find.text('Acknowledged'), findsOneWidget);
    });

    testWidgets('filters incidents by severity and resolution status',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createSecurityTabWidget());
      await tester.pumpAndSettle();

      // Filter: Unresolved
      await tester.tap(find.text('Unresolved (2)'));
      await tester.pumpAndSettle();

      expect(find.byType(SecurityIncidentCard), findsNWidgets(2));
      expect(find.text('ConcurrentStreamLimit'), findsOneWidget);
      expect(find.text('GeoLocationMismatch'), findsOneWidget);
      expect(find.text('BandwidthExceeded'), findsNothing);

      // Filter: Critical / High
      await tester.tap(find.text('Critical / High'));
      await tester.pumpAndSettle();

      expect(find.byType(SecurityIncidentCard), findsOneWidget);
      expect(find.text('ConcurrentStreamLimit'), findsOneWidget);
      expect(find.text('GeoLocationMismatch'), findsNothing);

      // Filter: Resolved
      await tester.tap(find.text('Resolved'));
      await tester.pumpAndSettle();

      expect(find.byType(SecurityIncidentCard), findsOneWidget);
      expect(find.text('BandwidthExceeded'), findsOneWidget);
    });

    testWidgets('acknowledges violation locally with feedback', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createSecurityTabWidget());
      await tester.pumpAndSettle();

      // Acknowledge first unacknowledged violation
      await tester.tap(find.text('Acknowledge').first);
      await tester.pumpAndSettle();

      // Now 2 should show Acknowledged status
      expect(find.text('Acknowledged'), findsNWidgets(2));
      expect(find.text('Unresolved (1)'), findsOneWidget);
    });

    testWidgets('dismisses incident locally and allows undo', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createSecurityTabWidget());
      await tester.pumpAndSettle();

      expect(find.byType(SecurityIncidentCard), findsNWidgets(3));

      // Tap close/dismiss icon on the first card
      await tester.tap(find.byIcon(Icons.close).first);
      await tester.pumpAndSettle();

      // Card count should be reduced to 2
      expect(find.byType(SecurityIncidentCard), findsNWidgets(2));
      expect(find.text('All (2)'), findsOneWidget);

      // Tap Undo in SnackBar
      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();

      // Card count restored to 3
      expect(find.byType(SecurityIncidentCard), findsNWidgets(3));
      expect(find.text('All (3)'), findsOneWidget);
    });

    testWidgets('renders All Clear banner when no violations exist',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createSecurityTabWidget(violations: []));
      await tester.pumpAndSettle();

      expect(find.text('All Clear'), findsOneWidget);
      expect(
        find.text(
          'No security policy violations recorded in the Sentinel audit ledger.',
        ),
        findsOneWidget,
      );
      expect(find.byType(SecurityIncidentCard), findsNothing);
    });
  });
}
