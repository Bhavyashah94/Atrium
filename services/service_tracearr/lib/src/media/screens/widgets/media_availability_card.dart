import 'package:core_models/core_models.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../models/tracearr_models.dart';

/// Card rendering multi-server presence and direct media server deep links.
class MediaAvailabilityCard extends StatelessWidget {
  const MediaAvailabilityCard({
    required this.instance,
    required this.availability,
    super.key,
  });

  final Instance instance;
  final List<TracearrMediaAvailability> availability;

  String _formatBytes(int? bytes) {
    if (bytes == null || bytes <= 0) return '';
    final double gigabytes = bytes / (1024 * 1024 * 1024);
    if (gigabytes >= 1000) {
      final double terabytes = gigabytes / 1024;
      return '${terabytes.toStringAsFixed(1)} TB';
    }
    return '${gigabytes.toStringAsFixed(1)} GB';
  }

  Future<void> _handleDeepLink(
      BuildContext context, TracearrMediaAvailability item) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final String? link = item.ratingKey != null && item.ratingKey!.isNotEmpty
        ? 'https://app.plex.tv/desktop'
        : null;

    if (link != null) {
      final uri = Uri.tryParse(link);
      if (uri != null && await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return;
      }
    }

    scaffoldMessenger.showSnackBar(
      SnackBar(
        content: Text(
            'Server ${item.serverType.toUpperCase()} item available on server ${item.serverId}'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (availability.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(Insets.md),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(Radii.md),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.dns_outlined, size: 16, color: colorScheme.primary),
              const SizedBox(width: Insets.xs),
              Text(
                'CROSS-SERVER AVAILABILITY (${availability.length})',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colorScheme.primary,
                  letterSpacing: 1.1,
                ),
              ),
            ],
          ),
          const SizedBox(height: Insets.md),
          ...availability.map((item) {
            final String sizeText = _formatBytes(item.fileSize);

            return Padding(
              padding: const EdgeInsets.only(bottom: Insets.sm),
              child: Container(
                padding: const EdgeInsets.all(Insets.sm),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest
                      .withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(Radii.sm),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(Radii.sm),
                      ),
                      child: Text(
                        item.serverType.toUpperCase(),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ),
                    const SizedBox(width: Insets.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.videoResolution ?? 'Standard Quality',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (sizeText.isNotEmpty)
                            Text(
                              sizeText,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.open_in_new, size: 18),
                      tooltip: 'View in Media Server',
                      onPressed: () => _handleDeepLink(context, item),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
