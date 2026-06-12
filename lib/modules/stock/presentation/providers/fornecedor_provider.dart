import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/requisicao_repository_impl.dart';
import '../../domain/entities/fornecedor.dart';

final supplierListProvider = FutureProvider<List<FornecedorResumo>>((ref) async {
  final repository = ref.read(requisicaoRepositoryProvider);
  return repository.listarFornecedores();
});
