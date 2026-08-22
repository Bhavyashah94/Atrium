import 'package:freezed_annotation/freezed_annotation.dart';

part 'beszel_stats.freezed.dart';
part 'beszel_stats.g.dart';

@freezed
abstract class BeszelStats with _$BeszelStats {
  const factory BeszelStats({
    @Default(0) double cpuUsage,
    @Default(0) double memoryUsage,
    @Default(-1.0) double gpuUsage,
    @Default(0) double diskUsage,
    @Default(0) double diskReadIo,
    @Default(0) double diskWriteIo,
    @Default(0) double networkSent,
    @Default(0) double networkRecv,
    @Default(0) double swapUsage,
    @Default(0) double loadAverage1m,
    @Default(0) double temperature,
    @Default(0) double dockerCpu,
    @Default(0) double dockerMemory,
    @Default(0) double dockerNetSent,
    @Default(0) double dockerNetRecv,
    DateTime? created,
  }) = _BeszelStats;

  factory BeszelStats.fromJson(Map<String, dynamic> json) =>
      _$BeszelStatsFromJson(json);
}

enum ChartTime { hour1, hour12, hour24, week1, month1 }
