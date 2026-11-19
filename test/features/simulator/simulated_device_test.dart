import 'package:flutter_test/flutter_test.dart';
import 'package:modbus_explorer/features/interpretation/domain/byte_order.dart';
import 'package:modbus_explorer/features/interpretation/domain/data_type.dart';
import 'package:modbus_explorer/features/interpretation/domain/interpreted_value.dart';
import 'package:modbus_explorer/features/interpretation/domain/text_decoder.dart';
import 'package:modbus_explorer/features/interpretation/domain/value_decoder.dart';
import 'package:modbus_explorer/features/modbus/domain/modbus_exception_code.dart';
import 'package:modbus_explorer/features/modbus/domain/modbus_request.dart';
import 'package:modbus_explorer/features/modbus/domain/modbus_response.dart';
import 'package:modbus_explorer/features/modbus/domain/register_table.dart';
import 'package:modbus_explorer/features/simulator/data/request_handler.dart';
import 'package:modbus_explorer/features/simulator/domain/demo_devices.dart';
import 'package:modbus_explorer/features/simulator/domain/simulated_device.dart';

import '../../helpers/hex.dart';

InterpretedValue decodeHolding(
  SimulatedDevice device,
  int address,
  DataType type,
  String order,
) => decodeValue(
  registersToBytes(
    device.holdingRegisters.sublist(address, address + type.registerCount),
  ),
  type,
  ByteOrder.parse(order),
);

