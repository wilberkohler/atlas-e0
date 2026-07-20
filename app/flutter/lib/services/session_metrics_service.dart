import '../models/experience_session.dart';
import '../models/session_metrics.dart';

class SessionMetricsService {
  const SessionMetricsService();

  SessionMetrics calculate(List<ExperienceSession> sessions) {
    if (sessions.isEmpty) {
      return const SessionMetrics(
        sessionCount: 0,
        averageDuration: Duration.zero,
        completionRate: 0,
        mostExploredElement: null,
        averageUniqueElements: 0,
      );
    }

    final durationTotalMs = sessions.fold<int>(
      0,
      (total, session) => total + session.totalDuration.inMilliseconds,
    );
    final completedCount = sessions
        .where((session) => session.completed)
        .length;
    final uniqueElementsTotal = sessions.fold<int>(
      0,
      (total, session) => total + session.uniqueElementsExplored.length,
    );
    final elementCounts = <String, int>{};

    for (final session in sessions) {
      for (final event in session.events) {
        elementCounts.update(
          event.elementTitle,
          (count) => count + 1,
          ifAbsent: () => 1,
        );
      }
    }

    return SessionMetrics(
      sessionCount: sessions.length,
      averageDuration: Duration(
        milliseconds: durationTotalMs ~/ sessions.length,
      ),
      completionRate: completedCount / sessions.length,
      mostExploredElement: _mostExploredElement(elementCounts),
      averageUniqueElements: uniqueElementsTotal / sessions.length,
    );
  }

  String? _mostExploredElement(Map<String, int> counts) {
    if (counts.isEmpty) {
      return null;
    }

    final entries = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entries.first.key;
  }
}
