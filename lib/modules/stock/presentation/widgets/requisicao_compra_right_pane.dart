import 'package:flutter/material.dart';

import '../../../../core/theme/design_tokens.dart';
import '../../../../core/theme/extensions.dart';
import '../../../../shared/widgets/buttons/pharma_button_loader.dart';
import '../../domain/entities/requisicao.dart';
import '../providers/requisicao_provider.dart';
import 'requisicao_empty_pane.dart';
import 'requisicao_hub_formatters.dart';
import 'requisicao_purchase_items_view.dart';

class RequisicaoCompraRightPane extends StatelessWidget {
  const RequisicaoCompraRightPane({
    super.key,
    required this.state,
    required this.onConfirm,
    required this.onEditHeader,
    required this.onEditItem,
    required this.onRemoveItem,
    this.onExportPdf,
    this.fullscreen = false,
  });

  final RequisicaoState state;
  final Future<void> Function() onConfirm;
  final Future<void> Function() onEditHeader;
  final Future<void> Function(RequisicaoItem item) onEditItem;
  final Future<void> Function(RequisicaoItem item) onRemoveItem;
  final Future<void> Function()? onExportPdf;
  final bool fullscreen;

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final s = context.spacing;
    final activeRequisicao = state.activeRequisicao;
    final isBusy =
        state.isLoadingActiveRequisicao ||
        state.isAddingItem ||
        state.isUpdatingRequisicao ||
        state.isApprovingRequisicao;

    final title = Row(
      children: [
        Expanded(
          child: Text(
            activeRequisicao == null
                ? 'Nova Requisição'
                : 'Requisição #${activeRequisicao.id}',
            style: Theme.of(
              context,
            ).textTheme.erpPageTitle.copyWith(color: t.textPrimary),
          ),
        ),
        if (isBusy) const PharmaButtonLoader(),
      ],
    );

    final body = activeRequisicao == null
        ? RequisicaoEmptyPane(
            icon: Icons.shopping_cart_outlined,
            title: 'Nenhuma requisição ativa',
            subtitle: 'Inicie uma requisição para adicionar produtos.',
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RequisicaoActivePurchaseHeader(
                purchase: activeRequisicao,
                canEdit:
                    activeRequisicao.status.isEditable &&
                    !state.isUpdatingRequisicao,
                onEdit: onEditHeader,
              ),
              SizedBox(height: s.md),
              if (activeRequisicao.items.isEmpty)
                RequisicaoEmptyPane(
                  icon: Icons.playlist_add_outlined,
                  title: 'Carrinho vazio',
                  subtitle: fullscreen
                      ? 'Selecione produtos na lista principal. Adicione itens para confirmar.'
                      : 'Selecione produtos na lista ao lado.',
                )
              else
                RequisicaoPurchaseItemsView(
                  items: activeRequisicao.items,
                  isEditable: activeRequisicao.status.isEditable,
                  onEdit: onEditItem,
                  onRemove: onRemoveItem,
                  nested: true,
                ),
            ],
          );

    final footer = RequisicaoConfirmFooter(
      canConfirm: state.canApproveActiveRequisicao,
      isLoading: state.isApprovingRequisicao,
      activeRequisicao: activeRequisicao,
      onConfirm: onConfirm,
      onExportPdf: onExportPdf,
      stackActions: fullscreen,
    );

    final decoration = BoxDecoration(
      color: t.card,
      borderRadius: fullscreen ? null : BorderRadius.circular(t.radiusXl),
      boxShadow: fullscreen
          ? null
          : [
              BoxShadow(
                color: Theme.of(
                  context,
                ).colorScheme.shadow.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
    );

    if (fullscreen) {
      return DecoratedBox(
        decoration: decoration,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(s.lg, s.lg, s.lg, s.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    title,
                    SizedBox(height: s.lg),
                    body,
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(s.lg, 0, s.lg, s.lg),
              child: footer,
            ),
          ],
        ),
      );
    }

    return Container(
      padding: EdgeInsets.all(s.lg),
      decoration: decoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          title,
          SizedBox(height: s.lg),
          if (activeRequisicao == null)
            Expanded(child: body)
          else ...[
            RequisicaoActivePurchaseHeader(
              purchase: activeRequisicao,
              canEdit:
                  activeRequisicao.status.isEditable &&
                  !state.isUpdatingRequisicao,
              onEdit: onEditHeader,
            ),
            SizedBox(height: s.md),
            Expanded(
              child: activeRequisicao.items.isEmpty
                  ? const RequisicaoEmptyPane(
                      icon: Icons.playlist_add_outlined,
                      title: 'Carrinho vazio',
                      subtitle: 'Selecione produtos na lista ao lado.',
                    )
                  : RequisicaoPurchaseItemsView(
                      items: activeRequisicao.items,
                      isEditable: activeRequisicao.status.isEditable,
                      onEdit: onEditItem,
                      onRemove: onRemoveItem,
                    ),
            ),
          ],
          SizedBox(height: s.md),
          footer,
        ],
      ),
    );
  }
}

