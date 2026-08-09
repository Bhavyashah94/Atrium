// AUTO-GENERATED FROM v2.json OpenAPI Specification
// DO NOT EDIT DIRECTLY. Run `dart run tool/generate_tracearr_models.dart` to update.

import 'package:freezed_annotation/freezed_annotation.dart';

part 'tracearr_v2_models.freezed.dart';
part 'tracearr_v2_models.g.dart';

const double kTracearrCompletionThreshold = 90.0;

/// HTTP Response status codes defined across v2.json paths
enum TracearrV2ApiStatus {
  ok(200, 'Specification retrieved'),
  badRequest(400, 'Invalid query parameters or cursor, or since is after until'),
  unauthorized(401, 'Invalid or missing API key'),
  forbidden(403, 'API key is not associated with an owner account'),
  notFound(404, 'No media matches the ref'),
  rateLimited(429, 'Rate limit exceeded for this key\'s shared budget across the whole v2 surface'),
  unknown(-1, 'Unknown response status');

  const TracearrV2ApiStatus(this.statusCode, this.description);
  final int statusCode;
  final String description;

  static TracearrV2ApiStatus fromStatusCode(int? code) {
    return TracearrV2ApiStatus.values.firstWhere(
      (TracearrV2ApiStatus e) => e.statusCode == code,
      orElse: () => TracearrV2ApiStatus.unknown,
    );
  }
}

typedef TracearrV2Library = TracearrV2LibraryRollup;
typedef TracearrV2RecentlyAddedItem = TracearrV2RecentlyAddedRecord;
typedef TracearrV2MediaDetails = TracearrV2MediaResource;

Object? _flexibleIntReader(Map<dynamic, dynamic> json, String key) {
  final Object? val = json[key];
  if (val is String) {
    final int? parsedInt = int.tryParse(val);
    if (parsedInt != null) return parsedInt;
    final double? parsedDouble = double.tryParse(val);
    if (parsedDouble != null) return parsedDouble.toInt();
  }
  return val;
}

Object? _flexibleDoubleReader(Map<dynamic, dynamic> json, String key) {
  final Object? val = json[key];
  if (val is String) {
    return double.tryParse(val);
  }
  return val;
}

/// HistoryResponse from v2.json
@freezed
abstract class TracearrV2HistoryResponse with _$TracearrV2HistoryResponse {
  const TracearrV2HistoryResponse._();

  const factory TracearrV2HistoryResponse({
    @JsonKey(name: 'data') @Default(<TracearrV2HistoryRecord>[]) List<TracearrV2HistoryRecord> data,
    @JsonKey(name: 'meta') TracearrV2CursorMeta? meta,
  }) = _TracearrV2HistoryResponse;

  factory TracearrV2HistoryResponse.fromJson(Map<String, dynamic> json) =>
      _$TracearrV2HistoryResponseFromJson(json);
}

/// HistoryRecord from v2.json
@freezed
abstract class TracearrV2HistoryRecord with _$TracearrV2HistoryRecord {
  const TracearrV2HistoryRecord._();

  const factory TracearrV2HistoryRecord({
    @JsonKey(name: 'id') String? id,
    @JsonKey(name: 'server_id') String? serverId,
    @JsonKey(name: 'server_name') String? serverName,
    @JsonKey(name: 'server_type') String? serverType,
    @JsonKey(name: 'state') String? state,
    @JsonKey(name: 'media_type') String? mediaType,
    @JsonKey(name: 'media_title') String? mediaTitle,
    @JsonKey(name: 'show_title') String? showTitle,
    @JsonKey(name: 'season_number', readValue: _flexibleIntReader) int? seasonNumber,
    @JsonKey(name: 'episode_number', readValue: _flexibleIntReader) int? episodeNumber,
    @JsonKey(name: 'year', readValue: _flexibleIntReader) int? year,
    @JsonKey(name: 'artist_name') String? artistName,
    @JsonKey(name: 'album_name') String? albumName,
    @JsonKey(name: 'track_number', readValue: _flexibleIntReader) int? trackNumber,
    @JsonKey(name: 'disc_number', readValue: _flexibleIntReader) int? discNumber,
    @JsonKey(name: 'thumb_path') String? thumbPath,
    @JsonKey(name: 'poster_url') String? posterUrl,
    @JsonKey(name: 'duration_ms', readValue: _flexibleIntReader) int? durationMs,
    @JsonKey(name: 'progress_ms', readValue: _flexibleIntReader) int? progressMs,
    @JsonKey(name: 'total_duration_ms', readValue: _flexibleIntReader) int? totalDurationMs,
    @JsonKey(name: 'percent_complete', readValue: _flexibleDoubleReader) double? percentComplete,
    @JsonKey(name: 'started_at') String? startedAt,
    @JsonKey(name: 'stopped_at') String? stoppedAt,
    @JsonKey(name: 'watched') bool? watched,
    @JsonKey(name: 'segment_count', readValue: _flexibleIntReader) int? segmentCount,
    @JsonKey(name: 'device') String? device,
    @JsonKey(name: 'player') String? player,
    @JsonKey(name: 'product') String? product,
    @JsonKey(name: 'platform') String? platform,
    @JsonKey(name: 'is_transcode') bool? isTranscode,
    @JsonKey(name: 'video_decision') String? videoDecision,
    @JsonKey(name: 'audio_decision') String? audioDecision,
    @JsonKey(name: 'bitrate', readValue: _flexibleIntReader) int? bitrate,
    @JsonKey(name: 'source_video_codec') String? sourceVideoCodec,
    @JsonKey(name: 'source_audio_codec') String? sourceAudioCodec,
    @JsonKey(name: 'source_audio_channels', readValue: _flexibleIntReader) int? sourceAudioChannels,
    @JsonKey(name: 'source_video_width', readValue: _flexibleIntReader) int? sourceVideoWidth,
    @JsonKey(name: 'source_video_height', readValue: _flexibleIntReader) int? sourceVideoHeight,
    @JsonKey(name: 'source_video_details') TracearrV2SourceVideoDetails? sourceVideoDetails,
    @JsonKey(name: 'source_audio_details') TracearrV2SourceAudioDetails? sourceAudioDetails,
    @JsonKey(name: 'stream_video_codec') String? streamVideoCodec,
    @JsonKey(name: 'stream_audio_codec') String? streamAudioCodec,
    @JsonKey(name: 'stream_video_details') TracearrV2StreamVideoDetails? streamVideoDetails,
    @JsonKey(name: 'stream_audio_details') TracearrV2StreamAudioDetails? streamAudioDetails,
    @JsonKey(name: 'transcode_info') TracearrV2TranscodeInfo? transcodeInfo,
    @JsonKey(name: 'subtitle_info') TracearrV2SubtitleInfo? subtitleInfo,
    @JsonKey(name: 'resolution') String? resolution,
    @JsonKey(name: 'source_video_codec_display') String? sourceVideoCodecDisplay,
    @JsonKey(name: 'source_audio_codec_display') String? sourceAudioCodecDisplay,
    @JsonKey(name: 'audio_channels_display') String? audioChannelsDisplay,
    @JsonKey(name: 'stream_video_codec_display') String? streamVideoCodecDisplay,
    @JsonKey(name: 'stream_audio_codec_display') String? streamAudioCodecDisplay,
    @JsonKey(name: 'media_id') String? mediaId,
    @JsonKey(name: 'show_media_id') String? showMediaId,
    @JsonKey(name: 'imdb_id') String? imdbId,
    @JsonKey(name: 'tmdb_id', readValue: _flexibleIntReader) int? tmdbId,
    @JsonKey(name: 'tvdb_id', readValue: _flexibleIntReader) int? tvdbId,
    @JsonKey(name: 'rating_key') String? ratingKey,
    @JsonKey(name: 'parent_rating_key') String? parentRatingKey,
    @JsonKey(name: 'grandparent_rating_key') String? grandparentRatingKey,
    @JsonKey(name: 'library_id') String? libraryId,
    @JsonKey(name: 'genres') @Default(<String>[]) List<String> genres,
    @JsonKey(name: 'reference_id') String? referenceId,
    @JsonKey(name: 'user') TracearrV2HistoryUser? user,
  }) = _TracearrV2HistoryRecord;

