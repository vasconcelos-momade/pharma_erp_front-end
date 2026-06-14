import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/errors/api_failure.dart';
import '../../data/repositories/requisicao_repository_impl.dart';
import '../../domain/entities/requisicao.dart';

enum RequisicaoTab { produtos, pendentes, historico }

class RequisicaoItemDraft {
  const RequisicaoItemDraft({
    required this.produtoId,
    required this.produtoNome,
    required this.quantidadeSolicitada,
    this.loteId,
  });

  final String produtoId;
  final String produtoNome;
  final double quantidadeSolicitada;
  final String? loteId;
}

class RequisicaoCompraItemDraft {
  const RequisicaoCompraItemDraft({
    required this.produtoId,
    required this.produtoNome,
    required this.numeroLote,
    required this.dataValidade,
    required this.quantidade,
    required this.precoCompra,
    this.precoVenda,
  });

  final String produtoId;
  final String produtoNome;
  final String numeroLote;
  final String dataValidade;
  final double quantidade;
  final double precoCompra;
  final double? precoVenda;
}

class RequisicaoState {
  const RequisicaoState({
    this.tipoScope = RequisicaoTipo.saida,
    this.activeTab = RequisicaoTab.produtos,
    this.isLoadingLists = false,
    this.isLoadingActiveRequisicao = false,
    this.isCreatingRequisicao = false,
    this.isUpdatingRequisicao = false,
    this.isAddingItem = false,
    this.isCreatingLote = false,
    this.isApprovingRequisicao = false,
    this.isRejectingRequisicao = false,
    this.isCancellingRequisicao = false,
    this.successMessage,
    this.errorMessage,
    this.activeRequisicao,
    this.pendingRequisicoes = const <RequisicaoResumo>[],
    this.historyRequisicoes = const <RequisicaoResumo>[],
  });

  final RequisicaoTipo tipoScope;
  final RequisicaoTab activeTab;
  final bool isLoadingLists;
  final bool isLoadingActiveRequisicao;
  final bool isCreatingRequisicao;
  final bool isUpdatingRequisicao;
  final bool isAddingItem;
  final bool isCreatingLote;
  final bool isApprovingRequisicao;
  final bool isRejectingRequisicao;
  final bool isCancellingRequisicao;
  final String? successMessage;
  final String? errorMessage;
  final RequisicaoDetalhe? activeRequisicao;
  final List<RequisicaoResumo> pendingRequisicoes;
  final List<RequisicaoResumo> historyRequisicoes;

  bool get canEditActiveRequisicao =>
      activeRequisicao != null && activeRequisicao!.status.isEditable;

  bool get canApproveActiveRequisicao =>
      canEditActiveRequisicao && activeRequisicao!.itens.isNotEmpty;

  bool get canRejectActiveRequisicao => canEditActiveRequisicao;

  bool get canCancelActiveRequisicao => canEditActiveRequisicao;

  RequisicaoState copyWith({
    RequisicaoTipo? tipoScope,
    RequisicaoTab? activeTab,
    bool? isLoadingLists,
    bool? isLoadingActiveRequisicao,
    bool? isCreatingRequisicao,
    bool? isUpdatingRequisicao,
    bool? isAddingItem,
    bool? isCreatingLote,
    bool? isApprovingRequisicao,
    bool? isRejectingRequisicao,
    bool? isCancellingRequisicao,
    String? successMessage,
    String? errorMessage,
    RequisicaoDetalhe? activeRequisicao,
    List<RequisicaoResumo>? pendingRequisicoes,
    List<RequisicaoResumo>? historyRequisicoes,
    bool clearSuccess = false,
    bool clearError = false,
    bool clearActiveRequisicao = false,
  }) {
    return RequisicaoState(
      tipoScope: tipoScope ?? this.tipoScope,
      activeTab: activeTab ?? this.activeTab,
      isLoadingLists: isLoadingLists ?? this.isLoadingLists,
      isLoadingActiveRequisicao:
          isLoadingActiveRequisicao ?? this.isLoadingActiveRequisicao,
      isCreatingRequisicao: isCreatingRequisicao ?? this.isCreatingRequisicao,
      isUpdatingRequisicao: isUpdatingRequisicao ?? this.isUpdatingRequisicao,
      isAddingItem: isAddingItem ?? this.isAddingItem,
      isCreatingLote: isCreatingLote ?? this.isCreatingLote,
      isApprovingRequisicao:
          isApprovingRequisicao ?? this.isApprovingRequisicao,
      isRejectingRequisicao:
          isRejectingRequisicao ?? this.isRejectingRequisicao,
      isCancellingRequisicao:
          isCancellingRequisicao ?? this.isCancellingRequisicao,
      successMessage: clearSuccess ? null : (successMessage ?? this.successMessage),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      activeRequisicao: clearActiveRequisicao
          ? null
          : (activeRequisicao ?? this.activeRequisicao),
      pendingRequisicoes: pendingRequisicoes ?? this.pendingRequisicoes,
      historyRequisicoes: historyRequisicoes ?? this.historyRequisicoes,
    );
  }
}

