import 'package:flutter/material.dart';

import '../models/experience_session.dart';
import '../widgets/interaction_timeline.dart';
import '../widgets/metric_card.dart';

class SessionDetailScreen extends StatelessWidget {
  const SessionDetailScreen({required this.session, super.key});

  final ExperienceSession session;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Detalhe da sessão')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              session.sessionId,
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                MetricCard(
                  label: 'Duração',
                  value: _formatDuration(session.totalDuration),
                ),
                MetricCard(
                  label: 'Interações',
                  value: '${session.totalInteractions}',
                ),
                MetricCard(
                  label: 'Elementos',
                  value: '${session.uniqueElementsExplored.length}',
                ),
                MetricCard(
                  label: 'Mais tocado',
                  value: session.mostTappedElement ?? 'Sem dados',
                ),
                MetricCard(
                  label: 'Intervalo médio',
                  value: _formatDuration(
                    session.averageTimeBetweenInteractions,
                  ),
                ),
                MetricCard(
                  label: 'Repetição',
                  value: session.repeatedExperience ? 'Sim' : 'Não',
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'Linha do tempo',
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            InteractionTimeline(events: session.events),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    if (duration.inMilliseconds < 1000) {
      return '${duration.inMilliseconds} ms';
    }

    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(60);
    if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    }

    return '${duration.inSeconds}s';
  }
}
