import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meta/meta.dart';
import 'package:modbus_explorer/core/storage/key_value_store.dart';
import 'package:modbus_explorer/modules/mqtt/domain/chart_field.dart';

@immutable
final class MqttHistorySettings {
  const new({this.perTopic = 100, this.budgetMb = 64, this.monitorSize = 5000});

  static const perTopicChoices = [10, 100, 1000, 10000];
  static const budgetChoices = [16, 64, 256];
  static const monitorChoices = [1000, 5000, 20000, 100000];

  final int perTopic;
  final int budgetMb;

  /// Entries kept in the monitor (ring buffer).
  final int monitorSize;

  MqttHistorySettings copyWith({
    int? perTopic,
    int? budgetMb,
    int? monitorSize,
  }) => MqttHistorySettings(
    perTopic: perTopic ?? this.perTopic,
    budgetMb: budgetMb ?? this.budgetMb,
    monitorSize: monitorSize ?? this.monitorSize,
  );

  int get budgetBytes => budgetMb << 20;
}

/// History size per topic and memory budget, persisted.
final class MqttHistorySettingsController
    extends Notifier<MqttHistorySettings> {
  static const _perTopicKey = 'mqtt.historyPerTopic';
  static const _budgetKey = 'mqtt.historyBudgetMb';
  static const _monitorKey = 'mqtt.monitorSize';

  KeyValueStore get _store => ref.read(keyValueStoreProvider);

  @override
  MqttHistorySettings build() {
    int read(String key, List<int> choices, int fallback) {
      final value = int.tryParse(_store.getString(key) ?? '');
      return value != null && choices.contains(value) ? value : fallback;
    }

    return MqttHistorySettings(
      perTopic: read(_perTopicKey, MqttHistorySettings.perTopicChoices, 100),
      budgetMb: read(_budgetKey, MqttHistorySettings.budgetChoices, 64),
      monitorSize: read(_monitorKey, MqttHistorySettings.monitorChoices, 5000),
    );
  }

  Future<void> setPerTopic(int value) async {
    state = state.copyWith(perTopic: value);
    await _store.setString(_perTopicKey, '$value');
  }

  Future<void> setMonitorSize(int value) async {
    state = state.copyWith(monitorSize: value);
    await _store.setString(_monitorKey, '$value');
  }

  Future<void> setBudgetMb(int value) async {
    state = state.copyWith(budgetMb: value);
    await _store.setString(_budgetKey, '$value');
  }
}

final mqttHistorySettingsProvider =
    NotifierProvider<MqttHistorySettingsController, MqttHistorySettings>(
      MqttHistorySettingsController.new,
    );

/// Chosen chart field per topic (session only).
final class ChartFieldsController extends Notifier<Map<String, ChartField>> {
  @override
  Map<String, ChartField> build() => const {};

  void set(String topic, ChartField? field) => state = {
    for (final e in state.entries)
      if (e.key != topic) e.key: e.value,
    topic: ?field,
  };
}

final chartFieldsProvider =
    NotifierProvider<ChartFieldsController, Map<String, ChartField>>(
      ChartFieldsController.new,
    );
