import 'package:freezed_annotation/freezed_annotation.dart';

part 'sonarr_models.freezed.dart';
part 'sonarr_models.g.dart';

@Freezed(when: FreezedWhenOptions.none, map: FreezedMapOptions.none)
abstract class SonarrAddSeriesOptions with _$SonarrAddSeriesOptions {
  const factory SonarrAddSeriesOptions({
    bool? ignoreEpisodesWithFiles,
    bool? ignoreEpisodesWithoutFiles,
    String? monitor,
    bool? searchForMissingEpisodes,
    bool? searchForCutoffUnmetEpisodes,
  }) = _SonarrAddSeriesOptions;

  factory SonarrAddSeriesOptions.fromJson(Map<String, dynamic> json) =>
      _$SonarrAddSeriesOptionsFromJson(json);
}

@Freezed(when: FreezedWhenOptions.none, map: FreezedMapOptions.none)
abstract class SonarrAlternateTitle with _$SonarrAlternateTitle {
  const factory SonarrAlternateTitle({
    String? title,
    int? seasonNumber,
    int? sceneSeasonNumber,
    String? sceneOrigin,
    String? comment,
  }) = _SonarrAlternateTitle;

  factory SonarrAlternateTitle.fromJson(Map<String, dynamic> json) =>
      _$SonarrAlternateTitleFromJson(json);
}

@Freezed(when: FreezedWhenOptions.none, map: FreezedMapOptions.none)
abstract class SonarrAutoTagging with _$SonarrAutoTagging {
  const factory SonarrAutoTagging({
    @Default(0) int id,
    String? name,
    bool? removeTagsAutomatically,
    @Default(<int>[]) List<int> tags,
    @Default(<SonarrAutoTaggingSpecificationSchema>[]) List<SonarrAutoTaggingSpecificationSchema> specifications,
  }) = _SonarrAutoTagging;

  factory SonarrAutoTagging.fromJson(Map<String, dynamic> json) =>
      _$SonarrAutoTaggingFromJson(json);
}

@Freezed(when: FreezedWhenOptions.none, map: FreezedMapOptions.none)
abstract class SonarrAutoTaggingSpecificationSchema with _$SonarrAutoTaggingSpecificationSchema {
  const factory SonarrAutoTaggingSpecificationSchema({
    @Default(0) int id,
    String? name,
    String? implementation,
    String? implementationName,
    bool? negate,
    bool? required,
    @Default(<SonarrField>[]) List<SonarrField> fields,
  }) = _SonarrAutoTaggingSpecificationSchema;

  factory SonarrAutoTaggingSpecificationSchema.fromJson(Map<String, dynamic> json) =>
      _$SonarrAutoTaggingSpecificationSchemaFromJson(json);
}

@Freezed(when: FreezedWhenOptions.none, map: FreezedMapOptions.none)
abstract class SonarrBackup with _$SonarrBackup {
  const factory SonarrBackup({
    @Default(0) int id,
    String? name,
    String? path,
    String? type,
    int? size,
    String? time,
  }) = _SonarrBackup;

  factory SonarrBackup.fromJson(Map<String, dynamic> json) =>
      _$SonarrBackupFromJson(json);
}

@Freezed(when: FreezedWhenOptions.none, map: FreezedMapOptions.none)
abstract class SonarrBlocklistBulk with _$SonarrBlocklistBulk {
  const factory SonarrBlocklistBulk({
    @Default(<int>[]) List<int> ids,
  }) = _SonarrBlocklistBulk;

  factory SonarrBlocklistBulk.fromJson(Map<String, dynamic> json) =>
      _$SonarrBlocklistBulkFromJson(json);
}

@Freezed(when: FreezedWhenOptions.none, map: FreezedMapOptions.none)
abstract class SonarrBlocklist with _$SonarrBlocklist {
  const factory SonarrBlocklist({
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
  }) = _SonarrBlocklist;

  factory SonarrBlocklist.fromJson(Map<String, dynamic> json) =>
      _$SonarrBlocklistFromJson(json);
}

@Freezed(when: FreezedWhenOptions.none, map: FreezedMapOptions.none)
abstract class SonarrBlocklistResourcePaging with _$SonarrBlocklistResourcePaging {
  const factory SonarrBlocklistResourcePaging({
    int? page,
    int? pageSize,
    String? sortKey,
    String? sortDirection,
    int? totalRecords,
    @Default(<SonarrBlocklist>[]) List<SonarrBlocklist> records,
  }) = _SonarrBlocklistResourcePaging;

  factory SonarrBlocklistResourcePaging.fromJson(Map<String, dynamic> json) =>
      _$SonarrBlocklistResourcePagingFromJson(json);
}

@Freezed(when: FreezedWhenOptions.none, map: FreezedMapOptions.none)
abstract class SonarrCommand with _$SonarrCommand {
  const factory SonarrCommand({
    bool? sendUpdatesToClient,
    bool? updateScheduledTask,
    String? completionMessage,
    bool? requiresDiskAccess,
    bool? isExclusive,
    bool? isLongRunning,
    String? name,
    String? lastExecutionTime,
    String? lastStartTime,
    String? trigger,
    bool? suppressMessages,
    String? clientUserAgent,
  }) = _SonarrCommand;

  factory SonarrCommand.fromJson(Map<String, dynamic> json) =>
      _$SonarrCommandFromJson(json);
}

@Freezed(when: FreezedWhenOptions.none, map: FreezedMapOptions.none)
abstract class SonarrCustomFilter with _$SonarrCustomFilter {
  const factory SonarrCustomFilter({
    @Default(0) int id,
    String? type,
    String? label,
    @Default(<Map<String, dynamic>>[]) List<Map<String, dynamic>> filters,
  }) = _SonarrCustomFilter;

  factory SonarrCustomFilter.fromJson(Map<String, dynamic> json) =>
      _$SonarrCustomFilterFromJson(json);
}

@Freezed(when: FreezedWhenOptions.none, map: FreezedMapOptions.none)
abstract class SonarrCustomFormatBulk with _$SonarrCustomFormatBulk {
  const factory SonarrCustomFormatBulk({
    @Default(<int>[]) List<int> ids,
    bool? includeCustomFormatWhenRenaming,
  }) = _SonarrCustomFormatBulk;

  factory SonarrCustomFormatBulk.fromJson(Map<String, dynamic> json) =>
      _$SonarrCustomFormatBulkFromJson(json);
}

@Freezed(when: FreezedWhenOptions.none, map: FreezedMapOptions.none)
abstract class SonarrCustomFormat with _$SonarrCustomFormat {
  const factory SonarrCustomFormat({
    @Default(0) int id,
    String? name,
    bool? includeCustomFormatWhenRenaming,
    @Default(<SonarrCustomFormatSpecificationSchema>[]) List<SonarrCustomFormatSpecificationSchema> specifications,
  }) = _SonarrCustomFormat;

  factory SonarrCustomFormat.fromJson(Map<String, dynamic> json) =>
      _$SonarrCustomFormatFromJson(json);
}

@Freezed(when: FreezedWhenOptions.none, map: FreezedMapOptions.none)
abstract class SonarrCustomFormatSpecificationSchema with _$SonarrCustomFormatSpecificationSchema {
  const factory SonarrCustomFormatSpecificationSchema({
    @Default(0) int id,
    String? name,
    String? implementation,
    String? implementationName,
    String? infoLink,
    bool? negate,
    bool? required,
    @Default(<SonarrField>[]) List<SonarrField> fields,
    @Default(<SonarrCustomFormatSpecificationSchema>[]) List<SonarrCustomFormatSpecificationSchema> presets,
  }) = _SonarrCustomFormatSpecificationSchema;

