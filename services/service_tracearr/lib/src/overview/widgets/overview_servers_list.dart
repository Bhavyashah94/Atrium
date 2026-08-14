import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/tracearr_models.dart';

/// Section rendering compact cards for each connected media server.
class OverviewServersList extends StatelessWidget {
  const OverviewServersList({
    required this.healthAsync,
    required this.streamsAsync,
    required this.onTapServer,
    super.key,
  });

  final AsyncValue<TracearrHealthResponse> healthAsync;
  final AsyncValue<List<TracearrStream>> streamsAsync;
  final void Function(String serverId) onTapServer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final health = healthAsync.value;
    final servers = health?.servers ?? const <TracearrServerStatus>[];
    final streams = streamsAsync.value ?? const <TracearrStream>[];

    if (servers.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'CONNECTED MEDIA SERVERS (${servers.length})',
          style: theme.textTheme.labelMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
            letterSpacing: 1.1,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: Insets.sm),
        ...servers.map((server) {
          final serverStreams =
              streams.where((s) => s.serverId == server.id).length;
          final activeCount =
              serverStreams > 0 ? serverStreams : server.activeStreams;

          return Padding(
            padding: const EdgeInsets.only(bottom: Insets.sm),
            child: Material(
              color: colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(Radii.md),
              child: InkWell(
                onTap: () => onTapServer(server.id),
                borderRadius: BorderRadius.circular(Radii.md),
                child: Padding(
                  padding: const EdgeInsets.all(Insets.md),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(Radii.sm),
                        ),
                        child: Icon(
                          Icons.dns_outlined,
                          size: 20,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(width: Insets.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    server.name,
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: Insets.xs),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 1,
                                  ),
                                  decoration: BoxDecoration(
                                    color: colorScheme.surfaceContainerHighest,
                                    borderRadius:
                                        BorderRadius.circular(Radii.sm),
                                  ),
                                  child: Text(
                                    server.type.toUpperCase(),
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              activeCount > 0
                                  ? '$activeCount streaming session${activeCount > 1 ? 's' : ''}'
                                  : 'Idle • Ready',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: Insets.sm,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: server.online
                              ? const Color(0xFF4CAF50).withValues(alpha: 0.12)
                              : colorScheme.error.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(Radii.sm),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: server.online
                                    ? const Color(0xFF4CAF50)
                                    : colorScheme.error,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              server.online ? 'Online' : 'Offline',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: server.online
                                    ? const Color(0xFF4CAF50)
                                    : colorScheme.error,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}
