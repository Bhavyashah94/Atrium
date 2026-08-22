import '../generated/api/raw_queue_api.dart';
import '../generated/api/raw_queue_details_api.dart';
import '../generated/api/raw_queue_status_api.dart';
import '../generated/models/queue_resource.dart';
import '../generated/models/queue_status_resource.dart';
import '../generated/responses/sonarr_exception.dart';

/// High-level service wrapper for Sonarr active download queue and sessions.
class SonarrQueueService {
  final RawQueueApi _rawQueueApi;
  final RawQueueDetailsApi _rawQueueDetailsApi;
  final RawQueueStatusApi _rawQueueStatusApi;

  SonarrQueueService(
    this._rawQueueApi,
    this._rawQueueDetailsApi,
    this._rawQueueStatusApi,
  );

  /// Retrieves active download queue records (with progress, time left, status).
  Future<List<QueueResource>> getQueue({
    String? page,
    String? pageSize,
    String? sortKey,
    String? sortDirection,
  }) async {
    final response = await _rawQueueApi.getQueue(
      page: page,
      pageSize: pageSize,
      sortKey: sortKey,
      sortDirection: sortDirection,
    );
    if (response.isSuccess && response.data != null) {
      return response.data!.records ?? [];
    }
    if (response.error != null) {
      throw SonarrException(
        response.error!.message ?? 'Failed to fetch queue',
        statusCode: response.statusCode,
        error: response.error,
      );
    }
    throw SonarrException('Failed to fetch queue', statusCode: response.statusCode);
  }

  /// Retrieves detailed download queue records, optionally filtered by seriesId or episodeIds.
  Future<List<QueueResource>> getQueueDetails({
    String? seriesId,
    String? episodeId,
  }) async {
    final response = await _rawQueueDetailsApi.getQueueDetails(
      seriesId: seriesId,
      episodeIds: episodeId,
    );
    if (response.isSuccess && response.data != null) {
      return response.data!;
    }
    if (response.error != null) {
      throw SonarrException(
        response.error!.message ?? 'Failed to fetch queue details',
        statusCode: response.statusCode,
        error: response.error,
      );
    }
    throw SonarrException('Failed to fetch queue details', statusCode: response.statusCode);
  }

  /// Retrieves status counts for active download queues.
  Future<QueueStatusResource?> getQueueStatus() async {
    final response = await _rawQueueStatusApi.getQueueStatus();
    if (response.isSuccess) {
      return response.data;
    }
    if (response.error != null) {
      throw SonarrException(
        response.error!.message ?? 'Failed to fetch queue status',
        statusCode: response.statusCode,
        error: response.error,
      );
    }
    throw SonarrException('Failed to fetch queue status', statusCode: response.statusCode);
  }
}
