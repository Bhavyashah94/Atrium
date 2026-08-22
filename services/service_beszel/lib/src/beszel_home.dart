import 'package:core_models/core_models.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'beszel_providers.dart';
import 'screens/beszel_system_detail_screen.dart';
import 'widgets/beszel_system_card.dart';

class BeszelHome extends ConsumerWidget {
  const BeszelHome({required this.instance, super.key});

  final Instance instance;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncSystems = ref.watch(beszelSystemsProvider(instance));

    return asyncSystems.when(
      skipLoadingOnReload: true,
      skipLoadingOnRefresh: true,
      data: (systems) {
        if (systems.isEmpty) {
          return EasyRefresh(
            header: const ClassicHeader(
              position: IndicatorPosition.locator,
              dragText: 'Pull to refresh',
              armedText: 'Release ready',
              readyText: 'Refreshing...',
              processingText: 'Refreshing...',
              processedText: 'Succeeded',
              failedText: 'Failed',
              messageText: 'Last updated at %T',
            ),
            onRefresh: () async =>
                ref.refresh(beszelSystemsProvider(instance).future),
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: <Widget>[
                const HeaderLocator.sliver(),
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Container(
                    alignment: Alignment.center,
                    child: const Text('No systems found'),
                  ),
                ),
              ],
            ),
          );
        }

        return EasyRefresh(
          header: const ClassicHeader(
            position: IndicatorPosition.locator,
            dragText: 'Pull to refresh',
            armedText: 'Release ready',
            readyText: 'Refreshing...',
            processingText: 'Refreshing...',
            processedText: 'Succeeded',
            failedText: 'Failed',
            messageText: 'Last updated at %T',
          ),
          onRefresh: () async =>
              ref.refresh(beszelSystemsProvider(instance).future),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: <Widget>[
              const HeaderLocator.sliver(),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  Insets.md,
                  Insets.md,
                  Insets.md,
                  Insets.xxl,
                ),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((
                    BuildContext context,
                    int index,
                  ) {
                    final system = systems[index];
                    return InkWell(
                      onTap: () => pushScreen<void>(
                        context,
                        BeszelSystemDetailScreen(
                          instance: instance,
                          system: system,
                        ),
                      ),
                      child: BeszelSystemCard(
                        instance: instance,
                        system: system,
                      ),
                    );
                  }, childCount: systems.length),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: Insets.xl)),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text('Error: $e')),
    );
  }
}
