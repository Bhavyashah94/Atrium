import 'package:core_models/core_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'dashdot_providers.dart';

const int _maxHistoryPoints = 60;

class MetricHistory {
  final List<double> values;
  final List<double> temps;
  MetricHistory(this.values, {this.temps = const []});
}

class NetworkHistory {
  final List<double> down;
  final List<double> up;
  NetworkHistory(this.down, this.up);
}

class CpuHistoryState {
  final MetricHistory overall;
  final List<MetricHistory> cores;
  CpuHistoryState(this.overall, this.cores);
}

class CpuHistoryNotifier extends Notifier<CpuHistoryState> {
  CpuHistoryNotifier(this.instance);
  final Instance instance;

  @override
  CpuHistoryState build() {
    ref.listen(dashdotCpuLoadProvider(instance), (previous, next) {
      if (next.hasValue && next.value != null && next.value is List) {
        final List<dynamic> cores = next.value as List<dynamic>;
        if (cores.isNotEmpty) {
          double totalLoad = 0;
          List<double> coreLoads = [];
          List<double> coreTemps = [];
          for (var core in cores) {
            final load = (core['load'] as num?)?.toDouble() ?? 0.0;
            final temp = (core['temp'] as num?)?.toDouble() ?? 0.0;
            totalLoad += load;
            coreLoads.add(load);
            coreTemps.add(temp);
          }
          final double avgLoad = totalLoad / cores.length;
          
          final List<double> newOverall = List.from(state.overall.values)..add(avgLoad);
          if (newOverall.length > _maxHistoryPoints) newOverall.removeAt(0);

          final List<MetricHistory> newCores = [];
          for (int i = 0; i < coreLoads.length; i++) {
            final List<double> prevCoreValues = state.cores.length > i ? state.cores[i].values : [];
            final List<double> prevCoreTemps = state.cores.length > i ? state.cores[i].temps : [];
            final List<double> newCore = List.from(prevCoreValues)..add(coreLoads[i]);
            final List<double> newTemps = List.from(prevCoreTemps)..add(coreTemps[i]);
            if (newCore.length > _maxHistoryPoints) newCore.removeAt(0);
            if (newTemps.length > _maxHistoryPoints) newTemps.removeAt(0);
            newCores.add(MetricHistory(newCore, temps: newTemps));
          }
          
          state = CpuHistoryState(MetricHistory(newOverall), newCores);
        }
      }
    });
    return CpuHistoryState(MetricHistory([]), []);
  }
}

final dashdotCpuHistoryProvider = NotifierProvider.family<CpuHistoryNotifier, CpuHistoryState, Instance>(
  CpuHistoryNotifier.new,
);

class RamHistoryNotifier extends Notifier<MetricHistory> {
  RamHistoryNotifier(this.instance);
  final Instance instance;

  @override
  MetricHistory build() {
    ref.listen(dashdotRamLoadProvider(instance), (previous, next) {
      if (next.hasValue && next.value != null && next.value is Map) {
        final num loadGb = (next.value as Map)['load'] as num? ?? 0;
        
        final List<double> newValues = List.from(state.values)..add(loadGb.toDouble());
        if (newValues.length > _maxHistoryPoints) {
          newValues.removeAt(0);
        }
        state = MetricHistory(newValues);
      }
    });
    return MetricHistory([]);
  }
}

final dashdotRamHistoryProvider = NotifierProvider.family<RamHistoryNotifier, MetricHistory, Instance>(
  RamHistoryNotifier.new,
);

class StorageHistoryNotifier extends Notifier<MetricHistory> {
  StorageHistoryNotifier(this.instance);
  final Instance instance;

  @override
  MetricHistory build() {
    ref.listen(dashdotStorageLoadProvider(instance), (previous, next) {
      if (next.hasValue && next.value != null && next.value is List) {
        final List<dynamic> disks = next.value as List<dynamic>;
        double totalUsed = 0;
        for (var used in disks) {
          if (used is num && used > 0) {
            totalUsed += used.toDouble();
          }
        }
        
        final List<double> newValues = List.from(state.values)..add(totalUsed);
        if (newValues.length > _maxHistoryPoints) {
          newValues.removeAt(0);
        }
        state = MetricHistory(newValues);
      }
    });
    return MetricHistory([]);
  }
}

final dashdotStorageHistoryProvider = NotifierProvider.family<StorageHistoryNotifier, MetricHistory, Instance>(
  StorageHistoryNotifier.new,
);

class NetworkHistoryNotifier extends Notifier<NetworkHistory> {
  NetworkHistoryNotifier(this.instance);
  final Instance instance;

  @override
  NetworkHistory build() {
    ref.listen(dashdotNetworkLoadProvider(instance), (previous, next) {
      if (next.hasValue && next.value != null && next.value is Map) {
        final map = next.value as Map;
        final num down = map['down'] as num? ?? 0;
        final num up = map['up'] as num? ?? 0;
        
        final List<double> newDown = List.from(state.down)..add(down.toDouble());
        final List<double> newUp = List.from(state.up)..add(up.toDouble());
        
        if (newDown.length > _maxHistoryPoints) newDown.removeAt(0);
        if (newUp.length > _maxHistoryPoints) newUp.removeAt(0);
        
        state = NetworkHistory(newDown, newUp);
      }
    });
    return NetworkHistory([], []);
  }
}

final dashdotNetworkHistoryProvider = NotifierProvider.family<NetworkHistoryNotifier, NetworkHistory, Instance>(
  NetworkHistoryNotifier.new,
);

class GpuHistoryState {
  final MetricHistory history;
  final List<dynamic> layout;
  GpuHistoryState(this.history, this.layout);
}

class GpuHistoryNotifier extends Notifier<GpuHistoryState> {
  GpuHistoryNotifier(this.instance);
  final Instance instance;

  @override
  GpuHistoryState build() {
    ref.listen(dashdotGpuLoadProvider(instance), (previous, next) {
      if (next.hasValue && next.value != null && next.value is Map) {
        final map = next.value as Map;
        final List<dynamic> layout = map['layout'] as List<dynamic>? ?? [];
        if (layout.isNotEmpty) {
          double totalLoad = 0;
          for (var gpu in layout) {
            totalLoad += (gpu['load'] as num?)?.toDouble() ?? 0.0;
          }
          final avgLoad = totalLoad / layout.length;
          
          final List<double> newValues = List.from(state.history.values)..add(avgLoad);
          if (newValues.length > _maxHistoryPoints) {
            newValues.removeAt(0);
          }
          state = GpuHistoryState(MetricHistory(newValues), layout);
        }
      }
    });
    return GpuHistoryState(MetricHistory([]), []);
  }
}

final dashdotGpuHistoryProvider = NotifierProvider.family<GpuHistoryNotifier, GpuHistoryState, Instance>(
  GpuHistoryNotifier.new,
);
