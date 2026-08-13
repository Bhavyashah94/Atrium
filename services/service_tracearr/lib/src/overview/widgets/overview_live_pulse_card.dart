import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/tracearr_models.dart';

/// Card summarizing live active streams, transcode triage breakdown, and bandwidth.
class OverviewLivePulseCard extends StatelessWidget {
  const OverviewLivePulseCard({
    required this.streamsAsync,
    required this.onTap,
    this.onRetry,
    super.key,
  });

  final AsyncValue<List<TracearrStream>> streamsAsync;
  final VoidCallback onTap;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return streamsAsync.when(
      loading: () => Container(
        height: 140,
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(Radii.lg),
        ),
        child: const Center(child: ExpressiveProgressIndicator()),
      ),
      error: (err, _) => Container(
        padding: const EdgeInsets.all(Insets.md),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(Radii.lg),
        ),
        child: Row(
          children: [
            Icon(Icons.sync_problem, color: colorScheme.error),
            const SizedBox(width: Insets.md),
            Expanded(
              child: Text(
                'Failed to load active streams telemetry',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface,
                ),
              ),
            ),
            if (onRetry != null)
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: onRetry,
              ),
          ],
        ),
      ),
      data: (streams) {
        final totalStreams = streams.length;
        final directPlays = streams.where((s) => !s.isTranscode).length;
        final hwTranscodes =
            streams.where((s) => s.isTranscode && s.isHwTranscode).length;
        final swTranscodes =
            streams.where((s) => s.isTranscode && !s.isHwTranscode).length;

        final totalBitrateKbps =
            streams.fold(0, (sum, s) => sum + (s.bitrate ?? 0));
        final String formattedBitrate = totalBitrateKbps >= 1000
            ? '${(totalBitrateKbps / 1000).toStringAsFixed(1)} Mbps'
            : '$totalBitrateKbps kbps';

        final bool hasActiveStreams = totalStreams > 0;

        return Material(
          color: colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(Radii.lg),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(Insets.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: hasActiveStreams
                              ? const Color(0xFF4CAF50)
                              : colorScheme.outlineVariant,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: Insets.sm),
                      Text(
                        'LIVE OPERATIONS',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          letterSpacing: 1.1,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      if (hasActiveStreams)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Inspect',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Icon(
                              Icons.chevron_right,
                              color: colorScheme.primary,
                              size: 16,
                            ),
                          ],
                        ),
                    ],
                  ),
                  const SizedBox(height: Insets.md),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        '$totalStreams',
                        style: theme.textTheme.displaySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(width: Insets.sm),
                      Text(
                        totalStreams == 1 ? 'Active Stream' : 'Active Streams',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (hasActiveStreams) ...[
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: Insets.sm,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(Radii.sm),
                          ),
                          child: Text(
                            formattedBitrate,
                            style: theme.textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: Insets.md),
                  if (hasActiveStreams)
                    Wrap(
                      spacing: Insets.sm,
                      runSpacing: Insets.xs,
                      children: [
                        _StatusPill(
                          label: 'Direct Play',
                          count: directPlays,
                          color: const Color(0xFF4CAF50),
                          backgroundColor:
                              const Color(0xFF4CAF50).withValues(alpha: 0.12),
                        ),
                        _StatusPill(
                          label: 'HW Transcode',
                          count: hwTranscodes,
                          color: const Color(0xFF2196F3),
                          backgroundColor:
                              const Color(0xFF2196F3).withValues(alpha: 0.12),
                        ),
                        if (swTranscodes > 0)
                          _StatusPill(
                            label: 'CPU Transcode',
                            count: swTranscodes,
                            color: const Color(0xFFFF9800),
                            backgroundColor:
                                const Color(0xFFFF9800).withValues(alpha: 0.15),
                          ),
                      ],
                    )
                  else
                    Text(
                      'All connected media servers are currently idle.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.label,
    required this.count,
    required this.color,
    required this.backgroundColor,
  });

  final String label;
  final int count;
  final Color color;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Insets.sm,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(Radii.sm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '$label: $count',
            style: theme.textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
