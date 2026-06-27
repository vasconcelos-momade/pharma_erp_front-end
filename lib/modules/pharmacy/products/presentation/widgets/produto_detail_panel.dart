import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/constants/api_constants.dart';
import '../../../../../core/contracts/api_envelope.dart';
import '../../../../../core/network/dio/dio_provider.dart';
import '../../../../../core/theme/design_tokens.dart';
import '../../../../../core/theme/spacing.dart';
import '../../data/datasources/product_remote_datasource.dart';
import '../../domain/entities/categoria_produto.dart';
import '../../domain/entities/product.dart';
import 'produto_regulacao_badges.dart';

class ProdutoDetailPanel extends ConsumerStatefulWidget {
  const ProdutoDetailPanel({
    super.key,
    required this.product,
    required this.onClose,
  });

  final Product product;
  final VoidCallback onClose;

  @override
  ConsumerState<ProdutoDetailPanel> createState() => _ProdutoDetailPanelState();
}

class _ProdutoDetailPanelState extends ConsumerState<ProdutoDetailPanel>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  var _loading = true;
  Product? _detail;
  List<Map<String, dynamic>> _lotes = [];
  List<Map<String, dynamic>> _movimentos = [];
  List<Map<String, dynamic>> _precos = [];
  List<Map<String, dynamic>> _historico = [];
  List<Map<String, dynamic>> _fornecedores = [];
  List<Map<String, dynamic>> _auditoria = [];

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 8, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final dio = ref.read(dioProvider);
    final productsDs = ref.read(productRemoteDataSourceProvider);
    try {
      final productResponse = await productsDs.getProduct(widget.product.id);
      final lotesRes = await dio.get<dynamic>(
        ApiConstants.tenantProdutoLotes(widget.product.id),
      );
      final movRes = await dio.get<Map<String, dynamic>>(
        ApiConstants.tenantStockMovements,
        queryParameters: {'produtoId': widget.product.id, 'pageSize': 20},
      );
      final precosRes = await dio.get<Map<String, dynamic>>(
        ApiConstants.tenantProdutoHistoricoPrecos(widget.product.id),
      );
      final historicoRes = await productsDs.listHistory(id: widget.product.id);
      final fornecedoresRes = await productsDs.listSuppliers(widget.product.id);
      final auditoriaRes = await productsDs.listAudit(id: widget.product.id);

      setState(() {
        _detail = Product(
          id: productResponse.id,
          nome: productResponse.nome,
          substanciaActiva: productResponse.substanciaActiva,
          dosagem: productResponse.dosagem,
          forma: productResponse.forma,
          apresentacao: productResponse.apresentacao,
          ativo: productResponse.ativo,
          barcode: productResponse.barcode,
          categoriaId: productResponse.categoriaId,
          categoriaNome: productResponse.categoriaNome,
          categoria: productResponse.categoria,
          tipoDispensacao: productResponse.tipoDispensacao,
          requiresPrescription: productResponse.requiresPrescription,
          requiresDoubleCheck: productResponse.requiresDoubleCheck,
          requiresPsychotropicBook: productResponse.requiresPsychotropicBook,
          antimicrobiano: productResponse.antimicrobiano,
          requiresManualReview: productResponse.requiresManualReview,
          precoVenda: productResponse.precoVenda,
          estoqueAtual: productResponse.estoqueAtual,
          estoqueMinimo: productResponse.estoqueMinimo,
          numLotes: productResponse.numLotes,
          lote: productResponse.lote,
          dataValidade: productResponse.dataValidade,
          proximaValidade: productResponse.proximaValidade,
          createdAt: productResponse.createdAt,
          taxRule: productResponse.taxRule,
        );
        final lotesPayload = lotesRes.data;
        if (lotesPayload is List) {
          _lotes = lotesPayload.cast<Map<String, dynamic>>();
        } else if (lotesPayload is Map) {
          _lotes = ApiEnvelope.unwrapList(lotesPayload).cast<Map<String, dynamic>>();
        }
        _movimentos = ApiEnvelope.unwrapMap(movRes.data!)
            .letItems();
        _precos = ApiEnvelope.unwrapMap(precosRes.data!).letItems();
        _historico = historicoRes.items;
        _fornecedores = fornecedoresRes;
        _auditoria = auditoriaRes.items;
        _loading = false;
      });
    } on DioException {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final s = context.spacing;
    final product = _detail ?? widget.product;

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.all(s.md),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.nome,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    if (product.barcode != null)
                      Text('Código: ${product.barcode}', style: TextStyle(color: t.textMuted)),
                  ],
                ),
              ),
              IconButton(onPressed: widget.onClose, icon: const Icon(Icons.close)),
            ],
          ),
        ),
        TabBar(
          controller: _tabs,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Geral'),
            Tab(text: 'Regulação'),
            Tab(text: 'Lotes'),
            Tab(text: 'Movimentos'),
            Tab(text: 'Preços'),
            Tab(text: 'Histórico'),
            Tab(text: 'Fornecedor'),
            Tab(text: 'Auditoria'),
          ],
        ),
        if (_loading) const LinearProgressIndicator(),
        Expanded(
          child: TabBarView(
            controller: _tabs,
            children: [
              _InfoTab(product: product),
              Padding(
                padding: EdgeInsets.all(s.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ProdutoRegulacaoBadges(product: product),
                    SizedBox(height: s.md),
                    Text('Tipo: ${product.tipoDispensacao}'),
                    Text('Receita: ${product.requiresPrescription ? 'Sim' : 'Não'}'),
                    Text('Dupla verificação: ${product.requiresDoubleCheck ? 'Sim' : 'Não'}'),
                    Text('Livro psicotrópicos: ${product.requiresPsychotropicBook ? 'Sim' : 'Não'}'),
                    Text('Revisão manual: ${product.requiresManualReview ? 'Sim' : 'Não'}'),
                    Text('Antimicrobiano: ${product.antimicrobiano ? 'Sim' : 'Não'}'),
                  ],
                ),
              ),
              _ListTab(
                empty: 'Sem lotes',
                items: _lotes.map((l) => '${l['numeroLote']} — val. ${l['dataValidade']?.toString().substring(0, 10) ?? '—'} — stock ${l['quantidadeAtual']}').toList(),
              ),
              _ListTab(
                empty: 'Sem movimentos',
                items: _movimentos.map((m) => '${m['tipoLabel'] ?? m['tipo']} ${m['quantidade']} (${m['createdAt']?.toString().substring(0, 10) ?? ''})').toList(),
              ),
              _ListTab(
                empty: 'Sem histórico',
                items: _precos.map((p) => '${p['precoAnterior']} → ${p['precoNovo']} (${p['data']?.toString().substring(0, 10) ?? ''})').toList(),
              ),
              _ListTab(
                empty: 'Sem histórico regulatório',
                items: _historico
                    .map(
                      (item) =>
                          '${item['rule'] ?? 'Regra'} • ${item['source'] ?? 'manual'} (${item['createdAt']?.toString().substring(0, 10) ?? ''})',
                    )
                    .toList(),
              ),
              _ListTab(
                empty: 'Sem fornecedores vinculados',
                items: _fornecedores
                    .map(
                      (item) =>
                          '${item['fornecedor']?['nome'] ?? 'Fornecedor'} • compra ${item['precoCompra'] ?? 0}${item['fornecedorPrincipal'] == true ? ' • principal' : ''}',
                    )
                    .toList(),
              ),
              _ListTab(
                empty: 'Sem auditoria',
                items: _auditoria
                    .map(
                      (item) =>
                          '${item['action'] ?? 'Evento'} • ${item['user']?['nome'] ?? 'Sistema'} (${item['createdAt']?.toString().substring(0, 10) ?? ''})',
                    )
                    .toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _InfoTab extends StatelessWidget {
  const _InfoTab({required this.product});
  final Product product;

  @override
  Widget build(BuildContext context) {
    final s = context.spacing;
    return ListView(
      padding: EdgeInsets.all(s.md),
      children: [
        _row('Substância activa', product.substanciaActiva),
        _row('Dosagem', product.dosagem),
        _row('Forma', product.forma),
        _row('Apresentação', product.apresentacao),
        _row('Categoria', product.categoriaNome ?? product.categoria.label),
        _row('Stock disponível', product.estoqueAtual.toString()),
        _row('Nº lotes', product.numLotes.toString()),
        _row('Próxima validade', product.proximaValidade?.toString().substring(0, 10)),
        _row('Estado', product.ativo ? 'Activo' : 'Inactivo'),
      ],
    );
  }

  Widget _row(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 140, child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600))),
          Expanded(child: Text(value ?? '—')),
        ],
      ),
    );
  }
}

class _ListTab extends StatelessWidget {
  const _ListTab({required this.empty, required this.items});
  final String empty;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Center(child: Text(empty));
    }
    return ListView.separated(
      itemCount: items.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (_, i) => ListTile(title: Text(items[i])),
    );
  }
}

extension on Map<String, dynamic> {
  List<Map<String, dynamic>> letItems() {
    return (this['items'] as List<dynamic>? ?? <dynamic>[])
        .cast<Map<String, dynamic>>();
  }
}
