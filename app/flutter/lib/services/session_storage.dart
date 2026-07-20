import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/experience_session.dart';

class SessionStorage {
  static const _sessionsKey = 'atlas_e0_sessions_json';

  Future<List<ExperienceSession>> loadSessions() async {
    final preferences = await SharedPreferences.getInstance();
    final rawJson = preferences.getString(_sessionsKey);
    if (rawJson == null || rawJson.isEmpty) {
      return const [];
    }

    final decoded = jsonDecode(rawJson);
    if (decoded is! List) {
      return const [];
    }

    return decoded
        .whereType<Map<String, Object?>>()
        .map(ExperienceSession.fromJson)
        .toList();
  }

  Future<List<ExperienceSession>> saveSession(ExperienceSession session) async {
    final sessions = await loadSessions();
    final updatedSessions = [...sessions, session];
    await saveSessions(updatedSessions);
    return updatedSessions;
  }

  Future<void> saveSessions(List<ExperienceSession> sessions) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_sessionsKey, encodeSessions(sessions));
  }

  String encodeSessions(List<ExperienceSession> sessions) {
    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(
      sessions.map((session) => session.toJson()).toList(),
    );
  }
}
