abstract final class ApiConstants {
  ApiConstants._();

  static const centralAuthLogin = '/central/auth/login';
  static const centralAuthForgotPassword = '/central/auth/forgot-password';
  static const centralTenants = '/central/tenants';

  static const tenantProdutos = '/tenant/produtos';
  static String tenantProduto(String productId) => '/tenant/produtos/$productId';
  static const tenantPosProdutosCatalogVersion =
      '/tenant/pos/produtos/catalog-version';
  static const tenantPosProdutosSearch = '/tenant/pos/produtos/search';
  static const tenantRequisicoesProdutosSearch =
      '/tenant/requisicoes/produtos/search';
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
  static const tenantProdutosTaxRules = '/tenant/produtos/tax-rules';
  static const tenantFornecedores = '/tenant/fornecedores';
  static const tenantCompras = '/tenant/compras';
  static const tenantDashboardProdutos = '/tenant/dashboard/produtos';
  static const tenantDashboardLotes = '/tenant/dashboard/lotes';
  static const tenantDashboardValidades = '/tenant/dashboard/validades';
  static const tenantDashboardFefo = '/tenant/dashboard/fefo';
  static const tenantDashboardExecutivo = '/tenant/dashboard/executivo';
  static const tenantDashboardExecutivoTables =
      '/tenant/dashboard/executivo/tables';
  static const tenantDashboardFinanceiro = '/tenant/dashboard/financeiro';
  static const tenantDashboardFinanceiroTables =
      '/tenant/dashboard/financeiro/tables';
  static const tenantDashboardFarmacia = '/tenant/dashboard/farmacia';
  static const tenantDashboardFarmaciaTables =
      '/tenant/dashboard/farmacia/tables';
  static const tenantDashboardStock = '/tenant/dashboard/stock';
  static const tenantDashboardStockTables = '/tenant/dashboard/stock/tables';
  static String tenantCompraDetalhe(String compraId) => '/tenant/compras/$compraId';
  static String tenantCompraItens(String compraId) => '/tenant/compras/$compraId/items';
  static String tenantCompraItem(String compraId, String itemId) =>
      '/tenant/compras/$compraId/items/$itemId';
  static String tenantCompraItemRemover(String compraId, String itemId) =>
      tenantCompraItem(compraId, itemId);
  static String tenantCompraConfirmar(String compraId) =>
      '/tenant/compras/$compraId/confirmar';

  static const tenantInventarios = '/tenant/inventarios';
  static const tenantStockMovements = '/tenant/stock/movements';
  static String tenantInventarioDetalhe(String inventarioId) =>
      '/tenant/inventarios/$inventarioId';
  static String tenantInventarioItens(String inventarioId) =>
      '/tenant/inventarios/$inventarioId/itens';
  static String tenantInventarioIniciarContagem(String inventarioId) =>
      '/tenant/inventarios/$inventarioId/iniciar-contagem';
  static String tenantInventarioItem(String inventarioId, String itemId) =>
      '/tenant/inventarios/$inventarioId/itens/$itemId';
  static String tenantInventarioReconciliar(String inventarioId) =>
      '/tenant/inventarios/$inventarioId/reconciliar';
  static String tenantInventarioCancelar(String inventarioId) =>
      '/tenant/inventarios/$inventarioId/cancelar';

