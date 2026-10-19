import 'dart:async';

import 'package:core_models/core_models.dart';
import 'package:core_networking/core_networking.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:service_adguard_home/service_adguard_home.dart';

import 'support/adguard_home_filters_fixtures.dart';
import 'support/adguard_home_test_instance.dart';
import 'support/fake_adguard_home.dart';

void main() {
  const Instance instance = adguardHomeTestInstance;
  late FakeAdguardHome server;
  late ProviderContainer container;

  setUp(() {
    server = FakeAdguardHome()
      ..on('GET', 'control/filtering/status', filterStatusJson());
    container = ProviderContainer(
      overrides: <Override>[
        instanceDioProvider(instance)
            .overrideWith((Ref ref) async => dioFor(server)),
      ],
    );
    addTearDown(container.dispose);
  });

  Future<Object?> settle<T>(ProviderListenable<AsyncValue<T>> provider) {
    final Completer<Object?> done = Completer<Object?>();
    container.listen<AsyncValue<T>>(
      provider,
      (AsyncValue<T>? _, AsyncValue<T> next) {
        if (done.isCompleted) return;
        if (next.hasError) {
          done.complete(next.error);
        } else if (!next.isLoading) {
          done.complete(next.value);
        }
      },
      fireImmediately: true,
    );
    return done.future;
  }

  Future<void> until(bool Function() condition) async {
    for (int turn = 0; turn < 500 && !condition(); turn++) {
      await pumpEventQueue(times: 1);
    }
    expect(condition(), isTrue, reason: 'the awaited state never came');
  }

  AdguardHomeActions actions() =>
      container.read(adguardHomeActionsProvider(instance));

  List<String> sent() => <String>[
        for (final RequestOptions request in server.requests)
          '${request.method} ${request.path}',
      ];

  Object? body(String method, String path) => server.single(method, path).data;

  final AdguardHomeFiltering filtering =
      AdguardHomeFiltering.fromJson(filterStatusJson());

  group('reads', () {
    test('the rewrites, their switch and the services, each once', () async {
      expect(
        await settle(adguardHomeRewritesProvider(instance)),
        hasLength(2),
      );
      expect(await settle(adguardHomeRewritesEnabledProvider(instance)), true);
      expect(
        await settle(adguardHomeGlobalServicesProvider(instance)),
        isA<AdguardHomeGlobalServices>(),
      );

      expect(sent(), <String>[
        'GET control/rewrite/list',
        'GET control/rewrite/settings',
        'GET control/blocked_services/get',
      ]);
    });

    test('that fail are not asked for again by themselves', () async {
      server.fail(
        'GET',
        'control/rewrite/list',
        500,
        '<html>no</html>',
        contentType: 'text/html',
      );

      await settle(adguardHomeRewritesProvider(instance));
      await Future<void>.delayed(const Duration(milliseconds: 700));

      expect(sent(), <String>['GET control/rewrite/list']);
    });

    test('are read again when the sign-in is tried again', () async {
      server.refusing = true;
      await settle(adguardHomeRewritesProvider(instance));
      server.refusing = false;

      actions().retrySignIn();
      await until(
        () => container.read(adguardHomeRewritesProvider(instance)).hasValue,
      );

      expect(server.to('GET', 'control/rewrite/list'), hasLength(2));
    });
  });

  group('filter lists', () {
    final AdguardHomeFilterList off = filtering.blocklists.last;

    test('a switch keeps the name and address of the list', () async {
      await actions().setListEnabled(off, allowlist: false, enabled: true);

      expect(body('POST', 'control/filtering/set_url'), <String, dynamic>{
        'url': off.url,
        'whitelist': false,
        'data': <String, dynamic>{
          'name': off.name,
          'url': off.url,
          'enabled': true,
        },
      });
    });

    test('a new list is added, and a changed one keeps its switch', () async {
      await actions().saveList(
        allowlist: true,
        name: 'Mine',
        url: 'https://lists.example/mine.txt',
      );
      await actions().saveList(
        original: off,
        allowlist: false,
        name: 'Renamed',
        url: 'https://lists.example/moved.txt',
      );

      expect(body('POST', 'control/filtering/add_url'), <String, dynamic>{
        'name': 'Mine',
        'url': 'https://lists.example/mine.txt',
        'whitelist': true,
      });
      expect(body('POST', 'control/filtering/set_url'), <String, dynamic>{
        'url': off.url,
        'whitelist': false,
        'data': <String, dynamic>{
          'name': 'Renamed',
          'url': 'https://lists.example/moved.txt',
          'enabled': false,
        },
      });
    });

    test('the update interval keeps filtering as the server has it', () async {
      // Switched off elsewhere since the screen was drawn.
      server.on(
        'GET',
        'control/filtering/status',
        filterStatusJson()..['enabled'] = false,
      );

      await actions().setUpdateInterval(168);

      expect(sent(), <String>[
        'GET control/filtering/status',
        'POST control/filtering/config',
      ]);
      expect(body('POST', 'control/filtering/config'), <String, dynamic>{
        'enabled': false,
        'interval': 168,
      });
    });

    test('a change reads the lists again', () async {
      await settle(adguardHomeFilteringProvider(instance));
      final int before = server.to('GET', 'control/filtering/status').length;

      await actions().removeList(off, allowlist: false);

      await until(
        () =>
            server.to('GET', 'control/filtering/status').length == before + 1,
      );
      expect(body('POST', 'control/filtering/remove_url'), <String, dynamic>{
        'url': off.url,
        'whitelist': false,
      });
    });

    test('checking for updates says how many changed', () async {
      server.on(
        'POST',
        'control/filtering/refresh',
        <String, dynamic>{'updated': 1},
      );

      expect(await actions().refreshLists(allowlist: false), 1);
    });
  });

  group('custom rules', () {
    test('are written whole when nobody changed them meanwhile', () async {
      await actions().saveRules(
        before: filtering.userRules,
        after: <String>[...filtering.userRules, '||new.example^'],
      );

      expect(sent(), <String>[
        'GET control/filtering/status',
        'POST control/filtering/set_rules',
      ]);
      expect(
        (body('POST', 'control/filtering/set_rules')!
            as Map<String, dynamic>)['rules'],
        <String>[...filtering.userRules, '||new.example^'],
      );
    });

    test('changed on the server meanwhile are not overwritten unasked',
        () async {
      final List<String> elsewhere = <String>[
        ...filtering.userRules,
        '||blocked-from-the-log.example^\$important',
      ];
      server.on(
        'GET',
        'control/filtering/status',
        filterStatusJson()..['user_rules'] = elsewhere,
      );

      await expectLater(
        actions().saveRules(
          before: filtering.userRules,
          after: <String>['||mine.example^'],
        ),
        throwsA(
          isA<AdguardHomeRulesChanged>().having(
            (AdguardHomeRulesChanged e) => e.rules,
            'rules',
            elsewhere,
          ),
        ),
      );
      expect(server.to('POST', 'control/filtering/set_rules'), isEmpty);

      // Unless the user says to.
      await actions().saveRules(
        before: filtering.userRules,
        after: <String>['||mine.example^'],
        overwrite: true,
      );
      expect(
        (body('POST', 'control/filtering/set_rules')!
            as Map<String, dynamic>)['rules'],
        <String>['||mine.example^'],
      );
    });

    test('follow a renamed client, and say how many did', () async {
      server.on(
        'GET',
        'control/filtering/status',
        filterStatusJson()
          ..['user_rules'] = <String>[
            "||tiktok.com^\$client='Kids tablet'",
            '||plain.example^',
          ],
      );

      expect(
        await actions().renameClientInRules('Kids tablet', 'Tablet'),
        1,
      );
      expect(
        (body('POST', 'control/filtering/set_rules')!
            as Map<String, dynamic>)['rules'],
        <String>["||tiktok.com^\$client='Tablet'", '||plain.example^'],
      );
    });

    test('naming no such client are not written at all', () async {
      expect(await actions().renameClientInRules('Nobody', 'Someone'), 0);
      expect(server.to('POST', 'control/filtering/set_rules'), isEmpty);
    });
  });

  group('the blocked services of the server', () {
    test('changing the services keeps the schedule as the server has it',
        () async {
      await actions().setGlobalServiceIds(<String>['youtube', 'tiktok']);

      expect(sent(), <String>[
        'GET control/blocked_services/get',
        'PUT control/blocked_services/update',
      ]);
      final Map<String, dynamic> sentBody =
          body('PUT', 'control/blocked_services/update')!
              as Map<String, dynamic>;
      expect(sentBody['ids'], <String>['youtube', 'tiktok']);
      expect(
        sentBody['schedule'],
        AdguardHomeSchedule.fromJson(globalServicesJson()['schedule']).toJson(),
      );
    });

    test('changing the schedule keeps the services as the server has them',
        () async {
      // Another service was blocked elsewhere meanwhile.
      server.on(
        'GET',
        'control/blocked_services/get',
        globalServicesJson()..['ids'] = <String>['tiktok', 'netflix'],
      );

      await actions().setGlobalSchedule(
        const AdguardHomeSchedule(timeZone: 'UTC'),
      );

      final Map<String, dynamic> sentBody =
          body('PUT', 'control/blocked_services/update')!
              as Map<String, dynamic>;
      expect(sentBody['ids'], <String>['tiktok', 'netflix']);
      expect(sentBody['schedule'], <String, dynamic>{'time_zone': 'UTC'});
    });
  });

  group('rewrites', () {
    const AdguardHomeRewrite rewrite = AdguardHomeRewrite(
      domain: '*.lan.example',
      answer: 'nas.home.example',
      enabled: false,
    );

    test('a new one is added, a changed one is updated by what it was',
        () async {
      await actions().saveRewrite(rewrite: rewrite);
      await actions().saveRewrite(
        original: rewrite,
        rewrite: rewrite.copyWith(answer: '10.0.0.9'),
      );

      expect(body('POST', 'control/rewrite/add'), rewrite.toJson());
      expect(body('PUT', 'control/rewrite/update'), <String, dynamic>{
        'target': rewrite.toJson(),
        'update': rewrite.copyWith(answer: '10.0.0.9').toJson(),
      });
    });

    test('a switch changes only whether it is on', () async {
      await actions().setRewriteEnabled(rewrite, enabled: true);

      expect(body('PUT', 'control/rewrite/update'), <String, dynamic>{
        'target': rewrite.toJson(),
        'update': rewrite.copyWith(enabled: true).toJson(),
      });
    });

    test('delete, and the overall switch, read the list again', () async {
      await settle(adguardHomeRewritesProvider(instance));
      await settle(adguardHomeRewritesEnabledProvider(instance));

      await actions().deleteRewrite(rewrite);
      await actions().setRewritesEnabled(enabled: false);

      await until(() => server.to('GET', 'control/rewrite/list').length == 2);
      await until(
        () => server.to('GET', 'control/rewrite/settings').length == 2,
      );
    });
  });

  test('checks a host', () async {
    final AdguardHomeHostCheck check =
        await actions().checkHost('wikipedia.org');

    expect(check.result, AdguardHomeQueryResult.allowed);
  });

  test('once the sign-in is refused, no write sends anything', () async {
    server.refusing = true;
    await settle(adguardHomeStatusProvider(instance));
    expect(server.requests, hasLength(1));

    final List<Future<Object?>> writes = <Future<Object?>>[
      actions().setUpdateInterval(1),
      actions().saveRules(before: const <String>[], after: const <String>[]),
      actions().setGlobalServiceIds(const <String>[]),
      actions().setRewritesEnabled(enabled: true),
      actions().checkHost('a.example'),
      actions().refreshLists(allowlist: true),
    ];
    for (final Future<Object?> write in writes) {
      await expectLater(write, throwsA(isA<AdguardHomeSignInRefused>()));
    }

    expect(server.requests, hasLength(1));
  });

  test('says rules changed elsewhere in a sentence', () {
    expect(
      describeAdguardHomeError(const AdguardHomeRulesChanged(<String>[])),
      'The custom rules were changed on the server since you opened them.',
    );
  });
}
