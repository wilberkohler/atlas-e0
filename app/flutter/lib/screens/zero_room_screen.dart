import 'package:flutter/material.dart';

import '../models/experience_state_summary.dart';
import '../models/interactive_element.dart';
import '../widgets/primary_button.dart';
import '../widgets/zero_room_layout.dart';

class ZeroRoomScreen extends StatelessWidget {
  const ZeroRoomScreen({
    required this.elements,
    required this.summary,
    required this.roomMessage,
    required this.exitReady,
    required this.onElementTapped,
    required this.onComplete,
    super.key,
  });

  final List<InteractiveElement> elements;
  final ExperienceStateSummary summary;
  final String roomMessage;
  final bool exitReady;
  final ValueChanged<InteractiveElement> onElementTapped;
  final VoidCallback onComplete;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 980),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Sala Zero',
                                      style: textTheme.displaySmall?.copyWith(
                                        fontWeight: FontWeight.w700,
                                        height: 1.05,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Cinco pontos discretos dividem o mesmo silêncio.',
                                      style: textTheme.titleMedium?.copyWith(
                                        color: const Color(0xFF535B55),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              _RoomCounter(summary: summary),
                            ],
                          ),
                          const SizedBox(height: 14),
                          _ExitProgress(summary: summary),
                          const SizedBox(height: 16),
                          ZeroRoomLayout(
                            elements: elements,
                            summary: summary,
                            exitUnlocked:
                                summary.uniqueNonExitElementIds.length >=
                                summary.minimumElementsToConclude,
                            onElementTapped: onElementTapped,
                          ),
                          const SizedBox(height: 20),
                          _ReactionPanel(message: roomMessage),
                          if (exitReady) ...[
                            const SizedBox(height: 18),
                            Align(
                              alignment: Alignment.centerRight,
                              child: PrimaryButton(
                                label: 'Sair da sala',
                                icon: Icons.door_front_door_outlined,
                                onPressed: onComplete,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ExitProgress extends StatelessWidget {
  const _ExitProgress({required this.summary});

  final ExperienceStateSummary summary;

  @override
  Widget build(BuildContext context) {
    final explored = summary.uniqueNonExitElementIds.length.clamp(
      0,
      summary.minimumElementsToConclude,
    );
    final unlocked = explored >= summary.minimumElementsToConclude;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: unlocked ? const Color(0xFFE2F5EA) : const Color(0xFFFFF7E6),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: unlocked ? const Color(0xFF8BC7A4) : const Color(0xFFE5C97B),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            Icon(
              unlocked ? Icons.lock_open : Icons.lock_outline,
              color: unlocked
                  ? const Color(0xFF2F6B59)
                  : const Color(0xFF8A6A18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                unlocked
                    ? 'Porta pronta: toque nela para encerrar.'
                    : 'Explore $explored de ${summary.minimumElementsToConclude} sinais para liberar a porta.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: unlocked
                      ? const Color(0xFF214D3F)
                      : const Color(0xFF705611),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Row(
              children: List.generate(
                summary.minimumElementsToConclude,
                (index) => Padding(
                  padding: const EdgeInsets.only(left: 5),
                  child: Icon(
                    index < explored ? Icons.circle : Icons.circle_outlined,
                    size: 12,
                    color: unlocked
                        ? const Color(0xFF2F6B59)
                        : const Color(0xFF8A6A18),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoomCounter extends StatelessWidget {
  const _RoomCounter({required this.summary});

  final ExperienceStateSummary summary;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFE2EFE9),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFB9D4C8)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Text(
          '${summary.totalInteractions} sinais',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: const Color(0xFF214D3F),
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _ReactionPanel extends StatelessWidget {
  const _ReactionPanel({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF1F2933),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            const Icon(Icons.graphic_eq, color: Color(0xFF9EE6C4)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.white,
                  height: 1.35,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
