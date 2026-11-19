import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meta/meta.dart';

/// A topic handed to the publish panel from elsewhere (tree, details).
/// [serial] makes repeated requests for the same topic distinct.
@immutable
final class PublishDraft {
  const new({required this.topic, required this.serial});

  final String topic;
  final int serial;
}

final class PublishDraftController extends Notifier<PublishDraft?> {
  int _serial = 0;

  @override
  PublishDraft? build() => null;

  void useTopic(String topic) =>
      state = PublishDraft(topic: topic, serial: ++_serial);
}

final mqttPublishDraftProvider =
    NotifierProvider<PublishDraftController, PublishDraft?>(
      PublishDraftController.new,
    );
