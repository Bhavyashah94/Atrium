import 'package:core_models/core_models.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/slskd_browse_models.dart';
import '../slskd_format.dart';
import '../slskd_providers.dart';
import 'slskd_peer_action_sheet.dart';

/// Shows the bottom sheet listing all users in the active room.
Future<void> showSlskdRoomMembersSheet(
  BuildContext context, {
  required Instance instance,
  required String roomName,
  List<SlskdUserPresence>? initialMembers,
}) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    useSafeArea: true,
    constraints: BoxConstraints(
      maxHeight: MediaQuery.sizeOf(context).height * 0.85,
    ),
    builder: (BuildContext _) => SlskdRoomMembersSheet(
      instance: instance,
      roomName: roomName,
      initialMembers: initialMembers,
    ),
  );
}

/// Modal bottom sheet displaying online room members with presence dots and 1-tap peer shortcuts.
class SlskdRoomMembersSheet extends ConsumerStatefulWidget {
  const SlskdRoomMembersSheet({
    required this.instance,
    required this.roomName,
    this.initialMembers,
    super.key,
  });

  final Instance instance;
  final String roomName;
  final List<SlskdUserPresence>? initialMembers;

  @override
  ConsumerState<SlskdRoomMembersSheet> createState() => _SlskdRoomMembersSheetState();
}

class _SlskdRoomMembersSheetState extends ConsumerState<SlskdRoomMembersSheet> {
  final TextEditingController _searchController = TextEditingController();
  String _filterQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _showInviteMemberDialog() async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Invite to #${widget.roomName}'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Soulseek Username',
            hintText: 'Enter username to grant access',
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
            child: const Text('Invite'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty && mounted) {
      try {
        final api = await ref.read(slskdApiProvider(widget.instance).future);
        await api.addPrivateRoomMember(widget.roomName, result);
        if (!mounted) return;
        ref.invalidate(slskdRoomUsersProvider((widget.instance, widget.roomName)));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Invited $result to #${widget.roomName}')),
        );
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to invite member: $e'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;

    final usersAsync = ref.watch(slskdRoomUsersProvider((widget.instance, widget.roomName)));
    final List<SlskdUserPresence> members =
        usersAsync.value ?? widget.initialMembers ?? const <SlskdUserPresence>[];

    final filtered = _filterQuery.isEmpty
        ? members
        : members.where((m) => m.username.toLowerCase().contains(_filterQuery.toLowerCase())).toList();

    final roomDetailAsync = ref.watch(slskdRoomDetailProvider((widget.instance, widget.roomName)));
    final bool isPrivate = roomDetailAsync.value?.isPrivate ?? false;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Insets.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          // Header
          Row(
            children: <Widget>[
              Icon(Icons.people_alt_rounded, size: 22, color: colorScheme.primary),
              const SizedBox(width: Insets.xs),
              Expanded(
                child: Text(
                  '${widget.roomName} Members (${members.length})',
                  style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (isPrivate)
                IconButton(
                  tooltip: 'Invite member to private room',
                  icon: const Icon(Icons.person_add_alt_1_rounded, size: 20),
                  onPressed: _showInviteMemberDialog,
                ),
              IconButton(
                tooltip: 'Refresh member list',
                icon: const Icon(Icons.refresh_rounded, size: 20),
                onPressed: () {
                  ref.invalidate(slskdRoomUsersProvider((widget.instance, widget.roomName)));
                },
              ),
            ],
          ),
          const SizedBox(height: Insets.xs),

          // Search member filter
          TextField(
            controller: _searchController,
            onChanged: (val) => setState(() => _filterQuery = val.trim()),
            decoration: InputDecoration(
              hintText: 'Search members...',
              isDense: true,
              prefixIcon: const Icon(Icons.search_rounded, size: 20),
              suffixIcon: _filterQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 16),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _filterQuery = '');
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: colorScheme.outlineVariant),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: Insets.sm, vertical: 8),
            ),
          ),
          const SizedBox(height: Insets.sm),

          // Member List
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Text(
                      _filterQuery.isNotEmpty ? 'No members match "$_filterQuery"' : 'No members found',
                      style: textTheme.bodyMedium?.copyWith(color: colorScheme.outline),
                    ),
                  )
                : ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (BuildContext context, int index) {
                      final member = filtered[index];
                      final bool isOnline = member.status == 2;
                      final bool isAway = member.status == 1;

                      final Color presenceColor = slskdPresenceColor(
                        colorScheme,
                        isOnline: isOnline,
                        isAway: isAway,
                      );

                      final String subtitle = member.fileCount > 0
                          ? '${member.fileCount} shares • ${member.averageSpeed > 0 ? slskdFormatRate(member.averageSpeed) : 'Direct'}'
                          : (isOnline ? 'Online' : (isAway ? 'Away' : 'Offline'));

                      return ListTile(
                        dense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: Insets.xs),
                        leading: Stack(
                          children: <Widget>[
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: colorScheme.surfaceContainerHighest,
                              child: Text(
                                member.username.isNotEmpty ? member.username[0].toUpperCase() : '?',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: Container(
                                width: 9,
                                height: 9,
                                decoration: BoxDecoration(
                                  color: presenceColor,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: colorScheme.surface, width: 1.5),
                                ),
                              ),
                            ),
                          ],
                        ),
                        title: Text(
                          member.username,
                          style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Row(
                          children: <Widget>[
                            Icon(
                              slskdPresenceIcon(
                                isOnline: isOnline,
                                isAway: isAway,
                              ),
                              size: 11,
                              color: presenceColor,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                subtitle,
                                style: textTheme.labelSmall?.copyWith(
                                  color: colorScheme.outline,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        trailing: const Icon(Icons.more_vert_rounded, size: 18),
                        onTap: () {
                          Navigator.of(context).pop();
                          showSlskdPeerActionSheet(
                            context,
                            instance: widget.instance,
                            username: member.username,
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
