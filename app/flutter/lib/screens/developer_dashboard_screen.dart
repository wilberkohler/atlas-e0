import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/experience_session.dart';
import '../services/session_metrics_service.dart';
import '../widgets/metric_card.dart';
import 'session_detail_screen.dart';

class DeveloperDashboardScreen extends StatefulWidget {
  const DeveloperDashboardScreen({
    required this.sessions,
    required this.exportedJson,
    super.key,
  });

  final List<ExperienceSession> sessions;
  final String exportedJson;

  @override
  State<DeveloperDashboardScreen> createState() =>
      _DeveloperDashboardScreenState();
}

class _DeveloperDashboardScreenState extends State<DeveloperDashboardScreen> {
  final SessionMetricsService _metricsService = const SessionMetricsService();
  bool _showJson = false;

  @override
  Widget build(BuildContext context) {
    final metrics = _metricsService.calculate(widget.sessions);
    final latestSessions = widget.sessions.reversed.take(8).toList();
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Painel Dev')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              'Histórico local',
              style: textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                MetricCard(label: 'Sessões', value: '${metrics.sessionCount}'),
                MetricCard(
                  label: 'Duração média',
                  value: _formatDuration(metrics.averageDuration),
                ),
                MetricCard(
                  label: 'Conclusão',
                  value: '${(metrics.completionRate * 100).round()}%',
                ),
                MetricCard(
                  label: 'Mais explorado',
                  value: metrics.mostExploredElement ?? 'Sem dados',
                ),
                MetricCard(
                  label: 'Elementos únicos',
                  value: metrics.averageUniqueElements.toStringAsFixed(1),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Últimas sessões',
                    style: textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                FilledButton.icon(
                  onPressed: _copyJson,
                  icon: const Icon(Icons.copy),
                  label: const Text('Copiar JSON'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (latestSessions.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(18),
                  child: Text('Nenhuma sessão registrada ainda.'),
                ),
              )
            else
              ...latestSessions.map(
                (session) => Card(
                  child: ListTile(
                    title: Text(_formatDateTime(session.startedAt)),
                    subtitle: Text(
                      '${session.totalInteractions} interações • '
                      '${session.uniqueElementsExplored.length} elementos • '
                      '${session.completed ? 'concluída' : 'parcial'}',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _openSessionDetail(session),
                  ),
                ),
              ),
            const SizedBox(height: 18),
            OutlinedButton.icon(
              onPressed: () {
                setState(() {
                  _showJson = !_showJson;
                });
              },
              icon: Icon(_showJson ? Icons.visibility_off : Icons.visibility),
              label: Text(_showJson ? 'Ocultar JSON' : 'Visualizar JSON'),
            ),
            if (_showJson) ...[
              const SizedBox(height: 12),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: const Color(0xFF17212B),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: SelectableText(
                    widget.exportedJson,
                    style: const TextStyle(
                      color: Colors.white,
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _copyJson() async {
    await Clipboard.setData(ClipboardData(text: widget.exportedJson));
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('JSON copiado para a área de transferência.'),
      ),
    );
  }

  void _openSessionDetail(ExperienceSession session) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => SessionDetailScreen(session: session),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    if (duration == Duration.zero) {
      return '0 s';
    }

    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(60);
    if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    }

    return '${duration.inSeconds}s';
  }

  String _formatDateTime(DateTime dateTime) {
    final local = dateTime.toLocal();
    final date =
        '${local.day.toString().padLeft(2, '0')}/'
        '${local.month.toString().padLeft(2, '0')}';
    final time =
        '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}';
    return '$date às $time';
  }
}
