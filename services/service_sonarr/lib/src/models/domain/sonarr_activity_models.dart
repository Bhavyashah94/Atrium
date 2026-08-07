import 'package:freezed_annotation/freezed_annotation.dart';

import 'sonarr_config_models.dart';
import 'sonarr_episode_models.dart';
import 'sonarr_series_models.dart';
import 'sonarr_system_models.dart';

part 'sonarr_activity_models.freezed.dart';
part 'sonarr_activity_models.g.dart';

@Freezed(when: FreezedWhenOptions.none, map: FreezedMapOptions.none)
abstract class SonarrBlocklistBulk with _$SonarrBlocklistBulk {
  const factory SonarrBlocklistBulk({
    @Default(<int>[]) List<int> ids,
  }) = _SonarrBlocklistBulk;

  factory SonarrBlocklistBulk.fromJson(Map<String, dynamic> json) =>
      _$SonarrBlocklistBulkFromJson(json);
}

@Freezed(when: FreezedWhenOptions.none, map: FreezedMapOptions.none)
abstract class SonarrBlocklistItem with _$SonarrBlocklistItem {
  const factory SonarrBlocklistItem({
    @Default(0) int id,
    int? seriesId,
    @Default(<int>[]) List<int> episodeIds,
    String? sourceTitle,
    @Default(<SonarrLanguage>[]) List<SonarrLanguage> languages,
    SonarrQuality? quality,
    @Default(<SonarrCustomFormat>[]) List<SonarrCustomFormat> customFormats,
    String? date,
    String? protocol,
    String? indexer,
    String? message,
    SonarrSeries? series,
  }) = _SonarrBlocklistItem;

  factory SonarrBlocklistItem.fromJson(Map<String, dynamic> json) =>
      _$SonarrBlocklistItemFromJson(json);
}

@Freezed(when: FreezedWhenOptions.none, map: FreezedMapOptions.none)
abstract class SonarrBlocklistResourcePaging with _$SonarrBlocklistResourcePaging {
  const factory SonarrBlocklistResourcePaging({
    int? page,
    int? pageSize,
    String? sortKey,
    String? sortDirection,
    int? totalRecords,
    @Default(<SonarrBlocklistItem>[]) List<SonarrBlocklistItem> records,
  }) = _SonarrBlocklistResourcePaging;

  factory SonarrBlocklistResourcePaging.fromJson(Map<String, dynamic> json) =>
      _$SonarrBlocklistResourcePagingFromJson(json);
}

@Freezed(when: FreezedWhenOptions.none, map: FreezedMapOptions.none)
abstract class SonarrDownloadClientBulk with _$SonarrDownloadClientBulk {
  const factory SonarrDownloadClientBulk({
    @Default(<int>[]) List<int> ids,
    @Default(<int>[]) List<int> tags,
    String? applyTags,
    bool? enable,
    int? priority,
    bool? removeCompletedDownloads,
    bool? removeFailedDownloads,
  }) = _SonarrDownloadClientBulk;

  factory SonarrDownloadClientBulk.fromJson(Map<String, dynamic> json) =>
      _$SonarrDownloadClientBulkFromJson(json);
}

@Freezed(when: FreezedWhenOptions.none, map: FreezedMapOptions.none)
abstract class SonarrDownloadClientConfig with _$SonarrDownloadClientConfig {
  const factory SonarrDownloadClientConfig({
    @Default(0) int id,
    String? downloadClientWorkingFolders,
    bool? enableCompletedDownloadHandling,
    bool? autoRedownloadFailed,
    bool? autoRedownloadFailedFromInteractiveSearch,
  }) = _SonarrDownloadClientConfig;

  factory SonarrDownloadClientConfig.fromJson(Map<String, dynamic> json) =>
      _$SonarrDownloadClientConfigFromJson(json);
}

@Freezed(when: FreezedWhenOptions.none, map: FreezedMapOptions.none)
abstract class SonarrDownloadClient with _$SonarrDownloadClient {
  const factory SonarrDownloadClient({
    @Default(0) int id,
    String? name,
    @Default(<SonarrField>[]) List<SonarrField> fields,
    String? implementationName,
    String? implementation,
    String? configContract,
    String? infoLink,
    SonarrProviderMessage? message,
    @Default(<int>[]) List<int> tags,
    @Default(<SonarrDownloadClient>[]) List<SonarrDownloadClient> presets,
    bool? enable,
    String? protocol,
    int? priority,
    bool? removeCompletedDownloads,
    bool? removeFailedDownloads,
  }) = _SonarrDownloadClient;

  factory SonarrDownloadClient.fromJson(Map<String, dynamic> json) =>
      _$SonarrDownloadClientFromJson(json);
}

