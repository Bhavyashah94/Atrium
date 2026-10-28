import 'package:core_models/core_models.dart';
import 'package:core_ui/core_ui.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../slskd_api.dart';
import '../slskd_providers.dart';

/// Modal bottom sheet allowing inspection of daemon configuration, editing slskd.yml,
/// dry-run YAML validation, and triggering runtime diagnostics.
class SlskdOptionsSheet extends ConsumerStatefulWidget {
  const SlskdOptionsSheet({
    required this.instance,
    super.key,
  });

  final Instance instance;

  static Future<void> show(
    BuildContext context, {
    required Instance instance,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SlskdOptionsSheet(instance: instance),
    );
  }

  @override
  ConsumerState<SlskdOptionsSheet> createState() => _SlskdOptionsSheetState();
}

class _SlskdOptionsSheetState extends ConsumerState<SlskdOptionsSheet>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final TextEditingController _yamlController = TextEditingController();
  bool _isYamlLoaded = false;
  bool _isActionInProgress = false;
  String? _validationResult;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _yamlController.dispose();
    super.dispose();
  }

  Future<void> _handleValidateYaml() async {
    setState(() {
      _isActionInProgress = true;
      _validationResult = null;
    });
    try {
      final SlskdApi api =
          await ref.read(slskdApiProvider(widget.instance).future);
      final error = await api.validateYaml(_yamlController.text);
      if (mounted) {
        setState(() {
          _validationResult = error ?? 'Configuration is valid! No syntax errors.';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _validationResult = 'Validation request error: $e');
      }
    } finally {
      if (mounted) setState(() => _isActionInProgress = false);
    }
  }

  Future<void> _handleSaveYaml() async {
    final messenger = ScaffoldMessenger.of(context);
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Save Configuration?'),
        content: const Text(
          'A backup copy of slskd.yml will be created automatically. The daemon may reload or require a restart.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Save & Apply'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isActionInProgress = true);
    try {
      final SlskdApi api =
          await ref.read(slskdApiProvider(widget.instance).future);
      await api.updateYaml(_yamlController.text);
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Configuration saved to daemon host!'),
          duration: Duration(seconds: 2),
        ),
      );
      ref.invalidate(slskdYamlContentProvider(widget.instance));
      ref.invalidate(slskdOptionsProvider(widget.instance));
    } catch (e) {
      final msg = (e is DioException && e.response?.statusCode == 403)
          ? 'Saving configuration requires an API key with Administrator role in slskd.yml'
          : 'Failed to save configuration: $e';
      messenger.showSnackBar(
        SnackBar(content: Text(msg)),
      );
    } finally {
      if (mounted) setState(() => _isActionInProgress = false);
    }
  }

  Future<void> _triggerGarbageCollection() async {
    setState(() => _isActionInProgress = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final SlskdApi api =
          await ref.read(slskdApiProvider(widget.instance).future);
      await api.collectGarbage();
      messenger.showSnackBar(
        const SnackBar(
          content: Text('.NET CLR Garbage Collection completed'),
          duration: Duration(seconds: 2),
        ),
      );
      ref.invalidate(slskdPrometheusKpisProvider(widget.instance));
    } catch (e) {
      final msg = (e is DioException && e.response?.statusCode == 403)
          ? 'Garbage collection requires an API key with Administrator/ReadWrite role'
          : 'Failed to trigger GC: $e';
      messenger.showSnackBar(
        SnackBar(content: Text(msg)),
      );
    } finally {
      if (mounted) setState(() => _isActionInProgress = false);
    }
  }

  Future<void> _triggerLoopbackTest() async {
    setState(() => _isActionInProgress = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final SlskdApi api =
          await ref.read(slskdApiProvider(widget.instance).future);
      final testPayload = <String, dynamic>{
        'timestamp': DateTime.now().toIso8601String(),
        'source': 'Atrium',
        'ping': 'pong',
      };
      await api.loopbackTest(testPayload);
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Loopback echo test succeeded (HTTP 200 OK)'),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      final msg = (e is DioException && e.response?.statusCode == 403)
          ? 'Loopback test requires an elevated API key'
          : 'Loopback test failed: $e';
      messenger.showSnackBar(
        SnackBar(content: Text(msg)),
      );
    } finally {
      if (mounted) setState(() => _isActionInProgress = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;

    final optionsAsync = ref.watch(slskdOptionsProvider(widget.instance));
    final yamlAsync = ref.watch(slskdYamlContentProvider(widget.instance));

    // Initialize YAML editor once data arrives
    yamlAsync.whenData((content) {
      if (!_isYamlLoaded) {
        _yamlController.text = content;
        _isYamlLoaded = true;
      }
    });

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Material(
          color: colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              // Sheet Handle
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.symmetric(vertical: Insets.sm),
                  decoration: BoxDecoration(
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: Insets.md),
                child: Row(
                  children: <Widget>[
                    Container(
                      padding: const EdgeInsets.all(Insets.xs),
                      decoration: BoxDecoration(
                        color: colorScheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.settings_suggest_rounded,
                        color: colorScheme.onSecondaryContainer,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: Insets.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'Configuration & Diagnostics',
                            style: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Host options, slskd.yml editor & runtime tools',
                            style: textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: Insets.xs),

              // Normal TabBar
              TabBar(
                controller: _tabController,
                dividerColor: colorScheme.outlineVariant.withValues(alpha: 0.3),
                indicatorColor: colorScheme.primary,
                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: colorScheme.primary,
                unselectedLabelColor: colorScheme.onSurfaceVariant,
                labelStyle: textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                unselectedLabelStyle: textTheme.titleSmall,
                tabs: const <Widget>[
                  Tab(text: 'Overview'),
                  Tab(text: 'slskd.yml'),
                  Tab(text: 'Diagnostics'),
                ],
              ),

              // Body content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: <Widget>[
                    _buildOverview(context, optionsAsync, colorScheme, textTheme, scrollController),
                    _buildYamlEditor(context, yamlAsync, colorScheme, textTheme),
                    _buildDiagnostics(context, colorScheme, textTheme),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOverview(
    BuildContext context,
    AsyncValue<Map<String, dynamic>> optionsAsync,
    ColorScheme colorScheme,
    TextTheme textTheme,
    ScrollController scrollController,
  ) {
    return optionsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(Insets.xl),
          child: Text(
            'Failed to load options: $err',
            style: TextStyle(color: colorScheme.error),
          ),
        ),
      ),
      data: (options) {
        if (options.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(Insets.xl),
              child: Text(
                'Options unavailable or remote configuration disabled.',
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          );
        }

        final soulseek = options['soulseek'] as Map? ?? const {};
        final directories = options['directories'] as Map? ?? const {};
        final flags = options['flags'] as Map? ?? const {};
        final network = options['network'] as Map? ?? const {};

        return ListView(
          controller: scrollController,
          padding: const EdgeInsets.all(Insets.md),
          children: <Widget>[
            // Soulseek Network settings card
            Card(
              elevation: 0,
              color: colorScheme.surfaceContainerLow,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(Insets.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Icon(Icons.public_rounded, size: 18, color: colorScheme.primary),
                        const SizedBox(width: Insets.xs),
                        Text(
                          'Soulseek Account & Listening',
                          style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: Insets.sm),
                    _buildConfigRow('Username', soulseek['username']?.toString() ?? 'N/A'),
                    _buildConfigRow('Listen Port', soulseek['listenPort']?.toString() ?? 'Auto'),
                    _buildConfigRow('UPnP Enabled', (network['upnp'] ?? false).toString()),
                    _buildConfigRow('Remote Config Allowed', (options['remoteConfiguration'] ?? false).toString()),
                  ],
                ),
              ),
            ),

            const SizedBox(height: Insets.md),

            // Directories card
            Card(
              elevation: 0,
              color: colorScheme.surfaceContainerLow,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(Insets.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Icon(Icons.folder_copy_rounded, size: 18, color: colorScheme.secondary),
                        const SizedBox(width: Insets.xs),
                        Text(
                          'Host Storage Locations',
                          style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: Insets.sm),
                    _buildConfigRow('Downloads Dir', directories['downloads']?.toString() ?? 'Default'),
                    _buildConfigRow('Incomplete Dir', directories['incomplete']?.toString() ?? 'Default'),
                    _buildConfigRow('Remote File Mgmt', (options['remoteFileManagement'] ?? false).toString()),
                  ],
                ),
              ),
            ),

            const SizedBox(height: Insets.md),

            // Runtime Flags card
            Card(
              elevation: 0,
              color: colorScheme.surfaceContainerLow,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(Insets.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Icon(Icons.flag_rounded, size: 18, color: colorScheme.tertiary),
                        const SizedBox(width: Insets.xs),
                        Text(
                          'Startup Flags',
                          style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: Insets.sm),
                    _buildConfigRow('Debug Mode', (options['debug'] ?? false).toString()),
                    _buildConfigRow('No Config Watch', (flags['noConfigWatch'] ?? false).toString()),
                    _buildConfigRow('Dumpable', (flags['dumpable'] ?? false).toString()),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildConfigRow(String label, String value) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Insets.xs / 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildYamlEditor(
    BuildContext context,
    AsyncValue<String> yamlAsync,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    return yamlAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) {
        final isForbidden =
            err is DioException && err.response?.statusCode == 403;
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(Insets.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(
                  Icons.lock_outline_rounded,
                  size: 40,
                  color: colorScheme.error,
                ),
                const SizedBox(height: Insets.sm),
                Text(
                  isForbidden
                      ? 'Access restricted: Reading and writing slskd.yml requires an API key with Administrator role or active JWT session.'
                      : 'Failed to read slskd.yml: $err',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: colorScheme.error),
                ),
              ],
            ),
          ),
        );
      },
      data: (_) {
        return Column(
          children: <Widget>[
            // Info banner
            Container(
              margin: const EdgeInsets.symmetric(
                horizontal: Insets.md,
                vertical: Insets.xs,
              ),
              padding: const EdgeInsets.all(Insets.xs),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: <Widget>[
                  Icon(
                    Icons.info_outline_rounded,
                    size: 16,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: Insets.xs),
                  Expanded(
                    child: Text(
                      'Viewing and modifying slskd.yml requires an Administrator role or active JWT session.',
                      style: textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Action toolbar
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: Insets.md,
                vertical: Insets.xs,
              ),
              child: Row(
                children: <Widget>[
                  OutlinedButton.icon(
                    onPressed: _isActionInProgress ? null : _handleValidateYaml,
                    icon: const Icon(Icons.check_circle_outline_rounded, size: 16),
                    label: const Text('Validate'),
                  ),
                  const SizedBox(width: Insets.xs),
                  FilledButton.icon(
                    onPressed: _isActionInProgress ? null : _handleSaveYaml,
                    icon: const Icon(Icons.save_rounded, size: 16),
                    label: const Text('Save'),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.copy_rounded, size: 18),
                    tooltip: 'Copy YAML',
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: _yamlController.text));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('YAML copied to clipboard'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            if (_validationResult != null)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: Insets.md, vertical: Insets.xs),
                padding: const EdgeInsets.all(Insets.sm),
                decoration: BoxDecoration(
                  color: _validationResult!.contains('valid')
                      ? colorScheme.primaryContainer.withValues(alpha: 0.3)
                      : colorScheme.errorContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _validationResult!,
                  style: textTheme.bodySmall?.copyWith(
                    color: _validationResult!.contains('valid')
                        ? colorScheme.primary
                        : colorScheme.error,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

            // Multi-line editor
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(Insets.md),
                child: TextField(
                  controller: _yamlController,
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                  style: textTheme.bodySmall?.copyWith(fontSize: 12),
                  decoration: InputDecoration(
                    hintText: '# slskd configuration YAML...',
                    filled: true,
                    fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDiagnostics(
    BuildContext context,
    ColorScheme colorScheme,
    TextTheme textTheme, [
    ScrollController? scrollController,
  ]) {
    final debugTransfersAsync = ref.watch(slskdDebugTransfersProvider(widget.instance));

    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.all(Insets.md),
      children: <Widget>[
        Text(
          'Runtime Diagnostic Actions',
          style: textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.primary,
          ),
        ),
        const SizedBox(height: Insets.xs),

        // GC Button Card
        Card(
          elevation: 0,
          color: colorScheme.surfaceContainerLow,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
          ),
          child: ListTile(
            leading: Icon(Icons.cleaning_services_rounded, color: colorScheme.primary),
            title: const Text('Force Garbage Collection'),
            subtitle: const Text('Triggers .NET CLR runtime memory cleanup immediately.'),
            trailing: FilledButton.tonal(
              onPressed: _isActionInProgress ? null : _triggerGarbageCollection,
              child: const Text('Run GC'),
            ),
          ),
        ),

        const SizedBox(height: Insets.sm),

        // Loopback Ping Card
        Card(
          elevation: 0,
          color: colorScheme.surfaceContainerLow,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
          ),
          child: ListTile(
            leading: Icon(Icons.repeat_rounded, color: colorScheme.secondary),
            title: const Text('Loopback Echo Test'),
            subtitle: const Text('Verifies daemon REST API ingress and JSON payload roundtrip.'),
            trailing: FilledButton.tonal(
              onPressed: _isActionInProgress ? null : _triggerLoopbackTest,
              child: const Text('Ping'),
            ),
          ),
        ),

        const SizedBox(height: Insets.lg),

        Text(
          'Low-Level Soulseek Client State (/debug/transfers)',
          style: textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: Insets.xs),

        debugTransfersAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Card(
            elevation: 0,
            color: colorScheme.surfaceContainerLow,
            child: Padding(
              padding: const EdgeInsets.all(Insets.md),
              child: Text('Debug state unavailable: $err'),
            ),
          ),
          data: (debugData) {
            return Card(
              elevation: 0,
              color: colorScheme.surfaceContainerLow,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(Insets.md),
                child: SelectableText(
                  debugData.isEmpty ? 'No active debug handles.' : debugData.toString(),
                  style: textTheme.bodySmall?.copyWith(fontSize: 11),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
