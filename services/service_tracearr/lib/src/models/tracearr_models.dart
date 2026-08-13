library;

/// Domain models for Tracearr domain data.
class TracearrStream {
  const TracearrStream({
    required this.id,
    required this.serverId,
    required this.serverName,
    required this.serverType,
    required this.mediaTitle,
    this.showTitle,
    this.seasonNumber,
    this.episodeNumber,
    this.year,
    required this.userUsername,
    this.userAvatarUrl,
    this.thumbPath,
    this.posterUrl,
    this.bitrate,
    this.totalBitrate,
    this.resolution,
    this.videoDecision,
    this.audioDecision,
    this.isTranscode = false,
    this.isHwTranscode = false,
    this.hwDecoding,
    this.hwEncoding,
    this.transcodeSpeed,
    this.isThrottled,
    this.mediaId,
    this.ratingKey,
    this.progressMs,
    this.durationMs,
    this.percentComplete,
    this.product,
    this.player,
    this.device,
    this.platform,
    this.videoCodec,
    this.audioCodec,
    this.audioChannels,
    this.transcodeReasons = const <String>[],
    this.state,
    this.startedAt,
    this.subtitleLanguage,
    this.subtitleCodec,
    this.artistName,
    this.albumName,
    this.trackNumber,
    this.userId,
  });

  final String id;
  final String serverId;
  final String serverName;
  final String serverType;
  final String mediaTitle;
  final String? showTitle;
  final int? seasonNumber;
  final int? episodeNumber;
  final int? year;
  final String userUsername;
  final String? userId;
  final String? userAvatarUrl;
  final String? thumbPath;
  final String? posterUrl;
  final int? bitrate;
  final String? totalBitrate;
  final String? resolution;
  final String? videoDecision;
  final String? audioDecision;
  final bool isTranscode;
  final bool isHwTranscode;
  final String? hwDecoding;
  final String? hwEncoding;
  final double? transcodeSpeed;
  final bool? isThrottled;
  final String? mediaId;
  final String? ratingKey;
  final int? progressMs;
  final int? durationMs;
  final double? percentComplete;
  final String? product;
  final String? player;
  final String? device;
  final String? platform;
  final String? videoCodec;
  final String? audioCodec;
  final String? audioChannels;
  final List<String> transcodeReasons;
  final String? state;
  final DateTime? startedAt;
  final String? subtitleLanguage;
  final String? subtitleCodec;
  final String? artistName;
  final String? albumName;
  final int? trackNumber;
}

class TracearrHistoryItem {
  const TracearrHistoryItem({
    required this.id,
    required this.serverId,
    required this.serverName,
    required this.serverType,
    required this.mediaTitle,
    this.showTitle,
    this.seasonNumber,
    this.episodeNumber,
    this.year,
    required this.userUsername,
    this.userAvatarUrl,
    this.thumbPath,
    this.posterUrl,
    this.startedAt,
    this.stoppedAt,
    this.watched = false,
    this.percentComplete,
    this.durationMs,
    this.mediaId,
    this.ratingKey,
    this.device,
    this.player,
    this.product,
    this.platform,
    this.isTranscode,
    this.isHwTranscode = false,
    this.hwDecoding,
    this.hwEncoding,
    this.videoDecision,
    this.audioDecision,
    this.bitrate,
    this.resolution,
    this.videoCodec,
    this.audioCodec,
    this.audioChannels,
    this.transcodeReasons = const <String>[],
    this.subtitleLanguage,
    this.subtitleCodec,
    this.userId,
    this.serverUserId,
    this.segmentCount,
  });

  final String id;
  final String serverId;
  final String serverName;
  final String serverType;
  final String mediaTitle;
  final String? showTitle;
  final int? seasonNumber;
  final int? episodeNumber;
  final int? year;
  final String userUsername;
  final String? userAvatarUrl;
  final String? thumbPath;
  final String? posterUrl;
  final DateTime? startedAt;
  final DateTime? stoppedAt;
  final bool watched;
  final double? percentComplete;
  final int? durationMs;
  final String? mediaId;
  final String? ratingKey;
  final String? device;
  final String? player;
  final String? product;
  final String? platform;
  final bool? isTranscode;
  final bool isHwTranscode;
  final String? hwDecoding;
  final String? hwEncoding;
  final String? videoDecision;
  final String? audioDecision;
  final int? bitrate;
  final String? resolution;
  final String? videoCodec;
  final String? audioCodec;
  final String? audioChannels;
  final List<String> transcodeReasons;
  final String? subtitleLanguage;
  final String? subtitleCodec;
  final String? userId;
  final String? serverUserId;
  final int? segmentCount;
}

