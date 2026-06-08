import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/errors/api_failure.dart';
import '../../../pharmacy/products/domain/entities/product.dart';
import '../../data/repositories/compra_repository_impl.dart';
import '../../domain/entities/compra.dart';

enum CompraTab { produtos, pendentes, finalizadas }

final supplierListProvider = FutureProvider<List<FornecedorResumo>>((ref) async {
  final repository = ref.read(compraRepositoryProvider);
  return repository.listarFornecedores();
});

class CompraItemDraft {
  const CompraItemDraft({
    required this.product,
    required this.numeroLote,
    required this.dataValidade,
    required this.quantidade,
    required this.precoCompra,
    this.precoVenda,
  });

  final Product product;
  final String numeroLote;
  final String dataValidade;
  final double quantidade;
  final double precoCompra;
  final double? precoVenda;
}

class CompraState {
  const CompraState({
    this.activeTab = CompraTab.produtos,
    this.isLoadingLists = false,
    this.isLoadingActivePurchase = false,
    this.isCreatingPurchase = false,
    this.isAddingItem = false,
    this.isConfirmingPurchase = false,
    this.successMessage,
    this.errorMessage,
    this.activePurchase,
    this.lastReceipt,
    this.pendingPurchases = const <CompraResumo>[],
    this.finalizedPurchases = const <CompraResumo>[],
  });

  final CompraTab activeTab;
  final bool isLoadingLists;
  final bool isLoadingActivePurchase;
  final bool isCreatingPurchase;
  final bool isAddingItem;
  final bool isConfirmingPurchase;
  final String? successMessage;
  final String? errorMessage;
  final CompraDetalhe? activePurchase;
  final CompraReceipt? lastReceipt;
  final List<CompraResumo> pendingPurchases;
  final List<CompraResumo> finalizedPurchases;

  bool get isBusy =>
      isLoadingLists ||
      isLoadingActivePurchase ||
      isCreatingPurchase ||
      isAddingItem ||
      isConfirmingPurchase;

  bool get hasActivePurchase => activePurchase != null;

  bool get canEditActivePurchase =>
      activePurchase != null && activePurchase!.status.isEditable;

  bool get canConfirmActivePurchase =>
      canEditActivePurchase && activePurchase!.items.isNotEmpty;

  CompraState copyWith({
    CompraTab? activeTab,
    bool? isLoadingLists,
    bool? isLoadingActivePurchase,
    bool? isCreatingPurchase,
    bool? isAddingItem,
    bool? isConfirmingPurchase,
    String? successMessage,
    String? errorMessage,
    CompraDetalhe? activePurchase,
    CompraReceipt? lastReceipt,
    List<CompraResumo>? pendingPurchases,
    List<CompraResumo>? finalizedPurchases,
    bool clearSuccess = false,
    bool clearError = false,
    bool clearReceipt = false,
    bool clearActivePurchase = false,
  }) {
    return CompraState(
      activeTab: activeTab ?? this.activeTab,
      isLoadingLists: isLoadingLists ?? this.isLoadingLists,
      isLoadingActivePurchase:
          isLoadingActivePurchase ?? this.isLoadingActivePurchase,
      isCreatingPurchase: isCreatingPurchase ?? this.isCreatingPurchase,
      isAddingItem: isAddingItem ?? this.isAddingItem,
      isConfirmingPurchase:
          isConfirmingPurchase ?? this.isConfirmingPurchase,
      successMessage: clearSuccess ? null : (successMessage ?? this.successMessage),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      activePurchase:
          clearActivePurchase ? null : (activePurchase ?? this.activePurchase),
      lastReceipt: clearReceipt ? null : (lastReceipt ?? this.lastReceipt),
      pendingPurchases: pendingPurchases ?? this.pendingPurchases,
      finalizedPurchases: finalizedPurchases ?? this.finalizedPurchases,
    );
  }
}

class CompraController extends Notifier<CompraState> {
  @override
  CompraState build() {
    Future.microtask(refreshLists);
    return const CompraState();
  }

  void setActiveTab(CompraTab tab) {
    state = state.copyWith(activeTab: tab);
  }

