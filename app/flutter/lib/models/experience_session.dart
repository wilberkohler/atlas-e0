import 'experience_state_summary.dart';
import 'interaction_event.dart';

class ExperienceSession {
  const ExperienceSession({
    required this.sessionId,
    required this.startedAt,
    required this.endedAt,
    required this.totalDuration,
    required this.events,
    required this.totalInteractions,
    required this.uniqueElementsExplored,
    required this.mostTappedElement,
    required this.averageTimeBetweenInteractions,
    required this.completed,
    required this.repeatedExperience,
  });

  final String sessionId;
  final DateTime startedAt;
  final DateTime endedAt;
  final Duration totalDuration;
  final List<InteractionEvent> events;
  final int totalInteractions;
  final List<String> uniqueElementsExplored;
  final String? mostTappedElement;
  final Duration averageTimeBetweenInteractions;
  final bool completed;
  final bool repeatedExperience;

  factory ExperienceSession.fromSummary({
    required ExperienceStateSummary summary,
    required bool repeatedExperience,
  }) {
    final startedAt = summary.startedAt ?? DateTime.now();
    final endedAt = summary.completedAt ?? DateTime.now();
    final events = List<InteractionEvent>.unmodifiable(summary.events);
    final elementCounts = <String, int>{};
    final elementTitles = <String, String>{};

    for (final event in events) {
      elementCounts.update(
        event.elementId,
        (count) => count + 1,
        ifAbsent: () => 1,
      );
      elementTitles[event.elementId] = event.elementTitle;
    }

    final mostTappedElementId = _mostTappedElementId(elementCounts);
    final uniqueElements =
        events
            .where((event) => event.elementId != 'door')
            .map((event) => event.elementTitle)
            .toSet()
            .toList()
          ..sort();

    return ExperienceSession(
      sessionId: 'session-${endedAt.microsecondsSinceEpoch}',
      startedAt: startedAt,
      endedAt: endedAt,
      totalDuration: endedAt.difference(startedAt),
      events: events,
      totalInteractions: events.length,
      uniqueElementsExplored: uniqueElements,
      mostTappedElement: mostTappedElementId == null
          ? null
          : elementTitles[mostTappedElementId],
      averageTimeBetweenInteractions: _averageTimeBetweenInteractions(events),
      completed: summary.completed,
      repeatedExperience: repeatedExperience,
    );
  }

  factory ExperienceSession.fromJson(Map<String, Object?> json) {
    final eventsJson = json['events'] as List<Object?>? ?? const [];
    final events = eventsJson
        .whereType<Map<String, Object?>>()
        .map(InteractionEvent.fromJson)
        .toList();

    return ExperienceSession(
      sessionId: json['sessionId'] as String? ?? '',
      startedAt:
          DateTime.tryParse(json['startedAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      endedAt:
          DateTime.tryParse(json['endedAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      totalDuration: Duration(
        milliseconds: json['totalDurationMs'] as int? ?? 0,
      ),
      events: List.unmodifiable(events),
      totalInteractions: json['totalInteractions'] as int? ?? events.length,
      uniqueElementsExplored:
          (json['uniqueElementsExplored'] as List<Object?>? ?? const [])
              .whereType<String>()
              .toList(),
      mostTappedElement: json['mostTappedElement'] as String?,
      averageTimeBetweenInteractions: Duration(
        milliseconds: json['averageTimeBetweenInteractionsMs'] as int? ?? 0,
      ),
      completed: json['completed'] as bool? ?? false,
      repeatedExperience: json['repeatedExperience'] as bool? ?? false,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'sessionId': sessionId,
      'startedAt': startedAt.toIso8601String(),
      'endedAt': endedAt.toIso8601String(),
      'totalDurationMs': totalDuration.inMilliseconds,
      'events': events.map((event) => event.toJson()).toList(),
      'totalInteractions': totalInteractions,
      'uniqueElementsExplored': uniqueElementsExplored,
      'mostTappedElement': mostTappedElement,
      'averageTimeBetweenInteractionsMs':
          averageTimeBetweenInteractions.inMilliseconds,
      'completed': completed,
      'repeatedExperience': repeatedExperience,
    };
  }

  static String? _mostTappedElementId(Map<String, int> counts) {
    if (counts.isEmpty) {
      return null;
    }

    final entries = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entries.first.key;
  }

  static Duration _averageTimeBetweenInteractions(
    List<InteractionEvent> events,
  ) {
    if (events.length < 2) {
      return Duration.zero;
    }

    final intervals = events
        .skip(1)
        .map((event) => event.elapsedSinceLastInteraction.inMilliseconds);
    final total = intervals.fold<int>(0, (sum, value) => sum + value);
    return Duration(milliseconds: total ~/ (events.length - 1));
  }
}
