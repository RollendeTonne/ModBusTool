import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:modbus_explorer/core/files/file_exchange.dart';
import 'package:modbus_explorer/core/l10n/l10n.dart';
import 'package:modbus_explorer/core/platform/platform_capabilities.dart';
import 'package:modbus_explorer/core/theme/app_colors.dart';
import 'package:modbus_explorer/core/theme/app_theme.dart';
import 'package:modbus_explorer/core/widgets/error_panel.dart';
import 'package:modbus_explorer/core/widgets/snackbar.dart';
import 'package:modbus_explorer/features/connection/domain/connection_config.dart';
import 'package:modbus_explorer/features/connection/domain/connection_profile.dart';
import 'package:modbus_explorer/features/connection/presentation/connection_controller.dart';
import 'package:modbus_explorer/features/connection/presentation/modbus_error_text.dart';
import 'package:modbus_explorer/features/connection/presentation/profiles_controller.dart';
import 'package:modbus_explorer/features/interpretation/domain/matrix_export.dart';
import 'package:modbus_explorer/features/interpretation/domain/value_formatter.dart';
import 'package:modbus_explorer/features/network_scan/data/network_scanner.dart';
import 'package:modbus_explorer/features/network_scan/domain/ipv4.dart';
import 'package:modbus_explorer/features/network_scan/domain/known_ports.dart';
import 'package:modbus_explorer/features/network_scan/domain/scan_models.dart';
import 'package:modbus_explorer/features/network_scan/presentation/network_scan_controller.dart';

class NetworkScanView extends ConsumerStatefulWidget {
  const new({super.key});

  @override
  ConsumerState<NetworkScanView> createState() => _NetworkScanViewState();
}

class _NetworkScanViewState extends ConsumerState<NetworkScanView> {
  final _range = TextEditingController();
  final _ports = TextEditingController(text: defaultScanPorts.join(', '));
  final _modbusPorts = TextEditingController(
    text: defaultModbusPorts.join(', '),
  );
  final _timeout = TextEditingController(text: '300');
  bool _resolveNames = true;
  bool _onlyModbus = false;
  String? _error;

  @override
  void dispose() {
    for (final c in [_range, _ports, _modbusPorts, _timeout]) {
      c.dispose();
    }
    super.dispose();
  }

  void _start() {
    final l10n = context.l10n;
    final Ipv4Range range;
    try {
      range = Ipv4Range.parse(_range.text);
    } on FormatException {
      setState(() => _error = '${l10n.netRange}: ${l10n.invalidValue}');
      return;
    }
    if (range.length > NetworkScanController.maxAddresses) {
      setState(
        () =>
            _error = l10n.netRangeTooLarge(NetworkScanController.maxAddresses),
      );
      return;
    }
    final ports = parsePortList(_ports.text);
    final modbusPorts = _modbusPorts.text.trim().isEmpty
        ? const <int>[]
        : parsePortList(_modbusPorts.text);
    final timeout = int.tryParse(_timeout.text);
    if (ports == null || modbusPorts == null) {
      setState(() => _error = '${l10n.netPorts}: ${l10n.invalidValue}');
      return;
    }
    if (timeout == null || timeout < 20 || timeout > 5000) {
      setState(() => _error = l10n.validationRange(20, 5000));
      return;
    }
    setState(() => _error = null);
    final caps = ref.read(platformCapabilitiesProvider);
    unawaited(
      ref
          .read(networkScanControllerProvider.notifier)
          .start(
            NetworkScanConfig(
              range: range,
              // Modbus ports are always probed so they can be verified.
              ports: {...ports, ...modbusPorts}.toList()..sort(),
              modbusPorts: modbusPorts,
              timeout: Duration(milliseconds: timeout),
              resolveHostnames: _resolveNames,
              readArp: caps.supportsMacAddresses,
            ),
          ),
    );
  }

