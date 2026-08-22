import 'package:dio/dio.dart';

import '../generated/api/raw_command_api.dart';
import '../generated/api/raw_episode_api.dart';
import '../generated/api/raw_history_api.dart';
import '../generated/api/raw_queue_api.dart';
import '../generated/api/raw_queue_details_api.dart';
import '../generated/api/raw_queue_status_api.dart';
import '../generated/api/raw_release_api.dart';
import '../generated/api/raw_series_api.dart';
import '../generated/api/raw_series_lookup_api.dart';

import 'sonarr_command_service.dart';
import 'sonarr_episode_service.dart';
import 'sonarr_queue_service.dart';
import 'sonarr_series_service.dart';

/// Central client for Sonarr API services.
class SonarrClient {
  final Dio dio;
  final String baseUrl;
  final String? apiKey;

  late final RawSeriesApi rawSeriesApi;
  late final RawSeriesLookupApi rawSeriesLookupApi;
  late final RawEpisodeApi rawEpisodeApi;
  late final RawQueueApi rawQueueApi;
  late final RawQueueDetailsApi rawQueueDetailsApi;
  late final RawQueueStatusApi rawQueueStatusApi;
  late final RawReleaseApi rawReleaseApi;
  late final RawHistoryApi rawHistoryApi;
  late final RawCommandApi rawCommandApi;

  late final SonarrSeriesService seriesService;
  late final SonarrEpisodeService episodeService;
  late final SonarrCommandService commandService;
  late final SonarrQueueService queueService;

  SonarrClient({
    Dio? dio,
    String? baseUrl,
    this.apiKey,
  })  : dio = dio ?? Dio(),
        baseUrl = baseUrl ?? dio?.options.baseUrl ?? '' {
    final effectiveBase = this.baseUrl.isNotEmpty ? this.baseUrl : this.dio.options.baseUrl;
    this.dio.options.baseUrl = effectiveBase.endsWith('/') ? effectiveBase : '$effectiveBase/';
    if (apiKey != null && apiKey!.isNotEmpty) {
      this.dio.options.headers['X-Api-Key'] = apiKey;
    }

    rawSeriesApi = RawSeriesApi(this.dio);
    rawSeriesLookupApi = RawSeriesLookupApi(this.dio);
    rawEpisodeApi = RawEpisodeApi(this.dio);
    rawQueueApi = RawQueueApi(this.dio);
    rawQueueDetailsApi = RawQueueDetailsApi(this.dio);
    rawQueueStatusApi = RawQueueStatusApi(this.dio);
    rawReleaseApi = RawReleaseApi(this.dio);
    rawHistoryApi = RawHistoryApi(this.dio);
    rawCommandApi = RawCommandApi(this.dio);

    seriesService = SonarrSeriesService(rawSeriesApi, rawSeriesLookupApi);
    episodeService = SonarrEpisodeService(rawEpisodeApi);
    commandService = SonarrCommandService(rawCommandApi);
    queueService = SonarrQueueService(rawQueueApi, rawQueueDetailsApi, rawQueueStatusApi);
  }
}
