import 'package:freezed_annotation/freezed_annotation.dart';

part 'beszel_systemd_service.freezed.dart';
part 'beszel_systemd_service.g.dart';

@freezed
abstract class BeszelSystemdService with _$BeszelSystemdService {
  const factory BeszelSystemdService({
    @Default('') String id,
    @Default('') String name,
    @Default('') String system,
    @Default(0) int state,
    @Default(0) int sub,
    @Default(0.0) double cpu,
    @Default(0.0) double memory,
  }) = _BeszelSystemdService;

  factory BeszelSystemdService.fromJson(Map<String, dynamic> json) =>
      _$BeszelSystemdServiceFromJson(json);
}

extension BeszelSystemdServiceX on BeszelSystemdService {
  String get stateStr {
    switch (state) {
      case 0: return 'Active';
      case 1: return 'Inactive';
      case 2: return 'Failed';
      case 3: return 'Activating';
      case 4: return 'Deactivating';
      case 5: return 'Reloading';
      default: return 'Unknown';
    }
  }

  String get subStr {
    switch (sub) {
      case 0: return 'Dead';
      case 1: return 'Running';
      case 2: return 'Exited';
      case 3: return 'Failed';
      case 4: return 'Unknown';
      default: return 'Unknown';
    }
  }
}
