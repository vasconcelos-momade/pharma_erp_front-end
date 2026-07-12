import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/constants/api_constants.dart';
import '../../../../../core/contracts/api_envelope.dart';
import '../../../../../core/errors/api_failure.dart';
import '../../../../../core/network/dio/dio_provider.dart';

enum PurchaseSuggestionOriginFilter { todas, automatica, manual }

class PurchaseSuggestionDashboard {
  const PurchaseSuggestionDashboard({
    this.produtosAbaixoMinimo = 0,
    this.produtosSemStock = 0,
    this.valorEstimadoCompra = 0,
    this.quantidadeTotalSugerida = 0,
    this.fornecedoresEnvolvidos = 0,
  });

  final int produtosAbaixoMinimo;
  final int produtosSemStock;
  final num valorEstimadoCompra;
  final num quantidadeTotalSugerida;
  final int fornecedoresEnvolvidos;

  factory PurchaseSuggestionDashboard.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const PurchaseSuggestionDashboard();
    return PurchaseSuggestionDashboard(
      produtosAbaixoMinimo: json['produtosAbaixoMinimo'] as int? ?? 0,
      produtosSemStock: json['produtosSemStock'] as int? ?? 0,
      valorEstimadoCompra: json['valorEstimadoCompra'] as num? ?? 0,
      quantidadeTotalSugerida: json['quantidadeTotalSugerida'] as num? ?? 0,
      fornecedoresEnvolvidos: json['fornecedoresEnvolvidos'] as int? ?? 0,
    );
  }
}

class PurchaseSuggestionItem {
  const PurchaseSuggestionItem({
    required this.id,
    required this.produtoId,
    required this.produtoNome,
    required this.categoriaNome,
    required this.fornecedorNome,
    required this.consumoMedioDiario,
    required this.estoqueAtual,
    required this.estoqueMinimo,
    required this.coberturaDias,
    required this.quantidadeSugerida,
    required this.quantidadeAprovada,
    required this.ultimoPreco,
    required this.valorEstimado,
    required this.unidade,
    required this.origem,
    this.fornecedorId,
    this.observacao,
    this.selected = true,
  });

  final String id;
  final String produtoId;
  final String produtoNome;
  final String categoriaNome;
  final String? fornecedorId;
  final String fornecedorNome;
  final num consumoMedioDiario;
  final num estoqueAtual;
  final num estoqueMinimo;
  final int coberturaDias;
  final num quantidadeSugerida;
  final num quantidadeAprovada;
  final num ultimoPreco;
  final num valorEstimado;
  final String unidade;
  final String origem;
  final String? observacao;
  final bool selected;

  bool get isManual => origem == 'MANUAL';

  String get origemLabel => isManual ? 'Manual' : 'Automática';

  num get subtotalAprovado => quantidadeAprovada * ultimoPreco;

  PurchaseSuggestionItem copyWith({
    num? quantidadeAprovada,
    bool? selected,
  }) {
    final approved = quantidadeAprovada ?? this.quantidadeAprovada;
    return PurchaseSuggestionItem(
      id: id,
      produtoId: produtoId,
      produtoNome: produtoNome,
      categoriaNome: categoriaNome,
      fornecedorId: fornecedorId,
      fornecedorNome: fornecedorNome,
      consumoMedioDiario: consumoMedioDiario,
      estoqueAtual: estoqueAtual,
      estoqueMinimo: estoqueMinimo,
      coberturaDias: coberturaDias,
      quantidadeSugerida: quantidadeSugerida,
      quantidadeAprovada: approved,
      ultimoPreco: ultimoPreco,
      valorEstimado: valorEstimado,
      unidade: unidade,
      origem: origem,
      observacao: observacao,
      selected: selected ?? this.selected,
    );
  }

  static num _readNum(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value;
    return num.tryParse(value.toString()) ?? 0;
  }

