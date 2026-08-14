import 'package:flutter_test/flutter_test.dart';
import 'package:service_tracearr/src/generated/models/active_stream.dart';
import 'package:service_tracearr/src/generated/models/transcode_info.dart';
import 'package:service_tracearr/src/mappers/tracearr_stream_mapper.dart';

void main() {
  group('TracearrStreamMapper', () {
    const baseUrl = 'https://tr.example.com';

    test('maps ActiveStream DTO to TracearrStream correctly', () {
      const dto = ActiveStream(
        id: 'st_1',
        serverId: 'srv_1',
        serverName: 'Main Server',
        serverType: 'plex',
        mediaTitle: 'Inception',
        year: 2010,
        username: 'Bhavyashah',
        userAvatarUrl: '/avatar.jpg',
        thumbPath: '/thumb.jpg',
        posterUrl: '/poster.jpg',
        bitrate: 15000,
        resolution: '4K',
        videoDecision: 'transcode',
        audioDecision: 'direct',
        isTranscode: true,
        mediaId: 'med_1',
        ratingKey: 'rk_1',
        progressMs: 3600000,
        durationMs: 7200000,
        product: 'Plex for iOS',
        player: 'iPhone 15',
        device: 'iOS',
        platform: 'iOS',
        sourceVideoCodecDisplay: 'HEVC',
        sourceAudioCodecDisplay: 'TrueHD 7.1',
        audioChannelsDisplay: '7.1',
        transcodeInfo: TranscodeInfo(reasons: ['bandwidth_limit']),
        state: 'playing',
        startedAt: '2026-01-01T12:00:00.000Z',
      );

      final domain = TracearrStreamMapper.fromDto(dto, baseUrl: baseUrl);

      expect(domain.id, equals('st_1'));
      expect(domain.serverId, equals('srv_1'));
      expect(domain.serverName, equals('Main Server'));
      expect(domain.serverType, equals('plex'));
      expect(domain.mediaTitle, equals('Inception'));
      expect(domain.userUsername, equals('Bhavyashah'));
      expect(domain.userAvatarUrl, equals('https://tr.example.com/avatar.jpg'));
      expect(domain.posterUrl, equals('https://tr.example.com/poster.jpg'));
      expect(domain.percentComplete, equals(50.0));
      expect(domain.isTranscode, isTrue);
      expect(domain.videoCodec, equals('HEVC'));
      expect(domain.audioCodec, equals('TrueHD 7.1'));
      expect(domain.transcodeReasons, equals(['bandwidth_limit']));
      expect(domain.state, equals('playing'));
      expect(
        domain.startedAt,
        equals(DateTime.parse('2026-01-01T12:00:00.000Z')),
      );
    });

    test('handles missing or zero duration gracefully', () {
      const dto = ActiveStream(
        id: 'st_2',
        mediaTitle: 'Track 1',
        progressMs: 100,
        durationMs: 0,
      );

      final domain = TracearrStreamMapper.fromDto(dto, baseUrl: baseUrl);
      expect(domain.percentComplete, isNull);
      expect(domain.userUsername, equals('Unknown'));
      expect(domain.isTranscode, isFalse);
    });
  });
}
