import '../generated/models/library_rollup.dart';
import '../models/tracearr_models.dart';

/// Pure transformation from raw [LibraryRollup] DTO to domain [TracearrLibrary].
class TracearrLibraryMapper {
  const TracearrLibraryMapper._();

  static TracearrLibrary? fromDto(LibraryRollup item) {
    final sId = item.serverId ?? '';
    final lId = item.libraryId ?? '';
    if (sId.isEmpty || lId.isEmpty) return null;

    final resMap = <String, int>{};
    final Map<String, dynamic>? resData =
        item.resolutions as Map<String, dynamic>?;
    if (resData != null) {
      resData.forEach((String key, dynamic val) {
        if (val is int) {
          resMap[key] = val;
        } else if (val is num) {
          resMap[key] = val.toInt();
        }
      });
    }

    return TracearrLibrary(
      serverId: sId,
      serverType: item.serverType ?? '',
      libraryId: lId,
      itemCount: item.itemCount ?? 0,
      movieCount: item.movieCount ?? 0,
      showCount: item.showCount ?? 0,
      episodeCount: item.episodeCount ?? 0,
      trackCount: item.trackCount ?? 0,
      totalFileSize: item.totalFileSize ?? 0,
      resolutions: resMap,
    );
  }

  static List<TracearrLibrary> fromDtoList(List<LibraryRollup>? list) {
    if (list == null || list.isEmpty) return const [];
    final result = <TracearrLibrary>[];
    for (final item in list) {
      final mapped = fromDto(item);
      if (mapped != null) {
        result.add(mapped);
      }
    }
    return result;
  }
}