void main() {
  group('SimulatedDevice', () {
    late SimulatedDevice device;
    setUp(() => device = SimulatedDevice(size: 100));

    test('reads beyond size are illegal data address', () {
      final response = device.handle(
        ReadRegistersRequest(
          table: RegisterTable.holdingRegisters,
          address: 99,
          count: 2,
        ),
      );
      expect(
        (response as ExceptionResponse).code,
        ModbusExceptionCode.illegalDataAddress,
      );
    });

    test('fault ranges answer with their code', () {
      final faulty = SimulatedDevice(
        faultRanges: const [
          SimulatedFaultRange(
            table: RegisterTable.inputRegisters,
            start: 10,
            end: 12,
            code: ModbusExceptionCode.serverDeviceBusy,
          ),
        ],
      );
      ModbusResponse read(int address, int count) => faulty.handle(
        ReadRegistersRequest(
          table: RegisterTable.inputRegisters,
          address: address,
          count: count,
        ),
      );
      expect(
        (read(8, 3) as ExceptionResponse).code,
        ModbusExceptionCode.serverDeviceBusy,
      );
      expect(read(13, 2), isA<ReadRegistersResponse>());
      expect(read(5, 5), isA<ReadRegistersResponse>());
    });

    test('mask write follows the spec formula', () {
      device
        ..holdingRegisters[4] = 0x12
        ..handle(
          MaskWriteRegisterRequest(address: 4, andMask: 0xF2, orMask: 0x25),
        );
      expect(device.holdingRegisters[4], 0x17);
    });

    test('read/write multiple writes before reading', () {
      final response = device.handle(
        ReadWriteMultipleRegistersRequest(
          readAddress: 0,
          readCount: 3,
          writeAddress: 1,
          writeValues: const [9, 9],
        ),
      );
      expect((response as ReadRegistersResponse).values, [0, 9, 9]);
    });

    test('device identification categories', () {
      final demo = buildDemoDevice();
      DeviceIdentificationResponse read(DeviceIdCategory c, [int id = 0]) =>
          demo.handle(
            ReadDeviceIdentificationRequest(category: c, objectId: id),
          ) as DeviceIdentificationResponse;
      expect(read(DeviceIdCategory.basic).objects.keys, [0, 1, 2]);
      expect(read(DeviceIdCategory.regular).objects.keys, [0, 1, 2, 3, 4, 5]);
      expect(
        read(DeviceIdCategory.individual, DeviceIdObject.productName).text(4),
        'Demo Device',
      );
      expect(
        demo.handle(
          ReadDeviceIdentificationRequest(
            category: DeviceIdCategory.individual,
            objectId: 0x42,
          ),
        ),
        isA<ExceptionResponse>(),
      );
    });

    test('raw PDU handler answers exceptions for bad requests', () {
      expect(handleRequestPdu(device, hex('07')), hex('87 01'));
      expect(handleRequestPdu(device, hex('03 00 00 00 00')), hex('83 03'));
      expect(
        handleRequestPdu(device, hex('03 00 00 00 01')),
        hex('03 02 00 00'),
      );
    });
  });

  group('demo device map', () {
    final device = buildDemoDevice();

    test('FLOAT32 10.0 in all four orders', () {
      for (final (address, order) in [
        (DemoMap.float10Abcd, 'ABCD'),
        (DemoMap.float10Cdab, 'CDAB'),
        (DemoMap.float10Badc, 'BADC'),
        (DemoMap.float10Dcba, 'DCBA'),
      ]) {
        final value = decodeHolding(device, address, DataType.float32, order);
        expect((value as FloatValue).value, 10.0, reason: order);
      }
    });

    test('FLOAT64 pi in ABCDEFGH and HGFEDCBA', () {
      for (final (address, order) in [
        (DemoMap.piAbcdefgh, 'ABCDEFGH'),
        (DemoMap.piHgfedcba, 'HGFEDCBA'),
      ]) {
        final value = decodeHolding(device, address, DataType.float64, order);
        expect((value as FloatValue).value, closeTo(3.141592653589793, 0));
      }
    });

    test('integers, BCD and text', () {
      expect(
        (decodeHolding(
          device,
          DemoMap.uint32Abcd,
          DataType.uint32,
          'ABCD',
        ) as IntegerValue).value,
        BigInt.from(123456),
      );
      expect(
        (decodeHolding(
          device,
          DemoMap.int32Cdab,
          DataType.int32,
          'CDAB',
        ) as IntegerValue).value,
        BigInt.from(-123456),
      );
      expect(
        (decodeHolding(
          device,
          DemoMap.int16,
          DataType.int16,
          'AB',
        ) as IntegerValue).value,
        BigInt.from(-1234),
      );
      expect(
        (decodeHolding(
          device,
          DemoMap.bcd16,
          DataType.bcd16,
          'AB',
        ) as IntegerValue).value,
        BigInt.from(1234),
      );
      expect(
        (decodeHolding(
          device,
          DemoMap.uint64Abcd,
          DataType.uint64,
          'ABCDEFGH',
        ) as IntegerValue).value,
        BigInt.from(1234567890123),
      );
      final text = decodeText(
        registersToBytes(
          device.holdingRegisters.sublist(DemoMap.text, DemoMap.text + 8),
        ),
      );
      expect(text.text, 'Modbus Explorer');
    });

    test('dynamic values follow the given time', () {
      final now = DateTime.utc(2025, 6, 1, 12);
      updateDemoDevice(device, now, 7);
      expect(
        (decodeHolding(
          device,
          DemoMap.unixTime32,
          DataType.unixTime32,
          'ABCD',
        ) as TimestampValue).value,
        now,
      );
      expect(
        (decodeHolding(
          device,
          DemoMap.unixTime64Ms,
          DataType.unixTime64Ms,
          'ABCDEFGH',
        ) as TimestampValue).value,
        now,
      );
      expect(device.holdingRegisters[DemoMap.counter], 7);
      final voltage = decodeHolding(
        device,
        DemoMap.voltage,
        DataType.float32,
        'ABCD',
      ) as FloatValue;
      expect(voltage.value, inInclusiveRange(227.5, 232.5));
      final frequency = decodeHolding(
        device,
        DemoMap.frequency,
        DataType.float32,
        'CDAB',
      ) as FloatValue;
      expect(frequency.value, inInclusiveRange(49.95, 50.05));
    });
  });
}
