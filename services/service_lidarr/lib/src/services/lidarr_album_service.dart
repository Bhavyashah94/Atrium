import '../generated/api/raw_album_api.dart';
import '../generated/models/album_resource.dart';
import '../generated/responses/lidarr_exception.dart';

/// High-level service wrapper for Lidarr Album operations.
class LidarrAlbumService {
  final RawAlbumApi _rawAlbumApi;

  LidarrAlbumService(this._rawAlbumApi);

  /// Retrieves albums in Lidarr, optionally filtered by artistId.
  Future<List<AlbumResource>> getAlbums({String? artistId}) async {
    final response = await _rawAlbumApi.getAlbum(artistId: artistId);
    if (response.isSuccess && response.data != null) {
      return response.data!;
    }
    if (response.error != null) {
      throw LidarrException(
        response.error!.message ?? 'Failed to fetch albums',
        statusCode: response.statusCode,
        error: response.error,
      );
    }
    throw LidarrException('Failed to fetch albums', statusCode: response.statusCode);
  }
}