  Future<void> _connect(HostResult host) async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final identity = host.modbus!;
    final name = [
      host.hostname ?? '${host.address}',
      if (identity.product != null) identity.product,
    ].join(' · ');
    final profile = ConnectionProfile(
      id: ProfilesController.newProfileId(),
      name: name,
      config: TcpConnectionConfig(host: '${host.address}', port: identity.port),
      createdAt: DateTime.now(),
    );
    await ref.read(profilesControllerProvider.notifier).save(profile);
    await ref.read(connectionControllerProvider.notifier).connect(profile);
    messenger.showReplacing(l10n.netProfileCreated(name));
  }

  Future<void> _export(List<HostResult> hosts) async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final lines = [
      [
        'ip',
        'hostname',
        'mac',
        'open_ports',
        'modbus_port',
        'modbus_device',
      ].join(csvSeparator),
      for (final h in hosts)
        [
          '${h.address}',
          h.hostname ?? '',
          h.mac ?? '',
          h.openPorts.join(' '),
          h.modbus?.port.toString() ?? '',
          h.modbus?.summary ?? '',
        ].map((f) => quoteField(f, csvSeparator)).join(csvSeparator),
    ];
    final name = timestampedFileName('network-scan', 'csv');
    try {
      final saved = await ref
          .read(fileExchangeProvider)
          .saveText(
            suggestedName: name,
            content: lines.join('\n'),
            type: ExchangeFileType.csv,
          );
      if (saved) messenger.showReplacing(l10n.exportSaved(name));
    } on Object catch (e) {
      messenger.showReplacing(l10n.exportFailed('$e'));
    }
  }

  String _phaseLabel(ScanPhase phase) {
    final l10n = context.l10n;
    return switch (phase) {
      ScanPhase.ports => l10n.netPhasePorts,
      ScanPhase.arp => l10n.netPhaseArp,
      ScanPhase.modbus => l10n.netPhaseModbus,
      ScanPhase.hostnames => l10n.netPhaseHostnames,
      ScanPhase.done => l10n.netPhaseDone,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final mono = theme.textTheme.bodyMedium!.mono;
    final caps = ref.watch(platformCapabilitiesProvider);
    final state = ref.watch(networkScanControllerProvider);
    final controller = ref.read(networkScanControllerProvider.notifier);
    final locals = ref.watch(localAddressesProvider).value ?? const [];
    if (_range.text.isEmpty && locals.isNotEmpty) {
      _range.text = '${locals.first.address.octets.take(3).join('.')}.0/24';
    }
    final visible = _onlyModbus
        ? state.hosts.where((h) => h.modbus != null).toList()
        : state.hosts;
    final modbusCount = state.hosts.where((h) => h.modbus != null).length;
    final elapsed = state.startedAt != null && state.finishedAt != null
        ? state.finishedAt!.difference(state.startedAt!)
        : null;

    Widget field(
      TextEditingController c,
      String label,
      double width, {
      Key? key,
      String? hint,
    }) => SizedBox(
      width: width,
      child: TextField(
        key: key,
        controller: c,
        style: mono,
        enabled: !state.isRunning,
        decoration: InputDecoration(labelText: label, hintText: hint),
      ),
    );

    return ListView(
      key: const Key('network.view'),
      padding: const EdgeInsets.all(12),
      children: [
        Text(l10n.netScanHint, style: theme.textTheme.bodySmall),
        if (caps.macAddressLimit case final limit?)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              limit == MacAddressLimit.sandbox
                  ? l10n.netScanNoMacSandbox
                  : l10n.netScanNoMac,
              style: theme.textTheme.bodySmall,
            ),
          ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            field(
              _range,
              l10n.netRange,
              260,
              key: const Key('network.range'),
              hint: l10n.netRangeHint,
            ),
            field(_ports, l10n.netPorts, 320, key: const Key('network.ports')),
            field(
              _modbusPorts,
              l10n.netModbusPorts,
              180,
              key: const Key('network.modbusPorts'),
            ),
            field(
              _timeout,
              l10n.scanTimeout,
              110,
              key: const Key('network.timeout'),
            ),
          ],
        ),
        if (locals.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              for (final local in locals)
                ActionChip(
                  avatar: const Icon(Icons.lan_outlined, size: 18),
                  label: Text('${local.interface} · ${local.address}'),
                  onPressed: state.isRunning
                      ? null
                      : () => setState(
                          () => _range.text =
                              '${local.address.octets.take(3).join('.')}.0/24',
                        ),
                ),
            ],
          ),
        ],
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          title: Text(l10n.netResolveNames),
          value: _resolveNames,
          onChanged: state.isRunning
              ? null
              : (v) => setState(() => _resolveNames = v!),
        ),
        if (_error != null)
          Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            if (state.isRunning)
              OutlinedButton.icon(
                key: const Key('network.cancel'),
                onPressed: controller.cancel,
                icon: const Icon(Icons.stop),
                label: Text(l10n.actionCancel),
              )
            else
              FilledButton.icon(
                key: const Key('network.start'),
                onPressed: _start,
                icon: const Icon(Icons.travel_explore),
                label: Text(l10n.netStart),
              ),
            Text(
              state.isRunning
                  ? l10n.netProgress(
                      _phaseLabel(state.phase),
                      state.done,
                      state.total,
                      state.hosts.length,
                    )
                  : [
                      if (state.cancelled) l10n.scanCancelled,
                      if (elapsed != null)
                        l10n.netSummary(
                          state.hosts.length,
                          modbusCount,
                          (elapsed.inMilliseconds / 1000).toStringAsFixed(1),
                        ),
                    ].join(' · '),
              key: const Key('network.status'),
            ),
          ],
        ),
        if (state.isRunning) ...[
          const SizedBox(height: 8),
          LinearProgressIndicator(value: state.progress),
        ],
        if (state.error case final error?) ...[
          const SizedBox(height: 12),
          Builder(
            builder: (context) {
              final text = describeError(l10n, error);
              return ErrorPanel(
                title: text.title,
                hint: text.hint,
                detail: text.detail,
                dense: true,
              );
            },
          ),
        ],
        if (state.arpEmpty && state.hosts.isNotEmpty && !state.isRunning)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(
              l10n.netArpEmptyHint,
              key: const Key('network.arpEmpty'),
              style: TextStyle(color: context.appColors.warning),
            ),
          ),
        if (state.hosts.isNotEmpty) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              FilterChip(
                key: const Key('network.onlyModbus'),
                label: Text(l10n.netOnlyModbus),
                selected: _onlyModbus,
                onSelected: (v) => setState(() => _onlyModbus = v),
              ),
              const Spacer(),
              TextButton.icon(
                key: const Key('network.export'),
                onPressed: state.isRunning ? null : () => _export(state.hosts),
                icon: const Icon(Icons.save_alt),
                label: Text(l10n.netExport),
              ),
            ],
          ),
        ],
        const SizedBox(height: 8),
        if (!state.isRunning && state.finishedAt != null && state.hosts.isEmpty)
          Text(l10n.netNoHosts),
        for (final host in visible)
          _HostTile(
            key: ValueKey('network.host.${host.address}'),
            host: host,
            showMac: caps.supportsMacAddresses,
            onConnect: host.modbus == null ? null : () => _connect(host),
          ),
      ],
    );
  }
}

