import 'package:flutter_test/flutter_test.dart';
import 'package:service_tracearr/src/generated/models/cursor_meta.dart';
import 'package:service_tracearr/src/generated/models/history_record.dart';
import 'package:service_tracearr/src/generated/models/history_response.dart';
import 'package:service_tracearr/src/generated/models/history_user.dart';
import 'package:service_tracearr/src/mappers/tracearr_history_mapper.dart';

void main() {
  group('TracearrHistoryMapper', () {
    const baseUrl = 'https://tr.example.com';

    test('maps HistoryRecord with userId and serverUserId correctly', () {
      const dto = HistoryRecord(
        id: 'hist_1',
        serverId: 'srv_1',
        serverName: 'Server 1',
        serverType: 'jellyfin',
        mediaTitle: 'Interstellar',
        watched: true,
        percentComplete: 99.5,
        durationMs: 10000000,
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