class TracearrHistoryPage {
  const TracearrHistoryPage({
    required this.items,
    this.nextCursor,
  });

  final List<TracearrHistoryItem> items;
  final String? nextCursor;
}

class TracearrUserAccount {
  const TracearrUserAccount({
    required this.serverId,
    required this.serverType,
    required this.serverUserId,
    required this.externalUserId,
    required this.username,
    this.removedAt,
  });

  final String serverId;
  final String serverType;
  final String serverUserId;
  final String externalUserId;
  final String username;
  final DateTime? removedAt;
}

class TracearrGenreStat {
  const TracearrGenreStat({
    required this.genre,
    required this.plays,
  });

  final String genre;
  final int plays;
}

class TracearrUserSummary {
  const TracearrUserSummary({
    required this.id,
    required this.username,
    this.email,
    this.avatarUrl,
    this.allTimePlays = 0,
    this.allTimeWatchTimeMs = 0,
    this.lastActiveAt,
    this.accounts = const <TracearrUserAccount>[],
  });

  final String id;
  final String username;
  final String? email;
  final String? avatarUrl;
  final int allTimePlays;
  final int allTimeWatchTimeMs;
  final DateTime? lastActiveAt;
  final List<TracearrUserAccount> accounts;
}

class TracearrUserDetail {
  const TracearrUserDetail({
    required this.id,
    required this.username,
    this.email,
    this.plexAccountId,
    this.accounts = const <TracearrUserAccount>[],
    this.allTimePlays = 0,
    this.allTimeWatchTimeMs = 0,
    this.last30DaysPlays = 0,
    this.last7DaysPlays = 0,
    this.topGenres = const <TracearrGenreStat>[],
    this.recentHistory = const <TracearrHistoryItem>[],
  });

  final String id;
  final String username;
  final String? email;
  final String? plexAccountId;
  final List<TracearrUserAccount> accounts;
  final int allTimePlays;
  final int allTimeWatchTimeMs;
  final int last30DaysPlays;
  final int last7DaysPlays;
  final List<TracearrGenreStat> topGenres;
  final List<TracearrHistoryItem> recentHistory;
}

class TracearrRecentlyAddedItem {
  const TracearrRecentlyAddedItem({
    required this.id,
    required this.serverId,
    this.serverType,
    required this.libraryId,
    required this.mediaType,
    required this.title,
    this.year,
    this.seasonNumber,
    this.episodeNumber,
    this.addedAt,
    this.mediaId,
    this.imdbId,
    this.tmdbId,
    this.tvdbId,
    this.ratingKey,
    this.resolvedPosterUrl,
  });

  final String id;
  final String serverId;
  final String? serverType;
  final String libraryId;
  final String mediaType;
  final String title;
  final int? year;
  final int? seasonNumber;
  final int? episodeNumber;
  final DateTime? addedAt;
  final String? mediaId;
  final String? imdbId;
  final String? tmdbId;
  final String? tvdbId;
  final String? ratingKey;
  final String? resolvedPosterUrl;
}

class TracearrRecentlyAddedPage {
  const TracearrRecentlyAddedPage({
    required this.items,
    this.nextCursor,
  });

  final List<TracearrRecentlyAddedItem> items;
  final String? nextCursor;
}

class TracearrViolationItem {
  const TracearrViolationItem({
    required this.id,
    required this.serverId,
    required this.serverName,
    required this.severity,
    required this.rule,
    required this.username,
    this.userId,
    this.createdAt,
    this.description,
    this.acknowledged = false,
  });

  final String id;
  final String serverId;
  final String serverName;
  final String severity;
  final String rule;
  final String username;
  final String? userId;
  final DateTime? createdAt;
  final String? description;
  final bool acknowledged;
}

class TracearrLibrary {
  const TracearrLibrary({
    required this.serverId,
    required this.serverType,
    required this.libraryId,
    this.itemCount = 0,
    this.movieCount = 0,
    this.showCount = 0,
    this.episodeCount = 0,
    this.trackCount = 0,
    this.totalFileSize = 0,
    this.resolutions = const <String, int>{},
  });

  final String serverId;
  final String serverType;
  final String libraryId;
  final int itemCount;
  final int movieCount;
  final int showCount;
  final int episodeCount;
  final int trackCount;
  final int totalFileSize;
  final Map<String, int> resolutions;
}

class TracearrMediaChild {
  const TracearrMediaChild({
    required this.id,
    required this.mediaType,
    required this.title,
    this.seasonNumber,
    this.episodeNumber,
    this.episodeCount,
  });

