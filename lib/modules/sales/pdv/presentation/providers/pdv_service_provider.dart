import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../app/providers/auth_session_notifier.dart';
import '../../../../../core/errors/api_failure.dart';
import '../../data/repositories/pdv_service_repository_impl.dart';
import '../../domain/entities/pdv_service.dart';

class PdvServiceListState {
  const PdvServiceListState({
    this.items = const <PdvService>[],
    this.query = '',
    this.isLoading = false,
    this.isInitialized = false,
    this.errorMessage,
  });

  final List<PdvService> items;
  final String query;
  final bool isLoading;
  final bool isInitialized;
  final String? errorMessage;

  PdvServiceListState copyWith({
    List<PdvService>? items,
    String? query,
    bool? isLoading,
    bool? isInitialized,
    String? errorMessage,
    bool clearError = false,
  }) {
    return PdvServiceListState(
      items: items ?? this.items,
      query: query ?? this.query,
      isLoading: isLoading ?? this.isLoading,
      isInitialized: isInitialized ?? this.isInitialized,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class PdvServiceListController extends Notifier<PdvServiceListState> {
  final Map<String, List<PdvService>> _cache = <String, List<PdvService>>{};
  Timer? _debounce;
  int _requestId = 0;

  @override
  PdvServiceListState build() {
    ref.onDispose(() {
      _debounce?.cancel();
    });

    final authReady = ref.watch(
      authSessionProvider.select(
        (session) => !session.isBootstrapping && session.hasTenantContext,
      ),
    );

    ref.listen<AuthSessionState>(authSessionProvider, (previous, next) {
      final previousSession = previous?.session;
      final nextSession = next.session;
      final wasReady =
          previous != null && !previous.isBootstrapping && previous.hasTenantContext;
      final isReady = !next.isBootstrapping && next.hasTenantContext;

      if (!isReady) {
        _cache.clear();
        state = const PdvServiceListState();
        return;
      }

      final tenantChanged =
          previousSession?.tenantId != nextSession?.tenantId ||
          previousSession?.branchId != nextSession?.branchId;

      if (isReady && (!wasReady || tenantChanged)) {
        _cache.clear();
        unawaited(fetchCurrentQuery(force: true));
      }
    });

    if (authReady) {
      Future.microtask(fetchCurrentQuery);
    }
    return const PdvServiceListState();
  }

  void onSearchChanged(String value) {
    final normalized = value.trim();
    if (normalized == state.query) {
      return;
    }

    _debounce?.cancel();
    state = state.copyWith(
      query: normalized,
      isLoading: true,
      clearError: true,
    );

    _debounce = Timer(const Duration(milliseconds: 350), () {
      fetchCurrentQuery();
    });
  }

  Future<void> refreshCurrentQuery() async {
    await fetchCurrentQuery(force: true);
  }

  Future<void> fetchCurrentQuery({bool force = false}) async {
    if (!ref.read(authSessionProvider).hasTenantContext) {
      _cache.clear();
      state = const PdvServiceListState();
      return;
    }

    final requestId = ++_requestId;
    final cacheKey = state.query.toLowerCase();

    if (!force && _cache.containsKey(cacheKey)) {
      state = state.copyWith(
        items: _cache[cacheKey]!,
        isLoading: false,
        isInitialized: true,
        clearError: true,
      );
      return;
    }

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final repository = ref.read(pdvServiceRepositoryProvider);
      final response = await repository.searchServices(query: state.query);

      if (requestId != _requestId) {
        return;
      }

      _cache[cacheKey] = response;
      state = state.copyWith(
        items: response,
        isLoading: false,
        isInitialized: true,
        clearError: true,
      );
    } on ApiFailure catch (e) {
      if (requestId != _requestId) {
        return;
      }
      state = state.copyWith(
        isLoading: false,
        isInitialized: true,
        errorMessage: e.message,
      );
    } catch (e) {
      if (requestId != _requestId) {
        return;
      }
      state = state.copyWith(
        isLoading: false,
        isInitialized: true,
        errorMessage: e.toString(),
      );
    }
  }
}

final pdvServiceListProvider =
    NotifierProvider<PdvServiceListController, PdvServiceListState>(
  PdvServiceListController.new,
);
