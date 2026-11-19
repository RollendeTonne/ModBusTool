import 'package:flutter_test/flutter_test.dart';
import 'package:modbus_explorer/modules/mqtt/domain/topic_filter.dart';

void main() {
  group('topicMatches', () {
    final cases = <(String, String, bool)>[
      ('a/b/c', 'a/b/c', true),
      ('a/b/c', 'a/b', false),
      ('a/b', 'a/b/c', false),
      ('a/+/c', 'a/x/c', true),
      ('a/+/c', 'a/x/y/c', false),
      ('a/+', 'a/', true), // empty level is a level
      ('a/+', 'a', false),
      ('+/+', '/finance', true),
      ('/+', '/finance', true),
      ('+', '/finance', false),
      ('a/#', 'a', true), // # includes the parent level
      ('a/#', 'a/b/c/d', true),
      ('#', 'a/b', true),
      ('#', '/', true),
      ('a/b/#', 'a/c', false),
      ('+/b/#', 'x/b', true),
      // Topics are case-sensitive.
      ('A/b', 'a/b', false),
      // Leading $ topics are excluded from leading wildcards.
      ('#', r'$SYS/broker/uptime', false),
      ('+/broker/uptime', r'$SYS/broker/uptime', false),
      (r'$SYS/#', r'$SYS/broker/uptime', true),
      (r'$SYS/+/uptime', r'$SYS/broker/uptime', true),
      ('a/#', r'a/$weird', true),
    ];
    for (final (filter, topic, expected) in cases) {
      test('"$filter" ${expected ? 'matches' : 'does not match'} "$topic"', () {
        expect(topicMatches(filter, topic), expected);
      });
    }
  });

  group('validateTopicFilter', () {
    test('valid filters', () {
      for (final f in ['#', '+', 'a/+/b', 'a/#', '/', '+/+/#', r'$SYS/#']) {
        expect(validateTopicFilter(f), isNull, reason: f);
      }
    });
    test('invalid filters', () {
      expect(validateTopicFilter(''), TopicError.empty);
      expect(validateTopicFilter('a/#/b'), TopicError.misplacedMultiLevel);
      expect(validateTopicFilter('a#'), TopicError.misplacedMultiLevel);
      expect(validateTopicFilter('a/b+'), TopicError.misplacedSingleLevel);
      expect(validateTopicFilter('a\u0000b'), TopicError.nullCharacter);
      expect(validateTopicFilter('x' * 65536), TopicError.tooLong);
      // 3-byte UTF-8 characters: 21846 × 3 bytes > 65535.
      expect(validateTopicFilter('€' * 21846), TopicError.tooLong);
    });
  });

  group('validateTopicName', () {
    test('wildcards are not allowed when publishing', () {
      expect(validateTopicName('a/+/b'), TopicError.wildcard);
      expect(validateTopicName('a/#'), TopicError.wildcard);
      expect(validateTopicName(''), TopicError.empty);
      expect(validateTopicName('a/b c/ü'), isNull);
      expect(validateTopicName('/'), isNull);
    });
  });
}
