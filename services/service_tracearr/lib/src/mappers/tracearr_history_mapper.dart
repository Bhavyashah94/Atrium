import '../generated/models/history_record.dart';
import '../generated/models/history_response.dart';
import '../media/tracearr_media_url_resolver.dart';
import '../models/tracearr_models.dart';

/// Pure transformation from raw [HistoryRecord] DTO to domain [TracearrHistoryItem].
class TracearrHistoryMapper {
  const TracearrHistoryMapper._();

  static TracearrHistoryItem fromDto(
    HistoryRecord item, {
    required String baseUrl,
  }) {
    final avatarUrl = TracearrMediaUrlResolver.formatUrl(
      baseUrl: baseUrl,
      rawUrl: item.user?.avatarUrl,
    );
    final posterUrl = TracearrMediaUrlResolver.formatUrl(
      baseUrl: baseUrl,
      rawUrl: item.posterUrl,
    );

    final tInfo = item.transcodeInfo;
    final isHw = (tInfo?.hwDecoding != null && tInfo!.hwDecoding!.isNotEmpty) ||
        (tInfo?.hwEncoding != null && tInfo!.hwEncoding!.isNotEmpty) ||
        (tInfo?.hwRequested == true);

    final sourceRes =
        (item.sourceVideoWidth != null && item.sourceVideoHeight != null)
            ? '${item.sourceVideoWidth}x${item.sourceVideoHeight}'
            : null;

    final streamRes = (item.streamVideoDetails?.width != null &&
            item.streamVideoDetails?.height != null)
        ? '${item.streamVideoDetails!.width!.toInt()}x${item.streamVideoDetails!.height!.toInt()}'
        : null;

    return TracearrHistoryItem(
      id: item.id ?? '',
      serverId: item.serverId ?? '',
      serverName: item.serverName ?? '',
      serverType: item.serverType ?? '',
      mediaTitle: item.mediaTitle ?? '',
      showTitle: item.showTitle,
      seasonNumber: item.seasonNumber,
      episodeNumber: item.episodeNumber,
      year: item.year,
      userUsername: item.user?.username ?? 'Unknown',
      userAvatarUrl: avatarUrl,
      thumbPath: item.thumbPath,
      posterUrl: posterUrl,
      startedAt:
          item.startedAt != null ? DateTime.tryParse(item.startedAt!) : null,
      stoppedAt:
          item.stoppedAt != null ? DateTime.tryParse(item.stoppedAt!) : null,
      watched: item.watched ?? false,
      percentComplete: item.percentComplete,
      durationMs: item.durationMs,
      mediaId: item.mediaId,
      ratingKey: item.ratingKey,
      device: item.device,
      player: item.player,
      product: item.product,
      platform: item.platform,
      isTranscode: item.isTranscode,
      isHwTranscode: isHw,
      hwDecoding: tInfo?.hwDecoding,
      hwEncoding: tInfo?.hwEncoding,
      videoDecision: item.videoDecision,
      audioDecision: item.audioDecision,
      bitrate: item.bitrate,
      resolution: item.resolution,
      videoCodec: item.sourceVideoCodecDisplay ?? item.sourceVideoCodec,
      audioCodec: item.sourceAudioCodecDisplay ?? item.sourceAudioCodec,
      audioChannels: item.audioChannelsDisplay,
      transcodeReasons: tInfo?.reasons ?? const <String>[],
      subtitleLanguage: item.subtitleInfo?.language,
      subtitleCodec: item.subtitleInfo?.codec,
      subtitleDecision: item.subtitleInfo?.decision,
      transcodeSpeed: tInfo?.speed,
      isThrottled: tInfo?.throttled,
      sourceDynamicRange: item.sourceVideoDetails?.dynamicRange,
      streamDynamicRange: item.streamVideoDetails?.dynamicRange,
      sourceResolution: sourceRes,
      streamResolution: streamRes,
      sourceContainer: tInfo?.sourceContainer,
      streamContainer: tInfo?.streamContainer,
      containerDecision: tInfo?.containerDecision,
      userId: item.user?.id,
      serverUserId: item.user?.serverUserId,
      segmentCount: item.segmentCount,
    );
  }

  static TracearrHistoryPage fromPageResponse(
    HistoryResponse response, {
    required String baseUrl,
  }) {
    final data = response.data ?? <HistoryRecord>[];
    final items = data.map((item) => fromDto(item, baseUrl: baseUrl)).toList();
    final nextCursor = response.meta?.nextCursor;
    return TracearrHistoryPage(items: items, nextCursor: nextCursor);
  }
}