  String? get effectiveUsername => user?.username;
  String? get effectiveUserId => user?.id;
  String? get effectiveUserAvatar => user?.avatarUrl;
  String? get effectivePlayedAt => startedAt;
  int? get effectiveDurationSeconds => durationMs != null ? durationMs! ~/ 1000 : null;
  bool get effectiveCompleted => watched ?? (percentComplete != null && percentComplete! >= kTracearrCompletionThreshold);

  factory TracearrV2HistoryRecord.fromJson(Map<String, dynamic> json) =>
      _$TracearrV2HistoryRecordFromJson(json);
}

/// SourceVideoDetails from v2.json
@freezed
abstract class TracearrV2SourceVideoDetails with _$TracearrV2SourceVideoDetails {
  const TracearrV2SourceVideoDetails._();

  const factory TracearrV2SourceVideoDetails({
    @JsonKey(name: 'bitrate', readValue: _flexibleDoubleReader) double? bitrate,
    @JsonKey(name: 'framerate') String? framerate,
    @JsonKey(name: 'dynamicRange') String? dynamicRange,
    @JsonKey(name: 'aspectRatio', readValue: _flexibleDoubleReader) double? aspectRatio,
    @JsonKey(name: 'profile') String? profile,
    @JsonKey(name: 'level') String? level,
    @JsonKey(name: 'colorSpace') String? colorSpace,
    @JsonKey(name: 'colorDepth', readValue: _flexibleDoubleReader) double? colorDepth,
  }) = _TracearrV2SourceVideoDetails;

  factory TracearrV2SourceVideoDetails.fromJson(Map<String, dynamic> json) =>
      _$TracearrV2SourceVideoDetailsFromJson(json);
}

/// SourceAudioDetails from v2.json
@freezed
abstract class TracearrV2SourceAudioDetails with _$TracearrV2SourceAudioDetails {
  const TracearrV2SourceAudioDetails._();

  const factory TracearrV2SourceAudioDetails({
    @JsonKey(name: 'bitrate', readValue: _flexibleDoubleReader) double? bitrate,
    @JsonKey(name: 'channelLayout') String? channelLayout,
    @JsonKey(name: 'language') String? language,
    @JsonKey(name: 'sampleRate', readValue: _flexibleDoubleReader) double? sampleRate,
  }) = _TracearrV2SourceAudioDetails;

  factory TracearrV2SourceAudioDetails.fromJson(Map<String, dynamic> json) =>
      _$TracearrV2SourceAudioDetailsFromJson(json);
}

/// StreamVideoDetails from v2.json
@freezed
abstract class TracearrV2StreamVideoDetails with _$TracearrV2StreamVideoDetails {
  const TracearrV2StreamVideoDetails._();

  const factory TracearrV2StreamVideoDetails({
    @JsonKey(name: 'bitrate', readValue: _flexibleDoubleReader) double? bitrate,
    @JsonKey(name: 'width', readValue: _flexibleDoubleReader) double? width,
    @JsonKey(name: 'height', readValue: _flexibleDoubleReader) double? height,
    @JsonKey(name: 'framerate') String? framerate,
    @JsonKey(name: 'dynamicRange') String? dynamicRange,
  }) = _TracearrV2StreamVideoDetails;

  factory TracearrV2StreamVideoDetails.fromJson(Map<String, dynamic> json) =>
      _$TracearrV2StreamVideoDetailsFromJson(json);
}

