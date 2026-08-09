import 'package:cached_network_image/cached_network_image.dart';
import 'package:core_models/core_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/tracearr_v2_models.dart';
import '../tracearr_api.dart';
import '../tracearr_providers.dart';
import '../utils/tracearr_formatters.dart';
import 'tracearr_user_avatar.dart';

/// Modal bottom sheet displaying deep playback session technical specs, transcode decisions,
/// audio/video codecs, device info, and user details matching Tracearr's official web session detail panel.
class TracearrSessionDetailBottomSheet extends ConsumerWidget {
  const TracearrSessionDetailBottomSheet.history({
    required this.instance,
    required TracearrV2HistoryRecord record,
    super.key,
  })  : historyRecord = record,
        activeStream = null;

  const TracearrSessionDetailBottomSheet.stream({
    required this.instance,
    required TracearrV2ActiveStream stream,
    super.key,
  })  : activeStream = stream,
        historyRecord = null;

  final Instance instance;
  final TracearrV2HistoryRecord? historyRecord;
  final TracearrV2ActiveStream? activeStream;

  static void showHistory(
    BuildContext context, {
    required Instance instance,
    required TracearrV2HistoryRecord record,
  }) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => TracearrSessionDetailBottomSheet.history(
        instance: instance,
        record: record,
      ),
    );
  }

  static void showStream(
    BuildContext context, {
    required Instance instance,
    required TracearrV2ActiveStream stream,
  }) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => TracearrSessionDetailBottomSheet.stream(
        instance: instance,
        stream: stream,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;

    final TracearrApi? api = ref.watch(tracearrApiProvider(instance)).value;
    final Map<String, String> serverMap =
        ref.watch(tracearrServerNamesMapProvider(instance));

    final String username = historyRecord?.effectiveUsername ??
        activeStream?.effectiveUsername ??
        'Unknown User';
    final String? avatarPath = historyRecord?.effectiveUserAvatar ??
        activeStream?.userAvatarUrl ??
        activeStream?.userThumb;
    final String? avatarUrl = api?.imageUrl(avatarPath);

    final String? rawPoster = historyRecord?.posterUrl ??
        historyRecord?.thumbPath ??
        activeStream?.posterUrl ??
        activeStream?.thumbPath;
    String? posterUrl = api?.imageUrl(rawPoster);

    // Dynamic Image Proxy fallback if direct poster is missing
    final String? ratingKey = historyRecord?.ratingKey ?? activeStream?.ratingKey;
    final String? serverId = historyRecord?.serverId ?? activeStream?.serverId;
    final String? serverType = historyRecord?.serverType ?? activeStream?.serverType;

    if (posterUrl == null && ratingKey != null && serverId != null) {
      final String sType = serverType ?? 'media';
      final String path = sType == 'plex'
          ? '/api/v1/images/proxy?server=$serverId&url=${Uri.encodeComponent('/library/metadata/$ratingKey/thumb')}'
          : '/api/v1/images/proxy?server=$serverId&url=${Uri.encodeComponent('/Items/$ratingKey/Images/Primary')}';
      posterUrl = api?.imageUrl(path);
    }

    final String title = historyRecord?.mediaTitle ??
        historyRecord?.showTitle ??
        activeStream?.mediaTitle ??
        activeStream?.showTitle ??
        'Playback Session';

    final String? grandParent = historyRecord?.showTitle ?? activeStream?.showTitle;
    final int? sNum = historyRecord?.seasonNumber ?? activeStream?.seasonNumber;
    final int? eNum = historyRecord?.episodeNumber ?? activeStream?.episodeNumber;

    final List<String> subtitleParts = <String>[];
    if (grandParent != null && grandParent != title) {
      subtitleParts.add(grandParent);
    }
    if (sNum != null && eNum != null) {
      subtitleParts.add(
        'S${sNum.toString().padLeft(2, '0')}E${eNum.toString().padLeft(2, '0')}',
      );
    } else if (historyRecord?.artistName != null || activeStream?.artistName != null) {
      final String artist = historyRecord?.artistName ?? activeStream?.artistName ?? '';
      final String album = historyRecord?.albumName ?? activeStream?.albumName ?? '';
      if (artist.isNotEmpty) subtitleParts.add(artist);
      if (album.isNotEmpty) subtitleParts.add(album);
    }
    final String subtitle = subtitleParts.join(' • ');

    final String serverDisplayName = resolveServerName(
      serverMap: serverMap,
      serverName: historyRecord?.serverName ?? activeStream?.serverName,
      serverId: historyRecord?.serverId ?? activeStream?.serverId,
      serverType: historyRecord?.serverType ?? activeStream?.serverType,
    );

    final bool isTranscode = historyRecord?.isTranscode ??
        activeStream?.isTranscode ??
        false;
    final String vDecision = (historyRecord?.videoDecision ??
            activeStream?.videoDecision ??
            'directplay')
        .toUpperCase();
    final String aDecision = (historyRecord?.audioDecision ??
            activeStream?.audioDecision ??
            'directplay')
        .toUpperCase();

    final int bitrate = historyRecord?.bitrate ?? activeStream?.bitrate ?? 0;
    final String bitrateText = bitrate > 1000
        ? '${(bitrate / 1000).toStringAsFixed(1)} Mbps'
        : (bitrate > 0 ? '$bitrate kbps' : '');

    final String vCodec = historyRecord?.sourceVideoCodecDisplay ??
        historyRecord?.sourceVideoCodec ??
        activeStream?.sourceVideoCodecDisplay ??
        activeStream?.sourceVideoCodec ??
        '';
    final String res = historyRecord?.resolution ?? activeStream?.resolution ?? '';
    final String videoSpec =
        <String>[vCodec, res].where((s) => s.isNotEmpty).join(' ');

    final String aCodec = historyRecord?.sourceAudioCodecDisplay ??
        historyRecord?.sourceAudioCodec ??
        activeStream?.sourceAudioCodecDisplay ??
        activeStream?.sourceAudioCodec ??
        '';
    final String aChannels = historyRecord?.audioChannelsDisplay ??
        activeStream?.audioChannelsDisplay ??
        '';
    final String audioSpec =
        <String>[aCodec, aChannels].where((s) => s.isNotEmpty).join(' ');

    final String formattedDate = formatTracearrTimestamp(
      historyRecord?.startedAt ??
          historyRecord?.stoppedAt ??
          activeStream?.startedAt,
    );

    final int durationMs =
        historyRecord?.durationMs ?? activeStream?.durationMs ?? 0;
    final double percent = historyRecord?.percentComplete ?? 0;
    final String durationText =
        durationMs > 0 ? formatTracearrWatchTime(durationMs) : '';

    final String product = historyRecord?.product ?? activeStream?.product ?? '';
    final String player = historyRecord?.player ??
        activeStream?.player ??
        activeStream?.effectivePlayer ??
        '';
    final String device = historyRecord?.device ??
        activeStream?.device ??
        activeStream?.effectiveDevice ??
        '';

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // Drag Handle
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: cs.onSurfaceVariant.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Header Media & User Info Card
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: SizedBox(
                    width: 70,
                    height: 100,
                    child: posterUrl != null
                        ? CachedNetworkImage(
                            imageUrl: posterUrl,
                            fit: BoxFit.cover,
                            errorWidget: (_, __, ___) => Container(
                              color: cs.surfaceContainerHighest,
                              child: Icon(
                                Icons.movie_outlined,
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                          )
                        : Container(
                            color: cs.surfaceContainerHighest,
                            child: Icon(
                              Icons.movie_outlined,
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (subtitle.isNotEmpty) ...<Widget>[
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 10),

                      // User info pill
                      Row(
                        children: <Widget>[
                          TracearrUserAvatar(
                            username: username,
                            avatarUrl: avatarUrl,
                            radius: 12,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              username,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Transcode Decision Status Badges
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: <Widget>[
                Chip(
                  visualDensity: VisualDensity.compact,
                  backgroundColor: isTranscode
                      ? cs.tertiaryContainer
                      : cs.primaryContainer,
                  side: BorderSide.none,
                  label: Text(
                    isTranscode ? 'TRANSCODE' : 'DIRECT PLAY',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isTranscode
                          ? cs.onTertiaryContainer
                          : cs.onPrimaryContainer,
                    ),
                  ),
                ),
                Chip(
                  visualDensity: VisualDensity.compact,
                  backgroundColor: cs.surfaceContainerHighest,
                  side: BorderSide.none,
                  label: Text(
                    'Video: $vDecision',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ),
                Chip(
                  visualDensity: VisualDensity.compact,
                  backgroundColor: cs.surfaceContainerHighest,
                  side: BorderSide.none,
                  label: Text(
                    'Audio: $aDecision',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Technical Stream Metrics Card
            Card(
              elevation: 0,
              color: cs.surfaceContainerHigh,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              child: Padding(
                padding: const EdgeInsets.all(14.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Stream Technical Details',
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: cs.primary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (bitrateText.isNotEmpty)
                      _DetailRow(
                        icon: Icons.speed,
                        label: 'Stream Bitrate',
                        value: bitrateText,
                        cs: cs,
                        theme: theme,
                      ),
                    if (videoSpec.isNotEmpty)
                      _DetailRow(
                        icon: Icons.videocam_outlined,
                        label: 'Video Stream',
                        value: videoSpec,
                        cs: cs,
                        theme: theme,
                      ),
                    if (audioSpec.isNotEmpty)
                      _DetailRow(
                        icon: Icons.audiotrack_outlined,
                        label: 'Audio Stream',
                        value: audioSpec,
                        cs: cs,
                        theme: theme,
                      ),
                    if (durationText.isNotEmpty)
                      _DetailRow(
                        icon: Icons.timer_outlined,
                        label: 'Watch Duration',
                        value: percent > 0
                            ? '$durationText (${percent.toStringAsFixed(0)}%)'
                            : durationText,
                        cs: cs,
                        theme: theme,
                      ),
                    if (formattedDate.isNotEmpty)
                      _DetailRow(
                        icon: Icons.event_outlined,
                        label: 'Timestamp',
                        value: formattedDate,
                        cs: cs,
                        theme: theme,
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Player & Device Environment Card
            Card(
              elevation: 0,
              color: cs.surfaceContainerHigh,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              child: Padding(
                padding: const EdgeInsets.all(14.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Client & Server Info',
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: cs.primary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _DetailRow(
                      icon: Icons.dns_outlined,
                      label: 'Media Server',
                      value: serverDisplayName,
                      cs: cs,
                      theme: theme,
                    ),
                    if (product.isNotEmpty)
                      _DetailRow(
                        icon: Icons.devices_outlined,
                        label: 'Client Product',
                        value: product,
                        cs: cs,
                        theme: theme,
                      ),
                    if (player.isNotEmpty)
                      _DetailRow(
                        icon: Icons.play_circle_outline,
                        label: 'Player App',
                        value: player,
                        cs: cs,
                        theme: theme,
                      ),
                    if (device.isNotEmpty)
                      _DetailRow(
                        icon: Icons.important_devices_outlined,
                        label: 'Device / Platform',
                        value: device,
                        cs: cs,
                        theme: theme,
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.cs,
    required this.theme,
  });

  final IconData icon;
  final String label;
  final String value;
  final ColorScheme cs;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: <Widget>[
          Icon(icon, size: 16, color: cs.onSurfaceVariant),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: theme.textTheme.bodySmall?.copyWith(
              color: cs.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: cs.onSurface,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