class RequisicaoActivePurchaseHeader extends StatelessWidget {
  const RequisicaoActivePurchaseHeader({
    super.key,
    required this.purchase,
    this.canEdit = false,
    this.onEdit,
  });

  final RequisicaoDetalhe purchase;
  final bool canEdit;
  final Future<void> Function()? onEdit;

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final s = context.spacing;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(s.md),
      decoration: BoxDecoration(
        color: t.bgPrimary.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(t.radiusMd),
        border: Border.all(color: t.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  purchase.numeroDocumento.isNotEmpty
                      ? 'Documento ${purchase.numeroDocumento}'
                      : 'Requisição #${purchase.id}',
                  style: Theme.of(
                    context,
                  ).textTheme.erpCardTitle.copyWith(color: t.textPrimary),
                ),
              ),
              if (canEdit && onEdit != null)
                IconButton(
                  tooltip: 'Editar cabeçalho',
                  onPressed: onEdit,
                  icon: Icon(Icons.edit_outlined, size: t.iconSm),
                ),
            ],
          ),
          SizedBox(height: s.sm),
          Wrap(
            spacing: s.sm,
            runSpacing: s.sm,
            children: [
              RequisicaoInfoTag(
                label: purchase.status.label,
                color: purchase.status.isEditable ? t.posWarning : t.brandGreen,
              ),
              if (purchase.numeroDocumento.isNotEmpty)
                RequisicaoInfoTag(
                  label: 'Nº doc. ${purchase.numeroDocumento}',
                  color: t.brandBlue,
                ),
              RequisicaoInfoTag(
                label: 'Fornecedor ${purchase.fornecedorNome ?? 'N/A'}',
                color: t.brandBlue,
              ),
              RequisicaoInfoTag(
                label: 'Data ${requisicaoFormatDate(purchase.createdAt)}',
                color: t.textMuted,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class RequisicaoConfirmFooter extends StatelessWidget {
  const RequisicaoConfirmFooter({
    super.key,
    required this.canConfirm,
    required this.isLoading,
    required this.activeRequisicao,
    required this.onConfirm,
    this.onExportPdf,
    this.stackActions = false,
  });

  final bool canConfirm;
  final bool isLoading;
  final RequisicaoDetalhe? activeRequisicao;
  final Future<void> Function() onConfirm;
  final Future<void> Function()? onExportPdf;
  final bool stackActions;

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final s = context.spacing;
    final textTheme = Theme.of(context).textTheme;
    final helperText = switch (activeRequisicao?.status) {
      null => 'Inicie uma requisição para habilitar ações.',
      RequisicaoStatus.pendente =>
        activeRequisicao!.items.isEmpty
            ? 'Adicione itens para confirmar.'
            : 'Total: ${requisicaoFormatMoney((activeRequisicao!.total ?? 0))}',
      RequisicaoStatus.aprovada => 'Requisição aprovada.',
      RequisicaoStatus.rejeitada => 'Requisição rejeitada.',
      RequisicaoStatus.concluida => 'Requisição finalizada.',
      RequisicaoStatus.cancelada => 'Requisição cancelada.',
    };

    final isPendingWithItems =
        activeRequisicao?.status == RequisicaoStatus.pendente &&
        (activeRequisicao?.items.isNotEmpty ?? false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          helperText,
          style: textTheme.erpBodySecondary.copyWith(
            color: isPendingWithItems ? t.textSecondary : t.textMuted,
            fontWeight: isPendingWithItems ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
        SizedBox(height: s.sm),
        if (stackActions)
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              OutlinedButton.icon(
                onPressed: onExportPdf != null ? () => onExportPdf!() : null,
                icon: const Icon(Icons.picture_as_pdf_outlined),
                label: const Text('Exportar PDF'),
              ),
              SizedBox(height: s.sm),
              FilledButton.icon(
                onPressed: canConfirm ? onConfirm : null,
                icon: isLoading
                    ? const PharmaButtonLoader()
                    : const Icon(Icons.check_circle_outline_rounded),
                label: Text(
                  isLoading ? 'A confirmar...' : 'Confirmar Requisição',
                ),
              ),
            ],
          )
        else
          Align(
            alignment: Alignment.centerRight,
            child: Wrap(
              spacing: s.md,
              runSpacing: s.sm,
              alignment: WrapAlignment.end,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: onExportPdf != null ? () => onExportPdf!() : null,
                  icon: const Icon(Icons.picture_as_pdf_outlined),
                  label: const Text('Exportar PDF'),
                ),
                FilledButton.icon(
                  onPressed: canConfirm ? onConfirm : null,
                  icon: isLoading
                      ? const PharmaButtonLoader()
                      : const Icon(Icons.check_circle_outline_rounded),
                  label: Text(
                    isLoading ? 'A confirmar...' : 'Confirmar Requisição',
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
