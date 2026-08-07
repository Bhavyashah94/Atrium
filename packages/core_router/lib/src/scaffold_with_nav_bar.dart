import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// The bottom-navigation shell that hosts the four top-level branches.
///
/// Wraps go_router's [StatefulNavigationShell] so each branch keeps its own
/// navigation stack (tapping away from a deep screen and back returns you
/// where you were). Used as the builder for a `StatefulShellRoute`.
class ScaffoldWithNavBar extends StatefulWidget {
  const ScaffoldWithNavBar({
    required this.navigationShell,
    this.drawer,
    super.key,
  });

  final StatefulNavigationShell navigationShell;
  final Widget? drawer;

  @override
  State<ScaffoldWithNavBar> createState() => _ScaffoldWithNavBarState();
}

class _ScaffoldWithNavBarState extends State<ScaffoldWithNavBar> {
  bool _isNavbarVisible = true;

  @override
  void didUpdateWidget(covariant ScaffoldWithNavBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.navigationShell.currentIndex !=
        widget.navigationShell.currentIndex) {
      _isNavbarVisible = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Material's NavigationBar wraps itself in a SafeArea and *then* sizes to
    // its height, so what it actually occupies is that height plus the bottom
    // inset. Pinning it to a bare 80 therefore ate the inset out of the bar
    // itself: on three-button devices, whose inset is roughly twice a gesture
    // bar's, that clipped the selection pill and the icons above the labels.
    // Gesture devices had just enough slack to hide it.
    //
    // padding, not viewPadding: it collapses to zero while the keyboard is up,
    // which is exactly when the bar no longer needs the room.
    final double barHeight = 80.0 + MediaQuery.paddingOf(context).bottom;
    return PopScope<Object?>(
      canPop: widget.navigationShell.currentIndex == 0,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (didPop) return;
        widget.navigationShell.goBranch(0);
      },
      child: Scaffold(
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
                  if (isScrollingDown && _isNavbarVisible) {
                    setState(() {
                      _isNavbarVisible = false;
                    });
                  } else if (!isScrollingDown && !_isNavbarVisible && !isAtBottom) {
                    setState(() {
                      _isNavbarVisible = true;
                    });
                  }
                }
              } else if (pixels <= 0.0) {
                if (!_isNavbarVisible) {
                  setState(() {
                    _isNavbarVisible = true;
                  });
                }
              }
            }
          }
          return false;
        },
        child: widget.navigationShell,
      ),
      drawer: widget.drawer,
      drawerEdgeDragWidth: widget.drawer != null
          ? MediaQuery.sizeOf(context).width * 0.15
          : null,
      bottomNavigationBar: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: _isNavbarVisible ? barHeight : 0.0,
        child: SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          child: SizedBox(
            height: barHeight,
            child: NavigationBar(
              selectedIndex: widget.navigationShell.currentIndex,
              onDestinationSelected: _onTap,
              destinations: const <NavigationDestination>[
                NavigationDestination(
                  icon: Icon(Icons.dashboard_outlined),
                  selectedIcon: Icon(Icons.dashboard),
                  label: 'Dashboard',
                ),
                NavigationDestination(
                  icon: Icon(Icons.calendar_today_outlined),
                  selectedIcon: Icon(Icons.calendar_today),
                  label: 'Calendar',
                ),
                NavigationDestination(
                  icon: Icon(Icons.swap_vert_outlined),
                  selectedIcon: Icon(Icons.swap_vert),
                  label: 'Activity',
                ),
                NavigationDestination(
                  icon: Icon(Icons.settings_outlined),
                  selectedIcon: Icon(Icons.settings),
                  label: 'Settings',
                ),
              ],
            ),
          ),
        ),
      ),
    ),);
  }

  void _onTap(int index) {
    // `initialLocation: true` when re-tapping the current tab pops it back to
    // that branch's root - matches the platform convention.
    widget.navigationShell.goBranch(
      index,
      initialLocation: index == widget.navigationShell.currentIndex,
    );
  }
}
