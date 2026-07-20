import 'package:flutter/material.dart';

import 'models/experience_session.dart';
import 'models/experience_state_summary.dart';
import 'models/interactive_element.dart';
import 'screens/developer_dashboard_screen.dart';
import 'screens/observation_screen.dart';
import 'screens/opening_screen.dart';
import 'screens/zero_room_screen.dart';
import 'services/experience_state_inferer.dart';
import 'services/interaction_observer.dart';
import 'services/session_storage.dart';

class AtlasE0App extends StatelessWidget {
  const AtlasE0App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Atlas E0',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2F6B59),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF3F7F5),
        cardTheme: CardThemeData(
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: const BorderSide(color: Color(0xFFD8E2DC)),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            minimumSize: const Size(144, 48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),
      home: const ExperienceFlow(),
    );
  }
}

class ExperienceFlow extends StatefulWidget {
  const ExperienceFlow({super.key});

  @override
  State<ExperienceFlow> createState() => _ExperienceFlowState();
}

class _ExperienceFlowState extends State<ExperienceFlow> {
  final InteractionObserver _interactionObserver = InteractionObserver();
  final ExperienceStateInferer _experienceStateInferer =
      const ExperienceStateInferer();
  final SessionStorage _sessionStorage = SessionStorage();

  List<ExperienceSession> _sessions = const [];
  ExperienceStateSummary? _completedSummary;
  String _roomMessage = 'A Sala Zero permanece em silêncio.';
  bool _roomStarted = false;
  bool _exitReady = false;

  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

  @override
  Widget build(BuildContext context) {
    if (!_roomStarted) {
      return OpeningScreen(
        onStart: _startSession,
        onOpenDeveloperDashboard: _openDeveloperDashboard,
      );
    }

    final completedSummary = _completedSummary;
    if (completedSummary != null) {
      return ObservationScreen(
        summary: completedSummary,
        observations: _experienceStateInferer.infer(completedSummary),
        onRestart: _startSession,
      );
    }

    return ZeroRoomScreen(
      elements: zeroRoomElements,
      summary: _interactionObserver.buildSummary(completed: false),
      roomMessage: _roomMessage,
      exitReady: _exitReady,
      onElementTapped: _handleElementTapped,
      onComplete: _completeSession,
    );
  }

  void _startSession() {
    setState(() {
      _interactionObserver.startSession();
      _completedSummary = null;
      _roomStarted = true;
      _exitReady = false;
      _roomMessage = 'A Sala Zero acorda aos poucos.';
    });
  }

  void _handleElementTapped(InteractiveElement element) {
    final event = _interactionObserver.recordInteraction(element);
    final canConclude = _interactionObserver.canConclude;

    setState(() {
      if (event.attemptedExitBeforeExploring) {
        _roomMessage =
            'A porta não cede. Outros sinais ainda parecem ativos na sala.';
        _exitReady = false;
        return;
      }

      if (element.isExit && canConclude) {
        _roomMessage = 'A fechadura responde. A sala parece aceitar sua saída.';
        _exitReady = true;
        return;
      }

      final reaction = element.reactionForTapCount(event.timesElementTapped);
      _roomMessage = canConclude
          ? '$reaction Três indicadores acenderam na porta.'
          : reaction;
    });
  }

  Future<void> _completeSession() async {
    final completedSummary = _interactionObserver.completeSession();
    final session = ExperienceSession.fromSummary(
      summary: completedSummary,
      repeatedExperience: _sessions.isNotEmpty,
    );
    final updatedSessions = await _sessionStorage.saveSession(session);

    if (!mounted) {
      return;
    }

    setState(() {
      _completedSummary = completedSummary;
      _sessions = updatedSessions;
    });
  }

  Future<void> _loadSessions() async {
    final sessions = await _sessionStorage.loadSessions();
    if (!mounted) {
      return;
    }

    setState(() {
      _sessions = sessions;
    });
  }

  void _openDeveloperDashboard() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => DeveloperDashboardScreen(
          sessions: _sessions,
          exportedJson: _sessionStorage.encodeSessions(_sessions),
        ),
      ),
    );
  }
}
