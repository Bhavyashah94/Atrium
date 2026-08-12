import 'package:json_annotation/json_annotation.dart';

part 'dashdot_models.g.dart';

@JsonSerializable(createToJson: false)
class DashdotInfo {
  const DashdotInfo({
    this.cpu,
    this.ram,
    this.storage,
    this.network,
    this.gpu,
  });

  factory DashdotInfo.fromJson(Map<String, dynamic> json) =>
      _$DashdotInfoFromJson(json);

  final DashdotCpuInfo? cpu;
  final DashdotRamInfo? ram;
  final List<DashdotStorageInfo>? storage;
  final DashdotNetworkInfo? network;
  final DashdotGpuInfo? gpu;
}

@JsonSerializable(createToJson: false)
class DashdotCpuInfo {
  const DashdotCpuInfo({
    this.brand,
    this.model,
    this.cores,
    this.threads,
    this.frequency,
  });

  factory DashdotCpuInfo.fromJson(Map<String, dynamic> json) =>
      _$DashdotCpuInfoFromJson(json);

  final String? brand;
  final String? model;
  final int? cores;
  final int? threads;
  final dynamic frequency; // could be double or int
}

@JsonSerializable(createToJson: false)
class DashdotRamInfo {
  const DashdotRamInfo({
    this.size,
    this.layout,
  });

  factory DashdotRamInfo.fromJson(Map<String, dynamic> json) =>
      _$DashdotRamInfoFromJson(json);

  final int? size;
  final List<DashdotRamLayout>? layout;
}

@JsonSerializable(createToJson: false)
class DashdotRamLayout {
  const DashdotRamLayout({
    this.brand,
    this.type,
    this.frequency,
  });

  factory DashdotRamLayout.fromJson(Map<String, dynamic> json) =>
      _$DashdotRamLayoutFromJson(json);

  final String? brand;
  final String? type;
  final int? frequency;
}

@JsonSerializable(createToJson: false)
class DashdotStorageInfo {
  const DashdotStorageInfo({
    this.size,
    this.disks,
  });

  factory DashdotStorageInfo.fromJson(Map<String, dynamic> json) =>
      _$DashdotStorageInfoFromJson(json);

  final int? size;
  final List<DashdotDiskInfo>? disks;
}

@JsonSerializable(createToJson: false)
class DashdotDiskInfo {
  const DashdotDiskInfo({
    this.brand,
    this.device,
    this.type,
  });

  factory DashdotDiskInfo.fromJson(Map<String, dynamic> json) =>
      _$DashdotDiskInfoFromJson(json);

  final String? brand;
  final String? device;
  final String? type;
}

@JsonSerializable(createToJson: false)
class DashdotNetworkInfo {
  const DashdotNetworkInfo({
    this.type,
    this.speedDown,
    this.speedUp,
  });

  factory DashdotNetworkInfo.fromJson(Map<String, dynamic> json) =>
      _$DashdotNetworkInfoFromJson(json);

  final String? type;
  final dynamic speedDown;
  final dynamic speedUp;
}

@JsonSerializable(createToJson: false)
class DashdotGpuInfo {
  const DashdotGpuInfo({
    this.layout,
  });

  factory DashdotGpuInfo.fromJson(Map<String, dynamic> json) =>
      _$DashdotGpuInfoFromJson(json);

  final List<dynamic>? layout;
}

@JsonSerializable(createToJson: false)
class DashdotConfig {
  const DashdotConfig({
    required this.widgetList,
  });

  factory DashdotConfig.fromJson(Map<String, dynamic> json) =>
      _$DashdotConfigFromJson(json);

  @JsonKey(name: 'widget_list')
  final List<String> widgetList;
}
