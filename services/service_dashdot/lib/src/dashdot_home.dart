import 'dart:convert';
import 'package:core_models/core_models.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'dashdot_providers.dart';

class DashdotHome extends ConsumerWidget {
  const DashdotHome({required this.instance, super.key});
  final Instance instance;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final infoAsync = ref.watch(dashdotInfoProvider(instance));
    
    return Scaffold(
      appBar: AppBar(
        title: Text(instance.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(dashdotInfoProvider(instance));
              ref.invalidate(dashdotConfigProvider(instance));
            },
          ),
        ],
      ),
      body: infoAsync.when(
        data: (info) {
          if (info == null) {
            return const Center(child: Text('Failed to load Dashdot info.'));
          }
          return ListView(
            padding: Insets.page,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(Insets.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('System Info', style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: Insets.sm),
                      Text('OS: ${info.os?.name ?? 'Unknown'}'),
                      Text('Uptime: ${info.os?.uptime ?? 'Unknown'}'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: Insets.md),
              _buildStreamCard(context, ref, 'CPU Load', dashdotCpuLoadProvider(instance)),
              const SizedBox(height: Insets.md),
              _buildStreamCard(context, ref, 'RAM Load', dashdotRamLoadProvider(instance)),
              const SizedBox(height: Insets.md),
              _buildStreamCard(context, ref, 'Storage Load', dashdotStorageLoadProvider(instance)),
              const SizedBox(height: Insets.md),
              _buildStreamCard(context, ref, 'Network Load', dashdotNetworkLoadProvider(instance)),
              const SizedBox(height: Insets.md),
              _buildStreamCard(context, ref, 'GPU Load', dashdotGpuLoadProvider(instance)),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildStreamCard(
    BuildContext context, 
    WidgetRef ref, 
    String title, 
    StreamProvider<Map<String, dynamic>?> provider,
  ) {
    // Note: Since we used StreamProvider.family, it's not autoDispose by default unless we declared it so,
    // but we didn't use `.autoDispose`. We used `StreamProvider.family`.
    // Wait, I defined them as `StreamProvider.family` in the other file. 
    // Let me just use `ProviderListenable<AsyncValue<Map<String, dynamic>?>>`.
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(Insets.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: Insets.sm),
            Consumer(
              builder: (context, ref, child) {
                final asyncValue = ref.watch(provider);
                return asyncValue.when(
                  data: (Map<String, dynamic>? data) {
                    if (data == null) return const Text('No data');
                    return Text(
                      const JsonEncoder.withIndent('  ').convert(data),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontFamily: 'monospace',
                      ),
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (Object e, StackTrace st) => Text('Error: $e'),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
