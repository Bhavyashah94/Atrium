import 'package:core_models/core_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'sections/connect_section.dart';
import 'sections/custom_formats_section.dart';
import 'sections/download_clients_section.dart';
import 'sections/general_section.dart';
import 'sections/import_lists_section.dart';
import 'sections/indexers_section.dart';
import 'sections/media_management_section.dart';
import 'sections/metadata_section.dart';
import 'sections/profiles_section.dart';
import 'sections/quality_section.dart';
import 'sections/root_folders_section.dart';
import 'sections/tags_section.dart';
import 'views/settings_category_page.dart';

/// Metadata item for a configurable Lidarr settings category.
class _SettingsItem {
  const _SettingsItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.builder,
  });

  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final Widget Function(BuildContext context, Instance instance) builder;
}

/// Grouping of related Lidarr settings categories.
class _SettingsGroup {
  const _SettingsGroup({
    required this.title,
    required this.items,
  });

  final String title;
  final List<_SettingsItem> items;
}

/// Modernized Lidarr Settings Tab featuring a categorized card list.
class SettingsTab extends ConsumerWidget {
  const SettingsTab({required this.instance, super.key});

  final Instance instance;

  static final List<_SettingsGroup> _groups = [
    _SettingsGroup(
      title: 'Profiles & Quality',
      items: [
        _SettingsItem(
          id: 'profiles',
          title: 'Profiles',
          subtitle: 'Quality, metadata, delay, and release profiles',
          icon: Icons.tune,
          builder: (context, instance) => ProfilesSection(instance: instance),
        ),
        _SettingsItem(
          id: 'quality',
          title: 'Quality Definitions',
          subtitle: 'Bitrate thresholds and file size limits',
          icon: Icons.high_quality_outlined,
          builder: (context, instance) => QualitySection(instance: instance),
        ),
        _SettingsItem(
          id: 'custom_formats',
          title: 'Custom Formats',
          subtitle: 'Release matching rules and scoring',
          icon: Icons.filter_list,
          builder: (context, instance) =>
              CustomFormatsSection(instance: instance),
        ),
      ],
    ),
    _SettingsGroup(
      title: 'Media & Organization',
      items: [
        _SettingsItem(
          id: 'media_management',
          title: 'Media Management',
          subtitle: 'Track naming, folder structures, and importing',
          icon: Icons.folder_copy_outlined,
          builder: (context, instance) =>
              MediaManagementSection(instance: instance),
        ),
        _SettingsItem(
          id: 'root_folders',
          title: 'Root Folders',
          subtitle: 'Library storage paths and disk space',
          icon: Icons.folder_open_outlined,
          builder: (context, instance) =>
              RootFoldersSection(instance: instance),
        ),
        _SettingsItem(
          id: 'tags',
          title: 'Tags',
          subtitle: 'Artist and release organization labels',
          icon: Icons.label_outline,
          builder: (context, instance) => TagsSection(instance: instance),
        ),
      ],
    ),
    _SettingsGroup(
      title: 'Indexers & Downloads',
      items: [
        _SettingsItem(
          id: 'indexers',
          title: 'Indexers',
          subtitle: 'Search feeds and restrictions',
          icon: Icons.travel_explore,
          builder: (context, instance) => IndexersSection(instance: instance),
        ),
        _SettingsItem(
          id: 'download_clients',
          title: 'Download Clients',
          subtitle: 'Torrent and Usenet client connections',
          icon: Icons.download_outlined,
          builder: (context, instance) =>
              DownloadClientsSection(instance: instance),
        ),
        _SettingsItem(
          id: 'import_lists',
          title: 'Import Lists',
          subtitle: 'Spotify, Last.fm, and automated sync',
          icon: Icons.playlist_add,
          builder: (context, instance) =>
              ImportListsSection(instance: instance),
        ),
      ],
    ),
    _SettingsGroup(
      title: 'Integrations & Host',
      items: [
        _SettingsItem(
          id: 'connect',
          title: 'Connect',
          subtitle: 'Discord, Telegram, Webhooks, and alerts',
          icon: Icons.notifications_active_outlined,
          builder: (context, instance) => ConnectSection(instance: instance),
        ),
        _SettingsItem(
          id: 'metadata',
          title: 'Metadata Consumers',
          subtitle: 'Kodi, Roon, and local music player metadata',
          icon: Icons.perm_media_outlined,
          builder: (context, instance) =>
              MetadataConsumersSection(instance: instance),
        ),
        _SettingsItem(
          id: 'general',
          title: 'General',
          subtitle: 'Host, port, SSL, authentication, and security',
          icon: Icons.settings_outlined,
          builder: (context, instance) =>
              GeneralSettingsSection(instance: instance),
        ),
      ],
    ),
  ];

  void _navigateToItem(BuildContext context, _SettingsItem item) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext ctx) => SettingsCategoryPage(
          title: item.title,
          body: item.builder(ctx, instance),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;

    return Scaffold(
      body: CustomScrollView(
        slivers: <Widget>[
          SliverAppBar(
            floating: true,
            snap: true,
            scrolledUnderElevation: 0.0,
            surfaceTintColor: Colors.transparent,
            backgroundColor: theme.colorScheme.surface,
            leading: IconButton(
              icon: const Icon(Icons.menu),
              tooltip: 'Open drawer',
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
            title: Text(
              'Settings',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (BuildContext context, int groupIndex) {
                  final _SettingsGroup group = _groups[groupIndex];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Padding(
                          padding: const EdgeInsets.only(
                            left: 4,
                            bottom: 8,
                            top: 4,
                          ),
                          child: Text(
                            group.title,
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: cs.primary,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                        ...group.items.map((_SettingsItem item) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Card(
                              elevation: 0,
                              margin: EdgeInsets.zero,
                              color: cs.surfaceContainerLow,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: BorderSide(
                                  color: cs.outlineVariant.withValues(
                                    alpha: 0.3,
                                  ),
                                ),
                              ),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(16),
                                onTap: () => _navigateToItem(context, item),
                                child: SizedBox(
                                  height: 72,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                    ),
                                    child: Row(
                                      children: <Widget>[
                                        Container(
                                          width: 44,
                                          height: 44,
                                          decoration: BoxDecoration(
                                            color: cs.primaryContainer,
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: Icon(
                                            item.icon,
                                            color: cs.onPrimaryContainer,
                                            size: 22,
                                          ),
                                        ),
                                        const SizedBox(width: 14),
                                        Expanded(
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: <Widget>[
                                              Text(
                                                item.title,
                                                style: theme
                                                    .textTheme.titleMedium
                                                    ?.copyWith(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 15,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                item.subtitle,
                                                style: theme.textTheme.bodySmall
                                                    ?.copyWith(
                                                  color: cs.onSurfaceVariant,
                                                  fontSize: 12,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Icon(
                                          Icons.chevron_right,
                                          size: 20,
                                          color: cs.onSurfaceVariant
                                              .withValues(alpha: 0.8),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  );
                },
                childCount: _groups.length,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
