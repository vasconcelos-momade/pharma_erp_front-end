import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/dashboard_remote_datasource.dart';
import '../../domain/dashboard_query.dart';

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
