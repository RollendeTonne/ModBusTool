import 'package:modbus_explorer/core/l10n/l10n.dart';
import 'package:modbus_explorer/features/modbus/data/client/frame_event.dart';
import 'package:modbus_explorer/features/modbus/data/codec/frame_dissector.dart';

String segmentLabel(AppLocalizations l10n, SegmentKind kind) => switch (kind) {
  SegmentKind.transactionId => l10n.segmentTransactionId,
  SegmentKind.protocolId => l10n.segmentProtocolId,
  SegmentKind.length => l10n.segmentLength,
  SegmentKind.unitId => l10n.segmentUnitId,
  SegmentKind.functionCode => l10n.segmentFunctionCode,
  SegmentKind.exceptionCode => l10n.segmentExceptionCode,
  SegmentKind.address => l10n.segmentAddress,
  SegmentKind.count => l10n.segmentCount,
  SegmentKind.byteCount => l10n.segmentByteCount,
  SegmentKind.value => l10n.segmentValue,
  SegmentKind.valueList => l10n.segmentValueList,
  SegmentKind.andMask => l10n.segmentAndMask,
  SegmentKind.orMask => l10n.segmentOrMask,
  SegmentKind.readAddress => l10n.segmentReadAddress,
  SegmentKind.readCount => l10n.segmentReadCount,
  SegmentKind.writeAddress => l10n.segmentWriteAddress,
  SegmentKind.writeCount => l10n.segmentWriteCount,
  SegmentKind.meiType => l10n.segmentMeiType,
  SegmentKind.deviceIdCode => l10n.segmentDeviceIdCode,
  SegmentKind.objectId => l10n.segmentObjectId,
  SegmentKind.conformityLevel => l10n.segmentConformityLevel,
  SegmentKind.moreFollows => l10n.segmentMoreFollows,
  SegmentKind.nextObjectId => l10n.segmentNextObjectId,
  SegmentKind.objectCount => l10n.segmentObjectCount,
  SegmentKind.object => l10n.segmentObject,
  SegmentKind.data => l10n.segmentData,
  SegmentKind.crc => l10n.segmentCrc,
  SegmentKind.truncated => l10n.segmentTruncated,
  SegmentKind.trailing => l10n.segmentTrailing,
};

String frameStatusLabel(AppLocalizations l10n, FrameStatus status) =>
    switch (status) {
      FrameStatus.ok => l10n.frameStatusOk,
      FrameStatus.crcError => l10n.frameStatusCrc,
      FrameStatus.malformed => l10n.frameStatusMalformed,
      FrameStatus.unexpected => l10n.frameStatusUnexpected,
      FrameStatus.incomplete => l10n.frameStatusIncomplete,
    };
