import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/errors/api_failure.dart';
import '../../data/repositories/transferencia_repository_impl.dart';
import '../../domain/entities/transferencia.dart';

enum TransferenciaTab { produtos, pendentes, concluidas }

class TransferenciaItemDraft {
  const TransferenciaItemDraft({
    required this.produtoId,
    required this.produtoNome,
    required this.quantidade,
    this.loteId,
  });

  final String produtoId;
  final String produtoNome;
  final double quantidade;
  final String? loteId;
}

class TransferenciaState {
  const TransferenciaState({
    this.activeTab = TransferenciaTab.produtos,
    this.isLoadingLists = false,
    this.isLoadingActiveTransfer = false,
    this.isCreatingTransfer = false,
    this.isAddingItem = false,
    this.isConfirmingTransfer = false,
    this.isCancellingTransfer = false,
    this.successMessage,
    this.errorMessage,
    this.activeTransfer,
    this.pendingTransfers = const <TransferenciaResumo>[],
    this.confirmedTransfers = const <TransferenciaResumo>[],
  });

  final TransferenciaTab activeTab;
  final bool isLoadingLists;
  final bool isLoadingActiveTransfer;
  final bool isCreatingTransfer;
  final bool isAddingItem;
  final bool isConfirmingTransfer;
  final bool isCancellingTransfer;
  final String? successMessage;
  final String? errorMessage;
  final TransferenciaDetalhe? activeTransfer;
  final List<TransferenciaResumo> pendingTransfers;
  final List<TransferenciaResumo> confirmedTransfers;

  bool get canEditActiveTransfer =>
      activeTransfer != null && activeTransfer!.status.isEditable;

  bool get canConfirmActiveTransfer =>
      canEditActiveTransfer && activeTransfer!.itens.isNotEmpty;

  bool get canCancelActiveTransfer => canEditActiveTransfer;

  TransferenciaState copyWith({
    TransferenciaTab? activeTab,
    bool? isLoadingLists,
    bool? isLoadingActiveTransfer,
    bool? isCreatingTransfer,
    bool? isAddingItem,
    bool? isConfirmingTransfer,
    bool? isCancellingTransfer,
    String? successMessage,
    String? errorMessage,
    TransferenciaDetalhe? activeTransfer,
    List<TransferenciaResumo>? pendingTransfers,
    List<TransferenciaResumo>? confirmedTransfers,
    bool clearSuccess = false,
    bool clearError = false,
    bool clearActiveTransfer = false,
  }) {
    return TransferenciaState(
      activeTab: activeTab ?? this.activeTab,
      isLoadingLists: isLoadingLists ?? this.isLoadingLists,
      isLoadingActiveTransfer:
          isLoadingActiveTransfer ?? this.isLoadingActiveTransfer,
      isCreatingTransfer: isCreatingTransfer ?? this.isCreatingTransfer,
      isAddingItem: isAddingItem ?? this.isAddingItem,
      isConfirmingTransfer:
          isConfirmingTransfer ?? this.isConfirmingTransfer,
      isCancellingTransfer:
          isCancellingTransfer ?? this.isCancellingTransfer,
      successMessage: clearSuccess ? null : (successMessage ?? this.successMessage),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      activeTransfer:
          clearActiveTransfer ? null : (activeTransfer ?? this.activeTransfer),
      pendingTransfers: pendingTransfers ?? this.pendingTransfers,
      confirmedTransfers: confirmedTransfers ?? this.confirmedTransfers,
    );
  }
}

class TransferenciaController extends Notifier<TransferenciaState> {
  @override
  TransferenciaState build() {
    Future.microtask(refreshLists);
    return const TransferenciaState();
  }

  void setActiveTab(TransferenciaTab tab) {
    state = state.copyWith(activeTab: tab);
  }

