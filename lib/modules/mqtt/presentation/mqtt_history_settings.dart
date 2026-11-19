import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meta/meta.dart';
import 'package:modbus_explorer/core/storage/key_value_store.dart';
import 'package:modbus_explorer/modules/mqtt/domain/chart_field.dart';

@immutable
final class MqttHistorySettings {
  const new({this.perTopic = 100, this.budgetMb = 64});

  static const perTopicChoices = [10, 100, 1000, 10000];
  static const budgetChoices = [16, 64, 256];

  final int perTopic;
  final int budgetMb;

  int get budgetBytes => budgetMb << 20;
}

/// History size per topic and memory budget, persisted.
final class MqttHistorySettingsController
    extends Notifier<MqttHistorySettings> {
  static const _perTopicKey = 'mqtt.historyPerTopic';
  static const _budgetKey = 'mqtt.historyBudgetMb';

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
    );
  }

  Future<void> setPerTopic(int value) async {
    state = MqttHistorySettings(perTopic: value, budgetMb: state.budgetMb);
    await _store.setString(_perTopicKey, '$value');
  }

  Future<void> setBudgetMb(int value) async {
    state = MqttHistorySettings(perTopic: state.perTopic, budgetMb: value);
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