  factory PurchaseSuggestionItem.fromJson(Map<String, dynamic> json) {
    final quantidadeSugerida = _readNum(json['quantidadeSugerida']);
    return PurchaseSuggestionItem(
      id: json['id']?.toString() ?? '',
      produtoId: json['produtoId']?.toString() ?? '',
      produtoNome: json['produtoNome']?.toString() ?? '—',
      categoriaNome: json['categoriaNome']?.toString() ?? '—',
      fornecedorId: json['fornecedorId']?.toString(),
      fornecedorNome: json['fornecedorNome']?.toString() ?? 'Sem fornecedor',
      consumoMedioDiario: _readNum(json['consumoMedioDiario']),
      estoqueAtual: _readNum(json['estoqueAtual']),
      estoqueMinimo: _readNum(json['estoqueMinimo']),
      coberturaDias: json['coberturaDias'] as int? ?? 30,
      quantidadeSugerida: quantidadeSugerida,
      quantidadeAprovada: quantidadeSugerida,
      ultimoPreco: _readNum(json['ultimoPreco']),
      valorEstimado: _readNum(json['valorEstimado']),
      unidade: json['unidade']?.toString() ?? 'un',
      origem: json['origem']?.toString() ?? 'AUTOMATICA',
      observacao: json['observacao']?.toString(),
    );
  }

  Map<String, dynamic> toCreatePayload() {
    return <String, dynamic>{
      'produtoId': produtoId,
      'quantidadeSugerida': quantidadeSugerida,
      'quantidadeAprovada': quantidadeAprovada,
      if (fornecedorId != null) 'fornecedorId': fornecedorId,
    };
  }
}

class PurchaseSuggestionsState {
  const PurchaseSuggestionsState({
    this.items = const <PurchaseSuggestionItem>[],
    this.selectedCatalog = const <String, PurchaseSuggestionItem>{},
    this.dashboard = const PurchaseSuggestionDashboard(),
    this.search = '',
    this.originFilter = PurchaseSuggestionOriginFilter.todas,
    this.page = 1,
    this.pageSize = 20,
    this.totalCount,
    this.hasMore = false,
    this.isLoading = false,
    this.isCreating = false,
    this.isMutating = false,
    this.errorMessage,
    this.successMessage,
  });

  final List<PurchaseSuggestionItem> items;
  final Map<String, PurchaseSuggestionItem> selectedCatalog;
  final PurchaseSuggestionDashboard dashboard;
  final String search;
  final PurchaseSuggestionOriginFilter originFilter;
  final int page;
  final int pageSize;
  final int? totalCount;
  final bool hasMore;
  final bool isLoading;
  final bool isCreating;
  final bool isMutating;
  final String? errorMessage;
  final String? successMessage;

  bool get allSelected => items.isNotEmpty && items.every((item) => item.selected);

  int get selectedCount => selectedCatalog.length;

  List<PurchaseSuggestionItem> get selectedItems => selectedCatalog.values
      .where((item) => item.quantidadeAprovada > 0)
      .toList(growable: false);

  PurchaseSuggestionsState copyWith({
    List<PurchaseSuggestionItem>? items,
    Map<String, PurchaseSuggestionItem>? selectedCatalog,
    PurchaseSuggestionDashboard? dashboard,
    String? search,
    PurchaseSuggestionOriginFilter? originFilter,
    int? page,
    int? pageSize,
    int? totalCount,
    bool? hasMore,
    bool? isLoading,
    bool? isCreating,
    bool? isMutating,
    String? errorMessage,
    String? successMessage,
    bool clearMessages = false,
  }) {
    return PurchaseSuggestionsState(
      items: items ?? this.items,
      selectedCatalog: selectedCatalog ?? this.selectedCatalog,
      dashboard: dashboard ?? this.dashboard,
      search: search ?? this.search,
      originFilter: originFilter ?? this.originFilter,
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
      totalCount: totalCount ?? this.totalCount,
      hasMore: hasMore ?? this.hasMore,
      isLoading: isLoading ?? this.isLoading,
      isCreating: isCreating ?? this.isCreating,
      isMutating: isMutating ?? this.isMutating,
      errorMessage: clearMessages ? null : (errorMessage ?? this.errorMessage),
      successMessage: clearMessages ? null : (successMessage ?? this.successMessage),
    );
  }
}

