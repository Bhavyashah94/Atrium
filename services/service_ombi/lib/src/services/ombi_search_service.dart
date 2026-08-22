import '../generated/api/raw_search_api.dart';
import '../generated/models/movie_full_info_view_model.dart';
import '../generated/models/multi_search_result.dart';
import '../generated/responses/ombi_exception.dart';

/// High-level service wrapper for Ombi search endpoints with exception handling.
class OmbiSearchService {
  final RawSearchApi _rawSearchApi;

  OmbiSearchService(this._rawSearchApi);

  /// Performs a multi-search across movies and TV shows.
  Future<List<MultiSearchResult>> searchMulti(String searchTerm) async {
    final response =
        await _rawSearchApi.postSearchMultiBySearchTerm(searchTerm: searchTerm);
    if (response.isSuccess && response.data != null) {
      return response.data!;
    }
    if (response.error != null) {
      throw OmbiException(
        response.error!.message ?? 'Multi search failed',
        statusCode: response.statusCode,
        error: response.error,
      );
    }
    throw OmbiException('Multi search failed', statusCode: response.statusCode);
  }

  /// Retrieves movie details by Movie DB ID.
  Future<MovieFullInfoViewModel?> getMovieInfo(String movieDbId) async {
    final response =
        await _rawSearchApi.getSearchMovieByMovieDbId(movieDbId: movieDbId);
    if (response.isSuccess) {
      return response.data;
    }
    if (response.error != null) {
      throw OmbiException(
        response.error!.message ?? 'Movie lookup failed',
        statusCode: response.statusCode,
        error: response.error,
      );
    }
    throw OmbiException('Movie lookup failed', statusCode: response.statusCode);
  }
}
