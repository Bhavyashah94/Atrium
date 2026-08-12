import 'package:flutter/material.dart';

import '../design_tokens.dart';

/// Small "BETA" pill shown beside a service whose integration is still
/// stabilizing. Call sites decide when to show it, typically from
/// `ServiceKind.isBeta`.
class BetaBadge extends StatelessWidget {
  const BetaBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Insets.sm,
        vertical: Insets.xxs,
      ),
      decoration: BoxDecoration(
        color: cs.tertiaryContainer,
        borderRadius: BorderRadius.circular(Radii.sm),
      ),
      child: Text(
        'BETA',
        style: theme.textTheme.labelSmall?.copyWith(
          color: cs.onTertiaryContainer,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
