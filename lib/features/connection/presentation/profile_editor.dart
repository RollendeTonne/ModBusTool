import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:modbus_explorer/core/l10n/l10n.dart';
import 'package:modbus_explorer/core/platform/platform_capabilities.dart';
import 'package:modbus_explorer/core/widgets/breakpoints.dart';
import 'package:modbus_explorer/features/connection/domain/connection_config.dart';
import 'package:modbus_explorer/features/connection/domain/connection_profile.dart';
import 'package:modbus_explorer/features/connection/domain/serial_settings.dart';
import 'package:modbus_explorer/features/connection/presentation/connection_kind_ui.dart';
import 'package:modbus_explorer/features/connection/presentation/profiles_controller.dart';
import 'package:modbus_explorer/features/modbus/data/channel/serial_port_service.dart';
import 'package:modbus_explorer/features/modbus/data/codec/rtu_codec.dart';
import 'package:modbus_explorer/features/modbus/data/modbus_providers.dart';

/// Dialog on wide screens, full-screen page on phones. Returns the edited
/// profile or `null` if cancelled.
Future<ConnectionProfile?> showProfileEditor(
  BuildContext context, {
  ConnectionProfile? initial,
}) {
  final editor = ProfileEditor(initial: initial);
  if (MediaQuery.sizeOf(context).width < Breakpoints.medium) {
    return Navigator.of(context).push<ConnectionProfile>(
      MaterialPageRoute(fullscreenDialog: true, builder: (_) => editor),
    );
  }
  return showDialog<ConnectionProfile>(
    context: context,
    builder: (_) => Dialog(
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 760),
        child: editor,
      ),
    ),
  );
}

const _customBaud = -1;

class ProfileEditor extends ConsumerStatefulWidget {
  const new({this.initial, super.key});

  final ConnectionProfile? initial;

  @override
  ConsumerState<ProfileEditor> createState() => _ProfileEditorState();
}

class _ProfileEditorState extends ConsumerState<ProfileEditor> {
  final _formKey = GlobalKey<FormState>();
  late ConnectionKind _kind;

  final _name = TextEditingController();
  final _host = TextEditingController();
  final _port = TextEditingController();
  final _unitId = TextEditingController();
  final _timeout = TextEditingController();
  final _retries = TextEditingController();
  final _serialPort = TextEditingController();
  final _customBaudRate = TextEditingController();
  final _interFrameDelay = TextEditingController();
  final _simLatency = TextEditingController();
  final _simDrop = TextEditingController();
  final _simCorrupt = TextEditingController();

  int _baudChoice = 19200;
  int _dataBits = 8;
  SerialParity _parity = SerialParity.even;
  int _stopBits = 1;
  SerialLineMode _rts = SerialLineMode.unchanged;
  SerialLineMode _dtr = SerialLineMode.unchanged;
  SimulatorFraming _simFraming = SimulatorFraming.tcp;
  bool _autoReconnect = false;

  List<SerialPortInfo>? _ports;
  bool _loadingPorts = false;

  @override
  void initState() {
    super.initState();
    final caps = ref.read(platformCapabilitiesProvider);
    final profile = widget.initial;
    final config =
        profile?.config ??
        defaultConfigFor(
          ConnectionKind.values.firstWhere((k) => k.isAvailable(caps)),
        );
    _kind = config.kind;
    _name.text = profile?.name ?? '';
    _autoReconnect = profile?.autoReconnect ?? false;
    _unitId.text = '${config.options.unitId}';
    _timeout.text = '${config.options.timeout.inMilliseconds}';
    _retries.text = '${config.options.retries}';
    _port.text = '${_defaultPort(_kind)}';

    switch (config) {
      case TcpConnectionConfig(:final host, :final port) ||
          RtuOverTcpConnectionConfig(:final host, :final port):
        _host.text = host;
        _port.text = '$port';
      case RtuConnectionConfig(:final serial):
        _loadSerial(serial);
      case SimulatorConnectionConfig():
        _simFraming = config.framing;
        _simLatency.text = '${config.latency.inMilliseconds}';
        _simDrop.text = _percent(config.dropProbability);
        _simCorrupt.text = _percent(config.corruptProbability);
    }
    if (config is! SimulatorConnectionConfig) {
      const defaults = SimulatorConnectionConfig();
      _simLatency.text = '${defaults.latency.inMilliseconds}';
      _simDrop.text = '0';
      _simCorrupt.text = '0';
    }
    if (caps.supportsSerial) unawaited(_refreshPorts());
  }