/// StreamAudioDetails from v2.json
@freezed
abstract class TracearrV2StreamAudioDetails with _$TracearrV2StreamAudioDetails {
  const TracearrV2StreamAudioDetails._();

  const factory TracearrV2StreamAudioDetails({
    @JsonKey(name: 'bitrate', readValue: _flexibleDoubleReader) double? bitrate,
    @JsonKey(name: 'channels', readValue: _flexibleDoubleReader) double? channels,
    @JsonKey(name: 'language') String? language,
  }) = _TracearrV2StreamAudioDetails;

  factory TracearrV2StreamAudioDetails.fromJson(Map<String, dynamic> json) =>
      _$TracearrV2StreamAudioDetailsFromJson(json);
}

/// TranscodeInfo from v2.json
@freezed
abstract class TracearrV2TranscodeInfo with _$TracearrV2TranscodeInfo {
  const TracearrV2TranscodeInfo._();

  const factory TracearrV2TranscodeInfo({
    @JsonKey(name: 'containerDecision') String? containerDecision,
    @JsonKey(name: 'sourceContainer') String? sourceContainer,
    @JsonKey(name: 'streamContainer') String? streamContainer,
    @JsonKey(name: 'hwRequested') bool? hwRequested,
    @JsonKey(name: 'hwDecoding') String? hwDecoding,
    @JsonKey(name: 'hwEncoding') String? hwEncoding,
    @JsonKey(name: 'speed', readValue: _flexibleDoubleReader) double? speed,
    @JsonKey(name: 'throttled') bool? throttled,
    @JsonKey(name: 'reasons') @Default(<String>[]) List<String> reasons,
  }) = _TracearrV2TranscodeInfo;

  factory TracearrV2TranscodeInfo.fromJson(Map<String, dynamic> json) =>
      _$TracearrV2TranscodeInfoFromJson(json);
}

/// SubtitleInfo from v2.json
@freezed
abstract class TracearrV2SubtitleInfo with _$TracearrV2SubtitleInfo {
  const TracearrV2SubtitleInfo._();

  const factory TracearrV2SubtitleInfo({
    @JsonKey(name: 'decision') String? decision,
    @JsonKey(name: 'codec') String? codec,
    @JsonKey(name: 'language') String? language,
    @JsonKey(name: 'forced') bool? forced,
  }) = _TracearrV2SubtitleInfo;

  factory TracearrV2SubtitleInfo.fromJson(Map<String, dynamic> json) =>
      _$TracearrV2SubtitleInfoFromJson(json);
}

/// HistoryUser from v2.json
@freezed
abstract class TracearrV2HistoryUser with _$TracearrV2HistoryUser {
  const TracearrV2HistoryUser._();

  const factory TracearrV2HistoryUser({
    @JsonKey(name: 'id') String? id,
    @JsonKey(name: 'username') String? username,
    @JsonKey(name: 'thumb_url') String? thumbUrl,
    @JsonKey(name: 'avatar_url') String? avatarUrl,
  }) = _TracearrV2HistoryUser;

  factory TracearrV2HistoryUser.fromJson(Map<String, dynamic> json) =>
      _$TracearrV2HistoryUserFromJson(json);
}

/// CursorMeta from v2.json
@freezed
abstract class TracearrV2CursorMeta with _$TracearrV2CursorMeta {
  const TracearrV2CursorMeta._();

  const factory TracearrV2CursorMeta({
    @JsonKey(name: 'nextCursor') String? nextCursor,
    @JsonKey(name: 'pageSize', readValue: _flexibleIntReader) int? pageSize,
  }) = _TracearrV2CursorMeta;

  factory TracearrV2CursorMeta.fromJson(Map<String, dynamic> json) =>
      _$TracearrV2CursorMetaFromJson(json);
}

/// StreamsResponse from v2.json
@freezed
abstract class TracearrV2StreamsResponse with _$TracearrV2StreamsResponse {
  const TracearrV2StreamsResponse._();

  const factory TracearrV2StreamsResponse({
    @JsonKey(name: 'data') @Default(<TracearrV2ActiveStream>[]) List<TracearrV2ActiveStream> data,
    @JsonKey(name: 'summary') TracearrV2StreamsSummary? summary,
  }) = _TracearrV2StreamsResponse;

  factory TracearrV2StreamsResponse.fromJson(Map<String, dynamic> json) =>
      _$TracearrV2StreamsResponseFromJson(json);
}

/// ActiveStream from v2.json
@freezed
abstract class TracearrV2ActiveStream with _$TracearrV2ActiveStream {
  const TracearrV2ActiveStream._();

