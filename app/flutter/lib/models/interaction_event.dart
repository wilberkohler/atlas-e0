import 'interactive_element.dart';

class InteractionEvent {
  const InteractionEvent({
    required this.elementType,
    required this.elementId,
    required this.elementTitle,
    required this.order,
    required this.occurredAt,
    required this.elapsedSinceStart,
    required this.elapsedSinceLastInteraction,
    required this.timesElementTapped,
    required this.exploredOptionalElement,
    required this.attemptedExitBeforeExploring,
  });

  final InteractiveElementType elementType;
  final String elementId;
  final String elementTitle;
  final int order;
  final DateTime occurredAt;
  final Duration elapsedSinceStart;
  final Duration elapsedSinceLastInteraction;
  final int timesElementTapped;
  final bool exploredOptionalElement;
  final bool attemptedExitBeforeExploring;

  Map<String, Object?> toJson() {
    return {
      'elementType': elementType.name,
      'elementId': elementId,
      'elementTitle': elementTitle,
      'order': order,
      'occurredAt': occurredAt.toIso8601String(),
      'elapsedSinceStartMs': elapsedSinceStart.inMilliseconds,
      'elapsedSinceLastInteractionMs':
          elapsedSinceLastInteraction.inMilliseconds,
      'timesElementTapped': timesElementTapped,
      'exploredOptionalElement': exploredOptionalElement,
      'attemptedExitBeforeExploring': attemptedExitBeforeExploring,
    };
  }

  factory InteractionEvent.fromJson(Map<String, Object?> json) {
    final elementTypeName = json['elementType'] as String? ?? '';
    return InteractionEvent(
      elementType: InteractiveElementType.values.firstWhere(
        (type) => type.name == elementTypeName,
        orElse: () => InteractiveElementType.unknownObject,
      ),
      elementId: json['elementId'] as String? ?? '',
      elementTitle: json['elementTitle'] as String? ?? '',
      order: json['order'] as int? ?? 0,
      occurredAt:
          DateTime.tryParse(json['occurredAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      elapsedSinceStart: Duration(
        milliseconds: json['elapsedSinceStartMs'] as int? ?? 0,
      ),
      elapsedSinceLastInteraction: Duration(
        milliseconds: json['elapsedSinceLastInteractionMs'] as int? ?? 0,
      ),
      timesElementTapped: json['timesElementTapped'] as int? ?? 0,
      exploredOptionalElement:
          json['exploredOptionalElement'] as bool? ?? false,
      attemptedExitBeforeExploring:
          json['attemptedExitBeforeExploring'] as bool? ?? false,
    );
  }
}
