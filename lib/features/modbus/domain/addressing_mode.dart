/// How register addresses are presented to and entered by the user.
///
/// The wire protocol is always 0-based; this only affects display/input.
enum AddressingMode {
  /// Address as sent in the PDU (0..65535).
  zeroBased,

  /// Classic Modicon notation, e.g. 40001 = holding register 0.
  oneBased,
}
