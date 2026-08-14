import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';
import '../../../models/tracearr_models.dart';

/// Card showing all cross-server media server accounts linked to a user.
class UserLinkedAccountsCard extends StatelessWidget {
  const UserLinkedAccountsCard({
    required this.accounts,
    super.key,
  });

  final List<TracearrUserAccount> accounts;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (accounts.isEmpty) {
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
              Icon(Icons.hub_outlined, size: 16, color: colorScheme.primary),
              const SizedBox(width: Insets.xs),
              Text(
                'LINKED SERVER IDENTITIES (${accounts.length})',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colorScheme.primary,
                  letterSpacing: 1.1,
                ),
              ),
            ],
          ),
          const SizedBox(height: Insets.md),
          ...accounts.map((acct) {
            final isRemoved = acct.removedAt != null;

            return Padding(
              padding: const EdgeInsets.only(bottom: Insets.sm),
              child: Container(
                padding: const EdgeInsets.all(Insets.sm),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest
                      .withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(Radii.sm),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2,),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(Radii.sm),
                      ),
                      child: Text(
                        acct.serverType.toUpperCase(),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ),
                    const SizedBox(width: Insets.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            acct.username,
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            'User ID: ${acct.serverUserId}',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2,),
                      decoration: BoxDecoration(
                        color: isRemoved
                            ? colorScheme.errorContainer
                            : const Color(0xFF4CAF50).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(Radii.sm),
                      ),
                      child: Text(
                        isRemoved ? 'Removed' : 'Active',
                        style: TextStyle(
                          color: isRemoved
                              ? colorScheme.onErrorContainer
                              : const Color(0xFF4CAF50),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
