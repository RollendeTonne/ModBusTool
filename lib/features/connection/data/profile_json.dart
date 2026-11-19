import 'package:modbus_explorer/features/connection/domain/connection_config.dart';
import 'package:modbus_explorer/features/connection/domain/connection_profile.dart';
import 'package:modbus_explorer/features/connection/domain/serial_settings.dart';

/// Versioned on-disk format; bump [profilesSchemaVersion] on breaking
/// changes and migrate in [profilesFromJson].
const profilesSchemaVersion = 1;

Map<String, Object?> profilesToJson(List<ConnectionProfile> profiles) => {
  'version': profilesSchemaVersion,
  'profiles': [for (final p in profiles) profileToJson(p)],
};

/// Skips entries it cannot read instead of failing, so one broken profile
/// (e.g. edited by hand) doesn't lose all others.
List<ConnectionProfile> profilesFromJson(Object? json) {
  if (json is! Map || json['profiles'] is! List) return const [];
  final result = <ConnectionProfile>[];
  for (final entry in json['profiles'] as List) {
    final profile = _tryParse(entry);
    if (profile != null) result.add(profile);
  }
  return result;
}

ConnectionProfile? _tryParse(Object? entry) {
  try {
    return profileFromJson(entry! as Map<String, Object?>);
  } on Object {
    return null;
  }
}

Map<String, Object?> profileToJson(ConnectionProfile p) {
  final config = p.config;
  return {
    'id': p.id,
    'name': p.name,
    'createdAt': p.createdAt.toUtc().toIso8601String(),
    if (p.lastUsedAt != null)
      'lastUsedAt': p.lastUsedAt!.toUtc().toIso8601String(),
    'autoReconnect': p.autoReconnect,
    'type': config.kind.name,
    'unitId': config.options.unitId,
    'timeoutMs': config.options.timeout.inMilliseconds,
    'retries': config.options.retries,
    ...switch (config) {
      TcpConnectionConfig(:final host, :final port) ||
      RtuOverTcpConnectionConfig(
        :final host,
        :final port,
      ) => {'host': host, 'port': port},
      RtuConnectionConfig(:final serial) => {'serial': _serialToJson(serial)},
      SimulatorConnectionConfig() => {
        'framing': config.framing.name,
        'latencyMs': config.latency.inMilliseconds,
        'dropProbability': config.dropProbability,
        'corruptProbability': config.corruptProbability,
      },
    },
  };
}

ConnectionProfile profileFromJson(Map<String, Object?> json) {
  final options = RequestOptions(
    unitId: json['unitId']! as int,
    timeout: Duration(milliseconds: json['timeoutMs']! as int),
    retries: json['retries']! as int,
  );
  final kind = ConnectionKind.values.byName(json['type']! as String);
  final config = switch (kind) {
    ConnectionKind.tcp => TcpConnectionConfig(
      host: json['host']! as String,
      port: json['port']! as int,
      options: options,
    ),
    ConnectionKind.rtuOverTcp => RtuOverTcpConnectionConfig(
      host: json['host']! as String,
      port: json['port']! as int,
      options: options,
    ),
    ConnectionKind.rtu => RtuConnectionConfig(
      serial: _serialFromJson(json['serial']! as Map<String, Object?>),
      options: options,
    ),
    ConnectionKind.simulator => SimulatorConnectionConfig(
      framing: SimulatorFraming.values.byName(json['framing']! as String),
      latency: Duration(milliseconds: json['latencyMs']! as int),
      dropProbability: (json['dropProbability']! as num).toDouble(),
      corruptProbability: (json['corruptProbability']! as num).toDouble(),
      options: options,
    ),
  };
  final lastUsed = json['lastUsedAt'] as String?;
  return ConnectionProfile(
    id: json['id']! as String,
    name: json['name']! as String,
    config: config,
    createdAt: DateTime.parse(json['createdAt']! as String),
    lastUsedAt: lastUsed == null ? null : DateTime.parse(lastUsed),
    autoReconnect: json['autoReconnect'] as bool? ?? false,
  );
}

Map<String, Object?> _serialToJson(SerialSettings s) => {
  'portName': s.portName,
  'baudRate': s.baudRate,
  'dataBits': s.dataBits,
  'parity': s.parity.name,
  'stopBits': s.stopBits,
  'rts': s.rts.name,
  'dtr': s.dtr.name,
  if (s.interFrameDelay != null)
    'interFrameDelayUs': s.interFrameDelay!.inMicroseconds,
};

SerialSettings _serialFromJson(Map<String, Object?> json) {
  final delay = json['interFrameDelayUs'] as int?;
  return SerialSettings(
    portName: json['portName']! as String,
    baudRate: json['baudRate']! as int,
    dataBits: json['dataBits']! as int,
    parity: SerialParity.values.byName(json['parity']! as String),
    stopBits: json['stopBits']! as int,
    rts: SerialLineMode.values.byName(json['rts'] as String? ?? 'unchanged'),
    dtr: SerialLineMode.values.byName(json['dtr'] as String? ?? 'unchanged'),
    interFrameDelay: delay == null ? null : Duration(microseconds: delay),
  );
}
