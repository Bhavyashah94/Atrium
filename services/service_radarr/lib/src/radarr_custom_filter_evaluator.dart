import 'models/radarr_custom_filter.dart';
import 'models/radarr_movie.dart';

/// Evaluates whether a [RadarrMovie] satisfies a [RadarrCustomFilter].
bool matchesRadarrCustomFilter(RadarrMovie movie, RadarrCustomFilter filter) {
  final List<dynamic>? rules = filter.filters;
  if (rules == null || rules.isEmpty) return true;

  for (final dynamic raw in rules) {
    if (raw is Map) {
      final String? key = raw['key']?.toString();
      final dynamic filterValue = raw['value'];
      final String type = raw['type']?.toString().toLowerCase() ?? 'equal';
      if (key == null) continue;

      final dynamic itemValue = extractRadarrMovieField(movie, key);
      if (!evaluateCustomFilterRule(itemValue, filterValue, type)) {
        return false;
      }
    }
  }
  return true;
}

/// Extracts a property value from [movie] for the given filter [key].
dynamic extractRadarrMovieField(RadarrMovie movie, String key) {
  switch (key) {
    case 'hasFile':
      return movie.hasFile;
    case 'monitored':
      return movie.monitored;
    case 'status':
      return movie.status;
    case 'title':
      return movie.title;
    case 'sortTitle':
      return movie.sortTitle ?? movie.title;
    case 'year':
      return movie.year;
    case 'genres':
      return movie.genres;
    case 'sizeOnDisk':
      return movie.sizeOnDisk;
    case 'studio':
      return movie.studio;
    case 'path':
      return movie.path;
    case 'certification':
      return movie.certification;
    case 'added':
      return movie.added;
    case 'inCinemas':
      return movie.inCinemas;
    case 'physicalRelease':
      return movie.physicalRelease;
    case 'digitalRelease':
      return movie.digitalRelease;
    case 'releaseDate':
      return movie.releaseDate;
    case 'runtime':
      return movie.runtime;
    case 'tmdbId':
      return movie.tmdbId;
    case 'imdbId':
      return movie.imdbId;
    case 'originalLanguage':
      return movie.originalLanguage?.name;
    case 'collection':
      return movie.collection?.title;
    case 'ratings':
      return movie.ratings?.tmdb?.value ?? movie.ratings?.imdb?.value;
    default:
      try {
        return movie.toJson()[key];
      } catch (_) {
        return null;
      }
  }
}