class RequisicaoController extends Notifier<RequisicaoState> {
  RequisicaoTipo get filterTipo => state.tipoScope;

  @override
  RequisicaoState build() {
    return const RequisicaoState();
  }

  void initializeScope(RequisicaoTipo tipo) {
    if (state.tipoScope != tipo) {
      state = RequisicaoState(tipoScope: tipo);
    }
    Future.microtask(refreshLists);
  }

  void setActiveTab(RequisicaoTab tab) {
    state = state.copyWith(activeTab: tab);
  }

  Future<void> refreshLists() async {
    state = state.copyWith(isLoadingLists: true, clearError: true);

    try {
      final repository = ref.read(requisicaoRepositoryProvider);
      final requisicoes = await repository.listarRequisicoes(tipo: filterTipo);
      state = state.copyWith(
        isLoadingLists: false,
        pendingRequisicoes: requisicoes
            .where((item) => item.status == RequisicaoStatus.pendente)
            .toList(),
        historyRequisicoes: requisicoes
            .where((item) => item.status != RequisicaoStatus.pendente)
            .toList(),
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

  Future<void> startRequisition({
    required String numeroDocumento,
    String? fornecedorId,
    String? origem,
    String? destino,
    RequisicaoTipo? tipo,
    String? observacao,
  }) async {
    final normalizedNumeroDocumento = numeroDocumento.trim();
    final normalizedFornecedorId = fornecedorId?.trim();
    final normalizedOrigem = origem?.trim();
    final normalizedDestino = destino?.trim();
    final effectiveTipo = tipo ?? filterTipo;

    if (effectiveTipo == RequisicaoTipo.compra &&
        (normalizedFornecedorId == null || normalizedFornecedorId.isEmpty)) {
      state = state.copyWith(
        errorMessage: 'Informe o fornecedor para iniciar a requisicao.',
        clearSuccess: true,
      );
      return;
    }

    if (normalizedNumeroDocumento.isEmpty) {
      state = state.copyWith(
        errorMessage: 'Preencha o numero do documento.',
        clearSuccess: true,
      );
      return;
    }

    state = state.copyWith(
      isCreatingRequisicao: true,
      clearError: true,
      clearSuccess: true,
    );

    try {
      final repository = ref.read(requisicaoRepositoryProvider);
      final result = await repository.criarRequisicao(
        CriarRequisicaoRequest(
          numeroDocumento: normalizedNumeroDocumento,
          fornecedorId: normalizedFornecedorId,
          origem: normalizedOrigem,
          destino: normalizedDestino,
          tipo: effectiveTipo,
          observacao: observacao?.trim(),
        ),
      );
      final detail = await repository.obterRequisicao(result.requisicaoId);
      await _refreshListsSilently();
      state = state.copyWith(
        isCreatingRequisicao: false,
        activeTab: RequisicaoTab.produtos,
        activeRequisicao: detail,
        successMessage: result.message,
        clearError: true,
      );
    } on ApiFailure catch (e) {
      state = state.copyWith(
        isCreatingRequisicao: false,
        errorMessage: e.message,
        clearSuccess: true,
      );
    } catch (e) {
      state = state.copyWith(
        isCreatingRequisicao: false,
        errorMessage: e.toString(),
        clearSuccess: true,
      );
    }
  }

  Future<void> selectPendingRequisition(String requisicaoId) async {
    await _loadRequisicao(
      requisicaoId,
      tabAfterLoad: RequisicaoTab.produtos,
    );
  }

  Future<void> selectHistoryRequisition(String requisicaoId) async {
    await _loadRequisicao(
      requisicaoId,
      tabAfterLoad: RequisicaoTab.historico,
    );
  }

  Future<void> addCompraItemToActiveRequisition({
    required RequisicaoCompraItemDraft draft,
  }) async {
    final activeRequisicao = state.activeRequisicao;
    if (activeRequisicao == null || !activeRequisicao.status.isEditable) {
      state = state.copyWith(
        errorMessage: 'Selecione uma requisicao pendente.',
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
      final updated = await ref.read(requisicaoRepositoryProvider).adicionarItem(
            requisicaoId: activeRequisicao.id,
            request: RequisicaoItemRequest(
              produtoId: draft.produtoId,
              quantidadeSolicitada: draft.quantidade,
              numeroLote: draft.numeroLote,
              dataValidade: draft.dataValidade,
              precoCompra: draft.precoCompra,
              precoVenda: draft.precoVenda,
            ),
          );

      await _refreshListsSilently();

      state = state.copyWith(
        isAddingItem: false,
        activeRequisicao: updated,
        successMessage: '${draft.produtoNome} adicionado a requisicao.',
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

  Future<void> updateCompraItemInActiveRequisition({
    required RequisicaoItem item,
    required RequisicaoCompraItemDraft draft,
  }) async {
    final activeRequisicao = state.activeRequisicao;
    if (activeRequisicao == null || !activeRequisicao.status.isEditable) {
      state = state.copyWith(
        errorMessage: 'Selecione uma requisicao pendente.',
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
      final updated = await ref.read(requisicaoRepositoryProvider).atualizarItem(
            requisicaoId: activeRequisicao.id,
            itemId: item.id,
            request: RequisicaoItemRequest(
              produtoId: draft.produtoId,
              quantidadeSolicitada: draft.quantidade,
              numeroLote: draft.numeroLote,
              dataValidade: draft.dataValidade,
              precoCompra: draft.precoCompra,
              precoVenda: draft.precoVenda,
            ),
          );

      await _refreshListsSilently();

      state = state.copyWith(
        isAddingItem: false,
        activeRequisicao: updated,
        successMessage: '${draft.produtoNome} actualizado na requisicao.',
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

  Future<void> addItemToActiveRequisition({
    required RequisicaoItemDraft draft,
  }) async {
    final activeRequisicao = state.activeRequisicao;
    if (activeRequisicao == null || !activeRequisicao.status.isEditable) {
      state = state.copyWith(
        errorMessage: 'Selecione uma requisicao pendente.',
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
      final updated = await ref.read(requisicaoRepositoryProvider).adicionarItem(
            requisicaoId: activeRequisicao.id,
            request: RequisicaoItemRequest(
              produtoId: draft.produtoId,
              loteId: draft.loteId?.trim().isEmpty == true ? null : draft.loteId,
              quantidadeSolicitada: draft.quantidadeSolicitada,
            ),
          );

      await _refreshListsSilently();

      state = state.copyWith(
        isAddingItem: false,
        activeRequisicao: updated,
        successMessage: '${draft.produtoNome} adicionado a requisicao.',
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

  Future<void> updateItemInActiveRequisition({
    required RequisicaoItem item,
    required double quantidadeSolicitada,
  }) async {
    final activeRequisicao = state.activeRequisicao;
    if (activeRequisicao == null || !activeRequisicao.status.isEditable) {
      state = state.copyWith(
        errorMessage: 'Selecione uma requisicao pendente.',
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
      final updated = await ref.read(requisicaoRepositoryProvider).atualizarItem(
            requisicaoId: activeRequisicao.id,
            itemId: item.id,
            request: RequisicaoItemRequest(
              produtoId: item.produtoId,
              quantidadeSolicitada: quantidadeSolicitada,
              loteId: item.lote?.id,
            ),
          );

      await _refreshListsSilently();

      state = state.copyWith(
        isAddingItem: false,
        activeRequisicao: updated,
        successMessage: '${item.produtoNome} actualizado na requisicao.',
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

  Future<void> updateActiveRequisitionHeader({
    required AtualizarRequisicaoRequest request,
  }) async {
    final activeRequisicao = state.activeRequisicao;
    if (activeRequisicao == null || !activeRequisicao.status.isEditable) {
      state = state.copyWith(
        errorMessage: 'Selecione uma requisicao pendente.',
        clearSuccess: true,
      );
      return;
    }

    state = state.copyWith(
      isUpdatingRequisicao: true,
      clearError: true,
      clearSuccess: true,
    );

    try {
      final updated = await ref.read(requisicaoRepositoryProvider).atualizarRequisicao(
            requisicaoId: activeRequisicao.id,
            request: request,
          );

      await _refreshListsSilently();

      state = state.copyWith(
        isUpdatingRequisicao: false,
        activeRequisicao: updated,
        successMessage: 'Requisicao actualizada com sucesso.',
        clearError: true,
      );
    } on ApiFailure catch (e) {
      state = state.copyWith(
        isUpdatingRequisicao: false,
        errorMessage: e.message,
        clearSuccess: true,
      );
    } catch (e) {
      state = state.copyWith(
        isUpdatingRequisicao: false,
        errorMessage: e.toString(),
        clearSuccess: true,
      );
    }
  }

  Future<void> removeItemFromActiveRequisition(String itemId) async {
    final activeRequisicao = state.activeRequisicao;
    if (activeRequisicao == null || !activeRequisicao.status.isEditable) {
      return;
    }

    state = state.copyWith(isAddingItem: true, clearError: true, clearSuccess: true);

    try {
      final updated = await ref.read(requisicaoRepositoryProvider).removerItem(
            requisicaoId: activeRequisicao.id,
            itemId: itemId,
          );
      await _refreshListsSilently();
      state = state.copyWith(
        isAddingItem: false,
        activeRequisicao: updated,
        successMessage: 'Item removido da requisicao.',
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

  Future<void> approveActiveRequisition() async {
    final activeRequisicao = state.activeRequisicao;
    if (activeRequisicao == null || !activeRequisicao.status.isEditable) {
      state = state.copyWith(
        errorMessage: 'Selecione uma requisicao pendente para aprovar.',
        clearSuccess: true,
      );
      return;
    }
    if (activeRequisicao.itens.isEmpty) {
      state = state.copyWith(
        errorMessage: 'Adicione pelo menos um item antes de aprovar a requisicao.',
        clearSuccess: true,
      );
      return;
    }

    state = state.copyWith(
      isApprovingRequisicao: true,
      clearError: true,
      clearSuccess: true,
    );

    try {
      final repository = ref.read(requisicaoRepositoryProvider);
      final result = await repository.aprovarRequisicao(activeRequisicao.id);
      final updated = await repository.obterRequisicao(activeRequisicao.id);
      await refreshLists();
      state = state.copyWith(
        isApprovingRequisicao: false,
        activeTab: RequisicaoTab.historico,
        activeRequisicao: updated,
        successMessage: result.message,
        clearError: true,
      );
    } on ApiFailure catch (e) {
      state = state.copyWith(
        isApprovingRequisicao: false,
        errorMessage: e.message,
        clearSuccess: true,
      );
    } catch (e) {
      state = state.copyWith(
        isApprovingRequisicao: false,
        errorMessage: e.toString(),
        clearSuccess: true,
      );
    }
  }

  Future<void> rejectActiveRequisition() async {
    final activeRequisicao = state.activeRequisicao;
    if (activeRequisicao == null || !activeRequisicao.status.isEditable) {
      state = state.copyWith(
        errorMessage: 'Selecione uma requisicao pendente para rejeitar.',
        clearSuccess: true,
      );
      return;
    }

    state = state.copyWith(
      isRejectingRequisicao: true,
      clearError: true,
      clearSuccess: true,
    );

    try {
      final repository = ref.read(requisicaoRepositoryProvider);
      final result = await repository.rejeitarRequisicao(activeRequisicao.id);
      final updated = await repository.obterRequisicao(activeRequisicao.id);
      await refreshLists();
      state = state.copyWith(
        isRejectingRequisicao: false,
        activeTab: RequisicaoTab.historico,
        activeRequisicao: updated,
        successMessage: result.message,
        clearError: true,
      );
    } on ApiFailure catch (e) {
      state = state.copyWith(
        isRejectingRequisicao: false,
        errorMessage: e.message,
        clearSuccess: true,
      );
    } catch (e) {
      state = state.copyWith(
        isRejectingRequisicao: false,
        errorMessage: e.toString(),
        clearSuccess: true,
      );
    }
  }

  Future<void> cancelActiveRequisition() async {
    final activeRequisicao = state.activeRequisicao;
    if (activeRequisicao == null || !activeRequisicao.status.isEditable) {
      return;
    }

    state = state.copyWith(
      isCancellingRequisicao: true,
      clearError: true,
      clearSuccess: true,
    );

    try {
      final repository = ref.read(requisicaoRepositoryProvider);
      final result = await repository.cancelarRequisicao(activeRequisicao.id);
      final updated = await repository.obterRequisicao(activeRequisicao.id);
      await refreshLists();
      state = state.copyWith(
        isCancellingRequisicao: false,
        activeTab: RequisicaoTab.historico,
        activeRequisicao: updated,
        successMessage: result.message,
        clearError: true,
      );
    } on ApiFailure catch (e) {
      state = state.copyWith(
        isCancellingRequisicao: false,
        errorMessage: e.message,
        clearSuccess: true,
      );
    } catch (e) {
      state = state.copyWith(
        isCancellingRequisicao: false,
        errorMessage: e.toString(),
        clearSuccess: true,
      );
    }
  }

  Future<void> _loadRequisicao(
    String requisicaoId, {
    required RequisicaoTab tabAfterLoad,
  }) async {
    state = state.copyWith(
      isLoadingActiveRequisicao: true,
      clearError: true,
      clearSuccess: true,
    );

    try {
      final detail = await ref
          .read(requisicaoRepositoryProvider)
          .obterRequisicao(requisicaoId);
      state = state.copyWith(
        isLoadingActiveRequisicao: false,
        activeTab: tabAfterLoad,
        activeRequisicao: detail,
        clearError: true,
      );
    } on ApiFailure catch (e) {
      state = state.copyWith(
        isLoadingActiveRequisicao: false,
        errorMessage: e.message,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingActiveRequisicao: false,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> _refreshListsSilently() async {
    try {
      final requisicoes = await ref
          .read(requisicaoRepositoryProvider)
          .listarRequisicoes(tipo: filterTipo);
      state = state.copyWith(
        pendingRequisicoes: requisicoes
            .where((item) => item.status == RequisicaoStatus.pendente)
            .toList(),
        historyRequisicoes: requisicoes
            .where((item) => item.status != RequisicaoStatus.pendente)
            .toList(),
      );
    } catch (_) {
      // Mantem as listas actuais se a actualizacao silenciosa falhar.
    }
  }

  Future<CriarLoteResult?> criarLote({
    required String produtoId,
    required String fornecedorId,
    required String numeroLote,
    required DateTime dataValidade,
    double? precoCompra,
  }) async {
    state = state.copyWith(
      isCreatingLote: true,
      clearError: true,
      clearSuccess: true,
    );

    try {
      final repository = ref.read(requisicaoRepositoryProvider);
      final result = await repository.criarLote(
        CriarLoteRequest(
          produtoId: produtoId,
          fornecedorId: fornecedorId,
          numeroLote: numeroLote,
          dataValidade: dataValidade,
          precoCompra: precoCompra,
        ),
      );
      state = state.copyWith(
        isCreatingLote: false,
        successMessage: result.message,
        clearError: true,
      );
      return result;
    } on ApiFailure catch (e) {
      state = state.copyWith(
        isCreatingLote: false,
        errorMessage: e.message,
        clearSuccess: true,
      );
      return null;
    } catch (e) {
      state = state.copyWith(
        isCreatingLote: false,
        errorMessage: e.toString(),
        clearSuccess: true,
      );
      return null;
    }
  }
}

final requisicaoProvider =
    NotifierProvider.autoDispose<RequisicaoController, RequisicaoState>(
  RequisicaoController.new,
);

class RequisicaoCompraController extends RequisicaoController {
  @override
  RequisicaoState build() {
    Future.microtask(refreshLists);
    return const RequisicaoState(tipoScope: RequisicaoTipo.compra);
  }

  @override
  RequisicaoTipo get filterTipo => RequisicaoTipo.compra;
}

final requisicaoCompraProvider =
    NotifierProvider.autoDispose<RequisicaoCompraController, RequisicaoState>(
  RequisicaoCompraController.new,
);