  factory SonarrCustomFormatSpecificationSchema.fromJson(Map<String, dynamic> json) =>
      _$SonarrCustomFormatSpecificationSchemaFromJson(json);
}

@Freezed(when: FreezedWhenOptions.none, map: FreezedMapOptions.none)
abstract class SonarrDelayProfile with _$SonarrDelayProfile {
  const factory SonarrDelayProfile({
    @Default(0) int id,
    bool? enableUsenet,
    bool? enableTorrent,
    String? preferredProtocol,
    int? usenetDelay,
    int? torrentDelay,
    bool? bypassIfHighestQuality,
    bool? bypassIfAboveCustomFormatScore,
    int? minimumCustomFormatScore,
    int? order,
    @Default(<int>[]) List<int> tags,
  }) = _SonarrDelayProfile;

  factory SonarrDelayProfile.fromJson(Map<String, dynamic> json) =>
      _$SonarrDelayProfileFromJson(json);
}

@Freezed(when: FreezedWhenOptions.none, map: FreezedMapOptions.none)
abstract class SonarrDiskSpace with _$SonarrDiskSpace {
  const factory SonarrDiskSpace({
    @Default(0) int id,
    String? path,
    String? label,
    int? freeSpace,
    int? totalSpace,
  }) = _SonarrDiskSpace;

  factory SonarrDiskSpace.fromJson(Map<String, dynamic> json) =>
      _$SonarrDiskSpaceFromJson(json);
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
abstract class SonarrEpisodeFileList with _$SonarrEpisodeFileList {
  const factory SonarrEpisodeFileList({
    @Default(<int>[]) List<int> episodeFileIds,
    @Default(<SonarrLanguage>[]) List<SonarrLanguage> languages,
    SonarrQuality? quality,
    String? sceneName,
    String? releaseGroup,
  }) = _SonarrEpisodeFileList;

  factory SonarrEpisodeFileList.fromJson(Map<String, dynamic> json) =>
      _$SonarrEpisodeFileListFromJson(json);
}

@Freezed(when: FreezedWhenOptions.none, map: FreezedMapOptions.none)
abstract class SonarrEpisodeFile with _$SonarrEpisodeFile {
  const factory SonarrEpisodeFile({
    @Default(0) int id,
    int? seriesId,
    int? seasonNumber,
    String? relativePath,
    String? path,
    int? size,
    String? dateAdded,
    String? sceneName,
    String? releaseGroup,
    @Default(<SonarrLanguage>[]) List<SonarrLanguage> languages,
    SonarrQuality? quality,
    @Default(<SonarrCustomFormat>[]) List<SonarrCustomFormat> customFormats,
    int? customFormatScore,
    int? indexerFlags,
    String? releaseType,
    SonarrMediaInfo? mediaInfo,
    bool? qualityCutoffNotMet,
  }) = _SonarrEpisodeFile;

  factory SonarrEpisodeFile.fromJson(Map<String, dynamic> json) =>
      _$SonarrEpisodeFileFromJson(json);
}

@Freezed(when: FreezedWhenOptions.none, map: FreezedMapOptions.none)
abstract class SonarrEpisode with _$SonarrEpisode {
  const factory SonarrEpisode({
    @Default(0) int id,
    int? seriesId,
    int? tvdbId,
    int? episodeFileId,
    int? seasonNumber,
    int? episodeNumber,
    String? title,
    String? airDate,
    String? airDateUtc,
    String? lastSearchTime,
    int? runtime,
    String? finaleType,
    String? overview,
    SonarrEpisodeFile? episodeFile,
    @Default(false) bool hasFile,
    @Default(false) bool monitored,
    int? absoluteEpisodeNumber,
    int? sceneAbsoluteEpisodeNumber,
    int? sceneEpisodeNumber,
    int? sceneSeasonNumber,
    bool? unverifiedSceneNumbering,
    String? endTime,
    String? grabDate,
    SonarrSeries? series,
    @Default(<SonarrMediaCover>[]) List<SonarrMediaCover> images,
  }) = _SonarrEpisode;

  factory SonarrEpisode.fromJson(Map<String, dynamic> json) =>
      _$SonarrEpisodeFromJson(json);
}

@Freezed(when: FreezedWhenOptions.none, map: FreezedMapOptions.none)
abstract class SonarrEpisodeResourcePaging with _$SonarrEpisodeResourcePaging {
  const factory SonarrEpisodeResourcePaging({
    int? page,
    int? pageSize,
    String? sortKey,
    String? sortDirection,
    int? totalRecords,
    @Default(<SonarrEpisode>[]) List<SonarrEpisode> records,
  }) = _SonarrEpisodeResourcePaging;

  factory SonarrEpisodeResourcePaging.fromJson(Map<String, dynamic> json) =>
      _$SonarrEpisodeResourcePagingFromJson(json);
}

@Freezed(when: FreezedWhenOptions.none, map: FreezedMapOptions.none)
abstract class SonarrEpisodesMonitored with _$SonarrEpisodesMonitored {
  const factory SonarrEpisodesMonitored({
    @Default(<int>[]) List<int> episodeIds,
    @Default(false) bool monitored,
  }) = _SonarrEpisodesMonitored;

  factory SonarrEpisodesMonitored.fromJson(Map<String, dynamic> json) =>
      _$SonarrEpisodesMonitoredFromJson(json);
}

@Freezed(when: FreezedWhenOptions.none, map: FreezedMapOptions.none)
abstract class SonarrField with _$SonarrField {
  const factory SonarrField({
    int? order,
    String? name,
    String? label,
    String? unit,
    String? helpText,
    String? helpTextWarning,
    String? helpLink,
    dynamic? value,
    String? type,
    bool? advanced,
    @Default(<SonarrSelectOption>[]) List<SonarrSelectOption> selectOptions,
    String? selectOptionsProviderAction,
    String? section,
    String? hidden,
    String? privacy,
    String? placeholder,
    bool? isFloat,
  }) = _SonarrField;

  factory SonarrField.fromJson(Map<String, dynamic> json) =>
      _$SonarrFieldFromJson(json);
}

@Freezed(when: FreezedWhenOptions.none, map: FreezedMapOptions.none)
abstract class SonarrHealth with _$SonarrHealth {
  const factory SonarrHealth({
    @Default(0) int id,
    String? source,
    String? type,
    String? message,
    SonarrHttpUri? wikiUrl,
  }) = _SonarrHealth;

  factory SonarrHealth.fromJson(Map<String, dynamic> json) =>
      _$SonarrHealthFromJson(json);
}

@Freezed(when: FreezedWhenOptions.none, map: FreezedMapOptions.none)
abstract class SonarrHistory with _$SonarrHistory {
  const factory SonarrHistory({
    @Default(0) int id,
    int? episodeId,
    int? seriesId,
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
  }) = _SonarrHistory;

  factory SonarrHistory.fromJson(Map<String, dynamic> json) =>
      _$SonarrHistoryFromJson(json);
}

@Freezed(when: FreezedWhenOptions.none, map: FreezedMapOptions.none)
abstract class SonarrHistoryResourcePaging with _$SonarrHistoryResourcePaging {
  const factory SonarrHistoryResourcePaging({
    int? page,
    int? pageSize,
    String? sortKey,
    String? sortDirection,
    int? totalRecords,
    @Default(<SonarrHistory>[]) List<SonarrHistory> records,
  }) = _SonarrHistoryResourcePaging;

