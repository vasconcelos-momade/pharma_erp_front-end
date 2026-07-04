import 'package:flutter/material.dart';

import '../../../../core/theme/design_tokens.dart';
import '../../../../core/theme/extensions.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../shared/navigation/adaptive_navigator.dart';
import '../../domain/entities/requisicao.dart';
import 'requisicao_hub_formatters.dart';

class RequisicaoPurchaseItemsView extends StatelessWidget {
  const RequisicaoPurchaseItemsView({
    super.key,
    required this.items,
    required this.isEditable,
    required this.onEdit,
    required this.onRemove,
    this.nested = false,
  });

  final List<RequisicaoItem> items;
  final bool isEditable;
  final ValueChanged<RequisicaoItem> onEdit;
  final ValueChanged<RequisicaoItem> onRemove;
  final bool nested;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        if (width < 768) {
          return RequisicaoPurchaseItemsCardList(
            items: items,
            isEditable: isEditable,
            onEdit: onEdit,
            onRemove: onRemove,
            nested: nested,
          );
        }

        if (width < 1200) {
          return RequisicaoPurchaseItemsTabletTable(
            items: items,
            isEditable: isEditable,
            onEdit: onEdit,
            onRemove: onRemove,
          );
        }

        return RequisicaoPurchaseItemsDesktopTable(
          items: items,
          isEditable: isEditable,
          onEdit: onEdit,
          onRemove: onRemove,
        );
      },
    );
  }
}

class RequisicaoPurchaseItemsDesktopTable extends StatelessWidget {
  const RequisicaoPurchaseItemsDesktopTable({
    super.key,
    required this.items,
    required this.isEditable,
    required this.onEdit,
    required this.onRemove,
  });

  final List<RequisicaoItem> items;
  final bool isEditable;
  final ValueChanged<RequisicaoItem> onEdit;
  final ValueChanged<RequisicaoItem> onRemove;

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final s = context.spacing;

