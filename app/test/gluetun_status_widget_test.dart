import 'package:atrium/src/dashboard/dashboard_widget_kind.dart';
import 'package:atrium/src/dashboard/widgets/gluetun_status_widget.dart';
import 'package:core_models/core_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:service_gluetun/service_gluetun.dart';

/// The Gluetun card takes every colour from the theme.
///
/// Its badge used the fixed brand blue while the other dashboard cards use a
/// theme role, so it was the one card that ignored the user's palette.
void main() {
  const Instance instance = Instance(
    id: 'gluetun',
    name: 'Gluetun',
    kind: ServiceKind.gluetun,
    localUrl: 'http://gluetun.test',
    externalUrl: '',
    urlMode: UrlMode.auto,
    auth: InstanceAuth.apiKey(apiKey: 'k'),
  );

  testWidgets('the badge and status chip follow the theme',
      (WidgetTester tester) async {
    // A purple seed, so a fixed blue or green cannot match by accident.
    final ColorScheme scheme =
        ColorScheme.fromSeed(seedColor: const Color(0xFF6750A4));
    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          gluetunVpnStatusProvider(instance).overrideWith(
            (Ref ref) async => const GluetunVpnStatus(status: 'running'),
          ),
          gluetunPublicIpProvider(instance)
              .overrideWith((Ref ref) async => null),
        ],
        child: MaterialApp(
          theme: ThemeData(colorScheme: scheme),
          home: const Scaffold(
            body: DashboardGluetunStatusWidget(instances: <Instance>[instance]),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    final Icon badge = tester.widget<Icon>(
      find.byIcon(DashboardWidgetKind.gluetunStatus.icon),
    );
    expect(badge.color, scheme.primary);
    expect(
      tester.widget<Text>(find.text('RUNNING')).style?.color,
      scheme.primary,
    );
  });
}
