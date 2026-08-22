import 'package:core_models/core_models.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';
import '../../models/tracearr_models.dart';
import 'terminate_stream_dialog.dart';

/// Modal bottom sheet providing deep telemetry and diagnostics for an active stream.
class StreamDiagnosticsSheet extends StatelessWidget {
  const StreamDiagnosticsSheet({
    required this.instance,
    required this.stream,
    super.key,
  });

  final Instance instance;
  final TracearrStream stream;

  static void show(
    BuildContext context, {
    required Instance instance,
    required TracearrStream stream,
  }) {
    showModalBottomSheet<void>(
      useRootNavigator: true,
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(Radii.lg)),
      ),
      builder: (context) => StreamDiagnosticsSheet(
        instance: instance,
        stream: stream,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final String videoDecision = stream.videoDecision?.toLowerCase() == 'copy'
        ? 'DIRECT STREAM (COPY)'
        : stream.videoDecision?.toUpperCase() ??
            (stream.isTranscode ? 'TRANSCODE' : 'DIRECT PLAY');
    final String audioDecision = stream.audioDecision?.toUpperCase() ??
        (stream.isTranscode ? 'TRANSCODE' : 'DIRECT PLAY');

    final bool isHw = stream.isHwTranscode ||
        (stream.hwDecoding != null && stream.hwDecoding!.isNotEmpty) ||
        (stream.hwEncoding != null && stream.hwEncoding!.isNotEmpty);

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            // Handle bar
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: Insets.sm),
              decoration: BoxDecoration(
                color: colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.all(Insets.lg),
                children: [
                  // Title & User Header
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              stream.mediaTitle,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (stream.showTitle != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                '${stream.showTitle} • S${stream.seasonNumber}:E${stream.episodeNumber}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                            const SizedBox(height: 4),
                            Text(
                              '@${stream.userUsername} on ${stream.serverName} (${stream.serverType.toUpperCase()})',
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: Insets.lg),
                  const Divider(height: 1),
                  const SizedBox(height: Insets.md),

                  // Video Stream Diagnostics
                  const _SectionHeader(
                    title: 'VIDEO TELEMETRY',
                    icon: Icons.videocam_outlined,
                  ),
                  const SizedBox(height: Insets.sm),
                  _TelemetryRow(
                    label: 'Decision',
                    value: videoDecision,
                    highlight: stream.isTranscode,
                  ),
                  if (stream.videoCodec != null)
                    _TelemetryRow(
                      label: 'Codec',
                      value: stream.videoCodec!.toUpperCase(),
                    ),
                  if (stream.resolution != null)
                    _TelemetryRow(
                      label: 'Resolution',
                      value: stream.resolution!,
                    ),
                  if (isHw) ...[
                    _TelemetryRow(
                      label: 'Hardware Acceleration',
                      value:
                          'Active (${stream.hwDecoding ?? stream.hwEncoding ?? "Hardware"})',
                      badgeColor: const Color(0xFF2196F3),
                    ),
                  ],
                  if (stream.transcodeSpeed != null)
                    _TelemetryRow(
                      label: 'Transcode Speed',
                      value: '${stream.transcodeSpeed!.toStringAsFixed(1)}x',
                    ),
                  if (stream.isThrottled != null)
                    _TelemetryRow(
                      label: 'Throttled',
                      value: stream.isThrottled! ? 'Yes (CPU Saved)' : 'No',
                    ),
                  if (stream.transcodeReasons.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: Insets.xs),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Transcode Reasons:',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 2),
                          ...stream.transcodeReasons.map(
                            (r) => Text(
                              '• $r',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.error,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: Insets.lg),
                  const Divider(height: 1),
                  const SizedBox(height: Insets.md),

                  // Audio Stream Diagnostics
                  const _SectionHeader(
                    title: 'AUDIO & SUBTITLES',
                    icon: Icons.audiotrack_outlined,
                  ),
                  const SizedBox(height: Insets.sm),
                  _TelemetryRow(label: 'Audio Decision', value: audioDecision),
                  if (stream.audioCodec != null)
                    _TelemetryRow(
                      label: 'Audio Codec',
                      value: stream.audioCodec!.toUpperCase(),
                    ),
                  if (stream.audioChannels != null)
                    _TelemetryRow(
                      label: 'Audio Channels',
                      value: stream.audioChannels!,
                    ),
                  if (stream.subtitleLanguage != null)
                    _TelemetryRow(
                      label: 'Subtitles',
                      value:
                          '${stream.subtitleLanguage} (${stream.subtitleCodec ?? "Standard"})',
                    ),

                  const SizedBox(height: Insets.lg),
                  const Divider(height: 1),
                  const SizedBox(height: Insets.md),

                  // Client & Bandwidth Telemetry
                  const _SectionHeader(
                    title: 'CLIENT & BANDWIDTH',
                    icon: Icons.devices_outlined,
                  ),
                  const SizedBox(height: Insets.sm),
                  if (stream.player != null)
                    _TelemetryRow(label: 'Player', value: stream.player!),
                  if (stream.product != null)
                    _TelemetryRow(label: 'Product', value: stream.product!),
                  if (stream.device != null)
                    _TelemetryRow(label: 'Device', value: stream.device!),
                  if (stream.platform != null)
                    _TelemetryRow(label: 'Platform', value: stream.platform!),
                  if (stream.bitrate != null)
                    _TelemetryRow(
                      label: 'Stream Bitrate',
                      value: stream.bitrate! >= 1000
                          ? '${(stream.bitrate! / 1000).toStringAsFixed(1)} Mbps'
                          : '${stream.bitrate} kbps',
                    ),

                  const SizedBox(height: Insets.xl),

                  // Terminate stream button
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: colorScheme.error,
                      foregroundColor: colorScheme.onError,
                      padding: const EdgeInsets.all(Insets.md),
                    ),
                    icon: const Icon(Icons.stop_circle_outlined),
                    label: const Text('Terminate Stream'),
                    onPressed: () {
                      Navigator.of(context).pop();
                      TerminateStreamDialog.show(
                        context,
                        instance: instance,
                        stream: stream,
                      );
                    },
                  ),
                  const SizedBox(height: Insets.md),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.icon});

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      children: [
        Icon(icon, size: 16, color: colorScheme.primary),
        const SizedBox(width: Insets.xs),
        Text(
          title,
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: colorScheme.primary,
            letterSpacing: 1.1,
          ),
        ),
      ],
    );
  }
}

class _TelemetryRow extends StatelessWidget {
  const _TelemetryRow({
    required this.label,
    required this.value,
    this.highlight = false,
    this.badgeColor,
  });

  final String label;
  final String value;
  final bool highlight;
  final Color? badgeColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: Insets.md),
          Flexible(
            child: Text(
              value,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: badgeColor ??
                    (highlight
                        ? const Color(0xFFFF9800)
                        : colorScheme.onSurface),
              ),
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