  const factory TracearrV2ActiveStream({
    @JsonKey(name: 'id') String? id,
    @JsonKey(name: 'server_id') String? serverId,
    @JsonKey(name: 'server_name') String? serverName,
    @JsonKey(name: 'server_type') String? serverType,
    @JsonKey(name: 'username') String? username,
    @JsonKey(name: 'user_thumb') String? userThumb,
    @JsonKey(name: 'user_avatar_url') String? userAvatarUrl,
    @JsonKey(name: 'media_type') String? mediaType,
    @JsonKey(name: 'media_title') String? mediaTitle,
    @JsonKey(name: 'show_title') String? showTitle,
    @JsonKey(name: 'season_number', readValue: _flexibleIntReader) int? seasonNumber,
    @JsonKey(name: 'episode_number', readValue: _flexibleIntReader) int? episodeNumber,
    @JsonKey(name: 'year', readValue: _flexibleIntReader) int? year,
    @JsonKey(name: 'artist_name') String? artistName,
    @JsonKey(name: 'album_name') String? albumName,
    @JsonKey(name: 'track_number', readValue: _flexibleIntReader) int? trackNumber,
    @JsonKey(name: 'disc_number', readValue: _flexibleIntReader) int? discNumber,
    @JsonKey(name: 'thumb_path') String? thumbPath,
    @JsonKey(name: 'poster_url') String? posterUrl,
    @JsonKey(name: 'duration_ms', readValue: _flexibleIntReader) int? durationMs,
    @JsonKey(name: 'state') String? state,
    @JsonKey(name: 'progress_ms', readValue: _flexibleIntReader) int? progressMs,
    @JsonKey(name: 'started_at') String? startedAt,
    @JsonKey(name: 'is_transcode') bool? isTranscode,
    @JsonKey(name: 'video_decision') String? videoDecision,
    @JsonKey(name: 'audio_decision') String? audioDecision,
    @JsonKey(name: 'bitrate', readValue: _flexibleIntReader) int? bitrate,
    @JsonKey(name: 'source_video_codec') String? sourceVideoCodec,
    @JsonKey(name: 'source_audio_codec') String? sourceAudioCodec,
    @JsonKey(name: 'source_audio_channels', readValue: _flexibleIntReader) int? sourceAudioChannels,
    @JsonKey(name: 'source_video_width', readValue: _flexibleIntReader) int? sourceVideoWidth,
    @JsonKey(name: 'source_video_height', readValue: _flexibleIntReader) int? sourceVideoHeight,
    @JsonKey(name: 'source_video_details') TracearrV2SourceVideoDetails? sourceVideoDetails,
    @JsonKey(name: 'source_audio_details') TracearrV2SourceAudioDetails? sourceAudioDetails,
    @JsonKey(name: 'stream_video_codec') String? streamVideoCodec,
    @JsonKey(name: 'stream_audio_codec') String? streamAudioCodec,
    @JsonKey(name: 'stream_video_details') TracearrV2StreamVideoDetails? streamVideoDetails,
    @JsonKey(name: 'stream_audio_details') TracearrV2StreamAudioDetails? streamAudioDetails,
    @JsonKey(name: 'transcode_info') TracearrV2TranscodeInfo? transcodeInfo,
    @JsonKey(name: 'subtitle_info') TracearrV2SubtitleInfo? subtitleInfo,
    @JsonKey(name: 'resolution') String? resolution,
    @JsonKey(name: 'source_video_codec_display') String? sourceVideoCodecDisplay,
    @JsonKey(name: 'source_audio_codec_display') String? sourceAudioCodecDisplay,
    @JsonKey(name: 'audio_channels_display') String? audioChannelsDisplay,
    @JsonKey(name: 'stream_video_codec_display') String? streamVideoCodecDisplay,
    @JsonKey(name: 'stream_audio_codec_display') String? streamAudioCodecDisplay,
    @JsonKey(name: 'device') String? device,
    @JsonKey(name: 'player') String? player,
    @JsonKey(name: 'product') String? product,
    @JsonKey(name: 'platform') String? platform,
    @JsonKey(name: 'media_id') String? mediaId,
    @JsonKey(name: 'show_media_id') String? showMediaId,
    @JsonKey(name: 'imdb_id') String? imdbId,
    @JsonKey(name: 'tmdb_id', readValue: _flexibleIntReader) int? tmdbId,
    @JsonKey(name: 'tvdb_id', readValue: _flexibleIntReader) int? tvdbId,
    @JsonKey(name: 'rating_key') String? ratingKey,
    @JsonKey(name: 'parent_rating_key') String? parentRatingKey,
    @JsonKey(name: 'grandparent_rating_key') String? grandparentRatingKey,
    @JsonKey(name: 'library_id') String? libraryId,
    @JsonKey(name: 'genres') @Default(<String>[]) List<String> genres,
  }) = _TracearrV2ActiveStream;

  String? get effectiveUsername => username;
  String? get effectiveShowTitle => showTitle;
  String? get effectivePlayer => player;
  String? get effectiveDevice => device;
  String? get effectivePlatform => platform;

  factory TracearrV2ActiveStream.fromJson(Map<String, dynamic> json) =>
      _$TracearrV2ActiveStreamFromJson(json);
}

/// StreamsSummary from v2.json
@freezed
abstract class TracearrV2StreamsSummary with _$TracearrV2StreamsSummary {
  const TracearrV2StreamsSummary._();

  const factory TracearrV2StreamsSummary({
    @JsonKey(name: 'total', readValue: _flexibleIntReader) int? total,
    @JsonKey(name: 'transcodes', readValue: _flexibleIntReader) int? transcodes,
    @JsonKey(name: 'direct_streams', readValue: _flexibleIntReader) int? directStreams,
    @JsonKey(name: 'direct_plays', readValue: _flexibleIntReader) int? directPlays,
    @JsonKey(name: 'total_bitrate') String? totalBitrate,
    @JsonKey(name: 'by_server') @Default(<TracearrV2StreamsServerSummary>[]) List<TracearrV2StreamsServerSummary> byServer,
  }) = _TracearrV2StreamsSummary;

  factory TracearrV2StreamsSummary.fromJson(Map<String, dynamic> json) =>
      _$TracearrV2StreamsSummaryFromJson(json);
}

/// StreamsServerSummary from v2.json
@freezed
abstract class TracearrV2StreamsServerSummary with _$TracearrV2StreamsServerSummary {
  const TracearrV2StreamsServerSummary._();

  const factory TracearrV2StreamsServerSummary({
    @JsonKey(name: 'server_id') String? serverId,
    @JsonKey(name: 'server_name') String? serverName,
    @JsonKey(name: 'total', readValue: _flexibleIntReader) int? total,
    @JsonKey(name: 'transcodes', readValue: _flexibleIntReader) int? transcodes,
    @JsonKey(name: 'direct_streams', readValue: _flexibleIntReader) int? directStreams,
    @JsonKey(name: 'direct_plays', readValue: _flexibleIntReader) int? directPlays,
    @JsonKey(name: 'total_bitrate') String? totalBitrate,
  }) = _TracearrV2StreamsServerSummary;

