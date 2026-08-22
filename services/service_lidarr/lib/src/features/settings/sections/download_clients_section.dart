import 'package:core_models/core_models.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../generated/generated.dart';
import '../../../lidarr_api.dart';
import '../../../lidarr_providers.dart';
import '../widgets/dynamic_schema_form.dart';
import '../widgets/schema_preset_picker.dart';

/// Download Clients configuration section.
class DownloadClientsSection extends ConsumerWidget {
  const DownloadClientsSection({required this.instance, super.key});

  final Instance instance;

  Future<void> _selectClientPresetAndAdd(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final AsyncValue<List<DownloadClientResource>> schemasAsync =
        ref.read(lidarrDownloadClientSchemaProvider(instance));
    final List<DownloadClientResource> presets = schemasAsync.value ?? [];
    if (presets.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Loading download client presets...')),
      );
      return;
    }

    final DownloadClientResource? selectedPreset =
        await showSchemaPresetPicker<DownloadClientResource>(
      context: context,
      title: 'Add Download Client',
      presets: presets,
      titleBuilder: (preset) {
        final String impl = preset.implementationName?.trim() ?? '';
        final String name = preset.name?.trim() ?? '';
        if (impl.isNotEmpty) return impl;
        if (name.isNotEmpty && name != 'Client') return name;
        return preset.implementation ?? 'Client';
      },
      subtitleBuilder: (preset) {
        final String impl = preset.implementationName?.trim() ?? '';
        final String name = preset.name?.trim() ?? '';
        if (impl.isNotEmpty &&
            name.isNotEmpty &&
            name != 'Client' &&
            name != impl) {
          return name;
        }
        return '';
      },
      icon: Icons.download_outlined,
    );