  factory SonarrHistoryResourcePaging.fromJson(Map<String, dynamic> json) =>
      _$SonarrHistoryResourcePagingFromJson(json);
}

@Freezed(when: FreezedWhenOptions.none, map: FreezedMapOptions.none)
abstract class SonarrHostConfig with _$SonarrHostConfig {
  const factory SonarrHostConfig({
    @Default(0) int id,
    String? bindAddress,
    int? port,
    int? sslPort,
    bool? enableSsl,
    bool? launchBrowser,
    String? authenticationMethod,
    String? authenticationRequired,
    bool? analyticsEnabled,
    String? username,
    String? password,
    String? passwordConfirmation,
    String? logLevel,
    int? logSizeLimit,
    String? consoleLogLevel,
    String? branch,
    String? apiKey,
    String? sslCertPath,
    String? sslCertPassword,
    String? urlBase,
    String? instanceName,
    String? applicationUrl,
    bool? updateAutomatically,
    String? updateMechanism,
    String? updateScriptPath,
    bool? proxyEnabled,
    String? proxyType,
    String? proxyHostname,
    int? proxyPort,
    String? proxyUsername,
    String? proxyPassword,
    String? proxyBypassFilter,
    bool? proxyBypassLocalAddresses,
    String? certificateValidation,
    String? backupFolder,
    int? backupInterval,
    int? backupRetention,
    bool? trustCgnatIpAddresses,
  }) = _SonarrHostConfig;

  factory SonarrHostConfig.fromJson(Map<String, dynamic> json) =>
      _$SonarrHostConfigFromJson(json);
}

@Freezed(when: FreezedWhenOptions.none, map: FreezedMapOptions.none)
abstract class SonarrHttpUri with _$SonarrHttpUri {
  const factory SonarrHttpUri({
    String? fullUri,
    String? scheme,
    String? host,
    int? port,
    String? path,
    String? query,
    String? fragment,
  }) = _SonarrHttpUri;

  factory SonarrHttpUri.fromJson(Map<String, dynamic> json) =>
      _$SonarrHttpUriFromJson(json);
}

@Freezed(when: FreezedWhenOptions.none, map: FreezedMapOptions.none)
abstract class SonarrImportListBulk with _$SonarrImportListBulk {
  const factory SonarrImportListBulk({
    @Default(<int>[]) List<int> ids,
    @Default(<int>[]) List<int> tags,
    String? applyTags,
    bool? enableAutomaticAdd,
    String? rootFolderPath,
    int? qualityProfileId,
  }) = _SonarrImportListBulk;

  factory SonarrImportListBulk.fromJson(Map<String, dynamic> json) =>
      _$SonarrImportListBulkFromJson(json);
}

@Freezed(when: FreezedWhenOptions.none, map: FreezedMapOptions.none)
abstract class SonarrImportListConfig with _$SonarrImportListConfig {
  const factory SonarrImportListConfig({
    @Default(0) int id,
    String? listSyncLevel,
    int? listSyncTag,
  }) = _SonarrImportListConfig;

  factory SonarrImportListConfig.fromJson(Map<String, dynamic> json) =>
      _$SonarrImportListConfigFromJson(json);
}

@Freezed(when: FreezedWhenOptions.none, map: FreezedMapOptions.none)
abstract class SonarrImportListExclusionBulk with _$SonarrImportListExclusionBulk {
  const factory SonarrImportListExclusionBulk({
    @Default(<int>[]) List<int> ids,
  }) = _SonarrImportListExclusionBulk;

  factory SonarrImportListExclusionBulk.fromJson(Map<String, dynamic> json) =>
      _$SonarrImportListExclusionBulkFromJson(json);
}

@Freezed(when: FreezedWhenOptions.none, map: FreezedMapOptions.none)
abstract class SonarrImportListExclusion with _$SonarrImportListExclusion {
  const factory SonarrImportListExclusion({
    @Default(0) int id,
    int? tvdbId,
    String? title,
  }) = _SonarrImportListExclusion;

  factory SonarrImportListExclusion.fromJson(Map<String, dynamic> json) =>
      _$SonarrImportListExclusionFromJson(json);
}

@Freezed(when: FreezedWhenOptions.none, map: FreezedMapOptions.none)
abstract class SonarrImportListExclusionResourcePaging with _$SonarrImportListExclusionResourcePaging {
  const factory SonarrImportListExclusionResourcePaging({
    int? page,
    int? pageSize,
    String? sortKey,
    String? sortDirection,
    int? totalRecords,
    @Default(<SonarrImportListExclusion>[]) List<SonarrImportListExclusion> records,
  }) = _SonarrImportListExclusionResourcePaging;

  factory SonarrImportListExclusionResourcePaging.fromJson(Map<String, dynamic> json) =>
      _$SonarrImportListExclusionResourcePagingFromJson(json);
}

@Freezed(when: FreezedWhenOptions.none, map: FreezedMapOptions.none)
abstract class SonarrImportList with _$SonarrImportList {
  const factory SonarrImportList({
    @Default(0) int id,
    String? name,
    @Default(<SonarrField>[]) List<SonarrField> fields,
    String? implementationName,
    String? implementation,
    String? configContract,
    String? infoLink,
    SonarrProviderMessage? message,
    @Default(<int>[]) List<int> tags,
    @Default(<SonarrImportList>[]) List<SonarrImportList> presets,
    bool? enableAutomaticAdd,
    bool? searchForMissingEpisodes,
    String? shouldMonitor,
    String? monitorNewItems,
    String? rootFolderPath,
    int? qualityProfileId,
    String? seriesType,
    bool? seasonFolder,
    String? listType,
    int? listOrder,
    String? minRefreshInterval,
  }) = _SonarrImportList;

  factory SonarrImportList.fromJson(Map<String, dynamic> json) =>
      _$SonarrImportListFromJson(json);
}

@Freezed(when: FreezedWhenOptions.none, map: FreezedMapOptions.none)
abstract class SonarrImportRejection with _$SonarrImportRejection {
  const factory SonarrImportRejection({
    String? reason,
    String? type,
  }) = _SonarrImportRejection;

  factory SonarrImportRejection.fromJson(Map<String, dynamic> json) =>
      _$SonarrImportRejectionFromJson(json);
}

@Freezed(when: FreezedWhenOptions.none, map: FreezedMapOptions.none)
abstract class SonarrIndexerBulk with _$SonarrIndexerBulk {
  const factory SonarrIndexerBulk({
    @Default(<int>[]) List<int> ids,
    @Default(<int>[]) List<int> tags,
    String? applyTags,
    bool? enableRss,
    bool? enableAutomaticSearch,
    bool? enableInteractiveSearch,
    int? priority,
  }) = _SonarrIndexerBulk;

  factory SonarrIndexerBulk.fromJson(Map<String, dynamic> json) =>
      _$SonarrIndexerBulkFromJson(json);
}

@Freezed(when: FreezedWhenOptions.none, map: FreezedMapOptions.none)
abstract class SonarrIndexerConfig with _$SonarrIndexerConfig {
  const factory SonarrIndexerConfig({
    @Default(0) int id,
    int? minimumAge,
    int? retention,
    int? maximumSize,
    int? rssSyncInterval,
  }) = _SonarrIndexerConfig;

  factory SonarrIndexerConfig.fromJson(Map<String, dynamic> json) =>
      _$SonarrIndexerConfigFromJson(json);
}

@Freezed(when: FreezedWhenOptions.none, map: FreezedMapOptions.none)
abstract class SonarrIndexerFlag with _$SonarrIndexerFlag {
  const factory SonarrIndexerFlag({
    @Default(0) int id,
    String? name,
    String? nameLower,
  }) = _SonarrIndexerFlag;

