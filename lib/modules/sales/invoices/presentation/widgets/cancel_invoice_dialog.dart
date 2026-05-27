import 'package:flutter/material.dart';

import '../../../../../core/theme/design_tokens.dart';
import '../../../../../core/theme/spacing.dart';
import '../../domain/entities/invoice_summary.dart';

class CancelInvoiceDialog extends StatefulWidget {
  const CancelInvoiceDialog({super.key, required this.invoice});

  final InvoiceSummary invoice;

  @override
  State<CancelInvoiceDialog> createState() => _CancelInvoiceDialogState();
}

class _CancelInvoiceDialogState extends State<CancelInvoiceDialog> {
  late final TextEditingController _reasonController;
  late final TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    _reasonController = TextEditingController();
    _notesController = TextEditingController();
  }

  @override
  void dispose() {
    _reasonController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final s = context.spacing;

    final media = MediaQuery.of(context);
    final isMobile = media.size.width < 600;

    return Dialog(
      backgroundColor: t.bgPrimary,
      insetPadding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : 32,
        vertical: isMobile ? 24 : 40,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(t.radiusXl),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 460,
          maxHeight: media.size.height * 0.82,
        ),
        child: Padding(
          padding: EdgeInsets.only(
            left: s.lg,
            right: s.lg,
            top: s.lg,
            bottom: media.viewInsets.bottom + s.lg,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cancelar ${widget.invoice.numero}',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: t.textPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                ),
                SizedBox(height: s.md),
                Text(
                  'Esta ação deve refletir a reversão no backend. Informe o motivo do cancelamento.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: t.textMuted,
                      ),
                ),
                SizedBox(height: s.lg),
                TextField(
                  controller: _reasonController,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Motivo',
                    hintText: 'Ex.: erro no caixa',
                  ),
                ),
                SizedBox(height: s.md),
                TextField(
                  controller: _notesController,
                  minLines: 3,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    labelText: 'Observações',
                    hintText: 'Opcional',
                  ),
                ),
                SizedBox(height: s.xl),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Fechar'),
                      ),
                    ),
                    SizedBox(width: s.md),
                    Expanded(
                      flex: 2,
                      child: FilledButton(
                        onPressed: () {
                          Navigator.of(context).pop(
                            CancelInvoicePayload(
                              motivo: _reasonController.text.trim(),
                              observacoes: _notesController.text.trim().isEmpty
                                  ? null
                                  : _notesController.text.trim(),
                            ),
                          );
                        },
                        child: const Text('Confirmar cancelamento'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class CancelInvoicePayload {
  const CancelInvoicePayload({
    required this.motivo,
    this.observacoes,
  });

  final String motivo;
  final String? observacoes;
}
