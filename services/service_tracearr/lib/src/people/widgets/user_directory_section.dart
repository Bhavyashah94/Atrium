import 'package:core_models/core_models.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/tracearr_models.dart';
import '../../providers/tracearr_providers.dart';
import 'user_roster_card.dart';

enum UserSortOption {
  mostPlays,
  mostWatchTime,
  name,
}

/// Container for the user directory roster with live search, sorting, and telemetry.
class UserDirectorySection extends ConsumerStatefulWidget {
  const UserDirectorySection({
    required this.instance,
    super.key,
  });

  final Instance instance;

  @override
  ConsumerState<UserDirectorySection> createState() =>
      _UserDirectorySectionState();
}

class _UserDirectorySectionState extends ConsumerState<UserDirectorySection> {
  final _searchController = TextEditingController();
  UserSortOption _selectedSort = UserSortOption.mostPlays;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<TracearrUserSummary> _filterAndSort(List<TracearrUserSummary> items) {
    final query = _searchController.text.trim().toLowerCase();
    var filtered = items;

    if (query.isNotEmpty) {
      filtered = items.where((u) {
        final matchesUsername = u.username.toLowerCase().contains(query);
        final matchesEmail = u.email?.toLowerCase().contains(query) ?? false;
        return matchesUsername || matchesEmail;
      }).toList();
    }

    final sorted = List<TracearrUserSummary>.from(filtered);
    switch (_selectedSort) {
      case UserSortOption.mostPlays:
        sorted.sort((a, b) => b.allTimePlays.compareTo(a.allTimePlays));
      case UserSortOption.mostWatchTime:
        sorted.sort(
          (a, b) => b.allTimeWatchTimeMs.compareTo(a.allTimeWatchTimeMs),
        );
      case UserSortOption.name:
        sorted.sort((a, b) => a.username.compareTo(b.username));
    }

    return sorted;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final usersAsync = ref.watch(tracearrUsersProvider(widget.instance));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Search & Filter Bar
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search fleet users...',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {});
                          },
                        )
                      : null,
                  isDense: true,
                  filled: true,
                  fillColor: colorScheme.surfaceContainerLow,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: Insets.sm,
                    vertical: Insets.sm,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(Radii.md),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
            const SizedBox(width: Insets.sm),
            PopupMenuButton<UserSortOption>(
              icon: Icon(
                Icons.sort,
                color: colorScheme.onSurfaceVariant,
              ),
              tooltip: 'Sort Users',
              initialValue: _selectedSort,
              onSelected: (option) => setState(() => _selectedSort = option),
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: UserSortOption.mostPlays,
                  child: Text('Most Plays'),
                ),
                const PopupMenuItem(
                  value: UserSortOption.mostWatchTime,
                  child: Text('Most Watch Time'),
                ),
                const PopupMenuItem(
                  value: UserSortOption.name,
                  child: Text('Username (A-Z)'),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: Insets.md),

        // Body States
        usersAsync.when(
          loading: () => Container(
            height: 180,
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(Radii.md),
            ),
            child: const Center(child: ExpressiveProgressIndicator()),
          ),
          error: (err, _) => Container(
            padding: const EdgeInsets.all(Insets.md),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(Radii.md),
            ),
            child: Row(
              children: [
                Icon(Icons.error_outline, color: colorScheme.error),
                const SizedBox(width: Insets.md),
                Expanded(
                  child: Text(
                    err.toString(),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Retry',
                  onPressed: () =>
                      ref.invalidate(tracearrUsersProvider(widget.instance)),
                ),
              ],
            ),
          ),
          data: (items) {
            final filteredUsers = _filterAndSort(items);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Section Title with Count
                Row(
                  children: [
                    Icon(
                      Icons.people_outline,
                      size: 18,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: Insets.xs),
                    Text(
                      'FLEET USERS (${items.length})',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        letterSpacing: 1.1,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: Insets.sm),
                if (filteredUsers.isEmpty) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(Insets.lg),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(Radii.md),
                      border: Border.all(
                        color: colorScheme.outlineVariant.withValues(
                          alpha: 0.3,
                        ),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        _searchController.text.isNotEmpty
                            ? 'No users match "${_searchController.text}".'
                            : 'No users found in fleet directory.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                ] else ...[
                  ...filteredUsers.map((user) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: Insets.sm),
                      child: UserRosterCard(
                        instance: widget.instance,
                        user: user,
                      ),
                    );
                  }),
                ],
              ],
            );
          },
        ),
      ],
    );
  }
}