  Future<void> refreshLists() async {
    state = state.copyWith(isLoadingLists: true, clearError: true);

    try {
      final repository = ref.read(transferenciaRepositoryProvider);
      final pending = await repository.listarTransferencias(
        status: TransferenciaStatus.rascunho,
      );
      final confirmed = await repository.listarTransferencias(
        status: TransferenciaStatus.confirmada,
      );
      state = state.copyWith(
        isLoadingLists: false,
        pendingTransfers: pending,
        confirmedTransfers: confirmed,
        clearError: true,
      );
    } on ApiFailure catch (e) {
      state = state.copyWith(
        isLoadingLists: false,
        errorMessage: e.message,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingLists: false,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> startTransfer({
    required String numeroDocumento,
    required String origem,
    required String destino,
    TransferenciaTipo tipo = TransferenciaTipo.saida,
    String? observacao,
  }) async {
    final normalizedNumeroDocumento = numeroDocumento.trim();
    final normalizedOrigem = origem.trim();
    final normalizedDestino = destino.trim();

    if (normalizedNumeroDocumento.isEmpty ||
        normalizedOrigem.isEmpty ||
        normalizedDestino.isEmpty) {
      state = state.copyWith(
        errorMessage: 'Preencha número do documento, origem e destino.',
        clearSuccess: true,
      );
      return;
    }

    state = state.copyWith(
      isCreatingTransfer: true,
      clearError: true,
      clearSuccess: true,
    );

    try {
      final repository = ref.read(transferenciaRepositoryProvider);
      final result = await repository.criarTransferencia(
        CriarTransferenciaRequest(
          numeroDocumento: normalizedNumeroDocumento,
          origem: normalizedOrigem,
          destino: normalizedDestino,
          tipo: tipo,
          observacao: observacao?.trim(),
        ),
      );
      final detail = await repository.obterTransferencia(result.transferenciaId);
      await _refreshPendingOnly();
      state = state.copyWith(
        isCreatingTransfer: false,
        activeTab: TransferenciaTab.produtos,
        activeTransfer: detail,
        successMessage: result.message,
        clearError: true,
      );
    } on ApiFailure catch (e) {
      state = state.copyWith(
        isCreatingTransfer: false,
        errorMessage: e.message,
        clearSuccess: true,
      );
    } catch (e) {
      state = state.copyWith(
        isCreatingTransfer: false,
        errorMessage: e.toString(),
        clearSuccess: true,
      );
    }
  }

  Future<void> selectPendingTransfer(String transferenciaId) async {
    await _loadTransfer(
      transferenciaId,
      tabAfterLoad: TransferenciaTab.produtos,
    );
  }

  Future<void> selectConfirmedTransfer(String transferenciaId) async {
    await _loadTransfer(
      transferenciaId,
      tabAfterLoad: TransferenciaTab.confirmadas,
    );
  }

  Future<void> addItemToActiveTransfer({
    required TransferenciaItemDraft draft,
  }) async {
    final activeTransfer = state.activeTransfer;
    if (activeTransfer == null || !activeTransfer.status.isEditable) {
      state = state.copyWith(
        errorMessage: 'Seleccione uma transferência em rascunho.',
        clearSuccess: true,
      );
      return;
    }

    state = state.copyWith(
      isAddingItem: true,
      clearError: true,
      clearSuccess: true,
    );

    try {
      final updated = await ref.read(transferenciaRepositoryProvider).adicionarItem(
            transferenciaId: activeTransfer.id,
            request: TransferenciaItemRequest(
              produtoId: draft.produtoId,
              loteId: draft.loteId?.trim().isEmpty == true ? null : draft.loteId,
              quantidade: draft.quantidade,
            ),
          );

      await _refreshPendingOnly();

      state = state.copyWith(
        isAddingItem: false,
        activeTransfer: updated,
        successMessage: '${draft.produtoNome} adicionado a transferência.',
        clearError: true,
      );
    } on ApiFailure catch (e) {
      state = state.copyWith(
        isAddingItem: false,
        errorMessage: e.message,
        clearSuccess: true,
      );
    } catch (e) {
      state = state.copyWith(
        isAddingItem: false,
        errorMessage: e.toString(),
        clearSuccess: true,
      );
    }
  }

  Future<void> removeItemFromActiveTransfer(String itemId) async {
    final activeTransfer = state.activeTransfer;
    if (activeTransfer == null || !activeTransfer.status.isEditable) {
      return;
    }

    state = state.copyWith(isAddingItem: true, clearError: true, clearSuccess: true);

    try {
      final updated = await ref.read(transferenciaRepositoryProvider).removerItem(
            transferenciaId: activeTransfer.id,
            itemId: itemId,
          );
      await _refreshPendingOnly();
      state = state.copyWith(
        isAddingItem: false,
        activeTransfer: updated,
        successMessage: 'Item removido da transferência.',
        clearError: true,
      );
    } on ApiFailure catch (e) {
      state = state.copyWith(
        isAddingItem: false,
        errorMessage: e.message,
        clearSuccess: true,
      );
    } catch (e) {
      state = state.copyWith(
        isAddingItem: false,
        errorMessage: e.toString(),
        clearSuccess: true,
      );
    }
  }

  Future<void> confirmActiveTransfer() async {
    final activeTransfer = state.activeTransfer;
    if (activeTransfer == null || !activeTransfer.status.isEditable) {
      state = state.copyWith(
        errorMessage: 'Seleccione uma transferência em rascunho para confirmar.',
        clearSuccess: true,
      );
      return;
    }
    if (activeTransfer.itens.isEmpty) {
      state = state.copyWith(
        errorMessage:
            'Adicione pelo menos um item antes de confirmar a transferência.',
        clearSuccess: true,
      );
      return;
    }

    state = state.copyWith(
      isConfirmingTransfer: true,
      clearError: true,
      clearSuccess: true,
    );

    try {
      final repository = ref.read(transferenciaRepositoryProvider);
      final result = await repository.confirmarTransferencia(activeTransfer.id);
      final updated = await repository.obterTransferencia(activeTransfer.id);
      await refreshLists();
      state = state.copyWith(
        isConfirmingTransfer: false,
        activeTab: TransferenciaTab.concluidas,
        activeTransfer: updated,
        successMessage: result.message,
        clearError: true,
      );
    } on ApiFailure catch (e) {
      state = state.copyWith(
        isConfirmingTransfer: false,
        errorMessage: e.message,
        clearSuccess: true,
      );
    } catch (e) {
      state = state.copyWith(
        isConfirmingTransfer: false,
        errorMessage: e.toString(),
        clearSuccess: true,
      );
    }
  }

  Future<void> cancelActiveTransfer() async {
    final activeTransfer = state.activeTransfer;
    if (activeTransfer == null || !activeTransfer.status.isEditable) {
      return;
    }

    state = state.copyWith(
      isCancellingTransfer: true,
      clearError: true,
      clearSuccess: true,
    );

    try {
      final repository = ref.read(transferenciaRepositoryProvider);
      final result = await repository.cancelarTransferencia(activeTransfer.id);
      final updated = await repository.obterTransferencia(activeTransfer.id);
      await refreshLists();
      state = state.copyWith(
        isCancellingTransfer: false,
        activeTab: TransferenciaTab.pendentes,
        activeTransfer: updated,
        successMessage: result.message,
        clearError: true,
      );
    } on ApiFailure catch (e) {
      state = state.copyWith(
        isCancellingTransfer: false,
        errorMessage: e.message,
        clearSuccess: true,
      );
    } catch (e) {
      state = state.copyWith(
        isCancellingTransfer: false,
        errorMessage: e.toString(),
        clearSuccess: true,
      );
    }
  }

  Future<void> _loadTransfer(
    String transferenciaId, {
    required TransferenciaTab tabAfterLoad,
  }) async {
    state = state.copyWith(
      isLoadingActiveTransfer: true,
      clearError: true,
      clearSuccess: true,
    );

    try {
      final detail = await ref
          .read(transferenciaRepositoryProvider)
          .obterTransferencia(transferenciaId);
      state = state.copyWith(
        isLoadingActiveTransfer: false,
        activeTab: tabAfterLoad,
        activeTransfer: detail,
        clearError: true,
      );
    } on ApiFailure catch (e) {
      state = state.copyWith(
        isLoadingActiveTransfer: false,
        errorMessage: e.message,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingActiveTransfer: false,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> _refreshPendingOnly() async {
    try {
      final pending = await ref
          .read(transferenciaRepositoryProvider)
          .listarTransferencias(status: TransferenciaStatus.rascunho);
      state = state.copyWith(pendingTransfers: pending);
    } catch (_) {
      // Mantem a lista actual se a actualização silenciosa falhar.
    }
  }
}

final transferenciaProvider =
    NotifierProvider.autoDispose<TransferenciaController, TransferenciaState>(
  TransferenciaController.new,
);
