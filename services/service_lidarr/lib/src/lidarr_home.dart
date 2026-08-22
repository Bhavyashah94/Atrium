import 'package:core_models/core_models.dart';
import 'package:core_router/core_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'features/activity/activity_tab.dart';
import 'features/artists/artists_tab.dart';
import 'features/settings/settings_tab.dart';
import 'features/system/system_tab.dart';
import 'features/wanted/wanted_tab.dart';
import 'lidarr_providers.dart';

/// Main Lidarr service home screen with Artists, Activity, Wanted, Settings, and System destinations.
class LidarrHome extends ConsumerWidget {
  const LidarrHome({
    required this.instance,
    this.drawer,
    super.key,
  });

  final Instance instance;
  final Widget? drawer;

  /// Clears the active tab's search query. Returns true if there was one.
  bool _clearActiveSearch(WidgetRef ref) {
    final int index = ref.read(lidarrActiveTabBarIndexProvider(instance));
    if (index == 0) {
      final String query = ref.read(lidarrSearchQueryProvider(instance));
      if (query.isNotEmpty) {
        ref.read(lidarrSearchQueryProvider(instance).notifier).state = '';
        return true;
      }
    } else if (index == 1) {
      final String query =
          ref.read(lidarrActivitySearchQueryProvider(instance));
      if (query.isNotEmpty) {
        ref.read(lidarrActivitySearchQueryProvider(instance).notifier).state =
            '';
        return true;
      }
    }
    return false;
  }

  /// Clears the active tab's selection. Returns true if there was one.
  bool _clearActiveSelection(WidgetRef ref) {
    final int index = ref.read(lidarrActiveTabBarIndexProvider(instance));
    if (index == 0) {
      final Set<int> sel = ref.read(lidarrArtistSelectionProvider(instance));
      if (sel.isNotEmpty) {
        ref.read(lidarrArtistSelectionProvider(instance).notifier).state =
            <int>{};
        return true;
      }
    } else if (index == 1) {
      final Set<int> queueSel =
          ref.read(lidarrQueueSelectionProvider(instance));
      final Set<int> blocklistSel =
          ref.read(lidarrBlocklistSelectionProvider(instance));
      if (queueSel.isNotEmpty || blocklistSel.isNotEmpty) {
        ref.read(lidarrQueueSelectionProvider(instance).notifier).state =
            <int>{};
        ref.read(lidarrBlocklistSelectionProvider(instance).notifier).state =
            <int>{};
        return true;
      }
    } else if (index == 2) {
      final Set<int> sel = ref.read(lidarrWantedSelectionProvider(instance));
      if (sel.isNotEmpty) {
        ref.read(lidarrWantedSelectionProvider(instance).notifier).state =
            <int>{};
        return true;
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final int currentIndex =
        ref.watch(lidarrActiveTabBarIndexProvider(instance));
    final bool isNavbarVisible =
        ref.watch(lidarrBottomNavVisibleProvider(instance));

    final bool isSelecting = (currentIndex == 0 &&
            ref.watch(lidarrArtistSelectionProvider(instance)).isNotEmpty) ||
        (currentIndex == 1 &&
            (ref.watch(lidarrQueueSelectionProvider(instance)).isNotEmpty ||
                ref
                    .watch(lidarrBlocklistSelectionProvider(instance))
                    .isNotEmpty)) ||
        (currentIndex == 2 &&
            ref.watch(lidarrWantedSelectionProvider(instance)).isNotEmpty);

    final List<Widget> tabs = [
      ArtistsTab(instance: instance),
      ActivityTab(instance: instance),
      WantedTab(instance: instance),
      SettingsTab(instance: instance),
      SystemTab(instance: instance),
    ];

    return Scaffold(
      drawerEdgeDragWidth:
          drawer != null ? MediaQuery.sizeOf(context).width * 0.15 : null,
      drawer: drawer,
      body: NotificationListener<ScrollNotification>(
        onNotification: (ScrollNotification notification) {
          if (notification.metrics.axis == Axis.vertical) {
            if (notification is ScrollUpdateNotification) {
              final double pixels = notification.metrics.pixels;
              if (pixels > 10.0) {
                final double maxExtent = notification.metrics.maxScrollExtent;
                final bool isAtBottom = pixels >= maxExtent - 10.0;
                final double? delta = notification.scrollDelta;
                if (delta != null && delta != 0.0) {
                  final bool isScrollingDown = delta > 0.0;
                  final bool currentVisible =
                      ref.read(lidarrBottomNavVisibleProvider(instance));
                  if (isScrollingDown && currentVisible) {
                    ref
                        .read(lidarrBottomNavVisibleProvider(instance).notifier)
                        .state = false;
                  } else if (!isScrollingDown &&
                      !currentVisible &&
                      !isAtBottom) {
                    ref
                        .read(lidarrBottomNavVisibleProvider(instance).notifier)
                        .state = true;
                  }
                }
              } else if (pixels <= 0.0) {
                final bool currentVisible =
                    ref.read(lidarrBottomNavVisibleProvider(instance));
                if (!currentVisible) {
                  ref
                      .read(lidarrBottomNavVisibleProvider(instance).notifier)
                      .state = true;
                }
              }
            }
          }
          return false;
        },
        child: Builder(
          builder: (BuildContext context) {
            return PopScope<Object?>(
              canPop: false,
              onPopInvokedWithResult: (bool didPop, Object? result) {
                if (didPop) return;

                // A back press while the drawer is open only closes it.
                if (Scaffold.of(context).isDrawerOpen) {
                  Navigator.of(context).pop();
                  return;
                }

                // Unwind search and selection
                if (_clearActiveSearch(ref)) return;
                if (_clearActiveSelection(ref)) return;

                // If nothing to unwind, go back to dashboard.
                GoRouter.of(context).go(AtriumRoutes.dashboard);
              },
              child: IndexedStack(
                index: currentIndex,
                children: tabs,
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: isNavbarVisible && !isSelecting ? 80 : 0,
        child: SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          child: SizedBox(
            height: 80,
            child: NavigationBar(
              selectedIndex: currentIndex,
              onDestinationSelected: (int index) {
                if (index == currentIndex) {
                  ref
                      .read(
                        lidarrHomeScrollToTopProvider((instance, index))
                            .notifier,
                      )
                      .update((state) => state + 1);
                } else {
                  ref
                      .read(lidarrActiveTabBarIndexProvider(instance).notifier)
                      .state = index;
                }
              },
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.person_outline),
                  selectedIcon: Icon(Icons.person),
                  label: 'Artists',
                ),
                NavigationDestination(
                  icon: Icon(Icons.swap_vert_outlined),
                  selectedIcon: Icon(Icons.swap_vert),
                  label: 'Activity',
                ),
                NavigationDestination(
                  icon: Icon(Icons.running_with_errors_outlined),
                  selectedIcon: Icon(Icons.running_with_errors),
                  label: 'Wanted',
                ),
                NavigationDestination(
                  icon: Icon(Icons.settings_outlined),
                  selectedIcon: Icon(Icons.settings),
                  label: 'Settings',
                ),
                NavigationDestination(
                  icon: Icon(Icons.computer_outlined),
                  selectedIcon: Icon(Icons.computer),
                  label: 'System',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
