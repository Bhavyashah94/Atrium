import 'package:core_models/core_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../generated/generated.dart';
import '../../../lidarr_api.dart';
import '../../../state/api_providers.dart';

/// System status / runtime information for an instance.
final lidarrSystemStatusProvider =
    FutureProvider.autoDispose.family<SystemResource, Instance>(
  (Ref ref, Instance instance) async {
    final LidarrApi api = await ref.watch(lidarrApiProvider(instance).future);
    final ApiResponse<SystemResource> resp = await api.system.getSystemStatus();
    return unwrapLidarrApiResponse(resp, 'Failed to load system status');
  },
);

/// Health checks and issues for an instance.
final lidarrHealthProvider =
    FutureProvider.autoDispose.family<List<HealthResource>, Instance>((
  Ref ref,
  Instance instance,
) async {
  final LidarrApi api = await ref.watch(lidarrApiProvider(instance).future);
  final ApiResponse<List<HealthResource>> resp = await api.health.getHealth();
  return unwrapLidarrApiResponse(resp, 'Failed to load health checks');
});

/// Disk space / mounts information for an instance.
final lidarrDiskSpaceProvider =
    FutureProvider.autoDispose.family<List<DiskSpaceResource>, Instance>(
  (Ref ref, Instance instance) async {
    final LidarrApi api = await ref.watch(lidarrApiProvider(instance).future);
    final ApiResponse<List<DiskSpaceResource>> resp =
        await api.diskSpace.getDiskspace();
    return unwrapLidarrApiResponse(resp, 'Failed to load disk space');
  },
);

/// Scheduled tasks configured in Lidarr.
final lidarrSystemTasksProvider =
    FutureProvider.autoDispose.family<List<TaskResource>, Instance>(
  (Ref ref, Instance instance) async {
    final LidarrApi api = await ref.watch(lidarrApiProvider(instance).future);
    final ApiResponse<List<TaskResource>> resp = await api.task.getSystemTask();
    return unwrapLidarrApiResponse(resp, 'Failed to load system tasks');
  },
);

/// System database backups for an instance.
final lidarrSystemBackupsProvider =
    FutureProvider.autoDispose.family<List<BackupResource>, Instance>(
  (Ref ref, Instance instance) async {
    final LidarrApi api = await ref.watch(lidarrApiProvider(instance).future);
    final ApiResponse<List<BackupResource>> resp =
        await api.backup.getSystemBackup();
    return unwrapLidarrApiResponse(resp, 'Failed to load backups');
  },
);

/// Paginated logs provider. Key is (Instance, {int page, int pageSize, String? level}).
final lidarrLogsProvider = FutureProvider.autoDispose.family<
    LogResourcePagingResource,
    (Instance, {int page, int pageSize, String? level})>(
  (Ref ref, (Instance, {int page, int pageSize, String? level}) key) async {
    final (
      Instance instance,
      page: int page,
      pageSize: int pageSize,
      level: String? level
    ) = key;
    final LidarrApi api = await ref.watch(lidarrApiProvider(instance).future);
    final ApiResponse<LogResourcePagingResource> resp = await api.log.getLog(
      page: page,
      pageSize: pageSize,
      sortKey: 'time',
      sortDirection: SortDirection.descending,
      level: level,
    );
    return unwrapLidarrApiResponse(resp, 'Failed to load logs');
  },
);

/// Log files list provider.
final lidarrLogFilesProvider =
    FutureProvider.autoDispose.family<List<LogFileResource>, Instance>(
  (Ref ref, Instance instance) async {
    final LidarrApi api = await ref.watch(lidarrApiProvider(instance).future);
    final ApiResponse<List<LogFileResource>> resp =
        await api.logFile.getLogFile();
    return unwrapLidarrApiResponse(resp, 'Failed to load log files');
  },
);

/// System updates and changelog provider.
final lidarrUpdatesProvider =
    FutureProvider.autoDispose.family<List<UpdateResource>, Instance>((
  Ref ref,
  Instance instance,
) async {
  final LidarrApi api = await ref.watch(lidarrApiProvider(instance).future);
  final ApiResponse<List<UpdateResource>> resp = await api.update.getUpdate();
  return unwrapLidarrApiResponse(resp, 'Failed to load updates');
});

/// Log file text content provider. Key is (Instance instance, {String filename, String? contentsUrl, String? downloadUrl}).
final lidarrLogFileContentProvider = FutureProvider.autoDispose.family<
    String,
    (
      Instance instance, {
      String filename,
      String? contentsUrl,
      String? downloadUrl
    })>(
  (
    Ref ref,
    (
      Instance instance, {
      String filename,
      String? contentsUrl,
      String? downloadUrl
    }) key,
  ) async {
    final (
      Instance instance,
      filename: String filename,
      contentsUrl: String? contentsUrl,
      downloadUrl: String? downloadUrl,
    ) = key;
    final LidarrApi api = await ref.watch(lidarrApiProvider(instance).future);
    final ApiResponse<String> resp = await api.getLogFileContent(
      filename,
      contentsUrl: contentsUrl,
      downloadUrl: downloadUrl,
    );
    return unwrapLidarrApiResponse(resp, 'Failed to load log file contents');
  },
);
