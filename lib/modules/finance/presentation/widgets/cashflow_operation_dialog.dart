import 'package:flutter/material.dart';

import '../../../../../shared/navigation/adaptive_navigator.dart';
import '../../../../../shared/widgets/dialogs/pharma_responsive_dialog.dart';
import '../../../../../shared/widgets/layout/adaptive_side_sheet.dart';

class CashflowOperationResult {
  const CashflowOperationResult({required this.payload});

  final Map<String, dynamic> payload;
}

Future<CashflowOperationResult?> showCashflowOperationDialog(
  BuildContext context, {
  required String operationType,
}) {
  final title = Text('Fluxo de Caixa - $operationType');
  final width = AdaptiveNavigator.widthOf(context);
  final panelWidth = width >= AdaptiveSideSheetMetrics.desktopBreakpoint ? 520.0 : 480.0;

  return AdaptiveNavigator.openPanel<CashflowOperationResult>(
    context: context,
    sideSheetWidth: panelWidth,
    routeSettings: RouteSettings(name: '/finance/operation/${operationType.toLowerCase()}'),
    builder: (detailContext) {
      if (AdaptiveNavigator.isMobile(detailContext)) {
        return Scaffold(
          appBar: AppBar(title: title),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: _CashflowOperationDialog(
                operationType: operationType,
                embedded: true,
              ),
            ),
          ),
        );
      }
      return _CashflowOperationDialog(
        operationType: operationType,
        embedded: true,
        showHeader: true,
        onClose: () => AdaptiveNavigator.cancel(detailContext),
      );
    },
  );
}

class _CashflowOperationDialog extends StatefulWidget {
  const _CashflowOperationDialog({
    required this.operationType,
    this.embedded = false,
    this.showHeader = false,
    this.onClose,
  });

  final String operationType;
  final bool embedded;
  final bool showHeader;
  final VoidCallback? onClose;

  @override
  State<_CashflowOperationDialog> createState() => _CashflowOperationDialogState();
}

class _CashflowOperationDialogState extends State<_CashflowOperationDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _saldoController;
  late final TextEditingController _valorController;
  late final TextEditingController _destinoOrigemController;
  late final TextEditingController _descricaoController;

  @override
  void initState() {
    super.initState();
    _saldoController = TextEditingController();
    _valorController = TextEditingController();
    _destinoOrigemController = TextEditingController();
    _descricaoController = TextEditingController();
  }

  @override
  void dispose() {
    _saldoController.dispose();
    _valorController.dispose();
    _destinoOrigemController.dispose();
    _descricaoController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() != true) return;
    AdaptiveNavigator.complete(
      context,
      CashflowOperationResult(
        payload: <String, dynamic>{
          'operation': widget.operationType,
          'saldo': _saldoController.text.trim(),
          'valor': _valorController.text.trim(),
          'destinoOrigem': _destinoOrigemController.text.trim(),
          'descricao': _descricaoController.text.trim(),
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final form = Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Caixa Ativo',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _saldoController,
            decoration: const InputDecoration(
              labelText: 'Saldo',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _valorController,
            decoration: const InputDecoration(
              labelText: 'Valor',
              border: OutlineInputBorder(),
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            validator: (value) =>
                value == null || value.trim().isEmpty ? 'Valor obrigatório' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _destinoOrigemController,
            decoration: const InputDecoration(
              labelText: 'Destino ou Origem',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _descricaoController,
            decoration: const InputDecoration(
              labelText: 'Descrição',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
        ],
      ),
    );

    final actions = [
      OutlinedButton(
        onPressed: () => AdaptiveNavigator.cancel(context),
        child: const Text('Cancelar'),
      ),
      const SizedBox(width: 8),
      FilledButton(
        onPressed: _submit,
        child: const Text('Confirmar'),
      ),
    ];

    if (widget.embedded) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.showHeader) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Fluxo de Caixa - ${widget.operationType}',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  if (widget.onClose != null)
                    IconButton(
                      onPressed: widget.onClose,
                      icon: const Icon(Icons.close),
                    ),
                ],
              ),
            ),
            const Divider(height: 1),
          ],
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: form,
            ),
          ),
          if (widget.showHeader) const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: actions,
            ),
          ),
        ],
      );
    }

    return PharmaResponsiveDialog(
      title: Text('Fluxo de Caixa - ${widget.operationType}'),
      content: form,
      actions: actions,
    );
  }
}
