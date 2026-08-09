import 'package:core_models/core_models.dart';
import 'package:easy_refresh/easy_refresh.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/tracearr_v2_models.dart';
import '../tracearr_api.dart';
import '../tracearr_providers.dart';
import '../tracearr_user_detail_screen.dart';
import '../utils/tracearr_formatters.dart';
import '../widgets/tracearr_user_avatar.dart';

/// Users tab displaying user account identities, emails, and connected servers.
class TracearrUsersTab extends ConsumerStatefulWidget {
  const TracearrUsersTab({
    required this.instance,
    super.key,
  });

  final Instance instance;

  @override
  ConsumerState<TracearrUsersTab> createState() => _TracearrUsersTabState();
}

class _TracearrUsersTabState extends ConsumerState<TracearrUsersTab>
    with WidgetsBindingObserver {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  double _lastBottomInset = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    final double bottomInset =
        WidgetsBinding.instance.platformDispatcher.views.first.viewInsets.bottom;
    if (bottomInset == 0 && _lastBottomInset > 0) {
      if (_searchFocusNode.hasFocus) {
        _searchFocusNode.unfocus();
      }
    }
    _lastBottomInset = bottomInset;
  }

  void _onScroll() {
    if (_scrollController.hasClients &&
        _scrollController.position.userScrollDirection != ScrollDirection.idle) {
      if (_searchFocusNode.hasFocus) {
        _searchFocusNode.unfocus();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AsyncValue<TracearrV2UsersResponse> asyncUsers =
        ref.watch(tracearrV2GetUsersProvider(widget.instance));

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      behavior: HitTestBehavior.translucent,
      child: EasyRefresh(
        header: const ClassicHeader(
          position: IndicatorPosition.locator,
        ),
        onRefresh: () =>
            ref.refresh(tracearrV2GetUsersProvider(widget.instance).future),
        child: asyncUsers.when(
          data: (TracearrV2UsersResponse response) {
            final List<TracearrV2UserIdentity> allUsers = response.data;

            final List<TracearrV2UserIdentity> filteredUsers = allUsers.where((TracearrV2UserIdentity u) {
              if (_searchQuery.isEmpty) return true;
              final String query = _searchQuery.toLowerCase();
              final String name = (u.username ?? '').toLowerCase();
              final String email = (u.email ?? '').toLowerCase();
              return name.contains(query) || email.contains(query);
            }).toList();

            int totalConnectedAccounts = 0;
            for (final TracearrV2UserIdentity u in allUsers) {
              totalConnectedAccounts += u.accounts.length;
            }

            return CustomScrollView(
              controller: _scrollController,
              slivers: <Widget>[
                SliverAppBar(
                  floating: true,
                  snap: true,
                  scrolledUnderElevation: 0.0,
                  surfaceTintColor: Colors.transparent,
                  backgroundColor: theme.colorScheme.surface,
                  toolbarHeight: 72,
                  titleSpacing: 0,
                  leadingWidth: 56,
                  leading: Builder(
                    builder: (BuildContext ctx) {
                      final ScaffoldState? scaffold =
                          Scaffold.maybeOf(ctx);
                      if (scaffold?.hasDrawer ?? false) {
                        return IconButton(
                          icon: const Icon(Icons.menu),
                          onPressed: () => scaffold?.openDrawer(),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                  title: SearchBar(
                    focusNode: _searchFocusNode,
                    controller: _searchController,
                    hintText: 'Search users...',
                    onTapOutside: (_) => FocusScope.of(context).unfocus(),
                    elevation: const WidgetStatePropertyAll<double>(0),
                    backgroundColor: WidgetStatePropertyAll<Color>(
                      theme.colorScheme.surfaceContainerHigh,
                    ),
                    trailing: <Widget>[
                      if (_searchQuery.isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            _searchFocusNode.unfocus();
                            setState(() {
                              _searchQuery = '';
                            });
                          },
                        ),
                    ],
                  onChanged: (String val) {
                    setState(() {
                      _searchQuery = val;
                    });
                  },
                ),
                actions: <Widget>[
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    tooltip: 'Refresh Users',
                    onPressed: () =>
                        ref.refresh(tracearrV2GetUsersProvider(widget.instance).future),
                  ),
                  const SizedBox(width: 8),
                ],
              ),
              const HeaderLocator.sliver(),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: <Widget>[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 16,
                          horizontal: 20,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHigh,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: <Widget>[
                            Column(
                              children: <Widget>[
                                Icon(
                                  Icons.people_alt_outlined,
                                  color: Theme.of(context).colorScheme.primary,
                                  size: 22,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${allUsers.length}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  'Total Users',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                            Column(
                              children: <Widget>[
                                Icon(
                                  Icons.dns_outlined,
                                  color: Theme.of(context).colorScheme.tertiary,
                                  size: 22,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '$totalConnectedAccounts',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  'Connected Accounts',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        onChanged: (String val) => setState(() => _searchQuery = val),
                        decoration: InputDecoration(
                          hintText: 'Search users by username or email...',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () => setState(() => _searchQuery = ''),
                                )
                              : null,
                          filled: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (filteredUsers.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Icon(
                          Icons.person_off_outlined,
                          size: 64,
                          color: Theme.of(context).colorScheme.outline,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          allUsers.isEmpty ? 'No Users Found' : 'No Matching Users',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (BuildContext context, int index) {
                        return _UserAccountTile(
                          instance: widget.instance,
                          user: filteredUsers[index],
                        );
                      },
                      childCount: filteredUsers.length,
                    ),
                  ),
                ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (Object error, StackTrace stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 12),
              Text('Failed to load users: $error'),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => ref.invalidate(tracearrV2GetUsersProvider(widget.instance)),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }
}

class _UserAccountTile extends ConsumerWidget {
  const _UserAccountTile({
    required this.instance,
    required this.user,
  });

  final Instance instance;
  final TracearrV2UserIdentity user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String username = user.username ?? 'Unknown User';
    final TracearrApi? api = ref.watch(tracearrApiProvider(instance)).value;
    final Map<String, String> serverMap =
        ref.watch(tracearrServerNamesMapProvider(instance));
    final Map<String, String> avatarMap =
        ref.watch(tracearrUserAvatarsMapProvider(instance));

    final String? rawAvatarPath = user.id != null ? avatarMap[user.id!] : null;
    final String? avatarUrl = api?.imageUrl(rawAvatarPath);

    final String subtitleText;
    if (user.email != null && user.email!.trim().isNotEmpty) {
      subtitleText = user.email!.trim();
    } else if (user.accounts.isNotEmpty) {
      final List<String> serverNames = user.accounts
          .map(
            (TracearrV2UserAccount acc) => resolveServerName(
              serverMap: serverMap,
              serverId: acc.serverId,
              serverType: acc.serverType,
            ),
          )
          .toSet()
          .toList();
      subtitleText = 'Servers: ${serverNames.join(', ')}';
    } else {
      subtitleText = '0 Connected Accounts';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: TracearrUserAvatar(
          username: username,
          avatarUrl: avatarUrl,
          radius: 22,
        ),
        title: Text(
          username,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Text(
          subtitleText,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          if (user.id != null) {
            Navigator.of(context, rootNavigator: true).push(
              MaterialPageRoute<void>(
                builder: (_) => TracearrV2UserDetailScreen(
                  instance: instance,
                  userId: user.id!,
                ),
              ),
            );
          }
        },
      ),
    );
  }
}
