import 'package:cached_network_image/cached_network_image.dart';
import 'package:core_models/core_models.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';
import '../../models/tracearr_models.dart';
import '../screens/tracearr_media_detail_screen.dart';

/// 2:3 aspect ratio poster tile for recently added media in grid view.
class RecentlyAddedPosterTile extends StatelessWidget {
  const RecentlyAddedPosterTile({
    required this.instance,
    required this.item,
    super.key,
  });

  final Instance instance;
  final TracearrRecentlyAddedItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final posterUrl = item.resolvedPosterUrl;

    return InkWell(
      borderRadius: BorderRadius.circular(Radii.md),
      onTap: () {
        final mediaRef = item.ratingKey ?? item.id;
        TracearrMediaDetailScreen.navigate(
          context,
          instance: instance,
          mediaRef: mediaRef,
          initialTitle: item.title,
          initialPosterUrl: posterUrl,
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Poster Artwork Container (2:3 Aspect Ratio)
          AspectRatio(
            aspectRatio: 2 / 3,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(Radii.md),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (posterUrl != null && posterUrl.isNotEmpty)
                    CachedNetworkImage(
                      imageUrl: posterUrl,
                      fit: BoxFit.cover,
                      errorWidget: (context, url, error) => Container(
                        color: colorScheme.surfaceContainerHighest,
                        child: Center(
                          child: Icon(
                            item.mediaType == 'show'
                                ? Icons.tv
                                : Icons.movie_outlined,
                            color: colorScheme.onSurfaceVariant,
                            size: 32,
                          ),
                        ),
                      ),
                    )
                  else
                    Container(
                      color: colorScheme.surfaceContainerHighest,
                      child: Center(
                        child: Icon(
                          item.mediaType == 'show'
                              ? Icons.tv
                              : Icons.movie_outlined,
                          color: colorScheme.onSurfaceVariant,
                          size: 32,
                        ),
                      ),
                    ),
                  // Media Type & Year Badges
                  Positioned(
                    top: 6,
                    left: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.75),
                        borderRadius: BorderRadius.circular(Radii.sm),
                      ),
                      child: Text(
                        item.mediaType.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  if (item.year != null)
                    Positioned(
                      top: 6,
                      right: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.75),
                          borderRadius: BorderRadius.circular(Radii.sm),
                        ),
                        child: Text(
                          '${item.year}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: Insets.xs),

          // Title
          Text(
            item.title,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
