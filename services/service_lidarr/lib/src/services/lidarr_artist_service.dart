import '../generated/api/raw_artist_api.dart';
import '../generated/api/raw_artist_lookup_api.dart';
import '../generated/models/artist_resource.dart';
import '../generated/responses/lidarr_exception.dart';

/// High-level service wrapper for Lidarr Artist operations.
class LidarrArtistService {
  final RawArtistApi _rawArtistApi;
  final RawArtistLookupApi _rawArtistLookupApi;

  LidarrArtistService(this._rawArtistApi, this._rawArtistLookupApi);

  /// Retrieves all artists monitored in Lidarr.
  Future<List<ArtistResource>> getArtists({String? mbId}) async {
    final response = await _rawArtistApi.getArtist(mbId: mbId);
    if (response.isSuccess && response.data != null) {
      return response.data!;
    }
    if (response.error != null) {
      throw LidarrException(
        response.error!.message ?? 'Failed to fetch artists',
        statusCode: response.statusCode,
        error: response.error,
      );
    }
    throw LidarrException('Failed to fetch artists', statusCode: response.statusCode);
  }

  /// Retrieves a specific artist by ID.
  Future<ArtistResource?> getArtistById(String id) async {
    final response = await _rawArtistApi.getArtistById(id: id);
    if (response.isSuccess) {
      return response.data;
    }
    if (response.error != null) {
      throw LidarrException(
        response.error!.message ?? 'Failed to fetch artist',
        statusCode: response.statusCode,
        error: response.error,
      );
    }
    throw LidarrException('Failed to fetch artist', statusCode: response.statusCode);
  }

  /// Searches for artists by term.
  Future<List<ArtistResource>> searchArtist(String term) async {
    final response = await _rawArtistLookupApi.getArtistLookup(term: term);
    if (response.isSuccess && response.data != null) {
      return response.data!;
    }
    if (response.error != null) {
      throw LidarrException(
        response.error!.message ?? 'Artist lookup failed',
        statusCode: response.statusCode,
        error: response.error,
      );
    }
    throw LidarrException('Artist lookup failed', statusCode: response.statusCode);
  }
}
