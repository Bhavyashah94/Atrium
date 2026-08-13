import 'package:cached_network_image/cached_network_image.dart';
import 'package:core_models/core_models.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../media/screens/tracearr_media_detail_screen.dart';
import '../../models/tracearr_models.dart';
import '../../people/screens/tracearr_user_dossier_screen.dart';

/// Card rendering an individual watch history record with cross-entity navigation.
class HistoryItemCard extends StatelessWidget {
  const HistoryItemCard({
    required this.item,
    this.instance,
    super.key,
  });

  final TracearrHistoryItem item;
  final Instance? instance;

  String _formatRelativeTime(DateTime? dt) {
    if (dt == null) return '';
    final now = DateTime.now();
    final difference = now.difference(dt);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('MMM d').format(dt);
    }
  }

  String _formatDuration(int? ms) {
    if (ms == null || ms <= 0) return '';
    final minutes = (ms / 60000).round();
    if (minutes >= 60) {
      final hours = minutes ~/ 60;
      final remainingMins = minutes % 60;
      return '${hours}h ${remainingMins}m';
    }
    return '${minutes}m';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final String timeAgo =
        _formatRelativeTime(item.startedAt ?? item.stoppedAt);
    final String durationText = _formatDuration(item.durationMs);

    final bool isTranscode = item.isTranscode ?? false;
    final bool isHw = item.isHwTranscode ||
        (item.hwDecoding != null && item.hwDecoding!.isNotEmpty) ||
        (item.hwEncoding != null && item.hwEncoding!.isNotEmpty);

    final String qualityLabel = !isTranscode
        ? 'Direct Play'
        : isHw
            ? 'HW Transcode'
            : 'CPU Transcode';

    final Color qualityColor = !isTranscode
        ? const Color(0xFF4CAF50)
        : isHw
            ? const Color(0xFF2196F3)
            : const Color(0xFFFF9800);

    return Container(
      padding: const EdgeInsets.all(Insets.md),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(Radii.md),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Poster / Thumbnail
          GestureDetector(
            onTap: instance != null
                ? () => TracearrMediaDetailScreen.navigate(
                      context,
                      instance: instance!,
                      mediaRef: item.ratingKey ?? item.id,
                      initialTitle: item.mediaTitle,
                      initialPosterUrl: item.posterUrl,
                    )
                : null,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(Radii.sm),
              child: SizedBox(
                width: 42,
                height: 60,
                child: item.posterUrl != null && item.posterUrl!.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: item.posterUrl!,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => Container(
                          color: colorScheme.surfaceContainerHighest,
                          child: Icon(
                            Icons.movie_outlined,
                            color: colorScheme.onSurfaceVariant,
                            size: 20,
                          ),
                        ),
                        placeholder: (_, __) => Container(
                          color: colorScheme.surfaceContainerHighest,
                        ),
                      )
                    : Container(
                        color: colorScheme.surfaceContainerHighest,
                        child: Icon(
                          Icons.movie_outlined,
                          color: colorScheme.onSurfaceVariant,
                          size: 20,
                        ),
                      ),
              ),
            ),
          ),
          const SizedBox(width: Insets.md),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: instance != null
                            ? () => TracearrMediaDetailScreen.navigate(
                                  context,
                                  instance: instance!,
                                  mediaRef: item.ratingKey ?? item.id,
                                  initialTitle: item.mediaTitle,
                                  initialPosterUrl: item.posterUrl,
                                )
                            : null,
                        child: Text(
                          item.mediaTitle,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    if (timeAgo.isNotEmpty)
                      Text(
                        timeAgo,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
                if (item.showTitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    '${item.showTitle} • S${item.seasonNumber}:E${item.episodeNumber}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ] else if (item.year != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    '${item.year}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
                const SizedBox(height: 4),
                Row(
                  children: [
                    GestureDetector(
                      onTap: instance != null
                          ? () => TracearrUserDossierScreen.navigate(
                                context,
                                instance: instance!,
                                userId: item.userId ?? item.userUsername,
                                username: item.userUsername,
                              )
                          : null,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircleAvatar(
                            radius: 8,
                            backgroundColor: colorScheme.primaryContainer,
                            child: Text(
                              item.userUsername.isNotEmpty
                                  ? item.userUsername[0].toUpperCase()
                                  : 'U',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onPrimaryContainer,
                              ),
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            '@${item.userUsername}',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    if (item.device != null) ...[
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          '• ${item.device}',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            fontSize: 10,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                    const Spacer(),
                    if (durationText.isNotEmpty)
                      Text(
                        durationText,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: qualityColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(Radii.sm),
                      ),
                      child: Text(
                        qualityLabel,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: qualityColor,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (item.resolution != null) ...[
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(Radii.sm),
                        ),
                        child: Text(
                          item.resolution!,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            fontSize: 9,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                    const Spacer(),
                    if (item.watched)
                      const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.check_circle,
                            size: 14,
                            color: Color(0xFF4CAF50),
                          ),
                          SizedBox(width: 3),
                          Text(
                            'Completed',
                            style: TextStyle(
                              color: Color(0xFF4CAF50),
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      )
                    else if (item.percentComplete != null &&
                        item.percentComplete! > 0)
                      Text(
                        '${item.percentComplete!.round()}% watched',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontSize: 9,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
