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
  final List<dynamic>? gpu;
}

@JsonSerializable(createToJson: false)
class DashdotCpuInfo {
  const DashdotCpuInfo({
    this.cpuBrand,
    this.cores,
    this.threads,
    this.freq,
  });

  factory DashdotCpuInfo.fromJson(Map<String, dynamic> json) =>
      _$DashdotCpuInfoFromJson(json);

  @JsonKey(name: 'cpu_brand')
  final String? cpuBrand;
  final int? cores;
  final int? threads;
  final dynamic freq;
}

@JsonSerializable(createToJson: false)
class DashdotRamInfo {
  const DashdotRamInfo({
    this.totalCapacity,
    this.sticks,
  });

  factory DashdotRamInfo.fromJson(Map<String, dynamic> json) =>
      _$DashdotRamInfoFromJson(json);

  @JsonKey(name: 'total_capacity')
  final dynamic totalCapacity;
  final List<DashdotRamStick>? sticks;
}

@JsonSerializable(createToJson: false)
class DashdotRamStick {
  const DashdotRamStick({
    this.ramBrand,
    this.type,
    this.frequency,
  });

  factory DashdotRamStick.fromJson(Map<String, dynamic> json) =>
      _$DashdotRamStickFromJson(json);

  @JsonKey(name: 'ram_brand')
  final String? ramBrand;
  final String? type;
  final int? frequency;
}

@JsonSerializable(createToJson: false)
class DashdotStorageInfo {
  const DashdotStorageInfo({
    this.storageBrand,
    this.device,
    this.type,
    this.capacity,
  });

  factory DashdotStorageInfo.fromJson(Map<String, dynamic> json) =>
      _$DashdotStorageInfoFromJson(json);

  @JsonKey(name: 'storage_brand')
  final String? storageBrand;
  final String? device;
  final String? type;
  final dynamic capacity;
}

@JsonSerializable(createToJson: false)
class DashdotNetworkInfo {
  const DashdotNetworkInfo({
    this.type,
    this.downMBps,
    this.upMBps,
    this.interfaceSpeed,
  });

  factory DashdotNetworkInfo.fromJson(Map<String, dynamic> json) =>
      _$DashdotNetworkInfoFromJson(json);

  final String? type;
  @JsonKey(name: 'down_MBps')
  final dynamic downMBps;
  @JsonKey(name: 'up_MBps')
  final dynamic upMBps;
  @JsonKey(name: 'interface_speed')
  final dynamic interfaceSpeed;
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
