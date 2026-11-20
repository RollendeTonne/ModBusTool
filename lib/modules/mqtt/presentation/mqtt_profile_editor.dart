import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:modbus_explorer/core/files/file_exchange.dart';
import 'package:modbus_explorer/core/l10n/l10n.dart';
import 'package:modbus_explorer/core/platform/platform_capabilities.dart';
import 'package:modbus_explorer/core/theme/app_theme.dart';
import 'package:modbus_explorer/core/widgets/breakpoints.dart';
import 'package:modbus_explorer/modules/mqtt/data/mqtt_profile_repository.dart';
import 'package:modbus_explorer/modules/mqtt/data/package_session_support.dart';
import 'package:modbus_explorer/modules/mqtt/domain/mqtt_config.dart';
import 'package:modbus_explorer/modules/mqtt/domain/topic_filter.dart';
import 'package:modbus_explorer/modules/mqtt/presentation/mqtt_profiles_controller.dart';
import 'package:modbus_explorer/modules/mqtt/presentation/mqtt_texts.dart';

/// Result of the editor: the profile plus secret changes. For secrets
/// `null` = unchanged, `''` = delete.
final class MqttEditorResult {
  const new(
    this.profile, {
    this.password,
    this.clientKeyPem,
    this.clientKeyPassword,
  });

  final MqttProfile profile;
  final String? password;
  final String? clientKeyPem;
  final String? clientKeyPassword;
}

const _pemTypes = [
  ExchangeFileType(
    label: 'PEM',
    extension: 'pem',
    mimeType: 'application/x-pem-file',
    uti: 'public.x509-certificate',
  ),
  ExchangeFileType(
    label: 'CRT',
    extension: 'crt',
    mimeType: 'application/x-x509-ca-cert',
    uti: 'public.x509-certificate',
  ),
  ExchangeFileType(
    label: 'KEY',
    extension: 'key',
    mimeType: 'application/x-pem-file',
    uti: 'public.data',
  ),
];

/// Dialog on wide screens, full-screen page on phones; saves the profile
/// and its secrets, returns the saved profile or `null` if cancelled.
Future<MqttProfile?> showMqttProfileEditor(
  BuildContext context,
  WidgetRef ref, {
  MqttProfile? initial,
}) async {
  final editor = MqttProfileEditor(initial: initial);
  final MqttEditorResult? result;
  if (MediaQuery.sizeOf(context).width < Breakpoints.medium) {
    result = await Navigator.of(context, rootNavigator: true)
        .push<MqttEditorResult>(
          MaterialPageRoute(fullscreenDialog: true, builder: (_) => editor),
        );
  } else {
    result = await showDialog<MqttEditorResult>(
      context: context,
      builder: (_) => Dialog(
        clipBehavior: Clip.antiAlias,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640, maxHeight: 820),
          child: editor,
        ),
      ),
    );
  }
  if (result == null) return null;
  await ref
      .read(mqttProfileRepositoryProvider)
      .saveSecrets(
        result.profile.id,
        password: result.password,
        clientKeyPem: result.clientKeyPem,
        clientKeyPassword: result.clientKeyPassword,
      );
  await ref.read(mqttProfilesControllerProvider.notifier).save(result.profile);
  return result.profile;
}

class MqttProfileEditor extends ConsumerStatefulWidget {
  const new({this.initial, super.key});

  final MqttProfile? initial;

  @override
  ConsumerState<MqttProfileEditor> createState() => _MqttProfileEditorState();
}

class _MqttProfileEditorState extends ConsumerState<MqttProfileEditor> {
  final _formKey = GlobalKey<FormState>();
  late final MqttConnectionConfig _c =
      widget.initial?.config ?? const MqttConnectionConfig(host: '');

  late final _name = TextEditingController(text: widget.initial?.name ?? '');
  late final _host = TextEditingController(text: _c.simulated ? '' : _c.host);
  late final _port = TextEditingController(text: '${_c.port}');
  late final _wsPath = TextEditingController(text: _c.webSocketPath);
  late final _clientId = TextEditingController(text: _c.clientId);
  late final _username = TextEditingController(text: _c.username);
  final _password = TextEditingController();
  late final _keepAlive = TextEditingController(
    text: '${_c.keepAlive.inSeconds}',
  );
  late final _sessionExpiry = TextEditingController(
    text: '${_c.sessionExpiry.inSeconds}',
  );
  late final _timeout = TextEditingController(
    text: '${_c.connectTimeout.inSeconds}',
  );
  late final _willTopic = TextEditingController(text: _c.lastWill?.topic ?? '');
  late final _willPayload = TextEditingController(
    text: _c.lastWill?.payload ?? '',
  );
  final _keyPassword = TextEditingController();

