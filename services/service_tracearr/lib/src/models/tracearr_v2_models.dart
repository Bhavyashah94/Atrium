import 'package:freezed_annotation/freezed_annotation.dart';

part 'tracearr_v2_models.freezed.dart';
part 'tracearr_v2_models.g.dart';

/// Cursor pagination metadata from v2.json
@freezed
abstract class TracearrV2CursorMeta with _$TracearrV2CursorMeta {
  const factory TracearrV2CursorMeta({
    String? nextCursor,
    int? pageSize,
    @Default(false) bool hasMore,
  }) = _TracearrV2CursorMeta;

  factory TracearrV2CursorMeta.fromJson(Map<String, dynamic> json) =>
      _$TracearrV2CursorMetaFromJson(json);
}

/// Active playback stream summary per server
@freezed
abstract class TracearrV2StreamsServerSummary
    with _$TracearrV2StreamsServerSummary {
  const factory TracearrV2StreamsServerSummary({
    @JsonKey(name: 'server_id') String? serverId,
    @JsonKey(name: 'server_name') String? serverName,
    @Default(0) int total,
    @Default(0) int transcodes,
    @JsonKey(name: 'direct_streams') @Default(0) int directStreams,
    @JsonKey(name: 'direct_plays') @Default(0) int directPlays,
    @JsonKey(name: 'total_bitrate') String? totalBitrate,
  }) = _TracearrV2StreamsServerSummary;

  factory TracearrV2StreamsServerSummary.fromJson(Map<String, dynamic> json) =>
      _$TracearrV2StreamsServerSummaryFromJson(json);
}

/// Active playback streams overall summary
@freezed
abstract class TracearrV2StreamsSummary with _$TracearrV2StreamsSummary {
  const factory TracearrV2StreamsSummary({
    @Default(0) int total,
    @Default(0) int transcodes,
    @JsonKey(name: 'direct_streams') @Default(0) int directStreams,
    @JsonKey(name: 'direct_plays') @Default(0) int directPlays,
    @JsonKey(name: 'total_bitrate') String? totalBitrate,
    @JsonKey(name: 'by_server')
    @Default(<TracearrV2StreamsServerSummary>[])
    List<TracearrV2StreamsServerSummary> byServer,
  }) = _TracearrV2StreamsSummary;

  factory TracearrV2StreamsSummary.fromJson(Map<String, dynamic> json) =>
      _$TracearrV2StreamsSummaryFromJson(json);
}

/// Active playback stream from GET /api/v2/public/streams
@freezed
abstract class TracearrV2Stream with _$TracearrV2Stream {
  const factory TracearrV2Stream({
    required String id,
    @JsonKey(name: 'session_id') String? sessionId,
    @JsonKey(name: 'server_id') String? serverId,
    @JsonKey(name: 'server_name') String? serverName,
    @JsonKey(name: 'user_id') String? userId,
    @JsonKey(name: 'user_name') String? userName,
    @JsonKey(name: 'user_avatar') String? userAvatar,
    @JsonKey(name: 'user_avatar_url') String? userAvatarUrl,
    @JsonKey(name: 'media_title') String? mediaTitle,
    @JsonKey(name: 'media_type') String? mediaType,
    @JsonKey(name: 'grandparent_title') String? grandparentTitle,
    @JsonKey(name: 'parent_title') String? parentTitle,
    @JsonKey(name: 'poster_url') String? posterUrl,
    @JsonKey(name: 'progress_percent') double? progressPercent,
    @JsonKey(name: 'progress_ms') int? progressMs,
    @JsonKey(name: 'duration_ms') int? durationMs,
    String? state,
    @JsonKey(name: 'started_at') String? startedAt,
    @JsonKey(name: 'player_name') String? playerName,
    @JsonKey(name: 'device_name') String? deviceName,
    @JsonKey(name: 'platform_name') String? platformName,
    @JsonKey(name: 'stream_decision') String? streamDecision,
    @JsonKey(name: 'video_decision') String? videoDecision,
    @JsonKey(name: 'audio_decision') String? audioDecision,
    @JsonKey(name: 'is_transcode') bool? isTranscode,
    String? device,
    String? player,
    String? product,
    String? platform,
  }) = _TracearrV2Stream;

