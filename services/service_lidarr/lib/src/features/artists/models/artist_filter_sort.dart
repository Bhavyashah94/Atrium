/// Active layout view mode for the artists tab (grid or list).
enum LidarrViewMode { grid, list }

/// Sort options for the artists library.
enum LidarrArtistSort {
  name,
  sizeOnDisk,
  dateAdded,
  albumCount,
  progress,
  rating,
}

/// Filter options for the artists library.
enum LidarrArtistFilter {
  all,
  monitored,
  unmonitored,
  completed,
  missingTracks,
  continuing,
  ended,
}