  late bool _simulated = _c.simulated;
  late MqttTransport _transport = _c.transport;
  late MqttProtocolVersion _version = _c.protocolVersion;
  late bool _cleanStart = _c.cleanStart;
  late bool _autoReconnect = widget.initial?.autoReconnect ?? true;
  late bool _willEnabled = _c.lastWill != null;
  late MqttQosLevel _willQos = _c.lastWill?.qos ?? MqttQosLevel.atMostOnce;
  late bool _willRetain = _c.lastWill?.retain ?? false;
  late String? _caPem = _c.tls.caCertificatePem;
  late String? _clientCertPem = _c.tls.clientCertificatePem;
  late bool _acceptInvalid = _c.tls.acceptInvalidCertificates;
  late bool _passwordStored = _c.hasPassword;
  bool _clientKeyStored = false;

  /// Secret edits: null = unchanged, '' = delete.
  String? _clientKeyPem;
  bool _removePassword = false;

  @override
  void initState() {
    super.initState();
    final id = widget.initial?.id;
    if (id != null) {
      unawaited(_loadKeyState(id));
    }
  }

  Future<void> _loadKeyState(String id) async {
    final secrets = await ref
        .read(mqttProfileRepositoryProvider)
        .loadSecrets(id);
    if (mounted) {
      setState(() => _clientKeyStored = secrets.clientKeyPem != null);
    }
  }

