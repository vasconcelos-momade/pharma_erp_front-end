import '../entities/auth_session.dart';

abstract class AuthRepository {
  Future<AuthSession> login({required String email, required String password});

  Future<AuthSession?> restoreSession();

  Future<void> persistTenantContext({
    required String tenantId,
    required String branchId,
  });

  Future<void> signOut();

  Future<void> requestPasswordReset({required String email});
}
