import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';

/// Bottom action bar for batch operations in Wanted views.
class WantedBulkActionsBar extends StatelessWidget {
  const WantedBulkActionsBar({
    required this.selectedCount,
    required this.onSearch,
    required this.onMonitor,
    required this.onUnmonitor,
    super.key,
  });

  final int selectedCount;
  final VoidCallback onSearch;
  final VoidCallback onMonitor;
  final VoidCallback onUnmonitor;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: Insets.md,
          vertical: Insets.sm,
        ),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHigh,
          border: Border(
            top: BorderSide(
              color: cs.outlineVariant.withValues(alpha: 0.3),
            ),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                icon: const Icon(Icons.search, size: 18),
                label: Text('Search ($selectedCount)'),
                onPressed: onSearch,
              ),
            ),
            const SizedBox(width: Insets.sm),
            OutlinedButton.icon(
              icon: const Icon(Icons.bookmark_add_outlined, size: 18),
              label: const Text('Monitor'),
              onPressed: onMonitor,
            ),
            const SizedBox(width: Insets.sm),
            OutlinedButton.icon(
              icon: const Icon(Icons.bookmark_remove_outlined, size: 18),
              label: const Text('Unmonitor'),
              onPressed: onUnmonitor,
            ),
          ],
        ),
      ),
    );
  }
}
