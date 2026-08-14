import 'package:flutter_test/flutter_test.dart';
import 'package:service_tracearr/src/cache/tracearr_memory_cache.dart';

void main() {
  group('TracearrMemoryCache', () {
    test('stores and retrieves values correctly', () {
      final cache = TracearrMemoryCache<String, String>(maxEntries: 10);
      cache.put('key1', 'val1');
      cache.put('key2', 'val2');

      expect(cache.get('key1'), equals('val1'));
      expect(cache.get('key2'), equals('val2'));
      expect(cache.get('key3'), isNull);
      expect(cache.length, equals(2));
      expect(cache.containsKey('key1'), isTrue);
      expect(cache.containsKey('key3'), isFalse);
    });

    test('evicts least recently used entry when maxEntries is exceeded', () {
      final cache = TracearrMemoryCache<String, int>(maxEntries: 3);
      cache.put('a', 1);
      cache.put('b', 2);
      cache.put('c', 3);

      expect(cache.length, equals(3));

      // Adding 4th entry should evict 'a' (oldest)
      cache.put('d', 4);
      expect(cache.get('a'), isNull);
      expect(cache.get('b'), equals(2));
      expect(cache.get('c'), equals(3));
      expect(cache.get('d'), equals(4));
    });

    test('accessing an entry refreshes its LRU position', () {
      final cache = TracearrMemoryCache<String, int>(maxEntries: 3);
      cache.put('a', 1);
      cache.put('b', 2);
      cache.put('c', 3);

      // Access 'a', making 'b' the oldest entry
      expect(cache.get('a'), equals(1));

      // Adding 'd' should now evict 'b' instead of 'a'
      cache.put('d', 4);
      expect(cache.get('a'), equals(1));
      expect(cache.get('b'), isNull);
      expect(cache.get('c'), equals(3));
      expect(cache.get('d'), equals(4));
    });

    test('expires entries based on TTL and injected clock', () {
      DateTime currentTime = DateTime(2026, 1, 1, 12);
      final cache = TracearrMemoryCache<String, String>(
        maxEntries: 10,
        clock: () => currentTime,
      );

      cache.put('short', 'expires_soon', ttl: const Duration(seconds: 30));
      cache.put('long', 'expires_later', ttl: const Duration(minutes: 5));
      cache.put('permanent', 'never_expires');

      expect(cache.get('short'), equals('expires_soon'));
      expect(cache.get('long'), equals('expires_later'));
      expect(cache.get('permanent'), equals('never_expires'));

      // Advance clock by 31 seconds
      currentTime = currentTime.add(const Duration(seconds: 31));

      expect(cache.get('short'), isNull);
      expect(cache.containsKey('short'), isFalse);
      expect(cache.get('long'), equals('expires_later'));
      expect(cache.get('permanent'), equals('never_expires'));

      // Advance clock past 5 minutes
      currentTime = currentTime.add(const Duration(minutes: 5));

      expect(cache.get('long'), isNull);
      expect(cache.get('permanent'), equals('never_expires'));
    });

    test('pruneExpired sweeps and evicts all expired entries', () {
      DateTime currentTime = DateTime(2026, 1, 1, 12);
      final cache = TracearrMemoryCache<String, String>(
        maxEntries: 10,
        clock: () => currentTime,
      );

      cache.put('e1', 'v1', ttl: const Duration(seconds: 10));
      cache.put('e2', 'v2', ttl: const Duration(seconds: 20));
      cache.put('e3', 'v3', ttl: const Duration(seconds: 60));

      expect(cache.length, equals(3));

      // Advance by 25 seconds (e1 and e2 should be pruned)
      currentTime = currentTime.add(const Duration(seconds: 25));

      final prunedCount = cache.pruneExpired();
      expect(prunedCount, equals(2));
      expect(cache.length, equals(1));
      expect(cache.get('e3'), equals('v3'));
    });

    test('remove and clear methods work as expected', () {
      final cache = TracearrMemoryCache<String, String>(maxEntries: 5);
      cache.put('k1', 'v1');
      cache.put('k2', 'v2');

      expect(cache.remove('k1'), equals('v1'));
      expect(cache.get('k1'), isNull);
      expect(cache.length, equals(1));

      cache.clear();
      expect(cache.length, equals(0));
      expect(cache.isEmpty, isTrue);
    });
  });
}
