import 'package:collection/collection.dart';
import 'package:meta/meta.dart';
import 'package:modbus_explorer/features/modbus/domain/modbus_exception_code.dart';
import 'package:modbus_explorer/features/modbus/domain/modbus_request.dart';

const _listEquality = ListEquality<Object>();

@immutable
sealed class ModbusResponse {
  const new();
}

/// FC01/02.
final class ReadBitsResponse extends ModbusResponse {
  new(List<bool> values) : values = List.unmodifiable(values);

  final List<bool> values;

  @override
  bool operator ==(Object other) =>
      other is ReadBitsResponse && _listEquality.equals(other.values, values);

  @override
  int get hashCode => _listEquality.hash(values);
}

/// FC03/04 and the read part of FC23.
final class ReadRegistersResponse extends ModbusResponse {
  new(List<int> values) : values = List.unmodifiable(values);

  final List<int> values;

  @override
  bool operator ==(Object other) =>
      other is ReadRegistersResponse &&
      _listEquality.equals(other.values, values);

  @override
  int get hashCode => _listEquality.hash(values);
}

/// FC05/06/15/16/22 confirm by echoing; the codec verifies the echo, so a
/// successful write carries no further data.
final class WriteAcknowledgedResponse extends ModbusResponse {
  const new();

  @override
  bool operator ==(Object other) => other is WriteAcknowledgedResponse;

  @override
  int get hashCode => (WriteAcknowledgedResponse).hashCode;
}

/// Broadcast (unit 0) on RTU: devices must not answer.
final class NoResponseExpected extends ModbusResponse {
  const new();

  @override
  bool operator ==(Object other) => other is NoResponseExpected;

  @override
  int get hashCode => (NoResponseExpected).hashCode;
}

/// Standard object IDs of FC43/MEI 14.
abstract final class DeviceIdObject {
  static const vendorName = 0x00;
  static const productCode = 0x01;
  static const majorMinorRevision = 0x02;
  static const vendorUrl = 0x03;
  static const productName = 0x04;
  static const modelName = 0x05;
  static const userApplicationName = 0x06;
}

final class DeviceIdentificationResponse extends ModbusResponse {
  new({
    required this.category,
    required this.conformityLevel,
    required this.moreFollows,
    required this.nextObjectId,
    required Map<int, List<int>> objects,
  }) : objects = Map.unmodifiable(objects);

  final DeviceIdCategory category;
  final int conformityLevel;
  final bool moreFollows;
  final int nextObjectId;

  /// Object ID → raw bytes (usually ASCII).
  final Map<int, List<int>> objects;

  String? text(int objectId) {
    final bytes = objects[objectId];
    return bytes == null ? null : String.fromCharCodes(bytes);
  }

  @override
  bool operator ==(Object other) =>
      other is DeviceIdentificationResponse &&
      other.category == category &&
      other.conformityLevel == conformityLevel &&
      other.moreFollows == moreFollows &&
      other.nextObjectId == nextObjectId &&
      const MapEquality<int, List<int>>(values: ListEquality<int>())
          .equals(other.objects, objects);

  @override
  int get hashCode =>
      Object.hash(category, conformityLevel, moreFollows, nextObjectId);
}

/// The device answered with an exception PDU.
final class ExceptionResponse extends ModbusResponse {
  const new({required this.functionCode, required this.exceptionCode});

  final int functionCode;
  final int exceptionCode;

  ModbusExceptionCode? get code => ModbusExceptionCode.fromCode(exceptionCode);

  @override
  bool operator ==(Object other) =>
      other is ExceptionResponse &&
      other.functionCode == functionCode &&
      other.exceptionCode == exceptionCode;

  @override
  int get hashCode => Object.hash(functionCode, exceptionCode);
}
