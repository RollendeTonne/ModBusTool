import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:modbus_explorer/core/l10n/l10n.dart';
import 'package:modbus_explorer/core/storage/key_value_store.dart';
import 'package:modbus_explorer/core/theme/app_theme.dart';
import 'package:modbus_explorer/core/widgets/snackbar.dart';
import 'package:modbus_explorer/modules/mqtt/domain/mqtt_config.dart';
import 'package:modbus_explorer/modules/mqtt/domain/mqtt_message.dart';
import 'package:modbus_explorer/modules/mqtt/domain/payload_codec.dart';
import 'package:modbus_explorer/modules/mqtt/domain/publish_template.dart';
import 'package:modbus_explorer/modules/mqtt/domain/topic_filter.dart';
import 'package:modbus_explorer/modules/mqtt/presentation/mqtt_connection_controller.dart';
import 'package:modbus_explorer/modules/mqtt/presentation/mqtt_profile_editor.dart';
import 'package:modbus_explorer/modules/mqtt/presentation/mqtt_publish_draft.dart';
import 'package:modbus_explorer/modules/mqtt/presentation/mqtt_texts.dart';
import 'package:modbus_explorer/modules/mqtt/presentation/mqtt_topic_tree_controller.dart';
import 'package:modbus_explorer/modules/mqtt/presentation/publish_templates_controller.dart';

const _confirmKey = 'mqtt.confirmOverwrite';

/// Topic, payload (text/JSON/hex/Base64), QoS, retain, MQTT 5 properties.
class MqttPublishPanel extends ConsumerStatefulWidget {
  const new({super.key});

  @override
  ConsumerState<MqttPublishPanel> createState() => _MqttPublishPanelState();
}

class _MqttPublishPanelState extends ConsumerState<MqttPublishPanel> {
  final _topic = TextEditingController();
  final _payload = TextEditingController();
  final _contentType = TextEditingController();
  final _responseTopic = TextEditingController();
  final _correlation = TextEditingController();
  final _expiry = TextEditingController();
  final _userProps = TextEditingController();
  PayloadFormat _format = PayloadFormat.text;
  MqttQosLevel _qos = MqttQosLevel.atMostOnce;
  bool _retain = false;
  String? _topicError;
  String? _payloadError;