  factory TracearrV2Stream.fromJson(Map<String, dynamic> json) =>
      _$TracearrV2StreamFromJson(json);
}

/// Active streams response wrapper
@freezed
abstract class TracearrV2StreamsResponse with _$TracearrV2StreamsResponse {
  const factory TracearrV2StreamsResponse({
    @Default(<TracearrV2Stream>[]) List<TracearrV2Stream> data,
    TracearrV2StreamsSummary? summary,
  }) = _TracearrV2StreamsResponse;

  factory TracearrV2StreamsResponse.fromJson(Map<String, dynamic> json) =>
      _$TracearrV2StreamsResponseFromJson(json);
}

/// History record from GET /api/v2/public/history
@freezed
abstract class TracearrV2HistoryRecord with _$TracearrV2HistoryRecord {
  const factory TracearrV2HistoryRecord({
    required String id,
    @JsonKey(name: 'server_id') String? serverId,
    @JsonKey(name: 'server_name') String? serverName,
    @JsonKey(name: 'user_id') String? userId,
    @JsonKey(name: 'user_name') String? userName,
    @JsonKey(name: 'user_avatar') String? userAvatar,
    @JsonKey(name: 'media_title') String? mediaTitle,
    @JsonKey(name: 'media_type') String? mediaType,
    @JsonKey(name: 'grandparent_title') String? grandparentTitle,
    @JsonKey(name: 'parent_title') String? parentTitle,
    @JsonKey(name: 'poster_url') String? posterUrl,
    @JsonKey(name: 'played_at') String? playedAt,
    @JsonKey(name: 'duration_seconds') int? durationSeconds,
    @JsonKey(name: 'completed') bool? completed,
    @JsonKey(name: 'media_id') String? mediaId,
    @JsonKey(name: 'show_media_id') String? showMediaId,
    @JsonKey(name: 'imdb_id') String? imdbId,
    @JsonKey(name: 'tmdb_id') int? tmdbId,
    @JsonKey(name: 'tvdb_id') int? tvdbId,
    @JsonKey(name: 'rating_key') String? ratingKey,
  }) = _TracearrV2HistoryRecord;

  factory TracearrV2HistoryRecord.fromJson(Map<String, dynamic> json) =>
      _$TracearrV2HistoryRecordFromJson(json);
}

/// Paginated history response
@freezed
abstract class TracearrV2HistoryResponse with _$TracearrV2HistoryResponse {
  const factory TracearrV2HistoryResponse({
    @Default(<TracearrV2HistoryRecord>[]) List<TracearrV2HistoryRecord> data,
    TracearrV2CursorMeta? meta,
  }) = _TracearrV2HistoryResponse;

  factory TracearrV2HistoryResponse.fromJson(Map<String, dynamic> json) =>
      _$TracearrV2HistoryResponseFromJson(json);
}

/// User account on a media server from GET /api/v2/public/users
@freezed
abstract class TracearrV2UserAccount with _$TracearrV2UserAccount {
  const factory TracearrV2UserAccount({
    @JsonKey(name: 'server_id') required String serverId,
    @JsonKey(name: 'server_type') required String serverType,
    @JsonKey(name: 'server_user_id') required String serverUserId,
    @JsonKey(name: 'external_user_id') required String externalUserId,
    required String username,
    @JsonKey(name: 'removed_at') String? removedAt,
  }) = _TracearrV2UserAccount;

  factory TracearrV2UserAccount.fromJson(Map<String, dynamic> json) =>
      _$TracearrV2UserAccountFromJson(json);
}

