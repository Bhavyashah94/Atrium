import '../generated/models/active_stream.dart';
import '../media/tracearr_media_url_resolver.dart';
import '../models/tracearr_models.dart';

/// Pure transformation from raw [ActiveStream] DTO to domain [TracearrStream].
class TracearrStreamMapper {
  const TracearrStreamMapper._();

  static TracearrStream fromDto(
    ActiveStream item, {
    required String baseUrl,
  }) {
    final sId = item.serverId ?? '';
    final rKey = item.ratingKey;
    final mId = item.mediaId;
    final tPath = item.thumbPath;
    final avatarUrl = TracearrMediaUrlResolver.formatUrl(
      baseUrl: baseUrl,
      rawUrl: item.userAvatarUrl,
    );
    final posterUrl = TracearrMediaUrlResolver.formatUrl(
      baseUrl: baseUrl,
      rawUrl: item.posterUrl,
    );

    double? pct;
    if (item.progressMs != null &&
        item.durationMs != null &&
        item.durationMs! > 0) {
      pct = (item.progressMs! / item.durationMs!) * 100;
    }

    final tInfo = item.transcodeInfo;
    final isHw = (tInfo?.hwDecoding != null && tInfo!.hwDecoding!.isNotEmpty) ||
        (tInfo?.hwEncoding != null && tInfo!.hwEncoding!.isNotEmpty) ||
        (tInfo?.hwRequested == true);

    return TracearrStream(
      id: item.id ?? '',
      serverId: sId,
      serverName: item.serverName ?? '',
      serverType: item.serverType ?? '',
      mediaTitle: item.mediaTitle ?? '',
      showTitle: item.showTitle,
      seasonNumber: item.seasonNumber,
      episodeNumber: item.episodeNumber,
      year: item.year,
      userUsername: item.username ?? 'Unknown',
      userAvatarUrl: avatarUrl,
      thumbPath: tPath,
      posterUrl: posterUrl,
      bitrate: item.bitrate,
      resolution: item.resolution,
      videoDecision: item.videoDecision,
      audioDecision: item.audioDecision,
      isTranscode: item.isTranscode ?? false,
      isHwTranscode: isHw,
      hwDecoding: tInfo?.hwDecoding,
      hwEncoding: tInfo?.hwEncoding,
      transcodeSpeed: tInfo?.speed,
      isThrottled: tInfo?.throttled,
      mediaId: mId,
      ratingKey: rKey,
      progressMs: item.progressMs,
      durationMs: item.durationMs,
      percentComplete: pct,
      product: item.product,
      player: item.player,
      device: item.device,
      platform: item.platform,
      videoCodec: item.sourceVideoCodecDisplay ?? item.sourceVideoCodec,
      audioCodec: item.sourceAudioCodecDisplay ?? item.sourceAudioCodec,
      audioChannels: item.audioChannelsDisplay,
      transcodeReasons: tInfo?.reasons ?? const <String>[],
      state: item.state,
      startedAt:
          item.startedAt != null ? DateTime.tryParse(item.startedAt!) : null,
      subtitleLanguage: item.subtitleInfo?.language,
      subtitleCodec: item.subtitleInfo?.codec,
      artistName: item.artistName,
      albumName: item.albumName,
      trackNumber: item.trackNumber,
    );
  }

  static List<TracearrStream> fromDtoList(
    List<ActiveStream> list, {
    required String baseUrl,
  }) {
    return list.map((item) => fromDto(item, baseUrl: baseUrl)).toList();
  }
}
