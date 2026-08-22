import '../generated/api/raw_episode_api.dart';
import '../generated/models/episode_resource.dart';
import '../generated/responses/sonarr_exception.dart';

/// High-level service wrapper for Sonarr Episode operations.
class SonarrEpisodeService {
  final RawEpisodeApi _rawEpisodeApi;

  SonarrEpisodeService(this._rawEpisodeApi);

  /// Retrieves episodes for a series or season.
  Future<List<EpisodeResource>> getEpisodes({
    String? seriesId,
    String? seasonNumber,
  }) async {
    final response = await _rawEpisodeApi.getEpisode(
      seriesId: seriesId,
      seasonNumber: seasonNumber,
    );
    if (response.isSuccess && response.data != null) {
      return response.data!;
    }
    if (response.error != null) {
      throw SonarrException(
        response.error!.message ?? 'Failed to fetch episodes',
        statusCode: response.statusCode,
        error: response.error,
      );
    }
    throw SonarrException('Failed to fetch episodes', statusCode: response.statusCode);
  }
}
