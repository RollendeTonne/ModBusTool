import 'dart:math' as math;
import 'dart:typed_data';

import 'package:modbus_explorer/features/modbus/domain/modbus_exception_code.dart';
import 'package:modbus_explorer/features/modbus/domain/modbus_response.dart';
import 'package:modbus_explorer/features/modbus/domain/register_table.dart';
import 'package:modbus_explorer/features/simulator/domain/simulated_device.dart';

/// Register layout of the demo device (unit 1). Documented in the README so
/// users know which interpretation to expect where.
abstract final class DemoMap {
  static const float10Abcd = 0; // FLOAT32 10.0 ABCD
  static const float10Cdab = 2; // FLOAT32 10.0 CDAB
  static const float10Badc = 4; // FLOAT32 10.0 BADC
  static const float10Dcba = 6; // FLOAT32 10.0 DCBA
  static const piAbcdefgh = 10; // FLOAT64 pi ABCDEFGH
  static const piHgfedcba = 14; // FLOAT64 pi HGFEDCBA
  static const uint32Abcd = 20; // UINT32 123456 ABCD
  static const int32Cdab = 22; // INT32 -123456 CDAB
  static const int16 = 24; // INT16 -1234
  static const bcd16 = 25; // BCD 1234
  static const uint64Abcd = 26; // UINT64 1234567890123 ABCDEFGH
  static const text = 30; // "Modbus Explorer" ASCII, 8 registers
  static const unixTime32 = 40; // UNIX32 now (dynamic)
  static const unixTime64Ms = 42; // UNIX64 ms now (dynamic)
  static const counter = 50; // UINT16 +1 per tick
  static const sine = 51; // INT16 sine * 1000
  static const voltage = 52; // FLOAT32 ~230 V ABCD (dynamic)
  static const frequency = 54; // FLOAT32 ~50 Hz CDAB (dynamic)
  static const statusWord = 60; // bit mask 0xA50F
  static const temperatureX10 = 70; // INT16 °C * 10 (dynamic)
  static const faultStart = 1000; // 1000..1009 → SERVER DEVICE FAILURE
  static const faultEnd = 1009;

  static const inputTemperature = 0; // FLOAT32 °C ABCD (dynamic)
  static const inputPressure = 2; // FLOAT32 1013.25 hPa ABCD
  static const inputRpm = 4; // UINT16 (dynamic)
}

const demoUnitId = 1;
const meterUnitId = 2;

List<int> float32Registers(double value, {bool swapWords = false}) {
  final data = ByteData(4)..setFloat32(0, value);
  final high = data.getUint16(0);
  final low = data.getUint16(2);
  return swapWords ? [low, high] : [high, low];
}

List<int> float64Registers(double value) {
  final data = ByteData(8)..setFloat64(0, value);
  return [for (var i = 0; i < 8; i += 2) data.getUint16(i)];
}

List<int> _u32(int value) => [(value >> 16) & 0xFFFF, value & 0xFFFF];

List<int> _u64(int value) => [
  for (var shift = 48; shift >= 0; shift -= 16) (value >> shift) & 0xFFFF,
];

List<int> _swapBytes(List<int> registers) => [
  for (final r in registers) ((r & 0xFF) << 8) | (r >> 8),
];

