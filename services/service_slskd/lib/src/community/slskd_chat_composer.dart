import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';

/// Pinned bottom input bar for sending messages in a chat room or direct message thread.
class SlskdChatComposer extends StatefulWidget {
  const SlskdChatComposer({
    required this.onSend,
    this.hintText = 'Type a message...',
    this.autofocus = false,
    super.key,
  });

  final ValueChanged<String> onSend;
  final String hintText;
  final bool autofocus;

  @override
  State<SlskdChatComposer> createState() => _SlskdChatComposerState();
}

class _SlskdChatComposerState extends State<SlskdChatComposer> {
  final TextEditingController _controller = TextEditingController();
  bool _canSend = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      final canSend = _controller.text.trim().isNotEmpty;
      if (canSend != _canSend) {
        setState(() => _canSend = canSend);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    widget.onSend(text);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Insets.sm, vertical: Insets.xs),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.35),
            width: 0.5,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: <Widget>[
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(24),
                ),
                padding: const EdgeInsets.symmetric(horizontal: Insets.md),
                child: TextField(
                  controller: _controller,
                  autofocus: widget.autofocus,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _submit(),
                  maxLines: 4,
                  minLines: 1,
                  style: Theme.of(context).textTheme.bodyMedium,
                  decoration: InputDecoration(
                    hintText: widget.hintText,
                    hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colorScheme.outline,
                        ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
            ),
            const SizedBox(width: Insets.xs),
            IconButton.filled(
              icon: const Icon(Icons.send_rounded, size: 18),
              onPressed: _canSend ? _submit : null,
              style: IconButton.styleFrom(
                backgroundColor: _canSend ? colorScheme.primary : colorScheme.surfaceContainerHighest,
                foregroundColor: _canSend ? colorScheme.onPrimary : colorScheme.outline,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
