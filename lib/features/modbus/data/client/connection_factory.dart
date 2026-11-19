import 'package:modbus_explorer/features/connection/domain/connection_config.dart';
import 'package:modbus_explorer/features/modbus/data/channel/byte_channel.dart';
import 'package:modbus_explorer/features/modbus/data/channel/serial_port_service.dart';
import 'package:modbus_explorer/features/modbus/data/channel/socket_channel.dart';
import 'package:modbus_explorer/features/modbus/data/client/modbus_client.dart';
import 'package:modbus_explorer/features/modbus/data/codec/mbap_codec.dart';
import 'package:modbus_explorer/features/modbus/data/codec/rtu_codec.dart';
import 'package:modbus_explorer/features/simulator/data/simulator_bank.dart';
import 'package:modbus_explorer/features/simulator/data/simulator_endpoint.dart';

/// Opens a TCP byte channel; replaceable so widget tests never touch the
/// real network.
typedef TcpConnector = Future<ByteChannel> Function(
  String host,
  int port,
  Duration timeout,
);

Future<ByteChannel> _connectSocket(String host, int port, Duration timeout) =>
    SocketChannel.connect(host, port, timeout: timeout);

/// Opens a [ModbusClient] for any [ConnectionConfig].
final class ModbusConnectionFactory {
  new({
    required this._serialPorts,
    required this._simulatorBank,
    this._tcpConnect = _connectSocket,
  });

  final SerialPortService _serialPorts;
  final SimulatorBank Function() _simulatorBank;
  final TcpConnector _tcpConnect;

  /// Generous delay for RTU over TCP: gateways add their own buffering, so
  /// the exact t3.5 of the serial side is unknown here.
  static const rtuOverTcpInterFrameDelay = Duration(milliseconds: 5);

  Future<ModbusClient> open(ConnectionConfig config) async {
    switch (config) {
      case TcpConnectionConfig(:final host, :final port):
        final channel = await _tcpConnect(host, port, _connectTimeout(config));
        return ModbusClient(
          channel: channel,
          framing: const MbapFraming(),
          defaults: config.options,
        );
      case RtuOverTcpConnectionConfig(:final host, :final port):
        final channel = await _tcpConnect(host, port, _connectTimeout(config));
        return ModbusClient(
          channel: channel,
          framing: const RtuFraming(),
          defaults: config.options,
          interFrameDelay: rtuOverTcpInterFrameDelay,
        );
      case RtuConnectionConfig(:final serial):
        final channel = await _serialPorts.open(serial);
        return ModbusClient(
          channel: channel,
          framing: const RtuFraming(),
          defaults: config.options,
          interFrameDelay:
              serial.interFrameDelay ?? rtuInterFrameDelay(serial.baudRate),
        );
      case SimulatorConnectionConfig():
        final (clientSide, serverSide) = InMemoryChannel.pair(
          description: 'Simulator',
        );
        final framing = switch (config.framing) {
          SimulatorFraming.tcp => const MbapFraming(),
          SimulatorFraming.rtu => const RtuFraming(),
        };
        // Lives as long as the channel; closing the client closes both.
        SimulatorEndpoint(
          channel: serverSide,
          framing: framing,
          bank: _simulatorBank(),
          faults: SimulatorFaults(
            latency: config.latency,
            dropProbability: config.dropProbability,
            corruptProbability: config.corruptProbability,
          ),
        );
        return ModbusClient(
          channel: clientSide,
          framing: framing,
          defaults: config.options,
        );
    }
  }

  // Connecting may take longer than a request; never less than 3 s.
  static Duration _connectTimeout(ConnectionConfig config) {
    final requestTimeout = config.options.timeout * 3;
    const minimum = Duration(seconds: 3);
    return requestTimeout > minimum ? requestTimeout : minimum;
  }
}