  @override
  void dispose() {
    for (final c in [
      _topic,
      _payload,
      _contentType,
      _responseTopic,
      _correlation,
      _expiry,
      _userProps,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  KeyValueStore get _store => ref.read(keyValueStoreProvider);
  bool get _confirmOverwrite => _store.getBool(_confirmKey) ?? true;

  MqttMessageProperties _properties() {
    final expiry = int.tryParse(_expiry.text.trim());
    final correlation = _correlation.text;
    return MqttMessageProperties(
      contentType: _contentType.text.trim().isEmpty
          ? null
          : _contentType.text.trim(),
      responseTopic: _responseTopic.text.trim().isEmpty
          ? null
          : _responseTopic.text.trim(),
      correlationData: correlation.isEmpty
          ? null
          : Uint8List.fromList(utf8.encode(correlation)),
      messageExpiry: expiry == null || expiry <= 0
          ? null
          : Duration(seconds: expiry),
      userProperties: [
        for (final line in _userProps.text.split('\n'))
          if (line.contains('='))
            (
              line.substring(0, line.indexOf('=')).trim(),
              line.substring(line.indexOf('=') + 1).trim(),
            ),
      ],
    );
  }

  /// Validates inputs; `null` if invalid.
  (String, Uint8List)? _validated() {
    final l10n = context.l10n;
    final topic = _topic.text.trim();
    final topicError = topicErrorText(l10n, validateTopicName(topic));
    Uint8List? payload;
    String? payloadError;
    try {
      payload = encodePayload(_payload.text, _format);
    } on FormatException catch (e) {
      payloadError = l10n.mqttPayloadInvalid(e.message);
    }
    setState(() {
      _topicError = topicError;
      _payloadError = payloadError;
    });
    if (topicError != null || payload == null) return null;
    return (topic, payload);
  }

  /// Received before: the tree knows every topic, unlike the bounded log.
  bool _isKnownTopic(String topic) =>
      ref.read(mqttTopicTreeControllerProvider).tree.find(topic)?.isTopic ??
      false;

  Future<void> _publish() async {
    final input = _validated();
    if (input == null) return;
    final (topic, payload) = input;
    if (_confirmOverwrite && _isKnownTopic(topic) && !await _confirm(topic)) {
      return;
    }
    if (!mounted) return;
    final v5 =
        ref
            .read(mqttConnectionControllerProvider)
            .profile
            ?.config
            .protocolVersion ==
        MqttProtocolVersion.v5;
    _send(
      MqttOutgoingMessage(
        topic: topic,
        payload: payload,
        qos: _qos,
        retain: _retain,
        properties: v5 ? _properties() : MqttMessageProperties.none,
      ),
      context.l10n.mqttPublished(topic, payload.length),
    );
  }

  void _send(MqttOutgoingMessage message, String confirmation) {
    final messenger = ScaffoldMessenger.of(context);
    try {
      ref.read(mqttConnectionControllerProvider.notifier).publish(message);
      messenger.showReplacing(confirmation);
    } on Object catch (e) {
      messenger.showReplacing('$e');
    }
  }

  Future<bool> _confirm(String topic) async {
    final l10n = context.l10n;
    var dontAsk = false;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(l10n.mqttOverwriteTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.mqttOverwriteText(topic)),
              CheckboxListTile(
                key: const Key('mqtt.dontAskAgain'),
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.mqttDontAskAgain),
                value: dontAsk,
                onChanged: (v) => setDialogState(() => dontAsk = v!),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n.actionCancel),
            ),
            FilledButton(
              key: const Key('mqtt.overwriteConfirm'),
              onPressed: () => Navigator.pop(context, true),
              child: Text(l10n.mqttPublishAction),
            ),
          ],
        ),
      ),
    );
    if ((ok ?? false) && dontAsk) {
      await _store.setBool(_confirmKey, value: false);
      if (mounted) setState(() {});
    }
    return ok ?? false;
  }

  PublishTemplate _currentTemplate(String name) => PublishTemplate(
    id: PublishTemplatesController.newId(),
    name: name,
    topic: _topic.text.trim(),
    payload: _payload.text,
    format: _format,
    qos: _qos,
    retain: _retain,
    contentType: _contentType.text,
    responseTopic: _responseTopic.text,
    correlationData: _correlation.text,
    messageExpiry: _expiry.text,
    userProperties: _userProps.text,
  );

  void _loadTemplate(PublishTemplate t) {
    setState(() {
      _topic.text = t.topic;
      _payload.text = t.payload;
      _format = t.format;
      _qos = t.qos;
      _retain = t.retain;
      _contentType.text = t.contentType;
      _responseTopic.text = t.responseTopic;
      _correlation.text = t.correlationData;
      _expiry.text = t.messageExpiry;
      _userProps.text = t.userProperties;
      _topicError = null;
      _payloadError = null;
    });
    ScaffoldMessenger.of(context)
        .showReplacing(context.l10n.mqttTemplateLoaded(t.name));
  }

  Future<void> _saveTemplate() async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final name = await showDialog<String>(
      context: context,
      builder: (_) => _TemplateNameDialog(initial: _topic.text.trim()),
    );
    final trimmed = name?.trim() ?? '';
    if (trimmed.isEmpty) return;
    await ref
        .read(publishTemplatesProvider.notifier)
        .save(_currentTemplate(trimmed));
    messenger.showReplacing(l10n.mqttTemplateSaved(trimmed));
  }

  Widget _templates(BuildContext context) {
    final l10n = context.l10n;
    final templates = ref.watch(publishTemplatesProvider).value ?? const [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.mqttTemplates, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final t in templates)
              InputChip(
                key: Key('mqtt.template.${t.name}'),
                label: Text(t.name),
                tooltip: t.topic,
                onPressed: () => _loadTemplate(t),
                onDeleted: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  await ref
                      .read(publishTemplatesProvider.notifier)
                      .delete(t.id);
                  messenger.showReplacing(l10n.mqttTemplateDeleted(t.name));
                },
              ),
            ActionChip(
              key: const Key('mqtt.template.save'),
              avatar: const Icon(Icons.bookmark_add_outlined, size: 18),
              label: Text(l10n.mqttTemplateSave),
              onPressed: _saveTemplate,
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _clearRetained() async {
    final l10n = context.l10n;
    final topic = _topic.text.trim();
    final error = topicErrorText(l10n, validateTopicName(topic));
    setState(() => _topicError = error);
    if (error != null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.delete_forever_outlined),
        title: Text(l10n.mqttClearRetained),
        content: Text(l10n.mqttClearRetainedConfirm(topic)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.actionCancel),
          ),
          FilledButton(
            key: const Key('mqtt.clearRetainedConfirm'),
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.actionDelete),
          ),
        ],
      ),
    );
    if (!(ok ?? false) || !mounted) return;
    _send(
      MqttOutgoingMessage(topic: topic, payload: Uint8List(0), retain: true),
      l10n.mqttClearRetainedDone(topic),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final mono = theme.textTheme.bodyMedium!.mono;
    ref.listen(mqttPublishDraftProvider, (_, draft) {
      if (draft != null) setState(() => _topic.text = draft.topic);
    });
    final state = ref.watch(mqttConnectionControllerProvider);
    final connected = state.isConnected;
    final v5 = state.profile?.config.protocolVersion == MqttProtocolVersion.v5;
    final shortcut = defaultTargetPlatform == TargetPlatform.macOS
        ? '⌘↩'
        : 'Ctrl+Enter';

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.enter, control: true):
            _publish,
        const SingleActivator(LogicalKeyboardKey.enter, meta: true): _publish,
      },
      child: Card(
        key: const Key('mqtt.publish'),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.mqttTabPublish, style: theme.textTheme.titleSmall),
              const SizedBox(height: 8),
              _templates(context),
              const SizedBox(height: 12),
              TextField(
                key: const Key('mqtt.pub.topic'),
                controller: _topic,
                style: mono,
                decoration: InputDecoration(
                  labelText: l10n.mqttFieldTopic,
                  errorText: _topicError,
                ),
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SegmentedButton<PayloadFormat>(
                  key: const Key('mqtt.pub.format'),
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment(
                      value: PayloadFormat.text,
                      label: Text('Text'),
                    ),
                    ButtonSegment(
                      value: PayloadFormat.json,
                      label: Text('JSON'),
                    ),
                    ButtonSegment(value: PayloadFormat.hex, label: Text('Hex')),
                    ButtonSegment(
                      value: PayloadFormat.base64,
                      label: Text('Base64'),
                    ),
                  ],
                  selected: {_format},
                  onSelectionChanged: (s) => setState(() => _format = s.single),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                key: const Key('mqtt.pub.payload'),
                controller: _payload,
                style: mono,
                minLines: 3,
                maxLines: 10,
                decoration: InputDecoration(
                  labelText: l10n.mqttFieldPayload,
                  errorText: _payloadError,
                  errorMaxLines: 2,
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  QosDropdown(
                    value: _qos,
                    onChanged: (q) => setState(() => _qos = q),
                  ),
                  const SizedBox(width: 12),
                  Checkbox(
                    key: const Key('mqtt.pub.retain'),
                    value: _retain,
                    onChanged: (v) => setState(() => _retain = v!),
                  ),
                  Text(l10n.mqttRetain),
                ],
              ),
              ExpansionTile(
                tilePadding: EdgeInsets.zero,
                title: Text(l10n.mqttProperties),
                subtitle: v5 ? null : Text(l10n.mqttPropertiesV311Hint),
                children: [
                  for (final (controller, label, key) in [
                    (_contentType, l10n.mqttContentType, 'contentType'),
                    (_responseTopic, l10n.mqttResponseTopic, 'responseTopic'),
                    (_correlation, l10n.mqttCorrelationData, 'correlation'),
                    (_expiry, l10n.mqttMessageExpiry, 'expiry'),
                  ])
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: TextField(
                        key: Key('mqtt.pub.$key'),
                        controller: controller,
                        enabled: v5,
                        style: mono,
                        keyboardType: key == 'expiry'
                            ? TextInputType.number
                            : null,
                        decoration: InputDecoration(labelText: label),
                      ),
                    ),
                  TextField(
                    key: const Key('mqtt.pub.userProps'),
                    controller: _userProps,
                    enabled: v5,
                    style: mono,
                    minLines: 2,
                    maxLines: 6,
                    decoration: InputDecoration(
                      labelText: l10n.mqttUserProperties,
                      alignLabelWithHint: true,
                    ),
                  ),
                ],
              ),
              SwitchListTile(
                key: const Key('mqtt.pub.confirmToggle'),
                contentPadding: EdgeInsets.zero,
                dense: true,
                title: Text(l10n.mqttConfirmOverwrite),
                value: _confirmOverwrite,
                onChanged: (v) async {
                  await _store.setBool(_confirmKey, value: v);
                  if (mounted) setState(() {});
                },
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  Tooltip(
                    message: l10n.mqttPublishTooltip(shortcut),
                    child: FilledButton.icon(
                      key: const Key('mqtt.pub.send'),
                      onPressed: connected ? _publish : null,
                      icon: const Icon(Icons.send),
                      label: Text(l10n.mqttPublishAction),
                    ),
                  ),
                  OutlinedButton.icon(
                    key: const Key('mqtt.pub.clearRetained'),
                    onPressed: connected ? _clearRetained : null,
                    icon: const Icon(Icons.delete_forever_outlined),
                    label: Text(l10n.mqttClearRetained),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Owns its text controller: disposing it in the caller right after the
/// dialog returns would break the dialog's closing animation.
class _TemplateNameDialog extends StatefulWidget {
  const new({required this.initial});

  final String initial;

  @override
  State<_TemplateNameDialog> createState() => _TemplateNameDialogState();
}

class _TemplateNameDialogState extends State<_TemplateNameDialog> {
  late final _controller = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AlertDialog(
      title: Text(l10n.mqttTemplateSave),
      content: TextField(
        key: const Key('mqtt.template.name'),
        controller: _controller,
        autofocus: true,
        decoration: InputDecoration(
          labelText: l10n.mqttTemplateName,
          helperText: l10n.mqttTemplateReplaceHint,
        ),
        onSubmitted: (v) => Navigator.pop(context, v),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.actionCancel),
        ),
        FilledButton(
          key: const Key('mqtt.template.confirm'),
          onPressed: () => Navigator.pop(context, _controller.text),
          child: Text(l10n.actionSave),
        ),
      ],
    );
  }
}