    if (selectedPreset != null && context.mounted) {
      await _showClientEditorDialog(
        context,
        ref,
        selectedPreset,
        isNew: true,
      );
    }
  }

  Future<void> _showClientEditorDialog(
    BuildContext context,
    WidgetRef ref,
    DownloadClientResource client, {
    bool isNew = false,
  }) async {
    final List<Map<String, dynamic>> fields =
        (client.fields ?? []).map((Field f) => f.toJson()).toList();

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext ctx) {
        return AlertDialog(
          title: Text(
            isNew
                ? 'Add ${client.name ?? 'Client'}'
                : 'Edit ${client.name ?? 'Client'}',
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: DynamicSchemaForm(
                fields: fields,
                onTest: (List<Map<String, dynamic>> updatedFields) async {
                  final LidarrApi api =
                      await ref.read(lidarrApiProvider(instance).future);
                  final DownloadClientResource payload = client.copyWith(
                    fields: updatedFields.map(Field.fromJson).toList(),
                  );
                  final ApiResponse<void> resp = await api.downloadClient
                      .postDownloadclientTest(body: payload);
                  if (!resp.isSuccess) {
                    throw Exception(
                      resp.error?.message ?? 'Connection test failed',
                    );
                  }
                },
                onSave: (List<Map<String, dynamic>> updatedFields) async {
                  final ScaffoldMessengerState messenger =
                      ScaffoldMessenger.of(context);
                  try {
                    final LidarrApi api =
                        await ref.read(lidarrApiProvider(instance).future);
                    final DownloadClientResource payload = client.copyWith(
                      fields: updatedFields.map(Field.fromJson).toList(),
                    );

                    if (isNew) {
                      final ApiResponse<DownloadClientResource> resp = await api
                          .downloadClient
                          .postDownloadclient(body: payload);
                      if (!resp.isSuccess) {
                        throw Exception(
                          resp.error?.message ??
                              'Failed to create download client',
                        );
                      }
                    } else {
                      final ApiResponse<DownloadClientResource> resp =
                          await api.downloadClient.putDownloadclientById(
                        id: client.id!,
                        body: payload,
                      );
                      if (!resp.isSuccess) {
                        throw Exception(
                          resp.error?.message ??
                              'Failed to update download client',
                        );
                      }
                    }

                    ref.invalidate(lidarrDownloadClientsProvider(instance));
                    if (ctx.mounted) {
                      Navigator.pop(ctx);
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text(
                            isNew
                                ? 'Download client added successfully!'
                                : 'Download client updated successfully!',
                          ),
                        ),
                      );
                    }
                  } catch (e) {
                    if (ctx.mounted) {
                      messenger.showSnackBar(
                        SnackBar(content: Text('Error saving client: $e')),
                      );
                    }
                  }
                },
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteClient(
    BuildContext context,
    WidgetRef ref,
    DownloadClientResource client,
  ) async {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: Text('Delete ${client.name ?? 'Download Client'}?'),
        content: Text('Are you sure you want to delete "${client.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true || client.id == null) return;

    try {
      final LidarrApi api = await ref.read(lidarrApiProvider(instance).future);
      await api.downloadClient.deleteDownloadclientById(id: client.id!);
      ref.invalidate(lidarrDownloadClientsProvider(instance));
      messenger.showSnackBar(
        const SnackBar(content: Text('Download client deleted.')),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Error deleting client: $e')),
      );
    }
  }

  Future<void> _showDownloadClientOptionsDialog(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final AsyncValue<DownloadClientConfigResource> configAsync =
        ref.read(lidarrDownloadClientConfigProvider(instance));
    final DownloadClientConfigResource? config = configAsync.value;

    final TextEditingController workingFoldersController =
        TextEditingController(
      text: config?.downloadClientWorkingFolders ?? '_UNPACK_',
    );
    bool enableCompletedHandling =
        config?.enableCompletedDownloadHandling ?? true;
    bool autoRedownloadFailed = config?.autoRedownloadFailed ?? true;
    bool autoRedownloadInteractive =
        config?.autoRedownloadFailedFromInteractiveSearch ?? true;

    await showDialog<void>(
      context: context,
      builder: (BuildContext ctx) {
        return StatefulBuilder(
          builder: (BuildContext dCtx, StateSetter setModalState) {
            return AlertDialog(
              title: const Text('Download Client Handling'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SwitchListTile(
                      title: const Text('Completed Download Handling'),
                      subtitle: const Text(
                        'Automatically import completed downloads from clients',
                      ),
                      value: enableCompletedHandling,
                      contentPadding: EdgeInsets.zero,
                      onChanged: (bool val) =>
                          setModalState(() => enableCompletedHandling = val),
                    ),
                    const SizedBox(height: Insets.xs),
                    SwitchListTile(
                      title: const Text('Auto Redownload Failed'),
                      subtitle: const Text(
                        'Automatically search for alternatives if a download fails',
                      ),
                      value: autoRedownloadFailed,
                      contentPadding: EdgeInsets.zero,
                      onChanged: (bool val) =>
                          setModalState(() => autoRedownloadFailed = val),
                    ),
                    const SizedBox(height: Insets.xs),
                    SwitchListTile(
                      title: const Text('Redownload Interactive Search'),
                      subtitle: const Text(
                        'Auto redownload failures from interactive search',
                      ),
                      value: autoRedownloadInteractive,
                      contentPadding: EdgeInsets.zero,
                      onChanged: (bool val) => setModalState(
                        () => autoRedownloadInteractive = val,
                      ),
                    ),
                    const SizedBox(height: Insets.sm),
                    TextField(
                      controller: workingFoldersController,
                      decoration: const InputDecoration(
                        labelText: 'Working Folders Pattern',
                        hintText: 'e.g. _UNPACK_',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dCtx),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () async {
                    final ScaffoldMessengerState messenger =
                        ScaffoldMessenger.of(context);
                    try {
                      final LidarrApi api =
                          await ref.read(lidarrApiProvider(instance).future);
                      final DownloadClientConfigResource updated =
                          (config ?? const DownloadClientConfigResource())
                              .copyWith(
                        enableCompletedDownloadHandling:
                            enableCompletedHandling,
                        autoRedownloadFailed: autoRedownloadFailed,
                        autoRedownloadFailedFromInteractiveSearch:
                            autoRedownloadInteractive,
                        downloadClientWorkingFolders:
                            workingFoldersController.text.trim(),
                      );

                      if (config?.id != null) {
                        await api.downloadClientConfig
                            .putConfigDownloadclientById(
                          id: config!.id!.toString(),
                          body: updated,
                        );
                      }

                      ref.invalidate(
                        lidarrDownloadClientConfigProvider(instance),
                      );
                      if (dCtx.mounted) {
                        Navigator.pop(dCtx);
                        messenger.showSnackBar(
                          const SnackBar(
                            content: Text('Download client options saved!'),
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;
    final AsyncValue<List<DownloadClientResource>> asyncClients =
        ref.watch(lidarrDownloadClientsProvider(instance));
    // Warm up schemas and config
    ref.watch(lidarrDownloadClientSchemaProvider(instance));
    ref.watch(lidarrDownloadClientConfigProvider(instance));

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        heroTag: 'client_add_fab',
        onPressed: () => _selectClientPresetAndAdd(context, ref),
        tooltip: 'Add Download Client',
        child: const Icon(Icons.add),
      ),
      body: EasyRefresh(
        onRefresh: () async {
          ref.invalidate(lidarrDownloadClientsProvider(instance));
          ref.invalidate(lidarrDownloadClientConfigProvider(instance));
        },
        child: AsyncValueView<List<DownloadClientResource>>(
          value: asyncClients,
          data: (List<DownloadClientResource> clients) {
            return ListView(
              padding: const EdgeInsets.all(Insets.md),
              children: <Widget>[
                // Options Banner
                Card(
                  elevation: 0,
                  color: cs.surfaceContainerLow,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: cs.outlineVariant.withValues(alpha: 0.3),
                    ),
                  ),
                  child: ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: cs.secondaryContainer,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.tune,
                        color: cs.onSecondaryContainer,
                        size: 20,
                      ),
                    ),
                    title: const Text(
                      'Download Client Handling',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: const Text(
                      'Completed handling, intervals, and redownloads',
                      style: TextStyle(fontSize: 12),
                    ),
                    trailing: const Icon(Icons.chevron_right, size: 20),
                    onTap: () => _showDownloadClientOptionsDialog(context, ref),
                  ),
                ),
                const SizedBox(height: Insets.md),
                if (clients.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: EmptyView(
                        icon: Icons.download_outlined,
                        title: 'No Download Clients',
                        message: 'No download clients configured in Lidarr.',
                        action: FilledButton.icon(
                          onPressed: () =>
                              _selectClientPresetAndAdd(context, ref),
                          icon: const Icon(Icons.add),
                          label: const Text('Add Client'),
                        ),
                      ),
                    ),
                  )
                else
                  ...clients.map((DownloadClientResource client) {
                    final String protocolStr =
                        client.protocol?.value.toUpperCase() ?? 'TORRENT';
                    final bool isEnabled = client.enable ?? true;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Card(
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
                              Icons.download_for_offline_outlined,
                              color: cs.onPrimaryContainer,
                              size: 22,
                            ),
                          ),
                          title: Text(
                            client.name ?? 'Client',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Row(
                              children: <Widget>[
                                Text(
                                  client.implementationName ?? 'Client',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: cs.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: isEnabled
                                        ? cs.primary
                                        : cs.onSurfaceVariant,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  isEnabled ? 'Enabled' : 'Disabled',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: isEnabled
                                        ? cs.primary
                                        : cs.onSurfaceVariant,
                                    fontWeight: isEnabled
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: cs.secondaryContainer,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  protocolStr,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: cs.onSecondaryContainer,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              IconButton(
                                icon:
                                    const Icon(Icons.delete_outline, size: 20),
                                tooltip: 'Delete Client',
                                onPressed: () =>
                                    _deleteClient(context, ref, client),
                              ),
                            ],
                          ),
                          onTap: () => _showClientEditorDialog(
                            context,
                            ref,
                            client,
                          ),
                        ),
                      ),
                    );
                  }),
              ],
            );
          },
        ),
      ),
    );
  }
}
