import 'package:core_models/core_models.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';
import '../../../models/tracearr_models.dart';
import '../../../people/screens/tracearr_user_dossier_screen.dart';

/// Leaderboard ranking the top viewers of a media item with deep user navigation.
class MediaWatchersLeaderboard extends StatelessWidget {
  const MediaWatchersLeaderboard({
    required this.watchers,
    this.instance,
    super.key,
  });

  final List<TracearrMediaWatcher> watchers;
  final Instance? instance;

  String _formatWatchTime(int ms) {
    if (ms <= 0) return '0h';
    final double hours = ms / (1000 * 60 * 60);
    return '${hours.toStringAsFixed(1)}h';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (watchers.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(Insets.md),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(Radii.md),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.leaderboard_outlined,
                size: 16,
                color: colorScheme.primary,
              ),
              const SizedBox(width: Insets.xs),
              Text(
                'TOP WATCHERS (${watchers.length})',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colorScheme.primary,
                  letterSpacing: 1.1,
                ),
              ),
            ],
          ),
          const SizedBox(height: Insets.md),
          ...watchers.asMap().entries.map((entry) {
            final int rank = entry.key + 1;
            final TracearrMediaWatcher watcher = entry.value;

            return Padding(
              padding: const EdgeInsets.only(bottom: Insets.sm),
              child: InkWell(
                borderRadius: BorderRadius.circular(Radii.sm),
                onTap: instance != null
                    ? () => TracearrUserDossierScreen.navigate(
                          context,
                          instance: instance!,
                          userId: watcher.userId,
                          username: watcher.username,
                        )
                    : null,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: rank == 1
                              ? const Color(0xFFFFD700).withValues(alpha: 0.2)
                              : rank == 2
                                  ? const Color(0xFFC0C0C0)
                                      .withValues(alpha: 0.2)
                                  : rank == 3
                                      ? const Color(0xFFCD7F32)
                                          .withValues(alpha: 0.2)
                                      : colorScheme.surfaceContainerHighest,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '$rank',
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                            color: rank == 1
                                ? const Color(0xFFD4AF37)
                                : colorScheme.onSurface,
                          ),
                        ),
                      ),
                      const SizedBox(width: Insets.sm),
                      CircleAvatar(
                        radius: 12,
                        backgroundColor: colorScheme.primaryContainer,
                        child: Text(
                          watcher.username.isNotEmpty
                              ? watcher.username[0].toUpperCase()
                              : 'U',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ),
                      const SizedBox(width: Insets.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '@${watcher.username}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (watcher.distinctEpisodesWatched != null)
                              Text(
                                '${watcher.distinctEpisodesWatched} episodes watched',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                  fontSize: 10,
                                ),
                              ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${watcher.plays} ${watcher.plays == 1 ? 'play' : 'plays'}',
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          Text(
                            _formatWatchTime(watcher.watchTimeMs),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
