import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:modbus_explorer/core/l10n/l10n.dart';
import 'package:modbus_explorer/features/modbus/domain/addressing_mode.dart';
import 'package:modbus_explorer/features/settings/domain/app_settings.dart';
import 'package:modbus_explorer/features/settings/presentation/settings_controller.dart';

class SettingsPage extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final settings = ref.watch(settingsControllerProvider);
    final controller = ref.read(settingsControllerProvider.notifier);
    final languageCode = settings.localeOverride?.languageCode;

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _SectionHeader(l10n.settingsAppearance),
            _LabeledControl(
              label: l10n.settingsTheme,
              child: SegmentedButton<AppThemePreference>(
                key: const Key('settings.theme'),
                segments: [
                  ButtonSegment(
                    value: AppThemePreference.system,
                    label: Text(l10n.themeSystem),
                    icon: const Icon(Icons.brightness_auto),
                  ),
                  ButtonSegment(
                    value: AppThemePreference.light,
                    label: Text(l10n.themeLight),
                    icon: const Icon(Icons.light_mode),
                  ),
                  ButtonSegment(
                    value: AppThemePreference.dark,
                    label: Text(l10n.themeDark),
                    icon: const Icon(Icons.dark_mode),
                  ),
                ],
                selected: {settings.theme},
                onSelectionChanged: (s) => controller.setTheme(s.single),
              ),
            ),
            _LabeledControl(
              label: l10n.settingsLanguage,
              child: SegmentedButton<String>(
                key: const Key('settings.language'),
                segments: [
                  ButtonSegment(value: '', label: Text(l10n.languageSystem)),
                  ButtonSegment(value: 'de', label: Text(l10n.languageGerman)),
                  ButtonSegment(value: 'en', label: Text(l10n.languageEnglish)),
                ],
                selected: {languageCode ?? ''},
                onSelectionChanged: (s) => controller.setLocaleOverride(
                  s.single.isEmpty ? null : Locale(s.single),
                ),
              ),
            ),
            const SizedBox(height: 16),
            _SectionHeader(l10n.settingsModbus),
            _LabeledControl(
              label: l10n.settingsAddressing,
              hint: settings.addressingMode == AddressingMode.zeroBased
                  ? l10n.addressingZeroBasedHint
                  : l10n.addressingOneBasedHint,
              child: SegmentedButton<AddressingMode>(
                key: const Key('settings.addressing'),
                segments: [
                  ButtonSegment(
                    value: AddressingMode.zeroBased,
                    label: Text(l10n.addressingZeroBased),
                  ),
                  ButtonSegment(
                    value: AddressingMode.oneBased,
                    label: Text(l10n.addressingOneBased),
                  ),
                ],
                selected: {settings.addressingMode},
                onSelectionChanged: (s) =>
                    controller.setAddressingMode(s.single),
              ),
            ),
            SwitchListTile(
              key: const Key('settings.confirmWrites'),
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.settingsConfirmWrites),
              subtitle: Text(l10n.settingsConfirmWritesHint),
              value: settings.confirmWrites,
              onChanged: (v) => controller.setConfirmWrites(enabled: v),
            ),
            SwitchListTile(
              key: const Key('settings.highlightPlausible'),
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.settingsHighlightPlausible),
              subtitle: Text(l10n.settingsHighlightPlausibleHint),
              value: settings.highlightPlausible,
              onChanged: (v) => controller.setHighlightPlausible(enabled: v),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const new(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Semantics(
      header: true,
      child: Text(
        text,
        style: Theme.of(context).textTheme.titleMedium
            ?.copyWith(color: Theme.of(context).colorScheme.primary),
      ),
    ),
  );
}

class _LabeledControl extends StatelessWidget {
  const new({required this.label, required this.child, this.hint});

  final String label;
  final String? hint;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: theme.textTheme.bodyLarge),
          const SizedBox(height: 8),
          // Segmented buttons overflow on narrow phones; scroll instead.
          SingleChildScrollView(scrollDirection: Axis.horizontal, child: child),
          if (hint != null) ...[
            const SizedBox(height: 6),
            Text(
              hint!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
