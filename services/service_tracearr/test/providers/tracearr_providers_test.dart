import 'package:core_models/core_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:service_tracearr/src/cache/tracearr_artwork_cache.dart';
import 'package:service_tracearr/src/generated/api/raw_public_a_p_i_v2_api.dart';
import 'package:service_tracearr/src/generated/models/cursor_meta.dart';
import 'package:service_tracearr/src/generated/models/history_record.dart';
import 'package:service_tracearr/src/generated/models/history_response.dart';
import 'package:service_tracearr/src/generated/models/recently_added_record.dart';
import 'package:service_tracearr/src/generated/models/recently_added_response.dart';
import 'package:service_tracearr/src/generated/responses/api_response.dart';
import 'package:service_tracearr/src/generated/responses/tracearr_error.dart';
import 'package:service_tracearr/src/providers/tracearr_providers.dart';
import 'package:service_tracearr/src/repository/tracearr_repository.dart';

class FakeV2ApiForProviders implements RawPublicAPIV2Api {
  int historyCalls = 0;
  int recentCalls = 0;
  bool shouldFail = false;
  Duration delay = Duration.zero;

  @override
  Future<ApiResponse<HistoryResponse>> getPublicHistory({
    String? cursor,
    String? pageSize,
    String? userId,
    String? serverId,
    String? mediaId,
    String? ratingKey,
    String? imdbId,
    String? tmdbId,
    String? tvdbId,
    String? mediaType,
    String? watched,
    String? since,
    String? until,
  }) async {
    historyCalls++;
    if (delay > Duration.zero) {
      await Future<void>.delayed(delay);
    }
    if (shouldFail) {
      return const ApiResponse.error(
        TracearrError(message: 'Failed to fetch history'),
        statusCode: 500,
      );
    }

    if (cursor == null) {
      return const ApiResponse.success(
        HistoryResponse(
          data: [HistoryRecord(id: 'h1', mediaTitle: 'Movie 1')],
          meta: CursorMeta(nextCursor: 'cursor_page_2'),
        ),
        statusCode: 200,
      );
    } else {
      return const ApiResponse.success(
        HistoryResponse(
          data: [HistoryRecord(id: 'h2', mediaTitle: 'Movie 2')],
          meta: CursorMeta(),
        ),
        statusCode: 200,
      );
    }
  }

  @override
  Future<ApiResponse<RecentlyAddedResponse>> getPublicRecentlyAdded({
    String? cursor,
    String? pageSize,
    String? serverId,
    String? libraryId,
    String? mediaType,
    String? includeRemoved,
  }) async {
    recentCalls++;
    if (delay > Duration.zero) {
      await Future<void>.delayed(delay);
    }
    if (shouldFail) {
      return const ApiResponse.error(
        TracearrError(message: 'Failed to fetch recent'),
        statusCode: 500,
      );
    }

    final titlePrefix = libraryId != null ? 'Lib-$libraryId' : 'All';
    if (cursor == null) {
      return ApiResponse.success(
        RecentlyAddedResponse(
          data: [
            RecentlyAddedRecord(
              id: 'r1',
              title: '$titlePrefix Item 1',
              ratingKey: '101',
              serverType: 'plex',
              serverId: 's1',
            ),
          ],
          meta: const CursorMeta(nextCursor: 'recent_page_2'),
        ),
        statusCode: 200,
      );
    } else {
      return ApiResponse.success(
        RecentlyAddedResponse(
          data: [
            RecentlyAddedRecord(
              id: 'r2',
              title: '$titlePrefix Item 2',
              ratingKey: '102',
              serverType: 'plex',
              serverId: 's1',
            ),
          ],
          meta: const CursorMeta(),
        ),
        statusCode: 200,
      );
    }
  }

