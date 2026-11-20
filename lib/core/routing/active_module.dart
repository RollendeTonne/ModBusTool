import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meta/meta.dart';
import 'package:modbus_explorer/core/routing/app_destination.dart';
import 'package:modbus_explorer/core/storage/key_value_store.dart';
import 'package:modbus_explorer/shared/profiles/protocol_module.dart';

@immutable
final class ModuleNavigation {
  const new({required this.module, required this.lastDestination});

  final ProtocolModule module;

  /// Where each module was left, so switching back returns there.
  final Map<ProtocolModule, AppDestination> lastDestination;

  AppDestination destinationFor(ProtocolModule module) =>
      lastDestination[module] ?? AppDestination.visibleFor(module).first;
}

/// The active module. Settings belong to no module, so the module cannot
/// be derived from the current route alone.
final class ActiveModuleController extends Notifier<ModuleNavigation> {
  /// Last active module, so the app starts where it was left.
  static const storageKey = 'app.module';

  /// The module stored by a previous session (Modbus if none).
  static ProtocolModule stored(KeyValueStore store) {
    final name = store.getString(storageKey);
    return ProtocolModule.values.firstWhere(
      (m) => m.name == name,
      orElse: () => ProtocolModule.modbus,
    );
  }

  @override
  ModuleNavigation build() => ModuleNavigation(
    module: stored(ref.read(keyValueStoreProvider)),
    lastDestination: const {},
  );

  void _persist(ProtocolModule module) => unawaited(
    ref.read(keyValueStoreProvider).setString(storageKey, module.name),
  );

  /// Records a visited destination; module destinations also activate
  /// their module.
  void visited(AppDestination destination) {
    final module = destination.module;
    if (module == null) return;
    if (state.module == module &&
        state.lastDestination[module] == destination) {
      return;
    }
    if (state.module != module) _persist(module);
    state = ModuleNavigation(
      module: module,
      lastDestination: {...state.lastDestination, module: destination},
    );
  }

  void select(ProtocolModule module) {
    if (state.module == module) return;
    _persist(module);
    state = ModuleNavigation(
      module: module,
      lastDestination: state.lastDestination,
    );
  }
}

final activeModuleProvider =
    NotifierProvider<ActiveModuleController, ModuleNavigation>(
      ActiveModuleController.new,
    );