/// Correlated Tracearr user identity from GET /api/v2/public/users
@freezed
abstract class TracearrV2UserIdentity with _$TracearrV2UserIdentity {
  const factory TracearrV2UserIdentity({
    required String id,
    required String username,
    String? email,
    @JsonKey(name: 'plex_account_id') String? plexAccountId,
    @Default(<TracearrV2UserAccount>[]) List<TracearrV2UserAccount> accounts,
  }) = _TracearrV2UserIdentity;

  factory TracearrV2UserIdentity.fromJson(Map<String, dynamic> json) =>
      _$TracearrV2UserIdentityFromJson(json);
}

/// User summary alias for backwards compatibility
@freezed
abstract class TracearrV2User with _$TracearrV2User {
  const factory TracearrV2User({
    required String id,
    required String username,
    String? email,
    String? avatar,
    @JsonKey(name: 'play_count') int? playCount,
    @JsonKey(name: 'total_watch_time') int? totalWatchTime,
    @JsonKey(name: 'last_active_at') String? lastActiveAt,
  }) = _TracearrV2User;

  factory TracearrV2User.fromJson(Map<String, dynamic> json) =>
      _$TracearrV2UserFromJson(json);
}

/// Paginated user list response
@freezed
abstract class TracearrV2UsersResponse with _$TracearrV2UsersResponse {
  const factory TracearrV2UsersResponse({
    @Default(<TracearrV2UserIdentity>[]) List<TracearrV2UserIdentity> data,
    TracearrV2CursorMeta? meta,
  }) = _TracearrV2UsersResponse;

  factory TracearrV2UsersResponse.fromJson(Map<String, dynamic> json) =>
      _$TracearrV2UsersResponseFromJson(json);
}

/// Library item from GET /api/v2/public/libraries
@freezed
abstract class TracearrV2Library with _$TracearrV2Library {
  const factory TracearrV2Library({
    required String id,
    required String name,
    required String type,
    @JsonKey(name: 'server_id') String? serverId,
    @JsonKey(name: 'server_name') String? serverName,
    @JsonKey(name: 'item_count') int? itemCount,
    @JsonKey(name: 'movie_count') int? movieCount,
    @JsonKey(name: 'episode_count') int? episodeCount,
    @JsonKey(name: 'show_count') int? showCount,
    @JsonKey(name: 'track_count') int? trackCount,
    @JsonKey(name: 'total_file_size') int? totalFileSize,
  }) = _TracearrV2Library;

  factory TracearrV2Library.fromJson(Map<String, dynamic> json) =>
      _$TracearrV2LibraryFromJson(json);
}

/// Libraries list response
@freezed
abstract class TracearrV2LibrariesResponse with _$TracearrV2LibrariesResponse {
  const factory TracearrV2LibrariesResponse({
    @Default(<TracearrV2Library>[]) List<TracearrV2Library> data,
  }) = _TracearrV2LibrariesResponse;

  factory TracearrV2LibrariesResponse.fromJson(Map<String, dynamic> json) =>
      _$TracearrV2LibrariesResponseFromJson(json);
}

/// Recently added item from GET /api/v2/public/recently-added
@freezed
abstract class TracearrV2RecentlyAddedItem with _$TracearrV2RecentlyAddedItem {
  const factory TracearrV2RecentlyAddedItem({
    required String id,
    required String title,
    required String type,
    @JsonKey(name: 'server_id') String? serverId,
    @JsonKey(name: 'server_name') String? serverName,
    @JsonKey(name: 'library_id') String? libraryId,
    @JsonKey(name: 'poster_url') String? posterUrl,
    @JsonKey(name: 'added_at') String? addedAt,
    @JsonKey(name: 'removed_at') String? removedAt,
    @JsonKey(name: 'media_id') String? mediaId,
    @JsonKey(name: 'imdb_id') String? imdbId,
    @JsonKey(name: 'tmdb_id') int? tmdbId,
    @JsonKey(name: 'tvdb_id') int? tvdbId,
    int? year,
  }) = _TracearrV2RecentlyAddedItem;

