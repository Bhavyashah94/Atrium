import 'package:core_models/core_models.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../generated/generated.dart';
import '../../../lidarr_api.dart';
import '../../../lidarr_providers.dart';
import '../widgets/dynamic_schema_form.dart';
import '../widgets/schema_preset_picker.dart';

/// Import Lists configuration section.
class ImportListsSection extends ConsumerWidget {
  const ImportListsSection({required this.instance, super.key});

  final Instance instance;

  Future<void> _selectListPresetAndAdd(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final AsyncValue<List<ImportListResource>> schemasAsync =
        ref.read(lidarrImportListSchemaProvider(instance));

    List<ImportListResource>? presets = schemasAsync.value;
    if (presets == null || presets.isEmpty) {
      try {
        final LidarrApi api =
            await ref.read(lidarrApiProvider(instance).future);
        final ApiResponse<List<ImportListResource>> resp =
            await api.importList.getImportlistSchema();
        presets = resp.data;
      } catch (_) {}
    }

    if (presets == null || presets.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load import list presets.')),
        );
      }
      return;
    }

    if (!context.mounted) return;

    final ImportListResource? selectedPreset =
        await showSchemaPresetPicker<ImportListResource>(
      context: context,
      title: 'Add Import List',
      presets: presets,
      titleBuilder: (preset) {
        final String impl = preset.implementationName?.trim() ?? '';
        final String name = preset.name?.trim() ?? '';
        if (impl.isNotEmpty) return impl;
        if (name.isNotEmpty && name != 'Import List') return name;
        return preset.implementation ?? 'Import List';
      },
      subtitleBuilder: (preset) {
        final String impl = preset.implementationName?.trim() ?? '';
        final String name = preset.name?.trim() ?? '';
        if (impl.isNotEmpty &&
            name.isNotEmpty &&
            name != 'Import List' &&
            name != impl) {
          return name;
        }
        return '';
      },
      icon: Icons.queue_music,
    );

    if (selectedPreset != null && context.mounted) {
      await _showImportListEditorDialog(
        context,
        ref,
        selectedPreset,
        isNew: true,
      );
    }
  }

  Future<void> _showImportListEditorDialog(
    BuildContext context,
    WidgetRef ref,
    ImportListResource list, {
    bool isNew = false,
  }) async {
    final List<Map<String, dynamic>> fields =
        (list.fields ?? []).map((Field f) => f.toJson()).toList();

    final String initialName = isNew
        ? ((list.implementationName?.isNotEmpty == true)
            ? list.implementationName!
            : (list.name != 'Import List' ? (list.name ?? '') : ''))
        : (list.name ?? '');

    final TextEditingController nameController =
        TextEditingController(text: initialName);
    bool enableAutomaticAdd = list.enableAutomaticAdd ?? true;
    bool shouldSearch = list.shouldSearch ?? false;

    // Load available root folders and profiles for dropdowns
    final List<RootFolderResource> rootFolders =
        ref.read(lidarrRootFoldersProvider(instance)).value ?? [];
    final List<QualityProfileResource> qualityProfiles =
        ref.read(lidarrQualityProfilesProvider(instance)).value ?? [];
    final List<MetadataProfileResource> metadataProfiles =
        ref.read(lidarrMetadataProfilesProvider(instance)).value ?? [];

    String? rootFolderPath = list.rootFolderPath ??
        (rootFolders.isNotEmpty ? rootFolders.first.path : null);
    int? qualityProfileId = list.qualityProfileId ??
        (qualityProfiles.isNotEmpty ? qualityProfiles.first.id : null);
    int? metadataProfileId = list.metadataProfileId ??
        (metadataProfiles.isNotEmpty ? metadataProfiles.first.id : null);

    if (!context.mounted) return;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext ctx) {
        return StatefulBuilder(
          builder: (BuildContext dCtx, StateSetter setDialogState) {
            return AlertDialog(
              title: Text(
                isNew
                    ? 'Add ${list.name ?? 'Import List'}'
                    : 'Edit ${list.name ?? 'Import List'}',
              ),
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
                          labelText: 'List Name',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: Insets.sm),
                      SwitchListTile(
                        title: const Text('Enable Automatic Add'),
                        subtitle:
                            const Text('Automatically add new artists/albums'),
                        value: enableAutomaticAdd,
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        onChanged: (bool val) =>
                            setDialogState(() => enableAutomaticAdd = val),
                      ),
                      SwitchListTile(
                        title: const Text('Search on Add'),
                        subtitle: const Text(
                          'Start automatic search for added albums',
                        ),
                        value: shouldSearch,
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        onChanged: (bool val) =>
                            setDialogState(() => shouldSearch = val),
                      ),
                      if (rootFolders.isNotEmpty) ...[
                        const SizedBox(height: Insets.xs),
                        DropdownButtonFormField<String>(
                          initialValue: rootFolderPath,
                          decoration: const InputDecoration(
                            labelText: 'Root Folder',
                            border: OutlineInputBorder(),
                          ),
                          items: rootFolders.map((RootFolderResource rf) {
                            return DropdownMenuItem<String>(
                              value: rf.path,
                              child: Text(
                                rf.path ?? 'Unknown',
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                          onChanged: (String? val) =>
                              setDialogState(() => rootFolderPath = val),
                        ),
                      ],
                      if (qualityProfiles.isNotEmpty) ...[
                        const SizedBox(height: Insets.sm),
                        DropdownButtonFormField<int>(
                          initialValue: qualityProfileId,
                          decoration: const InputDecoration(
                            labelText: 'Quality Profile',
                            border: OutlineInputBorder(),
                          ),
                          items:
                              qualityProfiles.map((QualityProfileResource qp) {
                            return DropdownMenuItem<int>(
                              value: qp.id,
                              child: Text(qp.name ?? 'Quality Profile'),
                            );
                          }).toList(),
                          onChanged: (int? val) =>
                              setDialogState(() => qualityProfileId = val),
                        ),
                      ],
                      if (metadataProfiles.isNotEmpty) ...[
                        const SizedBox(height: Insets.sm),
                        DropdownButtonFormField<int>(
                          initialValue: metadataProfileId,
                          decoration: const InputDecoration(
                            labelText: 'Metadata Profile',
                            border: OutlineInputBorder(),
                          ),
                          items: metadataProfiles
                              .map((MetadataProfileResource mp) {
                            return DropdownMenuItem<int>(
                              value: mp.id,
                              child: Text(mp.name ?? 'Metadata Profile'),
                            );
                          }).toList(),
                          onChanged: (int? val) =>
                              setDialogState(() => metadataProfileId = val),
                        ),
                      ],
                      const SizedBox(height: Insets.md),
                      const Text(
                        'Provider Settings',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: Insets.xs),
                      DynamicSchemaForm(
                        fields: fields,
                        onTest:
                            (List<Map<String, dynamic>> updatedFields) async {
                          final LidarrApi api = await ref
                              .read(lidarrApiProvider(instance).future);
                          final ImportListResource payload = list.copyWith(
                            name: nameController.text.trim().isNotEmpty
                                ? nameController.text.trim()
                                : list.name,
                            enableAutomaticAdd: enableAutomaticAdd,
                            shouldSearch: shouldSearch,
                            rootFolderPath: rootFolderPath,
                            qualityProfileId: qualityProfileId,
                            metadataProfileId: metadataProfileId,
                            fields: updatedFields.map(Field.fromJson).toList(),
                          );
                          final ApiResponse<void> resp = await api.importList
                              .postImportlistTest(body: payload);
                          if (!resp.isSuccess) {
                            throw Exception(
                              resp.error?.message ?? 'List test failed',
                            );
                          }
                        },
                        onSave:
                            (List<Map<String, dynamic>> updatedFields) async {
                          final ScaffoldMessengerState messenger =
                              ScaffoldMessenger.of(context);
                          final String enteredName = nameController.text.trim();
                          final ImportListResource payload = list.copyWith(
                            name: enteredName.isNotEmpty
                                ? enteredName
                                : list.name,
                            enableAutomaticAdd: enableAutomaticAdd,
                            shouldSearch: shouldSearch,
                            rootFolderPath: rootFolderPath,
                            qualityProfileId: qualityProfileId,
                            metadataProfileId: metadataProfileId,
                            fields: updatedFields.map(Field.fromJson).toList(),
                          );

                          try {
                            final LidarrApi api = await ref
                                .read(lidarrApiProvider(instance).future);
                            if (isNew) {
                              final ApiResponse<ImportListResource> resp =
                                  await api.importList
                                      .postImportlist(body: payload);
                              if (!resp.isSuccess) {
                                throw Exception(
                                  resp.error?.message ??
                                      'Failed to create import list',
                                );
                              }
                            } else {
                              final ApiResponse<ImportListResource> resp =
                                  await api.importList.putImportlistById(
                                id: list.id!,
                                body: payload,
                              );
                              if (!resp.isSuccess) {
                                throw Exception(
                                  resp.error?.message ??
                                      'Failed to update import list',
                                );
                              }
                            }

                            ref.invalidate(lidarrImportListsProvider(instance));
                            if (ctx.mounted) {
                              Navigator.pop(ctx);
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Import list ${isNew ? 'added' : 'updated'}!',
                                  ),
                                ),
                              );
                            }
                          } catch (e) {
                            if (ctx.mounted) {
                              messenger.showSnackBar(
                                SnackBar(
                                  content:
                                      Text('Failed to save import list: $e'),
                                ),
                              );
                            }
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _deleteImportList(
    BuildContext context,
    WidgetRef ref,
    ImportListResource list,
  ) async {
    final int? id = list.id;
    if (id == null) return;

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: Text('Delete ${list.name ?? 'Import List'}?'),
        content:
            const Text('Are you sure you want to delete this import list?'),
        actions: [
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
          await api.importList.deleteImportlistById(id: id);
      if (!resp.isSuccess) {
        throw Exception(
          resp.error?.message ?? 'Failed to delete import list',
        );
      }

      ref.invalidate(lidarrImportListsProvider(instance));
      messenger.showSnackBar(
        const SnackBar(content: Text('Import list deleted.')),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Failed to delete import list: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final AsyncValue<List<ImportListResource>> asyncLists =
        ref.watch(lidarrImportListsProvider(instance));

    // Prefetch schemas & dependencies
    ref.watch(lidarrImportListSchemaProvider(instance));
    ref.watch(lidarrRootFoldersProvider(instance));
    ref.watch(lidarrQualityProfilesProvider(instance));
    ref.watch(lidarrMetadataProfilesProvider(instance));

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        heroTag: 'add_import_list',
        onPressed: () => _selectListPresetAndAdd(context, ref),
        tooltip: 'Add Import List',
        child: const Icon(Icons.add),
      ),
      body: EasyRefresh(
        onRefresh: () async =>
            ref.invalidate(lidarrImportListsProvider(instance)),
        child: AsyncValueView<List<ImportListResource>>(
          value: asyncLists,
          data: (List<ImportListResource> lists) {
            if (lists.isEmpty) {
              return Center(
                child: EmptyView(
                  icon: Icons.queue_music_outlined,
                  title: 'No Import Lists',
                  message:
                      'Add Spotify, Last.fm, or MusicBrainz sync lists to automatically import artists and albums.',
                  action: FilledButton.icon(
                    onPressed: () => _selectListPresetAndAdd(context, ref),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Import List'),
                  ),
                ),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(Insets.md),
              itemCount: lists.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (BuildContext context, int index) {
                final ImportListResource item = lists[index];
                final bool autoAdd = item.enableAutomaticAdd == true;

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
                        Icons.queue_music,
                        color: cs.onPrimaryContainer,
                        size: 22,
                      ),
                    ),
                    title: Text(
                      item.name ?? 'Import List',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        [
                          item.implementationName ?? 'List',
                          if (autoAdd)
                            'Auto-Add Enabled'
                          else
                            'Auto-Add Disabled',
                        ].join(' • '),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                      ),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, size: 20),
                      tooltip: 'Delete Import List',
                      onPressed: () => _deleteImportList(context, ref, item),
                    ),
                    onTap: () => _showImportListEditorDialog(
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
