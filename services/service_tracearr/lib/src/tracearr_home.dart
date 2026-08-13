import 'package:core_models/core_models.dart';
import 'package:core_router/core_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'activity/activity_tab.dart';
import 'media/media_tab.dart';
import 'overview/overview_tab.dart';
import 'people/people_tab.dart';
import 'providers/tracearr_providers.dart';
import 'security/security_tab.dart';

/// Clean-slate 5-destination home shell for Tracearr service.
class TracearrHomeScreen extends ConsumerWidget {
  const TracearrHomeScreen({
    required this.instance,
    this.drawer,
    super.key,
  });

  final Instance instance;
  final Widget? drawer;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(tracearrActiveTabProvider(instance));
    final isNavbarVisible =
        ref.watch(tracearrBottomNavVisibleProvider(instance));

    final streamsAsync = ref.watch(tracearrStreamsProvider(instance));
    final violationsAsync = ref.watch(tracearrViolationsProvider(instance));

    final activeStreamsCount = streamsAsync.value?.length ?? 0;
    final unackViolationsCount =
        violationsAsync.value?.where((v) => !v.acknowledged).length ?? 0;

    final destinations = <Widget>[
      // Destination 0: Overview (Fleet Health, 24h Summary, Live Pulse, 7d Trends)
      OverviewTab(instance: instance),
      // Destination 1: Activity (Active Streams Triage & Continuous Watch History)
      ActivityTab(instance: instance),
      // Destination 2: Media (Recently Added Catalog & Storage Distribution)
      MediaTab(instance: instance),
      // Destination 3: People (User Directory & Cross-Server Linked Accounts)
      PeopleTab(instance: instance),
      // Destination 4: Security (Sentinel Violation Incident Ledger & Triage)
      SecurityTab(instance: instance),
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
              if (pixels > 20.0) {
                final double maxExtent = notification.metrics.maxScrollExtent;
                final bool isAtBottom = pixels >= maxExtent - 20.0;
                final double? delta = notification.scrollDelta;
                if (delta != null && delta.abs() > 4.0) {
                  final bool isScrollingDown = delta > 0.0;
                  final bool currentVisible =
                      ref.read(tracearrBottomNavVisibleProvider(instance));
                  if (isScrollingDown && currentVisible) {
                    ref
                        .read(
                          tracearrBottomNavVisibleProvider(instance).notifier,
                        )
                        .state = false;
                  } else if (!isScrollingDown &&
                      !currentVisible &&
                      !isAtBottom) {
                    ref
                        .read(
                          tracearrBottomNavVisibleProvider(instance).notifier,
                        )
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

                // Close drawer if open
                final ScaffoldState scaffold = Scaffold.of(context);
                if (scaffold.isDrawerOpen) {
                  scaffold.closeDrawer();
                  return;
                }

                // Return to first destination (Overview) if on a deeper tab
                if (ref.read(tracearrActiveTabProvider(instance)) != 0) {
                  ref.read(tracearrActiveTabProvider(instance).notifier).state =
                      0;
                  return;
                }

                // Return to main dashboard
                GoRouter.of(context).go(AtriumRoutes.dashboard);
              },
              child: IndexedStack(
                index: currentIndex,
                children: destinations,
              ),
            );
          },
        ),
      ),
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
                if (index == currentIndex) {
                  ref
                      .read(
                        tracearrHomeScrollToTopProvider(
                          (instance, index),
                        ).notifier,
                      )
                      .update((state) => state + 1);
                } else {
                  ref.read(tracearrActiveTabProvider(instance).notifier).state =
                      index;
                }
              },
              destinations: [
                const NavigationDestination(
                  icon: Icon(Icons.dashboard_outlined),
                  selectedIcon: Icon(Icons.dashboard),
                  label: 'Overview',
                ),
                NavigationDestination(
                  icon: activeStreamsCount > 0
                      ? Badge.count(
                          count: activeStreamsCount,
                          child: const Icon(Icons.sensors_outlined),
                        )
                      : const Icon(Icons.sensors_outlined),
                  selectedIcon: activeStreamsCount > 0
                      ? Badge.count(
                          count: activeStreamsCount,
                          child: const Icon(Icons.sensors),
                        )
                      : const Icon(Icons.sensors),
                  label: 'Activity',
                ),
                const NavigationDestination(
                  icon: Icon(Icons.video_library_outlined),
                  selectedIcon: Icon(Icons.video_library),
                  label: 'Media',
                ),
                const NavigationDestination(
                  icon: Icon(Icons.people_outline),
                  selectedIcon: Icon(Icons.people),
                  label: 'People',
                ),
                NavigationDestination(
                  icon: unackViolationsCount > 0
                      ? Badge.count(
                          count: unackViolationsCount,
                          child: const Icon(Icons.shield_outlined),
                        )
                      : const Icon(Icons.shield_outlined),
                  selectedIcon: unackViolationsCount > 0
                      ? Badge.count(
                          count: unackViolationsCount,
                          child: const Icon(Icons.shield),
                        )
                      : const Icon(Icons.shield),
                  label: 'Security',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