    return Scrollbar(
      thumbVisibility: true,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: 1200,
          child: SingleChildScrollView(
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(
                t.bgPrimary.withValues(alpha: 0.1),
              ),
              columnSpacing: s.lg,
              columns: const [
                DataColumn(label: Text('Produto')),
                DataColumn(label: Text('Lote')),
                DataColumn(label: Text('Validade')),
                DataColumn(label: Text('Preço Compra')),
                DataColumn(label: Text('Preço Venda')),
                DataColumn(label: Text('Qtd')),
                DataColumn(label: Text('Subtotal')),
                DataColumn(label: Text('Ações')),
              ],
              rows: items.map((item) {
                return DataRow(
                  cells: [
                    DataCell(
                      SizedBox(width: 260, child: Text(item.produtoNome)),
                    ),
                    DataCell(
                      SizedBox(width: 150, child: Text(item.numeroLote ?? '-')),
                    ),
                    DataCell(
                      SizedBox(
                        width: 130,
                        child: Text(
                          requisicaoFormatDisplayDate(item.dataValidade),
                        ),
                      ),
                    ),
                    DataCell(
                      SizedBox(
                        width: 130,
                        child: Text(
                          requisicaoFormatMoney(item.precoCompra ?? 0),
                        ),
                      ),
                    ),
                    DataCell(
                      SizedBox(
                        width: 130,
                        child: Text(
                          item.precoVenda != null
                              ? requisicaoFormatMoney(item.precoVenda!)
                              : '-',
                        ),
                      ),
                    ),
                    DataCell(
                      SizedBox(
                        width: 90,
                        child: Text(requisicaoFormatQuantity(item.quantidade)),
                      ),
                    ),
                    DataCell(
                      SizedBox(
                        width: 130,
                        child: Text(requisicaoFormatMoney(item.subtotal ?? 0)),
                      ),
                    ),
                    DataCell(
                      SizedBox(
                        width: 140,
                        child: RequisicaoPurchaseItemActionButtons(
                          item: item,
                          isEditable: isEditable,
                          onEdit: onEdit,
                          onRemove: onRemove,
                        ),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}

class RequisicaoPurchaseItemsTabletTable extends StatelessWidget {
  const RequisicaoPurchaseItemsTabletTable({
    super.key,
    required this.items,
    required this.isEditable,
    required this.onEdit,
    required this.onRemove,
  });

  final List<RequisicaoItem> items;
  final bool isEditable;
  final ValueChanged<RequisicaoItem> onEdit;
  final ValueChanged<RequisicaoItem> onRemove;

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final s = context.spacing;

    return Scrollbar(
      thumbVisibility: true,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: 920,
          child: SingleChildScrollView(
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(
                t.bgPrimary.withValues(alpha: 0.1),
              ),
              columnSpacing: s.md,
              columns: const [
                DataColumn(label: Text('Produto')),
                DataColumn(label: Text('Lote')),
                DataColumn(label: Text('Preço Compra')),
                DataColumn(label: Text('Qtd')),
                DataColumn(label: Text('Subtotal')),
                DataColumn(label: Text('Ações')),
              ],
              rows: items.map((item) {
                return DataRow(
                  cells: [
                    DataCell(
                      SizedBox(
                        width: 260,
                        child: Tooltip(
                          message:
                              'Validade: ${requisicaoFormatDisplayDate(item.dataValidade)}\n'
                              'Preço venda: ${item.precoVenda != null ? requisicaoFormatMoney(item.precoVenda!) : '-'}',
                          child: Text(
                            item.produtoNome,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ),
                    DataCell(
                      SizedBox(width: 140, child: Text(item.numeroLote ?? '-')),
                    ),
                    DataCell(
                      SizedBox(
                        width: 130,
                        child: Text(
                          requisicaoFormatMoney(item.precoCompra ?? 0),
                        ),
                      ),
                    ),
                    DataCell(
                      SizedBox(
                        width: 80,
                        child: Text(requisicaoFormatQuantity(item.quantidade)),
                      ),
                    ),
                    DataCell(
                      SizedBox(
                        width: 130,
                        child: Text(requisicaoFormatMoney(item.subtotal ?? 0)),
                      ),
                    ),
                    DataCell(
                      SizedBox(
                        width: 170,
                        child: RequisicaoPurchaseItemActionButtons(
                          item: item,
                          isEditable: isEditable,
                          onEdit: onEdit,
                          onRemove: onRemove,
                          showDetailsButton: true,
                        ),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}

class RequisicaoPurchaseItemsCardList extends StatelessWidget {
  const RequisicaoPurchaseItemsCardList({
    super.key,
    required this.items,
    required this.isEditable,
    required this.onEdit,
    required this.onRemove,
    this.nested = false,
  });

  final List<RequisicaoItem> items;
  final bool isEditable;
  final ValueChanged<RequisicaoItem> onEdit;
  final ValueChanged<RequisicaoItem> onRemove;
  final bool nested;

  @override
  Widget build(BuildContext context) {
    final s = context.spacing;

    return ListView.separated(
      shrinkWrap: nested,
      primary: !nested,
      physics: nested
          ? const NeverScrollableScrollPhysics()
          : const AlwaysScrollableScrollPhysics(),
      itemCount: items.length,
      separatorBuilder: (_, _) => SizedBox(height: s.sm),
      itemBuilder: (context, index) {
        final item = items[index];
        return RequisicaoPurchaseItemCard(
          item: item,
          isEditable: isEditable,
          onEdit: onEdit,
          onRemove: onRemove,
        );
      },
    );
  }
}

class RequisicaoPurchaseItemCard extends StatelessWidget {
  const RequisicaoPurchaseItemCard({
    super.key,
    required this.item,
    required this.isEditable,
    required this.onEdit,
    required this.onRemove,
  });

  final RequisicaoItem item;
  final bool isEditable;
  final ValueChanged<RequisicaoItem> onEdit;
  final ValueChanged<RequisicaoItem> onRemove;

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final s = context.spacing;

    return Container(
      padding: EdgeInsets.all(s.md),
      decoration: BoxDecoration(
        color: t.bgPrimary.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(t.radiusMd),
        border: Border.all(color: t.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.produtoNome,
            style: Theme.of(
              context,
            ).textTheme.erpCardTitle.copyWith(color: t.textPrimary),
          ),
          SizedBox(height: s.sm),
          Wrap(
            spacing: s.md,
            runSpacing: s.sm,
            children: [
              RequisicaoPurchaseItemInfo(
                label: 'Lote',
                value: item.numeroLote ?? '-',
              ),
              RequisicaoPurchaseItemInfo(
                label: 'Validade',
                value: requisicaoFormatDisplayDate(item.dataValidade),
              ),
              RequisicaoPurchaseItemInfo(
                label: 'Preço compra',
                value: requisicaoFormatMoney(item.precoCompra ?? 0),
              ),
              RequisicaoPurchaseItemInfo(
                label: 'Preço venda',
                value: item.precoVenda != null
                    ? requisicaoFormatMoney(item.precoVenda!)
                    : '-',
              ),
              RequisicaoPurchaseItemInfo(
                label: 'Quantidade',
                value: requisicaoFormatQuantity(item.quantidade),
              ),
              RequisicaoPurchaseItemInfo(
                label: 'Subtotal',
                value: requisicaoFormatMoney(item.subtotal ?? 0),
              ),
            ],
          ),
          SizedBox(height: s.md),
          Wrap(
            spacing: s.sm,
            runSpacing: s.sm,
            children: [
              OutlinedButton.icon(
                onPressed: isEditable ? () => onEdit(item) : null,
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Editar'),
              ),
              OutlinedButton.icon(
                onPressed: isEditable ? () => onRemove(item) : null,
                icon: const Icon(Icons.delete_outline_rounded),
                label: const Text('Remover'),
                style: OutlinedButton.styleFrom(foregroundColor: t.posDanger),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class RequisicaoPurchaseItemInfo extends StatelessWidget {
  const RequisicaoPurchaseItemInfo({
    super.key,
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final textTheme = Theme.of(context).textTheme;

    return RichText(
      text: TextSpan(
        style: textTheme.erpCaption.copyWith(color: t.textMuted),
        children: [
          TextSpan(
            text: '$label: ',
            style: textTheme.erpLabel.copyWith(color: t.textPrimary),
          ),
          TextSpan(text: value),
        ],
      ),
    );
  }
}

class RequisicaoPurchaseItemActionButtons extends StatelessWidget {
  const RequisicaoPurchaseItemActionButtons({
    super.key,
    required this.item,
    required this.isEditable,
    required this.onEdit,
    required this.onRemove,
    this.showDetailsButton = false,
  });

  final RequisicaoItem item;
  final bool isEditable;
  final ValueChanged<RequisicaoItem> onEdit;
  final ValueChanged<RequisicaoItem> onRemove;
  final bool showDetailsButton;

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showDetailsButton)
          IconButton(
            icon: Icon(Icons.info_outline_rounded, size: t.iconSm),
            onPressed: () => showRequisicaoPurchaseItemDetails(context, item),
            tooltip: 'Ver detalhes',
          ),
        IconButton(
          icon: Icon(Icons.edit_outlined, size: t.iconSm),
          onPressed: isEditable ? () => onEdit(item) : null,
          tooltip: 'Editar item',
        ),
        IconButton(
          icon: Icon(Icons.delete_outline_rounded, size: t.iconSm),
          onPressed: isEditable ? () => onRemove(item) : null,
          color: t.posDanger,
          tooltip: 'Remover item',
        ),
      ],
    );
  }
}

Future<void> showRequisicaoPurchaseItemDetails(
  BuildContext context,
  RequisicaoItem item,
) {
  return AdaptiveNavigator.openDetail(
    context: context,
    title: item.produtoNome,
    builder: (detailContext, onClose) {
      final s = detailContext.spacing;
      return Padding(
        padding: EdgeInsets.all(s.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            RequisicaoDialogDetailRow(
              label: 'Lote',
              value: item.numeroLote ?? '-',
            ),
            SizedBox(height: s.sm),
            RequisicaoDialogDetailRow(
              label: 'Validade',
              value: requisicaoFormatDisplayDate(item.dataValidade),
            ),
            SizedBox(height: s.sm),
            RequisicaoDialogDetailRow(
              label: 'Preço compra',
              value: requisicaoFormatMoney(item.precoCompra ?? 0),
            ),
            SizedBox(height: s.sm),
            RequisicaoDialogDetailRow(
              label: 'Preço venda',
              value: item.precoVenda != null
                  ? requisicaoFormatMoney(item.precoVenda!)
                  : '-',
            ),
            SizedBox(height: s.sm),
            RequisicaoDialogDetailRow(
              label: 'Quantidade',
              value: requisicaoFormatQuantity(item.quantidade),
            ),
            SizedBox(height: s.sm),
            RequisicaoDialogDetailRow(
              label: 'Subtotal',
              value: requisicaoFormatMoney(item.subtotal ?? 0),
            ),
            const Spacer(),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: onClose,
                child: const Text('Fechar'),
              ),
            ),
          ],
        ),
      );
    },
  );
}

class RequisicaoDialogDetailRow extends StatelessWidget {
  const RequisicaoDialogDetailRow({
    super.key,
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final textTheme = Theme.of(context).textTheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: textTheme.erpBodySecondary.copyWith(color: t.textMuted),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: textTheme.erpLabel.copyWith(color: t.textPrimary),
          ),
        ),
      ],
    );
  }
}
