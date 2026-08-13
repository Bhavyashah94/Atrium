import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';
import '../../../models/tracearr_models.dart';

/// Card displaying a user's favorite genres and viewing habits.
class UserGenreBreakdownCard extends StatelessWidget {
  const UserGenreBreakdownCard({
    required this.topGenres,
    super.key,
  });

  final List<TracearrGenreStat> topGenres;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (topGenres.isEmpty) {
      return const SizedBox.shrink();
    }

    final maxPlays =
        topGenres.fold(0, (max, g) => g.plays > max ? g.plays : max);

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
              Icon(Icons.category_outlined,
                  size: 16, color: colorScheme.primary),
              const SizedBox(width: Insets.xs),
              Text(
                'TOP GENRES & HABITS',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colorScheme.primary,
                  letterSpacing: 1.1,
                ),
              ),
            ],
          ),
          const SizedBox(height: Insets.md),
          ...topGenres.map((stat) {
            final double ratio =
                maxPlays > 0 ? (stat.plays / maxPlays).clamp(0.0, 1.0) : 0.0;

            return Padding(
              padding: const EdgeInsets.only(bottom: Insets.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          stat.genre,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Text(
                        '${stat.plays} ${stat.plays == 1 ? 'play' : 'plays'}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(Radii.sm),
                    child: LinearProgressIndicator(
                      value: ratio,
                      minHeight: 6,
                      backgroundColor: colorScheme.surfaceContainerHighest,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(colorScheme.primary),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
