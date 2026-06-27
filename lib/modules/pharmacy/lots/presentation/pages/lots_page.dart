import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/extensions/async_value_extensions.dart';
import '../../../../../core/theme/design_tokens.dart';
import '../../../../../core/theme/spacing.dart';
import '../../../../../shared/widgets/cards/enterprise_stat_card.dart';
import '../../../../../shared/widgets/layout/enterprise_module_hub.dart';
import '../../../../../shared/widgets/tables/enterprise_data_table.dart';
import '../../../../stock/presentation/widgets/movimentacoes_pagination.dart';
import '../providers/lots_provider.dart';
import '../widgets/lot_detail_drawer.dart';

class LotsPage extends ConsumerStatefulWidget {
  const LotsPage({super.key});

  @override
  ConsumerState<LotsPage> createState() => _LotsPageState();
}

class _LotsPageState extends ConsumerState<LotsPage> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Color _validadeColor(BuildContext context, String? indicador) {
    final t = context.pharmaTokens;
    switch (indicador) {
      case 'EXPIRADO':
        return t.posDanger;
      case '30_DIAS':
        return Colors.orange;
      case '60_DIAS':
        return Colors.amber.shade700;
      default:
        return t.brandGreen;
    }
  }

  @override
  Widget build(BuildContext context) {
    final asyncState = ref.watch(lotsViewProvider);
    final controller = ref.read(lotsViewProvider.notifier);
    final current = asyncState.valueOrNull;
    final dash = current?.dashboard;
    final t = context.pharmaTokens;
    final s = context.spacing;

    if (current != null && _search.text != current.query) {
      _search.value = TextEditingValue(
        text: current.query,
        selection: TextSelection.collapsed(offset: current.query.length),
      );
    }

    return EnterpriseModuleHub(
      title: 'Lotes',
      subtitle: 'Gestão de lotes, validades e disponibilidade sanitária.',
      tag: 'Farmácia',
      kpis: dash == null
          ? null
          : [
              EnterpriseStatCard(
                title: 'Total de lotes',
                value: '${dash['totalLotes'] ?? 0}',
                icon: Icons.inventory_2_outlined,
              ),
              EnterpriseStatCard(
                title: 'Disponíveis',
                value: '${dash['lotesDisponiveis'] ?? 0}',
                icon: Icons.check_circle_outline,
              ),
              EnterpriseStatCard(
                title: 'Sanitários',
                value: '${dash['lotesSanitarios'] ?? 0}',
                icon: Icons.health_and_safety_outlined,
              ),
              EnterpriseStatCard(
                title: 'Alertas',
                value: '${dash['alertasOperacionais'] ?? 0}',
                icon: Icons.notifications_active_outlined,
              ),
            ],
      actions: [
        IconButton(
          onPressed: () => controller.refresh(force: true),
          icon: const Icon(Icons.refresh),
        ),
      ],
      filters: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          SizedBox(
            width: 260,
            child: TextField(
              controller: _search,
              decoration: const InputDecoration(
                hintText: 'Produto ou nº lote...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onSubmitted: controller.setSearch,
            ),
          ),
          DropdownMenu<String?>(
            label: const Text('Estado sanitário'),
            initialSelection: current?.estadoSanitario,
            onSelected: controller.setEstadoSanitario,
            dropdownMenuEntries: const [
              DropdownMenuEntry(value: null, label: 'Todos'),
              DropdownMenuEntry(value: 'VALIDO', label: 'Válido'),
              DropdownMenuEntry(value: 'EXPIRADO', label: 'Expirado'),
              DropdownMenuEntry(value: 'QUARENTENA', label: 'Quarentena'),
              DropdownMenuEntry(value: 'RECALL', label: 'Recall'),
            ],
          ),
          DropdownMenu<String?>(
            label: const Text('Disponibilidade'),
            initialSelection: current?.disponibilidade,
            onSelected: controller.setDisponibilidade,
            dropdownMenuEntries: const [
              DropdownMenuEntry(value: null, label: 'Todas'),
              DropdownMenuEntry(value: 'DISPONIVEL', label: 'Disponível'),
              DropdownMenuEntry(value: 'RESERVADO', label: 'Reservado'),
              DropdownMenuEntry(value: 'BLOQUEADO', label: 'Bloqueado'),
              DropdownMenuEntry(value: 'INDISPONIVEL', label: 'Indisponível'),
            ],
          ),
          FilterChip(
            label: const Text('Expirados'),
            selected: current?.expirado == true,
            onSelected: (v) => controller.setExpirado(v ? true : null),
          ),
        ],
      ),
      child: Column(
        children: [
          if (asyncState.isLoading) const LinearProgressIndicator(),
          if (asyncState.hasError)
            Padding(
              padding: EdgeInsets.only(bottom: s.sm),
              child: Text(
                asyncState.error.toString(),
                style: TextStyle(color: t.posDanger),
              ),
            ),
          Expanded(
            child: (current?.items.isEmpty ?? true) && !asyncState.isLoading
                ? const Center(child: Text('Nenhum lote encontrado'))
                : EnterpriseDataTable(
              columns: const [
                DataColumn(label: Text('PRODUTO')),
                DataColumn(label: Text('Nº LOTE')),
                DataColumn(label: Text('VALIDADE')),
                DataColumn(label: Text('STOCK')),
                DataColumn(label: Text('P. COMPRA')),
                DataColumn(label: Text('P. VENDA')),
                DataColumn(label: Text('ESTADO')),
              ],
              rowCount: current?.items.length ?? 0,
              rowBuilder: (context, index) {
                final item = current!.items[index];
                final color = _validadeColor(context, item['indicadorValidade'] as String?);
                return DataRow(
                  onSelectChanged: (_) => _openLoteDrawer(item['id']?.toString() ?? ''),
                  cells: [
                    DataCell(Text(item['produtoNome']?.toString() ?? '—')),
                    DataCell(Text(item['numeroLote']?.toString() ?? '—')),
                    DataCell(Text(
                      item['dataValidade']?.toString().substring(0, 10) ?? '—',
                      style: TextStyle(color: color, fontWeight: FontWeight.w600),
                    )),
                    DataCell(Text(item['quantidadeDisponivel']?.toString() ?? '0')),
                    DataCell(Text(item['precoCompra']?.toString() ?? '—')),
                    DataCell(Text(item['precoVenda']?.toString() ?? '—')),
                    DataCell(Text(item['estadoSanitario']?.toString() ?? '—')),
                  ],
                );
              },
            ),
          ),
          MovimentacoesPagination(
            page: current?.page ?? 1,
            pageSize: current?.pageSize ?? 20,
            hasMore: current?.hasMore ?? false,
            isBusy: asyncState.isLoading,
            onPrev: (current?.page ?? 1) > 1
                ? () => controller.goToPage((current?.page ?? 1) - 1)
                : null,
            onNext: current?.hasMore == true
                ? () => controller.goToPage((current?.page ?? 1) + 1)
                : null,
            onPageSizeChanged: controller.setPageSize,
          ),
          if (current?.totalCount != null)
            Text(
              'Total: ${current!.totalCount} lote(s)',
              style: TextStyle(color: t.textMuted, fontSize: 12),
            ),
        ],
      ),
    );
  }

  Future<void> _openLoteDrawer(String loteId) async {
    if (loteId.isEmpty) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        final s = context.spacing;
        return Dialog(
          alignment: Alignment.centerRight,
          insetPadding: EdgeInsets.symmetric(horizontal: 16, vertical: s.md),
          backgroundColor: Colors.transparent,
          child: LotDetailDrawer(
            loteId: loteId,
            onClose: () => Navigator.of(dialogContext).pop(),
          ),
        );
      },
    );
  }
}
