/// The four Modbus data tables and their classic Modicon prefix digit.
enum RegisterTable {
  coils(0, isBitTable: true, isWritable: true),
  discreteInputs(1, isBitTable: true, isWritable: false),
  inputRegisters(3, isBitTable: false, isWritable: false),
  holdingRegisters(4, isBitTable: false, isWritable: true);

  new(this.modiconPrefix, {required this.isBitTable, required this.isWritable});

  final int modiconPrefix;
  final bool isBitTable;
  final bool isWritable;
}
