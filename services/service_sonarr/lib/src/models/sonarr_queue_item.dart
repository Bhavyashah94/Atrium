import 'package:freezed_annotation/freezed_annotation.dart';

import 'sonarr_episode.dart';
import 'sonarr_series.dart';

part 'sonarr_queue_item.freezed.dart';
part 'sonarr_queue_item.g.dart';

@Freezed(when: FreezedWhenOptions.none, map: FreezedMapOptions.none)
abstract class SonarrQueueItem with _$SonarrQueueItem {
  const factory SonarrQueueItem({
    required int id,
    int? seriesId,
    int? episodeId,
    int? seasonNumber,
    SonarrSeries? series,
    SonarrEpisode? episode,
    double? size,
    String? title,
    String? estimatedCompletionTime,
    String? added,
    String? status,
    String? trackedDownloadStatus,
    String? trackedDownloadState,
    String? errorMessage,
    String? downloadId,
    String? downloadClient,
    String? indexer,
    String? outputPath,
    double? sizeleft,
    String? timeleft,
    @Default(<SonarrLanguage>[]) List<SonarrLanguage> languages,
    Map<String, dynamic>? quality,
    @Default(<Map<String, dynamic>>[]) List<Map<String, dynamic>> customFormats,
    int? customFormatScore,
    @Default(<Map<String, dynamic>>[]) List<Map<String, dynamic>> statusMessages,
    String? protocol,
    bool? downloadClientHasPostImportCategory,
    bool? episodeHasFile,
  }) = _SonarrQueueItem;

  factory SonarrQueueItem.fromJson(Map<String, dynamic> json) =>
      _$SonarrQueueItemFromJson(json);
}