  factory SonarrIndexerFlag.fromJson(Map<String, dynamic> json) =>
      _$SonarrIndexerFlagFromJson(json);
}

@Freezed(when: FreezedWhenOptions.none, map: FreezedMapOptions.none)
abstract class SonarrIndexer with _$SonarrIndexer {
  const factory SonarrIndexer({
    @Default(0) int id,
    String? name,
    @Default(<SonarrField>[]) List<SonarrField> fields,
    String? implementationName,
    String? implementation,
    String? configContract,
    String? infoLink,
    SonarrProviderMessage? message,
    @Default(<int>[]) List<int> tags,
    @Default(<SonarrIndexer>[]) List<SonarrIndexer> presets,
    bool? enableRss,
    bool? enableAutomaticSearch,
    bool? enableInteractiveSearch,
    bool? supportsRss,
    bool? supportsSearch,
    String? protocol,
    int? priority,
    int? seasonSearchMaximumSingleEpisodeAge,
    int? downloadClientId,
  }) = _SonarrIndexer;

  factory SonarrIndexer.fromJson(Map<String, dynamic> json) =>
      _$SonarrIndexerFromJson(json);
}

@Freezed(when: FreezedWhenOptions.none, map: FreezedMapOptions.none)
abstract class SonarrLanguage with _$SonarrLanguage {
  const factory SonarrLanguage({
    @Default(0) int id,
    String? name,
  }) = _SonarrLanguage;

  factory SonarrLanguage.fromJson(Map<String, dynamic> json) =>
      _$SonarrLanguageFromJson(json);
}

@Freezed(when: FreezedWhenOptions.none, map: FreezedMapOptions.none)
abstract class SonarrLanguageProfileItem with _$SonarrLanguageProfileItem {
  const factory SonarrLanguageProfileItem({
    @Default(0) int id,
    SonarrLanguage? language,
    bool? allowed,
  }) = _SonarrLanguageProfileItem;

  factory SonarrLanguageProfileItem.fromJson(Map<String, dynamic> json) =>
      _$SonarrLanguageProfileItemFromJson(json);
}

@Freezed(when: FreezedWhenOptions.none, map: FreezedMapOptions.none)
abstract class SonarrLanguageProfile with _$SonarrLanguageProfile {
  const factory SonarrLanguageProfile({
    @Default(0) int id,
    String? name,
    bool? upgradeAllowed,
    SonarrLanguage? cutoff,
    @Default(<SonarrLanguageProfileItem>[]) List<SonarrLanguageProfileItem> languages,
  }) = _SonarrLanguageProfile;

  factory SonarrLanguageProfile.fromJson(Map<String, dynamic> json) =>
      _$SonarrLanguageProfileFromJson(json);
}

@Freezed(when: FreezedWhenOptions.none, map: FreezedMapOptions.none)
abstract class SonarrLocalizationLanguage with _$SonarrLocalizationLanguage {
  const factory SonarrLocalizationLanguage({
    String? identifier,
  }) = _SonarrLocalizationLanguage;

  factory SonarrLocalizationLanguage.fromJson(Map<String, dynamic> json) =>
      _$SonarrLocalizationLanguageFromJson(json);
}

@Freezed(when: FreezedWhenOptions.none, map: FreezedMapOptions.none)
abstract class SonarrLocalization with _$SonarrLocalization {
  const factory SonarrLocalization({
    @Default(0) int id,
    Map<String, dynamic>? strings,
  }) = _SonarrLocalization;

  factory SonarrLocalization.fromJson(Map<String, dynamic> json) =>
      _$SonarrLocalizationFromJson(json);
}

@Freezed(when: FreezedWhenOptions.none, map: FreezedMapOptions.none)
abstract class SonarrLogFile with _$SonarrLogFile {
  const factory SonarrLogFile({
    @Default(0) int id,
    String? filename,
    String? lastWriteTime,
    String? contentsUrl,
    String? downloadUrl,
  }) = _SonarrLogFile;

  factory SonarrLogFile.fromJson(Map<String, dynamic> json) =>
      _$SonarrLogFileFromJson(json);
}

@Freezed(when: FreezedWhenOptions.none, map: FreezedMapOptions.none)
abstract class SonarrLog with _$SonarrLog {
  const factory SonarrLog({
    @Default(0) int id,
    String? time,
    String? exception,
    String? exceptionType,
    String? level,
    String? logger,
    String? message,
    String? method,
  }) = _SonarrLog;

  factory SonarrLog.fromJson(Map<String, dynamic> json) =>
      _$SonarrLogFromJson(json);
}

@Freezed(when: FreezedWhenOptions.none, map: FreezedMapOptions.none)
abstract class SonarrLogResourcePaging with _$SonarrLogResourcePaging {
  const factory SonarrLogResourcePaging({
    int? page,
    int? pageSize,
    String? sortKey,
    String? sortDirection,
    int? totalRecords,
    @Default(<SonarrLog>[]) List<SonarrLog> records,
  }) = _SonarrLogResourcePaging;

  factory SonarrLogResourcePaging.fromJson(Map<String, dynamic> json) =>
      _$SonarrLogResourcePagingFromJson(json);
}

@Freezed(when: FreezedWhenOptions.none, map: FreezedMapOptions.none)
abstract class SonarrManualImportReprocess with _$SonarrManualImportReprocess {
  const factory SonarrManualImportReprocess({
    @Default(0) int id,
    String? path,
    int? seriesId,
    int? seasonNumber,
    @Default(<SonarrEpisode>[]) List<SonarrEpisode> episodes,
    @Default(<int>[]) List<int> episodeIds,
    SonarrQuality? quality,
    @Default(<SonarrLanguage>[]) List<SonarrLanguage> languages,
    String? releaseGroup,
    String? downloadId,
    @Default(<SonarrCustomFormat>[]) List<SonarrCustomFormat> customFormats,
    int? customFormatScore,
    int? indexerFlags,
    String? releaseType,
    @Default(<SonarrImportRejection>[]) List<SonarrImportRejection> rejections,
  }) = _SonarrManualImportReprocess;

  factory SonarrManualImportReprocess.fromJson(Map<String, dynamic> json) =>
      _$SonarrManualImportReprocessFromJson(json);
}

@Freezed(when: FreezedWhenOptions.none, map: FreezedMapOptions.none)
abstract class SonarrManualImport with _$SonarrManualImport {
  const factory SonarrManualImport({
    @Default(0) int id,
    String? path,
    String? relativePath,
    String? folderName,
    String? name,
    int? size,
    SonarrSeries? series,
    int? seasonNumber,
    @Default(<SonarrEpisode>[]) List<SonarrEpisode> episodes,
    int? episodeFileId,
    String? releaseGroup,
    SonarrQuality? quality,
    @Default(<SonarrLanguage>[]) List<SonarrLanguage> languages,
    int? qualityWeight,
    String? downloadId,
    @Default(<SonarrCustomFormat>[]) List<SonarrCustomFormat> customFormats,
    int? customFormatScore,
    int? indexerFlags,
    String? releaseType,
    @Default(<SonarrImportRejection>[]) List<SonarrImportRejection> rejections,
  }) = _SonarrManualImport;

  factory SonarrManualImport.fromJson(Map<String, dynamic> json) =>
      _$SonarrManualImportFromJson(json);
}

@Freezed(when: FreezedWhenOptions.none, map: FreezedMapOptions.none)
abstract class SonarrMediaCover with _$SonarrMediaCover {
  const factory SonarrMediaCover({
    String? coverType,
    String? url,
    String? remoteUrl,
  }) = _SonarrMediaCover;

