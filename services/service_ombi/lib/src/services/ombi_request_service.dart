import '../generated/api/raw_request_api.dart';
import '../generated/models/movie_requests.dart';
import '../generated/responses/ombi_exception.dart';

/// High-level service wrapper for Ombi media requests and approvals.
class OmbiRequestService {
  final RawRequestApi _rawRequestApi;

  OmbiRequestService(this._rawRequestApi);

  /// Retrieves details for a specific movie request by ID.
  Future<MovieRequests?> getMovieRequestInfo(String requestId) async {
    final response = await _rawRequestApi.getRequestMovieInfoByRequestId(requestId: requestId);
    if (response.isSuccess) {
      return response.data;
    }
    if (response.error != null) {
      throw OmbiException(
        response.error!.message ?? 'Movie request info failed',
        statusCode: response.statusCode,
        error: response.error,
      );
    }
    throw OmbiException('Movie request info failed', statusCode: response.statusCode);
  }
}
