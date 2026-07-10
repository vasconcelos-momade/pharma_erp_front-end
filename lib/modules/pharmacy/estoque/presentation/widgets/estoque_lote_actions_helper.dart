import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../../app/router/routes.dart';
import '../../../../../core/errors/api_failure.dart';
import '../../../../../core/theme/extensions.dart';
import '../../../../../core/utils/lote_stock_utils.dart';
import '../../../../../shared/widgets/feedback/pharma_feedback.dart';
import '../../../lots/presentation/widgets/lot_actions_helper.dart';
import '../../data/datasources/estoque_remote_datasource.dart';
import '../../domain/entities/estoque_item.dart';
import '../providers/estoque_provider.dart';

abstract final class EstoqueLoteActionsHelper {
  EstoqueLoteActionsHelper._();

  static Future<void> editarLote(
    BuildContext context,
    WidgetRef ref,
    EstoqueItem item,
  ) async {
    final numeroController = TextEditingController(text: item.numeroLote);
    final validadeController = TextEditingController(
      text: item.dataValidade != null
          ? DateFormat('yyyy-MM-dd').format(item.dataValidade!.toLocal())
          : '',
    );
    final fabricacaoController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final s = dialogContext.spacing;
        return AlertDialog(
          title: const Text('Editar lote'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: numeroController,
                  decoration: const InputDecoration(
                    labelText: 'Número do lote',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: s.sm),
                TextField(
                  controller: validadeController,
                  decoration: const InputDecoration(
                    labelText: 'Data de validade (AAAA-MM-DD)',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: s.sm),
                TextField(
                  controller: fabricacaoController,
                  decoration: const InputDecoration(
                    labelText: 'Data de fabricação (opcional)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !context.mounted) return;

    final numeroLote = numeroController.text.trim();
    final dataValidade = validadeController.text.trim();
    final dataFabricacao = fabricacaoController.text.trim();

    numeroController.dispose();
    validadeController.dispose();
    fabricacaoController.dispose();

    final controller = ref.read(estoqueListProvider.notifier);
    controller.setActionLoteId(item.id);
    try {
      await ref.read(estoqueRemoteDataSourceProvider).updateLote(
            item.id,
            numeroLote: numeroLote,
            dataValidade: dataValidade,
            dataFabricacao: dataFabricacao.isEmpty ? null : dataFabricacao,
          );
      if (!context.mounted) return;
      PharmaFeedback.success(context, 'Lote actualizado com sucesso');
      await controller.refreshCurrentPage();
    } on ApiFailure catch (e) {
      if (context.mounted) PharmaFeedback.error(context, e.message);
    } catch (e) {
      if (context.mounted) PharmaFeedback.error(context, e.toString());
    } finally {
      controller.setActionLoteId(null);
    }
  }

  static Future<void> alterarPreco(
    BuildContext context,
    WidgetRef ref,
    EstoqueItem item,
  ) async {
    final compraController =
        TextEditingController(text: item.precoCompra.toString());
    final vendaController = TextEditingController(
      text: item.precoVenda?.toString() ?? '',
    );
    final motivoController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final s = dialogContext.spacing;
        return AlertDialog(
          title: const Text('Alterar preço do lote'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: compraController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Preço de compra',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: s.sm),
                TextField(
                  controller: vendaController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Preço de venda',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: s.sm),
                TextField(
                  controller: motivoController,
                  decoration: const InputDecoration(
                    labelText: 'Motivo da alteração (opcional)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Confirmar'),
            ),
          ],
        );
      },
    );

    final precoCompra =
        num.tryParse(compraController.text.replaceAll(',', '.')) ?? item.precoCompra;
    final precoVendaRaw = vendaController.text.trim();
    final precoVenda = precoVendaRaw.isEmpty
        ? null
        : num.tryParse(precoVendaRaw.replaceAll(',', '.'));
    final motivo = motivoController.text.trim();

    compraController.dispose();
    vendaController.dispose();
    motivoController.dispose();

    if (confirmed != true || !context.mounted) return;

    final controller = ref.read(estoqueListProvider.notifier);
    controller.setActionLoteId(item.id);
    try {
      await ref.read(estoqueRemoteDataSourceProvider).updateLotePrecos(
            item.id,
            precoCompra: precoCompra,
            precoVenda: precoVenda,
            motivo: motivo.isEmpty ? null : motivo,
          );
      if (!context.mounted) return;
      PharmaFeedback.success(context, 'Preços actualizados com sucesso');
      await controller.refreshCurrentPage();
    } on ApiFailure catch (e) {
      if (context.mounted) PharmaFeedback.error(context, e.message);
    } catch (e) {
      if (context.mounted) PharmaFeedback.error(context, e.toString());
    } finally {
      controller.setActionLoteId(null);
    }
  }

  static Future<void> ajustarStock(
    BuildContext context,
    WidgetRef ref,
    EstoqueItem item,
  ) async {
    final quantidadeController = TextEditingController();
    final motivoController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final s = dialogContext.spacing;
        return AlertDialog(
          title: const Text('Ajustar stock'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Stock actual: ${LoteStockUtils.formatDisponivelFromNum(item.quantidadeDisponivel)}',
                  style: Theme.of(dialogContext).textTheme.erpBodySecondary,
                ),
                SizedBox(height: s.sm),
                TextField(
                  controller: quantidadeController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true, signed: true),
                  decoration: const InputDecoration(
                    labelText: 'Quantidade (+ entrada / − saída)',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: s.sm),
                TextField(
                  controller: motivoController,
                  decoration: const InputDecoration(
                    labelText: 'Motivo',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Confirmar'),
            ),
          ],
        );
      },
    );

    final quantidade =
        num.tryParse(quantidadeController.text.replaceAll(',', '.'));
    final motivo = motivoController.text.trim();
    quantidadeController.dispose();
    motivoController.dispose();

    if (confirmed != true || !context.mounted) return;
    if (quantidade == null || quantidade == 0) {
      PharmaFeedback.error(context, 'Indique uma quantidade válida');
      return;
    }
    if (motivo.isEmpty) {
      PharmaFeedback.error(context, 'Motivo é obrigatório');
      return;
    }

    final controller = ref.read(estoqueListProvider.notifier);
    controller.setActionLoteId(item.id);
    try {
      await ref.read(estoqueRemoteDataSourceProvider).adjustStock(
            produtoId: item.produtoId,
            loteId: item.id,
            quantidade: quantidade,
            motivo: motivo,
          );
      if (!context.mounted) return;
      PharmaFeedback.success(context, 'Stock ajustado com sucesso');
      await controller.refreshCurrentPage();
    } on ApiFailure catch (e) {
      if (context.mounted) PharmaFeedback.error(context, e.message);
    } catch (e) {
      if (context.mounted) PharmaFeedback.error(context, e.toString());
    } finally {
      controller.setActionLoteId(null);
    }
  }

  static Future<void> movimentacaoSanitaria(
    BuildContext context,
    WidgetRef ref,
    EstoqueItem item,
  ) async {
    String tipo = 'QUARENTENA';
    final quantidadeController = TextEditingController();
    final motivoController = TextEditingController();
    final documentoController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final s = dialogContext.spacing;
        return StatefulBuilder(
          builder: (context, setState) {
            final requiresQty = tipo != 'RECALL';
            return AlertDialog(
              title: const Text('Movimentação sanitária'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      key: ValueKey('sanitaria-tipo-$tipo'),
                      initialValue: tipo,
                      decoration: const InputDecoration(
                        labelText: 'Tipo de movimentação',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'QUARENTENA',
                          child: Text('Quarentena'),
                        ),
                        DropdownMenuItem(
                          value: 'LIBERACAO',
                          child: Text('Liberação'),
                        ),
                        DropdownMenuItem(
                          value: 'INCINERACAO',
                          child: Text('Incineração'),
                        ),
                        DropdownMenuItem(value: 'RECALL', child: Text('Recall')),
                        DropdownMenuItem(
                          value: 'DEVOLUCAO_FORNECEDOR',
                          child: Text('Devolução ao fornecedor'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() => tipo = value);
                      },
                    ),
                    if (requiresQty) ...[
                      SizedBox(height: s.sm),
                      TextField(
                        controller: quantidadeController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Quantidade',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                    SizedBox(height: s.sm),
                    TextField(
                      controller: motivoController,
                      decoration: const InputDecoration(
                        labelText: 'Motivo',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                    ),
                    SizedBox(height: s.sm),
                    TextField(
                      controller: documentoController,
                      decoration: const InputDecoration(
                        labelText: 'Documento de referência (opcional)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(dialogContext, true),
                  child: const Text('Confirmar'),
                ),
              ],
            );
          },
        );
      },
    );

    final motivo = motivoController.text.trim();
    final documento = documentoController.text.trim();
    final quantidade =
        num.tryParse(quantidadeController.text.replaceAll(',', '.'));
    quantidadeController.dispose();
    motivoController.dispose();
    documentoController.dispose();

    if (confirmed != true || !context.mounted) return;
    if (motivo.length < 3) {
      PharmaFeedback.error(context, 'Motivo é obrigatório');
      return;
    }
    if (tipo != 'RECALL' && (quantidade == null || quantidade <= 0)) {
      PharmaFeedback.error(context, 'Quantidade inválida');
      return;
    }

    final controller = ref.read(estoqueListProvider.notifier);
    controller.setActionLoteId(item.id);
    try {
      await ref.read(estoqueRemoteDataSourceProvider).movimentacaoSanitaria(
            item.id,
            tipo: tipo,
            motivo: motivo,
            quantidade: tipo == 'RECALL' ? null : quantidade,
            documentoReferencia: documento.isEmpty ? null : documento,
          );
      if (!context.mounted) return;
      PharmaFeedback.success(context, 'Movimentação sanitária registada');
      await controller.refreshCurrentPage();
    } on ApiFailure catch (e) {
      if (context.mounted) PharmaFeedback.error(context, e.message);
    } catch (e) {
      if (context.mounted) PharmaFeedback.error(context, e.toString());
    } finally {
      controller.setActionLoteId(null);
    }
  }

  static Future<void> bloquearLote(
    BuildContext context,
    WidgetRef ref,
    EstoqueItem item,
  ) async {
    final controller = ref.read(estoqueListProvider.notifier);
    controller.setActionLoteId(item.id);
    try {
      await LotActionsHelper.moveToQuarentena(context, ref, item.toActionMap());
      await controller.refreshCurrentPage();
    } finally {
      controller.setActionLoteId(null);
    }
  }

  static Future<void> liberarLote(
    BuildContext context,
    WidgetRef ref,
    EstoqueItem item,
  ) async {
    final controller = ref.read(estoqueListProvider.notifier);
    controller.setActionLoteId(item.id);
    try {
      await LotActionsHelper.revertQuarentena(context, ref, item.toActionMap());
      await controller.refreshCurrentPage();
    } finally {
      controller.setActionLoteId(null);
    }
  }

  static void adicionarAoInventario(BuildContext context) {
    context.push(AppRoutePaths.stockInventory);
  }
}
