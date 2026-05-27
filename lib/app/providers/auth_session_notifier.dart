import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../modules/auth/domain/entities/auth_session.dart';
import '../../modules/auth/domain/entities/tenant_access.dart';
import '../../core/errors/api_failure.dart';
import '../../modules/auth/data/repositories/auth_repository_impl.dart';

/// Estado global de autenticação e contexto tenant/branch.
class AuthSessionState {
  const AuthSessionState({
    this.isBootstrapping = false,
    this.isLoading = false,
    this.session,
    this.errorMessage,
  });

  final bool isBootstrapping;
  final bool isLoading;
  final AuthSession? session;
  final String? errorMessage;

  bool get isAuthenticated => session != null;
  bool get hasTenantContext => session?.hasTenantContext ?? false;

  AuthSessionState copyWith({
    bool? isBootstrapping,
    bool? isLoading,
    AuthSession? session,
    String? errorMessage,
    bool clearSession = false,
    bool clearError = false,
  }) {
    return AuthSessionState(
      isBootstrapping: isBootstrapping ?? this.isBootstrapping,
      isLoading: isLoading ?? this.isLoading,
      session: clearSession ? null : (session ?? this.session),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  static const bootstrapping = AuthSessionState(isBootstrapping: true);
  static const initial = AuthSessionState();
}

class AuthSessionNotifier extends Notifier<AuthSessionState> {
  @override
  AuthSessionState build() {
    Future.microtask(_restoreSession);
    return AuthSessionState.bootstrapping;
  }

  Future<void> _restoreSession() async {
    try {
      final repo = ref.read(authRepositoryProvider);
      final session = await repo.restoreSession();
      if (session != null) {
        state = AuthSessionState(session: session);
      } else {
        state = AuthSessionState.initial;
      }
    } catch (_) {
      state = AuthSessionState.initial;
    }
  }

  Future<bool> login({required String email, required String password}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final repo = ref.read(authRepositoryProvider);
      final session = await repo.login(email: email.trim(), password: password);
      state = AuthSessionState(session: session);

      if (_shouldAutoSelectTenant(session.tenants)) {
        final t = session.tenants.first;
        final b = t.branches.first;
        await selectTenantBranch(tenantId: t.id, branchId: b.id);
      }
      return true;
    } on ApiFailure catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  bool _shouldAutoSelectTenant(List<TenantAccess> tenants) {
    if (tenants.length != 1) return false;
    return tenants.first.branches.length == 1;
  }

  Future<void> selectTenantBranch({
    required String tenantId,
    required String branchId,
  }) async {
    final current = state.session;
    if (current == null) return;

    final updated = current.copyWith(tenantId: tenantId, branchId: branchId);
    await ref.read(authRepositoryProvider).persistTenantContext(
          tenantId: tenantId,
          branchId: branchId,
        );
    state = AuthSessionState(session: updated);
  }

  Future<void> signOut() async {
    await ref.read(authRepositoryProvider).signOut();
    state = AuthSessionState.initial;
  }
}

final authSessionProvider =
    NotifierProvider<AuthSessionNotifier, AuthSessionState>(AuthSessionNotifier.new);

/// Compatibilidade com código que esperava `bool` autenticado.
final isAuthenticatedProvider = Provider<bool>(
  (ref) => ref.watch(authSessionProvider).hasTenantContext,
);
