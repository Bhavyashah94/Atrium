import 'package:freezed_annotation/freezed_annotation.dart';

import 'sonarr_series_models.dart';
import 'sonarr_episode_models.dart';
import 'sonarr_activity_models.dart';
import 'sonarr_release_models.dart';
import 'sonarr_config_models.dart';

part 'sonarr_system_models.freezed.dart';
part 'sonarr_system_models.g.dart';

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
abstract class SonarrLanguage with _$SonarrLanguage {
  const factory SonarrLanguage({
    @Default(0) int id,
    String? name,
  }) = _SonarrLanguage;

  factory SonarrLanguage.fromJson(Map<String, dynamic> json) =>
      _$SonarrLanguageFromJson(json);
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
abstract class SonarrPing with _$SonarrPing {
  const factory SonarrPing({
    String? status,
  }) = _SonarrPing;

  factory SonarrPing.fromJson(Map<String, dynamic> json) =>
      _$SonarrPingFromJson(json);
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
