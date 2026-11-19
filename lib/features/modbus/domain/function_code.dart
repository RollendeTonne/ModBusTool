enum FunctionCode {
  readCoils(0x01),
  readDiscreteInputs(0x02),
  readHoldingRegisters(0x03),
  readInputRegisters(0x04),
  writeSingleCoil(0x05),
  writeSingleRegister(0x06),
  writeMultipleCoils(0x0F),
  writeMultipleRegisters(0x10),
  maskWriteRegister(0x16),
  readWriteMultipleRegisters(0x17),

  /// Encapsulated interface transport; used with MEI 0x0E for device ID.
  encapsulatedInterface(0x2B);

  new(this.code);

  final int code;

  /// Exception responses echo the function code with this bit set.
  static const exceptionFlag = 0x80;

  static FunctionCode? fromCode(int code) {
    for (final fc in values) {
      if (fc.code == code) return fc;
    }
    return null;
  }

  bool get isWrite => switch (this) {
    writeSingleCoil ||
    writeSingleRegister ||
    writeMultipleCoils ||
    writeMultipleRegisters ||
    maskWriteRegister ||
    readWriteMultipleRegisters => true,
    _ => false,
  };

  /// `FC03` style label used in logs.
  String get label =>
      'FC${code.toRadixString(16).toUpperCase().padLeft(2, '0')}';
}
