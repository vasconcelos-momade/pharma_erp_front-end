import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/errors/api_failure.dart';
import '../../../../../core/utils/lote_stock_utils.dart';
import '../../../../../shared/widgets/layout/adaptive_side_sheet.dart';
import '../../../../../shared/navigation/adaptive_navigator.dart';
import '../../../../../shared/widgets/feedback/pharma_feedback.dart';
import '../models/lote_quarentena_form_data.dart';
import '../pages/lote_quarentena_page.dart';
import '../pages/lote_sanitario_history_page.dart';
import '../providers/lots_provider.dart';
import '../widgets/lote_quarentena_form_content.dart';
import '../widgets/lote_sanitario_history_content.dart';

abstract final class LotActionsHelper {
  LotActionsHelper._();

  static num _num(dynamic value) {
    if (value is num) return value;
    return num.tryParse(value?.toString() ?? '') ?? 0;
  }

  static bool canMoveToQuarentena(Map<String, dynamic> lote) {
    if (lote['estadoSanitario']?.toString() == 'RECALL') return false;
    return LoteStockUtils.readDisponivel(lote) > 0;
  }

  static bool canRevertQuarentena(Map<String, dynamic> lote) {
    final estado = lote['estadoSanitario']?.toString();
    if (estado == 'RECALL' || estado == 'EXPIRADO') return false;
    return _num(lote['quantidadeQuarentena']) > 0;
  }

  static Future<void> showHistory(
    BuildContext context,
    WidgetRef ref,
    String loteId, {
    String? numeroLote,
  }) async {
    final width = AdaptiveNavigator.widthOf(context);
    final panelWidth = width >= AdaptiveSideSheetMetrics.desktopBreakpoint
        ? 720.0
        : 520.0;

    await AdaptiveNavigator.openPanel<void>(
      context: context,
      sideSheetWidth: panelWidth,
      routeSettings: RouteSettings(name: '/lotes/$loteId/historico'),
      builder: (detailContext) {
        if (AdaptiveNavigator.isMobile(detailContext)) {
          return LoteSanitarioHistoryPage(
            loteId: loteId,
            numeroLote: numeroLote,
          );
        }
        return LoteSanitarioHistoryContent(
          loteId: loteId,
          numeroLote: numeroLote,
          onClose: () => AdaptiveNavigator.close(detailContext),
        );
      },
    );
  }

  static Future<void> moveToQuarentena(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> lote,
  ) async {
    await _submitQuarentena(
      context: context,
      ref: ref,
      lote: lote,
      isRevert: false,
    );
  }

  static Future<void> revertQuarentena(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> lote,
  ) async {
    await _submitQuarentena(
      context: context,
      ref: ref,
      lote: lote,
      isRevert: true,
    );
  }

  static Future<LoteQuarentenaFormData?> _openQuarentenaForm(
    BuildContext context, {
    required Map<String, dynamic> lote,
    required bool isRevert,
  }) {
    final loteId = lote['id']?.toString() ?? '';
    final maxQty = isRevert
        ? _num(lote['quantidadeQuarentena'])
        : LoteStockUtils.readDisponivel(lote);
    final title = Text(
      isRevert ? 'Reverter quarentena' : 'Mover para quarentena',
    );

    return AdaptiveNavigator.openForm<LoteQuarentenaFormData>(
      context: context,
      title: title,
      routeSettings: RouteSettings(
        name: isRevert
            ? '/lotes/$loteId/liberar-quarentena'
            : '/lotes/$loteId/quarentena',
      ),
      contentBuilder: (formContext) {
        if (AdaptiveNavigator.isMobile(formContext)) {
          return LoteQuarentenaPage(lote: lote, isRevert: isRevert);
        }
        return LoteQuarentenaFormContent(
          lote: lote,
          maxQuantidade: maxQty,
          isRevert: isRevert,
          onSubmit: (data) => AdaptiveNavigator.complete(formContext, data),
          onCancel: () => AdaptiveNavigator.cancel(formContext),
        );
      },
    );
  }

  static Future<void> _submitQuarentena({
    required BuildContext context,
    required WidgetRef ref,
    required Map<String, dynamic> lote,
    required bool isRevert,
  }) async {
    final loteId = lote['id']?.toString() ?? '';
    if (loteId.isEmpty) return;

    final formData = await _openQuarentenaForm(
      context,
      lote: lote,
      isRevert: isRevert,
    );
    if (formData == null || !context.mounted) return;

    final confirmed = await PharmaFeedback.confirm(
      context: context,
      title: isRevert ? 'Confirmar liberação' : 'Confirmar quarentena',
      message: isRevert
          ? 'A quantidade seleccionada voltará a ficar disponível para operações de stock.'
          : 'O stock seleccionado ficará indisponível para FEFO, vendas e reservas até ser libertado.',
      confirmText: isRevert ? 'Reverter quarentena' : 'Mover para quarentena',
      destructive: !isRevert,
    );
    if (!confirmed || !context.mounted) return;

    try {
      await PharmaFeedback.loading(
        context: context,
        title: isRevert ? 'A libertar quarentena' : 'A processar quarentena',
      );
      if (isRevert) {
        await ref
            .read(lotsViewProvider.notifier)
            .revertQuarentena(
              loteId: loteId,
              quantidade: formData.quantidade,
              motivo: formData.motivo,
              documentoReferencia: formData.documentoReferencia,
            );
      } else {
        await ref
            .read(lotsViewProvider.notifier)
            .moveToQuarentena(
              loteId: loteId,
              quantidade: formData.quantidade,
              motivo: formData.motivo,
              documentoReferencia: formData.documentoReferencia,
            );
      }
      if (!context.mounted) return;
      PharmaFeedback.dismiss(context);
      PharmaFeedback.success(
        context,
        isRevert
            ? 'Quarentena revertida com sucesso'
            : 'Lote movido para quarentena',
      );
    } on ApiFailure catch (e) {
      if (!context.mounted) return;
      PharmaFeedback.dismiss(context);
      PharmaFeedback.error(context, e.message);
    } catch (e) {
      if (!context.mounted) return;
      PharmaFeedback.dismiss(context);
      PharmaFeedback.error(context, e.toString());
    }
  }
}
