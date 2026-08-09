import 'package:core_models/core_models.dart';
import 'package:core_router/core_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'home/dashboard_tab.dart';
import 'home/history_tab.dart';
import 'home/libraries_tab.dart';
import 'home/recently_added_tab.dart';
import 'home/users_tab.dart';
import 'tracearr_providers.dart';

/// Tracearr 2.0 per-instance main hub UI matching Sonarr and Radarr architecture:
/// Material 3 Bottom NavigationBar, auto-hiding scroll listener, PopScope unwinding, and IndexedStack.
class TracearrHome extends ConsumerWidget {
  const TracearrHome({
    required this.instance,
    this.drawer,
    super.key,
  });

  final Instance instance;
  final Widget? drawer;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final int currentIndex = ref.watch(tracearrActiveTabBarIndexProvider(instance));
    final bool isNavbarVisible = ref.watch(tracearrBottomNavVisibleProvider(instance));

    final List<Widget> tabs = <Widget>[
      TracearrDashboardTab(instance: instance),
      TracearrHistoryTab(instance: instance),
      TracearrRecentlyAddedTab(instance: instance),
      TracearrUsersTab(instance: instance),
      TracearrLibrariesTab(instance: instance),
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
                      ref.read(tracearrBottomNavVisibleProvider(instance));
                  if (isScrollingDown && currentVisible) {
                    ref
                        .read(tracearrBottomNavVisibleProvider(instance).notifier)
                        .state = false;
                  } else if (!isScrollingDown && !currentVisible && !isAtBottom) {
                    ref
                        .read(tracearrBottomNavVisibleProvider(instance).notifier)
                        .state = true;
                  }
                }
              } else if (pixels <= 0.0) {
                final bool currentVisible =
                    ref.read(tracearrBottomNavVisibleProvider(instance));
                if (!currentVisible) {
                  ref
                      .read(tracearrBottomNavVisibleProvider(instance).notifier)
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

                if (Scaffold.of(context).isDrawerOpen) {
                  Navigator.of(context).pop();
                  return;
                }

                if (ref.read(tracearrActiveTabBarIndexProvider(instance)) != 0) {
                  ref
                      .read(tracearrActiveTabBarIndexProvider(instance).notifier)
                      .state = 0;
                  return;
                }

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
      floatingActionButton: (currentIndex == 1 || currentIndex == 2) && isNavbarVisible
          ? FloatingActionButton.small(
              heroTag: 'tracearr_sort_filter_fab',
              backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
              foregroundColor: Theme.of(context).colorScheme.onSecondaryContainer,
              onPressed: () {
                if (currentIndex == 1) {
                  showModalBottomSheet<void>(
                    context: context,
                    showDragHandle: true,
                    useRootNavigator: true,
                    builder: (BuildContext context) =>
                        TracearrHistorySortFilterBottomSheet(instance: instance),
                  );
                } else if (currentIndex == 2) {
                  showModalBottomSheet<void>(
                    context: context,
                    showDragHandle: true,
                    useRootNavigator: true,
                    builder: (BuildContext context) =>
                        TracearrRecentlyAddedSortFilterBottomSheet(instance: instance),
                  );
                }
              },
              child: const Icon(Icons.tune),
            )
          : null,
      bottomNavigationBar: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: isNavbarVisible ? 80 : 0,
        child: SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          child: SizedBox(
            height: 80,
            child: NavigationBar(
              selectedIndex: currentIndex,
              onDestinationSelected: (int index) {
                ref
                    .read(tracearrActiveTabBarIndexProvider(instance).notifier)
                    .state = index;
              },
              destinations: const <Widget>[
                NavigationDestination(
                  icon: Icon(Icons.dashboard_outlined),
                  selectedIcon: Icon(Icons.dashboard),
                  label: 'Dashboard',
                ),
                NavigationDestination(
                  icon: Icon(Icons.history_outlined),
                  selectedIcon: Icon(Icons.history),
                  label: 'History',
                ),
                NavigationDestination(
                  icon: Icon(Icons.grid_view_outlined),
                  selectedIcon: Icon(Icons.grid_view),
                  label: 'Recent',
                ),
                NavigationDestination(
                  icon: Icon(Icons.people_alt_outlined),
                  selectedIcon: Icon(Icons.people_alt),
                  label: 'Users',
                ),
                NavigationDestination(
                  icon: Icon(Icons.video_library_outlined),
                  selectedIcon: Icon(Icons.video_library),
                  label: 'Libraries',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
