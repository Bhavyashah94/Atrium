import 'package:freezed_annotation/freezed_annotation.dart';

part 'beszel_container.freezed.dart';
part 'beszel_container.g.dart';

@freezed
abstract class BeszelContainer with _$BeszelContainer {
  const factory BeszelContainer({
    @Default('') String id,
    @Default('') String name,
    @Default('') String system,
    String? status,
    double? health,
    double? cpu,
    double? memory,
    double? net,
    String? image,
    String? ports,
  }) = _BeszelContainer;

  factory BeszelContainer.fromJson(Map<String, dynamic> json) =>
      _$BeszelContainerFromJson(json);
}