  final String id;
  final String mediaType;
  final String title;
  final int? seasonNumber;
  final int? episodeNumber;
  final int? episodeCount;
}

class TracearrMediaWatcher {
  const TracearrMediaWatcher({
    required this.userId,
    required this.username,
    this.avatarUrl,
    this.plays = 0,
    this.watchTimeMs = 0,
    this.completionPct,
    this.lastWatchedDay,
    this.distinctEpisodesWatched,
  });

  final String userId;
  final String username;
  final String? avatarUrl;
  final int plays;
  final int watchTimeMs;
  final double? completionPct;
  final String? lastWatchedDay;
  final int? distinctEpisodesWatched;
}

class TracearrMediaAvailability {
  const TracearrMediaAvailability({
    required this.serverId,
    required this.serverType,
    this.ratingKey,
    this.libraryId,
    this.videoResolution,
    this.fileSize,
    this.addedAt,
    this.removedAt,
  });

  final String serverId;
  final String serverType;
  final String? ratingKey;
  final String? libraryId;
  final String? videoResolution;
  final int? fileSize;
  final DateTime? addedAt;
  final DateTime? removedAt;
}

class TracearrMediaDetail {
  const TracearrMediaDetail({
    required this.id,
    required this.title,
    this.mediaType = 'movie',
    this.year,
    this.showMediaId,
    this.imdbId,
    this.tmdbId,
    this.tvdbId,
    this.genres = const [],
    this.seasonCount,
    this.episodeCount,
    this.servers = const [],
    this.availability = const [],
    this.posterUrl,
    this.children = const [],
    this.watchers = const [],
    this.allTimePlays = 0,
    this.last30DaysPlays = 0,
    this.last7DaysPlays = 0,
    this.allTimeWatchTimeMs = 0,
  });

  final String id;
  final String title;
  final String mediaType;
  final int? year;
  final String? showMediaId;
  final String? imdbId;
  final String? tmdbId;
  final String? tvdbId;
  final List<String> genres;
  final int? seasonCount;
  final int? episodeCount;
  final List<String> servers;
  final List<TracearrMediaAvailability> availability;
  final String? posterUrl;
  final List<TracearrMediaChild> children;
  final List<TracearrMediaWatcher> watchers;
  final int allTimePlays;
  final int last30DaysPlays;
  final int last7DaysPlays;
  final int allTimeWatchTimeMs;
}

/// Server connectivity status from v1 health endpoint.
class TracearrServerStatus {
  const TracearrServerStatus({
    required this.id,
    required this.name,
    required this.type,
    required this.online,
    this.activeStreams = 0,
  });

  final String id;
  final String name;
  final String type;
  final bool online;
  final int activeStreams;
}

/// Health check response.
class TracearrHealthResponse {
  const TracearrHealthResponse({
    required this.status,
    this.version,
    this.timestamp,
    this.servers = const <TracearrServerStatus>[],
  });

  final String status;
  final String? version;
  final DateTime? timestamp;
  final List<TracearrServerStatus> servers;
}

/// Today's fleet dashboard statistics.
class TracearrTodayStats {
  const TracearrTodayStats({
    this.activeStreams = 0,
    this.todayPlays = 0,
    this.watchTimeHours = 0.0,
    this.alertsLast24h = 0,
    this.activeUsersToday = 0,
    this.timestamp,
  });

  final int activeStreams;
  final int todayPlays;
  final double watchTimeHours;
  final int alertsLast24h;
  final int activeUsersToday;
  final DateTime? timestamp;
}

/// 30-day dashboard aggregate statistics.
class TracearrAggregateStats {
  const TracearrAggregateStats({
    this.activeStreams = 0,
    this.totalUsers = 0,
    this.totalSessions = 0,
    this.recentViolations = 0,
    this.timestamp,
  });

  final int activeStreams;
  final int totalUsers;
  final int totalSessions;
  final int recentViolations;
  final DateTime? timestamp;
}

/// Single bucket in playback activity trends.
class TracearrActivityBucket {
  const TracearrActivityBucket({
    this.date,
    this.count = 0,
    this.durationMs = 0,
  });

  final DateTime? date;
  final int count;
  final int durationMs;
}

/// Playback activity trends across the fleet.
class TracearrActivityTrend {
  const TracearrActivityTrend({
    required this.period,
    this.rangeStart,
    this.rangeEnd,
    this.plays = const <TracearrActivityBucket>[],
  });

  final String period;
  final DateTime? rangeStart;
  final DateTime? rangeEnd;
  final List<TracearrActivityBucket> plays;
}
