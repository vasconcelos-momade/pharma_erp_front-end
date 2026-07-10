import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/constants/api_constants.dart';
import '../../../../../core/contracts/api_envelope.dart';
import '../../../../../core/errors/api_failure.dart';
import '../../../../../core/network/dio/dio_provider.dart';

class PurchaseSuggestionItem {
  const PurchaseSuggestionItem({
    required this.produtoId,
    required this.produtoNome,
    required this.fornecedorNome,
    required this.consumo,
    required this.estoqueAtual,
    required this.estoqueMinimo,
    required this.quantidadeSugerida,
    required this.unidade,
    this.fornecedorId,
  });

  final String produtoId;
  final String produtoNome;
  final String? fornecedorId;
  final String fornecedorNome;
  final num consumo;
  final num estoqueAtual;
  final num estoqueMinimo;
  final num quantidadeSugerida;
  final String unidade;

  factory PurchaseSuggestionItem.fromJson(Map<String, dynamic> json) {
    return PurchaseSuggestionItem(
      produtoId: json['produtoId']?.toString() ?? '',
      produtoNome: json['produtoNome']?.toString() ?? '—',
      fornecedorId: json['fornecedorId']?.toString(),
      fornecedorNome: json['fornecedorNome']?.toString() ?? 'Sem fornecedor',
      consumo: json['consumo'] as num? ?? 0,
      estoqueAtual: json['estoqueAtual'] as num? ?? 0,
      estoqueMinimo: json['estoqueMinimo'] as num? ?? 0,
      quantidadeSugerida: json['quantidadeSugerida'] as num? ?? 0,
      unidade: json['unidade']?.toString() ?? 'un',
    );
  }
}

class PurchaseSuggestionsState {
  const PurchaseSuggestionsState({
    this.items = const <PurchaseSuggestionItem>[],
    this.days = 30,
    this.isLoading = false,
    this.errorMessage,
  });

  final List<PurchaseSuggestionItem> items;
  final int days;
  final bool isLoading;
  final String? errorMessage;

  PurchaseSuggestionsState copyWith({
    List<PurchaseSuggestionItem>? items,
    int? days,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return PurchaseSuggestionsState(
      items: items ?? this.items,
      days: days ?? this.days,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class PurchaseSuggestionsController extends Notifier<PurchaseSuggestionsState> {
  @override
  PurchaseSuggestionsState build() {
    Future.microtask(load);
    return const PurchaseSuggestionsState(isLoading: true);
  }

  Future<void> setDays(int days) async {
    state = state.copyWith(days: days, isLoading: true, clearError: true);
    await load();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final dio = ref.read(dioProvider);
      final response = await dio.get<Map<String, dynamic>>(
        ApiConstants.tenantComprasSugestoes,
        queryParameters: <String, dynamic>{'days': state.days},
      );
      final payload = ApiEnvelope.unwrapMap(response.data ?? {});
      final items = (payload['items'] as List<dynamic>? ?? <dynamic>[])
          .whereType<Map<String, dynamic>>()
          .map(PurchaseSuggestionItem.fromJson)
          .toList();
      state = state.copyWith(items: items, isLoading: false, clearError: true);
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: ApiFailure.fromDio(e).message,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }
}

final purchaseSuggestionsProvider =
    NotifierProvider.autoDispose<PurchaseSuggestionsController, PurchaseSuggestionsState>(
  PurchaseSuggestionsController.new,
);
