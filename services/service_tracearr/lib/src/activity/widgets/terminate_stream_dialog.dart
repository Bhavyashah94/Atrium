import 'package:core_models/core_models.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/tracearr_models.dart';
import '../../providers/tracearr_providers.dart';

/// Modal dialog for safely terminating an active stream with optional message.
class TerminateStreamDialog extends StatefulWidget {
  const TerminateStreamDialog({
    required this.instance,
    required this.stream,
    super.key,
  });

  final Instance instance;
  final TracearrStream stream;

  static Future<bool?> show(
    BuildContext context, {
    required Instance instance,
    required TracearrStream stream,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => TerminateStreamDialog(
        instance: instance,
        stream: stream,
      ),
    );
  }

  @override
  State<TerminateStreamDialog> createState() => _TerminateStreamDialogState();
}

class _TerminateStreamDialogState extends State<TerminateStreamDialog> {
  late final TextEditingController _messageController;
  bool _isTerminating = false;

  static const List<String> _quickReasons = [
    'Server maintenance in progress',
    'Bandwidth limit exceeded',
    'Please set quality to Original',
    'Streaming policy violation',
  ];

  @override
  void initState() {
    super.initState();
    _messageController = TextEditingController();
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _handleTerminate(WidgetRef ref) async {
    setState(() => _isTerminating = true);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    try {
      final repo =
          await ref.read(tracearrRepositoryProvider(widget.instance).future);
      final customMsg = _messageController.text.trim();
      final success = await repo.terminateStream(
        streamId: widget.stream.id,
        message: customMsg.isNotEmpty ? customMsg : null,
      );

      if (!mounted) return;

      if (success) {
        ref.invalidate(tracearrStreamsProvider(widget.instance));
        navigator.pop(true);
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(
              'Terminated stream for @${widget.stream.userUsername}',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        setState(() => _isTerminating = false);
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text('Failed to terminate stream. Please try again.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isTerminating = false);
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('Error terminating stream: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Consumer(
      builder: (context, ref, child) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.stop_circle_outlined, color: colorScheme.error),
              const SizedBox(width: Insets.sm),
              const Expanded(
                child: Text('Terminate Stream'),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Are you sure you want to stop playback for @${widget.stream.userUsername}?',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  widget.stream.mediaTitle,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(height: Insets.md),
                Text(
                  'Quick Message Preset:',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: Insets.xs),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: _quickReasons.map((reason) {
                    final isSelected = _messageController.text == reason;
                    return ChoiceChip(
                      label: Text(reason, style: const TextStyle(fontSize: 11)),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          _messageController.text = selected ? reason : '';
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: Insets.md),
                TextField(
                  controller: _messageController,
                  decoration: const InputDecoration(
                    labelText: 'Custom Message to User (Optional)',
                    hintText: 'e.g. Server restarting in 5 minutes',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  maxLines: 2,
                  enabled: !_isTerminating,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: _isTerminating
                  ? null
                  : () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: colorScheme.error,
                foregroundColor: colorScheme.onError,
              ),
              onPressed: _isTerminating ? null : () => _handleTerminate(ref),
              child: _isTerminating
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Stop Stream'),
            ),
          ],
        );
      },
    );
  }
}
