import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:modbus_explorer/core/files/file_exchange.dart';
import 'package:modbus_explorer/core/l10n/l10n.dart';
import 'package:modbus_explorer/core/theme/app_theme.dart';
import 'package:modbus_explorer/modules/mqtt/domain/mqtt_log.dart';
import 'package:modbus_explorer/modules/mqtt/presentation/mqtt_connection_controller.dart';
import 'package:modbus_explorer/modules/mqtt/presentation/mqtt_monitor_page.dart';
import 'package:modbus_explorer/modules/mqtt/presentation/mqtt_replay_controller.dart';

Future<void> showReplayDialog(BuildContext context) =>
    showDialog<void>(context: context, builder: (_) => const _ReplayDialog());

class _ReplayDialog extends ConsumerStatefulWidget {
  const new();

  @override
  ConsumerState<_ReplayDialog> createState() => _ReplayDialogState();
}

class _ReplayDialogState extends ConsumerState<_ReplayDialog> {
  /// Loaded file: name and parsed recording.
  (String, Recording)? _loaded;
  Recording? get _recording => _loaded?.$2;
  String get _name => _loaded?.$1 ?? '';
  double _speed = 1;
  bool _capPauses = true;
  bool _keepRetain = false;
  bool _onlyReceived = true;
  final _prefix = TextEditingController(text: 'replay/');

  @override
  void dispose() {
    _prefix.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final file = await ref.read(fileExchangeProvider).openText([
      jsonLinesFileType,
      ExchangeFileType.json,
    ]);
    if (file == null || !mounted) return;
    setState(() => _loaded = (file.name, parseRecording(file.content)));
  }

  ReplayOptions get _options => ReplayOptions(
    speed: _speed,
    maxPause: _capPauses ? const Duration(seconds: 10) : null,
    topicPrefix: _prefix.text,
    keepRetain: _keepRetain,
    onlyReceived: _onlyReceived,
  );

  Future<void> _start() async {
    final l10n = context.l10n;
    final recording = _recording!;
    final steps = planReplay(recording, _options);
    final profile = ref.read(mqttConnectionControllerProvider).profile;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.warning_amber),
        title: Text(l10n.replayTitle),
        content: Text(l10n.replayConfirm(steps.length, profile?.name ?? '')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.actionCancel),
          ),
          FilledButton(
            key: const Key('replay.confirm'),
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.replayStart),
          ),
        ],
      ),
    );
    if (!(ok ?? false) || !mounted) return;
    ref.read(mqttReplayControllerProvider.notifier).start(steps, name: _name);
    Navigator.of(context).pop();
  }

  static String _duration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes % 60;
    final s = d.inSeconds % 60;
    return h > 0
        ? '$h h $m min'
        : m > 0
        ? '$m min $s s'
        : '$s s';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final connected = ref.watch(
      mqttConnectionControllerProvider.select((s) => s.isConnected),
    );
    final recording = _recording;
    final playable =
        recording != null &&
        connected &&
        planReplay(recording, _options).isNotEmpty;

    return AlertDialog(
      title: Text(l10n.replayTitle),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              OutlinedButton.icon(
                key: const Key('replay.load'),
                onPressed: _load,
                icon: const Icon(Icons.file_open_outlined),
                label: Text(l10n.replayLoad),
              ),
              if (recording != null) ...[
                const SizedBox(height: 8),
                if (recording.messages.isEmpty)
                  Text(l10n.replayNoMessages)
                else
                  Text(
                    l10n.replayLoaded(
                      _name,
                      recording.messages.length,
                      recording.topicCount,
                      _duration(recording.duration),
                    ),
                    key: const Key('replay.summary'),
                  ),
                if (recording.skippedLines > 0)
                  Text(
                    l10n.replaySkipped(recording.skippedLines),
                    style: theme.textTheme.bodySmall,
                  ),
                const SizedBox(height: 12),
                Text(l10n.replaySpeed, style: theme.textTheme.labelLarge),
                const SizedBox(height: 6),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SegmentedButton<double>(
                    key: const Key('replay.speed'),
                    showSelectedIcon: false,
                    segments: [
                      for (final s in [1.0, 2.0, 5.0, 10.0])
                        ButtonSegment(value: s, label: Text('${s.round()}×')),
                      ButtonSegment(value: 0, label: Text(l10n.replayNoPauses)),
                    ],
                    selected: {_speed},
                    onSelectionChanged: (s) =>
                        setState(() => _speed = s.single),
                  ),
                ),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.replayCapPauses),
                  value: _capPauses,
                  onChanged: (v) => setState(() => _capPauses = v!),
                ),
                TextField(
                  key: const Key('replay.prefix'),
                  controller: _prefix,
                  style: theme.textTheme.bodyMedium!.mono,
                  decoration: InputDecoration(
                    labelText: l10n.replayPrefix,
                    helperText: l10n.replayPrefixHint,
                    helperMaxLines: 2,
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                CheckboxListTile(
                  key: const Key('replay.keepRetain'),
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.replayKeepRetain),
                  subtitle: Text(l10n.replayKeepRetainHint),
                  value: _keepRetain,
                  onChanged: (v) => setState(() => _keepRetain = v!),
                ),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.replayOnlyReceived),
                  value: _onlyReceived,
                  onChanged: (v) => setState(() => _onlyReceived = v!),
                ),
              ],
              if (!connected)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    l10n.replayNeedsConnection,
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.actionCancel),
        ),
        FilledButton.icon(
          key: const Key('replay.start'),
          onPressed: playable ? _start : null,
          icon: const Icon(Icons.play_arrow),
          label: Text(l10n.replayStart),
        ),
      ],
    );
  }
}
