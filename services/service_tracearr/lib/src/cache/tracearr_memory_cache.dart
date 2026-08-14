import 'dart:collection';

/// A bounded in-memory Least-Recently-Used (LRU) cache with optional
/// Time-To-Live (TTL) expiration per entry.
class TracearrMemoryCache<K, V> {
  TracearrMemoryCache({
    this.maxEntries = 500,
    DateTime Function()? clock,
  })  : assert(maxEntries > 0, 'maxEntries must be greater than 0'),
        _clock = clock ?? DateTime.now;

  /// Maximum number of active entries retained in memory before eviction.
  final int maxEntries;

  final DateTime Function() _clock;
  final LinkedHashMap<K, _CacheEntry<V>> _entries =
      LinkedHashMap<K, _CacheEntry<V>>();

  /// Current number of entries stored in the cache.
  int get length {
    pruneExpired();
    return _entries.length;
  }

  /// Whether the cache contains no unexpired entries.
  bool get isEmpty => length == 0;

  /// Whether the cache contains unexpired entries.
  bool get isNotEmpty => length > 0;

  /// Retrieve a value by [key].
  ///
  /// Returns `null` if the key is not present or if the entry has expired.
  /// Accessing an unexpired entry refreshes its position as most recently used.
  V? get(K key) {
    final entry = _entries.remove(key);
    if (entry == null) return null;

    if (entry.isExpired(_clock())) {
      return null;
    }

    // Re-insert to mark as most recently used
    _entries[key] = entry;
    return entry.value;
  }

  /// Store a [value] for [key] with an optional [ttl].
  ///
  /// If the cache is full, the least recently used entry will be evicted.
  void put(K key, V value, {Duration? ttl}) {
    _entries.remove(key);

    if (_entries.length >= maxEntries) {
      _evictLeastRecentlyUsed();
    }

    final now = _clock();
    final expiresAt = ttl != null ? now.add(ttl) : null;
    _entries[key] = _CacheEntry<V>(value, expiresAt: expiresAt);
  }

  /// Check if an unexpired entry exists for [key].
  bool containsKey(K key) {
    final entry = _entries[key];
    if (entry == null) return false;
    if (entry.isExpired(_clock())) {
      _entries.remove(key);
      return false;
    }
    return true;
  }

  /// Remove an entry by [key]. Returns the removed value or `null`.
  V? remove(K key) {
    final entry = _entries.remove(key);
    if (entry == null || entry.isExpired(_clock())) {
      return null;
    }
    return entry.value;
  }

  /// Sweep all entries and remove any whose TTL has passed.
  int pruneExpired() {
    final now = _clock();
    final expiredKeys = <K>[];
    for (final entry in _entries.entries) {
      if (entry.value.isExpired(now)) {
        expiredKeys.add(entry.key);
      }
    }
    for (final key in expiredKeys) {
      _entries.remove(key);
    }
    return expiredKeys.length;
  }

  /// Clear all entries from the cache.
  void clear() {
    _entries.clear();
  }

  void _evictLeastRecentlyUsed() {
    // First, try pruning an expired entry to free space
    if (pruneExpired() > 0 && _entries.length < maxEntries) {
      return;
    }
    if (_entries.isNotEmpty) {
      _entries.remove(_entries.keys.first);
    }
  }
}

class _CacheEntry<V> {
  const _CacheEntry(this.value, {this.expiresAt});

  final V value;
  final DateTime? expiresAt;

  bool isExpired(DateTime now) {
    return expiresAt != null && now.isAfter(expiresAt!);
  }
}