  factory TracearrV2StreamsServerSummary.fromJson(Map<String, dynamic> json) =>
      _$TracearrV2StreamsServerSummaryFromJson(json);
}

/// MediaResource from v2.json
@freezed
abstract class TracearrV2MediaResource with _$TracearrV2MediaResource {
  const TracearrV2MediaResource._();

  const factory TracearrV2MediaResource({
    @JsonKey(name: 'id') String? id,
    @JsonKey(name: 'media_type') String? mediaType,
    @JsonKey(name: 'title') String? title,
    @JsonKey(name: 'year', readValue: _flexibleIntReader) int? year,
    @JsonKey(name: 'imdb_id') String? imdbId,
    @JsonKey(name: 'tmdb_id', readValue: _flexibleIntReader) int? tmdbId,
    @JsonKey(name: 'tvdb_id', readValue: _flexibleIntReader) int? tvdbId,
    @JsonKey(name: 'genres') @Default(<String>[]) List<String> genres,
    @JsonKey(name: 'show_media_id') String? showMediaId,
    @JsonKey(name: 'merged_ids') @Default(<String>[]) List<String> mergedIds,
    @JsonKey(name: 'availability') @Default(<TracearrV2MediaAvailability>[]) List<TracearrV2MediaAvailability> availability,
    @JsonKey(name: 'season_count', readValue: _flexibleIntReader) int? seasonCount,
    @JsonKey(name: 'episode_count', readValue: _flexibleIntReader) int? episodeCount,
    @JsonKey(name: 'poster_url') String? posterUrl,
    @JsonKey(name: 'thumb_path') String? thumbPath,
  }) = _TracearrV2MediaResource;

  factory TracearrV2MediaResource.fromJson(Map<String, dynamic> json) =>
      _$TracearrV2MediaResourceFromJson(json);
}

/// MediaAvailability from v2.json
@freezed
abstract class TracearrV2MediaAvailability with _$TracearrV2MediaAvailability {
  const TracearrV2MediaAvailability._();

  const factory TracearrV2MediaAvailability({
    @JsonKey(name: 'server_id') String? serverId,
    @JsonKey(name: 'server_type') String? serverType,
    @JsonKey(name: 'library_id') String? libraryId,
    @JsonKey(name: 'rating_key') String? ratingKey,
    @JsonKey(name: 'added_at') String? addedAt,
    @JsonKey(name: 'removed_at') String? removedAt,
    @JsonKey(name: 'video_resolution') String? videoResolution,
    @JsonKey(name: 'file_size', readValue: _flexibleIntReader) int? fileSize,
    @JsonKey(name: 'versions') @Default(<TracearrV2MediaVersion>[]) List<TracearrV2MediaVersion> versions,
  }) = _TracearrV2MediaAvailability;

  factory TracearrV2MediaAvailability.fromJson(Map<String, dynamic> json) =>
      _$TracearrV2MediaAvailabilityFromJson(json);
}

/// MediaVersion from v2.json
@freezed
abstract class TracearrV2MediaVersion with _$TracearrV2MediaVersion {
  const TracearrV2MediaVersion._();

  const factory TracearrV2MediaVersion({
    @JsonKey(name: 'resolution') String? resolution,
    @JsonKey(name: 'video_codec') String? videoCodec,
    @JsonKey(name: 'audio_codec') String? audioCodec,
    @JsonKey(name: 'dynamic_range') String? dynamicRange,
    @JsonKey(name: 'container') String? container,
    @JsonKey(name: 'file_size', readValue: _flexibleIntReader) int? fileSize,
  }) = _TracearrV2MediaVersion;

  factory TracearrV2MediaVersion.fromJson(Map<String, dynamic> json) =>
      _$TracearrV2MediaVersionFromJson(json);
}

/// MediaChildrenResponse from v2.json
@freezed
abstract class TracearrV2MediaChildrenResponse with _$TracearrV2MediaChildrenResponse {
  const TracearrV2MediaChildrenResponse._();

  const factory TracearrV2MediaChildrenResponse({
    @JsonKey(name: 'data') @Default(<TracearrV2MediaChild>[]) List<TracearrV2MediaChild> data,
  }) = _TracearrV2MediaChildrenResponse;

  factory TracearrV2MediaChildrenResponse.fromJson(Map<String, dynamic> json) =>
      _$TracearrV2MediaChildrenResponseFromJson(json);
}

/// MediaChild from v2.json
@freezed
abstract class TracearrV2MediaChild with _$TracearrV2MediaChild {
  const TracearrV2MediaChild._();

  const factory TracearrV2MediaChild({
    @JsonKey(name: 'id') String? id,
    @JsonKey(name: 'media_type') String? mediaType,
    @JsonKey(name: 'title') String? title,
    @JsonKey(name: 'season_number', readValue: _flexibleIntReader) int? seasonNumber,
    @JsonKey(name: 'episode_count', readValue: _flexibleIntReader) int? episodeCount,
    @JsonKey(name: 'episode_number', readValue: _flexibleIntReader) int? episodeNumber,
    @JsonKey(name: 'imdb_id') String? imdbId,
    @JsonKey(name: 'tmdb_id', readValue: _flexibleIntReader) int? tmdbId,
    @JsonKey(name: 'tvdb_id', readValue: _flexibleIntReader) int? tvdbId,
    @JsonKey(name: 'show_media_id') String? showMediaId,
    @JsonKey(name: 'genres') @Default(<String>[]) List<String> genres,
  }) = _TracearrV2MediaChild;

  factory TracearrV2MediaChild.fromJson(Map<String, dynamic> json) =>
      _$TracearrV2MediaChildFromJson(json);
}

/// MediaStatsResponse from v2.json
@freezed
abstract class TracearrV2MediaStatsResponse with _$TracearrV2MediaStatsResponse {
  const TracearrV2MediaStatsResponse._();

