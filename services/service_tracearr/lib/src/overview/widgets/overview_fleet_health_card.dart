import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/tracearr_models.dart';

/// Card displaying fleet health, online server count, and Tracearr version.
class OverviewFleetHealthCard extends StatelessWidget {
  const OverviewFleetHealthCard({
    required this.healthAsync,
    this.onRetry,
    super.key,
  });

  final AsyncValue<TracearrHealthResponse> healthAsync;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return healthAsync.when(
      loading: () => Container(
        padding: const EdgeInsets.all(Insets.md),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(Radii.md),
        ),
        child: const Center(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: Insets.sm),
            child: ExpressiveProgressIndicator(),
          ),
        ),
      ),
      error: (err, _) => Container(
        padding: const EdgeInsets.all(Insets.md),
        decoration: BoxDecoration(
          color: colorScheme.errorContainer.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(Radii.md),
          border: Border.all(
            color: colorScheme.error.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.cloud_off, color: colorScheme.error),
            const SizedBox(width: Insets.md),
            Expanded(
              child: Text(
                'Could not fetch server health status',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onErrorContainer,
                ),
              ),
            ),
            if (onRetry != null)
              IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: 'Retry',
                onPressed: onRetry,
              ),
          ],
        ),
      ),
      data: (health) {
        final totalServers = health.servers.length;
        final onlineServers = health.servers.where((s) => s.online).length;
        final allOnline = totalServers > 0 && onlineServers == totalServers;
        final partialOnline = onlineServers > 0 && onlineServers < totalServers;

        final Color statusColor = allOnline
            ? const Color(0xFF4CAF50)
            : partialOnline
                ? const Color(0xFFFF9800)
                : colorScheme.error;

        final String statusLabel = allOnline
            ? 'All Systems Operational'
            : partialOnline
                ? 'Degraded Performance'
                : totalServers == 0
                    ? 'No Servers Configured'
                    : 'All Servers Offline';

        return Container(
          padding: const EdgeInsets.all(Insets.md),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(Radii.md),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.4),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: statusColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: Insets.sm),
                  Text(
                    statusLabel,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const Spacer(),
                  if (health.version != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: Insets.sm,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(Radii.sm),
                      ),
                      child: Text(
                        'v${health.version}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: Insets.sm),
              Text(
                totalServers > 0
                    ? '$onlineServers of $totalServers media servers reachable'
                    : 'Tracearr service online',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