  factory TracearrV2RecentlyAddedItem.fromJson(Map<String, dynamic> json) =>
      _$TracearrV2RecentlyAddedItemFromJson(json);
}

/// Paginated recently added response
@freezed
abstract class TracearrV2RecentlyAddedResponse
    with _$TracearrV2RecentlyAddedResponse {
  const factory TracearrV2RecentlyAddedResponse({
    @Default(<TracearrV2RecentlyAddedItem>[])
    List<TracearrV2RecentlyAddedItem> data,
    TracearrV2CursorMeta? meta,
  }) = _TracearrV2RecentlyAddedResponse;

  factory TracearrV2RecentlyAddedResponse.fromJson(
    Map<String, dynamic> json,
  ) =>
      _$TracearrV2RecentlyAddedResponseFromJson(json);
}

/// Genre breakdown for user stats
@freezed
abstract class TracearrV2UserGenre with _$TracearrV2UserGenre {
  const factory TracearrV2UserGenre({
    required String genre,
    @Default(0) int plays,
  }) = _TracearrV2UserGenre;

  factory TracearrV2UserGenre.fromJson(Map<String, dynamic> json) =>
      _$TracearrV2UserGenreFromJson(json);
}

/// User detailed stats response from GET /api/v2/public/users/{id}/stats
@freezed
abstract class TracearrV2UserStatsResponse with _$TracearrV2UserStatsResponse {
  const factory TracearrV2UserStatsResponse({
    @JsonKey(name: 'user_id') required String userId,
    Map<String, dynamic>? windows,
    @JsonKey(name: 'top_genres')
    @Default(<TracearrV2UserGenre>[])
    List<TracearrV2UserGenre> topGenres,
  }) = _TracearrV2UserStatsResponse;

  factory TracearrV2UserStatsResponse.fromJson(Map<String, dynamic> json) =>
      _$TracearrV2UserStatsResponseFromJson(json);
}

/// User stats alias for backwards compatibility
@freezed
abstract class TracearrV2UserStats with _$TracearrV2UserStats {
  const factory TracearrV2UserStats({
    @JsonKey(name: 'user_id') required String userId,
    @JsonKey(name: 'play_count') int? playCount,
    @JsonKey(name: 'total_watch_time') int? totalWatchTime,
    @JsonKey(name: 'favorite_platform') String? favoritePlatform,
    @JsonKey(name: 'favorite_player') String? favoritePlayer,
  }) = _TracearrV2UserStats;

  factory TracearrV2UserStats.fromJson(Map<String, dynamic> json) =>
      _$TracearrV2UserStatsFromJson(json);
}

/// Media Version detail
@freezed
abstract class TracearrV2MediaVersion with _$TracearrV2MediaVersion {
  const factory TracearrV2MediaVersion({
    String? resolution,
    @JsonKey(name: 'video_codec') String? videoCodec,
    @JsonKey(name: 'audio_codec') String? audioCodec,
    @JsonKey(name: 'dynamic_range') String? dynamicRange,
    String? container,
    @JsonKey(name: 'file_size') int? fileSize,
  }) = _TracearrV2MediaVersion;

  factory TracearrV2MediaVersion.fromJson(Map<String, dynamic> json) =>
      _$TracearrV2MediaVersionFromJson(json);
}

/// Media Availability per server
@freezed
abstract class TracearrV2MediaAvailability with _$TracearrV2MediaAvailability {
  const factory TracearrV2MediaAvailability({
    @JsonKey(name: 'server_id') required String serverId,
    @JsonKey(name: 'server_type') required String serverType,
    @JsonKey(name: 'library_id') required String libraryId,
    @JsonKey(name: 'rating_key') required String ratingKey,
    @JsonKey(name: 'added_at') required String addedAt,
    @JsonKey(name: 'removed_at') String? removedAt,
    @JsonKey(name: 'video_resolution') String? videoResolution,
    @JsonKey(name: 'file_size') int? fileSize,
    @Default(<TracearrV2MediaVersion>[]) List<TracearrV2MediaVersion> versions,
  }) = _TracearrV2MediaAvailability;