class _HostTile extends StatelessWidget {
  const new({
    required this.host,
    required this.showMac,
    required this.onConnect,
    super.key,
  });

  final HostResult host;
  final bool showMac;
  final VoidCallback? onConnect;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final mono = theme.textTheme.bodyMedium!.mono;
    final modbus = host.modbus;

    return Card.outlined(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              modbus != null ? Icons.memory : Icons.devices_other,
              color: modbus != null ? theme.colorScheme.primary : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      SelectableText(
                        '${host.address}',
                        style: mono.copyWith(fontWeight: FontWeight.w700),
                      ),
                      if (host.hostname != null) Text(host.hostname!),
                      if (host.isLocal)
                        Text(
                          '(${l10n.netThisDevice})',
                          style: theme.textTheme.bodySmall,
                        ),
                    ],
                  ),
                  if (showMac)
                    SelectableText(
                      host.mac ?? l10n.netNoMac,
                      style: theme.textTheme.bodySmall!.mono.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  const SizedBox(height: 6),
                  if (host.openPorts.isEmpty)
                    Text(l10n.netNoOpenPorts, style: theme.textTheme.bodySmall)
                  else
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (final port in host.openPorts)
                          _PortChip(port: port, isModbus: modbus?.port == port),
                      ],
                    ),
                  if (modbus != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      [
                        l10n.netModbusVerified(modbus.port),
                        if (modbus.summary.isNotEmpty) modbus.summary,
                        if (modbus.exceptionCode != null)
                          l10n.netModbusException(
                            formatHex(modbus.exceptionCode!, digits: 2),
                          ),
                      ].join(' · '),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: context.appColors.success,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (onConnect != null)
              FilledButton.tonalIcon(
                key: Key('network.connect.${host.address}'),
                onPressed: onConnect,
                icon: const Icon(Icons.link),
                label: Text(l10n.netConnect),
              ),
          ],
        ),
      ),
    );
  }
}

class _PortChip extends StatelessWidget {
  const new({required this.port, required this.isModbus});

  final int port;
  final bool isModbus;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = portName(port);
    // Port 502 stands out: it is what this tool is about.
    final highlight = isModbus || port == 502;
    return Semantics(
      label: 'Port $port${name == null ? '' : ' $name'}',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: highlight
              ? theme.colorScheme.primaryContainer
              : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          name == null ? '$port' : '$port $name',
          style: theme.textTheme.labelMedium!.mono.copyWith(
            color: highlight
                ? theme.colorScheme.onPrimaryContainer
                : theme.colorScheme.onSurfaceVariant,
            fontWeight: highlight ? FontWeight.w700 : null,
          ),
        ),
      ),
    );
  }
}
