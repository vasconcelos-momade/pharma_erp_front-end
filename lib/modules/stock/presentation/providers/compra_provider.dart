import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/constants/api_constants.dart';
import '../../../../../core/contracts/api_envelope.dart';
import '../../../../../core/errors/api_failure.dart';
import '../../../../../core/network/dio/dio_provider.dart';

class CompraSummary {
  const CompraSummary({
    required this.id,
    required this.numeroDocumento,
    required this.fornecedorNome,
    required this.status,
    required this.total,
    required this.itemCount,
  });

  final String id;
  final String numeroDocumento;
  final String fornecedorNome;
  final String status;
  final num total;
  final int itemCount;

  factory CompraSummary.fromJson(Map<String, dynamic> json) {
    return CompraSummary(
      id: json['id']?.toString() ?? '',
      numeroDocumento: json['numeroDocumento']?.toString() ?? '—',
      fornecedorNome: json['fornecedorNome']?.toString() ?? '—',
      status: json['status']?.toString() ?? 'PENDENTE',
      total: json['total'] as num? ?? 0,
      itemCount: json['itemCount'] as int? ?? 0,
    );
  }
}

class ComprasState {
  const ComprasState({
    this.items = const <CompraSummary>[],
    this.isLoading = false,
    this.errorMessage,
  });

  final List<CompraSummary> items;
  final bool isLoading;
  final String? errorMessage;

  ComprasState copyWith({
    List<CompraSummary>? items,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ComprasState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class ComprasController extends Notifier<ComprasState> {
  @override
  ComprasState build() {
    Future.microtask(load);
    return const ComprasState(isLoading: true);
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final dio = ref.read(dioProvider);
      final response = await dio.get<dynamic>(ApiConstants.tenantCompras);
      final payload = ApiEnvelope.unwrapList(response.data);
      final items = payload
          .whereType<Map<String, dynamic>>()
          .map(CompraSummary.fromJson)
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

final comprasProvider =
    NotifierProvider.autoDispose<ComprasController, ComprasState>(ComprasController.new);