  static const tenantRequisicoes = '/tenant/requisicoes';
  static String tenantRequisicaoDetalhe(String requisicaoId) =>
      '/tenant/requisicoes/$requisicaoId';
  static String tenantRequisicaoItens(String requisicaoId) =>
      '/tenant/requisicoes/$requisicaoId/items';
  static String tenantRequisicaoAprovar(String requisicaoId) =>
      '/tenant/requisicoes/$requisicaoId/aprovar';
  static String tenantRequisicaoRejeitar(String requisicaoId) =>
      '/tenant/requisicoes/$requisicaoId/rejeitar';
  static String tenantRequisicaoConfirmar(String requisicaoId) =>
      tenantRequisicaoAprovar(requisicaoId);
  static String tenantRequisicaoCancelar(String requisicaoId) =>
      '/tenant/requisicoes/$requisicaoId/cancelar';
  static const tenantLotes = '/tenant/lotes';
  static String tenantLote(String loteId) => '/tenant/lotes/$loteId';
  static String tenantLoteMovimentos(String loteId) =>
      '/tenant/lotes/$loteId/movimentos';
  static String tenantLoteReservas(String loteId) =>
      '/tenant/lotes/$loteId/reservas';
  static String tenantLoteDispensacoes(String loteId) =>
      '/tenant/lotes/$loteId/dispensacoes';
  static String tenantLoteIncineracoes(String loteId) =>
      '/tenant/lotes/$loteId/incineracoes';
  static String tenantLoteQuarentena(String loteId) =>
      '/tenant/lotes/$loteId/quarentena';
  static String tenantLoteLiberarQuarentena(String loteId) =>
      '/tenant/lotes/$loteId/liberar-quarentena';
  static String tenantLoteSanitarioHistorico(String loteId) =>
      '/tenant/regulatory/sanitario/lotes/$loteId/historico';
  static const tenantValidadesDashboard = '/tenant/validades/dashboard';
  static const tenantValidades = '/tenant/validades';
  static const tenantFefoDashboard = '/tenant/fefo/dashboard';
  static const tenantFefoOverview = '/tenant/fefo/overview';
  static const tenantFefoAudit = '/tenant/fefo/audit';
  static const tenantCategorias = '/tenant/categorias';
  static const tenantCategoriasAtivas = '/tenant/categorias/ativas';
  static const tenantCategoriasStats = '/tenant/categorias/stats';
  static String tenantCategoria(String categoryId) =>
      '/tenant/categorias/$categoryId';
  static String tenantProdutoHistoricoPrecos(String productId) =>
      '/tenant/produtos/$productId/historico-precos';
  static String tenantProdutoLotes(String produtoId) =>
      '/tenant/produtos/$produtoId/lotes';
  static String tenantProdutoFornecedores(String produtoId) =>
      '/tenant/produtos/$produtoId/fornecedores';
  static String tenantProdutoHistorico(String produtoId) =>
      '/tenant/produtos/$produtoId/historico';
  static String tenantProdutoAuditoria(String produtoId) =>
      '/tenant/produtos/$produtoId/auditoria';
  static String tenantRequisicaoItem(
    String requisicaoId,
    String itemId,
  ) =>
      '/tenant/requisicoes/$requisicaoId/items/$itemId';

  static const tenantClientes = '/tenant/clientes';
  static const tenantClientesDashboard = '/tenant/clientes/dashboard';
  static const tenantCotacoes = '/tenant/cotacoes';
  static String tenantCotacao(String cotacaoId) => '/tenant/cotacoes/$cotacaoId';
  static String tenantCliente(String clienteId) => '/tenant/clientes/$clienteId';
  static String tenantClienteFaturas(String clienteId) =>
      '/tenant/clientes/$clienteId/faturas';
  static String tenantClienteContasReceber(String clienteId) =>
      '/tenant/clientes/$clienteId/contas-receber';
  static String tenantClienteReceitas(String clienteId) =>
      '/tenant/clientes/$clienteId/receitas';
  static String tenantClienteAuditoria(String clienteId) =>
      '/tenant/clientes/$clienteId/auditoria';

  static const tenantFaturas = '/tenant/faturas';
  static const tenantFaturasDashboard = '/tenant/faturas/dashboard';

  static const tenantVendasHistorico = '/tenant/vendas/historico';
  static const tenantVendasHistoricoDashboard =
      '/tenant/vendas/historico/dashboard';

  static const tenantUtilizadores = '/tenant/utilizadores';
  static const tenantUtilizadoresDashboard = '/tenant/utilizadores/dashboard';
  static const tenantUtilizadorAtualPermissoes = '/tenant/utilizadores/me/permissoes';
  static String tenantUtilizador(String userId) => '/tenant/utilizadores/$userId';
  static String tenantUtilizadorAuditoria(String userId) =>
      '/tenant/utilizadores/$userId/auditoria';
  static String tenantUtilizadorPermissoes(String userId) =>
      '/tenant/utilizadores/$userId/permissoes';

  static String tenantUtilizadorEventos(String userId) =>
      '/tenant/utilizadores/$userId/eventos';

  static const tenantPerfis = '/tenant/perfis';
  static String tenantPerfil(String role) => '/tenant/perfis/$role';
  static String tenantPerfilPermissoes(String role) =>
      '/tenant/perfis/$role/permissoes';

  static const tenantPermissoes = '/tenant/permissoes';
  static const tenantPermissoesDashboard = '/tenant/permissoes/dashboard';

  static const tenantAuditoriaDashboard = '/tenant/auditoria/dashboard';
  static const tenantAuditoriaLogs = '/tenant/auditoria/logs';
  static const tenantAuditoriaEventos = '/tenant/auditoria/eventos';

  static const headerAuthorization = 'Authorization';
  static const headerTenantId = 'x-tenant-id';
  static const headerBranchId = 'x-branch-id';

  static const bearerPrefix = 'Bearer ';
}
