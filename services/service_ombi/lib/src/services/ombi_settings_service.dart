import '../generated/api/raw_settings_api.dart';
import '../generated/responses/ombi_exception.dart';

/// High-level service wrapper for Ombi settings endpoints.
class OmbiSettingsService {
  final RawSettingsApi _rawSettingsApi;

  OmbiSettingsService(this._rawSettingsApi);

  /// Retrieves general Ombi system settings.
  Future<dynamic> getOmbiSettings() async {
    final response = await _rawSettingsApi.getSettingsOmbi();
    if (response.isSuccess) {
      return response.data;
    }
    if (response.error != null) {
      throw OmbiException(
        response.error!.message ?? 'Failed to fetch Ombi settings',
        statusCode: response.statusCode,
        error: response.error,
      );
    }
    throw OmbiException('Failed to fetch Ombi settings', statusCode: response.statusCode);
  }
}