  factory TracearrV2MediaAvailability.fromJson(Map<String, dynamic> json) =>
      _$TracearrV2MediaAvailabilityFromJson(json);
}

/// Media resource item from GET /api/v2/public/media/{ref}
@freezed
abstract class TracearrV2MediaResource with _$TracearrV2MediaResource {
  const factory TracearrV2MediaResource({
    required String id,
    @JsonKey(name: 'media_type') required String mediaType,
    required String title,
    int? year,
    @JsonKey(name: 'imdb_id') String? imdbId,
    @JsonKey(name: 'tmdb_id') int? tmdbId,
    @JsonKey(name: 'tvdb_id') int? tvdbId,
    @Default(<String>[]) List<String> genres,
    @JsonKey(name: 'show_media_id') String? showMediaId,
    @JsonKey(name: 'merged_ids') @Default(<String>[]) List<String> mergedIds,
    @Default(<TracearrV2MediaAvailability>[])
    List<TracearrV2MediaAvailability> availability,
    @JsonKey(name: 'season_count') int? seasonCount,
    @JsonKey(name: 'episode_count') int? episodeCount,
  }) = _TracearrV2MediaResource;

  factory TracearrV2MediaResource.fromJson(Map<String, dynamic> json) =>
      _$TracearrV2MediaResourceFromJson(json);
}

/// Media detail alias for backwards compatibility
@freezed
abstract class TracearrV2MediaDetails with _$TracearrV2MediaDetails {
  const factory TracearrV2MediaDetails({
    required String id,
    required String title,
    required String type,
    @JsonKey(name: 'poster_url') String? posterUrl,
    @JsonKey(name: 'total_plays') int? totalPlays,
    @JsonKey(name: 'total_watch_time') int? totalWatchTime,
  }) = _TracearrV2MediaDetails;

  factory TracearrV2MediaDetails.fromJson(Map<String, dynamic> json) =>
      _$TracearrV2MediaDetailsFromJson(json);
}

/// Media child node from GET /api/v2/public/media/{ref}/children
@freezed
abstract class TracearrV2MediaChild with _$TracearrV2MediaChild {
  const factory TracearrV2MediaChild({
    required String id,
    @JsonKey(name: 'media_type') required String mediaType,
    required String title,
    @JsonKey(name: 'season_number') int? seasonNumber,
    @JsonKey(name: 'episode_count') int? episodeCount,
    @JsonKey(name: 'episode_number') int? episodeNumber,
    @JsonKey(name: 'imdb_id') String? imdbId,
    @JsonKey(name: 'tmdb_id') int? tmdbId,
    @JsonKey(name: 'tvdb_id') int? tvdbId,
    @JsonKey(name: 'show_media_id') String? showMediaId,
    @Default(<String>[]) List<String> genres,
  }) = _TracearrV2MediaChild;

  factory TracearrV2MediaChild.fromJson(Map<String, dynamic> json) =>
      _$TracearrV2MediaChildFromJson(json);
}

/// Media children response
@freezed
abstract class TracearrV2MediaChildrenResponse
    with _$TracearrV2MediaChildrenResponse {
  const factory TracearrV2MediaChildrenResponse({
    @Default(<TracearrV2MediaChild>[]) List<TracearrV2MediaChild> data,
  }) = _TracearrV2MediaChildrenResponse;

  factory TracearrV2MediaChildrenResponse.fromJson(
    Map<String, dynamic> json,
  ) =>
      _$TracearrV2MediaChildrenResponseFromJson(json);
}

