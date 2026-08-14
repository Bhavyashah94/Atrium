import 'package:core_models/core_models.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/tracearr_models.dart';
import 'active_stream_card.dart';

/// Section displaying real-time active playback sessions or an idle message.
class ActiveStreamsSection extends StatelessWidget {
  const ActiveStreamsSection({
    required this.instance,
    required this.streamsAsync,
    this.onRetry,
    super.key,
  });

  final Instance instance;
  final AsyncValue<List<TracearrStream>> streamsAsync;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: (streamsAsync.value?.isNotEmpty ?? false)
                    ? const Color(0xFF4CAF50)
                    : colorScheme.outlineVariant,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: Insets.sm),
            Text(
              'LIVE STREAMS',
              style: theme.textTheme.labelMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                letterSpacing: 1.1,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (streamsAsync.value != null) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 1,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(Radii.sm),
                ),
                child: Text(
                  '${streamsAsync.value!.length}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: Insets.sm),
        streamsAsync.when(
          loading: () => Container(
            height: 100,
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(Radii.md),
            ),
            child: const Center(child: ExpressiveProgressIndicator()),
          ),
          error: (err, _) => Container(
            padding: const EdgeInsets.all(Insets.md),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(Radii.md),
            ),
            child: Row(
              children: [
                Icon(Icons.sync_problem, color: colorScheme.error),
                const SizedBox(width: Insets.md),
                Expanded(
                  child: Text(
                    'Failed to load active playback sessions',
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
            if (streams.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(Insets.md),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(Radii.md),
                  border: Border.all(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.play_disabled_outlined,
                      size: 22,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: Insets.md),
                    Expanded(
                      child: Text(
                        'No active streams playing right now.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }

            return Column(
              children: streams.map((stream) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: Insets.sm),
                  child: ActiveStreamCard(
                    instance: instance,
                    stream: stream,
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }
}