  @override
  Future<ApiResponse<HistoryResponse>> getPublicMediaHistoryByRef({
    required String ref,
    String? cursor,
    String? pageSize,
  }) async {
    return const ApiResponse.success(
      HistoryResponse(
        data: [HistoryRecord(id: 'h_media_1', mediaTitle: 'Media 1')],
      ),
      statusCode: 200,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('Tracearr Providers & Notifiers', () {
    const testInstance = Instance(
      id: 'inst_1',
      name: 'Test Tracearr',
      kind: ServiceKind.tracearr,
      localUrl: 'https://tr.example.com',
      externalUrl: '',
      urlMode: UrlMode.auto,
      auth: InstanceAuthApiKey(apiKey: 'dummy_key'),
    );

    late FakeV2ApiForProviders fakeApi;
    late TracearrRepository repository;
    late ProviderContainer container;

    setUp(() {
      fakeApi = FakeV2ApiForProviders();
      repository = TracearrRepository(
        apiV2: fakeApi,
        artworkCache: TracearrArtworkCache(),
        baseUrl: 'https://tr.example.com',
      );

      container = ProviderContainer(
        overrides: [
          tracearrRepositoryProvider(testInstance)
              .overrideWith((ref) async => repository),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('TracearrHistoryPaginatedNotifier loads initial page and paginates',
        () async {
      final notifier = container
          .read(tracearrHistoryPaginatedProvider(testInstance).notifier);

      // Wait for initial load
      await Future<void>.delayed(const Duration(milliseconds: 50));

      var state =
          container.read(tracearrHistoryPaginatedProvider(testInstance));
      expect(state.isLoadingInitial, isFalse);
      expect(state.items.length, equals(1));
      expect(state.items.first.mediaTitle, equals('Movie 1'));
      expect(state.nextCursor, equals('cursor_page_2'));
      expect(state.hasMore, isTrue);

      // Load more
      await notifier.loadMore();
      state = container.read(tracearrHistoryPaginatedProvider(testInstance));

      expect(state.isLoadingMore, isFalse);
      expect(state.items.length, equals(2));
      expect(state.items[1].mediaTitle, equals('Movie 2'));
      expect(state.nextCursor, isNull);
      expect(state.hasMore, isFalse);
    });

    test('TracearrHistoryPaginatedNotifier captures error states cleanly',
        () async {
      fakeApi.shouldFail = true;
      final notifier = container
          .read(tracearrHistoryPaginatedProvider(testInstance).notifier);

      await Future<void>.delayed(const Duration(milliseconds: 50));

      final state =
          container.read(tracearrHistoryPaginatedProvider(testInstance));
      expect(state.isLoadingInitial, isFalse);
      expect(state.error, isNotNull);
      expect(state.items.isEmpty, isTrue);

      // Retry with recovery
      fakeApi.shouldFail = false;
      await notifier.refresh();

      final recoveredState =
          container.read(tracearrHistoryPaginatedProvider(testInstance));
      expect(recoveredState.error, isNull);
      expect(recoveredState.items.length, equals(1));
    });

    test('TracearrRecentPaginatedNotifier updates when library filter changes',
        () async {
      container.read(tracearrRecentPaginatedProvider(testInstance));

      // Wait for initial load
      await Future<void>.delayed(const Duration(milliseconds: 50));

      var state = container.read(tracearrRecentPaginatedProvider(testInstance));
      expect(state.items.first.title, equals('All Item 1'));

      // Change filter
      container
          .read(tracearrSelectedLibraryFilterProvider(testInstance).notifier)
          .state = '42';

      await Future<void>.delayed(const Duration(milliseconds: 50));

      state = container.read(tracearrRecentPaginatedProvider(testInstance));
      expect(state.items.first.title, equals('Lib-42 Item 1'));
    });

    test(
        'TracearrRecentPaginatedNotifier race protection discards older requests',
        () async {
      container.read(tracearrRecentPaginatedProvider(testInstance).notifier);

      await Future<void>.delayed(const Duration(milliseconds: 50));

      // Rapidly switch library and refresh
      fakeApi.delay = const Duration(milliseconds: 20);
      container
          .read(tracearrSelectedLibraryFilterProvider(testInstance).notifier)
          .state = 'lib_slow';

      // Immediately refresh before lib_slow finishes
      await Future<void>.delayed(const Duration(milliseconds: 5));
      container
          .read(tracearrSelectedLibraryFilterProvider(testInstance).notifier)
          .state = 'lib_fast';

      await Future<void>.delayed(const Duration(milliseconds: 60));

      final state =
          container.read(tracearrRecentPaginatedProvider(testInstance));
      expect(state.items.first.title, equals('Lib-lib_fast Item 1'));
    });

    test('tracearrMediaHistoryProvider returns history page for media item',
        () async {
      final historyPage = await container.read(
        tracearrMediaHistoryProvider((testInstance, 'med_1')).future,
      );
      expect(historyPage.items.length, equals(1));
      expect(historyPage.items.first.id, equals('h_media_1'));
    });
  });
}
