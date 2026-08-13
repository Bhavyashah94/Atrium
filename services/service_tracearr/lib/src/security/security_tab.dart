import 'package:core_models/core_models.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/tracearr_providers.dart';
import 'widgets/security_incident_ledger_section.dart';

/// Main Security destination for Tracearr in Atrium.
///
/// Features Sentinel policy violation ledger, severity filtering,
/// real-time triage, and incident resolution tracking.
class SecurityTab extends ConsumerWidget {
  const SecurityTab({
    required this.instance,
    super.key,
  });

  final Instance instance;

  Future<void> _refreshAll(WidgetRef ref) async {
    ref.invalidate(tracearrViolationsProvider(instance));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final violationsAsync = ref.watch(tracearrViolationsProvider(instance));

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu),
          tooltip: 'Open menu',
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              instance.name,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              'Security',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
      body: EasyRefresh(
        header: const ClassicHeader(
          dragText: 'Pull to refresh',
          armedText: 'Release ready',
          readyText: 'Refreshing security audit ledger...',
          processingText: 'Refreshing security audit ledger...',
          processedText: 'Updated',
          failedText: 'Failed',
          messageText: 'Last updated at %T',
        ),
        onRefresh: () => _refreshAll(ref),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(
            horizontal: Insets.lg,
            vertical: Insets.md,
          ),
          children: [
            // Sentinel Policy Violation Incident Ledger
            SecurityIncidentLedgerSection(
              instance: instance,
              violationsAsync: violationsAsync,
              onRetry: () =>
                  ref.invalidate(tracearrViolationsProvider(instance)),
            ),
            const SizedBox(height: Insets.xl),
          ],
        ),
      ),
    );
  }
}
