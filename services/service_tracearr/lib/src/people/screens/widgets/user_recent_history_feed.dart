import 'package:core_models/core_models.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';
import '../../../activity/widgets/history_item_card.dart';
import '../../../models/tracearr_models.dart';

/// Feed of recently watched items for a specific user.
class UserRecentHistoryFeed extends StatelessWidget {
  const UserRecentHistoryFeed({
    required this.recentHistory,
    this.instance,
    super.key,
  });

  final List<TracearrHistoryItem> recentHistory;
  final Instance? instance;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (recentHistory.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.history, size: 16, color: colorScheme.primary),
            const SizedBox(width: Insets.xs),
            Text(
              'RECENT WATCH ACTIVITY (${recentHistory.length})',
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: colorScheme.primary,
                letterSpacing: 1.1,
              ),
            ),
          ],
        ),
        const SizedBox(height: Insets.md),
        ...recentHistory.map((item) {
          return Padding(
            padding: const EdgeInsets.only(bottom: Insets.sm),
            child: HistoryItemCard(
              item: item,
              instance: instance,
            ),
          );
        }),
      ],
    );
  }
}
