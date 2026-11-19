import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:modbus_explorer/core/storage/document_store.dart';
import 'package:modbus_explorer/core/storage/key_value_store.dart';
import 'package:modbus_explorer/core/storage/secret_store.dart';
import 'package:modbus_explorer/modules/modbus/protocol/data/modbus_providers.dart';
import 'package:modbus_explorer/modules/modbus/simulator/data/simulator_bank.dart';

/// Provider container with in-memory storage and a non-animated simulator.
ProviderContainer createTestContainer({
  InMemoryDocumentStore? documents,
  SimulatorBank? bank,
  SecretStore? secrets,
  List<Override> overrides = const [],
}) => ProviderContainer(
  overrides: [
    keyValueStoreProvider.overrideWithValue(InMemoryKeyValueStore()),
    documentStoreProvider.overrideWithValue(
      documents ?? InMemoryDocumentStore(),
    ),
    simulatorBankProvider.overrideWithValue(bank ?? SimulatorBank.demo()),
    // Keychain/Keystore plugins are unavailable in tests.
    secretStoreProvider.overrideWithValue(secrets ?? InMemorySecretStore()),
    ...overrides,
  ],
);
