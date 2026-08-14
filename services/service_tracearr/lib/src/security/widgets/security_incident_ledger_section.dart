import 'package:core_models/core_models.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/tracearr_models.dart';
import 'security_incident_card.dart';

enum SecurityFilterOption {
  all,
  unacknowledged,
  criticalHigh,
  resolved,
}

/// Interactive Sentinel policy violation ledger with severity filtering, dismissal, and triage actions.
class SecurityIncidentLedgerSection extends StatefulWidget {
  const SecurityIncidentLedgerSection({
    required this.instance,
    required this.violationsAsync,
    this.onRetry,
    super.key,
  });

  final Instance instance;
  final AsyncValue<List<TracearrViolationItem>> violationsAsync;
  final VoidCallback? onRetry;

  @override
  State<SecurityIncidentLedgerSection> createState() =>
      _SecurityIncidentLedgerSectionState();
}

class _SecurityIncidentLedgerSectionState
    extends State<SecurityIncidentLedgerSection> {
  SecurityFilterOption _selectedFilter = SecurityFilterOption.all;
  final Set<String> _locallyAcknowledgedIds = {};
  final Set<String> _locallyDismissedIds = {};

  List<TracearrViolationItem> _filterViolations(
    List<TracearrViolationItem> items,
  ) {
    return items
        .where((item) => !_locallyDismissedIds.contains(item.id))
        .map((item) {
      if (_locallyAcknowledgedIds.contains(item.id)) {
        return TracearrViolationItem(
          id: item.id,
          serverId: item.serverId,
          serverName: item.serverName,
          severity: item.severity,
          rule: item.rule,
          username: item.username,
          userId: item.userId,
          createdAt: item.createdAt,
          description: item.description,
          acknowledged: true,
        );
      }
      return item;
    }).where((item) {
      switch (_selectedFilter) {
        case SecurityFilterOption.all:
          return true;
        case SecurityFilterOption.unacknowledged:
          return !item.acknowledged;
        case SecurityFilterOption.criticalHigh:
          final sev = item.severity.toLowerCase();
          return sev == 'critical' || sev == 'high';
        case SecurityFilterOption.resolved:
          return item.acknowledged;
      }
    }).toList();
  }

  void _handleAcknowledge(TracearrViolationItem item) {
    setState(() {
      _locallyAcknowledgedIds.add(item.id);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Marked reviewed on this device: ${item.rule} (@${item.username}). '
          'Tracearr still lists it as unresolved.',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _handleDismiss(TracearrViolationItem item) {
    setState(() {
      _locallyDismissedIds.add(item.id);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Hidden on this device: ${item.rule} (@${item.username})',
        ),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            setState(() {
              _locallyDismissedIds.remove(item.id);
            });
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return widget.violationsAsync.when(
      loading: () => Container(
        height: 180,
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(Radii.md),
        ),
        child: const Center(child: ExpressiveProgressIndicator()),
      ),
      error: (err, _) => Container(
        padding: const EdgeInsets.all(Insets.md),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(Radii.md),
        ),
        child: Row(
          children: [
            Icon(Icons.shield_outlined, color: colorScheme.error),
            const SizedBox(width: Insets.md),
            Expanded(
              child: Text(
                'Failed to load security audit ledger',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface,
                ),
              ),
            ),
            if (widget.onRetry != null)
              IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: 'Retry',
                onPressed: widget.onRetry,
              ),
          ],
        ),
      ),
      data: (items) {
        final filtered = _filterViolations(items);
        final unackCount = items
            .where(
              (i) =>
                  !i.acknowledged &&
                  !_locallyAcknowledgedIds.contains(i.id) &&
                  !_locallyDismissedIds.contains(i.id),
            )
            .length;

        final activeItemsCount =
            items.where((i) => !_locallyDismissedIds.contains(i.id)).length;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Filter Segment Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  FilterChip(
                    label: Text('All ($activeItemsCount)'),
                    selected: _selectedFilter == SecurityFilterOption.all,
                    onSelected: (selected) {
                      if (selected) {
                        setState(
                          () => _selectedFilter = SecurityFilterOption.all,
                        );
                      }
                    },
                  ),
                  const SizedBox(width: Insets.xs),
                  FilterChip(
                    label: Text(
                      'Not reviewed ${unackCount > 0 ? "($unackCount)" : ""}',
                    ),
                    selected:
                        _selectedFilter == SecurityFilterOption.unacknowledged,
                    avatar: unackCount > 0
                        ? Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Color(0xFFE53935),
                              shape: BoxShape.circle,
                            ),
                          )
                        : null,
                    onSelected: (selected) {
                      if (selected) {
                        setState(
                          () => _selectedFilter =
                              SecurityFilterOption.unacknowledged,
                        );
                      }
                    },
                  ),
                  const SizedBox(width: Insets.xs),
                  FilterChip(
                    label: const Text('Critical / High'),
                    selected:
                        _selectedFilter == SecurityFilterOption.criticalHigh,
                    onSelected: (selected) {
                      if (selected) {
                        setState(
                          () => _selectedFilter =
                              SecurityFilterOption.criticalHigh,
                        );
                      }
                    },
                  ),
                  const SizedBox(width: Insets.xs),
                  FilterChip(
                    label: const Text('Reviewed'),
                    selected: _selectedFilter == SecurityFilterOption.resolved,
                    onSelected: (selected) {
                      if (selected) {
                        setState(
                          () => _selectedFilter = SecurityFilterOption.resolved,
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: Insets.md),

            // 2. Incident Ledger List
            if (filtered.isEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(Insets.xl),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(Radii.md),
                  border: Border.all(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.verified_user_outlined,
                      size: 40,
                      color: Color(0xFF4CAF50),
                    ),
                    const SizedBox(height: Insets.sm),
                    Text(
                      'All Clear',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF4CAF50),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _selectedFilter == SecurityFilterOption.all
                          ? 'No security policy violations recorded in the Sentinel audit ledger.'
                          : 'No incidents match the active filter.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ] else ...[
              ...filtered.map((incident) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: Insets.sm),
                  child: SecurityIncidentCard(
                    incident: incident,
                    instance: widget.instance,
                    onAcknowledge: incident.acknowledged
                        ? null
                        : () => _handleAcknowledge(incident),
                    onDismiss: () => _handleDismiss(incident),
                  ),
                );
              }),
            ],
          ],
        );
      },
    );
  }
}
