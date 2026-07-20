import 'package:flutter/material.dart';

import '../models/experience_state_summary.dart';
import '../models/interactive_element.dart';
import 'interactive_element_card.dart';

class ZeroRoomLayout extends StatelessWidget {
  const ZeroRoomLayout({
    required this.elements,
    required this.summary,
    required this.exitUnlocked,
    required this.onElementTapped,
    super.key,
  });

  final List<InteractiveElement> elements;
  final ExperienceStateSummary summary;
  final bool exitUnlocked;
  final ValueChanged<InteractiveElement> onElementTapped;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFEAF0ED),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFC8D6CF)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          spacing: 12,
          runSpacing: 12,
          alignment: WrapAlignment.center,
          children: elements.map(_buildElement).toList(),
        ),
      ),
    );
  }

  Widget _buildElement(InteractiveElement element) {
    return InteractiveElementCard(
      element: element,
      touchCount: _touchCountFor(element.id),
      exitUnlocked: exitUnlocked,
      onTap: () => onElementTapped(element),
    );
  }

  int _touchCountFor(String elementId) {
    return summary.events.where((event) => event.elementId == elementId).length;
  }
}
