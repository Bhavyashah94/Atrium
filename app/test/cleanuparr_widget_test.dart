import 'package:atrium/src/dashboard/widgets/cleanuparr_widget.dart';
import 'package:core_models/core_models.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:service_cleanuparr/service_cleanuparr.dart';

void main() {
  const Instance testInstance = Instance(
    id: 'cleanuparr-1',
    name: 'Home Cleanuparr',
    kind: ServiceKind.cleanuparr,
    localUrl: 'http://cleanuparr.local:11011',
    externalUrl: '',
    urlMode: UrlMode.auto,
    auth: InstanceAuth.apiKey(apiKey: 'secret'),
  );

  const CleanuparrStats sampleStats = CleanuparrStats(
    hours: 168,
    totalEvents: 40,
    malwareBlocked: 5,
    activeStrikes: 2,
    totalCleaned: 14,
    seekerTriggers: 6,
  );

  const List<CleanuparrStrikeItem> sampleStrikes = <CleanuparrStrikeItem>[
    CleanuparrStrikeItem(
      id: 'hash1',
      title: 'Stalled.Torrent.Release.2026',
      hash: '3f2e1d0c9b8a',
      strikeCount: 2,
      isMarkedForRemoval: true,
    ),
  ];

  testWidgets('renders compact Cleanuparr widget with stats pills and top active strike',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          cleanuparrStatsProvider(testInstance).overrideWith(
            (ref) async => sampleStats,
          ),
          cleanuparrStrikesProvider(testInstance).overrideWith(
            (ref) async => sampleStrikes,
          ),
        ],
        child: MaterialApp(
          theme: AtriumTheme.light(null),
          home: const Scaffold(
            body: DashboardCleanuparrWidget(
              instances: <Instance>[testInstance],
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    // Verify title and label
    expect(find.text('Cleanuparr'), findsOneWidget);

    // Verify stat pills
    expect(find.text('5 blocked'), findsOneWidget);
    expect(find.text('2 strikes'), findsOneWidget);
    expect(find.text('14 cleaned'), findsOneWidget);

    // Verify top strike preview
    expect(find.text('Stalled.Torrent.Release.2026'), findsOneWidget);
    expect(find.text('2 strikes • removal'), findsOneWidget);
  });

  testWidgets('renders clean state when active strikes list is empty',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          cleanuparrStatsProvider(testInstance).overrideWith(
            (ref) async => const CleanuparrStats(
              hours: 168,
              malwareBlocked: 2,
              activeStrikes: 0,
              totalCleaned: 5,
            ),
          ),
          cleanuparrStrikesProvider(testInstance).overrideWith(
            (ref) async => const <CleanuparrStrikeItem>[],
          ),
        ],
        child: MaterialApp(
          theme: AtriumTheme.light(null),
          home: const Scaffold(
            body: DashboardCleanuparrWidget(
              instances: <Instance>[testInstance],
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('Cleanuparr'), findsOneWidget);
    expect(find.text('All queues clean'), findsOneWidget);
  });
}