  @override
  void dispose() {
    for (final c in [
      _name,
      _host,
      _port,
      _wsPath,
      _clientId,
      _username,
      _password,
      _keepAlive,
      _sessionExpiry,
      _timeout,
      _willTopic,
      _willPayload,
      _keyPassword,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  void _setTransport(MqttTransport transport) {
    setState(() {
      // Follow the default port unless the user chose a custom one.
      if (int.tryParse(_port.text) == _transport.defaultPort) {
        _port.text = '${transport.defaultPort}';
      }
      _transport = transport;
    });
  }

  Future<void> _loadPem(void Function(String pem) apply) async {
    final file = await ref.read(fileExchangeProvider).openText(_pemTypes);
    if (file != null && mounted) setState(() => apply(file.content));
  }

  String? _required(String? v) =>
      (v ?? '').trim().isEmpty ? context.l10n.validationRequired : null;

  String? Function(String?) _intRange(int min, int max) => (v) {
    final n = int.tryParse((v ?? '').trim());
    return n == null || n < min || n > max
        ? context.l10n.validationRange(min, max)
        : null;
  };

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final password = _password.text;
    final hasPassword =
        !_removePassword && (password.isNotEmpty || _passwordStored);
    final config = MqttConnectionConfig(
      simulated: _simulated,
      host: _simulated ? 'simulator' : _host.text.trim(),
      port: int.parse(_port.text.trim()),
      transport: _transport,
      webSocketPath: _wsPath.text.trim(),
      clientId: _clientId.text.trim(),
      username: _username.text.trim(),
      hasPassword: hasPassword && _username.text.trim().isNotEmpty,
      cleanStart: _cleanStart,
      keepAlive: Duration(seconds: int.parse(_keepAlive.text.trim())),
      sessionExpiry: Duration(seconds: int.parse(_sessionExpiry.text.trim())),
      protocolVersion: _version,
      connectTimeout: Duration(seconds: int.parse(_timeout.text.trim())),
      lastWill: _willEnabled
          ? MqttLastWill(
              topic: _willTopic.text.trim(),
              payload: _willPayload.text,
              qos: _willQos,
              retain: _willRetain,
            )
          : null,
      tls: MqttTlsSettings(
        caCertificatePem: _caPem,
        clientCertificatePem: _clientCertPem,
        acceptInvalidCertificates: _acceptInvalid,
      ),
      subscriptions: _c.subscriptions,
    );
    final initial = widget.initial;
    final profile = initial == null
        ? MqttProfile(
            id: MqttProfilesController.newId(),
            name: _name.text.trim(),
            config: config,
            createdAt: DateTime.now(),
            autoReconnect: _autoReconnect,
          )
        : initial.copyWith(
            name: _name.text.trim(),
            config: config,
            autoReconnect: _autoReconnect,
          );
    Navigator.of(context).pop(
      MqttEditorResult(
        profile,
        password: _removePassword
            ? ''
            : password.isEmpty
            ? null
            : password,
        clientKeyPem: _clientKeyPem,
        clientKeyPassword: _keyPassword.text.isEmpty ? null : _keyPassword.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final caps = ref.watch(platformCapabilitiesProvider);
    final mono = theme.textTheme.bodyMedium!.mono;
    final isNew = widget.initial == null;
    final transports = [
      for (final t in MqttTransport.values)
        if (t.webSocket || caps.supportsMqttSockets) t,
    ];
    if (!transports.contains(_transport)) _transport = transports.first;
    const gap = SizedBox(height: 12);

    Widget section(String title) => Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 12),
      child: Semantics(
        header: true,
        child: Text(
          title,
          style: theme.textTheme.titleSmall?.copyWith(
            color: theme.colorScheme.primary,
          ),
        ),
      ),
    );

    Widget pemRow({
      required String label,
      required String? value,
      required Key key,
      required void Function(String) onLoad,
      required VoidCallback onRemove,
      String? storedHint,
    }) => ListTile(
      key: key,
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      subtitle: Text(
        value != null
            ? value.trim().split('\n').first
            : storedHint ?? l10n.mqttNotSet,
        style: value != null ? theme.textTheme.bodySmall!.mono : null,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Wrap(
        children: [
          IconButton(
            tooltip: l10n.mqttLoadFile,
            icon: const Icon(Icons.file_open_outlined),
            onPressed: () => _loadPem(onLoad),
          ),
          if (value != null || storedHint != null)
            IconButton(
              tooltip: l10n.mqttRemove,
              icon: const Icon(Icons.delete_outline),
              onPressed: () => setState(onRemove),
            ),
        ],
      ),
    );

    QosDropdown qos(MqttQosLevel value, ValueChanged<MqttQosLevel> onChanged) =>
        QosDropdown(value: value, onChanged: onChanged);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.close),
          tooltip: l10n.actionCancel,
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(isNew ? l10n.mqttNewProfile : l10n.mqttEditProfile),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilledButton(
              key: const Key('mqttEditor.save'),
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
                key: const Key('mqttEditor.name'),
                controller: _name,
                autofocus: isNew,
                decoration: InputDecoration(labelText: l10n.fieldName),
                validator: _required,
              ),
              gap,
              SegmentedButton<bool>(
                key: const Key('mqttEditor.type'),
                segments: [
                  ButtonSegment(
                    value: false,
                    icon: const Icon(Icons.dns_outlined),
                    label: Text(l10n.mqttTypeBroker),
                  ),
                  ButtonSegment(
                    value: true,
                    icon: const Icon(Icons.science_outlined),
                    label: Text(l10n.mqttTypeSimulator),
                  ),
                ],
                selected: {_simulated},
                onSelectionChanged: (s) =>
                    setState(() => _simulated = s.single),
              ),
              if (_simulated) ...[
                gap,
                Text(l10n.mqttSimulatorHint, style: theme.textTheme.bodySmall),
              ] else ...[
                section(l10n.mqttSectionBroker),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextFormField(
                        key: const Key('mqttEditor.host'),
                        controller: _host,
                        style: mono,
                        keyboardType: TextInputType.url,
                        decoration: InputDecoration(labelText: l10n.fieldHost),
                        validator: _required,
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 110,
                      child: TextFormField(
                        key: const Key('mqttEditor.port'),
                        controller: _port,
                        style: mono,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: InputDecoration(labelText: l10n.fieldPort),
                        validator: _intRange(1, 65535),
                      ),
                    ),
                  ],
                ),
                gap,
                Text(
                  l10n.mqttFieldTransport,
                  style: theme.textTheme.labelLarge,
                ),
                const SizedBox(height: 6),
                SegmentedButton<MqttTransport>(
                  key: const Key('mqttEditor.transport'),
                  showSelectedIcon: false,
                  segments: [
                    for (final t in transports)
                      ButtonSegment(value: t, label: Text(transportLabel(t))),
                  ],
                  selected: {_transport},
                  onSelectionChanged: (s) => _setTransport(s.single),
                ),
                if (!caps.supportsMqttSockets)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      l10n.mqttWebOnlyWs,
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                if (_transport.webSocket) ...[
                  gap,
                  TextFormField(
                    key: const Key('mqttEditor.wsPath'),
                    controller: _wsPath,
                    style: mono,
                    decoration: InputDecoration(
                      labelText: l10n.mqttFieldWsPath,
                    ),
                  ),
                ],
              ],
              gap,
              Text(l10n.mqttFieldVersion, style: theme.textTheme.labelLarge),
              const SizedBox(height: 6),
              SegmentedButton<MqttProtocolVersion>(
                key: const Key('mqttEditor.version'),
                showSelectedIcon: false,
                segments: [
                  for (final v in MqttProtocolVersion.values)
                    ButtonSegment(
                      value: v,
                      label: Text('MQTT ${versionLabel(v)}'),
                    ),
                ],
                selected: {_version},
                onSelectionChanged: (s) => setState(() => _version = s.single),
              ),
              section(l10n.mqttSectionAuth),
              TextFormField(
                key: const Key('mqttEditor.clientId'),
                controller: _clientId,
                style: mono,
                decoration: InputDecoration(
                  labelText: l10n.mqttFieldClientId,
                  helperText: l10n.mqttClientIdAuto,
                  suffixIcon: IconButton(
                    tooltip: l10n.mqttGenerateClientId,
                    icon: const Icon(Icons.casino_outlined),
                    onPressed: () =>
                        setState(() => _clientId.text = generateClientId()),
                  ),
                ),
              ),
              gap,
              TextFormField(
                key: const Key('mqttEditor.username'),
                controller: _username,
                autocorrect: false,
                decoration: InputDecoration(labelText: l10n.mqttFieldUsername),
              ),
              gap,
              TextFormField(
                key: const Key('mqttEditor.password'),
                controller: _password,
                obscureText: true,
                autocorrect: false,
                enableSuggestions: false,
                decoration: InputDecoration(
                  labelText: l10n.mqttFieldPassword,
                  helperText: _passwordStored && !_removePassword
                      ? l10n.mqttPasswordStored
                      : l10n.mqttPasswordSecure,
                  helperMaxLines: 2,
                  suffixIcon: _passwordStored && !_removePassword
                      ? IconButton(
                          key: const Key('mqttEditor.removePassword'),
                          tooltip: l10n.mqttRemovePassword,
                          icon: const Icon(Icons.key_off_outlined),
                          onPressed: () => setState(() {
                            _removePassword = true;
                            _passwordStored = false;
                          }),
                        )
                      : null,
                ),
                onChanged: (v) {
                  if (v.isNotEmpty && _removePassword) {
                    setState(() => _removePassword = false);
                  }
                },
              ),
              section(l10n.mqttSectionSession),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.mqttCleanStart),
                subtitle: Text(l10n.mqttCleanStartHint),
                value: _cleanStart,
                onChanged: (v) => setState(() => _cleanStart = v),
              ),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  SizedBox(
                    width: 150,
                    child: TextFormField(
                      key: const Key('mqttEditor.keepAlive'),
                      controller: _keepAlive,
                      style: mono,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: InputDecoration(
                        labelText: l10n.mqttFieldKeepAlive,
                      ),
                      validator: _intRange(0, 65535),
                    ),
                  ),
                  if (_version == MqttProtocolVersion.v5)
                    SizedBox(
                      width: 230,
                      child: TextFormField(
                        key: const Key('mqttEditor.sessionExpiry'),
                        controller: _sessionExpiry,
                        style: mono,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: InputDecoration(
                          labelText: l10n.mqttFieldSessionExpiry,
                        ),
                        validator: _intRange(0, 0xFFFFFFFF),
                      ),
                    ),
                  SizedBox(
                    width: 190,
                    child: TextFormField(
                      key: const Key('mqttEditor.timeout'),
                      controller: _timeout,
                      style: mono,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: InputDecoration(
                        labelText: l10n.mqttFieldConnectTimeout,
                      ),
                      validator: _intRange(1, 120),
                    ),
                  ),
                ],
              ),
              SwitchListTile(
                key: const Key('mqttEditor.autoReconnect'),
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.mqttAutoReconnect),
                value: _autoReconnect,
                onChanged: (v) => setState(() => _autoReconnect = v),
              ),
              section(l10n.mqttSectionWill),
              SwitchListTile(
                key: const Key('mqttEditor.willEnabled'),
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.mqttWillEnabled),
                value: _willEnabled,
                onChanged: (v) => setState(() => _willEnabled = v),
              ),
              if (_willEnabled) ...[
                TextFormField(
                  key: const Key('mqttEditor.willTopic'),
                  controller: _willTopic,
                  style: mono,
                  decoration: InputDecoration(labelText: l10n.mqttFieldTopic),
                  validator: (v) =>
                      topicErrorText(l10n, validateTopicName((v ?? '').trim())),
                ),
                gap,
                TextFormField(
                  controller: _willPayload,
                  style: mono,
                  decoration: InputDecoration(labelText: l10n.mqttFieldPayload),
                ),
                gap,
                Row(
                  children: [
                    qos(_willQos, (q) => setState(() => _willQos = q)),
                    const SizedBox(width: 16),
                    Checkbox(
                      value: _willRetain,
                      onChanged: (v) => setState(() => _willRetain = v!),
                    ),
                    Text(l10n.mqttRetain),
                  ],
                ),
              ],
              if (!_simulated && _transport.secure) ...[
                section(l10n.mqttSectionTls),
                Text(l10n.mqttTlsVerify, style: theme.textTheme.bodySmall),
                if (_transport == MqttTransport.wss)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      l10n.mqttWssCertLimit,
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                if (_transport == MqttTransport.tls) ...[
                  pemRow(
                    key: const Key('mqttEditor.ca'),
                    label: l10n.mqttCaCert,
                    value: _caPem,
                    onLoad: (pem) => _caPem = pem,
                    onRemove: () => _caPem = null,
                  ),
                  pemRow(
                    key: const Key('mqttEditor.clientCert'),
                    label: l10n.mqttClientCert,
                    value: _clientCertPem,
                    onLoad: (pem) => _clientCertPem = pem,
                    onRemove: () => _clientCertPem = null,
                  ),
                  pemRow(
                    key: const Key('mqttEditor.clientKey'),
                    label: l10n.mqttClientKey,
                    // The key itself is never shown.
                    value: null,
                    storedHint: _clientKeyPem == ''
                        ? null
                        : _clientKeyPem != null || _clientKeyStored
                        ? l10n.mqttClientKeyStored
                        : null,
                    onLoad: (pem) => _clientKeyPem = pem,
                    onRemove: () {
                      _clientKeyPem = '';
                      _clientKeyStored = false;
                    },
                  ),
                  TextFormField(
                    controller: _keyPassword,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: l10n.mqttClientKeyPassword,
                      helperText: l10n.mqttPasswordSecure,
                    ),
                  ),
                ],
                gap,
                SwitchListTile(
                  key: const Key('mqttEditor.acceptInvalid'),
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.mqttAcceptInvalid),
                  value: _acceptInvalid,
                  onChanged: (v) => setState(() => _acceptInvalid = v),
                ),
                if (_acceptInvalid)
                  Container(
                    key: const Key('mqttEditor.insecureWarning'),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.warning_amber,
                          color: theme.colorScheme.onErrorContainer,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            l10n.mqttAcceptInvalidWarning,
                            style: TextStyle(
                              color: theme.colorScheme.onErrorContainer,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

/// QoS 0/1/2 selector shared by editor, subscriptions and publish.
class QosDropdown extends StatelessWidget {
  const new({required this.value, required this.onChanged, super.key});

  final MqttQosLevel value;
  final ValueChanged<MqttQosLevel>? onChanged;

  @override
  Widget build(BuildContext context) => DropdownButton<MqttQosLevel>(
    value: value,
    items: [
      for (final q in MqttQosLevel.values)
        DropdownMenuItem(value: q, child: Text('QoS ${q.value}')),
    ],
    onChanged: onChanged == null ? null : (q) => onChanged!(q!),
  );
}
