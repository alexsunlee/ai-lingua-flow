import '../../domain/entities/shadowing_session.dart';
import '../../domain/repositories/shadowing_repository.dart';
import '../datasources/shadowing_local_datasource.dart';
import '../models/shadowing_session_model.dart';

class ShadowingRepositoryImpl implements ShadowingRepository {
  final ShadowingLocalDatasource _datasource;

  ShadowingRepositoryImpl(this._datasource);

  @override
  Future<List<ShadowingSession>> getSessionsForSource(String sourceId) {
    return _datasource.getSessionsForSource(sourceId);
  }

  @override
  Future<List<ShadowingSession>> getAllSessions() {
    return _datasource.getAllSessions();
  }

  @override
  Future<ShadowingSession?> getSessionById(String id) {
    return _datasource.getSessionById(id);
  }

  @override
  Future<void> saveSession(ShadowingSession session) {
    return _datasource.insertSession(
      ShadowingSessionModel.fromEntity(session),
    );
  }
}