SimulatedDevice buildDemoDevice() {
  final device = SimulatedDevice(
    identification: {
      DeviceIdObject.vendorName: 'Modbus Explorer',
      DeviceIdObject.productCode: 'MBX-SIM-1',
      DeviceIdObject.majorMinorRevision: '1.0',
      DeviceIdObject.vendorUrl: 'https://example.com/modbus-explorer',
      DeviceIdObject.productName: 'Demo Device',
      DeviceIdObject.modelName: 'Simulator',
    },
    faultRanges: const [
      SimulatedFaultRange(
        table: RegisterTable.holdingRegisters,
        start: DemoMap.faultStart,
        end: DemoMap.faultEnd,
        code: ModbusExceptionCode.serverDeviceFailure,
      ),
    ],
  );
  const holding = RegisterTable.holdingRegisters;
  final ten = float32Registers(10);
  device
    ..setRegisters(holding, DemoMap.float10Abcd, ten)
    ..setRegisters(holding, DemoMap.float10Cdab, ten.reversed.toList())
    ..setRegisters(holding, DemoMap.float10Badc, _swapBytes(ten))
    ..setRegisters(
      holding,
      DemoMap.float10Dcba,
      _swapBytes(ten.reversed.toList()),
    );
  final pi = float64Registers(math.pi);
  device
    ..setRegisters(holding, DemoMap.piAbcdefgh, pi)
    ..setRegisters(
      holding,
      DemoMap.piHgfedcba,
      _swapBytes(pi.reversed.toList()),
    )
    ..setRegisters(holding, DemoMap.uint32Abcd, _u32(123456))
    ..setRegisters(
      holding,
      DemoMap.int32Cdab,
      _u32(-123456 & 0xFFFFFFFF).reversed.toList(),
    )
    ..setRegisters(holding, DemoMap.int16, [-1234 & 0xFFFF])
    ..setRegisters(holding, DemoMap.bcd16, [0x1234])
    ..setRegisters(holding, DemoMap.uint64Abcd, _u64(1234567890123))
    ..setRegisters(holding, DemoMap.text, _ascii('Modbus Explorer', 8))
    ..setRegisters(holding, DemoMap.statusWord, [0xA50F])
    ..setRegisters(
      RegisterTable.inputRegisters,
      DemoMap.inputPressure,
      float32Registers(1013.25),
    );
  for (var i = 0; i < 16; i++) {
    device
      ..coils[i] = i % 3 == 0 ? 1 : 0
      ..discreteInputs[i] = i.isEven ? 1 : 0;
  }
  updateDemoDevice(device, DateTime.utc(2024), 0);
  return device;
}

/// Small second device so the slave scan finds more than one ID.
SimulatedDevice buildMeterDevice() {
  return SimulatedDevice(
      size: 100,
      identification: {
        DeviceIdObject.vendorName: 'Modbus Explorer',
        DeviceIdObject.productCode: 'MBX-METER',
        DeviceIdObject.majorMinorRevision: '0.9',
      },
    )
    ..setRegisters(RegisterTable.inputRegisters, 0, float32Registers(230.1))
    ..setRegisters(RegisterTable.inputRegisters, 2, float32Registers(5.25))
    ..setRegisters(RegisterTable.inputRegisters, 4, float32Registers(49.98));
}

/// Deterministic update of the dynamic demo values for time [now].
void updateDemoDevice(SimulatedDevice device, DateTime now, int tick) {
  final seconds = now.millisecondsSinceEpoch / 1000;
  const holding = RegisterTable.holdingRegisters;
  final unixSeconds = now.millisecondsSinceEpoch ~/ 1000;
  device
    ..setRegisters(holding, DemoMap.unixTime32, _u32(unixSeconds))
    ..setRegisters(
      holding,
      DemoMap.unixTime64Ms,
      _u64(now.millisecondsSinceEpoch),
    )
    ..setRegisters(holding, DemoMap.counter, [tick & 0xFFFF])
    ..setRegisters(holding, DemoMap.sine, [
      (1000 * math.sin(seconds / 10)).round() & 0xFFFF,
    ])
    ..setRegisters(
      holding,
      DemoMap.voltage,
      float32Registers(_round(230 + 2.5 * math.sin(seconds / 7), 1)),
    )
    ..setRegisters(
      holding,
      DemoMap.frequency,
      float32Registers(
        _round(50 + 0.05 * math.sin(seconds / 13), 2),
        swapWords: true,
      ),
    )
    ..setRegisters(holding, DemoMap.temperatureX10, [
      (215 + 15 * math.sin(seconds / 60)).round() & 0xFFFF,
    ])
    ..setRegisters(
      RegisterTable.inputRegisters,
      DemoMap.inputTemperature,
      float32Registers(_round(21.5 + 1.5 * math.sin(seconds / 60), 2)),
    )
    ..setRegisters(RegisterTable.inputRegisters, DemoMap.inputRpm, [
      (1450 + 30 * math.sin(seconds / 3)).round(),
    ])
    ..coils[0] = unixSeconds.isEven ? 1 : 0
    ..discreteInputs[0] = unixSeconds.isEven ? 0 : 1;
}

// Rounded so the plausibility heuristic recognises the values as "short".
double _round(double value, int decimals) {
  final factor = math.pow(10, decimals);
  return (value * factor).roundToDouble() / factor;
}

List<int> _ascii(String text, int registerCount) {
  final bytes = [...text.codeUnits];
  while (bytes.length < registerCount * 2) {
    bytes.add(0);
  }
  return [
    for (var i = 0; i < registerCount * 2; i += 2)
      (bytes[i] << 8) | bytes[i + 1],
  ];
}