  const factory TracearrV2MediaStatsResponse({
    @JsonKey(name: 'media_id') String? mediaId,
    @JsonKey(name: 'media_type') String? mediaType,
    @JsonKey(name: 'windows') Map<String, dynamic>? windows,
  }) = _TracearrV2MediaStatsResponse;

  factory TracearrV2MediaStatsResponse.fromJson(Map<String, dynamic> json) =>
      _$TracearrV2MediaStatsResponseFromJson(json);
}

/// StatWindow from v2.json
@freezed
abstract class TracearrV2StatWindow with _$TracearrV2StatWindow {
  const TracearrV2StatWindow._();

  const factory TracearrV2StatWindow({
    @JsonKey(name: 'combined') Map<String, dynamic>? combined,
    @JsonKey(name: 'per_server') @Default(<TracearrV2StatServerMeasures>[]) List<TracearrV2StatServerMeasures> perServer,
  }) = _TracearrV2StatWindow;

  factory TracearrV2StatWindow.fromJson(Map<String, dynamic> json) =>
      _$TracearrV2StatWindowFromJson(json);
}

/// StatServerMeasures from v2.json
@freezed
abstract class TracearrV2StatServerMeasures with _$TracearrV2StatServerMeasures {
  const TracearrV2StatServerMeasures._();

  const factory TracearrV2StatServerMeasures({
    @JsonKey(name: 'server_id') String? serverId,
    @JsonKey(name: 'server_name') String? serverName,
    @JsonKey(name: 'plays', readValue: _flexibleIntReader) int? plays,
    @JsonKey(name: 'watch_time_ms', readValue: _flexibleIntReader) int? watchTimeMs,
    @JsonKey(name: 'unique_users', readValue: _flexibleIntReader) int? uniqueUsers,
  }) = _TracearrV2StatServerMeasures;

  factory TracearrV2StatServerMeasures.fromJson(Map<String, dynamic> json) =>
      _$TracearrV2StatServerMeasuresFromJson(json);
}

/// MediaWatchersResponse from v2.json
@freezed
abstract class TracearrV2MediaWatchersResponse with _$TracearrV2MediaWatchersResponse {
  const TracearrV2MediaWatchersResponse._();

  const factory TracearrV2MediaWatchersResponse({
    @JsonKey(name: 'media_id') String? mediaId,
    @JsonKey(name: 'media_type') String? mediaType,
    @JsonKey(name: 'window') String? window,
    @JsonKey(name: 'watchers') @Default(<TracearrV2Watcher>[]) List<TracearrV2Watcher> watchers,
  }) = _TracearrV2MediaWatchersResponse;

  factory TracearrV2MediaWatchersResponse.fromJson(Map<String, dynamic> json) =>
      _$TracearrV2MediaWatchersResponseFromJson(json);
}

/// Watcher from v2.json
@freezed
abstract class TracearrV2Watcher with _$TracearrV2Watcher {
  const TracearrV2Watcher._();

  const factory TracearrV2Watcher({
    @JsonKey(name: 'user') TracearrV2WatcherUser? user,
    @JsonKey(name: 'plays', readValue: _flexibleIntReader) int? plays,
    @JsonKey(name: 'watch_time_ms', readValue: _flexibleIntReader) int? watchTimeMs,
    @JsonKey(name: 'completion_pct', readValue: _flexibleDoubleReader) double? completionPct,
    @JsonKey(name: 'last_watched_day') String? lastWatchedDay,
    @JsonKey(name: 'distinct_episodes_watched', readValue: _flexibleIntReader) int? distinctEpisodesWatched,
  }) = _TracearrV2Watcher;

  factory TracearrV2Watcher.fromJson(Map<String, dynamic> json) =>
      _$TracearrV2WatcherFromJson(json);
}

/// WatcherUser from v2.json
@freezed
abstract class TracearrV2WatcherUser with _$TracearrV2WatcherUser {
  const TracearrV2WatcherUser._();

  const factory TracearrV2WatcherUser({
    @JsonKey(name: 'server_user_id') String? serverUserId,
    @JsonKey(name: 'user_id') String? userId,
    @JsonKey(name: 'username') String? username,
    @JsonKey(name: 'identity_name') String? identityName,
  }) = _TracearrV2WatcherUser;

  factory TracearrV2WatcherUser.fromJson(Map<String, dynamic> json) =>
      _$TracearrV2WatcherUserFromJson(json);
}

/// UsersResponse from v2.json
@freezed
abstract class TracearrV2UsersResponse with _$TracearrV2UsersResponse {
  const TracearrV2UsersResponse._();

  const factory TracearrV2UsersResponse({
    @JsonKey(name: 'data') @Default(<TracearrV2UserIdentity>[]) List<TracearrV2UserIdentity> data,
    @JsonKey(name: 'meta') TracearrV2CursorMeta? meta,
  }) = _TracearrV2UsersResponse;

  factory TracearrV2UsersResponse.fromJson(Map<String, dynamic> json) =>
      _$TracearrV2UsersResponseFromJson(json);
}

/// UserIdentity from v2.json
@freezed
abstract class TracearrV2UserIdentity with _$TracearrV2UserIdentity {
  const TracearrV2UserIdentity._();

  const factory TracearrV2UserIdentity({
    @JsonKey(name: 'id') String? id,
    @JsonKey(name: 'username') String? username,
    @JsonKey(name: 'email') String? email,
    @JsonKey(name: 'plex_account_id') String? plexAccountId,
    @JsonKey(name: 'accounts') @Default(<TracearrV2UserAccount>[]) List<TracearrV2UserAccount> accounts,
  }) = _TracearrV2UserIdentity;

  factory TracearrV2UserIdentity.fromJson(Map<String, dynamic> json) =>
      _$TracearrV2UserIdentityFromJson(json);
}

