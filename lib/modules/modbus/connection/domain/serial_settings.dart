import 'package:meta/meta.dart';

enum SerialParity { none, even, odd }

/// Fixed level for a modem control line; most USB-RS485 adapters switch
/// direction automatically, some need RTS/DTR held at a level.
enum SerialLineMode { unchanged, off, on }

@immutable
final class SerialSettings {
  const new({
    required this.portName,
    this.baudRate = 19200,
    this.dataBits = 8,
    this.parity = SerialParity.even,
    this.stopBits = 1,
    this.rts = SerialLineMode.unchanged,
    this.dtr = SerialLineMode.unchanged,
    this.interFrameDelay,
  });

  static const commonBaudRates = [
    1200,
    2400,
    4800,
    9600,
    19200,
    38400,
    57600,
    115200,
  ];

  final String portName;
  final int baudRate;
  final int dataBits;
  final SerialParity parity;
  final int stopBits;
  final SerialLineMode rts;
  final SerialLineMode dtr;

  /// Minimum silence between frames; `null` = t3.5 derived from baud rate.
  final Duration? interFrameDelay;

  /// Compact notation like `19200 8E1`.
  String get shortDescription =>
      '$baudRate $dataBits${switch (parity) {
        SerialParity.none => 'N',
        SerialParity.even => 'E',
        SerialParity.odd => 'O',
      }}$stopBits';

  SerialSettings copyWith({
    String? portName,
    int? baudRate,
    int? dataBits,
    SerialParity? parity,
    int? stopBits,
    SerialLineMode? rts,
    SerialLineMode? dtr,
    Duration? interFrameDelay,
  }) => SerialSettings(
    portName: portName ?? this.portName,
    baudRate: baudRate ?? this.baudRate,
    dataBits: dataBits ?? this.dataBits,
    parity: parity ?? this.parity,
    stopBits: stopBits ?? this.stopBits,
    rts: rts ?? this.rts,
    dtr: dtr ?? this.dtr,
    interFrameDelay: interFrameDelay ?? this.interFrameDelay,
  );

  @override
  bool operator ==(Object other) =>
      other is SerialSettings &&
      other.portName == portName &&
      other.baudRate == baudRate &&
      other.dataBits == dataBits &&
      other.parity == parity &&
      other.stopBits == stopBits &&
      other.rts == rts &&
      other.dtr == dtr &&
      other.interFrameDelay == interFrameDelay;

  @override
  int get hashCode => Object.hash(
    portName,
    baudRate,
    dataBits,
    parity,
    stopBits,
    rts,
    dtr,
    interFrameDelay,
  );
}