@Freezed(when: FreezedWhenOptions.none, map: FreezedMapOptions.none)
abstract class SonarrHistoryItem with _$SonarrHistoryItem {
  const factory SonarrHistoryItem({
    @Default(0) int id,
    @Default(0) int episodeId,
    @Default(0) int seriesId,
    String? sourceTitle,
    @Default(<SonarrLanguage>[]) List<SonarrLanguage> languages,
    SonarrQuality? quality,
    @Default(<SonarrCustomFormat>[]) List<SonarrCustomFormat> customFormats,
    int? customFormatScore,
    bool? qualityCutoffNotMet,
    String? date,
    String? downloadId,
    String? eventType,
    Map<String, dynamic>? data,
    SonarrEpisode? episode,
    SonarrSeries? series,
  }) = _SonarrHistoryItem;

  factory SonarrHistoryItem.fromJson(Map<String, dynamic> json) =>
      _$SonarrHistoryItemFromJson(json);
}

@Freezed(when: FreezedWhenOptions.none, map: FreezedMapOptions.none)
abstract class SonarrHistoryResourcePaging with _$SonarrHistoryResourcePaging {
  const factory SonarrHistoryResourcePaging({
    int? page,
    int? pageSize,
    String? sortKey,
    String? sortDirection,
    int? totalRecords,
    @Default(<SonarrHistoryItem>[]) List<SonarrHistoryItem> records,
  }) = _SonarrHistoryResourcePaging;

  factory SonarrHistoryResourcePaging.fromJson(Map<String, dynamic> json) =>
      _$SonarrHistoryResourcePagingFromJson(json);
}

@Freezed(when: FreezedWhenOptions.none, map: FreezedMapOptions.none)
abstract class SonarrQueueBulk with _$SonarrQueueBulk {
  const factory SonarrQueueBulk({
    @Default(<int>[]) List<int> ids,
  }) = _SonarrQueueBulk;

  factory SonarrQueueBulk.fromJson(Map<String, dynamic> json) =>
      _$SonarrQueueBulkFromJson(json);
}

@Freezed(when: FreezedWhenOptions.none, map: FreezedMapOptions.none)
abstract class SonarrQueueItem with _$SonarrQueueItem {
  const factory SonarrQueueItem({
    @Default(0) int id,
    int? seriesId,
    int? episodeId,
    int? seasonNumber,
    SonarrSeries? series,
    SonarrEpisode? episode,
    @Default(<SonarrLanguage>[]) List<SonarrLanguage> languages,
    SonarrQuality? quality,
    @Default(<SonarrCustomFormat>[]) List<SonarrCustomFormat> customFormats,
    int? customFormatScore,
    double? size,
    String? title,
    String? estimatedCompletionTime,
    String? added,
    String? status,
    String? trackedDownloadStatus,
    String? trackedDownloadState,
    @Default(<SonarrTrackedDownloadStatusMessage>[]) List<SonarrTrackedDownloadStatusMessage> statusMessages,
    String? errorMessage,
    String? downloadId,
    String? protocol,
    String? downloadClient,
    bool? downloadClientHasPostImportCategory,
    String? indexer,
    String? outputPath,
    bool? episodeHasFile,
    double? sizeleft,
    String? timeleft,
  }) = _SonarrQueueItem;

  factory SonarrQueueItem.fromJson(Map<String, dynamic> json) =>
      _$SonarrQueueItemFromJson(json);
}

@Freezed(when: FreezedWhenOptions.none, map: FreezedMapOptions.none)
abstract class SonarrQueueResourcePaging with _$SonarrQueueResourcePaging {
  const factory SonarrQueueResourcePaging({
    int? page,
    int? pageSize,
    String? sortKey,
    String? sortDirection,
    int? totalRecords,
    @Default(<SonarrQueueItem>[]) List<SonarrQueueItem> records,
  }) = _SonarrQueueResourcePaging;

  factory SonarrQueueResourcePaging.fromJson(Map<String, dynamic> json) =>
      _$SonarrQueueResourcePagingFromJson(json);
}

@Freezed(when: FreezedWhenOptions.none, map: FreezedMapOptions.none)
abstract class SonarrQueueStatus with _$SonarrQueueStatus {
  const factory SonarrQueueStatus({
    @Default(0) int id,
    int? totalCount,
    int? count,
    int? unknownCount,
    bool? errors,
    bool? warnings,
    bool? unknownErrors,
    bool? unknownWarnings,
  }) = _SonarrQueueStatus;

  factory SonarrQueueStatus.fromJson(Map<String, dynamic> json) =>
      _$SonarrQueueStatusFromJson(json);
}

@Freezed(when: FreezedWhenOptions.none, map: FreezedMapOptions.none)
abstract class SonarrTrackedDownloadStatusMessage with _$SonarrTrackedDownloadStatusMessage {
  const factory SonarrTrackedDownloadStatusMessage({
    String? title,
    @Default(<String>[]) List<String> messages,
  }) = _SonarrTrackedDownloadStatusMessage;

  factory SonarrTrackedDownloadStatusMessage.fromJson(Map<String, dynamic> json) =>
      _$SonarrTrackedDownloadStatusMessageFromJson(json);
}