/// UserAccount from v2.json
@freezed
abstract class TracearrV2UserAccount with _$TracearrV2UserAccount {
  const TracearrV2UserAccount._();

  const factory TracearrV2UserAccount({
    @JsonKey(name: 'server_id') String? serverId,
    @JsonKey(name: 'server_type') String? serverType,
    @JsonKey(name: 'server_user_id') String? serverUserId,
    @JsonKey(name: 'external_user_id') String? externalUserId,
    @JsonKey(name: 'username') String? username,
    @JsonKey(name: 'removed_at') String? removedAt,
  }) = _TracearrV2UserAccount;

  factory TracearrV2UserAccount.fromJson(Map<String, dynamic> json) =>
      _$TracearrV2UserAccountFromJson(json);
}

/// UserStatsResponse from v2.json
@freezed
abstract class TracearrV2UserStatsResponse with _$TracearrV2UserStatsResponse {
  const TracearrV2UserStatsResponse._();

  const factory TracearrV2UserStatsResponse({
    @JsonKey(name: 'user_id') String? userId,
    @JsonKey(name: 'windows') Map<String, dynamic>? windows,
    @JsonKey(name: 'top_genres') @Default(<TracearrV2UserGenre>[]) List<TracearrV2UserGenre> topGenres,
  }) = _TracearrV2UserStatsResponse;

  factory TracearrV2UserStatsResponse.fromJson(Map<String, dynamic> json) =>
      _$TracearrV2UserStatsResponseFromJson(json);
}

/// UserGenre from v2.json
@freezed
abstract class TracearrV2UserGenre with _$TracearrV2UserGenre {
  const TracearrV2UserGenre._();

  const factory TracearrV2UserGenre({
    @JsonKey(name: 'genre') String? genre,
    @JsonKey(name: 'plays', readValue: _flexibleIntReader) int? plays,
  }) = _TracearrV2UserGenre;

  factory TracearrV2UserGenre.fromJson(Map<String, dynamic> json) =>
      _$TracearrV2UserGenreFromJson(json);
}

/// RecentlyAddedResponse from v2.json
@freezed
abstract class TracearrV2RecentlyAddedResponse with _$TracearrV2RecentlyAddedResponse {
  const TracearrV2RecentlyAddedResponse._();

  const factory TracearrV2RecentlyAddedResponse({
    @JsonKey(name: 'data') @Default(<TracearrV2RecentlyAddedRecord>[]) List<TracearrV2RecentlyAddedRecord> data,
    @JsonKey(name: 'meta') TracearrV2CursorMeta? meta,
  }) = _TracearrV2RecentlyAddedResponse;

  factory TracearrV2RecentlyAddedResponse.fromJson(Map<String, dynamic> json) =>
      _$TracearrV2RecentlyAddedResponseFromJson(json);
}

/// RecentlyAddedRecord from v2.json
@freezed
abstract class TracearrV2RecentlyAddedRecord with _$TracearrV2RecentlyAddedRecord {
  const TracearrV2RecentlyAddedRecord._();

  const factory TracearrV2RecentlyAddedRecord({
    @JsonKey(name: 'id') String? id,
    @JsonKey(name: 'server_id') String? serverId,
    @JsonKey(name: 'server_type') String? serverType,
    @JsonKey(name: 'library_id') String? libraryId,
    @JsonKey(name: 'media_type') String? mediaType,
    @JsonKey(name: 'title') String? title,
    @JsonKey(name: 'year', readValue: _flexibleIntReader) int? year,
    @JsonKey(name: 'added_at') String? addedAt,
    @JsonKey(name: 'removed_at') String? removedAt,
    @JsonKey(name: 'media_id') String? mediaId,
    @JsonKey(name: 'imdb_id') String? imdbId,
    @JsonKey(name: 'tmdb_id', readValue: _flexibleIntReader) int? tmdbId,
    @JsonKey(name: 'tvdb_id', readValue: _flexibleIntReader) int? tvdbId,
    @JsonKey(name: 'rating_key') String? ratingKey,
    @JsonKey(name: 'parent_rating_key') String? parentRatingKey,
    @JsonKey(name: 'grandparent_rating_key') String? grandparentRatingKey,
    @JsonKey(name: 'poster_url') String? posterUrl,
    @JsonKey(name: 'thumb_path') String? thumbPath,
  }) = _TracearrV2RecentlyAddedRecord;

  String get type => mediaType ?? 'movie';

  factory TracearrV2RecentlyAddedRecord.fromJson(Map<String, dynamic> json) =>
      _$TracearrV2RecentlyAddedRecordFromJson(json);
}

/// LibrariesResponse from v2.json
@freezed
abstract class TracearrV2LibrariesResponse with _$TracearrV2LibrariesResponse {
  const TracearrV2LibrariesResponse._();

  const factory TracearrV2LibrariesResponse({
    @JsonKey(name: 'data') @Default(<TracearrV2LibraryRollup>[]) List<TracearrV2LibraryRollup> data,
  }) = _TracearrV2LibrariesResponse;

  factory TracearrV2LibrariesResponse.fromJson(Map<String, dynamic> json) =>
      _$TracearrV2LibrariesResponseFromJson(json);
}

/// LibraryRollup from v2.json
@freezed
abstract class TracearrV2LibraryRollup with _$TracearrV2LibraryRollup {
  const TracearrV2LibraryRollup._();

