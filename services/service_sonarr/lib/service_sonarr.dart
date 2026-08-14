/// Public surface of `service_sonarr`.
library;

import 'package:core_models/core_models.dart';
import 'package:flutter_riverpod/legacy.dart';

export 'src/generated/generated.dart';
export 'src/models/sonarr_episode.dart';
export 'src/models/sonarr_history_item.dart';
export 'src/models/sonarr_queue_item.dart';
export 'src/models/sonarr_series.dart';
export 'src/series_detail_screen.dart';
export 'src/services/sonarr_client.dart';
export 'src/services/sonarr_command_service.dart';
export 'src/services/sonarr_episode_service.dart';
export 'src/services/sonarr_queue_service.dart';
export 'src/services/sonarr_series_service.dart';
export 'src/sonarr_add_series_search_screen.dart';
export 'src/sonarr_add_series_sheet.dart';
export 'src/sonarr_api.dart';
export 'src/sonarr_home.dart';
export 'src/sonarr_providers.dart';
export 'src/sonarr_release_search_screen.dart';

final sonarrActiveTabBarIndexProvider =
    StateProvider.family<int, Instance>((ref, instance) => 0);
