import 'package:flutter_test/flutter_test.dart';
import 'package:service_tracearr/src/generated/models/cursor_meta.dart';
import 'package:service_tracearr/src/generated/models/history_record.dart';
import 'package:service_tracearr/src/generated/models/history_response.dart';
import 'package:service_tracearr/src/generated/models/history_user.dart';
import 'package:service_tracearr/src/generated/models/source_video_details.dart';
import 'package:service_tracearr/src/generated/models/stream_video_details.dart';
import 'package:service_tracearr/src/generated/models/subtitle_info.dart';
import 'package:service_tracearr/src/generated/models/transcode_info.dart';
import 'package:service_tracearr/src/mappers/tracearr_history_mapper.dart';

void main() {
  group('TracearrHistoryMapper', () {
    const baseUrl = 'https://tr.example.com';

    test('maps HistoryRecord with full diagnostic telemetry correctly', () {
      const dto = HistoryRecord(
        id: 'hist_1',
        serverId: 'srv_1',
        serverName: 'Server 1',
        serverType: 'jellyfin',
        mediaTitle: 'Interstellar',
        watched: true,
        percentComplete: 99.5,
        durationMs: 10000000,
        resolution: '1080p',
        sourceVideoWidth: 3840,
        sourceVideoHeight: 2160,
        sourceVideoDetails: SourceVideoDetails(dynamicRange: 'HDR10'),
        streamVideoDetails: StreamVideoDetails(
          width: 1920,
          height: 1080,
          dynamicRange: 'SDR',
        ),
        transcodeInfo: TranscodeInfo(
          speed: 3.4,
          throttled: true,
          containerDecision: 'transcode',
          sourceContainer: 'mkv',
          streamContainer: 'mpegts',
          hwRequested: true,
          hwDecoding: 'nvenc',
          hwEncoding: 'nvenc',
          reasons: ['Container not supported'],
        ),
        subtitleInfo: SubtitleInfo(
          decision: 'burn',
          codec: 'pgs',
          language: 'English',
        ),
        user: HistoryUser(
          id: 'user-identity-uuid-1',
          serverUserId: 'server-account-uuid-2',
          username: 'Bhavyashah',
          avatarUrl: '/avatars/1.png',
        ),
        startedAt: '2026-01-01T10:00:00.000Z',
        stoppedAt: '2026-01-01T12:45:00.000Z',
        segmentCount: 2,
      );

      final domain = TracearrHistoryMapper.fromDto(dto, baseUrl: baseUrl);

      expect(domain.id, equals('hist_1'));
      expect(domain.serverId, equals('srv_1'));
      expect(domain.mediaTitle, equals('Interstellar'));
      expect(domain.watched, isTrue);
      expect(domain.percentComplete, equals(99.5));
      expect(domain.userId, equals('user-identity-uuid-1'));
      expect(domain.serverUserId, equals('server-account-uuid-2'));
      expect(domain.userUsername, equals('Bhavyashah'));
      expect(
        domain.userAvatarUrl,
        equals('https://tr.example.com/avatars/1.png'),
      );
      expect(domain.segmentCount, equals(2));
      expect(domain.transcodeSpeed, equals(3.4));
      expect(domain.isThrottled, isTrue);
      expect(domain.sourceDynamicRange, equals('HDR10'));
      expect(domain.streamDynamicRange, equals('SDR'));
      expect(domain.sourceResolution, equals('3840x2160'));
      expect(domain.streamResolution, equals('1920x1080'));
      expect(domain.sourceContainer, equals('mkv'));
      expect(domain.streamContainer, equals('mpegts'));
      expect(domain.containerDecision, equals('transcode'));
      expect(domain.subtitleDecision, equals('burn'));
      expect(domain.subtitleCodec, equals('pgs'));
      expect(domain.subtitleLanguage, equals('English'));
      expect(domain.transcodeReasons, equals(['Container not supported']));
    });

    test('maps HistoryResponse to TracearrHistoryPage with cursor', () {
      const response = HistoryResponse(
        data: [
          HistoryRecord(id: 'hist_1', mediaTitle: 'Movie A'),
          HistoryRecord(id: 'hist_2', mediaTitle: 'Movie B'),
        ],
        meta: CursorMeta(nextCursor: 'cursor_xyz_123'),
      );

      final page = TracearrHistoryMapper.fromPageResponse(
        response,
        baseUrl: baseUrl,
      );

      expect(page.items.length, equals(2));
      expect(page.items[0].mediaTitle, equals('Movie A'));
      expect(page.items[1].mediaTitle, equals('Movie B'));
      expect(page.nextCursor, equals('cursor_xyz_123'));
    });
  });
}
