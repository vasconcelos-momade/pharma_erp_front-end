abstract final class ApiConstants {
  ApiConstants._();

  static const centralAuthLogin = '/central/auth/login';
  static const centralTenants = '/central/tenants';

  static const tenantProdutos = '/tenant/produtos';
  static const tenantPosProdutosCatalogVersion =
      '/tenant/pos/produtos/catalog-version';
  static const tenantPosProdutosSearch = '/tenant/pos/produtos/search';
  static const tenantPosServicosSearch = '/tenant/pos/servicos/search';
  static const tenantPosValidarDispensacao = '/tenant/pos/validar-dispensacao';
  static const tenantPosDraftSale = '/tenant/pos/sales/draft';
  static const tenantPosDraftCart = '/tenant/pos/sales/draft';
  static const tenantPosDraftCartItems = '/tenant/pos/sales/draft/items';
  static String tenantPosDraftCartItem(String itemId) =>
      '/tenant/pos/sales/draft/items/$itemId';
  static String tenantPosDraftCartItemIncrement(String itemId) =>
      '/tenant/pos/sales/draft/items/$itemId/increment';
  static String tenantPosDraftCartItemDecrement(String itemId) =>
      '/tenant/pos/sales/draft/items/$itemId/decrement';
  static const tenantPosFinalizarVenda = '/tenant/pos/finalizar';
  static const tenantPosFaturas = '/tenant/pos/faturas';
  static String tenantPosFaturaDetalhe(String invoiceId) =>
      '/tenant/pos/faturas/$invoiceId';
  static String tenantPosCancelarFatura(String invoiceId) =>
      '/tenant/pos/faturas/$invoiceId/cancel';
  static String tenantPosFaturaPdf(String invoiceId) =>
      '/tenant/pos/faturas/$invoiceId/pdf';
  static String tenantPosFaturaPrint(String invoiceId) =>
      '/tenant/pos/faturas/$invoiceId/print';
  static const tenantPosAbrirSessaoCaixa = '/tenant/pos/sessions/open';
  static const tenantPosFecharSessaoCaixa = '/tenant/pos/sessions/close';
  static const tenantPosSessaoCaixaAtual = '/tenant/pos/sessions/current';
  static const tenantPosCaixasDisponiveis = '/tenant/pos/caixas/available';
  static const tenantPosTaxRules = '/tenant/pos/tax-rules';
  static const tenantFornecedores = '/tenant/fornecedores';
  static const tenantCompras = '/tenant/compras';
  static String tenantCompraDetalhe(String compraId) => '/tenant/compras/$compraId';
  static String tenantCompraItens(String compraId) => '/tenant/compras/$compraId/items';
  static String tenantCompraItemRemover(String compraId, String itemId) =>
      '/tenant/compras/$compraId/items/$itemId';
  static String tenantCompraConfirmar(String compraId) =>
      '/tenant/compras/$compraId/confirmar';

  static const headerAuthorization = 'Authorization';
  static const headerTenantId = 'x-tenant-id';
  static const headerBranchId = 'x-branch-id';

  static const bearerPrefix = 'Bearer ';
}
