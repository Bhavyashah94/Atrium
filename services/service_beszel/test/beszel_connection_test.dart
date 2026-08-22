import 'package:core_models/core_models.dart';
import 'package:core_networking/core_networking.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:service_beszel/service_beszel.dart';

import 'support/fake_http_client_adapter.dart';

({Dio dio, FakeHttpClientAdapter adapter}) _harness(
  ({int status, Object? data}) Function(RequestOptions) factory,
) {
  final Dio dio = Dio(BaseOptions(baseUrl: 'http://beszel.local:8090/'));
  final FakeHttpClientAdapter adapter = FakeHttpClientAdapter(factory);
  dio.httpClientAdapter = adapter;
  return (dio: dio, adapter: adapter);
}

const InstanceAuth _creds = InstanceAuth.userPass(
  username: 'me@example.com',
  password: 'hunter2',
);

void main() {
  test('accepts valid credentials and posts the PocketBase login', () async {
    final ({Dio dio, FakeHttpClientAdapter adapter}) h = _harness(
      (RequestOptions o) => (
        status: 200,
        data: <String, dynamic>{
          'token': 'abc.def.ghi',
          'record': <String, dynamic>{'id': '1'},
        },
      ),
    );

    await verifyBeszelConnection(h.dio, _creds);

    final RequestOptions req = h.adapter.requests.single;
    expect(req.method, 'POST');
    expect(req.path, '/api/collections/users/auth-with-password');
    expect((req.data as Map<String, dynamic>)['identity'], 'me@example.com');
    expect((req.data as Map<String, dynamic>)['password'], 'hunter2');
  });

  test('rejects a wrong password (PocketBase answers 400) as auth failure',
      () async {
    final ({Dio dio, FakeHttpClientAdapter adapter}) h = _harness(
      (RequestOptions o) => (
        status: 400,
        data: <String, dynamic>{'code': 400, 'message': 'Failed to authenticate.'},
      ),
    );

    await expectLater(
      verifyBeszelConnection(h.dio, _creds),
      throwsA(isA<NetworkAuthException>()),
    );
  });

  test('treats a 401 as an auth failure', () async {
    final ({Dio dio, FakeHttpClientAdapter adapter}) h =
        _harness((RequestOptions o) => (status: 401, data: <String, dynamic>{}));

    await expectLater(
      verifyBeszelConnection(h.dio, _creds),
      throwsA(isA<NetworkAuthException>()),
    );
  });

  test('a 200 without a token is an auth failure, not success', () async {
    final ({Dio dio, FakeHttpClientAdapter adapter}) h = _harness(
      (RequestOptions o) =>
          (status: 200, data: <String, dynamic>{'record': <String, dynamic>{}}),
    );

    await expectLater(
      verifyBeszelConnection(h.dio, _creds),
      throwsA(isA<NetworkAuthException>()),
    );
  });

  test('a server error surfaces as a non-auth NetworkException', () async {
    final ({Dio dio, FakeHttpClientAdapter adapter}) h =
        _harness((RequestOptions o) => (status: 500, data: <String, dynamic>{}));

    await expectLater(
      verifyBeszelConnection(h.dio, _creds),
      throwsA(
        allOf(isA<NetworkException>(), isNot(isA<NetworkAuthException>())),
      ),
    );
  });

  test('without user/pass, an auth-gated 403 is still a credential failure',
      () async {
    final ({Dio dio, FakeHttpClientAdapter adapter}) h =
        _harness((RequestOptions o) => (status: 403, data: <String, dynamic>{}));

    await expectLater(
      verifyBeszelConnection(h.dio, const InstanceAuth.apiKey(apiKey: 'x')),
      throwsA(isA<NetworkAuthException>()),
    );
  });
}
