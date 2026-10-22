import 'package:core_models/core_models.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:service_seerr/service_seerr.dart';

const Instance _instance = Instance(
  id: 'test-seerr',
  name: 'Test Seerr',
  kind: ServiceKind.seerr,
  localUrl: 'http://seerr.test',
  externalUrl: '',
  urlMode: UrlMode.auto,
  auth: InstanceAuth.apiKey(apiKey: 'k'),
);

/// Two pending (the default status), one approved, one declined and one failed, in that order.
const List<SeerrRequest> _requests = <SeerrRequest>[
  SeerrRequest(id: 1),
  SeerrRequest(id: 2, status: 2),
  SeerrRequest(id: 3),
  SeerrRequest(id: 4, status: 3),
  SeerrRequest(id: 5, status: 4),
];

void main() {
  group('the filter', () {
    List<int> ids(SeerrRequestFilter filter) => <int>[
          for (final SeerrRequest r in filter.apply(_requests)) r.id,
        ];

    test('all keeps every request, failed ones included', () {
      expect(ids(SeerrRequestFilter.all), <int>[1, 2, 3, 4, 5]);
    });

    test('each status chip keeps its own status, in order', () {
      expect(ids(SeerrRequestFilter.pending), <int>[1, 3]);
      expect(ids(SeerrRequestFilter.approved), <int>[2]);
      expect(ids(SeerrRequestFilter.declined), <int>[4]);
    });
  });

  group('the Requests tab', () {
    Future<void> pump(
      WidgetTester tester,
      List<SeerrRequest> requests, {
      void Function()? onRead,
    }) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            seerrRequestsProvider.overrideWith((Ref ref, Instance i) async {
              onRead?.call();
              return requests;
            }),
          ],
          child: const MaterialApp(
            home: Scaffold(body: SeerrHome(instance: _instance)),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    Future<void> pick(WidgetTester tester, String label) async {
      await tester.tap(find.widgetWithText(FilterChip, label));
      await tester.pumpAndSettle();
    }

    testWidgets('opens on All, with a chip for each status',
        (WidgetTester tester) async {
      await pump(tester, _requests);

      for (final String label in <String>[
        'All',
        'Pending',
        'Approved',
        'Declined',
      ]) {
        expect(find.widgetWithText(FilterChip, label), findsOneWidget);
      }
      final FilterChip all =
          tester.widget(find.widgetWithText(FilterChip, 'All'));
      expect(all.selected, isTrue);
      expect(find.textContaining('Status: '), findsNWidgets(5));
    });

    testWidgets('a chip shows only its status, without reading again',
        (WidgetTester tester) async {
      int reads = 0;
      await pump(tester, _requests, onRead: () => reads++);

      await pick(tester, 'Pending');
      expect(find.text('Status: Pending'), findsNWidgets(2));
      expect(find.textContaining('Status: '), findsNWidgets(2));

      await pick(tester, 'Approved');
      expect(find.text('Status: Approved'), findsOneWidget);
      expect(find.textContaining('Status: '), findsOneWidget);

      await pick(tester, 'Declined');
      expect(find.text('Status: Declined'), findsOneWidget);
      expect(find.textContaining('Status: '), findsOneWidget);

      await pick(tester, 'All');
      expect(find.textContaining('Status: '), findsNWidgets(5));
      expect(reads, 1);
    });

    testWidgets('an empty chip says what it has none of, chips still there',
        (WidgetTester tester) async {
      await pump(tester, const <SeerrRequest>[SeerrRequest(id: 2, status: 2)]);

      await pick(tester, 'Pending');

      expect(find.text('No pending requests'), findsOneWidget);
      expect(find.text('Nothing is waiting for approval.'), findsOneWidget);
      expect(find.widgetWithText(FilterChip, 'All'), findsOneWidget);
    });

    testWidgets('no requests at all says so under All',
        (WidgetTester tester) async {
      await pump(tester, const <SeerrRequest>[]);

      expect(find.byType(EmptyView), findsOneWidget);
      expect(find.text('No requests'), findsOneWidget);
    });
  });
}