class PurchaseSuggestionsController extends Notifier<PurchaseSuggestionsState> {
  @override
  PurchaseSuggestionsState build() {
    Future.microtask(load);
    return const PurchaseSuggestionsState(isLoading: true);
  }

  Map<String, dynamic> _queryParams() {
    return <String, dynamic>{
      if (state.search.trim().isNotEmpty) 'q': state.search.trim(),
      if (state.originFilter != PurchaseSuggestionOriginFilter.todas)
        'origem': switch (state.originFilter) {
          PurchaseSuggestionOriginFilter.automatica => 'AUTOMATICA',
          PurchaseSuggestionOriginFilter.manual => 'MANUAL',
          PurchaseSuggestionOriginFilter.todas => 'TODAS',
        },
      'page': state.page,
      'pageSize': state.pageSize,
    };
  }

  Future<void> setSearch(String value) async {
    state = state.copyWith(search: value, page: 1, isLoading: true, clearMessages: true);
    await load();
  }

  Future<void> setOriginFilter(PurchaseSuggestionOriginFilter filter) async {
    state = state.copyWith(originFilter: filter, page: 1, isLoading: true, clearMessages: true);
    await load();
  }

  Future<void> goToPage(int page) async {
    if (page < 1 || page == state.page) return;
    state = state.copyWith(page: page, isLoading: true, clearMessages: true);
    await load();
  }

