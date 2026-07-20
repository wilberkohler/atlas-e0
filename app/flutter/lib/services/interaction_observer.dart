import '../models/experience_state_summary.dart';
import '../models/interaction_event.dart';
import '../models/interactive_element.dart';

class InteractionObserver {
  static const minimumElementsToConclude = 3;

  final List<InteractionEvent> _events = <InteractionEvent>[];
  final Map<String, int> _tapCounts = <String, int>{};

  DateTime? _startedAt;
  DateTime? _lastInteractionAt;
  DateTime? _completedAt;

  bool get hasStarted => _startedAt != null;

  bool get canConclude {
    return _uniqueNonExitElementIds.length >= minimumElementsToConclude;
  }

  void startSession() {
    final now = DateTime.now();
    _events.clear();
    _tapCounts.clear();
    _startedAt = now;
    _lastInteractionAt = null;
    _completedAt = null;
  }

  InteractionEvent recordInteraction(InteractiveElement element) {
    final now = DateTime.now();
    final startedAt = _startedAt ?? now;
    _startedAt ??= now;

    final previousTapCount = _tapCounts[element.id] ?? 0;
    final tapCount = previousTapCount + 1;
    _tapCounts[element.id] = tapCount;

    final attemptedEarlyExit = element.isExit && !canConclude;
    final event = InteractionEvent(
      elementType: element.type,
      elementId: element.id,
      elementTitle: element.title,
      order: _events.length + 1,
      occurredAt: now,
      elapsedSinceStart: now.difference(startedAt),
      elapsedSinceLastInteraction: _lastInteractionAt == null
          ? Duration.zero
          : now.difference(_lastInteractionAt!),
      timesElementTapped: tapCount,
      exploredOptionalElement: element.isOptional,
      attemptedExitBeforeExploring: attemptedEarlyExit,
    );

    _events.add(event);
    _lastInteractionAt = now;
    return event;
  }

  ExperienceStateSummary completeSession() {
    _completedAt = DateTime.now();
    return buildSummary(completed: true);
  }

  ExperienceStateSummary buildSummary({required bool completed}) {
    return ExperienceStateSummary(
      startedAt: _startedAt,
      completedAt: _completedAt,
      events: List.unmodifiable(_events),
      minimumElementsToConclude: minimumElementsToConclude,
      completed: completed,
    );
  }

  Set<String> get _uniqueNonExitElementIds {
    return _events
        .where((event) => event.elementId != 'door')
        .map((event) => event.elementId)
        .toSet();
  }
}
