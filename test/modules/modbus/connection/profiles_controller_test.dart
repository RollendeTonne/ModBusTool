import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:modbus_explorer/core/storage/document_store.dart';
import 'package:modbus_explorer/modules/modbus/connection/data/profile_repository.dart';
import 'package:modbus_explorer/modules/modbus/connection/domain/connection_config.dart';
import 'package:modbus_explorer/modules/modbus/connection/domain/connection_profile.dart';
import 'package:modbus_explorer/modules/modbus/connection/presentation/profiles_controller.dart';

import '../../../helpers/container.dart';

ConnectionProfile profile(String id, String name, {DateTime? lastUsed}) =>
    ConnectionProfile(
      id: id,
      name: name,
      config: TcpConnectionConfig(host: '$name.local'),
      createdAt: DateTime.utc(2026),
      lastUsedAt: lastUsed,
    );

void main() {
  test('first start seeds and persists a simulator profile', () async {
    final documents = InMemoryDocumentStore();
    final container = createTestContainer(documents: documents);
    addTearDown(container.dispose);
    final profiles = await container.read(profilesControllerProvider.future);
    expect(profiles.single.config, isA<SimulatorConnectionConfig>());
    expect(documents.documents[ProfileRepository.documentName], isNotNull);
  });

  test('an intentionally empty list is not re-seeded', () async {
    final container = createTestContainer(
      documents: InMemoryDocumentStore({
        ProfileRepository.documentName: jsonEncode({
          'version': 1,
          'profiles': <Object>[],
        }),
      }),
    );
    addTearDown(container.dispose);
    expect(await container.read(profilesControllerProvider.future), isEmpty);
  });

  test('save, duplicate, mark used and delete keep the list sorted', () async {
    final documents = InMemoryDocumentStore({
      ProfileRepository.documentName: jsonEncode({
        'version': 1,
        'profiles': <Object>[],
      }),
    });
    final container = createTestContainer(documents: documents);
    addTearDown(container.dispose);
    await container.read(profilesControllerProvider.future);
    final controller = container.read(profilesControllerProvider.notifier);

    await controller.save(profile('b', 'beta'));
    await controller.save(profile('a', 'Alpha'));
    List<String> names() => container
        .read(profilesControllerProvider)
        .value!
        .map((p) => p.name)
        .toList();
    expect(names(), ['Alpha', 'beta']);

    final copy = await controller.duplicate(
      profile('b', 'beta', lastUsed: DateTime.utc(2026, 3)),
      name: 'beta (copy)',
    );
    expect(copy.lastUsedAt, isNull);
    expect(copy.id, isNot('b'));
    expect(names(), ['Alpha', 'beta', 'beta (copy)']);

    await controller.markUsed('b');
    expect(names().first, 'beta');

    await controller.save(profile('a', 'Alpha renamed'));
    expect(names(), contains('Alpha renamed'));
    expect(names(), hasLength(3));

    await controller.delete('a');
    expect(names(), ['beta', 'beta (copy)']);

    final reloaded = await ProfileRepository(documents).load();
    expect(reloaded!.map((p) => p.name), ['beta', 'beta (copy)']);
  });

  test('generated IDs are unique', () {
    final ids = {
      for (var i = 0; i < 200; i++) ProfilesController.newProfileId(),
    };
    expect(ids, hasLength(200));
  });
}
