import 'generated/models/custom_filter_resource.dart';
import 'models/sonarr_series.dart';

/// Evaluates whether a [SonarrSeries] satisfies a [CustomFilterResource].
bool matchesSonarrCustomFilter(
  SonarrSeries series,
  CustomFilterResource filter,
) {
  final List<dynamic>? rules = filter.filters;
  if (rules == null || rules.isEmpty) return true;

  for (final dynamic raw in rules) {
    if (raw is Map) {
      final String? key = raw['key']?.toString();
      final dynamic filterValue = raw['value'];
      final String type = raw['type']?.toString().toLowerCase() ?? 'equal';
      if (key == null) continue;

      final dynamic itemValue = extractSonarrSeriesField(series, key);
      if (!evaluateCustomFilterRule(itemValue, filterValue, type)) {
        return false;
      }
    }
  }
  return true;
}

/// Extracts a property value from [series] for the given filter [key].
dynamic extractSonarrSeriesField(SonarrSeries series, String key) {
  switch (key) {
    case 'monitored':
      return series.monitored;
    case 'status':
      return series.status;
    case 'ended':
      return series.status?.toLowerCase() == 'ended';
    case 'continuing':
      return series.status?.toLowerCase() == 'continuing';
    case 'seriesType':
      return series.seriesType;
    case 'title':
      return series.title;
    case 'sortTitle':
      return series.sortTitle ?? series.title;
    case 'network':
      return series.network;
    case 'year':
      return series.year;
    case 'genres':
      return series.genres;
    case 'path':
      return series.path;
    case 'certification':
      return series.certification;
    case 'runtime':
      return series.runtime;
    case 'added':
      return series.added;
    case 'nextAiring':
      return series.nextAiring;
    case 'previousAiring':
      return series.previousAiring;
    case 'tvdbId':
      return series.tvdbId;
    case 'seasonCount':
      return series.statistics?.seasonCount;
    case 'episodeCount':
      return series.statistics?.episodeCount;
    case 'episodeFileCount':
      return series.statistics?.episodeFileCount;
    case 'totalEpisodeCount':
      return series.statistics?.totalEpisodeCount;
    case 'sizeOnDisk':
      return series.statistics?.sizeOnDisk;
    case 'episodeProgress':
      final int count = series.statistics?.episodeCount ?? 0;
      final int files = series.statistics?.episodeFileCount ?? 0;
      return count > 0 ? (files / count) * 100 : 100.0;
    case 'missing':
      final int count = series.statistics?.episodeCount ?? 0;
      final int files = series.statistics?.episodeFileCount ?? 0;
      return count - files > 0;
    default:
      try {
        return series.toJson()[key];
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
      return _compare(itemValue, filterValue) > 0;

    case 'greaterthanorequal':
      return _compare(itemValue, filterValue) >= 0;

    case 'lessthan':
      return _compare(itemValue, filterValue) < 0;

    case 'lessthanorequal':
      return _compare(itemValue, filterValue) <= 0;

    case 'startswith':
      if (itemValue == null || filterValue == null) return false;
      return itemValue.toString().toLowerCase().startsWith(
            filterValue.toString().toLowerCase(),
          );

    case 'notstartswith':
      if (itemValue == null || filterValue == null) return true;
      return !itemValue.toString().toLowerCase().startsWith(
            filterValue.toString().toLowerCase(),
          );

    case 'endswith':
      if (itemValue == null || filterValue == null) return false;
      return itemValue.toString().toLowerCase().endsWith(
            filterValue.toString().toLowerCase(),
          );

    case 'notendswith':
      if (itemValue == null || filterValue == null) return true;
      return !itemValue.toString().toLowerCase().endsWith(
            filterValue.toString().toLowerCase(),
          );

    default:
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