  const factory TracearrV2LibraryRollup({
    @JsonKey(name: 'server_id') String? serverId,
    @JsonKey(name: 'server_type') String? serverType,
    @JsonKey(name: 'library_id') String? libraryId,
    @JsonKey(name: 'item_count', readValue: _flexibleIntReader) int? itemCount,
    @JsonKey(name: 'movie_count', readValue: _flexibleIntReader) int? movieCount,
    @JsonKey(name: 'episode_count', readValue: _flexibleIntReader) int? episodeCount,
    @JsonKey(name: 'show_count', readValue: _flexibleIntReader) int? showCount,
    @JsonKey(name: 'track_count', readValue: _flexibleIntReader) int? trackCount,
    @JsonKey(name: 'total_file_size', readValue: _flexibleIntReader) int? totalFileSize,
    @JsonKey(name: 'resolutions') Map<String, dynamic>? resolutions,
    @JsonKey(name: 'library_name') String? libraryName,
    @JsonKey(name: 'name') String? nameField,
    @JsonKey(name: 'server_name') String? serverName,
  }) = _TracearrV2LibraryRollup;

  String get type => serverType ?? 'unknown';
  String get name => libraryName ?? nameField ?? libraryId ?? 'Library';

  factory TracearrV2LibraryRollup.fromJson(Map<String, dynamic> json) =>
      _$TracearrV2LibraryRollupFromJson(json);
}

/// Response descriptions per API endpoint path in v2.json
class TracearrV2EndpointResponses {
  const TracearrV2EndpointResponses._();

  static const Map<String, Map<int, String>> catalog = <String, Map<int, String>>{
    'GET /api/v2/public/docs': <int, String>{
      200: 'Specification retrieved',
      401: 'Invalid or missing API key',
      403: 'API key is not associated with an owner account',
      429: 'Rate limit exceeded for this key\'s shared budget across the whole v2 surface',
    },
    'GET /api/v2/public/history': <int, String>{
      200: 'History retrieved',
      400: 'Invalid query parameters or cursor, or since is after until',
      401: 'Invalid or missing API key',
      403: 'API key is not associated with an owner account',
      429: 'Rate limit exceeded for this key\'s shared budget across the whole v2 surface',
    },
    'GET /api/v2/public/streams': <int, String>{
      200: 'Active streams retrieved',
      400: 'Invalid query parameters',
      401: 'Invalid or missing API key',
      403: 'API key is not associated with an owner account',
      429: 'Rate limit exceeded for this key\'s shared budget across the whole v2 surface',
    },
    'GET /api/v2/public/media/{ref}': <int, String>{
      200: 'Media resolved',
      401: 'Invalid or missing API key',
      403: 'API key is not associated with an owner account',
      404: 'No media matches the ref',
      429: 'Rate limit exceeded for this key\'s shared budget across the whole v2 surface',
    },
    'GET /api/v2/public/media/{ref}/children': <int, String>{
      200: 'Children retrieved',
      401: 'Invalid or missing API key',
      403: 'API key is not associated with an owner account',
      404: 'Ref is unknown or has no children. A season whose number cannot be derived returns 200 with an empty list instead',
      429: 'Rate limit exceeded for this key\'s shared budget across the whole v2 surface',
    },
    'GET /api/v2/public/media/{ref}/stats': <int, String>{
      200: 'Statistics retrieved',
      401: 'Invalid or missing API key',
      403: 'API key is not associated with an owner account',
      404: 'No media matches the ref',
      429: 'Rate limit exceeded for this key\'s shared budget across the whole v2 surface',
    },
    'GET /api/v2/public/media/{ref}/watchers': <int, String>{
      200: 'Watchers retrieved',
      400: 'Invalid query parameters',
      401: 'Invalid or missing API key',
      403: 'API key is not associated with an owner account',
      404: 'No media matches the ref',
      429: 'Rate limit exceeded for this key\'s shared budget across the whole v2 surface',
    },
    'GET /api/v2/public/media/{ref}/history': <int, String>{
      200: 'History retrieved',
      400: 'Invalid query parameters or cursor',
      401: 'Invalid or missing API key',
      403: 'API key is not associated with an owner account',
      404: 'No media matches the ref',
      429: 'Rate limit exceeded for this key\'s shared budget across the whole v2 surface',
    },
    'GET /api/v2/public/users': <int, String>{
      200: 'Identities retrieved',
      400: 'Invalid query parameters or cursor',
      401: 'Invalid or missing API key',
      403: 'API key is not associated with an owner account',
      429: 'Rate limit exceeded for this key\'s shared budget across the whole v2 surface',
    },
    'GET /api/v2/public/users/{id}': <int, String>{
      200: 'Identity retrieved',
      400: 'id is not a valid uuid',
      401: 'Invalid or missing API key',
      403: 'API key is not associated with an owner account',
      404: 'No identity matches the id',
      429: 'Rate limit exceeded for this key\'s shared budget across the whole v2 surface',
    },
    'GET /api/v2/public/users/{id}/stats': <int, String>{
      200: 'Statistics retrieved',
      400: 'id is not a valid uuid',
      401: 'Invalid or missing API key',
      403: 'API key is not associated with an owner account',
      404: 'No identity matches the id',
      429: 'Rate limit exceeded for this key\'s shared budget across the whole v2 surface',
    },
    'GET /api/v2/public/users/{id}/history': <int, String>{
      200: 'History retrieved',
      400: 'Invalid query parameters or cursor',
      401: 'Invalid or missing API key',
      403: 'API key is not associated with an owner account',
      404: 'No identity matches the id',
      429: 'Rate limit exceeded for this key\'s shared budget across the whole v2 surface',
    },
    'GET /api/v2/public/recently-added': <int, String>{
      200: 'Items retrieved',
      400: 'Invalid query parameters or cursor',
      401: 'Invalid or missing API key',
      403: 'API key is not associated with an owner account',
      429: 'Rate limit exceeded for this key\'s shared budget across the whole v2 surface',
    },
    'GET /api/v2/public/libraries': <int, String>{
      200: 'Rollups retrieved',
      401: 'Invalid or missing API key',
      403: 'API key is not associated with an owner account',
      429: 'Rate limit exceeded for this key\'s shared budget across the whole v2 surface',
    },
  };
}

