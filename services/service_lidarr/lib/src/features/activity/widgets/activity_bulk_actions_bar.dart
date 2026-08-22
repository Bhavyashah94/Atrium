import 'package:core_models/core_models.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../generated/generated.dart';
import '../../../lidarr_api.dart';
import '../../../lidarr_providers.dart';

/// Floating bottom action bar presenting bulk actions for selected Activity items (Queue or Blocklist).
class ActivityBulkActionsBar extends ConsumerWidget {
  const ActivityBulkActionsBar({
    required this.instance,
    required this.selectedIds,
    required this.isQueue,
    required this.onClear,
    super.key,
  });

  final Instance instance;
  final Set<int> selectedIds;
  final bool isQueue;
  final VoidCallback onClear;

  Future<void> _bulkRemoveQueue(BuildContext context, WidgetRef ref) async {
    bool removeFromClient = true;
    bool blocklist = false;

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => StatefulBuilder(
        builder: (BuildContext context, StateSetter setDialogState) {
          return AlertDialog(
            title: Text('Remove ${selectedIds.length} Downloads'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Remove ${selectedIds.length} items from download queue?',
                ),
                const SizedBox(height: Insets.md),
                CheckboxListTile(
                  title: const Text('Remove from Download Client'),
                  subtitle: const Text('Delete from client and discard files'),
                  value: removeFromClient,
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  onChanged: (bool? val) {
                    setDialogState(() {
                      removeFromClient = val ?? true;
                    });
                  },
                ),
                CheckboxListTile(
                  title: const Text('Blocklist Releases'),
                  subtitle: const Text(
                    'Prevent Lidarr from grabbing these releases again',
                  ),
                  value: blocklist,
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  onChanged: (bool? val) {
                    setDialogState(() {
                      blocklist = val ?? false;
                    });
                  },
                ),
              ],
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(ctx).colorScheme.error,
                  foregroundColor: Theme.of(ctx).colorScheme.onError,
                ),
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Remove'),
              ),
            ],
          );
        },
      ),
    );

    if (confirmed != true || !context.mounted) return;

    try {
      final LidarrApi api = await ref.read(lidarrApiProvider(instance).future);
      final ApiResponse<void> resp = await api.queue.deleteQueueBulk(
        body: QueueBulkResource(
          ids: selectedIds.toList(),
        ),
        removeFromClient: removeFromClient,
        blocklist: blocklist,
      );

      if (!resp.isSuccess) {
        throw Exception(resp.error?.message ?? 'Bulk remove failed');
      }

      ref.invalidate(lidarrQueueProvider(instance));
      ref.invalidate(lidarrBlocklistProvider(instance));
      onClear();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Removed ${selectedIds.length} items from queue'),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to remove: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _bulkRemoveBlocklist(BuildContext context, WidgetRef ref) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: Text('Remove ${selectedIds.length} from Blocklist?'),
        content: Text(
          'Remove ${selectedIds.length} releases from blocklist so Lidarr may grab them again?',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    try {
      final LidarrApi api = await ref.read(lidarrApiProvider(instance).future);
      final ApiResponse<void> resp = await api.blocklist.deleteBlocklistBulk(
        body: BlocklistBulkResource(
          ids: selectedIds.toList(),
        ),
      );

      if (!resp.isSuccess) {
        throw Exception(resp.error?.message ?? 'Bulk unblock failed');
      }

      ref.invalidate(lidarrBlocklistProvider(instance));
      onClear();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Removed ${selectedIds.length} releases from blocklist',
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to remove: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh,
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: <Widget>[
            Text(
              '${selectedIds.length} selected',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            TextButton(
              onPressed: onClear,
              child: const Text('Cancel'),
            ),
            const SizedBox(width: 8),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: cs.error,
                foregroundColor: cs.onError,
              ),
              icon: const Icon(Icons.delete_outline, size: 18),
              label: Text(isQueue ? 'Remove' : 'Unblock'),
              onPressed: () {
                if (isQueue) {
                  _bulkRemoveQueue(context, ref);
                } else {
                  _bulkRemoveBlocklist(context, ref);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
