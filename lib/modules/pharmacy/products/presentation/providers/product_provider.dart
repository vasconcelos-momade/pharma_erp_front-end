import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/catalog/pdv_catalog_cache_policy.dart';
import '../../../../../core/contracts/pagination_response.dart';
import '../../../../../core/errors/api_failure.dart';
import '../../data/repositories/product_repository_impl.dart';
import '../../domain/entities/product.dart';

class ProductListState {
  const ProductListState({
    this.items = const <Product>[],
    this.query = '',
    this.page = 1,
    this.pageSize = 50,
    this.hasMore = false,
    this.isLoading = false,
    this.isInitialized = false,
    this.errorMessage,
    this.catalogVersion,
  });

  final List<Product> items;
  final String query;
  final int page;
  final int pageSize;
  final bool hasMore;
  final bool isLoading;
  final bool isInitialized;
  final String? errorMessage;
  final String? catalogVersion;

  ProductListState copyWith({
    List<Product>? items,
    String? query,
    int? page,
    int? pageSize,
    bool? hasMore,
    bool? isLoading,
    bool? isInitialized,
    String? errorMessage,
    String? catalogVersion,
    bool clearError = false,
  }) {
    return ProductListState(
      items: items ?? this.items,
      query: query ?? this.query,
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
      hasMore: hasMore ?? this.hasMore,
      isLoading: isLoading ?? this.isLoading,
      isInitialized: isInitialized ?? this.isInitialized,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      catalogVersion: catalogVersion ?? this.catalogVersion,
    );
  }
}

class ProductListController extends Notifier<ProductListState> {
  Timer? _debounce;
  int _requestId = 0;

  @override
  ProductListState build() {
    ref.onDispose(() {
      _debounce?.cancel();
    });
    Future.microtask(fetchCurrentPage);
    return const ProductListState();
  }

  void onSearchChanged(String value) {
    final normalized = value.trim();
    if (normalized == state.query) {
      return;
    }

    _debounce?.cancel();
    state = state.copyWith(
      query: normalized,
      page: 1,
      isLoading: true,
      clearError: true,
    );

    _debounce = Timer(const Duration(milliseconds: 350), () {
      fetchCurrentPage();
    });
  }

  Future<void> goToPage(int page) async {
    if (page < 1 || page == state.page) {
      return;
    }
    state = state.copyWith(page: page, isLoading: true, clearError: true);
    await fetchCurrentPage();
  }

  Future<void> refreshCurrentPage() async {
    await fetchCurrentPage(force: true);
  }

  /// Actualiza `catalogVersion` no servidor e recarrega a página actual.
  Future<void> refreshCatalogAndPage() async {
    final repository = ref.read(productRepositoryProvider);
    await repository.fetchCatalogVersion();
    await fetchCurrentPage(force: true);
  }

  Future<void> fetchCurrentPage({bool force = false}) async {
    final requestId = ++_requestId;
    final isBarcode = _looksLikeBarcode(state.query);
    final cacheKey = PdvCatalogCachePolicy.productPageKey(
      query: state.query,
      page: state.page,
      pageSize: state.pageSize,
    );

    if (!force && !isBarcode) {
      final cached =
          PdvCatalogCachePolicy.get<PaginationResponse<Product>>(cacheKey);
      if (cached != null) {
        state = state.copyWith(
          items: cached.items,
          page: cached.page,
          pageSize: cached.pageSize,
          hasMore: cached.hasMore,
          isLoading: false,
          isInitialized: true,
          catalogVersion: PdvCatalogCachePolicy.activeCatalogVersion,
          clearError: true,
        );
        return;
      }
    }

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final repository = ref.read(productRepositoryProvider);
      final response = await repository.searchProducts(
        query: isBarcode ? null : state.query,
        barcode: isBarcode ? state.query : null,
        page: state.page,
        pageSize: state.pageSize,
      );

      if (requestId != _requestId) {
        return;
      }

      if (!isBarcode) {
        PdvCatalogCachePolicy.put(cacheKey, response);
      }

      state = state.copyWith(
        items: response.items,
        page: response.page,
        pageSize: response.pageSize,
        hasMore: response.hasMore,
        isLoading: false,
        isInitialized: true,
        catalogVersion: PdvCatalogCachePolicy.activeCatalogVersion,
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

  bool _looksLikeBarcode(String value) {
    final trimmed = value.trim();
    if (trimmed.length < 8) {
      return false;
    }
    return RegExp(r'^\d+$').hasMatch(trimmed);
  }
}

final productListProvider =
    NotifierProvider.autoDispose<ProductListController, ProductListState>(
  ProductListController.new,
);

class PurchaseProductListController extends Notifier<ProductListState> {
  Timer? _debounce;
  int _requestId = 0;

  @override
  ProductListState build() {
    ref.onDispose(() {
      _debounce?.cancel();
    });
    Future.microtask(fetchCurrentPage);
    return const ProductListState();
  }

  void onSearchChanged(String value) {
    final normalized = value.trim();
    if (normalized == state.query) {
      return;
    }

    _debounce?.cancel();
    state = state.copyWith(
      query: normalized,
      page: 1,
      isLoading: true,
      clearError: true,
    );

    _debounce = Timer(const Duration(milliseconds: 350), () {
      fetchCurrentPage();
    });
  }

  Future<void> goToPage(int page) async {
    if (page < 1 || page == state.page) {
      return;
    }
    state = state.copyWith(page: page, isLoading: true, clearError: true);
    await fetchCurrentPage();
  }

  Future<void> refreshCurrentPage() async {
    await fetchCurrentPage(force: true);
  }

  Future<void> fetchCurrentPage({bool force = false}) async {
    final requestId = ++_requestId;
    final isBarcode = _looksLikeBarcode(state.query);

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final repository = ref.read(productRepositoryProvider);
      final response = await repository.searchProducts(
        query: isBarcode ? null : state.query,
        barcode: isBarcode ? state.query : null,
        page: state.page,
        pageSize: state.pageSize,
      );

      if (requestId != _requestId) {
        return;
      }

      state = state.copyWith(
        items: response.items.where((product) => product.ativo).toList(),
        page: response.page,
        pageSize: response.pageSize,
        hasMore: response.hasMore,
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

  bool _looksLikeBarcode(String value) {
    final trimmed = value.trim();
    if (trimmed.length < 8) {
      return false;
    }
    return RegExp(r'^\d+$').hasMatch(trimmed);
  }
}

final purchaseProductListProvider =
    NotifierProvider.autoDispose<PurchaseProductListController, ProductListState>(
  PurchaseProductListController.new,
);
