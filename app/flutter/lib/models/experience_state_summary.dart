import 'interaction_event.dart';

class ExperienceStateSummary {
  const ExperienceStateSummary({
    required this.startedAt,
    required this.completedAt,
    required this.events,
    required this.minimumElementsToConclude,
    required this.completed,
  });

  final DateTime? startedAt;
  final DateTime? completedAt;
  final List<InteractionEvent> events;
  final int minimumElementsToConclude;
  final bool completed;

  int get totalInteractions => events.length;

  Set<String> get uniqueElementIds {
    return events.map((event) => event.elementId).toSet();
  }

  Set<String> get uniqueNonExitElementIds {
    return events
        .where((event) => !event.attemptedExitBeforeExploring)
        .where((event) => event.elementId != 'door')
        .map((event) => event.elementId)
        .toSet();
  }

  bool get exploredOptionalElements {
    return events.any((event) => event.exploredOptionalElement);
  }

  bool get attemptedExitBeforeExploring {
    return events.any((event) => event.attemptedExitBeforeExploring);
  }

  bool get exploredMoreThanMinimum {
    return uniqueNonExitElementIds.length > minimumElementsToConclude;
  }

  bool get returnedToKnownElements {
    return events.any((event) => event.timesElementTapped > 1);
  }

  bool get hasLongPause {
    return events.any(
      (event) =>
          event.order > 1 && event.elapsedSinceLastInteraction.inSeconds >= 12,
    );
  }

  Duration get totalDuration {
    if (startedAt == null) {
      return Duration.zero;
    }

    final end = completedAt ?? events.lastOrNull?.occurredAt ?? startedAt!;
    return end.difference(startedAt!);
  }
}
