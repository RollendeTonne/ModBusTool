/// Quantity limits imposed by the 253-byte PDU size.
abstract final class ModbusLimits {
  static const maxPduLength = 253;
  static const maxReadBits = 2000;
  static const maxReadRegisters = 125;
  static const maxWriteCoils = 1968;
  static const maxWriteRegisters = 123;
  static const maxReadWriteReadRegisters = 125;
  static const maxReadWriteWriteRegisters = 121;
  static const maxUnitId = 247;
  static const broadcastUnitId = 0;
}
