import 'package:flutter_test/flutter_test.dart';
import 'package:service_tracearr/src/generated/models/health_response.dart';
import 'package:service_tracearr/src/generated/models/server_status.dart';
import 'package:service_tracearr/src/mappers/tracearr_health_mapper.dart';

void main() {
  group('TracearrHealthMapper', () {
    test('maps health response with servers correctly', () {
      const response = HealthResponse(
        status: 'healthy',
        version: '2.4.1',
        timestamp: '2026-08-14T02:00:00Z',
        servers: [
          ServerStatus(
            id: 'srv_1',
            name: 'Plex Media Server',
            type: 'plex',
            online: true,
            activeStreams: 3,
          ),
          ServerStatus(
            id: 'srv_2',
            name: 'Jellyfin Lab',
            type: 'jellyfin',
            online: false,
            activeStreams: 0,
          ),
        ],
      );

      final domain = TracearrHealthMapper.fromDto(response);

      expect(domain.status, 'healthy');
      expect(domain.version, '2.4.1');
      expect(domain.timestamp, DateTime.parse('2026-08-14T02:00:00Z'));
      expect(domain.servers.length, 2);
      expect(domain.servers[0].id, 'srv_1');
      expect(domain.servers[0].name, 'Plex Media Server');
      expect(domain.servers[0].type, 'plex');
      expect(domain.servers[0].online, isTrue);
      expect(domain.servers[0].activeStreams, 3);
      expect(domain.servers[1].online, isFalse);
    });

    test('handles empty and null fields gracefully', () {
      const response = HealthResponse();
      final domain = TracearrHealthMapper.fromDto(response);

      expect(domain.status, 'ok');
      expect(domain.version, isNull);
      expect(domain.timestamp, isNull);
      expect(domain.servers, isEmpty);
    });
  });
}
