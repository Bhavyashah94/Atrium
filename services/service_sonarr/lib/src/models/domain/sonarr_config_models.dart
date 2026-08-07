import 'package:freezed_annotation/freezed_annotation.dart';

import 'sonarr_episode_models.dart';
import 'sonarr_series_models.dart';
import 'sonarr_system_models.dart';

part 'sonarr_config_models.freezed.dart';
part 'sonarr_config_models.g.dart';

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
