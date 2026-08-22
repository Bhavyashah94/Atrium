import 'package:core_models/core_models.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../generated/generated.dart';
import '../../../lidarr_api.dart';
import '../../../lidarr_providers.dart';

/// General Host and Network settings section.
class GeneralSettingsSection extends ConsumerStatefulWidget {
  const GeneralSettingsSection({required this.instance, super.key});

  final Instance instance;

  @override
  ConsumerState<GeneralSettingsSection> createState() =>
      _GeneralSettingsSectionState();
}

class _GeneralSettingsSectionState
    extends ConsumerState<GeneralSettingsSection> {
  TextEditingController? _portController;
  TextEditingController? _sslPortController;
  bool? _enableSsl;
  TextEditingController? _urlBaseController;
  TextEditingController? _instanceNameController;
  TextEditingController? _branchController;
  bool? _updateAutomatically;

  @override
  void dispose() {
    _portController?.dispose();
    _sslPortController?.dispose();
    _urlBaseController?.dispose();
    _instanceNameController?.dispose();
    _branchController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;
    final AsyncValue<HostConfigResource> asyncHost =
        ref.watch(lidarrHostConfigProvider(widget.instance));

    return Scaffold(
      body: EasyRefresh(
        onRefresh: () async {
          ref.invalidate(lidarrHostConfigProvider(widget.instance));
        },
        child: AsyncValueView<HostConfigResource>(
          value: asyncHost,
          data: (HostConfigResource host) {
            _portController ??=
                TextEditingController(text: '${host.port ?? 8686}');
            _sslPortController ??=
                TextEditingController(text: '${host.sslPort ?? 6969}');
            _enableSsl ??= host.enableSsl ?? false;
            _urlBaseController ??=
                TextEditingController(text: host.urlBase ?? '');
            _instanceNameController ??=
                TextEditingController(text: host.instanceName ?? 'Lidarr');
            _branchController ??=
                TextEditingController(text: host.branch ?? 'master');
            _updateAutomatically ??= host.updateAutomatically ?? false;

            return ListView(
              padding: const EdgeInsets.fromLTRB(
                Insets.md,
                Insets.md,
                Insets.md,
                80,
              ),
              children: [
                // Host & Port Settings Card
                Card(
                  elevation: 0,
                  color: cs.surfaceContainerLow,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: cs.outlineVariant.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(Insets.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: cs.primaryContainer,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                Icons.dns_outlined,
                                color: cs.onPrimaryContainer,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Host & Network Settings',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: Insets.sm),
                        Container(
                          padding: const EdgeInsets.all(Insets.sm),
                          decoration: BoxDecoration(
                            color: cs.errorContainer.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: cs.error.withValues(alpha: 0.35),
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.warning_amber_rounded,
                                color: cs.error,
                                size: 20,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Caution: Modifying host, port, SSL, or URL base settings can break the connection with this app. Make sure you know what you are doing before saving changes.',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: cs.onErrorContainer,
                                    fontWeight: FontWeight.w500,
                                    height: 1.35,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: Insets.md),
                        TextField(
                          controller: _instanceNameController,
                          decoration: const InputDecoration(
                            labelText: 'Instance Name',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: Insets.sm),
                        TextField(
                          controller: _portController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Port',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: Insets.sm),
                        TextField(
                          controller: _sslPortController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'SSL Port',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: Insets.xs),
                        SwitchListTile(
                          title: const Text('Enable SSL'),
                          value: _enableSsl ?? false,
                          contentPadding: EdgeInsets.zero,
                          onChanged: (bool val) =>
                              setState(() => _enableSsl = val),
                        ),
                        const SizedBox(height: Insets.xs),
                        TextField(
                          controller: _urlBaseController,
                          decoration: const InputDecoration(
                            labelText: 'URL Base',
                            hintText: 'e.g. /lidarr',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: Insets.sm),
                        TextField(
                          controller: _branchController,
                          decoration: const InputDecoration(
                            labelText: 'Branch',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: Insets.xs),
                        SwitchListTile(
                          title: const Text('Update Automatically'),
                          value: _updateAutomatically ?? false,
                          contentPadding: EdgeInsets.zero,
                          onChanged: (bool val) =>
                              setState(() => _updateAutomatically = val),
                        ),
                        const SizedBox(height: Insets.md),
                        if (host.apiKey != null && host.apiKey!.isNotEmpty) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: cs.surfaceContainerHigh,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: cs.outlineVariant.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.key_outlined,
                                  size: 18,
                                  color: cs.primary,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'API Key: ${host.apiKey!}',
                                    style: const TextStyle(
                                      fontFamily: 'monospace',
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.copy, size: 18),
                                  tooltip: 'Copy API Key',
                                  onPressed: () {
                                    Clipboard.setData(
                                      ClipboardData(text: host.apiKey!),
                                    );
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'API Key copied to clipboard!',
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: Insets.md),
                        ],
                        FilledButton.icon(
                          icon: const Icon(Icons.save, size: 18),
                          label: const Text('Save Host Settings'),
                          onPressed: () async {
                            final ScaffoldMessengerState messenger =
                                ScaffoldMessenger.of(context);
                            final HostConfigResource payload = host.copyWith(
                              port: int.tryParse(_portController!.text.trim()),
                              sslPort:
                                  int.tryParse(_sslPortController!.text.trim()),
                              enableSsl: _enableSsl,
                              urlBase: _urlBaseController?.text.trim(),
                              instanceName:
                                  _instanceNameController?.text.trim(),
                              branch: _branchController?.text.trim(),
                              updateAutomatically: _updateAutomatically,
                            );

                            try {
                              final LidarrApi api = await ref.read(
                                lidarrApiProvider(widget.instance).future,
                              );
                              final ApiResponse<HostConfigResource> resp =
                                  await api.hostConfig.putConfigHostById(
                                id: '${host.id}',
                                body: payload,
                              );
                              if (!resp.isSuccess) {
                                throw Exception(
                                  resp.error?.message ??
                                      'Failed to update host settings',
                                );
                              }

                              ref.invalidate(
                                lidarrHostConfigProvider(widget.instance),
                              );
                              messenger.showSnackBar(
                                const SnackBar(
                                  content: Text('Host settings saved!'),
                                ),
                              );
                            } catch (e) {
                              messenger.showSnackBar(
                                SnackBar(content: Text('Error: $e')),
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
