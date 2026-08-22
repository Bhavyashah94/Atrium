import 'package:collection/collection.dart';
import 'package:core_models/core_models.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../generated/generated.dart';
import '../../lidarr_api.dart';
import '../../lidarr_providers.dart';

/// Modal bottom sheet for editing an existing artist's configuration in Lidarr.
class LidarrEditArtistSheet extends ConsumerStatefulWidget {
  const LidarrEditArtistSheet({
    required this.instance,
    required this.artist,
    super.key,
  });

  final Instance instance;
  final ArtistResource artist;

  /// Convenience static helper to show this sheet.
  static Future<bool?> show(
    BuildContext context, {
    required Instance instance,
    required ArtistResource artist,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => LidarrEditArtistSheet(
        instance: instance,
        artist: artist,
      ),
    );
  }

  @override
  ConsumerState<LidarrEditArtistSheet> createState() =>
      _LidarrEditArtistSheetState();
}

class _LidarrEditArtistSheetState extends ConsumerState<LidarrEditArtistSheet> {
  late bool _monitored;
  late int? _selectedQualityProfileId;
  late int? _selectedMetadataProfileId;
  late NewItemMonitorTypes _selectedMonitorNewItems;
  late String? _selectedRootFolder;
  late List<int> _selectedTagIds;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _monitored = widget.artist.monitored ?? true;
    _selectedQualityProfileId = widget.artist.qualityProfileId;
    _selectedMetadataProfileId = widget.artist.metadataProfileId;
    _selectedMonitorNewItems =
        widget.artist.monitorNewItems ?? NewItemMonitorTypes.all;
    _selectedRootFolder = widget.artist.rootFolderPath;
    _selectedTagIds = List<int>.from(widget.artist.tags ?? <int>[]);
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;

