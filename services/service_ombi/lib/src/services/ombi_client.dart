import 'package:dio/dio.dart';

import '../generated/api/raw_calendar_api.dart';
import '../generated/api/raw_identity_api.dart';
import '../generated/api/raw_issues_api.dart';
import '../generated/api/raw_plex_api.dart';
import '../generated/api/raw_radarr_api.dart';
import '../generated/api/raw_request_api.dart';
import '../generated/api/raw_requests_api.dart';
import '../generated/api/raw_search_api.dart';
import '../generated/api/raw_settings_api.dart';
import '../generated/api/raw_sonarr_api.dart';
import 'ombi_request_service.dart';
import 'ombi_search_service.dart';
import 'ombi_settings_service.dart';

/// Central client for Ombi API services.
class OmbiClient {
  final Dio dio;
  final String baseUrl;
  final String? apiKey;

  late final RawSearchApi rawSearchApi;
  late final RawRequestApi rawRequestApi;
  late final RawRequestsApi rawRequestsApi;
  late final RawSettingsApi rawSettingsApi;
  late final RawIdentityApi rawIdentityApi;
  late final RawCalendarApi rawCalendarApi;
  late final RawIssuesApi rawIssuesApi;
  late final RawSonarrApi rawSonarrApi;
  late final RawRadarrApi rawRadarrApi;
  late final RawPlexApi rawPlexApi;

  late final OmbiSearchService searchService;
  late final OmbiRequestService requestService;
  late final OmbiSettingsService settingsService;

  OmbiClient({
    Dio? dio,
    required this.baseUrl,
    this.apiKey,
  }) : dio = dio ?? Dio() {
    this.dio.options.baseUrl = baseUrl.endsWith('/') ? baseUrl : '$baseUrl/';
    if (apiKey != null && apiKey!.isNotEmpty) {
      this.dio.options.headers['ApiKey'] = apiKey;
    }

    rawSearchApi = RawSearchApi(this.dio);
    rawRequestApi = RawRequestApi(this.dio);
    rawRequestsApi = RawRequestsApi(this.dio);
    rawSettingsApi = RawSettingsApi(this.dio);
    rawIdentityApi = RawIdentityApi(this.dio);
    rawCalendarApi = RawCalendarApi(this.dio);
    rawIssuesApi = RawIssuesApi(this.dio);
    rawSonarrApi = RawSonarrApi(this.dio);
    rawRadarrApi = RawRadarrApi(this.dio);
    rawPlexApi = RawPlexApi(this.dio);

    searchService = OmbiSearchService(rawSearchApi);
    requestService = OmbiRequestService(rawRequestApi);
    settingsService = OmbiSettingsService(rawSettingsApi);
  }
}
