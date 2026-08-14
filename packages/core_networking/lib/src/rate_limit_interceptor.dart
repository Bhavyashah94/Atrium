import 'dart:async';
import 'dart:io' show HttpDate;
import 'dart:math' as math;

import 'package:dio/dio.dart';

/// Retries a request once the server says it is being rate limited.
///
/// A 429 means the request was refused, not performed, so replaying it is safe
/// even for a POST: nothing happened the first time. That is the opposite of a
/// 5xx, where the server may well have acted before failing to answer, which is
/// why this only ever retries 429.
///
/// Self-hosted services differ wildly here. Tracearr allows 240 requests a
/// minute by default but lets an admin drop that to one, so a client cannot
/// assume a ceiling and throttle to it. Reacting to the server's own
/// `Retry-After` is the only approach that stays correct at every setting.
class RateLimitInterceptor extends Interceptor {
  RateLimitInterceptor(
    this._dio, {
    this.maxRetries = 2,
    this.fallbackDelay = const Duration(seconds: 2),
    this.maxDelay = const Duration(seconds: 30),
  });

  /// The client the retry is replayed through.
  ///
  /// It has to be the same one: a fresh [Dio] would lose the resolved base URL,
  /// the merged headers, the self-signed adapter and the auth interceptor, so
  /// the retry would fail for reasons unrelated to rate limiting.
  final Dio _dio;

  /// How many times a single request may be replayed before giving up.
  final int maxRetries;

  /// Used when the response carries no usable `Retry-After`. Doubles per
  /// attempt.
  final Duration fallbackDelay;

  /// Ceiling on the wait, however long the server asks for.
  ///
  /// A service under pressure can answer `Retry-After: 3600`. Honouring that
  /// literally would hang a screen for an hour, so past this point failing and
  /// letting the user retry is the better outcome.
  final Duration maxDelay;

  /// Key under which the attempt count rides along on the request.
  ///
  /// The replay goes back through the same Dio, and therefore through this
  /// interceptor again, so the count has to travel with the request or a
  /// server answering 429 forever would loop forever.
  static const String attemptKey = 'core_networking.rate_limit.attempt';

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode != 429) {
      handler.next(err);
      return;
    }

    final RequestOptions options = err.requestOptions;
    final int attempt = (options.extra[attemptKey] as int?) ?? 0;
    if (attempt >= maxRetries) {
      handler.next(err);
      return;
    }

    final Duration? asked =
        parseRetryAfter(err.response?.headers.value('retry-after'));
    if (asked != null && asked > maxDelay) {
      // Longer than we are willing to hold a screen for; surface it instead.
      handler.next(err);
      return;
    }

    final Duration backoff = fallbackDelay * math.pow(2, attempt).toInt();
    final Duration wait = asked ?? backoff;
    await Future<void>.delayed(wait > maxDelay ? maxDelay : wait);

    options.extra[attemptKey] = attempt + 1;

    try {
      handler.resolve(await _dio.fetch<dynamic>(options));
    } on DioException catch (e) {
      handler.next(e);
    }
  }

  /// Parses a `Retry-After`, which is either a delay in seconds or an HTTP
  /// date. Returns null when absent or unparseable, so the caller falls back.
  static Duration? parseRetryAfter(String? value) {
    final String? raw = value?.trim();
    if (raw == null || raw.isEmpty) return null;

    final int? seconds = int.tryParse(raw);
    if (seconds != null) {
      return seconds <= 0 ? Duration.zero : Duration(seconds: seconds);
    }

    try {
      final Duration delta = HttpDate.parse(raw).difference(DateTime.now());
      return delta.isNegative ? Duration.zero : delta;
    } catch (_) {
      return null;
    }
  }
}
