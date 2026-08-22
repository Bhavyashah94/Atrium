import 'package:core_models/core_models.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../generated/generated.dart';
import '../../../lidarr_api.dart';
import '../../../lidarr_providers.dart';

/// Custom Formats configuration section.
class CustomFormatsSection extends ConsumerWidget {
  const CustomFormatsSection({required this.instance, super.key});

  final Instance instance;

  Future<void> _showAddEditCustomFormatDialog(
    BuildContext context,
    WidgetRef ref, [
    CustomFormatResource? format,
  ]) async {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final bool isNew = format == null;

    final TextEditingController nameController =
        TextEditingController(text: format?.name ?? '');
    bool includeInRenaming = format?.includeCustomFormatWhenRenaming ?? false;

    // Clone specifications
    final List<CustomFormatSpecificationSchema> specifications =
        (format?.specifications ?? <CustomFormatSpecificationSchema>[])
            .map(
              (e) => e.copyWith(
                fields: e.fields?.map((f) => f.copyWith()).toList(),
              ),
            )
            .toList();

    if (!context.mounted) return;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext ctx) {
        return StatefulBuilder(
          builder: (BuildContext dCtx, StateSetter setDialogState) {
            final ColorScheme cs = Theme.of(dCtx).colorScheme;

            return AlertDialog(
              title: Text(isNew ? 'Add Custom Format' : 'Edit Custom Format'),
              content: SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: 'Custom Format Name',
                          hintText: 'e.g. Lossless 24-bit, Vinyl Rip',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: Insets.sm),
                      SwitchListTile(
                        title: const Text('Include in Renaming'),
                        subtitle: const Text(
                          'Include custom format token when renaming tracks',
                        ),
                        value: includeInRenaming,
                        contentPadding: EdgeInsets.zero,
                        onChanged: (bool val) =>
                            setDialogState(() => includeInRenaming = val),
                      ),
                      const Divider(),
                      const SizedBox(height: Insets.xs),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Specifications (${specifications.length})',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          TextButton.icon(
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('Add Condition'),
                            onPressed: () async {
                              final List<CustomFormatSpecificationSchema>
                                  schemas = ref
                                          .read(
                                            lidarrCustomFormatSchemaProvider(
                                              instance,
                                            ),
                                          )
                                          .value ??
                                      <CustomFormatSpecificationSchema>[];
                              if (schemas.isEmpty) {
                                messenger.showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'No specification templates available.',
                                    ),
                                  ),
                                );
                                return;
                              }

                              final CustomFormatSpecificationSchema? selected =
                                  await showModalBottomSheet<
                                      CustomFormatSpecificationSchema>(
                                context: dCtx,
                                isScrollControlled: true,
                                builder: (BuildContext bCtx) {
                                  return SafeArea(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Padding(
                                          padding:
                                              const EdgeInsets.all(Insets.md),
                                          child: Text(
                                            'Select Specification Type',
                                            style: Theme.of(bCtx)
                                                .textTheme
                                                .titleMedium
                                                ?.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                          ),
                                        ),
                                        Flexible(
                                          child: ListView.separated(
                                            shrinkWrap: true,
                                            itemCount: schemas.length,
                                            separatorBuilder: (_, __) =>
                                                const Divider(height: 1),
                                            itemBuilder: (
                                              BuildContext context,
                                              int idx,
                                            ) {
                                              final schema = schemas[idx];
                                              return ListTile(
                                                title: Text(
                                                  schema.name ??
                                                      schema
                                                          .implementationName ??
                                                      'Specification',
                                                ),
                                                subtitle:
                                                    schema.infoLink != null
                                                        ? Text(
                                                            schema.implementation ??
                                                                '',
                                                          )
                                                        : null,
                                                trailing: const Icon(
                                                  Icons.chevron_right,
                                                ),
                                                onTap: () =>
                                                    Navigator.pop(bCtx, schema),
                                              );
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              );

                              if (selected != null) {
                                setDialogState(() {
                                  specifications.add(
                                    selected.copyWith(
                                      name: selected.name,
                                      negate: false,
                                      requiredVal: false,
                                      fields: selected.fields
                                          ?.map(
                                            (f) => f.copyWith(value: f.value),
                                          )
                                          .toList(),
                                    ),
                                  );
                                });
                              }
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: Insets.xs),
                      if (specifications.isEmpty)
                        Padding(
                          padding:
                              const EdgeInsets.symmetric(vertical: Insets.md),
                          child: Center(
                            child: Text(
                              'No conditions added yet. Add at least one specification condition.',
                              style: TextStyle(
                                color: cs.onSurfaceVariant,
                                fontStyle: FontStyle.italic,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        )
                      else
                        ...specifications.asMap().entries.map((entry) {
                          final int idx = entry.key;
                          final CustomFormatSpecificationSchema spec =
                              entry.value;

                          return Card(
                            margin: const EdgeInsets.only(bottom: Insets.sm),
                            color: cs.surfaceContainerLow,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: BorderSide(
                                color: cs.outlineVariant.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(Insets.sm),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          spec.name ??
                                              spec.implementationName ??
                                              'Condition',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.delete_outline,
                                          size: 18,
                                        ),
                                        tooltip: 'Remove condition',
                                        onPressed: () {
                                          setDialogState(() {
                                            specifications.removeAt(idx);
                                          });
                                        },
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      FilterChip(
                                        label: const Text('Negate'),
                                        selected: spec.negate == true,
                                        onSelected: (bool val) {
                                          setDialogState(() {
                                            specifications[idx] =
                                                spec.copyWith(negate: val);
                                          });
                                        },
                                      ),
                                      const SizedBox(width: Insets.xs),
                                      FilterChip(
                                        label: const Text('Required'),
                                        selected: spec.requiredVal == true,
                                        onSelected: (bool val) {
                                          setDialogState(() {
                                            specifications[idx] = spec.copyWith(
                                              requiredVal: val,
                                            );
                                          });
                                        },
                                      ),
                                    ],
                                  ),
                                  if (spec.fields != null &&
                                      spec.fields!.isNotEmpty) ...[
                                    const SizedBox(height: Insets.xs),
                                    ...spec.fields!
                                        .asMap()
                                        .entries
                                        .map((fEntry) {
                                      final int fIdx = fEntry.key;
                                      final Field f = fEntry.value;
                                      return Padding(
                                        padding: const EdgeInsets.only(top: 4),
                                        child: TextFormField(
                                          initialValue:
                                              f.value?.toString() ?? '',
                                          decoration: InputDecoration(
                                            labelText:
                                                f.label ?? f.name ?? 'Value',
                                            hintText:
                                                f.helpText ?? f.placeholder,
                                            isDense: true,
                                            border: const OutlineInputBorder(),
                                          ),
                                          onChanged: (String text) {
                                            final updatedFields =
                                                List<Field>.from(spec.fields!);
                                            updatedFields[fIdx] =
                                                f.copyWith(value: text);
                                            specifications[idx] = spec.copyWith(
                                              fields: updatedFields,
                                            );
                                          },
                                        ),
                                      );
                                    }),
                                  ],
                                ],
                              ),
                            ),
                          );
                        }),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dCtx),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () async {
                    final String name = nameController.text.trim();
                    if (name.isEmpty) {
                      messenger.showSnackBar(
                        const SnackBar(
                          content: Text('Please enter a format name.'),
                        ),
                      );
                      return;
                    }

                    final CustomFormatResource payload =
                        (format ?? const CustomFormatResource()).copyWith(
                      name: name,
                      includeCustomFormatWhenRenaming: includeInRenaming,
                      specifications: specifications,
                    );

                    try {
                      final LidarrApi api =
                          await ref.read(lidarrApiProvider(instance).future);
                      if (isNew) {
                        final ApiResponse<CustomFormatResource> resp = await api
                            .customFormat
                            .postCustomformat(body: payload);
                        if (!resp.isSuccess) {
                          throw Exception(
                            resp.error?.message ??
                                'Failed to create custom format',
                          );
                        }
                      } else {
                        final ApiResponse<CustomFormatResource> resp =
                            await api.customFormat.putCustomformatById(
                          id: '${format.id}',
                          body: payload,
                        );
                        if (!resp.isSuccess) {
                          throw Exception(
                            resp.error?.message ??
                                'Failed to update custom format',
                          );
                        }
                      }

                      ref.invalidate(lidarrCustomFormatsProvider(instance));
                      if (dCtx.mounted) {
                        Navigator.pop(dCtx);
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text(
                              'Custom format ${isNew ? 'added' : 'updated'}!',
                            ),
                          ),
                        );
                      }
                    } catch (e) {
                      if (dCtx.mounted) {
                        messenger.showSnackBar(
                          SnackBar(content: Text('Error: $e')),
                        );
                      }
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _deleteCustomFormat(
    BuildContext context,
    WidgetRef ref,
    CustomFormatResource format,
  ) async {
    final int? id = format.id;
    if (id == null) return;

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: Text('Delete ${format.name ?? 'Custom Format'}?'),
        content: Text(
          'Are you sure you want to delete the "${format.name}" custom format?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
              foregroundColor: Theme.of(ctx).colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    try {
      final LidarrApi api = await ref.read(lidarrApiProvider(instance).future);
      final ApiResponse<void> resp =
          await api.customFormat.deleteCustomformatById(id: id);
      if (!resp.isSuccess) {
        throw Exception(
          resp.error?.message ?? 'Failed to delete custom format',
        );
      }

      ref.invalidate(lidarrCustomFormatsProvider(instance));
      messenger.showSnackBar(
        const SnackBar(content: Text('Custom format deleted.')),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Failed to delete custom format: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;
    final AsyncValue<List<CustomFormatResource>> asyncFormats =
        ref.watch(lidarrCustomFormatsProvider(instance));

    ref.watch(lidarrCustomFormatSchemaProvider(instance));

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        heroTag: 'add_custom_format_fab',
        onPressed: () => _showAddEditCustomFormatDialog(context, ref),
        tooltip: 'Add Custom Format',
        child: const Icon(Icons.add),
      ),
      body: EasyRefresh(
        onRefresh: () async {
          ref.invalidate(lidarrCustomFormatsProvider(instance));
        },
        child: AsyncValueView<List<CustomFormatResource>>(
          value: asyncFormats,
          data: (List<CustomFormatResource> formats) {
            if (formats.isEmpty) {
              return Center(
                child: EmptyView(
                  icon: Icons.tune,
                  title: 'No Custom Formats',
                  message:
                      'Custom Formats allow scoring and filtering releases by attributes like release title, quality modifier, and size.',
                  action: FilledButton.icon(
                    onPressed: () =>
                        _showAddEditCustomFormatDialog(context, ref),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Custom Format'),
                  ),
                ),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(
                Insets.md,
                Insets.md,
                Insets.md,
                80,
              ),
              itemCount: formats.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (BuildContext context, int index) {
                final CustomFormatResource item = formats[index];
                final List<CustomFormatSpecificationSchema> specs =
                    item.specifications ?? <CustomFormatSpecificationSchema>[];

                return Card(
                  elevation: 0,
                  color: cs.surfaceContainerLow,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: cs.outlineVariant.withValues(alpha: 0.3),
                    ),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    leading: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: cs.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.tune_outlined,
                        color: cs.onPrimaryContainer,
                        size: 22,
                      ),
                    ),
                    title: Text(
                      item.name ?? 'Custom Format',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            if (item.includeCustomFormatWhenRenaming == true)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: cs.secondaryContainer,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'Rename Tag',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: cs.onSecondaryContainer,
                                  ),
                                ),
                              ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: cs.surfaceContainerHigh,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '${specs.length} Conditions',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: cs.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (specs.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            specs
                                .map(
                                  (s) =>
                                      '• ${s.name ?? s.implementationName ?? 'Condition'}'
                                      '${s.negate == true ? ' [NOT]' : ''}'
                                      '${s.requiredVal == true ? ' [REQ]' : ''}',
                                )
                                .join('\n'),
                            style: TextStyle(
                              fontSize: 12,
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, size: 20),
                      tooltip: 'Delete Custom Format',
                      onPressed: () => _deleteCustomFormat(context, ref, item),
                    ),
                    onTap: () => _showAddEditCustomFormatDialog(
                      context,
                      ref,
                      item,
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