    final AsyncValue<List<RootFolderResource>> rootFoldersAsync =
        ref.watch(lidarrRootFoldersProvider(widget.instance));
    final AsyncValue<List<QualityProfileResource>> qualityProfilesAsync =
        ref.watch(lidarrQualityProfilesProvider(widget.instance));
    final AsyncValue<List<MetadataProfileResource>> metadataProfilesAsync =
        ref.watch(lidarrMetadataProfilesProvider(widget.instance));
    final AsyncValue<List<TagResource>> tagsAsync =
        ref.watch(lidarrTagsProvider(widget.instance));

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (BuildContext context, ScrollController scrollController) {
        return Scaffold(
          backgroundColor: cs.surface,
          appBar: AppBar(
            backgroundColor: cs.surface,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            title: Text(
              'Edit ${widget.artist.artistName ?? 'Artist'}',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            centerTitle: true,
          ),
          body: Column(
            children: [
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(
                    horizontal: Insets.lg,
                    vertical: Insets.sm,
                  ),
                  children: [
                    // Profiles Card
                    Card(
                      elevation: 0,
                      color: cs.surfaceContainerLow,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: cs.outlineVariant.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(Insets.md),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Profiles & Paths',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: cs.primary,
                              ),
                            ),
                            const SizedBox(height: Insets.md),

                            // Quality Profile Dropdown
                            qualityProfilesAsync.when(
                              data: (List<QualityProfileResource> profiles) {
                                final int selectedVal =
                                    _selectedQualityProfileId != null &&
                                            profiles.any(
                                              (p) =>
                                                  p.id ==
                                                  _selectedQualityProfileId,
                                            )
                                        ? _selectedQualityProfileId!
                                        : profiles.firstOrNull?.id ?? 1;
                                return DropdownButtonFormField<int>(
                                  key: ValueKey<String>(
                                    'edit_qp_$_selectedQualityProfileId',
                                  ),
                                  initialValue: selectedVal,
                                  isExpanded: true,
                                  decoration: InputDecoration(
                                    labelText: 'Quality Profile',
                                    prefixIcon:
                                        const Icon(Icons.high_quality_outlined),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  items:
                                      profiles.map((QualityProfileResource p) {
                                    return DropdownMenuItem<int>(
                                      value: p.id,
                                      child: Text(p.name ?? 'Profile ${p.id}'),
                                    );
                                  }).toList(),
                                  onChanged: (int? val) {
                                    if (val != null) {
                                      setState(() {
                                        _selectedQualityProfileId = val;
                                      });
                                    }
                                  },
                                );
                              },
                              loading: () => const Center(
                                child: ExpressiveProgressIndicator(),
                              ),
                              error: (e, _) =>
                                  Text('Failed to load quality profiles: $e'),
                            ),
                            const SizedBox(height: Insets.md),

                            // Metadata Profile Dropdown
                            metadataProfilesAsync.when(
                              data: (List<MetadataProfileResource> profiles) {
                                final int selectedVal =
                                    _selectedMetadataProfileId != null &&
                                            profiles.any(
                                              (p) =>
                                                  p.id ==
                                                  _selectedMetadataProfileId,
                                            )
                                        ? _selectedMetadataProfileId!
                                        : profiles.firstOrNull?.id ?? 1;
                                return DropdownButtonFormField<int>(
                                  key: ValueKey<String>(
                                    'edit_meta_$_selectedMetadataProfileId',
                                  ),
                                  initialValue: selectedVal,
                                  isExpanded: true,
                                  decoration: InputDecoration(
                                    labelText: 'Metadata Profile',
                                    prefixIcon: const Icon(
                                      Icons.library_music_outlined,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  items:
                                      profiles.map((MetadataProfileResource p) {
                                    return DropdownMenuItem<int>(
                                      value: p.id,
                                      child: Text(p.name ?? 'Profile ${p.id}'),
                                    );
                                  }).toList(),
                                  onChanged: (int? val) {
                                    if (val != null) {
                                      setState(() {
                                        _selectedMetadataProfileId = val;
                                      });
                                    }
                                  },
                                );
                              },
                              loading: () => const Center(
                                child: ExpressiveProgressIndicator(),
                              ),
                              error: (e, _) =>
                                  Text('Failed to load metadata profiles: $e'),
                            ),
                            const SizedBox(height: Insets.md),

                            // Root Folder
                            rootFoldersAsync.when(
                              data: (List<RootFolderResource> folders) {
                                final String selectedVal =
                                    _selectedRootFolder != null &&
                                            folders.any(
                                              (f) =>
                                                  f.path == _selectedRootFolder,
                                            )
                                        ? _selectedRootFolder!
                                        : (folders.firstOrNull?.path ??
                                            widget.artist.path ??
                                            '');
                                return DropdownButtonFormField<String>(
                                  key: ValueKey<String>(
                                    'edit_folder_$_selectedRootFolder',
                                  ),
                                  initialValue: selectedVal,
                                  isExpanded: true,
                                  decoration: InputDecoration(
                                    labelText: 'Root Folder',
                                    prefixIcon:
                                        const Icon(Icons.folder_outlined),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  items: folders.map((RootFolderResource f) {
                                    return DropdownMenuItem<String>(
                                      value: f.path,
                                      child: Text(f.path ?? ''),
                                    );
                                  }).toList(),
                                  onChanged: (String? val) {
                                    if (val != null) {
                                      setState(() {
                                        _selectedRootFolder = val;
                                      });
                                    }
                                  },
                                );
                              },
                              loading: () => const Center(
                                child: ExpressiveProgressIndicator(),
                              ),
                              error: (e, _) =>
                                  Text('Failed to load root folders: $e'),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: Insets.md),

                    // Monitoring Options Card
                    Card(
                      elevation: 0,
                      color: cs.surfaceContainerLow,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: cs.outlineVariant.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(Insets.md),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Monitoring',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: cs.primary,
                              ),
                            ),
                            const SizedBox(height: Insets.md),

                            // Monitor New Items Dropdown
                            DropdownButtonFormField<NewItemMonitorTypes>(
                              initialValue: _selectedMonitorNewItems,
                              isExpanded: true,
                              decoration: InputDecoration(
                                labelText: 'Monitor New Releases',
                                prefixIcon:
                                    const Icon(Icons.new_releases_outlined),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: NewItemMonitorTypes.all,
                                  child: Text('All'),
                                ),
                                DropdownMenuItem(
                                  value: NewItemMonitorTypes.newVal,
                                  child: Text('New Only'),
                                ),
                                DropdownMenuItem(
                                  value: NewItemMonitorTypes.none,
                                  child: Text('None'),
                                ),
                              ],
                              onChanged: (NewItemMonitorTypes? val) {
                                if (val != null) {
                                  setState(() {
                                    _selectedMonitorNewItems = val;
                                  });
                                }
                              },
                            ),
                            const SizedBox(height: Insets.sm),

                            SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              title: const Text('Monitored'),
                              subtitle: const Text(
                                'Monitor this artist for new releases and upgrades',
                              ),
                              value: _monitored,
                              onChanged: (bool val) {
                                setState(() {
                                  _monitored = val;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: Insets.md),

                    // Tags Card
                    tagsAsync.maybeWhen(
                      data: (List<TagResource> tags) {
                        if (tags.isEmpty) return const SizedBox.shrink();
                        return Card(
                          elevation: 0,
                          color: cs.surfaceContainerLow,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(
                              color: cs.outlineVariant.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(Insets.md),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Tags',
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: cs.primary,
                                  ),
                                ),
                                const SizedBox(height: Insets.sm),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: tags.map((TagResource tag) {
                                    final int id = tag.id ?? 0;
                                    final String label = tag.label ?? 'Tag $id';
                                    final bool isSelected =
                                        _selectedTagIds.contains(id);
                                    return FilterChip(
                                      label: Text(label),
                                      selected: isSelected,
                                      onSelected: (bool selected) {
                                        setState(() {
                                          if (selected) {
                                            _selectedTagIds.add(id);
                                          } else {
                                            _selectedTagIds.remove(id);
                                          }
                                        });
                                      },
                                    );
                                  }).toList(),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                      orElse: () => const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),

              // Bottom Save Button
              Padding(
                padding: const EdgeInsets.all(Insets.md),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      shape: const StadiumBorder(),
                      backgroundColor: cs.primary,
                      foregroundColor: cs.onPrimary,
                    ),
                    onPressed: _submitting ? null : _save,
                    child: _submitting
                        ? ExpressiveProgressIndicator(color: cs.onPrimary)
                        : const Text(
                            'Save Changes',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _save() async {
    setState(() {
      _submitting = true;
    });

    try {
      final LidarrApi api =
          await ref.read(lidarrApiProvider(widget.instance).future);

      String? resolvedPath = widget.artist.path;
      if (_selectedRootFolder != null &&
          _selectedRootFolder!.isNotEmpty &&
          _selectedRootFolder != widget.artist.rootFolderPath) {
        final String cleanRoot = _selectedRootFolder!.endsWith('/') ||
                _selectedRootFolder!.endsWith('\\')
            ? _selectedRootFolder!.substring(0, _selectedRootFolder!.length - 1)
            : _selectedRootFolder!;

        final String artistFolder =
            (widget.artist.path != null && widget.artist.path!.isNotEmpty)
                ? widget.artist.path!
                    .split(RegExp(r'[/\\]'))
                    .where((s) => s.isNotEmpty)
                    .last
                : (widget.artist.artistName ?? 'Artist');

        resolvedPath = '$cleanRoot/$artistFolder';
      }

      final ArtistResource updatedPayload = widget.artist.copyWith(
        monitored: _monitored,
        qualityProfileId: _selectedQualityProfileId,
        metadataProfileId: _selectedMetadataProfileId,
        monitorNewItems: _selectedMonitorNewItems,
        rootFolderPath: _selectedRootFolder,
        path: resolvedPath,
        tags: _selectedTagIds,
      );

      final ApiResponse<ArtistResource> resp = await api.artist.putArtistById(
        id: '${widget.artist.id}',
        body: updatedPayload,
      );

      if (!resp.isSuccess) {
        throw Exception(resp.error?.message ?? 'Failed to update artist');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Updated "${widget.artist.artistName ?? 'Artist'}" successfully!',
            ),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );

        ref.invalidate(
          lidarrArtistByIdProvider((widget.instance, widget.artist.id ?? 0)),
        );
        ref.invalidate(lidarrArtistsProvider(widget.instance));

        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update artist: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _submitting = false;
        });
      }
    }
  }
}