  Future<void> setPageSize(int pageSize) async {
    if (pageSize == state.pageSize) return;
    state = state.copyWith(pageSize: pageSize, page: 1, isLoading: true, clearMessages: true);
    await load();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearMessages: true);
    try {
      final dio = ref.read(dioProvider);
      final response = await dio.get<Map<String, dynamic>>(
        ApiConstants.tenantComprasSugestoes,
        queryParameters: _queryParams(),
      );
      final payload = ApiEnvelope.unwrapMap(response.data ?? {});
      final catalog = Map<String, PurchaseSuggestionItem>.from(state.selectedCatalog);
      final items = (payload['items'] as List<dynamic>? ?? <dynamic>[])
          .whereType<Map<String, dynamic>>()
          .map(PurchaseSuggestionItem.fromJson)
          .map((item) {
            final selected = catalog[item.produtoId];
            if (selected != null) {
              return item.copyWith(
                selected: true,
                quantidadeAprovada: selected.quantidadeAprovada,
              );
            }
            return item;
          })
          .toList();

      state = state.copyWith(
        items: items,
        dashboard: PurchaseSuggestionDashboard.fromJson(
          payload['dashboard'] as Map<String, dynamic>?,
        ),
        totalCount: payload['totalCount'] as int? ?? payload['totalItens'] as int?,
        hasMore: payload['hasMore'] as bool? ?? false,
        page: payload['page'] as int? ?? state.page,
        pageSize: payload['pageSize'] as int? ?? state.pageSize,
        isLoading: false,
        clearMessages: true,
      );
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: ApiFailure.fromDio(e).message,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  void toggleSelectAll(bool? value) {
    final selected = value ?? false;
    final catalog = Map<String, PurchaseSuggestionItem>.from(state.selectedCatalog);
    final items = state.items.map((item) {
      final updated = item.copyWith(selected: selected);
      if (selected && updated.quantidadeAprovada > 0) {
        catalog[updated.produtoId] = updated;
      } else {
        catalog.remove(updated.produtoId);
      }
      return updated;
    }).toList();
    state = state.copyWith(items: items, selectedCatalog: catalog, clearMessages: true);
  }

  void toggleItem(String produtoId, bool? value) {
    final catalog = Map<String, PurchaseSuggestionItem>.from(state.selectedCatalog);
    final items = state.items.map((item) {
      if (item.produtoId != produtoId) return item;
      final updated = item.copyWith(selected: value ?? false);
      if (updated.selected && updated.quantidadeAprovada > 0) {
        catalog[updated.produtoId] = updated;
      } else {
        catalog.remove(updated.produtoId);
      }
      return updated;
    }).toList();
    state = state.copyWith(items: items, selectedCatalog: catalog, clearMessages: true);
  }

  void updateQuantidadeAprovada(String produtoId, String rawValue) {
    final parsed = num.tryParse(rawValue.replaceAll(',', '.')) ?? 0;
    final approved = parsed < 0 ? 0 : parsed;
    final catalog = Map<String, PurchaseSuggestionItem>.from(state.selectedCatalog);
    final items = state.items.map((item) {
      if (item.produtoId != produtoId) return item;
      final updated = item.copyWith(quantidadeAprovada: approved);
      if (updated.selected && updated.quantidadeAprovada > 0) {
        catalog[updated.produtoId] = updated;
      } else {
        catalog.remove(updated.produtoId);
      }
      return updated;
    }).toList();
    state = state.copyWith(items: items, selectedCatalog: catalog, clearMessages: true);
  }

  Future<void> addManualSuggestion({
    required String produtoId,
    required num quantidadeSugerida,
    String? observacao,
  }) async {
    state = state.copyWith(isMutating: true, clearMessages: true);
    try {
      final dio = ref.read(dioProvider);
      final response = await dio.post<Map<String, dynamic>>(
        ApiConstants.tenantComprasSugestoes,
        data: <String, dynamic>{
          'produtoId': produtoId,
          'quantidadeSugerida': quantidadeSugerida,
          if (observacao != null && observacao.trim().isNotEmpty) 'observacao': observacao.trim(),
        },
      );
      final payload = ApiEnvelope.unwrapMap(response.data ?? {});
      state = state.copyWith(
        isMutating: false,
        successMessage: payload['message']?.toString() ?? 'Produto adicionado',
      );
      await load();
    } on DioException catch (e) {
      state = state.copyWith(
        isMutating: false,
        errorMessage: ApiFailure.fromDio(e).message,
      );
    } catch (e) {
      state = state.copyWith(isMutating: false, errorMessage: e.toString());
    }
  }

  Future<void> removeSuggestion(String produtoId) async {
    state = state.copyWith(isMutating: true, clearMessages: true);
    try {
      final dio = ref.read(dioProvider);
      await dio.delete<Map<String, dynamic>>(
        ApiConstants.tenantCompraSugestao(produtoId),
      );
      final catalog = Map<String, PurchaseSuggestionItem>.from(state.selectedCatalog)
        ..remove(produtoId);
      state = state.copyWith(
        isMutating: false,
        selectedCatalog: catalog,
        successMessage: 'Sugestão removida',
      );
      await load();
    } on DioException catch (e) {
      state = state.copyWith(
        isMutating: false,
        errorMessage: ApiFailure.fromDio(e).message,
      );
    } catch (e) {
      state = state.copyWith(isMutating: false, errorMessage: e.toString());
    }
  }

  Future<void> clearSuggestions() async {
    state = state.copyWith(isMutating: true, clearMessages: true);
    try {
      final dio = ref.read(dioProvider);
      final response = await dio.delete<Map<String, dynamic>>(
        ApiConstants.tenantComprasSugestoes,
      );
      final payload = ApiEnvelope.unwrapMap(response.data ?? {});
      state = state.copyWith(
        isMutating: false,
        selectedCatalog: const {},
        successMessage: payload['message']?.toString() ?? 'Lista limpa',
      );
      await load();
    } on DioException catch (e) {
      state = state.copyWith(
        isMutating: false,
        errorMessage: ApiFailure.fromDio(e).message,
      );
    } catch (e) {
      state = state.copyWith(isMutating: false, errorMessage: e.toString());
    }
  }
}

final purchaseSuggestionsProvider =
    NotifierProvider.autoDispose<PurchaseSuggestionsController, PurchaseSuggestionsState>(
  PurchaseSuggestionsController.new,
);
