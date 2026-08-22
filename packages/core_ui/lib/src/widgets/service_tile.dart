import 'package:core_models/core_models.dart';
import 'package:flutter/material.dart';

import '../design_tokens.dart';
import '../service_visuals.dart';
import 'beta_badge.dart';
import 'status_chip.dart';

/// A list tile representing one configured [Instance]: service icon badge,
/// instance name, service tagline, and a health dot.
class ServiceTile extends StatelessWidget {
  const ServiceTile({
    required this.instance,
    this.health = Health.unknown,
    this.subtitle,
    this.onTap,
    this.onLongPress,
    super.key,
  });

  final Instance instance;
  final Health health;

  /// Overrides the default subtitle (the service tagline) when provided -
  /// e.g., a queue count or "3 missing".
  final String? subtitle;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;
    final Color accent = ServiceVisuals.accent(instance.kind);
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: cs.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.md),
        side: BorderSide(
          color: cs.outlineVariant.withValues(alpha: 0.45),
        ),
      ),
      child: ListTile(
        leading: Container(
          width: Sizes.serviceBadge,
          height: Sizes.serviceBadge,
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(Radii.sm),
          ),
          child: Icon(ServiceVisuals.icon(instance.kind), color: accent),
        ),
        title: Row(
          children: <Widget>[
            Flexible(
              child: Text(
                instance.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (instance.kind.isBeta) ...<Widget>[
              const SizedBox(width: Insets.sm),
              const BetaBadge(),
            ],
          ],
        ),
        subtitle: Text(subtitle ?? instance.kind.tagline),
        trailing: StatusChip(health: health, compact: true),
        onTap: onTap,
        onLongPress: onLongPress,
      ),
    );
  }
}
