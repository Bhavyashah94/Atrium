import 'package:freezed_annotation/freezed_annotation.dart';

import 'sonarr_config_models.dart';
import 'sonarr_episode_models.dart';
import 'sonarr_series_models.dart';
import 'sonarr_system_models.dart';

part 'sonarr_release_models.freezed.dart';
part 'sonarr_release_models.g.dart';

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
abstract class SonarrReleaseProfile with _$SonarrReleaseProfile {
  const factory SonarrReleaseProfile({
    @Default(0) int id,
    String? name,
    bool? enabled,
    dynamic required,
    dynamic ignored,
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
