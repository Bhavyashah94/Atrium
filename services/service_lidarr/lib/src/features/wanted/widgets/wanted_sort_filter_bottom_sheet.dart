import 'package:core_models/core_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/wanted_providers.dart';

/// Modal bottom sheet for sorting and filtering Wanted albums.
class WantedSortFilterBottomSheet extends ConsumerWidget {
  const WantedSortFilterBottomSheet({required this.instance, super.key});

  final Instance instance;

  static void show(BuildContext context, Instance instance) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (BuildContext ctx) =>
          WantedSortFilterBottomSheet(instance: instance),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;
    final bool monitoredOnly =
        ref.watch(lidarrWantedMonitoredOnlyProvider(instance));
    final WantedSortKey sortKey =
        ref.watch(lidarrWantedSortKeyProvider(instance));
    final bool sortAscending =
        ref.watch(lidarrWantedSortAscendingProvider(instance));

    final bool isNonDefault =
        !monitoredOnly || sortKey != WantedSortKey.releaseDate || sortAscending;

    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Text(
                    'Filter & Sort',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (isNonDefault)
                    TextButton(
                      onPressed: () {
                        ref
                            .read(
                              lidarrWantedMonitoredOnlyProvider(instance)
                                  .notifier,
                            )
                            .state = true;
                        ref
                            .read(
                              lidarrWantedSortKeyProvider(instance).notifier,
                            )
                            .state = WantedSortKey.releaseDate;
                        ref
                            .read(
                              lidarrWantedSortAscendingProvider(instance)
                                  .notifier,
                            )
                            .state = false;
                      },
                      child: const Text('Reset'),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Monitoring Status',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: cs.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              SegmentedButton<bool>(
                segments: const <ButtonSegment<bool>>[
                  ButtonSegment<bool>(
                    value: true,
                    icon: Icon(Icons.bookmark_outlined),
                    label: Text('Monitored Only'),
                  ),
                  ButtonSegment<bool>(
                    value: false,
                    icon: Icon(Icons.all_inclusive_outlined),
                    label: Text('All Albums'),
                  ),
                ],
                selected: <bool>{monitoredOnly},
                onSelectionChanged: (Set<bool> newSelection) {
                  ref
                      .read(
                        lidarrWantedMonitoredOnlyProvider(instance).notifier,
                      )
                      .state = newSelection.first;
                },
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Text(
                    'Sort By',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                  TextButton.icon(
                    icon: Icon(
                      sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                      size: 18,
                    ),
                    label: Text(
                      sortAscending ? 'Ascending' : 'Descending',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    onPressed: () {
                      ref
                          .read(
                            lidarrWantedSortAscendingProvider(instance)
                                .notifier,
                          )
                          .state = !sortAscending;
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: WantedSortKey.values.map((WantedSortKey k) {
                  final bool selected = sortKey == k;
                  return ChoiceChip(
                    label: Text(k.label),
                    selected: selected,
                    onSelected: (bool val) {
                      if (val) {
                        ref
                            .read(
                              lidarrWantedSortKeyProvider(instance).notifier,
                            )
                            .state = k;
                      }
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
