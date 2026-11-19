import 'package:modbus_explorer/core/l10n/l10n.dart';
import 'package:modbus_explorer/features/interpretation/domain/plausibility.dart';

String? plausibilityText(
  AppLocalizations l10n,
  PlausibilityAssessment assessment,
) => switch (assessment.issue) {
  PlausibilityIssue.notANumber => l10n.plausibilityNaN,
  PlausibilityIssue.infinite => l10n.plausibilityInfinite,
  PlausibilityIssue.denormalized => l10n.plausibilityDenormal,
  PlausibilityIssue.hugeMagnitude => l10n.plausibilityHuge,
  PlausibilityIssue.tinyMagnitude => l10n.plausibilityTiny,
  PlausibilityIssue.dateOutOfRange => l10n.plausibilityDate,
  PlausibilityIssue.nonPrintable => l10n.plausibilityNonPrintable,
  PlausibilityIssue.invalid => l10n.plausibilityInvalid,
  null =>
    assessment.level == Plausibility.plausible
        ? l10n.plausibilityPlausible
        : null,
};
