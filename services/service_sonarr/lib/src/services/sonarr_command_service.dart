import '../generated/api/raw_command_api.dart';
import '../generated/models/command_resource.dart';
import '../generated/responses/sonarr_exception.dart';

/// High-level service for triggering Sonarr background commands (searches, refreshes, renames).
class SonarrCommandService {
  final RawCommandApi _rawCommandApi;

  SonarrCommandService(this._rawCommandApi);

  /// Triggers an automatic search for all monitored missing episodes in a series.
  Future<CommandResource?> searchSeriesEpisodes(int seriesId) async {
    return _postCommand({
      'name': 'SeriesSearch',
      'seriesId': seriesId,
    });
  }

  /// Triggers an automatic search for monitored missing episodes in a specific season.
  Future<CommandResource?> searchSeasonEpisodes(
      int seriesId, int seasonNumber) async {
    return _postCommand({
      'name': 'SeasonSearch',
      'seriesId': seriesId,
      'seasonNumber': seasonNumber,
    });
  }

  /// Triggers an automatic search for specific episodes.
  Future<CommandResource?> searchEpisodes(List<int> episodeIds) async {
    return _postCommand({
      'name': 'EpisodeSearch',
      'episodeIds': episodeIds,
    });
  }

  /// Triggers a global search for all missing monitored episodes across all series.
  Future<CommandResource?> searchMissingEpisodes() async {
    return _postCommand({
      'name': 'MissingEpisodeSearch',
    });
  }

  Future<CommandResource?> _postCommand(Map<String, dynamic> body) async {
    final response = await _rawCommandApi.postCommand(body: body);
    if (response.isSuccess) {
      return response.data;
    }
    if (response.error != null) {
      throw SonarrException(
        response.error!.message ?? 'Command execution failed',
        statusCode: response.statusCode,
        error: response.error,
      );
    }
    throw SonarrException('Command execution failed',
        statusCode: response.statusCode);
  }
}
