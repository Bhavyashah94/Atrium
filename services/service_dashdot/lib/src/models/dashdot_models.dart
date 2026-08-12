import 'package:json_annotation/json_annotation.dart';

part 'dashdot_models.g.dart';

@JsonSerializable(createToJson: false)
class DashdotInfo {
  const DashdotInfo({
    this.os,
    this.network,
  });

  factory DashdotInfo.fromJson(Map<String, dynamic> json) =>
      _$DashdotInfoFromJson(json);

  final DashdotOsInfo? os;
  final DashdotNetworkInfo? network;
}

@JsonSerializable(createToJson: false)
class DashdotOsInfo {
  const DashdotOsInfo({
    this.name,
    this.uptime,
  });

  factory DashdotOsInfo.fromJson(Map<String, dynamic> json) =>
      _$DashdotOsInfoFromJson(json);

  final String? name;
  final int? uptime;
}

@JsonSerializable(createToJson: false)
class DashdotNetworkInfo {
  const DashdotNetworkInfo({
    this.speedDown,
    this.speedUp,
  });

  factory DashdotNetworkInfo.fromJson(Map<String, dynamic> json) =>
      _$DashdotNetworkInfoFromJson(json);

  final int? speedDown;
  final int? speedUp;
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
