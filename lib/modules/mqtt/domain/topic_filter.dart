// Topic and topic-filter rules of MQTT 3.1.1 §4.7 / MQTT 5 §4.7.

/// `null` if [topic] is a valid topic name for publishing, else the reason.
TopicError? validateTopicName(String topic) {
  if (topic.isEmpty) return TopicError.empty;
  if (topic.contains('+') || topic.contains('#')) return TopicError.wildcard;
  return _common(topic);
}

/// `null` if [filter] is a valid subscription filter, else the reason.
TopicError? validateTopicFilter(String filter) {
  if (filter.isEmpty) return TopicError.empty;
  final levels = filter.split('/');
  for (var i = 0; i < levels.length; i++) {
    final level = levels[i];
    if (level.contains('#') && (level != '#' || i != levels.length - 1)) {
      return TopicError.misplacedMultiLevel;
    }
    if (level.contains('+') && level != '+') {
      return TopicError.misplacedSingleLevel;
    }
  }
  return _common(filter);
}

TopicError? _common(String s) {
  if (s.contains('\u0000')) return TopicError.nullCharacter;
  // UTF-8 encoded length is limited to 65535 bytes.
  if (s.length > 65535 || _utf8Length(s) > 65535) return TopicError.tooLong;
  return null;
}

int _utf8Length(String s) {
  var length = 0;
  for (final rune in s.runes) {
    length += rune < 0x80
        ? 1
        : rune < 0x800
        ? 2
        : rune < 0x10000
        ? 3
        : 4;
  }
  return length;
}

enum TopicError {
  empty,
  wildcard,
  misplacedMultiLevel,
  misplacedSingleLevel,
  nullCharacter,
  tooLong,
}

/// Whether [topic] matches [filter]. Topics starting with `$` (e.g.
/// `$SYS/…`) are not matched by a filter starting with a wildcard.
bool topicMatches(String filter, String topic) {
  if (topic.startsWith(r'$') &&
      (filter.startsWith('+') || filter.startsWith('#'))) {
    return false;
  }
  final f = filter.split('/');
  final t = topic.split('/');
  for (var i = 0; i < f.length; i++) {
    final level = f[i];
    // `#` also matches the parent level: `a/#` matches `a`.
    if (level == '#') return true;
    if (i >= t.length) return false;
    if (level != '+' && level != t[i]) return false;
  }
  return f.length == t.length;
}

/// Why [topicMatches] decided as it did, for the topic tester.
enum MatchReason {
  /// Every level matched (wildcards included).
  match,

  /// `#` at the end matched the rest (or the parent level itself).
  matchMultiLevel,

  /// Level [MatchExplanation.level] differs.
  levelMismatch,

  /// The topic ends before the filter does.
  topicTooShort,

  /// The topic has more levels than the filter.
  topicTooLong,

  /// A leading wildcard never matches topics starting with `$`.
  dollarTopic,
  invalidFilter,
  invalidTopic,
}

final class MatchExplanation {
  const new(this.reason, {this.level, this.filterError, this.topicError});

  final MatchReason reason;

  /// 0-based level where the decision fell.
  final int? level;
  final TopicError? filterError;
  final TopicError? topicError;

  bool get matches =>
      reason == MatchReason.match || reason == MatchReason.matchMultiLevel;
}

/// [topicMatches] with the reason, after validating both inputs.
MatchExplanation explainMatch(String filter, String topic) {
  final filterError = validateTopicFilter(filter);
  if (filterError != null) {
    return MatchExplanation(
      MatchReason.invalidFilter,
      filterError: filterError,
    );
  }
  final topicError = validateTopicName(topic);
  if (topicError != null) {
    return MatchExplanation(MatchReason.invalidTopic, topicError: topicError);
  }
  if (topic.startsWith(r'$') &&
      (filter.startsWith('+') || filter.startsWith('#'))) {
    return const MatchExplanation(MatchReason.dollarTopic, level: 0);
  }
  final f = filter.split('/');
  final t = topic.split('/');
  for (var i = 0; i < f.length; i++) {
    if (f[i] == '#') {
      return MatchExplanation(MatchReason.matchMultiLevel, level: i);
    }
    if (i >= t.length) {
      return MatchExplanation(MatchReason.topicTooShort, level: i);
    }
    if (f[i] != '+' && f[i] != t[i]) {
      return MatchExplanation(MatchReason.levelMismatch, level: i);
    }
  }
  return f.length == t.length
      ? const MatchExplanation(MatchReason.match)
      : MatchExplanation(MatchReason.topicTooLong, level: f.length);
}
