import 'package:freezed_annotation/freezed_annotation.dart';

part 'beszel_system.freezed.dart';
part 'beszel_system.g.dart';

@freezed
abstract class BeszelSystem with _$BeszelSystem {
  const factory BeszelSystem({
    @Default('') String id,
    @Default('') String name,
    @Default('') String host,
    @Default('') String status,
    @Default({}) Map<String, dynamic> info,
  }) = _BeszelSystem;

  factory BeszelSystem.fromJson(Map<String, dynamic> json) =>
      _$BeszelSystemFromJson(json);
}
