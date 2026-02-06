import '../entities/shadowing_session.dart';

abstract class ShadowingRepository {
  /// Retrieve all shadowing sessions for a given source, ordered by
  /// sentence index ascending.
  Future<List<ShadowingSession>> getSessionsForSource(String sourceId);

  /// Persist a shadowing session (insert or update).
  Future<void> saveSession(ShadowingSession session);

  /// Retrieve every shadowing session, ordered by most recent first.
  Future<List<ShadowingSession>> getAllSessions();

  /// Retrieve a single session by [id], or `null` if not found.
  Future<ShadowingSession?> getSessionById(String id);
}
