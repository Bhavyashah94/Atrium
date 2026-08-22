import 'package:flutter/material.dart';

/// Generic bottom sheet to pick a preset from a schema list before opening the editor.
Future<T?> showSchemaPresetPicker<T>({
  required BuildContext context,
  required String title,
  required List<T> presets,
  required String Function(T) titleBuilder,
  String Function(T)? subtitleBuilder,
  IconData icon = Icons.extension,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (BuildContext ctx) {
      final theme = Theme.of(ctx);
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const Divider(),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: presets.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (BuildContext _, int index) {
                  final T preset = presets[index];
                  final String subtitle = subtitleBuilder?.call(preset) ?? '';
                  final String itemTitle = titleBuilder(preset);
                  return ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        icon,
                        size: 20,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                    title: Text(
                      itemTitle,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: subtitle.isNotEmpty ? Text(subtitle) : null,
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.of(ctx).pop(preset),
                  );
                },
              ),
            ),
          ],
        ),
      );
    },
  );
}
