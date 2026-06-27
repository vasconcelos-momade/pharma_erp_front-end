import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pharma_erp/core/theme/app_theme.dart';
import 'package:pharma_erp/modules/dashboard/data/datasources/dashboard_remote_datasource.dart';
import 'package:pharma_erp/modules/dashboard/domain/dashboard_query.dart';
import 'package:pharma_erp/modules/dashboard/presentation/pages/executive_dashboard_page.dart';
import 'package:pharma_erp/modules/dashboard/presentation/pages/finance_dashboard_page.dart';

void main() {
  testWidgets('Finance dashboard renders and scrolls without exceptions', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1440, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(_buildHarness(const FinanceDashboardPage()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(tester.takeException(), isNull);

    await tester.drag(find.byType(Scrollable).first, const Offset(0, -500));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  testWidgets('Executive dashboard renders and scrolls without exceptions', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1440, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(_buildHarness(const ExecutiveDashboardPage()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(tester.takeException(), isNull);

    await tester.drag(find.byType(Scrollable).first, const Offset(0, -500));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}

Widget _buildHarness(Widget child) {
  return ProviderScope(
    overrides: [
      dashboardRemoteDataSourceProvider.overrideWithValue(_FakeDashboardRemoteDataSource()),
    ],
    child: MaterialApp(
      theme: AppTheme.lightEnterprise(),
      home: Scaffold(body: child),
    ),
  );
}

class _FakeDashboardRemoteDataSource extends DashboardRemoteDataSource {
  _FakeDashboardRemoteDataSource() : super(Dio());

  @override
  Future<Map<String, dynamic>> executiveDashboard(DashboardQuery query) async {
    return {
      'kpis': {
        'receitaHoje': 1200,
        'receitaMes': 5400,
        'lucroBruto': 2100,
        'lucroLiquido': 1700,
        'totalVendas': 5400,
        'ticketMedio': 250,
        'numeroFaturas': 32,
        'produtosVendidos': 148,
        'clientesAtivos': 20,
        'contasReceber': 950,
        'contasPagar': 640,
        'stockTotal': 780,
        'produtosCriticos': 12,
        'valorInventario': 9000,
        'lotesExpirados': 3,
        'produtosProximosValidade': 9,
      },
      'tables': {
        'ultimasVendas': [
          {
            'numero': 'FT-001',
            'clienteNome': 'Cliente A',
            'total': 450,
            'estado': 'PAGA',
            'tipoPagamento': 'MPESA',
          },
        ],
        'alertasCriticos': [
          {
            'produtoNome': 'Produto crítico',
            'tipo': 'STOCK',
            'mensagem': 'Stock baixo',
          },
        ],
        'ultimosEventos': [
          {
            'type': 'VENDA',
            'entity': 'Factura',
            'userNome': 'Admin',
            'createdAt': '2026-06-27T10:00:00.000Z',
          },
        ],
      },
      'charts': {
        'receitaDiaria': List.generate(12, (i) => {'data': '2026-06-${i + 1}'.padLeft(2, '0'), 'total': (i + 1) * 10}),
        'receitaMensal': List.generate(12, (i) => {'mes': '2026-${(i + 1).toString().padLeft(2, '0')}', 'total': (i + 1) * 120}),
        'fluxoFinanceiro': List.generate(12, (i) => {'receitas': (i + 1) * 120, 'despesas': (i + 1) * 70}),
        'evolucaoVendas': List.generate(12, (i) => {'data': '2026-06-${i + 1}'.padLeft(2, '0'), 'total': (i + 1) * 8}),
        'metodosPagamento': [
          {'metodo': 'MPESA', 'total': 20},
          {'metodo': 'CASH', 'total': 18},
          {'metodo': 'POS', 'total': 10},
        ],
        'topProdutos': List.generate(8, (i) => {'produtoNome': 'Produto ${i + 1}', 'total': (i + 1) * 4}),
        'topCategorias': List.generate(8, (i) => {'categoria': 'Categoria ${i + 1}', 'total': (i + 1) * 3}),
      },
    };
  }

  @override
  Future<Map<String, dynamic>> financeDashboard(DashboardQuery query) async {
    return {
      'kpis': {
        'receita': 1200,
        'despesas': 700,
        'lucro': 500,
        'fluxoCaixa': 300,
        'saldoAtual': 2000,
        'contasReceber': 900,
        'contasPagar': 650,
        'recebimentosPendentes': 6,
        'pagamentosPendentes': 4,
      },
      'tables': {
        'ultimosPagamentos': [
          {'faturaNumero': 'FT-001', 'metodo': 'MPESA', 'valor': 200, 'status': 'PAGO'},
        ],
      },
      'charts': {
        'receitasDespesas': List.generate(8, (i) => {'receitas': (i + 1) * 100, 'despesas': (i + 1) * 60}),
        'fluxoDiario': List.generate(8, (i) => {'data': '2026-06-${i + 1}'.padLeft(2, '0'), 'saldo': (i + 1) * 35}),
        'fluxoMensal': List.generate(8, (i) => {'mes': '2026-${(i + 1).toString().padLeft(2, '0')}', 'saldo': (i + 1) * 80}),
        'evolucaoFinanceira': List.generate(8, (i) => {'receitas': (i + 1) * 100, 'despesas': (i + 1) * 55}),
        'metodosPagamento': [
          {'metodo': 'MPESA', 'total': 10},
          {'metodo': 'CASH', 'total': 8},
        ],
      },
    };
  }

  @override
  Future<Map<String, dynamic>> executiveDashboardTable({
    required String table,
    required DashboardQuery query,
    required int page,
    required int pageSize,
  }) async {
    return _pagedResult(_executiveTableItems(table));
  }

  @override
  Future<Map<String, dynamic>> financeDashboardTable({
    required String table,
    required DashboardQuery query,
    required int page,
    required int pageSize,
  }) async {
    return _pagedResult(_financeTableItems(table));
  }

  List<Map<String, dynamic>> _executiveTableItems(String table) {
    switch (table) {
      case 'ultimasVendas':
        return List.generate(
          12,
          (i) => {
            'numero': 'FT-${i + 1}',
            'clienteNome': 'Cliente ${i + 1}',
            'total': (i + 1) * 100,
            'estado': i.isEven ? 'PAGA' : 'PENDENTE',
          },
        );
      case 'alertasCriticos':
        return List.generate(
          8,
          (i) => {
            'produtoNome': 'Produto ${i + 1}',
            'tipo': 'ALERTA',
            'mensagem': 'Mensagem ${i + 1}',
          },
        );
      case 'ultimosEventos':
        return List.generate(
          8,
          (i) => {
            'type': 'EVENTO',
            'entity': 'Entidade ${i + 1}',
            'userNome': 'Admin',
            'createdAt': '2026-06-27T10:00:00.000Z',
          },
        );
      default:
        return const [];
    }
  }

  List<Map<String, dynamic>> _financeTableItems(String table) {
    switch (table) {
      case 'contasVencidas':
        return List.generate(
          10,
          (i) => {
            'clienteNome': 'Cliente ${i + 1}',
            'saldo': (i + 1) * 50,
            'vencimento': '2026-06-27',
          },
        );
      case 'ultimosPagamentos':
        return List.generate(
          10,
          (i) => {
            'faturaNumero': 'FT-${i + 1}',
            'metodo': 'MPESA',
            'valor': (i + 1) * 30,
          },
        );
      case 'ultimasReceitas':
      case 'ultimasDespesas':
        return List.generate(
          10,
          (i) => {
            'tipo': 'MOV',
            'referencia': 'Ref ${i + 1}',
            'valor': (i + 1) * 30,
            'createdAt': '2026-06-27T10:00:00.000Z',
          },
        );
      default:
        return const [];
    }
  }

  Map<String, dynamic> _pagedResult(List<Map<String, dynamic>> items) {
    return {
      'items': items,
      'page': 1,
      'pageSize': items.length,
      'hasMore': false,
      'hasPrevious': false,
      'totalCount': items.length,
      'totalPages': 1,
    };
  }
}
