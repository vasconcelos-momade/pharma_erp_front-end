import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../app/providers/auth_session_notifier.dart';
import '../../../../../core/catalog/pdv_catalog_cache_policy.dart';
import '../../../../../core/contracts/pagination_response.dart';
import '../../../../../core/errors/api_failure.dart';
import '../../data/repositories/product_repository_impl.dart';
import '../../domain/entities/categoria_produto.dart';
import '../../domain/entities/product.dart';
import '../../domain/entities/product_tax_rule.dart';

class ProductListState {
  const ProductListState({
    this.items = const <Product>[],
    this.query = '',
    this.categoria,
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
  final CategoriaProduto? categoria;
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
    CategoriaProduto? categoria,
    bool clearCategoria = false,
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
      categoria: clearCategoria ? null : (categoria ?? this.categoria),
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

  void setCategoriaFilter(CategoriaProduto? categoria) {
    if (state.categoria == categoria) {
      return;
    }

    _debounce?.cancel();
    state = state.copyWith(
      categoria: categoria,
      clearCategoria: categoria == null,
      page: 1,
      isLoading: true,
      clearError: true,
    );
    unawaited(fetchCurrentPage());
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
      categoria: state.categoria?.apiValue,
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
        categoria: state.categoria,
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

final productTaxRulesProvider =
    FutureProvider.autoDispose<List<ProductTaxRule>>((ref) async {
  final repository = ref.watch(productRepositoryProvider);
  return repository.listTaxRules();
});

class RequisicaoProductListController extends Notifier<ProductListState> {
  Timer? _debounce;
  int _requestId = 0;

  @override
  ProductListState build() {
    ref.keepAlive();
    ref.onDispose(() {
      _debounce?.cancel();
    });

    final authReady = ref.watch(
      authSessionProvider.select(
        (session) => !session.isBootstrapping && session.hasTenantContext,
      ),
    );

    ref.listen<AuthSessionState>(authSessionProvider, (previous, next) {
      final wasReady =
          previous != null && !previous.isBootstrapping && previous.hasTenantContext;
      final isReady = !next.isBootstrapping && next.hasTenantContext;
      if (isReady && !wasReady) {
        unawaited(ensureLoaded(force: true));
      }
    });

    if (authReady) {
      Future.microtask(ensureLoaded);
    }

    return const ProductListState();
  }

  Future<void> ensureLoaded({bool force = false}) async {
    if (!ref.read(authSessionProvider).hasTenantContext) {
      return;
    }
    if (!force &&
        state.isInitialized &&
        (state.items.isNotEmpty || state.errorMessage != null)) {
      return;
    }
    await fetchCurrentPage(force: force);
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

  void setCategoriaFilter(CategoriaProduto? categoria) {
    if (state.categoria == categoria) {
      return;
    }

    _debounce?.cancel();
    state = state.copyWith(
      categoria: categoria,
      clearCategoria: categoria == null,
      page: 1,
      isLoading: true,
      clearError: true,
    );
    unawaited(fetchCurrentPage());
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

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final repository = ref.read(productRepositoryProvider);
      final response = await repository.searchRequisitionProducts(
        query: state.query.isEmpty ? null : state.query,
        categoria: state.categoria,
        page: state.page,
        pageSize: state.pageSize,
      );

      if (requestId != _requestId) {
        return;
      }

      state = state.copyWith(
        items: response.items,
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
}

/// Catálogo de produtos para requisições (Compra, Entrada e Saída).
final requisicaoProductListProvider =
    NotifierProvider<RequisicaoProductListController, ProductListState>(
  RequisicaoProductListController.new,
);

@Deprecated('Use requisicaoProductListProvider')
final purchaseProductListProvider = requisicaoProductListProvider;

class MasterProductListState {
  const MasterProductListState({
    this.items = const <Product>[],
    this.query = '',
    this.categoria,
    this.includeInactive = false,
    this.deletingProductIds = const <String>{},
    this.page = 1,
    this.pageSize = 20,
    this.hasMore = false,
    this.isLoading = false,
    this.isInitialized = false,
    this.errorMessage,
  });

  final List<Product> items;
  final String query;
  final CategoriaProduto? categoria;
  final bool includeInactive;
  final Set<String> deletingProductIds;
  final int page;
  final int pageSize;
  final bool hasMore;
  final bool isLoading;
  final bool isInitialized;
  final String? errorMessage;

  MasterProductListState copyWith({
    List<Product>? items,
    String? query,
    CategoriaProduto? categoria,
    bool clearCategoria = false,
    bool? includeInactive,
    Set<String>? deletingProductIds,
    int? page,
    int? pageSize,
    bool? hasMore,
    bool? isLoading,
    bool? isInitialized,
    String? errorMessage,
    bool clearError = false,
  }) {
    return MasterProductListState(
      items: items ?? this.items,
      query: query ?? this.query,
      categoria: clearCategoria ? null : (categoria ?? this.categoria),
      includeInactive: includeInactive ?? this.includeInactive,
      deletingProductIds: deletingProductIds ?? this.deletingProductIds,
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
      hasMore: hasMore ?? this.hasMore,
      isLoading: isLoading ?? this.isLoading,
      isInitialized: isInitialized ?? this.isInitialized,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class MasterProductListController extends Notifier<MasterProductListState> {
  Timer? _debounce;
  int _requestId = 0;

  @override
  MasterProductListState build() {
    ref.onDispose(() {
      _debounce?.cancel();
    });
    Future.microtask(load);
    return const MasterProductListState();
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
      load();
    });
  }

  void setCategoriaFilter(CategoriaProduto? categoria) {
    if (state.categoria == categoria) {
      return;
    }
    _debounce?.cancel();
    state = state.copyWith(
      categoria: categoria,
      clearCategoria: categoria == null,
      page: 1,
      isLoading: true,
      clearError: true,
    );
    unawaited(load());
  }

  void setIncludeInactive(bool value) {
    if (state.includeInactive == value) {
      return;
    }
    _debounce?.cancel();
    state = state.copyWith(
      includeInactive: value,
      page: 1,
      isLoading: true,
      clearError: true,
    );
    unawaited(load(force: true));
  }

  Future<void> goToPage(int page) async {
    if (page < 1 || page == state.page) {
      return;
    }
    state = state.copyWith(page: page, isLoading: true, clearError: true);
    await load();
  }

  Future<void> refreshCurrentPage() async {
    await load(force: true);
  }

  Future<void> load({bool force = false}) async {
    final requestId = ++_requestId;
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final repository = ref.read(productRepositoryProvider);
      final response = await repository.searchMasterProducts(
        query: state.query.isEmpty ? null : state.query,
        categoria: state.categoria,
        includeInactive: state.includeInactive,
        page: state.page,
        pageSize: state.pageSize,
      );

      if (requestId != _requestId) {
        return;
      }

      state = state.copyWith(
        items: response.items,
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

  Future<Product?> createProduct(Map<String, dynamic> payload) async {
    final repository = ref.read(productRepositoryProvider);
    final created = await repository.createProduct(payload);
    await load(force: true);
    return created;
  }

  Future<Product?> updateProduct(String id, Map<String, dynamic> payload) async {
    final repository = ref.read(productRepositoryProvider);
    final updated = await repository.updateProduct(id, payload);
    await load(force: true);
    var items = state.items;
    if (state.includeInactive &&
        !updated.ativo &&
        !items.any((item) => item.id == updated.id)) {
      items = <Product>[
        updated,
        ...items,
      ];
    }
    state = state.copyWith(
      items: items,
    );
    return updated;
  }

  Future<void> deleteProduct(String id) async {
    if (state.deletingProductIds.contains(id)) {
      return;
    }

    final repository = ref.read(productRepositoryProvider);
    state = state.copyWith(
      deletingProductIds: <String>{
        ...state.deletingProductIds,
        id,
      },
      clearError: true,
    );

    try {
      await repository.deleteProduct(id);
      await load(force: true);
      final items = state.items.where((item) => item.id != id).toList(growable: false);
      state = state.copyWith(
        items: items,
      );
    } finally {
      state = state.copyWith(
        deletingProductIds: state.deletingProductIds
            .where((productId) => productId != id)
            .toSet(),
      );
    }
  }
}

final masterProductListProvider =
    NotifierProvider<MasterProductListController, MasterProductListState>(
  MasterProductListController.new,
);