/// Evaluates a single rule: [itemValue] against [filterValue] with operator [type].
bool evaluateCustomFilterRule(
  dynamic itemValue,
  dynamic filterValue,
  String type,
) {
  switch (type) {
    case 'equal':
      if (filterValue is List) {
        return filterValue.any((dynamic v) => _isEqual(itemValue, v));
      }
      return _isEqual(itemValue, filterValue);

    case 'notequal':
      if (filterValue is List) {
        return filterValue.every((dynamic v) => !_isEqual(itemValue, v));
      }
      return !_isEqual(itemValue, filterValue);

    case 'contains':
      if (filterValue is List) {
        return filterValue.any((dynamic v) => _isContains(itemValue, v));
      }
      return _isContains(itemValue, filterValue);

    case 'notcontains':
      if (filterValue is List) {
        return filterValue.every((dynamic v) => !_isContains(itemValue, v));
      }
      return !_isContains(itemValue, filterValue);

    case 'greaterthan':
      if (filterValue is List) {
        if (filterValue.isEmpty) return false;
        return _compare(itemValue, filterValue.first) > 0;
      }
      return _compare(itemValue, filterValue) > 0;

    case 'greaterthanorequal':
      if (filterValue is List) {
        if (filterValue.isEmpty) return false;
        return _compare(itemValue, filterValue.first) >= 0;
      }
      return _compare(itemValue, filterValue) >= 0;

    case 'lessthan':
      if (filterValue is List) {
        if (filterValue.isEmpty) return false;
        return _compare(itemValue, filterValue.first) < 0;
      }
      return _compare(itemValue, filterValue) < 0;

    case 'lessthanorequal':
      if (filterValue is List) {
        if (filterValue.isEmpty) return false;
        return _compare(itemValue, filterValue.first) <= 0;
      }
      return _compare(itemValue, filterValue) <= 0;

    case 'startswith':
      if (itemValue == null || filterValue == null) return false;
      final target = (filterValue is List && filterValue.isNotEmpty)
          ? filterValue.first
          : filterValue;
      return itemValue.toString().toLowerCase().startsWith(
            target.toString().toLowerCase(),
          );

    case 'notstartswith':
      if (itemValue == null || filterValue == null) return true;
      final target = (filterValue is List && filterValue.isNotEmpty)
          ? filterValue.first
          : filterValue;
      return !itemValue.toString().toLowerCase().startsWith(
            target.toString().toLowerCase(),
          );

    case 'endswith':
      if (itemValue == null || filterValue == null) return false;
      final target = (filterValue is List && filterValue.isNotEmpty)
          ? filterValue.first
          : filterValue;
      return itemValue.toString().toLowerCase().endsWith(
            target.toString().toLowerCase(),
          );

    case 'notendswith':
      if (itemValue == null || filterValue == null) return true;
      final target = (filterValue is List && filterValue.isNotEmpty)
          ? filterValue.first
          : filterValue;
      return !itemValue.toString().toLowerCase().endsWith(
            target.toString().toLowerCase(),
          );

    default:
      if (filterValue is List) {
        return filterValue.any((dynamic v) => _isEqual(itemValue, v));
      }
      return _isEqual(itemValue, filterValue);
  }
}

bool _isEqual(dynamic a, dynamic b) {
  if (a == null && b == null) return true;
  if (a == null || b == null) return false;

  if (a is bool && b is bool) return a == b;
  if (a is bool && b is String) {
    if (b.toLowerCase() == 'true') return a == true;
    if (b.toLowerCase() == 'false') return a == false;
  }
  if (b is bool && a is String) {
    if (a.toLowerCase() == 'true') return b == true;
    if (a.toLowerCase() == 'false') return b == false;
  }

  if (a is num && b is num) return a == b;
  if (a is num && b is String) {
    final num? parsed = num.tryParse(b);
    if (parsed != null) return a == parsed;
  }
  if (b is num && a is String) {
    final num? parsed = num.tryParse(a);
    if (parsed != null) return b == parsed;
  }

  if (a is String && b is String) {
    return a.toLowerCase() == b.toLowerCase();
  }

  return a.toString().toLowerCase() == b.toString().toLowerCase();
}

bool _isContains(dynamic itemValue, dynamic filterValue) {
  if (itemValue == null || filterValue == null) return false;
  if (itemValue is Iterable) {
    return itemValue.any((dynamic item) => _isEqual(item, filterValue));
  }
  return itemValue
      .toString()
      .toLowerCase()
      .contains(filterValue.toString().toLowerCase());
}

int _compare(dynamic a, dynamic b) {
  if (a == null && b == null) return 0;
  if (a == null) return -1;
  if (b == null) return 1;

  if (a is num && b is num) return a.compareTo(b);
  if (a is num && b is String) {
    final num? parsed = num.tryParse(b);
    if (parsed != null) return a.compareTo(parsed);
  }
  if (b is num && a is String) {
    final num? parsed = num.tryParse(a);
    if (parsed != null) return parsed.compareTo(b);
  }

  if (a is String && b is String) {
    final DateTime? dateA = DateTime.tryParse(a);
    final DateTime? dateB = DateTime.tryParse(b);
    if (dateA != null && dateB != null) return dateA.compareTo(dateB);
    return a.toLowerCase().compareTo(b.toLowerCase());
  }

  return a.toString().toLowerCase().compareTo(b.toString().toLowerCase());
}
