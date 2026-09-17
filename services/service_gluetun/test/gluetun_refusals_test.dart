import 'dart:typed_data';

import 'package:core_models/core_models.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:service_gluetun/service_gluetun.dart';

/// A change Gluetun refuses has to be reported as refused.
///
/// Current Gluetun refuses any route its auth config does not grant, which is
/// the easiest thing to get wrong when setting it up. Verified against a live
/// Gluetun with the PUT routes left out of the role: Update Servers and Stop
/// DNS both got a 401 and the app showed a success message for each, and
/// Stop VPN showed a raw DioException that never mentioned the route.
void main() {
  group('GluetunApi changes', () {
    GluetunApi apiAnswering(int status, String body) => GluetunApi(
          Dio(BaseOptions(baseUrl: 'http://gluetun.test/'))
            ..httpClientAdapter = _Answer(status: status, body: body),
        );

    test('a refused change throws instead of passing for success', () async {
      final GluetunApi api = apiAnswering(401, 'Unauthorized');

      await expectLater(
        api.setVpnStatus(run: false),
        throwsA(isA<DioException>()),
      );
      await expectLater(
        api.setDnsStatus(run: false),
        throwsA(isA<DioException>()),
      );
      await expectLater(
        api.setUpdaterStatus(run: true),
        throwsA(isA<DioException>()),
      );
    });

    test('a successful change reports the state that was asked for', () async {
      // Gluetun answers a change with {"outcome": ...}, not the status object
      // its GET returns, so parsing the reply as a status read nothing and
      // fell back to "unknown" or "idle".
      final GluetunApi api = apiAnswering(200, '{"outcome":"already running"}');

      expect((await api.setVpnStatus(run: true)).status, 'running');
      expect((await api.setDnsStatus(run: false)).status, 'stopped');
      expect((await api.setUpdaterStatus(run: true)).status, 'running');
    });
  });

  group('GluetunHome when a change is refused', () {
    const Instance instance = Instance(
      id: 'gluetun',
      name: 'Gluetun',
      kind: ServiceKind.gluetun,
      localUrl: 'http://gluetun.test',
      externalUrl: '',
      urlMode: UrlMode.auto,
      auth: InstanceAuth.apiKey(apiKey: 'k'),
    );

    Future<void> pumpRefusingHome(WidgetTester tester) async {
      final Dio dio = Dio(BaseOptions(baseUrl: 'http://gluetun.test/'))
        ..httpClientAdapter = _Answer(status: 401, body: 'Unauthorized');
      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            gluetunApiProvider(instance)
                .overrideWith((Ref ref) async => GluetunApi(dio)),
            gluetunVpnStatusProvider(instance).overrideWith(
              (Ref ref) async => const GluetunVpnStatus(status: 'running'),
            ),
            gluetunPublicIpProvider(instance)
                .overrideWith((Ref ref) async => null),
            gluetunDnsStatusProvider(instance).overrideWith(
              (Ref ref) async => const GluetunDnsStatus(status: 'running'),
            ),
            gluetunUpdaterStatusProvider(instance).overrideWith(
              (Ref ref) async => const GluetunUpdaterStatus(status: 'stopped'),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(body: GluetunHome(instance: instance)),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();
    }

    Future<void> settle(WidgetTester tester) =>
        tester.pump(const Duration(milliseconds: 500));

    testWidgets('Update Servers says it was refused, not triggered',
        (WidgetTester tester) async {
      await pumpRefusingHome(tester);

      await tester.tap(find.text('Update Servers'));
      await settle(tester);

      expect(find.textContaining('Triggered server list'), findsNothing);
      expect(find.textContaining('Gluetun refused it'), findsOneWidget);
      expect(find.textContaining('PUT /v1/updater/status'), findsOneWidget);
    });

    testWidgets('Stop DNS says it was refused, not stopping',
        (WidgetTester tester) async {
      await pumpRefusingHome(tester);

      await tester.tap(find.text('Stop'));
      await settle(tester);
      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('Stop DNS'),
        ),
      );
      await settle(tester);

      expect(find.text('Stopping DNS...'), findsNothing);
      expect(find.textContaining('PUT /v1/dns/status'), findsOneWidget);
    });

    testWidgets('Stop VPN names the route instead of dumping the exception',
        (WidgetTester tester) async {
      await pumpRefusingHome(tester);

      await tester.tap(find.text('Stop VPN'));
      await settle(tester);
      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('Stop VPN'),
        ),
      );
      await settle(tester);

      expect(find.textContaining('DioException'), findsNothing);
      expect(find.textContaining('PUT /v1/vpn/status'), findsOneWidget);
    });
  });
}

/// Answers every request with one status and body.
///
/// The content type follows the body, as Gluetun's does: a JSON object for a
/// successful change, and `text/plain` for its 401, whose body is the bare
/// word Unauthorized. Labelling that as JSON makes Dio fail to decode it and
/// lose the status code, which is not what happens against the real thing.
class _Answer implements HttpClientAdapter {
  _Answer({required this.status, required this.body});

  final int status;
  final String body;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async =>
      ResponseBody.fromString(
        body,
        status,
        headers: <String, List<String>>{
          Headers.contentTypeHeader: <String>[
            if (body.startsWith('{'))
              Headers.jsonContentType
            else
              'text/plain; charset=utf-8',
          ],
        },
      );

  @override
  void close({bool force = false}) {}
}