  void _loadSerial(SerialSettings serial) {
    _serialPort.text = serial.portName;
    if (SerialSettings.commonBaudRates.contains(serial.baudRate)) {
      _baudChoice = serial.baudRate;
    } else {
      _baudChoice = _customBaud;
      _customBaudRate.text = '${serial.baudRate}';
    }
    _dataBits = serial.dataBits;
    _parity = serial.parity;
    _stopBits = serial.stopBits;
    _rts = serial.rts;
    _dtr = serial.dtr;
    final delay = serial.interFrameDelay;
    if (delay != null) {
      _interFrameDelay.text = (delay.inMicroseconds / 1000).toString();
    }
  }

  static String _percent(double probability) {
    final value = probability * 100;
    return value == value.roundToDouble()
        ? '${value.round()}'
        : value.toStringAsFixed(1);
  }

  static int _defaultPort(ConnectionKind kind) => switch (kind) {
    ConnectionKind.rtuOverTcp => RtuOverTcpConnectionConfig.defaultPort,
    _ => TcpConnectionConfig.defaultPort,
  };

  @override
  void dispose() {
    for (final c in [
      _name,
      _host,
      _port,
      _unitId,
      _timeout,
      _retries,
      _serialPort,
      _customBaudRate,
      _interFrameDelay,
      _simLatency,
      _simDrop,
      _simCorrupt,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _refreshPorts() async {
    setState(() => _loadingPorts = true);
    try {
      // A hanging driver must not leave the spinner running forever.
      final ports = await ref
          .read(serialPortServiceProvider)
          .listPorts()
          .timeout(const Duration(seconds: 5));
      if (!mounted) return;
      // USB adapters first; built-in Bluetooth/debug ports are rarely the
      // Modbus line, so only a USB port is pre-selected.
      final sorted = [...ports]
        ..sort((a, b) {
          final usbA = a.vendorId != null ? 0 : 1;
          final usbB = b.vendorId != null ? 0 : 1;
          return usbA != usbB ? usbA - usbB : a.name.compareTo(b.name);
        });
      setState(() {
        _ports = sorted;
        final firstUsb = sorted.where((p) => p.vendorId != null).firstOrNull;
        if (_serialPort.text.isEmpty && firstUsb != null) {
          _serialPort.text = firstUsb.name;
        }
      });
    } on Object {
      if (mounted) setState(() => _ports = const []);
    } finally {
      if (mounted) setState(() => _loadingPorts = false);
    }
  }

  void _setKind(ConnectionKind kind) {
    setState(() {
      // Keep the port if the user changed it, otherwise follow the default.
      if (_port.text == '${_defaultPort(_kind)}') {
        _port.text = '${_defaultPort(kind)}';
      }
      _kind = kind;
    });
  }

  int get _baudRate => _baudChoice == _customBaud
      ? int.tryParse(_customBaudRate.text) ?? 0
      : _baudChoice;

  ConnectionConfig _buildConfig() {
    final options = RequestOptions(
      unitId: int.parse(_unitId.text),
      timeout: Duration(milliseconds: int.parse(_timeout.text)),
      retries: int.parse(_retries.text),
    );
    return switch (_kind) {
      ConnectionKind.tcp => TcpConnectionConfig(
        host: _host.text.trim(),
        port: int.parse(_port.text),
        options: options,
      ),
      ConnectionKind.rtuOverTcp => RtuOverTcpConnectionConfig(
        host: _host.text.trim(),
        port: int.parse(_port.text),
        options: options,
      ),
      ConnectionKind.rtu => RtuConnectionConfig(
        serial: SerialSettings(
          portName: _serialPort.text.trim(),
          baudRate: _baudRate,
          dataBits: _dataBits,
          parity: _parity,
          stopBits: _stopBits,
          rts: _rts,
          dtr: _dtr,
          interFrameDelay: _interFrameDelay.text.trim().isEmpty
              ? null
              : Duration(
                  microseconds:
                      (double.parse(
                                _interFrameDelay.text.replaceAll(',', '.'),
                              ) *
                              1000)
                          .round(),
                ),
        ),
        options: options,
      ),
      ConnectionKind.simulator => SimulatorConnectionConfig(
        framing: _simFraming,
        latency: Duration(milliseconds: int.parse(_simLatency.text)),
        dropProbability: double.parse(_simDrop.text) / 100,
        corruptProbability: double.parse(_simCorrupt.text) / 100,
        options: options,
      ),
    };
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final config = _buildConfig();
    final initial = widget.initial;
    final name = _name.text.trim().isEmpty ? config.summary : _name.text.trim();
    Navigator.of(context).pop(
      initial == null
          ? ConnectionProfile(
              id: ProfilesController.newProfileId(),
              name: name,
              config: config,
              createdAt: DateTime.now(),
              autoReconnect: _autoReconnect,
            )
          : initial.copyWith(
              name: name,
              config: config,
              autoReconnect: _autoReconnect,
            ),
    );
  }

  String? Function(String?) _intValidator(int min, int max) => (value) {
    final l10n = context.l10n;
    final text = value?.trim() ?? '';
    if (text.isEmpty) return l10n.validationRequired;
    final number = int.tryParse(text);
    if (number == null) return l10n.validationNumber;
    if (number < min || number > max) return l10n.validationRange(min, max);
    return null;
  };

  Widget _intField(
    TextEditingController controller,
    String label, {
    required int min,
    required int max,
    double width = 140,
    String? helper,
  }) => SizedBox(
    width: width,
    child: TextFormField(
      controller: controller,
      decoration: InputDecoration(labelText: label, helperText: helper),
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      validator: _intValidator(min, max),
      autovalidateMode: AutovalidateMode.onUserInteraction,
    ),
  );

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final caps = ref.watch(platformCapabilitiesProvider);
    final isNew = widget.initial == null;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.close),
          tooltip: l10n.actionCancel,
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(isNew ? l10n.profileNew : l10n.profileEditTitle),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilledButton(
              key: const Key('profileEditor.save'),
              onPressed: _save,
              child: Text(l10n.actionSave),
            ),
          ),
        ],
      ),
      body: CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.enter, control: true): _save,
          const SingleActivator(LogicalKeyboardKey.enter, meta: true): _save,
        },
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextFormField(
                key: const Key('profileEditor.name'),
                controller: _name,
                autofocus: isNew,
                decoration: InputDecoration(labelText: l10n.fieldName),
              ),
              const SizedBox(height: 16),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SegmentedButton<ConnectionKind>(
                  key: const Key('profileEditor.kind'),
                  segments: [
                    for (final kind in ConnectionKind.values)
                      if (kind.isAvailable(caps) || kind == _kind)
                        ButtonSegment(
                          value: kind,
                          icon: Icon(kind.icon),
                          label: Text(kind.label(l10n)),
                        ),
                  ],
                  selected: {_kind},
                  onSelectionChanged: (s) => _setKind(s.single),
                ),
              ),
              const SizedBox(height: 20),
              ..._kindFields(l10n, theme),
              const SizedBox(height: 20),
              _SectionTitle(l10n.sectionRequests),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _intField(
                    _unitId,
                    l10n.fieldUnitId,
                    min: 0,
                    max: 255,
                    width: 120,
                  ),
                  _intField(
                    _timeout,
                    l10n.fieldTimeout,
                    min: 10,
                    max: 60000,
                    width: 130,
                  ),
                  _intField(
                    _retries,
                    l10n.fieldRetries,
                    min: 0,
                    max: 10,
                    width: 130,
                  ),
                ],
              ),
              if (_kind != ConnectionKind.simulator) ...[
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.fieldAutoReconnect),
                  subtitle: Text(l10n.fieldAutoReconnectHint),
                  value: _autoReconnect,
                  onChanged: (v) => setState(() => _autoReconnect = v),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _kindFields(AppLocalizations l10n, ThemeData theme) {
    switch (_kind) {
      case ConnectionKind.tcp || ConnectionKind.rtuOverTcp:
        return [
          _SectionTitle(l10n.sectionConnection),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              SizedBox(
                width: 280,
                child: TextFormField(
                  key: const Key('profileEditor.host'),
                  controller: _host,
                  decoration: InputDecoration(labelText: l10n.fieldHost),
                  keyboardType: TextInputType.url,
                  autocorrect: false,
                  validator: (v) =>
                      (v ?? '').trim().isEmpty ? l10n.validationRequired : null,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                ),
              ),
              _intField(_port, l10n.fieldPort, min: 1, max: 65535, width: 110),
            ],
          ),
        ];
      case ConnectionKind.rtu:
        return _serialFields(l10n, theme);
      case ConnectionKind.simulator:
        return [
          _SectionTitle(l10n.sectionSimulator),
          SegmentedButton<SimulatorFraming>(
            segments: const [
              ButtonSegment(value: SimulatorFraming.tcp, label: Text('TCP')),
              ButtonSegment(value: SimulatorFraming.rtu, label: Text('RTU')),
            ],
            selected: {_simFraming},
            onSelectionChanged: (s) => setState(() => _simFraming = s.single),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _intField(
                _simLatency,
                l10n.fieldSimLatency,
                min: 0,
                max: 10000,
                width: 180,
              ),
              _intField(
                _simDrop,
                l10n.fieldSimDrop,
                min: 0,
                max: 100,
                width: 180,
              ),
              _intField(
                _simCorrupt,
                l10n.fieldSimCorrupt,
                min: 0,
                max: 100,
                width: 200,
              ),
            ],
          ),
        ];
    }
  }

  List<Widget> _serialFields(AppLocalizations l10n, ThemeData theme) {
    final ports = _ports ?? const [];
    final autoDelay = rtuInterFrameDelay(_baudRate > 0 ? _baudRate : 19200);
    return [
      _SectionTitle(l10n.sectionSerial),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: TextFormField(
              key: const Key('profileEditor.serialPort'),
              controller: _serialPort,
              autocorrect: false,
              decoration: InputDecoration(
                labelText: l10n.fieldSerialPort,
                helperText: _ports != null && ports.isEmpty
                    ? l10n.noPortsFound
                    : null,
                suffixIcon: ports.isEmpty
                    ? null
                    : PopupMenuButton<String>(
                        icon: const Icon(Icons.arrow_drop_down),
                        onSelected: (name) =>
                            setState(() => _serialPort.text = name),
                        itemBuilder: (_) => [
                          for (final p in ports)
                            PopupMenuItem(
                              value: p.name,
                              child: ListTile(
                                dense: true,
                                title: Text(p.name),
                                subtitle: Text(
                                  [
                                    p.description,
                                    p.manufacturer,
                                  ].whereType<String>().join(' · '),
                                ),
                              ),
                            ),
                        ],
                      ),
              ),
              validator: (v) =>
                  (v ?? '').trim().isEmpty ? l10n.validationRequired : null,
              autovalidateMode: AutovalidateMode.onUserInteraction,
            ),
          ),
          const SizedBox(width: 4),
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: _loadingPorts
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : IconButton(
                    tooltip: l10n.refreshPorts,
                    icon: const Icon(Icons.refresh),
                    onPressed: _refreshPorts,
                  ),
          ),
        ],
      ),
      const SizedBox(height: 12),
      Wrap(
        spacing: 12,
        runSpacing: 12,
        crossAxisAlignment: WrapCrossAlignment.end,
        children: [
          SizedBox(
            width: 150,
            child: DropdownButtonFormField<int>(
              isExpanded: true,
              initialValue: _baudChoice,
              decoration: InputDecoration(labelText: l10n.fieldBaudRate),
              items: [
                for (final rate in SerialSettings.commonBaudRates)
                  DropdownMenuItem(value: rate, child: Text('$rate')),
                DropdownMenuItem(
                  value: _customBaud,
                  child: Text(l10n.baudRateCustom),
                ),
              ],
              onChanged: (v) => setState(() => _baudChoice = v!),
            ),
          ),
          if (_baudChoice == _customBaud)
            _intField(
              _customBaudRate,
              l10n.fieldCustomBaudRate,
              min: 50,
              max: 4000000,
              width: 160,
            ),
          SizedBox(
            width: 130,
            child: DropdownButtonFormField<int>(
              isExpanded: true,
              initialValue: _dataBits,
              decoration: InputDecoration(labelText: l10n.fieldDataBits),
              items: const [
                DropdownMenuItem(value: 7, child: Text('7')),
                DropdownMenuItem(value: 8, child: Text('8')),
              ],
              onChanged: (v) => setState(() => _dataBits = v!),
            ),
          ),
          SizedBox(
            width: 140,
            child: DropdownButtonFormField<SerialParity>(
              isExpanded: true,
              initialValue: _parity,
              decoration: InputDecoration(labelText: l10n.fieldParity),
              items: [
                DropdownMenuItem(
                  value: SerialParity.none,
                  child: Text(l10n.parityNone),
                ),
                DropdownMenuItem(
                  value: SerialParity.even,
                  child: Text(l10n.parityEven),
                ),
                DropdownMenuItem(
                  value: SerialParity.odd,
                  child: Text(l10n.parityOdd),
                ),
              ],
              onChanged: (v) => setState(() => _parity = v!),
            ),
          ),
          SizedBox(
            width: 130,
            child: DropdownButtonFormField<int>(
              isExpanded: true,
              initialValue: _stopBits,
              decoration: InputDecoration(labelText: l10n.fieldStopBits),
              items: const [
                DropdownMenuItem(value: 1, child: Text('1')),
                DropdownMenuItem(value: 2, child: Text('2')),
              ],
              onChanged: (v) => setState(() => _stopBits = v!),
            ),
          ),
        ],
      ),
      const SizedBox(height: 12),
      Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          _lineModeField(l10n.fieldRts, _rts, (v) => setState(() => _rts = v)),
          _lineModeField(l10n.fieldDtr, _dtr, (v) => setState(() => _dtr = v)),
          SizedBox(
            width: 260,
            child: TextFormField(
              controller: _interFrameDelay,
              decoration: InputDecoration(
                labelText: l10n.fieldInterFrameDelay,
                helperText: l10n.interFrameDelayAuto(
                  (autoDelay.inMicroseconds / 1000).toStringAsFixed(2),
                ),
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              validator: (v) {
                final text = (v ?? '').trim().replaceAll(',', '.');
                if (text.isEmpty) return null;
                final value = double.tryParse(text);
                return value == null || value < 0 || value > 1000
                    ? l10n.validationRange(0, 1000)
                    : null;
              },
              autovalidateMode: AutovalidateMode.onUserInteraction,
            ),
          ),
        ],
      ),
    ];
  }

  Widget _lineModeField(
    String label,
    SerialLineMode value,
    ValueChanged<SerialLineMode> onChanged,
  ) {
    final l10n = context.l10n;
    return SizedBox(
      width: 180,
      child: DropdownButtonFormField<SerialLineMode>(
        isExpanded: true,
        initialValue: value,
        decoration: InputDecoration(labelText: label),
        items: [
          DropdownMenuItem(
            value: SerialLineMode.unchanged,
            child: Text(l10n.lineUnchanged),
          ),
          DropdownMenuItem(value: SerialLineMode.on, child: Text(l10n.lineOn)),
          DropdownMenuItem(
            value: SerialLineMode.off,
            child: Text(l10n.lineOff),
          ),
        ],
        onChanged: (v) => onChanged(v!),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const new(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Semantics(
      header: true,
      child: Text(
        text,
        style: Theme.of(context).textTheme.titleSmall
            ?.copyWith(color: Theme.of(context).colorScheme.primary),
      ),
    ),
  );
}
