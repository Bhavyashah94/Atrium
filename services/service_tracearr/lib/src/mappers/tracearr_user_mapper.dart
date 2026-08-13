import '../generated/models/history_record.dart';
import '../generated/models/user_account.dart';
import '../generated/models/user_identity.dart';
import '../generated/models/user_stats_response.dart';
import '../media/tracearr_media_url_resolver.dart';
import '../models/tracearr_models.dart';
import 'tracearr_history_mapper.dart';

/// Pure transformation for user identities, accounts, statistics, and detail profiles.
class TracearrUserMapper {
  const TracearrUserMapper._();

  static TracearrUserAccount mapAccount(UserAccount acc) {
    return TracearrUserAccount(
      serverId: acc.serverId ?? '',
      serverType: acc.serverType ?? '',
      serverUserId: acc.serverUserId ?? '',
      externalUserId: acc.externalUserId ?? '',
      username: acc.username ?? '',
    );
  }

  static List<TracearrUserAccount> mapAccounts(List<UserAccount>? accounts) {
    if (accounts == null || accounts.isEmpty) return const [];
    return accounts.map(mapAccount).toList();
  }

  static TracearrUserSummary summaryFromDto({
    required UserIdentity identity,
    UserStatsResponse? stats,
    required String baseUrl,
  }) {
    int totalPlays = 0;
    int watchTimeMs = 0;

    if (stats != null && stats.windows is Map<String, dynamic>) {
      final windowsMap = stats.windows as Map<String, dynamic>;
      final allTime = windowsMap['all_time'];
      if (allTime is Map<String, dynamic>) {
        totalPlays = (allTime['plays'] as num?)?.toInt() ?? 0;
        watchTimeMs = (allTime['watch_time_ms'] as num?)?.toInt() ?? 0;
      }
    }

    final accounts = mapAccounts(identity.accounts);

    String? avatarUrl;
    if (identity.accounts != null && identity.accounts!.isNotEmpty) {
      final firstAcc = identity.accounts!.first;
      final accServerId = firstAcc.serverId ?? '';
      final extUserId = firstAcc.externalUserId ?? firstAcc.serverUserId;
      if (accServerId.isNotEmpty && extUserId != null && extUserId.isNotEmpty) {
        final path = TracearrMediaUrlResolver.buildUserAvatarPath(
          firstAcc.serverType,
          extUserId,
        );
        avatarUrl = TracearrMediaUrlResolver.formatUrl(
          baseUrl: baseUrl,
          rawUrl: TracearrMediaUrlResolver.buildProxyPosterUrl(
            baseUrl: baseUrl,
            serverId: accServerId,
            thumbPath: path,
          ),
        );
      }
    }

    return TracearrUserSummary(
      id: identity.id ?? '',
      username: identity.username ?? 'Unknown',
      email: identity.email,
      avatarUrl: avatarUrl,
      allTimePlays: totalPlays,
      allTimeWatchTimeMs: watchTimeMs,
      accounts: accounts,
    );
  }

  static TracearrUserDetail detailFromDto({
    required UserIdentity identity,
    UserStatsResponse? stats,
    List<HistoryRecord>? recentHistoryRecords,
    required String baseUrl,
  }) {
    final accounts = mapAccounts(identity.accounts);

    int allTimePlays = 0;
    int allTimeWatchTimeMs = 0;
    int last30DaysPlays = 0;
    int last7DaysPlays = 0;
    final topGenres = <TracearrGenreStat>[];

    if (stats != null && stats.windows is Map<String, dynamic>) {
      final windowsMap = stats.windows as Map<String, dynamic>;

      if (windowsMap['all_time'] is Map<String, dynamic>) {
        final m = windowsMap['all_time'] as Map<String, dynamic>;
        allTimePlays = (m['plays'] as num?)?.toInt() ?? 0;
        allTimeWatchTimeMs = (m['watch_time_ms'] as num?)?.toInt() ?? 0;
      }

      if (windowsMap['last_30'] is Map<String, dynamic>) {
        final m = windowsMap['last_30'] as Map<String, dynamic>;
        last30DaysPlays = (m['plays'] as num?)?.toInt() ?? 0;
      } else if (windowsMap['last_30_days'] is Map<String, dynamic>) {
        final m = windowsMap['last_30_days'] as Map<String, dynamic>;
        last30DaysPlays = (m['plays'] as num?)?.toInt() ?? 0;
      }

      if (windowsMap['last_7'] is Map<String, dynamic>) {
        final m = windowsMap['last_7'] as Map<String, dynamic>;
        last7DaysPlays = (m['plays'] as num?)?.toInt() ?? 0;
      } else if (windowsMap['last_7_days'] is Map<String, dynamic>) {
        final m = windowsMap['last_7_days'] as Map<String, dynamic>;
        last7DaysPlays = (m['plays'] as num?)?.toInt() ?? 0;
      }

      if (windowsMap['top_genres'] is List) {
        final list = windowsMap['top_genres'] as List;
        for (final g in list) {
          if (g is Map<String, dynamic>) {
            topGenres.add(
              TracearrGenreStat(
                genre: (g['genre'] as String?) ?? 'Unknown',
                plays: (g['plays'] as num?)?.toInt() ?? 0,
              ),
            );
          }
        }
      }
    }

    if (topGenres.isEmpty && stats?.topGenres != null) {
      for (final g in stats!.topGenres!) {
        final genre = g.genre ?? '';
        final plays = g.plays ?? 0;
        if (genre.isNotEmpty) {
          topGenres.add(TracearrGenreStat(genre: genre, plays: plays));
        }
      }
    }

    final recentHistory = recentHistoryRecords != null
        ? recentHistoryRecords
            .map((r) => TracearrHistoryMapper.fromDto(r, baseUrl: baseUrl))
            .toList()
        : const <TracearrHistoryItem>[];

    return TracearrUserDetail(
      id: identity.id ?? '',
      username: identity.username ?? 'Unknown',
      email: identity.email,
      plexAccountId: identity.plexAccountId,
      accounts: accounts,
      allTimePlays: allTimePlays,
      allTimeWatchTimeMs: allTimeWatchTimeMs,
      last30DaysPlays: last30DaysPlays,
      last7DaysPlays: last7DaysPlays,
      topGenres: topGenres,
      recentHistory: recentHistory,
    );
  }
}
