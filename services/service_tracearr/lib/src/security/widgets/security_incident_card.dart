import 'package:core_models/core_models.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';
import '../../models/tracearr_models.dart';
import '../../people/screens/tracearr_user_dossier_screen.dart';

/// Card rendering a Sentinel security policy violation incident with triage and user navigation.
class SecurityIncidentCard extends StatelessWidget {
  const SecurityIncidentCard({
    required this.incident,
    this.instance,
    this.onAcknowledge,
    this.onDismiss,
    super.key,
  });

  final TracearrViolationItem incident;
  final Instance? instance;
  final VoidCallback? onAcknowledge;
  final VoidCallback? onDismiss;

  Color _getSeverityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'critical':
      case 'high':
        return const Color(0xFFE53935);
      case 'medium':
      case 'warning':
        return const Color(0xFFFF9800);
      case 'low':
      case 'info':
        return const Color(0xFF2196F3);
      default:
        return const Color(0xFF9E9E9E);
    }
  }

  String _formatTimestamp(DateTime? dt) {
    if (dt == null) return '';
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.month}/${dt.day}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final severityColor = _getSeverityColor(incident.severity);
    final timeStr = _formatTimestamp(incident.createdAt);

    return Container(
      padding: const EdgeInsets.all(Insets.md),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(Radii.md),
        border: Border.all(
          color: incident.acknowledged
              ? colorScheme.outlineVariant.withValues(alpha: 0.3)
              : severityColor.withValues(alpha: 0.5),
          width: incident.acknowledged ? 1 : 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Header: Severity Pill, Server Badge, Timestamp, and Dismiss
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: severityColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(Radii.sm),
                  border:
                      Border.all(color: severityColor.withValues(alpha: 0.4)),
                ),
                child: Text(
                  incident.severity.toUpperCase(),
                  style: TextStyle(
                    color: severityColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(width: Insets.xs),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(Radii.sm),
                ),
                child: Text(
                  incident.serverName,
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 10,
                  ),
                ),
              ),
              const Spacer(),
              if (timeStr.isNotEmpty)
                Text(
                  timeStr,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 10,
                  ),
                ),
              if (onDismiss != null) ...[
                const SizedBox(width: 4),
                InkWell(
                  borderRadius: BorderRadius.circular(Radii.sm),
                  onTap: onDismiss,
                  child: Padding(
                    padding: const EdgeInsets.all(2),
                    child: Icon(
                      Icons.close,
                      size: 14,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: Insets.sm),

          // 2. Incident Rule & Explanation
          Text(
            incident.rule,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          if (incident.description != null &&
              incident.description!.isNotEmpty) ...[
            const SizedBox(height: 3),
            Text(
              incident.description!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: Insets.sm),

          // 3. User Identity & Acknowledged Status Row
          Row(
            children: [
              GestureDetector(
                onTap: instance != null
                    ? () => TracearrUserDossierScreen.navigate(
                          context,
                          instance: instance!,
                          userId: incident.userId ?? incident.username,
                          username: incident.username,
                        )
                    : null,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(
                      radius: 10,
                      backgroundColor: colorScheme.primaryContainer,
                      child: Text(
                        incident.username.isNotEmpty
                            ? incident.username[0].toUpperCase()
                            : 'U',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                    const SizedBox(width: Insets.xs),
                    Text(
                      '@${incident.username}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              if (incident.acknowledged)
                const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.check_circle,
                      size: 14,
                      color: Color(0xFF4CAF50),
                    ),
                    SizedBox(width: 3),
                    Text(
                      'Acknowledged',
                      style: TextStyle(
                        color: Color(0xFF4CAF50),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                )
              else if (onAcknowledge != null)
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    visualDensity: VisualDensity.compact,
                  ),
                  icon: const Icon(Icons.done, size: 14),
                  label:
                      const Text('Acknowledge', style: TextStyle(fontSize: 11)),
                  onPressed: onAcknowledge,
                ),
            ],
          ),
        ],
      ),
    );
  }
}
