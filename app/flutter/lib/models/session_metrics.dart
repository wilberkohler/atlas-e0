class SessionMetrics {
  const SessionMetrics({
    required this.sessionCount,
    required this.averageDuration,
    required this.completionRate,
    required this.mostExploredElement,
    required this.averageUniqueElements,
  });

  final int sessionCount;
  final Duration averageDuration;
  final double completionRate;
  final String? mostExploredElement;
  final double averageUniqueElements;
}
