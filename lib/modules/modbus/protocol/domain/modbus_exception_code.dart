/// Exception codes from the Modbus application protocol spec (V1.1b3, 7).
enum ModbusExceptionCode {
  illegalFunction(0x01),
  illegalDataAddress(0x02),
  illegalDataValue(0x03),
  serverDeviceFailure(0x04),
  acknowledge(0x05),
  serverDeviceBusy(0x06),

  /// Only in older Modicon documentation, still sent by some devices.
  negativeAcknowledge(0x07),
  memoryParityError(0x08),
  gatewayPathUnavailable(0x0A),
  gatewayTargetDeviceFailedToRespond(0x0B);

  new(this.code);

  final int code;

  static ModbusExceptionCode? fromCode(int code) {
    for (final value in values) {
      if (value.code == code) return value;
    }
    return null;
  }

  /// Spec name, language-neutral (used in logs and exports).
  String get specName => switch (this) {
    illegalFunction => 'ILLEGAL FUNCTION',
    illegalDataAddress => 'ILLEGAL DATA ADDRESS',
    illegalDataValue => 'ILLEGAL DATA VALUE',
    serverDeviceFailure => 'SERVER DEVICE FAILURE',
    acknowledge => 'ACKNOWLEDGE',
    serverDeviceBusy => 'SERVER DEVICE BUSY',
    negativeAcknowledge => 'NEGATIVE ACKNOWLEDGE',
    memoryParityError => 'MEMORY PARITY ERROR',
    gatewayPathUnavailable => 'GATEWAY PATH UNAVAILABLE',
    gatewayTargetDeviceFailedToRespond =>
      'GATEWAY TARGET DEVICE FAILED TO RESPOND',
  };
}