/// Media stats measures per server
@freezed
abstract class TracearrV2StatServerMeasures
    with _$TracearrV2StatServerMeasures {
  const factory TracearrV2StatServerMeasures({
    @JsonKey(name: 'server_id') required String serverId,
    @JsonKey(name: 'server_name') String? serverName,
    @Default(0) int plays,
    @JsonKey(name: 'watch_time_ms') @Default(0) int watchTimeMs,
    @JsonKey(name: 'unique_users') @Default(0) int uniqueUsers,
  }) = _TracearrV2StatServerMeasures;

  factory TracearrV2StatServerMeasures.fromJson(Map<String, dynamic> json) =>
      _$TracearrV2StatServerMeasuresFromJson(json);
}

/// Media stats window summary
@freezed
abstract class TracearrV2StatWindow with _$TracearrV2StatWindow {
  const factory TracearrV2StatWindow({
    TracearrV2StatServerMeasures? combined,
    @JsonKey(name: 'per_server')
    @Default(<TracearrV2StatServerMeasures>[])
    List<TracearrV2StatServerMeasures> perServer,
  }) = _TracearrV2StatWindow;

  factory TracearrV2StatWindow.fromJson(Map<String, dynamic> json) =>
      _$TracearrV2StatWindowFromJson(json);
}

/// Media play statistics response from GET /api/v2/public/media/{ref}/stats
@freezed
abstract class TracearrV2MediaStatsResponse
    with _$TracearrV2MediaStatsResponse {
  const factory TracearrV2MediaStatsResponse({
    @JsonKey(name: 'media_id') required String mediaId,
    @JsonKey(name: 'media_type') required String mediaType,
    Map<String, dynamic>? windows,
  }) = _TracearrV2MediaStatsResponse;

  factory TracearrV2MediaStatsResponse.fromJson(Map<String, dynamic> json) =>
      _$TracearrV2MediaStatsResponseFromJson(json);
}

/// Watcher user identification from GET /api/v2/public/media/{ref}/watchers
@freezed
abstract class TracearrV2WatcherUser with _$TracearrV2WatcherUser {
  const factory TracearrV2WatcherUser({
    @JsonKey(name: 'server_user_id') required String serverUserId,
    @JsonKey(name: 'user_id') required String userId,
    String? username,
    @JsonKey(name: 'identity_name') String? identityName,
  }) = _TracearrV2WatcherUser;

  factory TracearrV2WatcherUser.fromJson(Map<String, dynamic> json) =>
      _$TracearrV2WatcherUserFromJson(json);
}

/// Watcher item from GET /api/v2/public/media/{ref}/watchers
@freezed
abstract class TracearrV2Watcher with _$TracearrV2Watcher {
  const factory TracearrV2Watcher({
    TracearrV2WatcherUser? user,
    @Default(0) int plays,
    @JsonKey(name: 'watch_time_ms') @Default(0) int watchTimeMs,
    @JsonKey(name: 'completion_pct') double? completionPct,
    @JsonKey(name: 'last_watched_day') String? lastWatchedDay,
    @JsonKey(name: 'distinct_episodes_watched') int? distinctEpisodesWatched,
  }) = _TracearrV2Watcher;

  factory TracearrV2Watcher.fromJson(Map<String, dynamic> json) =>
      _$TracearrV2WatcherFromJson(json);
}

/// Media watchers response from GET /api/v2/public/media/{ref}/watchers
@freezed
abstract class TracearrV2MediaWatchersResponse
    with _$TracearrV2MediaWatchersResponse {
  const factory TracearrV2MediaWatchersResponse({
    @JsonKey(name: 'media_id') required String mediaId,
    @JsonKey(name: 'media_type') required String mediaType,
    String? window,
    @Default(<TracearrV2Watcher>[]) List<TracearrV2Watcher> watchers,
  }) = _TracearrV2MediaWatchersResponse;

  factory TracearrV2MediaWatchersResponse.fromJson(
    Map<String, dynamic> json,
  ) =>
      _$TracearrV2MediaWatchersResponseFromJson(json);
}
