import 'package:freezed_annotation/freezed_annotation.dart';

import 'sonarr_system_models.dart';

part 'sonarr_series_models.freezed.dart';
part 'sonarr_series_models.g.dart';

typedef SonarrImage = SonarrMediaCover;
typedef SonarrAddOptions = SonarrAddSeriesOptions;

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
abstract class SonarrRatings with _$SonarrRatings {
  const factory SonarrRatings({
    int? votes,
    double? value,
  }) = _SonarrRatings;

  factory SonarrRatings.fromJson(Map<String, dynamic> json) =>
      _$SonarrRatingsFromJson(json);
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
    @Default('') String title,
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
