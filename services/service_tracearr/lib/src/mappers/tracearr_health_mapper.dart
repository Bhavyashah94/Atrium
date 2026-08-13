import '../generated/models/health_response.dart';
import '../generated/models/server_status.dart';
import '../models/tracearr_models.dart';

/// Pure transformation for health response and server status.
class TracearrHealthMapper {
  const TracearrHealthMapper._();

  static TracearrServerStatus mapServer(ServerStatus item) {
    return TracearrServerStatus(
      id: item.id ?? '',
      name: item.name ?? 'Unknown Server',
      type: item.type ?? 'unknown',
      online: item.online ?? false,
      activeStreams: item.activeStreams ?? 0,
    );
  }

  static TracearrHealthResponse fromDto(HealthResponse response) {
    final serverList = response.servers?.map(mapServer).toList() ??
        const <TracearrServerStatus>[];

    return TracearrHealthResponse(
      status: response.status ?? 'ok',
      version: response.version,
      timestamp: response.timestamp != null
          ? DateTime.tryParse(response.timestamp!)
          : null,
      servers: serverList,
    );
  }
}