  factory SonarrMediaCover.fromJson(Map<String, dynamic> json) =>
      _$SonarrMediaCoverFromJson(json);
}

@Freezed(when: FreezedWhenOptions.none, map: FreezedMapOptions.none)
abstract class SonarrMediaInfo with _$SonarrMediaInfo {
  const factory SonarrMediaInfo({
    @Default(0) int id,
    int? audioBitrate,
    double? audioChannels,
    String? audioCodec,
    String? audioLanguages,
    int? audioStreamCount,
    int? videoBitDepth,
    int? videoBitrate,
    String? videoCodec,
    double? videoFps,
    String? videoDynamicRange,
    String? videoDynamicRangeType,
    String? resolution,
    String? runTime,
    String? scanType,
    String? subtitles,
  }) = _SonarrMediaInfo;

  factory SonarrMediaInfo.fromJson(Map<String, dynamic> json) =>
      _$SonarrMediaInfoFromJson(json);
}

@Freezed(when: FreezedWhenOptions.none, map: FreezedMapOptions.none)
abstract class SonarrMediaManagementConfig with _$SonarrMediaManagementConfig {
  const factory SonarrMediaManagementConfig({
    @Default(0) int id,
    bool? autoUnmonitorPreviouslyDownloadedEpisodes,
    String? recycleBin,
    int? recycleBinCleanupDays,
    String? downloadPropersAndRepacks,
    bool? createEmptySeriesFolders,
    bool? deleteEmptyFolders,
    String? fileDate,
    String? rescanAfterRefresh,
    bool? setPermissionsLinux,
    String? chmodFolder,
    String? chownGroup,
    String? episodeTitleRequired,
    bool? skipFreeSpaceCheckWhenImporting,
    int? minimumFreeSpaceWhenImporting,
    bool? copyUsingHardlinks,
    bool? useScriptImport,
    String? scriptImportPath,
    bool? importExtraFiles,
    String? extraFileExtensions,
    bool? enableMediaInfo,
  }) = _SonarrMediaManagementConfig;

  factory SonarrMediaManagementConfig.fromJson(Map<String, dynamic> json) =>
      _$SonarrMediaManagementConfigFromJson(json);
}

@Freezed(when: FreezedWhenOptions.none, map: FreezedMapOptions.none)
abstract class SonarrMetadata with _$SonarrMetadata {
  const factory SonarrMetadata({
    @Default(0) int id,
    String? name,
    @Default(<SonarrField>[]) List<SonarrField> fields,
    String? implementationName,
    String? implementation,
    String? configContract,
    String? infoLink,
    SonarrProviderMessage? message,
    @Default(<int>[]) List<int> tags,
    @Default(<SonarrMetadata>[]) List<SonarrMetadata> presets,
    bool? enable,
  }) = _SonarrMetadata;

  factory SonarrMetadata.fromJson(Map<String, dynamic> json) =>
      _$SonarrMetadataFromJson(json);
}

@Freezed(when: FreezedWhenOptions.none, map: FreezedMapOptions.none)
abstract class SonarrMonitoringOptions with _$SonarrMonitoringOptions {
  const factory SonarrMonitoringOptions({
    bool? ignoreEpisodesWithFiles,
    bool? ignoreEpisodesWithoutFiles,
    String? monitor,
  }) = _SonarrMonitoringOptions;

  factory SonarrMonitoringOptions.fromJson(Map<String, dynamic> json) =>
      _$SonarrMonitoringOptionsFromJson(json);
}

@Freezed(when: FreezedWhenOptions.none, map: FreezedMapOptions.none)
abstract class SonarrNamingConfig with _$SonarrNamingConfig {
  const factory SonarrNamingConfig({
    @Default(0) int id,
    bool? renameEpisodes,
    bool? replaceIllegalCharacters,
    int? colonReplacementFormat,
    String? customColonReplacementFormat,
    int? multiEpisodeStyle,
    String? standardEpisodeFormat,
    String? dailyEpisodeFormat,
    String? animeEpisodeFormat,
    String? seriesFolderFormat,
    String? seasonFolderFormat,
    String? specialsFolderFormat,
  }) = _SonarrNamingConfig;

  factory SonarrNamingConfig.fromJson(Map<String, dynamic> json) =>
      _$SonarrNamingConfigFromJson(json);
}

@Freezed(when: FreezedWhenOptions.none, map: FreezedMapOptions.none)
abstract class SonarrNotification with _$SonarrNotification {
  const factory SonarrNotification({
    @Default(0) int id,
    String? name,
    @Default(<SonarrField>[]) List<SonarrField> fields,
    String? implementationName,
    String? implementation,
    String? configContract,
    String? infoLink,
    SonarrProviderMessage? message,
    @Default(<int>[]) List<int> tags,
    @Default(<SonarrNotification>[]) List<SonarrNotification> presets,
    String? link,
    bool? onGrab,
    bool? onDownload,
    bool? onUpgrade,
    bool? onImportComplete,
    bool? onRename,
    bool? onSeriesAdd,
    bool? onSeriesDelete,
    bool? onEpisodeFileDelete,
    bool? onEpisodeFileDeleteForUpgrade,
    bool? onHealthIssue,
    bool? includeHealthWarnings,
    bool? onHealthRestored,
    bool? onApplicationUpdate,
    bool? onManualInteractionRequired,
    bool? supportsOnGrab,
    bool? supportsOnDownload,
    bool? supportsOnUpgrade,
    bool? supportsOnImportComplete,
    bool? supportsOnRename,
    bool? supportsOnSeriesAdd,
    bool? supportsOnSeriesDelete,
    bool? supportsOnEpisodeFileDelete,
    bool? supportsOnEpisodeFileDeleteForUpgrade,
    bool? supportsOnHealthIssue,
    bool? supportsOnHealthRestored,
    bool? supportsOnApplicationUpdate,
    bool? supportsOnManualInteractionRequired,
    String? testCommand,
  }) = _SonarrNotification;

  factory SonarrNotification.fromJson(Map<String, dynamic> json) =>
      _$SonarrNotificationFromJson(json);
}

@Freezed(when: FreezedWhenOptions.none, map: FreezedMapOptions.none)
abstract class SonarrParse with _$SonarrParse {
  const factory SonarrParse({
    @Default(0) int id,
    String? title,
    SonarrParsedEpisodeInfo? parsedEpisodeInfo,
    SonarrSeries? series,
    @Default(<SonarrEpisode>[]) List<SonarrEpisode> episodes,
    @Default(<SonarrLanguage>[]) List<SonarrLanguage> languages,
    @Default(<SonarrCustomFormat>[]) List<SonarrCustomFormat> customFormats,
    int? customFormatScore,
  }) = _SonarrParse;

  factory SonarrParse.fromJson(Map<String, dynamic> json) =>
      _$SonarrParseFromJson(json);
}

@Freezed(when: FreezedWhenOptions.none, map: FreezedMapOptions.none)
abstract class SonarrParsedEpisodeInfo with _$SonarrParsedEpisodeInfo {
  const factory SonarrParsedEpisodeInfo({
    String? releaseTitle,
    String? seriesTitle,
    SonarrSeriesTitleInfo? seriesTitleInfo,
    SonarrQuality? quality,
    int? seasonNumber,
    @Default(<int>[]) List<int> episodeNumbers,
    @Default(<int>[]) List<int> absoluteEpisodeNumbers,
    @Default(<double>[]) List<double> specialAbsoluteEpisodeNumbers,
    String? airDate,
    @Default(<SonarrLanguage>[]) List<SonarrLanguage> languages,
    bool? fullSeason,
    bool? isPartialSeason,
    bool? isMultiSeason,
    bool? isSeasonExtra,
    bool? isSplitEpisode,
    bool? isMiniSeries,
    bool? special,
    String? releaseGroup,
    String? releaseHash,
    int? seasonPart,
    String? releaseTokens,
    int? dailyPart,
    bool? isDaily,
    bool? isAbsoluteNumbering,
    bool? isPossibleSpecialEpisode,
    bool? isPossibleSceneSeasonSpecial,
    String? releaseType,
  }) = _SonarrParsedEpisodeInfo;

