import 'package:dio/dio.dart';

import '../generated/api/raw_album_api.dart';
import '../generated/api/raw_artist_api.dart';
import '../generated/api/raw_artist_lookup_api.dart';
import '../generated/api/raw_command_api.dart';
import '../generated/api/raw_history_api.dart';
import '../generated/api/raw_queue_api.dart';

import 'lidarr_album_service.dart';
import 'lidarr_artist_service.dart';

/// Central client for Lidarr API services.
class LidarrClient {
  final Dio dio;
  final String baseUrl;
  final String? apiKey;

  late final RawArtistApi rawArtistApi;
  late final RawArtistLookupApi rawArtistLookupApi;
  late final RawAlbumApi rawAlbumApi;
  late final RawQueueApi rawQueueApi;
  late final RawHistoryApi rawHistoryApi;
  late final RawCommandApi rawCommandApi;

  late final LidarrArtistService artistService;
  late final LidarrAlbumService albumService;

  LidarrClient({
    Dio? dio,
    required this.baseUrl,
    this.apiKey,
  }) : dio = dio ?? Dio() {
    this.dio.options.baseUrl = baseUrl.endsWith('/') ? baseUrl : '$baseUrl/';
    if (apiKey != null && apiKey!.isNotEmpty) {
      this.dio.options.headers['X-Api-Key'] = apiKey;
    }

    rawArtistApi = RawArtistApi(this.dio);
    rawArtistLookupApi = RawArtistLookupApi(this.dio);
    rawAlbumApi = RawAlbumApi(this.dio);
    rawQueueApi = RawQueueApi(this.dio);
    rawHistoryApi = RawHistoryApi(this.dio);
    rawCommandApi = RawCommandApi(this.dio);

    artistService = LidarrArtistService(rawArtistApi, rawArtistLookupApi);
    albumService = LidarrAlbumService(rawAlbumApi);
  }
}
