import 'package:freezed_annotation/freezed_annotation.dart';

part 'sonarr_series.freezed.dart';
part 'sonarr_series.g.dart';

@Freezed(when: FreezedWhenOptions.none, map: FreezedMapOptions.none)
abstract class SonarrSeries with _$SonarrSeries {
  const factory SonarrSeries({
    @Default(0) int id,
    required String title,
    String? sortTitle,
    String? status,
    String? overview,
    String? network,
    int? year,
    @Default(false) bool monitored,
    @Default(<SonarrImage>[]) List<SonarrImage> images,
    @Default(<SonarrSeason>[]) List<SonarrSeason> seasons,
    SonarrSeriesStatistics? statistics,
    String? seriesType,
    int? runtime,
    String? certification,
    @Default(<String>[]) List<String> genres,
    String? path,
    String? nextAiring,
    String? previousAiring,
    int? tvdbId,
    String? titleSlug,
    String? added,
    int? qualityProfileId,
    int? languageProfileId,
    @Default(<int>[]) List<int> tags,
    bool? seasonFolder,
    String? rootFolderPath,
    String? imdbId,
    int? tmdbId,
    int? tvMazeId,
    int? tvRageId,
    String? airTime,
    String? cleanTitle,
    bool? ended,
    bool? episodesChanged,
    String? firstAired,
    String? folder,
    String? lastAired,
    String? monitorNewItems,
    SonarrLanguage? originalLanguage,
    String? profileName,
    SonarrRatings? ratings,
    String? remotePoster,
    bool? useSceneNumbering,
    @Default(<SonarrAlternateTitle>[]) List<SonarrAlternateTitle> alternateTitles,
    SonarrAddOptions? addOptions,
  }) = _SonarrSeries;

  factory SonarrSeries.fromJson(Map<String, dynamic> json) =>
      _$SonarrSeriesFromJson(json);
}

@Freezed(when: FreezedWhenOptions.none, map: FreezedMapOptions.none)
abstract class SonarrImage with _$SonarrImage {
  const factory SonarrImage({
    required String coverType,
    String? remoteUrl,
    String? url,
  }) = _SonarrImage;

  factory SonarrImage.fromJson(Map<String, dynamic> json) =>
      _$SonarrImageFromJson(json);
}

@Freezed(when: FreezedWhenOptions.none, map: FreezedMapOptions.none)
abstract class SonarrSeason with _$SonarrSeason {
  const factory SonarrSeason({
    @Default(0) int seasonNumber,
    @Default(false) bool monitored,
    SonarrSeasonStatistics? statistics,
  }) = _SonarrSeason;

  factory SonarrSeason.fromJson(Map<String, dynamic> json) =>
      _$SonarrSeasonFromJson(json);
}

@Freezed(when: FreezedWhenOptions.none, map: FreezedMapOptions.none)
abstract class SonarrSeasonStatistics with _$SonarrSeasonStatistics {
  const factory SonarrSeasonStatistics({
    @Default(0) int episodeFileCount,
    @Default(0) int episodeCount,
    @Default(0) int totalEpisodeCount,
    @Default(0) int sizeOnDisk,
  }) = _SonarrSeasonStatistics;

  factory SonarrSeasonStatistics.fromJson(Map<String, dynamic> json) =>
      _$SonarrSeasonStatisticsFromJson(json);
}

@Freezed(when: FreezedWhenOptions.none, map: FreezedMapOptions.none)
abstract class SonarrSeriesStatistics with _$SonarrSeriesStatistics {
  const factory SonarrSeriesStatistics({
    @Default(0) int seasonCount,
    @Default(0) int episodeFileCount,
    @Default(0) int episodeCount,
    @Default(0) int totalEpisodeCount,
    @Default(0) int sizeOnDisk,
  }) = _SonarrSeriesStatistics;

  factory SonarrSeriesStatistics.fromJson(Map<String, dynamic> json) =>
      _$SonarrSeriesStatisticsFromJson(json);
}

@Freezed(when: FreezedWhenOptions.none, map: FreezedMapOptions.none)
abstract class SonarrAlternateTitle with _$SonarrAlternateTitle {
  const factory SonarrAlternateTitle({
    String? title,
    int? seasonNumber,
    int? sceneSeasonNumber,
    String? sceneOrigin,
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
abstract class SonarrAddOptions with _$SonarrAddOptions {
  const factory SonarrAddOptions({
    bool? ignoreEpisodesWithFiles,
    bool? ignoreEpisodesWithoutFiles,
    String? monitor,
    bool? searchForMissingEpisodes,
  }) = _SonarrAddOptions;

  factory SonarrAddOptions.fromJson(Map<String, dynamic> json) =>
      _$SonarrAddOptionsFromJson(json);
}

@Freezed(when: FreezedWhenOptions.none, map: FreezedMapOptions.none)
abstract class SonarrLanguage with _$SonarrLanguage {
  const factory SonarrLanguage({
    int? id,
    String? name,
  }) = _SonarrLanguage;

  factory SonarrLanguage.fromJson(Map<String, dynamic> json) =>
      _$SonarrLanguageFromJson(json);
}
