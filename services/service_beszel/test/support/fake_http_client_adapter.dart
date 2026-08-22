import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

typedef ResponseFactory =
    ({int status, Object? data}) Function(RequestOptions options);

/// Minimal [HttpClientAdapter] that answers every request with a canned status
/// and JSON body, and records the requests it saw. Lets the Beszel connection
/// check be tested without a live PocketBase server.
class FakeHttpClientAdapter implements HttpClientAdapter {
  FakeHttpClientAdapter(this.responseFactory);

  final ResponseFactory responseFactory;
  final List<RequestOptions> requests = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final ({Object? data, int status}) response = responseFactory(options);
    return ResponseBody.fromString(
      jsonEncode(response.data),
      response.status,
      headers: <String, List<String>>{
        Headers.contentTypeHeader: <String>[Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
