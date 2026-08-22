import 'package:core_networking/core_networking.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

/// Answers a fixed number of 429s before succeeding, counting attempts.
class _RateLimitedAdapter implements HttpClientAdapter {
  _RateLimitedAdapter({required this.failures, this.retryAfter});

  final int failures;
  final String? retryAfter;
  int attempts = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    attempts++;
    if (attempts <= failures) {
      return ResponseBody.fromString(
        'slow down',
        429,
        headers: <String, List<String>>{
          if (retryAfter != null) 'retry-after': <String>[retryAfter!],
        },
      );
    }
    return ResponseBody.fromString('ok', 200);
  }

  @override
  void close({bool force = false}) {}
}

Dio _dioWith(_RateLimitedAdapter adapter, {int maxRetries = 2}) {
  final Dio dio = Dio(BaseOptions(baseUrl: 'http://x/'));
  dio.httpClientAdapter = adapter;
  dio.interceptors.add(
    RateLimitInterceptor(
      dio,
      maxRetries: maxRetries,
      fallbackDelay: const Duration(milliseconds: 1),
      maxDelay: const Duration(milliseconds: 50),
    ),
  );
  return dio;
}

void main() {
  group('RateLimitInterceptor', () {
    test('retries a 429 and returns the eventual success', () async {
      final adapter = _RateLimitedAdapter(failures: 1);
      final Response<dynamic> res = await _dioWith(adapter).get<dynamic>('/a');

      expect(res.statusCode, 200);
      expect(adapter.attempts, 2, reason: 'one refusal then one replay');
    });

    test('gives up after maxRetries and surfaces the 429', () async {
      final adapter = _RateLimitedAdapter(failures: 99);

      await expectLater(
        _dioWith(adapter).get<dynamic>('/a'),
        throwsA(
          isA<DioException>().having(
            (DioException e) => e.response?.statusCode,
            'statusCode',
            429,
          ),
        ),
      );
      // Original attempt plus two replays, then it stops rather than looping.
      expect(adapter.attempts, 3);
    });

    test('does not retry when Retry-After exceeds maxDelay', () async {
      final adapter = _RateLimitedAdapter(failures: 99, retryAfter: '3600');

      await expectLater(
        _dioWith(adapter).get<dynamic>('/a'),
        throwsA(isA<DioException>()),
      );
      expect(adapter.attempts, 1, reason: 'an hour is not worth waiting for');
    });

    test('leaves non-429 errors alone', () async {
      final Dio dio = Dio(BaseOptions(baseUrl: 'http://x/'));
      var attempts = 0;
      dio.httpClientAdapter = _CallbackAdapter(() {
        attempts++;
        return ResponseBody.fromString('boom', 500);
      });
      dio.interceptors.add(RateLimitInterceptor(dio));

      await expectLater(
        dio.get<dynamic>('/a'),
        throwsA(isA<DioException>()),
      );
      expect(attempts, 1, reason: 'a 500 may already have been acted on');
    });
  });

  group('parseRetryAfter', () {
    test('reads a delay in seconds', () {
      expect(
        RateLimitInterceptor.parseRetryAfter('12'),
        const Duration(seconds: 12),
      );
    });

    test('reads an HTTP date', () {
      final DateTime soon = DateTime.now().toUtc().add(const Duration(minutes: 1));
      final Duration? parsed = RateLimitInterceptor.parseRetryAfter(
        _httpDate(soon),
      );
      expect(parsed, isNotNull);
      expect(parsed!.inSeconds, closeTo(60, 5));
    });

    test('clamps a past date to zero rather than going negative', () {
      final DateTime past = DateTime.now().toUtc().subtract(const Duration(hours: 1));
      expect(RateLimitInterceptor.parseRetryAfter(_httpDate(past)), Duration.zero);
    });

    test('returns null for absent or unparseable values', () {
      expect(RateLimitInterceptor.parseRetryAfter(null), isNull);
      expect(RateLimitInterceptor.parseRetryAfter(''), isNull);
      expect(RateLimitInterceptor.parseRetryAfter('later please'), isNull);
    });
  });
}

class _CallbackAdapter implements HttpClientAdapter {
  _CallbackAdapter(this.onFetch);
  final ResponseBody Function() onFetch;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async =>
      onFetch();

  @override
  void close({bool force = false}) {}
}

const List<String> _days = <String>[
  'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun',
];
const List<String> _months = <String>[
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

String _two(int v) => v.toString().padLeft(2, '0');

String _httpDate(DateTime utc) =>
    '${_days[utc.weekday - 1]}, ${_two(utc.day)} ${_months[utc.month - 1]} '
    '${utc.year} ${_two(utc.hour)}:${_two(utc.minute)}:${_two(utc.second)} GMT';
