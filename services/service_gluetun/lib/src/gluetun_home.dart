import 'package:core_models/core_models.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'gluetun_api.dart';
import 'gluetun_providers.dart';
import 'models/gluetun_models.dart';

class GluetunHome extends ConsumerStatefulWidget {
  const GluetunHome({required this.instance, super.key});

  final Instance instance;

  @override
  ConsumerState<GluetunHome> createState() => _GluetunHomeState();
}

class _GluetunHomeState extends ConsumerState<GluetunHome> {
  bool _togglingVpn = false;
  bool _togglingDns = false;
  bool _triggeringUpdater = false;

  void _refreshAll() {
    ref.invalidate(gluetunVpnStatusProvider(widget.instance));
    ref.invalidate(gluetunPublicIpProvider(widget.instance));
    ref.invalidate(gluetunDnsStatusProvider(widget.instance));
    ref.invalidate(gluetunUpdaterStatusProvider(widget.instance));
  }

  Future<void> _toggleVpn(bool currentlyRunning) async {
    if (_togglingVpn) return;
    setState(() => _togglingVpn = true);

    try {
      final GluetunApi api =
          await ref.read(gluetunApiProvider(widget.instance).future);
      await api.setVpnStatus(run: !currentlyRunning);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              !currentlyRunning ? 'Starting VPN...' : 'Stopping VPN...',
            ),
          ),
        );
      }
    } on Object catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to change VPN status: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _togglingVpn = false);
        _refreshAll();
      }
    }
  }

  Future<void> _toggleDns(bool currentlyRunning) async {
    if (_togglingDns) return;
    setState(() => _togglingDns = true);

    try {
      final GluetunApi api =
          await ref.read(gluetunApiProvider(widget.instance).future);
      await api.setDnsStatus(run: !currentlyRunning);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              !currentlyRunning ? 'Starting DNS...' : 'Stopping DNS...',
            ),
          ),
        );
      }
    } on Object catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to change DNS status: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _togglingDns = false);
        _refreshAll();
      }
    }
  }

  Future<void> _triggerUpdater() async {
    if (_triggeringUpdater) return;
    setState(() => _triggeringUpdater = true);

    try {
      final GluetunApi api =
          await ref.read(gluetunApiProvider(widget.instance).future);
      await api.setUpdaterStatus(run: true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Triggered server list database update...'),
          ),
        );
      }
    } on Object catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to trigger updater: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _triggeringUpdater = false);
        _refreshAll();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<GluetunVpnStatus> vpnStatus =
        ref.watch(gluetunVpnStatusProvider(widget.instance));
    final AsyncValue<GluetunPublicIp?> publicIp =
        ref.watch(gluetunPublicIpProvider(widget.instance));
    final AsyncValue<GluetunDnsStatus?> dnsStatus =
        ref.watch(gluetunDnsStatusProvider(widget.instance));
    final AsyncValue<GluetunUpdaterStatus?> updaterStatus =
        ref.watch(gluetunUpdaterStatusProvider(widget.instance));

    final ColorScheme scheme = Theme.of(context).colorScheme;

    return EasyRefresh(
      header: const ClassicHeader(
        dragText: 'Pull to refresh',
        armedText: 'Release ready',
        readyText: 'Refreshing...',
        processingText: 'Refreshing...',
        processedText: 'Succeeded',
        failedText: 'Failed',
        messageText: 'Last updated at %T',
      ),
      onRefresh: () async => _refreshAll(),
      child: ListView(
        padding: Insets.page,
        children: <Widget>[
          // VPN Control Card Banner
          vpnStatus.when(
            data: (GluetunVpnStatus status) {
              final bool isRunning = status.isRunning;
              final Color statusColor = isRunning
                  ? (scheme.brightness == Brightness.dark
                      ? Colors.greenAccent
                      : Colors.green)
                  : scheme.error;

              return Card(
                elevation: 0,
                color: statusColor.withValues(alpha: 0.12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: statusColor.withValues(alpha: 0.3),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(Insets.lg),
                  child: Column(
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Container(
                            padding: const EdgeInsets.all(Insets.md),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isRunning
                                  ? Icons.shield_outlined
                                  : Icons.shield_moon_outlined,
                              size: 32,
                              color: statusColor,
                            ),
                          ),
                          const SizedBox(width: Insets.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  'VPN Status',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                        color: scheme.onSurfaceVariant,
                                      ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  status.status.toUpperCase(),
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: statusColor,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: Insets.lg),
                      SizedBox(
                        width: double.infinity,
                        child: _togglingVpn
                            ? const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: CircularProgressIndicator(),
                                ),
                              )
                            : FilledButton.icon(
                                style: FilledButton.styleFrom(
                                  backgroundColor: isRunning
                                      ? scheme.error
                                      : scheme.primary,
                                  foregroundColor: isRunning
                                      ? scheme.onError
                                      : scheme.onPrimary,
                                ),
                                onPressed: () => _toggleVpn(isRunning),
                                icon: Icon(
                                  isRunning
                                      ? Icons.power_settings_new
                                      : Icons.play_arrow,
                                ),
                                label: Text(
                                  isRunning ? 'Stop VPN' : 'Start VPN',
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
              );
            },
            loading: () => const Card(
              child: Padding(
                padding: EdgeInsets.all(Insets.xl),
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
            error: (Object error, StackTrace stack) => Card(
              color: scheme.errorContainer,
              child: Padding(
                padding: const EdgeInsets.all(Insets.lg),
                child: Row(
                  children: <Widget>[
                    Icon(Icons.error_outline, color: scheme.onErrorContainer),
                    const SizedBox(width: Insets.md),
                    Expanded(
                      child: Text(
                        'Could not check VPN status: $error',
                        style: TextStyle(color: scheme.onErrorContainer),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: Insets.lg),

          // Public IP Card (Connection Details)
          Text(
            'Connection Details',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: scheme.primary,
                ),
          ),
          const SizedBox(height: Insets.sm),

          Card(
            elevation: 0,
            color: scheme.surfaceContainerLow,
            child: Padding(
              padding: const EdgeInsets.all(Insets.md),
              child: publicIp.when(
                data: (GluetunPublicIp? ipInfo) {
                  if (ipInfo == null || ipInfo.publicIp.isEmpty) {
                    return const ListTile(
                      leading: Icon(Icons.public_off),
                      title: Text('Public IP Unavailable'),
                      subtitle: Text(
                        'Unable to retrieve external IP or check disabled.',
                      ),
                    );
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.public),
                        title: const Text('Public IP Address'),
                        subtitle: SelectableText(
                          ipInfo.publicIp,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                                fontFamily: 'monospace',
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.copy, size: 20),
                          tooltip: 'Copy IP',
                          onPressed: () {
                            Clipboard.setData(
                              ClipboardData(text: ipInfo.publicIp),
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Public IP copied to clipboard'),
                              ),
                            );
                          },
                        ),
                      ),
                      if (ipInfo.country != null ||
                          ipInfo.region != null ||
                          ipInfo.city != null ||
                          ipInfo.organization != null) ...<Widget>[
                        const Divider(),
                        const SizedBox(height: Insets.xs),
                        Wrap(
                          spacing: Insets.xs,
                          runSpacing: Insets.xs,
                          children: <Widget>[
                            if (ipInfo.country != null)
                              Chip(
                                avatar: const Icon(Icons.flag, size: 16),
                                label: Text(ipInfo.country!),
                                padding: EdgeInsets.zero,
                              ),
                            if (ipInfo.region != null)
                              Chip(
                                avatar:
                                    const Icon(Icons.location_on, size: 16),
                                label: Text(ipInfo.region!),
                                padding: EdgeInsets.zero,
                              ),
                            if (ipInfo.city != null)
                              Chip(
                                avatar:
                                    const Icon(Icons.location_city, size: 16),
                                label: Text(ipInfo.city!),
                                padding: EdgeInsets.zero,
                              ),
                            if (ipInfo.organization != null)
                              Chip(
                                avatar: const Icon(Icons.business, size: 16),
                                label: Text(ipInfo.organization!),
                                padding: EdgeInsets.zero,
                              ),
                          ],
                        ),
                      ],
                    ],
                  );
                },
                loading: () => const Padding(
                  padding: EdgeInsets.all(Insets.md),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (Object error, StackTrace stack) => ListTile(
                  leading: const Icon(Icons.error_outline),
                  title: const Text('Public IP Error'),
                  subtitle: Text('$error'),
                ),
              ),
            ),
          ),

          const SizedBox(height: Insets.md),

          // DNS Server Card with Toggle Action
          Card(
            elevation: 0,
            color: scheme.surfaceContainerLow,
            child: Padding(
              padding: const EdgeInsets.all(Insets.md),
              child: dnsStatus.when(
                data: (GluetunDnsStatus? dns) {
                  final bool isOk = dns?.isRunning ?? false;
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      Icons.dns,
                      color: isOk ? Colors.green : scheme.onSurfaceVariant,
                    ),
                    title: const Text('DNS Server Status'),
                    subtitle: Text(
                      dns?.status.toUpperCase() ?? 'UNKNOWN',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isOk ? Colors.green : null,
                      ),
                    ),
                    trailing: _togglingDns
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : TextButton.icon(
                            onPressed: () => _toggleDns(isOk),
                            icon: Icon(
                              isOk ? Icons.pause : Icons.play_arrow,
                              size: 18,
                            ),
                            label: Text(isOk ? 'Stop' : 'Start'),
                          ),
                  );
                },
                loading: () => const Padding(
                  padding: EdgeInsets.all(Insets.md),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (_, __) => const ListTile(
                  leading: Icon(Icons.dns_outlined),
                  title: Text('DNS Server Status'),
                  subtitle: Text('Unavailable'),
                ),
              ),
            ),
          ),

          const SizedBox(height: Insets.md),

          // Server Database Updater Card with Trigger Action
          Card(
            elevation: 0,
            color: scheme.surfaceContainerLow,
            child: Padding(
              padding: const EdgeInsets.all(Insets.md),
              child: updaterStatus.when(
                data: (GluetunUpdaterStatus? updater) {
                  final bool isRunning = updater?.isRunning ?? false;
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      Icons.sync,
                      color: isRunning ? scheme.primary : scheme.onSurfaceVariant,
                    ),
                    title: const Text('Server Database Updater'),
                    subtitle: Text(
                      updater?.status.toUpperCase() ?? 'IDLE',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isRunning ? scheme.primary : null,
                      ),
                    ),
                    trailing: _triggeringUpdater
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : OutlinedButton.icon(
                            onPressed: _triggerUpdater,
                            icon: const Icon(Icons.refresh, size: 18),
                            label: const Text('Update Servers'),
                          ),
                  );
                },
                loading: () => const Padding(
                  padding: EdgeInsets.all(Insets.md),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (_, __) => const ListTile(
                  leading: Icon(Icons.sync_problem),
                  title: Text('Server Database Updater'),
                  subtitle: Text('Unavailable'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
