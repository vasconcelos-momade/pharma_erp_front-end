import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/dashboard_remote_datasource.dart';
import '../../domain/dashboard_query.dart';
import '../../../pharmacy/categories/domain/entities/category.dart';
import '../../../pharmacy/categories/presentation/providers/category_provider.dart';
import '../../../pharmacy/products/data/repositories/product_repository_impl.dart';
import '../../../pharmacy/products/domain/entities/product.dart';

final executiveDashboardProvider =
    FutureProvider.autoDispose.family<Map<String, dynamic>, DashboardQuery>((ref, query) async {
  return ref.watch(dashboardRemoteDataSourceProvider).executiveDashboard(query);
});

final financeDashboardProvider =
    FutureProvider.autoDispose.family<Map<String, dynamic>, DashboardQuery>((ref, query) async {
  return ref.watch(dashboardRemoteDataSourceProvider).financeDashboard(query);
});

final pharmacyDashboardProvider =
    FutureProvider.autoDispose.family<Map<String, dynamic>, DashboardQuery>((ref, query) async {
  return ref.watch(dashboardRemoteDataSourceProvider).pharmacyDashboard(query);
});

final stockDashboardProvider =
    FutureProvider.autoDispose.family<Map<String, dynamic>, DashboardQuery>((ref, query) async {
  return ref.watch(dashboardRemoteDataSourceProvider).stockDashboard(query);
});

final dashboardFilterCategoriesProvider =
    FutureProvider.autoDispose<List<Category>>((ref) async {
  return ref.watch(activeCategoriesProvider.future);
});

final dashboardFilterProductsProvider =
    FutureProvider.autoDispose<List<Product>>((ref) async {
  final repository = ref.watch(productRepositoryProvider);
  final response = await repository.searchMasterProducts(
    page: 1,
    pageSize: 100,
    sortBy: 'nome',
    sortOrder: 'asc',
  );
  return response.items.where((product) => product.ativo).toList(growable: false);
});
