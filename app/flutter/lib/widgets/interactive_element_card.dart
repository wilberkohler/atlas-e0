import 'package:flutter/material.dart';

import '../models/interactive_element.dart';

class InteractiveElementCard extends StatelessWidget {
  const InteractiveElementCard({
    required this.element,
    required this.touchCount,
    required this.exitUnlocked,
    required this.onTap,
    super.key,
  });

  final InteractiveElement element;
  final int touchCount;
  final bool exitUnlocked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final color = _stateColor;
    final stateLabel = _stateLabel;

    return SizedBox(
      width: 132,
      child: Card(
        clipBehavior: Clip.antiAlias,
        color: _surfaceColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: color.withValues(alpha: 0.5), width: 1.4),
        ),
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(7),
                        child: Icon(
                          _iconFor(element.type),
                          color: color,
                          size: 22,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      touchCount > 0 ? '$touchCount' : '·',
                      style: textTheme.labelLarge?.copyWith(
                        color: color,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  element.title,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Text(
                  element.sensoryHint,
                  style: textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF5A625D),
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.13),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    child: Text(
                      stateLabel,
                      style: textTheme.labelSmall?.copyWith(
                        color: color,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color get _stateColor {
    if (element.isExit && exitUnlocked) {
      return const Color(0xFF2F6B59);
    }

    if (touchCount == 0) {
      return const Color(0xFF75817B);
    }

    if (touchCount == 1) {
      return _accentColor(element.type);
    }

    return const Color(0xFF7B5EA7);
  }

  Color get _surfaceColor {
    if (element.isExit && exitUnlocked) {
      return const Color(0xFFE8F6ED);
    }

    if (touchCount == 0) {
      return const Color(0xFFF8FAF8);
    }

    return Colors.white;
  }

  String get _stateLabel {
    if (element.isExit) {
      return exitUnlocked ? 'pronta' : 'bloqueada';
    }

    if (touchCount == 0) {
      return 'intocado';
    }

    if (touchCount == 1) {
      return 'explorado';
    }

    return 'revisitado';
  }

  Color _accentColor(InteractiveElementType type) {
    return switch (type) {
      InteractiveElementType.unknownObject => const Color(0xFF7B5EA7),
      InteractiveElementType.sealedDoor => const Color(0xFF8A4F43),
      InteractiveElementType.distantWindow => const Color(0xFF2B6F8A),
      InteractiveElementType.deskDrawer => const Color(0xFF7A6A2F),
      InteractiveElementType.dormantPanel => const Color(0xFF2F6B59),
    };
  }

  IconData _iconFor(InteractiveElementType type) {
    return switch (type) {
      InteractiveElementType.unknownObject => Icons.blur_circular,
      InteractiveElementType.sealedDoor => Icons.door_front_door_outlined,
      InteractiveElementType.distantWindow => Icons.window_outlined,
      InteractiveElementType.deskDrawer => Icons.inventory_2_outlined,
      InteractiveElementType.dormantPanel => Icons.sensors_outlined,
    };
  }
}