  factory SonarrParsedEpisodeInfo.fromJson(Map<String, dynamic> json) =>
      _$SonarrParsedEpisodeInfoFromJson(json);
}

@Freezed(when: FreezedWhenOptions.none, map: FreezedMapOptions.none)
abstract class SonarrPing with _$SonarrPing {
  const factory SonarrPing({
    String? status,
  }) = _SonarrPing;

  factory SonarrPing.fromJson(Map<String, dynamic> json) =>
      _$SonarrPingFromJson(json);
}

@Freezed(when: FreezedWhenOptions.none, map: FreezedMapOptions.none)
abstract class SonarrProfileFormatItem with _$SonarrProfileFormatItem {
  const factory SonarrProfileFormatItem({
    @Default(0) int id,
    int? format,
    String? name,
    int? score,
  }) = _SonarrProfileFormatItem;

  factory SonarrProfileFormatItem.fromJson(Map<String, dynamic> json) =>
      _$SonarrProfileFormatItemFromJson(json);
}

@Freezed(when: FreezedWhenOptions.none, map: FreezedMapOptions.none)
abstract class SonarrProviderMessage with _$SonarrProviderMessage {
  const factory SonarrProviderMessage({
    String? message,
    String? type,
  }) = _SonarrProviderMessage;

  factory SonarrProviderMessage.fromJson(Map<String, dynamic> json) =>
      _$SonarrProviderMessageFromJson(json);
}

@Freezed(when: FreezedWhenOptions.none, map: FreezedMapOptions.none)
abstract class SonarrQuality with _$SonarrQuality {
  const factory SonarrQuality({
    @Default(0) int id,
    String? name,
    String? source,
    int? resolution,
  }) = _SonarrQuality;

  factory SonarrQuality.fromJson(Map<String, dynamic> json) =>
      _$SonarrQualityFromJson(json);
}

@Freezed(when: FreezedWhenOptions.none, map: FreezedMapOptions.none)
abstract class SonarrQualityDefinitionLimits with _$SonarrQualityDefinitionLimits {
  const factory SonarrQualityDefinitionLimits({
    int? min,
    int? max,
  }) = _SonarrQualityDefinitionLimits;

  factory SonarrQualityDefinitionLimits.fromJson(Map<String, dynamic> json) =>
      _$SonarrQualityDefinitionLimitsFromJson(json);
}

@Freezed(when: FreezedWhenOptions.none, map: FreezedMapOptions.none)
abstract class SonarrQualityDefinition with _$SonarrQualityDefinition {
  const factory SonarrQualityDefinition({
    @Default(0) int id,
    SonarrQuality? quality,
    String? title,
    int? weight,
    double? minSize,
    double? maxSize,
    double? preferredSize,
  }) = _SonarrQualityDefinition;

  factory SonarrQualityDefinition.fromJson(Map<String, dynamic> json) =>
      _$SonarrQualityDefinitionFromJson(json);
}

@Freezed(when: FreezedWhenOptions.none, map: FreezedMapOptions.none)
abstract class SonarrQualityProfileQualityItem with _$SonarrQualityProfileQualityItem {
  const factory SonarrQualityProfileQualityItem({
    @Default(0) int id,
    String? name,
    SonarrQuality? quality,
    @Default(<SonarrQualityProfileQualityItem>[]) List<SonarrQualityProfileQualityItem> items,
    bool? allowed,
  }) = _SonarrQualityProfileQualityItem;

  factory SonarrQualityProfileQualityItem.fromJson(Map<String, dynamic> json) =>
      _$SonarrQualityProfileQualityItemFromJson(json);
}

@Freezed(when: FreezedWhenOptions.none, map: FreezedMapOptions.none)
abstract class SonarrQualityProfile with _$SonarrQualityProfile {
  const factory SonarrQualityProfile({
    @Default(0) int id,
    String? name,
    bool? upgradeAllowed,
    int? cutoff,
    @Default(<SonarrQualityProfileQualityItem>[]) List<SonarrQualityProfileQualityItem> items,
    int? minFormatScore,
    int? cutoffFormatScore,
    int? minUpgradeFormatScore,
    @Default(<SonarrProfileFormatItem>[]) List<SonarrProfileFormatItem> formatItems,
  }) = _SonarrQualityProfile;

  factory SonarrQualityProfile.fromJson(Map<String, dynamic> json) =>
      _$SonarrQualityProfileFromJson(json);
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
abstract class SonarrQueue with _$SonarrQueue {
  const factory SonarrQueue({
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
    SonarrQueueStatus? status,
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
  }) = _SonarrQueue;

