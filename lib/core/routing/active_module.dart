import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meta/meta.dart';
import 'package:modbus_explorer/core/routing/app_destination.dart';
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
  @override
  ModuleNavigation build() => const ModuleNavigation(
    module: ProtocolModule.modbus,
    lastDestination: {},
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
    state = ModuleNavigation(
      module: module,
      lastDestination: {...state.lastDestination, module: destination},
    );
  }

  void select(ProtocolModule module) {
    if (state.module == module) return;
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
