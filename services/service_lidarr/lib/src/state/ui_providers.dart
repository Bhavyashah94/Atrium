import 'package:core_models/core_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

/// Active tab bar index provider per instance.
final lidarrActiveTabBarIndexProvider =
    StateProvider.family<int, Instance>((Ref ref, Instance instance) => 0);

/// Multi-selection artist IDs for bulk operations in ArtistsTab.
final lidarrArtistSelectionProvider = StateProvider.family<Set<int>, Instance>(
  (Ref ref, Instance instance) => <int>{},
);

/// Multi-selection album IDs for batch operations in WantedTab.
final lidarrWantedSelectionProvider = StateProvider.family<Set<int>, Instance>(
  (Ref ref, Instance instance) => <int>{},
);

/// Bottom navigation bar visibility provider per instance.
final lidarrBottomNavVisibleProvider = StateProvider.family<bool, Instance>(
  (Ref ref, Instance instance) => true,
);

/// Scroll-to-top trigger provider per tab.
final lidarrHomeScrollToTopProvider =
    StateProvider.family<int, (Instance, int)>(
  (Ref ref, (Instance, int) key) => 0,
);