  Future<void> refreshLists() async {
    state = state.copyWith(
      isLoadingLists: true,
      clearError: true,
    );

    try {
      final repository = ref.read(compraRepositoryProvider);
      final pending = await repository.listarCompras(status: CompraStatus.pendente);
      final finalized = await repository.listarCompras(status: CompraStatus.recebida);
      state = state.copyWith(
        isLoadingLists: false,
        pendingPurchases: pending,
        finalizedPurchases: finalized,
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

  Future<void> startPurchase(String fornecedorId) async {
    final normalizedFornecedorId = fornecedorId.trim();
    if (normalizedFornecedorId.isEmpty) {
      state = state.copyWith(
        errorMessage: 'Informe o fornecedor para iniciar a compra.',
        clearSuccess: true,
      );
      return;
    }

    state = state.copyWith(
      isCreatingPurchase: true,
      clearError: true,
      clearSuccess: true,
    );

    try {
      final repository = ref.read(compraRepositoryProvider);
      final summary = await repository.criarCompraPendente(
        CriarCompraPendenteRequest(fornecedorId: normalizedFornecedorId),
      );
      final detail = await repository.obterCompra(summary.id);
      final nextPending = <CompraResumo>[
        summary,
        ...state.pendingPurchases.where((item) => item.id != summary.id),
      ];

      state = state.copyWith(
        isCreatingPurchase: false,
        activeTab: CompraTab.produtos,
        activePurchase: detail,
        pendingPurchases: nextPending,
        successMessage: 'Compra pendente criada com sucesso.',
        clearError: true,
      );
    } on ApiFailure catch (e) {
      state = state.copyWith(
        isCreatingPurchase: false,
        errorMessage: e.message,
        clearSuccess: true,
      );
    } catch (e) {
      state = state.copyWith(
        isCreatingPurchase: false,
        errorMessage: e.toString(),
        clearSuccess: true,
      );
    }
  }

  Future<void> selectPendingPurchase(String compraId) async {
    await _loadPurchase(compraId, tabAfterLoad: CompraTab.produtos);
  }

  Future<void> selectFinalizedPurchase(String compraId) async {
    await _loadPurchase(compraId, tabAfterLoad: CompraTab.finalizadas);
  }

  Future<void> addItemToActivePurchase({
    required Product product,
    required CompraItemDraft draft,
  }) async {
    final activePurchase = state.activePurchase;
    if (activePurchase == null || !activePurchase.status.isEditable) {
      state = state.copyWith(
        errorMessage: 'Seleccione uma compra pendente para adicionar itens.',
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
      final updated = await ref.read(compraRepositoryProvider).adicionarItem(
            compraId: activePurchase.id,
            request: CompraItemRequest(
              produtoId: product.id,
              numeroLote: draft.numeroLote,
              dataValidade: draft.dataValidade,
              quantidade: draft.quantidade,
              precoCompra: draft.precoCompra,
              precoVenda: draft.precoVenda,
            ),
          );

      await _refreshPendingOnly();

      state = state.copyWith(
        isAddingItem: false,
        activePurchase: updated,
        successMessage: '${product.nome} adicionado a compra activa.',
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

  Future<void> removeItemFromActivePurchase(String itemId) async {
    final activePurchase = state.activePurchase;
    if (activePurchase == null || !activePurchase.status.isEditable) {
      return;
    }

    state = state.copyWith(
      isAddingItem: true, // Reuse adding state for busy indicator
      clearError: true,
      clearSuccess: true,
    );

    try {
      final updated = await ref.read(compraRepositoryProvider).removerItem(
            compraId: activePurchase.id,
            itemId: itemId,
          );

      await _refreshPendingOnly();

      state = state.copyWith(
        isAddingItem: false,
        activePurchase: updated,
        successMessage: 'Item removido da compra.',
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

  Future<void> confirmActivePurchase() async {
    final activePurchase = state.activePurchase;
    if (activePurchase == null || !activePurchase.status.isEditable) {
      state = state.copyWith(
        errorMessage: 'Seleccione uma compra pendente para confirmar.',
        clearSuccess: true,
      );
      return;
    }
    if (activePurchase.items.isEmpty) {
      state = state.copyWith(
        errorMessage: 'Adicione pelo menos um item antes de confirmar a compra.',
        clearSuccess: true,
      );
      return;
    }

    state = state.copyWith(
      isConfirmingPurchase: true,
      clearError: true,
      clearSuccess: true,
    );

    try {
      final repository = ref.read(compraRepositoryProvider);
      final receipt = await repository.confirmarCompra(activePurchase.id);
      CompraDetalhe updatedPurchase;
      try {
        updatedPurchase = await repository.obterCompra(activePurchase.id);
      } on Object {
        updatedPurchase = activePurchase.copyWith(
          status: CompraStatus.recebida,
          total: receipt.total,
        );
      }

      await refreshLists();

      state = state.copyWith(
        isConfirmingPurchase: false,
        activeTab: CompraTab.finalizadas,
        activePurchase: updatedPurchase,
        lastReceipt: receipt,
        successMessage: receipt.message,
        clearError: true,
      );
    } on ApiFailure catch (e) {
      state = state.copyWith(
        isConfirmingPurchase: false,
        errorMessage: e.message,
        clearSuccess: true,
      );
    } catch (e) {
      state = state.copyWith(
        isConfirmingPurchase: false,
        errorMessage: e.toString(),
        clearSuccess: true,
      );
    }
  }

  Future<void> _loadPurchase(
    String compraId, {
    required CompraTab tabAfterLoad,
  }) async {
    state = state.copyWith(
      isLoadingActivePurchase: true,
      clearError: true,
      clearSuccess: true,
    );

    try {
      final detail = await ref.read(compraRepositoryProvider).obterCompra(compraId);
      state = state.copyWith(
        isLoadingActivePurchase: false,
        activeTab: tabAfterLoad,
        activePurchase: detail,
        clearError: true,
      );
    } on ApiFailure catch (e) {
      state = state.copyWith(
        isLoadingActivePurchase: false,
        errorMessage: e.message,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingActivePurchase: false,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> _refreshPendingOnly() async {
    try {
      final pending = await ref
          .read(compraRepositoryProvider)
          .listarCompras(status: CompraStatus.pendente);
      state = state.copyWith(pendingPurchases: pending);
    } catch (_) {
      // Mantem a lista actual caso a actualização silenciosa falhe.
    }
  }
}

final compraProvider = NotifierProvider.autoDispose<CompraController, CompraState>(
  CompraController.new,
);
