import 'package:dio/dio.dart';

import 'models/cleanuparr_event.dart';
import 'models/cleanuparr_job.dart';
import 'models/cleanuparr_stats.dart';
import 'models/cleanuparr_status.dart';
import 'models/cleanuparr_strike.dart';

/// REST client for communicating with a Cleanuparr daemon instance.
class CleanuparrApi {
  const CleanuparrApi(this._dio);

  final Dio _dio;

  /// Fetches system information, uptime, memory, and Arr/client connections.
  Future<CleanuparrStatus> getStatus() async {
    final Response<dynamic> response = await _dio.get<dynamic>('api/status');
    final dynamic data = response.data;

    List<dynamic>? rawClients;
    try {
      final Response<dynamic> clientResp =
          await _dio.get<dynamic>('api/status/download-client');
      final dynamic clientData = clientResp.data;
      if (clientData is Map<String, dynamic>) {
        final dynamic list = clientData['clients'] ?? clientData['Clients'];
        if (list is List) rawClients = list;
      } else if (clientData is List) {
        rawClients = clientData;
      }
    } catch (_) {
      // Optional endpoint; ignore if not reachable
    }

    if (data is Map<String, dynamic>) {
      final Map<String, dynamic> merged = Map<String, dynamic>.from(data);
      if (rawClients != null && !merged.containsKey('downloadClients')) {
        merged['downloadClients'] = rawClients;
      }
      return CleanuparrStatus.fromJson(merged);
    }
    return const CleanuparrStatus(version: 'Unknown', appName: 'Cleanuparr');
  }

  /// Fetches operational statistics rolled up over the requested [hours] (e.g. 24, 168, 720).
  Future<CleanuparrStats> getStats({int hours = 168}) async {
    final Response<dynamic> response = await _dio.get<dynamic>(
      'api/v2/stats',
      queryParameters: <String, dynamic>{
        'hours': hours,
        'includeDryRun': false,
      },
    );
    final dynamic data = response.data;
    if (data is Map<String, dynamic>) {
      return CleanuparrStats.fromJson(data, hours: hours);
    }
    return CleanuparrStats(hours: hours);
  }

  /// Lists download items that currently hold active strikes.
  Future<List<CleanuparrStrikeItem>> getStrikes({
    int page = 1,
    int pageSize = 50,
    String? search,
  }) async {
    final Map<String, dynamic> params = <String, dynamic>{
      'page': page,
      'pageSize': pageSize,
      if (search != null && search.isNotEmpty) 'search': search,
    };

    final Response<dynamic> response = await _dio.get<dynamic>(
      'api/strikes',
      queryParameters: params,
    );
    final dynamic data = response.data;

    final List<CleanuparrStrikeItem> items = <CleanuparrStrikeItem>[];
    List<dynamic>? rawList;

    if (data is List) {
      rawList = data;
    } else if (data is Map<String, dynamic>) {
      // Handles paginated responses with results or items list
      final dynamic list = data['items'] ?? data['results'] ?? data['data'];
      if (list is List) {
        rawList = list;
      }
    }

    if (rawList != null) {
      for (final dynamic item in rawList) {
        if (item is Map<String, dynamic>) {
          items.add(CleanuparrStrikeItem.fromJson(item));
        }
      }
    }

    return items;
  }

  /// Resets and clears all strikes for a download item by [downloadItemId].
  Future<void> deleteStrike(String downloadItemId) async {
    await _dio.delete<void>('api/strikes/$downloadItemId');
  }

  /// Fetches historical audit and operational events.
  Future<List<CleanuparrEvent>> getEvents({
    int page = 1,
    int pageSize = 50,
    String? eventType,
    String? severity,
    String? search,
  }) async {
    final Map<String, dynamic> params = <String, dynamic>{
      'page': page,
      'pageSize': pageSize,
      if (eventType != null && eventType.isNotEmpty) 'eventType': eventType,
      if (severity != null && severity.isNotEmpty) 'severity': severity,
      if (search != null && search.isNotEmpty) 'search': search,
    };

    final Response<dynamic> response = await _dio.get<dynamic>(
      'api/events',
      queryParameters: params,
    );
    final dynamic data = response.data;

    final List<CleanuparrEvent> events = <CleanuparrEvent>[];
    List<dynamic>? rawList;

    if (data is List) {
      rawList = data;
    } else if (data is Map<String, dynamic>) {
      final dynamic list = data['items'] ?? data['results'] ?? data['data'];
      if (list is List) {
        rawList = list;
      }
    }

    if (rawList != null) {
      for (final dynamic item in rawList) {
        if (item is Map<String, dynamic>) {
          events.add(CleanuparrEvent.fromJson(item));
        }
      }
    }

    return events;
  }

  /// Lists registered background jobs and their execution schedules.
  Future<List<CleanuparrJob>> getJobs() async {
    final Response<dynamic> response = await _dio.get<dynamic>('api/jobs');
    final dynamic data = response.data;

    final List<CleanuparrJob> jobs = <CleanuparrJob>[];
    List<dynamic>? rawList;

    if (data is List) {
      rawList = data;
    } else if (data is Map<String, dynamic>) {
      final dynamic list = data['jobs'] ?? data['items'] ?? data['data'];
      if (list is List) {
        rawList = list;
      }
    }

    if (rawList != null) {
      for (final dynamic item in rawList) {
        if (item is Map<String, dynamic>) {
          jobs.add(CleanuparrJob.fromJson(item));
        }
      }
    }

    return jobs;
  }

  /// Triggers immediate on-demand execution of a background job by [jobType].
  Future<void> triggerJob(String jobType) async {
    await _dio.post<void>('api/jobs/$jobType/trigger');
  }
}
