import 'package:modbus_explorer/modules/modbus/connection/domain/connection_config.dart';
import 'package:modbus_explorer/modules/modbus/protocol/data/channel/byte_channel.dart';
import 'package:modbus_explorer/modules/modbus/protocol/data/client/modbus_client.dart';
import 'package:modbus_explorer/modules/modbus/protocol/data/codec/framing.dart';
import 'package:modbus_explorer/modules/modbus/simulator/data/simulator_bank.dart';
import 'package:modbus_explorer/modules/modbus/simulator/data/simulator_endpoint.dart';

/// Client wired to an in-process simulator, for transport tests.
final class SimulatedSetup {
  new(
    ModbusFraming framing, {
    SimulatorBank? bank,
    RequestOptions options = const RequestOptions(
      timeout: Duration(milliseconds: 150),
      retries: 0,
    ),
  }) : bank = bank ?? SimulatorBank.demo() {
    final (clientSide, serverSide) = InMemoryChannel.pair();
    this.serverSide = serverSide;
    endpoint = SimulatorEndpoint(
      channel: serverSide,
      framing: framing,
      bank: this.bank,
      faults: faults,
    );
    client = ModbusClient(
      channel: clientSide,
      framing: framing,
      defaults: options,
    );
  }

  final SimulatorBank bank;
  final faults = SimulatorFaults();
  late final InMemoryChannel serverSide;
  late final SimulatorEndpoint endpoint;
  late final ModbusClient client;

  Future<void> dispose() => client.close();
}
