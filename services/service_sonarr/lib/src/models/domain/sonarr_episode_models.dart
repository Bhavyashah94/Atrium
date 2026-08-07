import 'package:freezed_annotation/freezed_annotation.dart';

import 'sonarr_series_models.dart';
import 'sonarr_activity_models.dart';
import 'sonarr_release_models.dart';
import 'sonarr_config_models.dart';
import 'sonarr_system_models.dart';

part 'sonarr_episode_models.freezed.dart';
part 'sonarr_episode_models.g.dart';

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
    @Default(0) int seriesId,
    int? tvdbId,
    int? episodeFileId,
    @Default(0) int seasonNumber,
    @Default(0) int episodeNumber,
    @Default('') String title,
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
