import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/tracearr_models.dart';

/// Banner shown when there are unacknowledged security policy violations.
class OverviewSecurityAlertBanner extends StatelessWidget {
  const OverviewSecurityAlertBanner({
    required this.violationsAsync,
    required this.onTap,
    super.key,
  });

  final AsyncValue<List<TracearrViolationItem>> violationsAsync;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final violations = violationsAsync.value ?? const <TracearrViolationItem>[];
    final unackViolations = violations.where((v) => !v.acknowledged).toList();

    if (unackViolations.isEmpty) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final count = unackViolations.length;
    final hasCritical =
        unackViolations.any((v) => v.severity.toLowerCase() == 'critical');

    final containerColor = hasCritical
        ? colorScheme.errorContainer
        : colorScheme.tertiaryContainer;
    final onContainerColor = hasCritical
        ? colorScheme.onErrorContainer
        : colorScheme.onTertiaryContainer;

    final latestIncident = unackViolations.first;

    return Padding(
      padding: const EdgeInsets.only(bottom: Insets.md),
      child: Material(
        color: containerColor,
        borderRadius: BorderRadius.circular(Radii.md),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(Insets.md),
            child: Row(
              children: [
                Icon(
                  Icons.shield_outlined,
                  color: onContainerColor,
                  size: 28,
                ),
                const SizedBox(width: Insets.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$count Unacknowledged Alert${count > 1 ? 's' : ''}',
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: onContainerColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Latest: ${latestIncident.rule} • @${latestIncident.username}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: onContainerColor.withValues(alpha: 0.85),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: Insets.sm),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Triage',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: onContainerColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      color: onContainerColor,
                      size: 18,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
