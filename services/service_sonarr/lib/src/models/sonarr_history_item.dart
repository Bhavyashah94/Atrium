import 'package:freezed_annotation/freezed_annotation.dart';

import 'sonarr_episode.dart';
import 'sonarr_series.dart';

part 'sonarr_history_item.freezed.dart';
part 'sonarr_history_item.g.dart';

@Freezed(when: FreezedWhenOptions.none, map: FreezedMapOptions.none)
abstract class SonarrHistoryItem with _$SonarrHistoryItem {
  const factory SonarrHistoryItem({
    required int id,
    int? episodeId,
    int? seriesId,
    String? sourceTitle,
    String? date,
    String? downloadId,
    String? eventType,
    Map<String, dynamic>? data,
    SonarrEpisode? episode,
    SonarrSeries? series,
    @Default(<SonarrLanguage>[]) List<SonarrLanguage> languages,
    Map<String, dynamic>? quality,
    @Default(<Map<String, dynamic>>[]) List<Map<String, dynamic>> customFormats,
    int? customFormatScore,
    bool? qualityCutoffNotMet,
  }) = _SonarrHistoryItem;

  factory SonarrHistoryItem.fromJson(Map<String, dynamic> json) =>
      _$SonarrHistoryItemFromJson(json);
}
