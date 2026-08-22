import 'package:core_models/core_models.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../generated/generated.dart';
import '../../../lidarr_api.dart';
import '../../../lidarr_providers.dart';

/// Quality Definitions bitrate boundaries configuration section.
class QualitySection extends ConsumerWidget {
  const QualitySection({required this.instance, super.key});

  final Instance instance;

  Future<void> _showEditQualityDefinitionDialog(
    BuildContext context,
    WidgetRef ref,
    QualityDefinitionResource item,
  ) async {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final TextEditingController minSizeController =
        TextEditingController(text: '${item.minSize ?? 0}');
    final TextEditingController maxSizeController =
        TextEditingController(text: '${item.maxSize ?? 0}');
    final TextEditingController preferredSizeController =
        TextEditingController(text: '${item.preferredSize ?? 0}');

    await showDialog<void>(
      context: context,
      builder: (BuildContext dCtx) {
        return AlertDialog(
          title: Text(
            'Edit ${item.title ?? item.quality?.name ?? 'Quality Definition'}',
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: minSizeController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Min Size (MB/min)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: Insets.sm),
                  TextField(
                    controller: maxSizeController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Max Size (MB/min - 0 for unlimited)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: Insets.sm),
                  TextField(
                    controller: preferredSizeController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Preferred Size (MB/min)',
                      border: OutlineInputBorder(),
                    ),
                  ),
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
                final double? minSize =
                    double.tryParse(minSizeController.text.trim());
                final double? maxSize =
                    double.tryParse(maxSizeController.text.trim());
                final double? prefSize =
                    double.tryParse(preferredSizeController.text.trim());

                final QualityDefinitionResource payload = item.copyWith(
                  minSize: minSize,
                  maxSize: maxSize,
                  preferredSize: prefSize,
                );

                try {
                  final LidarrApi api =
                      await ref.read(lidarrApiProvider(instance).future);
                  final ApiResponse<QualityDefinitionResource> resp =
                      await api.qualityDefinition.putQualitydefinitionById(
                    id: '${item.id}',
                    body: payload,
                  );
                  if (!resp.isSuccess) {
                    throw Exception(
                      resp.error?.message ??
                          'Failed to update quality definition',
                    );
                  }

                  ref.invalidate(lidarrQualityDefinitionsProvider(instance));
                  if (dCtx.mounted) {
                    Navigator.pop(dCtx);
                    messenger.showSnackBar(
                      const SnackBar(
                        content: Text('Quality definition updated!'),
                      ),
                    );
                  }
                } catch (e) {
                  if (dCtx.mounted) {
                    messenger
                        .showSnackBar(SnackBar(content: Text('Error: $e')));
                  }
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final AsyncValue<List<QualityDefinitionResource>> asyncQualityDefs =
        ref.watch(lidarrQualityDefinitionsProvider(instance));

    return Scaffold(
      body: EasyRefresh(
        onRefresh: () async {
          ref.invalidate(lidarrQualityDefinitionsProvider(instance));
        },
        child: AsyncValueView<List<QualityDefinitionResource>>(
          value: asyncQualityDefs,
          data: (List<QualityDefinitionResource> definitions) {
            if (definitions.isEmpty) {
              return const Center(
                child: EmptyView(
                  icon: Icons.tune,
                  title: 'No Quality Definitions',
                  message:
                      'Quality definitions control file size bitrate boundaries.',
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
              itemCount: definitions.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (BuildContext context, int index) {
                final QualityDefinitionResource item = definitions[index];
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
                        Icons.speed,
                        color: cs.onPrimaryContainer,
                        size: 22,
                      ),
                    ),
                    title: Text(
                      item.title ?? item.quality?.name ?? 'Quality',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'Min: ${item.minSize ?? 0} MB/min • Max: ${item.maxSize == 0 || item.maxSize == null ? 'Unlimited' : '${item.maxSize} MB/min'} • Preferred: ${item.preferredSize ?? 0} MB/min',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                      ),
                    ),
                    trailing: const Icon(Icons.edit_outlined, size: 20),
                    onTap: () =>
                        _showEditQualityDefinitionDialog(context, ref, item),
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
