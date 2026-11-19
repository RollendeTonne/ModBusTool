import 'package:modbus_explorer/core/l10n/l10n.dart';
import 'package:modbus_explorer/modules/modbus/protocol/domain/modbus_exception_code.dart';

/// Short title and plain-language explanation (incl. typical cause) for a
/// Modbus exception code.
({String title, String explanation}) modbusExceptionText(
  AppLocalizations l10n,
  int code,
) {
  final hex = '0x${code.toRadixString(16).toUpperCase().padLeft(2, '0')}';
  return switch (ModbusExceptionCode.fromCode(code)) {
    ModbusExceptionCode.illegalFunction => (
      title: l10n.exceptionIllegalFunctionTitle,
      explanation: l10n.exceptionIllegalFunctionExplanation,
    ),
    ModbusExceptionCode.illegalDataAddress => (
      title: l10n.exceptionIllegalDataAddressTitle,
      explanation: l10n.exceptionIllegalDataAddressExplanation,
    ),
    ModbusExceptionCode.illegalDataValue => (
      title: l10n.exceptionIllegalDataValueTitle,
      explanation: l10n.exceptionIllegalDataValueExplanation,
    ),
    ModbusExceptionCode.serverDeviceFailure => (
      title: l10n.exceptionServerDeviceFailureTitle,
      explanation: l10n.exceptionServerDeviceFailureExplanation,
    ),
    ModbusExceptionCode.acknowledge => (
      title: l10n.exceptionAcknowledgeTitle,
      explanation: l10n.exceptionAcknowledgeExplanation,
    ),
    ModbusExceptionCode.serverDeviceBusy => (
      title: l10n.exceptionServerDeviceBusyTitle,
      explanation: l10n.exceptionServerDeviceBusyExplanation,
    ),
    ModbusExceptionCode.negativeAcknowledge => (
      title: l10n.exceptionNegativeAcknowledgeTitle,
      explanation: l10n.exceptionNegativeAcknowledgeExplanation,
    ),
    ModbusExceptionCode.memoryParityError => (
      title: l10n.exceptionMemoryParityErrorTitle,
      explanation: l10n.exceptionMemoryParityErrorExplanation,
    ),
    ModbusExceptionCode.gatewayPathUnavailable => (
      title: l10n.exceptionGatewayPathUnavailableTitle,
      explanation: l10n.exceptionGatewayPathUnavailableExplanation,
    ),
    ModbusExceptionCode.gatewayTargetDeviceFailedToRespond => (
      title: l10n.exceptionGatewayTargetFailedTitle,
      explanation: l10n.exceptionGatewayTargetFailedExplanation,
    ),
    null => (
      title: l10n.exceptionUnknownTitle(hex),
      explanation: l10n.exceptionUnknownExplanation,
    ),
  };
}