  factory SonarrQueue.fromJson(Map<String, dynamic> json) =>
      _$SonarrQueueFromJson(json);
}

@Freezed(when: FreezedWhenOptions.none, map: FreezedMapOptions.none)
abstract class SonarrQueueResourcePaging with _$SonarrQueueResourcePaging {
  const factory SonarrQueueResourcePaging({
    int? page,
    int? pageSize,
    String? sortKey,
    String? sortDirection,
    int? totalRecords,
    @Default(<SonarrQueue>[]) List<SonarrQueue> records,
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
abstract class SonarrRatings with _$SonarrRatings {
  const factory SonarrRatings({
    int? votes,
    double? value,
  }) = _SonarrRatings;

  factory SonarrRatings.fromJson(Map<String, dynamic> json) =>
      _$SonarrRatingsFromJson(json);
}

@Freezed(when: FreezedWhenOptions.none, map: FreezedMapOptions.none)
abstract class SonarrReleaseEpisode with _$SonarrReleaseEpisode {
  const factory SonarrReleaseEpisode({
    @Default(0) int id,
    int? seasonNumber,
    int? episodeNumber,
    int? absoluteEpisodeNumber,
    String? title,
  }) = _SonarrReleaseEpisode;

  factory SonarrReleaseEpisode.fromJson(Map<String, dynamic> json) =>
      _$SonarrReleaseEpisodeFromJson(json);
}

@Freezed(when: FreezedWhenOptions.none, map: FreezedMapOptions.none)
abstract class SonarrReleaseProfile with _$SonarrReleaseProfile {
  const factory SonarrReleaseProfile({
    @Default(0) int id,
    String? name,
    bool? enabled,
    dynamic? required,
    dynamic? ignored,
    int? indexerId,
    @Default(<int>[]) List<int> tags,
  }) = _SonarrReleaseProfile;

  factory SonarrReleaseProfile.fromJson(Map<String, dynamic> json) =>
      _$SonarrReleaseProfileFromJson(json);
}

@Freezed(when: FreezedWhenOptions.none, map: FreezedMapOptions.none)
abstract class SonarrRelease with _$SonarrRelease {
  const factory SonarrRelease({
    @Default(0) int id,
    String? guid,
    SonarrQuality? quality,
    int? qualityWeight,
    int? age,
    double? ageHours,
    double? ageMinutes,
    int? size,
    int? indexerId,
    String? indexer,
    String? releaseGroup,
    String? subGroup,
    String? releaseHash,
    String? title,
    bool? fullSeason,
    bool? sceneSource,
    int? seasonNumber,
    @Default(<SonarrLanguage>[]) List<SonarrLanguage> languages,
    int? languageWeight,
    String? airDate,
    String? seriesTitle,
    @Default(<int>[]) List<int> episodeNumbers,
    @Default(<int>[]) List<int> absoluteEpisodeNumbers,
    int? mappedSeasonNumber,
    @Default(<int>[]) List<int> mappedEpisodeNumbers,
    @Default(<int>[]) List<int> mappedAbsoluteEpisodeNumbers,
    int? mappedSeriesId,
    @Default(<SonarrReleaseEpisode>[]) List<SonarrReleaseEpisode> mappedEpisodeInfo,
    bool? approved,
    bool? temporarilyRejected,
    bool? rejected,
    int? tvdbId,
    int? tvRageId,
    String? imdbId,
    @Default(<String>[]) List<String> rejections,
    String? publishDate,
    String? commentUrl,
    String? downloadUrl,
    String? infoUrl,
    bool? episodeRequested,
    bool? downloadAllowed,
    int? releaseWeight,
    @Default(<SonarrCustomFormat>[]) List<SonarrCustomFormat> customFormats,
    int? customFormatScore,
    SonarrAlternateTitle? sceneMapping,
    String? magnetUrl,
    String? infoHash,
    int? seeders,
    int? leechers,
    String? protocol,
    int? indexerFlags,
    bool? isDaily,
    bool? isAbsoluteNumbering,
    bool? isPossibleSpecialEpisode,
    bool? special,
    int? seriesId,
    int? episodeId,
    @Default(<int>[]) List<int> episodeIds,
    int? downloadClientId,
    String? downloadClient,
    bool? shouldOverride,
  }) = _SonarrRelease;

  factory SonarrRelease.fromJson(Map<String, dynamic> json) =>
      _$SonarrReleaseFromJson(json);
}

@Freezed(when: FreezedWhenOptions.none, map: FreezedMapOptions.none)
abstract class SonarrRemotePathMapping with _$SonarrRemotePathMapping {
  const factory SonarrRemotePathMapping({
    @Default(0) int id,
    String? host,
    String? remotePath,
    String? localPath,
  }) = _SonarrRemotePathMapping;

  factory SonarrRemotePathMapping.fromJson(Map<String, dynamic> json) =>
      _$SonarrRemotePathMappingFromJson(json);
}

@Freezed(when: FreezedWhenOptions.none, map: FreezedMapOptions.none)
abstract class SonarrRenameEpisode with _$SonarrRenameEpisode {
  const factory SonarrRenameEpisode({
    @Default(0) int id,
    int? seriesId,
    int? seasonNumber,
    @Default(<int>[]) List<int> episodeNumbers,
    int? episodeFileId,
    String? existingPath,
    String? newPath,
  }) = _SonarrRenameEpisode;

  factory SonarrRenameEpisode.fromJson(Map<String, dynamic> json) =>
      _$SonarrRenameEpisodeFromJson(json);
}

@Freezed(when: FreezedWhenOptions.none, map: FreezedMapOptions.none)
abstract class SonarrRevision with _$SonarrRevision {
  const factory SonarrRevision({
    int? version,
    int? real,
    bool? isRepack,
  }) = _SonarrRevision;

  factory SonarrRevision.fromJson(Map<String, dynamic> json) =>
      _$SonarrRevisionFromJson(json);
}

@Freezed(when: FreezedWhenOptions.none, map: FreezedMapOptions.none)
abstract class SonarrRootFolder with _$SonarrRootFolder {
  const factory SonarrRootFolder({
    @Default(0) int id,
    String? path,
    bool? accessible,
    int? freeSpace,
    @Default(<SonarrUnmappedFolder>[]) List<SonarrUnmappedFolder> unmappedFolders,
  }) = _SonarrRootFolder;

  factory SonarrRootFolder.fromJson(Map<String, dynamic> json) =>
      _$SonarrRootFolderFromJson(json);
}

@Freezed(when: FreezedWhenOptions.none, map: FreezedMapOptions.none)
abstract class SonarrSeasonPass with _$SonarrSeasonPass {
  const factory SonarrSeasonPass({
    @Default(<SonarrSeasonPassSeries>[]) List<SonarrSeasonPassSeries> series,
    SonarrMonitoringOptions? monitoringOptions,
  }) = _SonarrSeasonPass;

  factory SonarrSeasonPass.fromJson(Map<String, dynamic> json) =>
      _$SonarrSeasonPassFromJson(json);
}

@Freezed(when: FreezedWhenOptions.none, map: FreezedMapOptions.none)
abstract class SonarrSeasonPassSeries with _$SonarrSeasonPassSeries {
  const factory SonarrSeasonPassSeries({
    @Default(0) int id,
    @Default(false) bool monitored,
    @Default(<SonarrSeason>[]) List<SonarrSeason> seasons,
  }) = _SonarrSeasonPassSeries;

  factory SonarrSeasonPassSeries.fromJson(Map<String, dynamic> json) =>
      _$SonarrSeasonPassSeriesFromJson(json);
}

@Freezed(when: FreezedWhenOptions.none, map: FreezedMapOptions.none)
abstract class SonarrSeason with _$SonarrSeason {
  const factory SonarrSeason({
    int? seasonNumber,
    @Default(false) bool monitored,
    SonarrSeasonStatistics? statistics,
    @Default(<SonarrMediaCover>[]) List<SonarrMediaCover> images,
  }) = _SonarrSeason;

  factory SonarrSeason.fromJson(Map<String, dynamic> json) =>
      _$SonarrSeasonFromJson(json);
}

@Freezed(when: FreezedWhenOptions.none, map: FreezedMapOptions.none)
abstract class SonarrSeasonStatistics with _$SonarrSeasonStatistics {
  const factory SonarrSeasonStatistics({
    String? nextAiring,
    String? previousAiring,
    int? episodeFileCount,
    int? episodeCount,
    int? totalEpisodeCount,
    int? sizeOnDisk,
    @Default(<String>[]) List<String> releaseGroups,
    double? percentOfEpisodes,
  }) = _SonarrSeasonStatistics;

  factory SonarrSeasonStatistics.fromJson(Map<String, dynamic> json) =>
      _$SonarrSeasonStatisticsFromJson(json);
}

@Freezed(when: FreezedWhenOptions.none, map: FreezedMapOptions.none)
abstract class SonarrSelectOption with _$SonarrSelectOption {
  const factory SonarrSelectOption({
    int? value,
    String? name,
    int? order,
    String? hint,
  }) = _SonarrSelectOption;

  factory SonarrSelectOption.fromJson(Map<String, dynamic> json) =>
      _$SonarrSelectOptionFromJson(json);
}

@Freezed(when: FreezedWhenOptions.none, map: FreezedMapOptions.none)
abstract class SonarrSeriesEditor with _$SonarrSeriesEditor {
  const factory SonarrSeriesEditor({
    @Default(<int>[]) List<int> seriesIds,
    @Default(false) bool monitored,
    String? monitorNewItems,
    int? qualityProfileId,
    String? seriesType,
    bool? seasonFolder,
    String? rootFolderPath,
    @Default(<int>[]) List<int> tags,
    String? applyTags,
    bool? moveFiles,
    bool? deleteFiles,
    bool? addImportListExclusion,
  }) = _SonarrSeriesEditor;

  factory SonarrSeriesEditor.fromJson(Map<String, dynamic> json) =>
      _$SonarrSeriesEditorFromJson(json);
}

@Freezed(when: FreezedWhenOptions.none, map: FreezedMapOptions.none)
abstract class SonarrSeries with _$SonarrSeries {
  const factory SonarrSeries({
    @Default(0) int id,
    String? title,
    @Default(<SonarrAlternateTitle>[]) List<SonarrAlternateTitle> alternateTitles,
    String? sortTitle,
    String? status,
    bool? ended,
    String? profileName,
    String? overview,
    String? nextAiring,
    String? previousAiring,
    String? network,
    String? airTime,
    @Default(<SonarrMediaCover>[]) List<SonarrMediaCover> images,
    SonarrLanguage? originalLanguage,
    String? remotePoster,
    @Default(<SonarrSeason>[]) List<SonarrSeason> seasons,
    int? year,
    String? path,
    int? qualityProfileId,
    bool? seasonFolder,
    @Default(false) bool monitored,
    String? monitorNewItems,
    bool? useSceneNumbering,
    int? runtime,
    int? tvdbId,
    int? tvRageId,
    int? tvMazeId,
    int? tmdbId,
    String? firstAired,
    String? lastAired,
    String? seriesType,
    String? cleanTitle,
    String? imdbId,
    String? titleSlug,
    String? rootFolderPath,
    String? folder,
    String? certification,
    @Default(<String>[]) List<String> genres,
    @Default(<int>[]) List<int> tags,
    String? added,
    SonarrAddSeriesOptions? addOptions,
    SonarrRatings? ratings,
    SonarrSeriesStatistics? statistics,
    bool? episodesChanged,
    int? languageProfileId,
  }) = _SonarrSeries;

  factory SonarrSeries.fromJson(Map<String, dynamic> json) =>
      _$SonarrSeriesFromJson(json);
}

@Freezed(when: FreezedWhenOptions.none, map: FreezedMapOptions.none)
abstract class SonarrSeriesStatistics with _$SonarrSeriesStatistics {
  const factory SonarrSeriesStatistics({
    int? seasonCount,
    int? episodeFileCount,
    int? episodeCount,
    int? totalEpisodeCount,
    int? sizeOnDisk,
    @Default(<String>[]) List<String> releaseGroups,
    double? percentOfEpisodes,
  }) = _SonarrSeriesStatistics;

  factory SonarrSeriesStatistics.fromJson(Map<String, dynamic> json) =>
      _$SonarrSeriesStatisticsFromJson(json);
}

@Freezed(when: FreezedWhenOptions.none, map: FreezedMapOptions.none)
abstract class SonarrSeriesTitleInfo with _$SonarrSeriesTitleInfo {
  const factory SonarrSeriesTitleInfo({
    String? title,
    String? titleWithoutYear,
    int? year,
    @Default(<String>[]) List<String> allTitles,
  }) = _SonarrSeriesTitleInfo;

  factory SonarrSeriesTitleInfo.fromJson(Map<String, dynamic> json) =>
      _$SonarrSeriesTitleInfoFromJson(json);
}

@Freezed(when: FreezedWhenOptions.none, map: FreezedMapOptions.none)
abstract class SonarrSystem with _$SonarrSystem {
  const factory SonarrSystem({
    String? appName,
    String? instanceName,
    String? version,
    String? buildTime,
    bool? isDebug,
    bool? isProduction,
    bool? isAdmin,
    bool? isUserInteractive,
    String? startupPath,
    String? appData,
    String? osName,
    String? osVersion,
    bool? isNetCore,
    bool? isLinux,
    bool? isOsx,
    bool? isWindows,
    bool? isDocker,
    String? mode,
    String? branch,
    String? authentication,
    String? sqliteVersion,
    int? migrationVersion,
    String? urlBase,
    String? runtimeVersion,
    String? runtimeName,
    String? startTime,
    String? packageVersion,
    String? packageAuthor,
    String? packageUpdateMechanism,
    String? packageUpdateMechanismMessage,
    String? databaseVersion,
    String? databaseType,
  }) = _SonarrSystem;

  factory SonarrSystem.fromJson(Map<String, dynamic> json) =>
      _$SonarrSystemFromJson(json);
}

@Freezed(when: FreezedWhenOptions.none, map: FreezedMapOptions.none)
abstract class SonarrTagDetails with _$SonarrTagDetails {
  const factory SonarrTagDetails({
    @Default(0) int id,
    String? label,
    @Default(<int>[]) List<int> delayProfileIds,
    @Default(<int>[]) List<int> importListIds,
    @Default(<int>[]) List<int> notificationIds,
    @Default(<int>[]) List<int> restrictionIds,
    @Default(<int>[]) List<int> indexerIds,
    @Default(<int>[]) List<int> downloadClientIds,
    @Default(<int>[]) List<int> autoTagIds,
    @Default(<int>[]) List<int> seriesIds,
  }) = _SonarrTagDetails;

  factory SonarrTagDetails.fromJson(Map<String, dynamic> json) =>
      _$SonarrTagDetailsFromJson(json);
}

@Freezed(when: FreezedWhenOptions.none, map: FreezedMapOptions.none)
abstract class SonarrTag with _$SonarrTag {
  const factory SonarrTag({
    @Default(0) int id,
    String? label,
  }) = _SonarrTag;

  factory SonarrTag.fromJson(Map<String, dynamic> json) =>
      _$SonarrTagFromJson(json);
}

@Freezed(when: FreezedWhenOptions.none, map: FreezedMapOptions.none)
abstract class SonarrTask with _$SonarrTask {
  const factory SonarrTask({
    @Default(0) int id,
    String? name,
    String? taskName,
    int? interval,
    String? lastExecution,
    String? lastStartTime,
    String? nextExecution,
    String? lastDuration,
  }) = _SonarrTask;

  factory SonarrTask.fromJson(Map<String, dynamic> json) =>
      _$SonarrTaskFromJson(json);
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

@Freezed(when: FreezedWhenOptions.none, map: FreezedMapOptions.none)
abstract class SonarrUiConfig with _$SonarrUiConfig {
  const factory SonarrUiConfig({
    @Default(0) int id,
    int? firstDayOfWeek,
    String? calendarWeekColumnHeader,
    String? shortDateFormat,
    String? longDateFormat,
    String? timeFormat,
    bool? showRelativeDates,
    bool? enableColorImpairedMode,
    String? theme,
    int? uiLanguage,
  }) = _SonarrUiConfig;

  factory SonarrUiConfig.fromJson(Map<String, dynamic> json) =>
      _$SonarrUiConfigFromJson(json);
}

@Freezed(when: FreezedWhenOptions.none, map: FreezedMapOptions.none)
abstract class SonarrUnmappedFolder with _$SonarrUnmappedFolder {
  const factory SonarrUnmappedFolder({
    String? name,
    String? path,
    String? relativePath,
  }) = _SonarrUnmappedFolder;

  factory SonarrUnmappedFolder.fromJson(Map<String, dynamic> json) =>
      _$SonarrUnmappedFolderFromJson(json);
}

@Freezed(when: FreezedWhenOptions.none, map: FreezedMapOptions.none)
abstract class SonarrUpdateChanges with _$SonarrUpdateChanges {
  const factory SonarrUpdateChanges({
    @JsonKey(name: 'new') @Default(<String>[]) List<String> newValue,
    @Default(<String>[]) List<String> fixed,
  }) = _SonarrUpdateChanges;

  factory SonarrUpdateChanges.fromJson(Map<String, dynamic> json) =>
      _$SonarrUpdateChangesFromJson(json);
}

@Freezed(when: FreezedWhenOptions.none, map: FreezedMapOptions.none)
abstract class SonarrUpdate with _$SonarrUpdate {
  const factory SonarrUpdate({
    @Default(0) int id,
    String? version,
    String? branch,
    String? releaseDate,
    String? fileName,
    String? url,
    bool? installed,
    String? installedOn,
    bool? installable,
    bool? latest,
    SonarrUpdateChanges? changes,
    String? hash,
  }) = _SonarrUpdate;

  factory SonarrUpdate.fromJson(Map<String, dynamic> json) =>
      _$SonarrUpdateFromJson(json);
}
