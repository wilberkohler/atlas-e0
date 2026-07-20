import 'package:flutter/material.dart';

import '../models/interaction_event.dart';

class InteractionTimeline extends StatelessWidget {
  const InteractionTimeline({required this.events, super.key});

  final List<InteractionEvent> events;

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(18),
          child: Text('Nenhum evento registrado.'),
        ),
      );
    }

    return Column(
      children: events.map((event) => _TimelineRow(event: event)).toList(),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({required this.event});

  final InteractionEvent event;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: const Color(0xFFE2EFE9),
              child: Text(
                '${event.order}',
                style: textTheme.labelMedium?.copyWith(
                  color: const Color(0xFF214D3F),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.elementTitle,
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'desde início: ${_formatDuration(event.elapsedSinceStart)} • '
                    'intervalo: ${_formatDuration(event.elapsedSinceLastInteraction)} • '
                    'toques no elemento: ${event.timesElementTapped}',
                    style: textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF59635E),
                    ),
                  ),
                  if (event.attemptedExitBeforeExploring) ...[
                    const SizedBox(height: 8),
                    const _EventBadge(label: 'tentou sair cedo'),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    if (duration.inMilliseconds < 1000) {
      return '${duration.inMilliseconds} ms';
    }

    return '${duration.inSeconds}s';
  }
}

class _EventBadge extends StatelessWidget {
  const _EventBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFFFE5D9),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: const Color(0xFF8A4F43),
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}
