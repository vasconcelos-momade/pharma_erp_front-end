import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/design_tokens.dart';
import '../../../../core/theme/extensions.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../shared/navigation/adaptive_navigator.dart';
import '../../../../shared/widgets/dialogs/pharma_responsive_dialog.dart';
import '../../../pharmacy/products/domain/entities/product.dart';
import '../../domain/entities/requisicao.dart';
import '../providers/requisicao_provider.dart';
import 'requisicao_hub_formatters.dart';

Future<RequisicaoCompraItemDraft?> showRequisicaoCompraItemDialog(
  BuildContext context, {
  Product? product,
  RequisicaoItem? item,
}) {
  final isEditing = item != null;
  return AdaptiveNavigator.openEmbeddedForm<RequisicaoCompraItemDraft>(
    context: context,
    title: Text(isEditing ? 'Editar Item' : 'Adicionar Item'),
    routeSettings: RouteSettings(
      name: isEditing
          ? '/requisicoes/compra/itens/${item.id}/editar'
          : '/requisicoes/compra/itens/novo',
    ),
    formBuilder: (ctx, {required embedded}) => RequisicaoCompraItemDialog(
      product: product,
      item: item,
      embedded: embedded,
    ),
  );
}

class RequisicaoCompraItemDialog extends StatefulWidget {
  const RequisicaoCompraItemDialog({
    super.key,
    this.product,
    this.item,
    this.embedded = false,
  }) : assert(product != null || item != null);

  final Product? product;
  final RequisicaoItem? item;
  final bool embedded;

  bool get isEditing => item != null;
  String get productName => item?.produtoNome ?? product!.nomeComercial;
  String get productId => item?.produtoId ?? product!.id;

  @override
  State<RequisicaoCompraItemDialog> createState() =>
      _RequisicaoCompraItemDialogState();
}

class _RequisicaoCompraItemDialogState
    extends State<RequisicaoCompraItemDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _loteController;
  late final TextEditingController _precoCompraController;
  late final TextEditingController _precoVendaController;
  late final TextEditingController _dataValidadeController;
  late final TextEditingController _quantidadeController;

  @override
  void initState() {
    super.initState();
    _loteController = TextEditingController(
      text: widget.item?.numeroLote ?? widget.product?.lote ?? '',
    );
    _precoCompraController = TextEditingController(
      text: widget.item?.precoCompra != null
          ? widget.item!.precoCompra!.toStringAsFixed(2)
          : '',
    );
    _precoVendaController = TextEditingController(
      text: widget.item?.precoVenda != null
          ? widget.item!.precoVenda!.toStringAsFixed(2)
          : '',
    );
    _dataValidadeController = TextEditingController(
      text: widget.item?.dataValidade != null
          ? requisicaoFormatDate(widget.item!.dataValidade!)
          : (widget.product?.dataValidade != null
                ? requisicaoFormatDate(widget.product!.dataValidade!)
                : requisicaoFormatDate(DateTime(2027, 12, 31))),
    );
    _quantidadeController = TextEditingController(
      text: widget.item != null
          ? requisicaoFormatQuantity(widget.item!.quantidade)
          : '1',
    );
  }

  @override
  void dispose() {
    _loteController.dispose();
    _precoCompraController.dispose();
    _precoVendaController.dispose();
    _dataValidadeController.dispose();
    _quantidadeController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() != true) {
      return;
    }
    AdaptiveNavigator.complete(
      context,
      RequisicaoCompraItemDraft(
        produtoId: widget.productId,
        produtoNome: widget.productName,
        numeroLote: _loteController.text.trim(),
        dataValidade: requisicaoFormatIsoDate(
          requisicaoParseDateInputValue(_dataValidadeController.text.trim())!,
        ),
        quantidade: _parseNumber(_quantidadeController.text),
        precoCompra: _parseNumber(_precoCompraController.text),
        precoVenda: _precoVendaController.text.trim().isEmpty
            ? null
            : _parseNumber(_precoVendaController.text),
      ),
    );
  }

  Future<void> _pickExpiryDate() async {
    final initialDate =
        requisicaoParseDateInputValue(_dataValidadeController.text.trim()) ??
        widget.product?.dataValidade ??
        DateTime.now().add(const Duration(days: 365));
    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate.isBefore(now) ? now : initialDate,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 20),
    );
    if (pickedDate == null) {
      return;
    }
    _dataValidadeController.text = requisicaoFormatDate(pickedDate);
  }

  @override
  Widget build(BuildContext context) {
    final s = context.spacing;

    final form = Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          RequisicaoItemDialogProductHeader(
            productName: widget.productName,
            description: widget.isEditing
                ? 'Atualize os dados do item selecionado mantendo o padrão visual e documental da requisição.'
                : 'Preencha os dados do lote e os preços para adicionar este produto à requisição.',
            metadata: [
              if (_loteController.text.trim().isNotEmpty)
                'Lote ${_loteController.text.trim()}',
              if (_dataValidadeController.text.trim().isNotEmpty)
                'Validade ${_dataValidadeController.text.trim()}',
            ],
          ),
          SizedBox(height: s.lg),
          RequisicaoItemDialogField(
            controller: _loteController,
            label: 'Lote',
            hint: 'Ex.: LOTE-2026-001',
            validator: _requiredValidator,
          ),
          SizedBox(height: s.md),
          RequisicaoItemDialogField(
            controller: _dataValidadeController,
            label: 'Data de validade',
            hint: 'DD/MM/AAAA',
            validator: _dateValidator,
            keyboardType: TextInputType.datetime,
            inputFormatters: [RequisicaoDateTextInputFormatter()],
            onEditingComplete: () {
              _dataValidadeController.text = requisicaoNormalizeDateInputValue(
                _dataValidadeController.text,
              );
            },
            suffixIcon: IconButton(
              onPressed: _pickExpiryDate,
              icon: const Icon(Icons.calendar_today_outlined),
              tooltip: 'Selecionar data',
            ),
          ),
          SizedBox(height: s.md),
          RequisicaoItemDialogField(
            controller: _precoCompraController,
            label: 'Preço de compra',
            hint: 'Ex.: 44.10',
            validator: _positiveNumberValidator,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          SizedBox(height: s.md),
          RequisicaoItemDialogField(
            controller: _precoVendaController,
            label: 'Preço de venda',
            hint: 'Opcional',
            validator: _optionalPositiveNumberValidator,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          SizedBox(height: s.md),
          RequisicaoItemDialogField(
            controller: _quantidadeController,
            label: 'Quantidade',
            hint: 'Ex.: 10',
            validator: _positiveNumberValidator,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
        ],
      ),
    );

    final actions = [
      TextButton(
        onPressed: () => AdaptiveNavigator.cancel(context),
        child: const Text('Cancelar'),
      ),
      FilledButton.icon(
        onPressed: _submit,
        icon: Icon(
          widget.isEditing ? Icons.save_outlined : Icons.add_task_rounded,
        ),
        label: Text(widget.isEditing ? 'Guardar alterações' : 'Adicionar item'),
      ),
    ];

    if (widget.embedded) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          form,
          const SizedBox(height: 16),
          Row(mainAxisAlignment: MainAxisAlignment.end, children: actions),
        ],
      );
    }

    return PharmaResponsiveDialog(
      title: Text(widget.isEditing ? 'Editar Item' : 'Adicionar Item'),
      content: form,
      actions: actions,
    );
  }

  String? _requiredValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Campo obrigatorio';
    }
    return null;
  }

  String? _dateValidator(String? value) {
    final normalized = value?.trim() ?? '';
    if (normalized.isEmpty) {
      return 'Campo obrigatorio';
    }
    if (requisicaoParseDateInputValue(normalized) == null) {
      return 'Use o formato DD/MM/AAAA';
    }
    return null;
  }

  String? _positiveNumberValidator(String? value) {
    final normalized = value?.trim().replaceAll(',', '.') ?? '';
    if (normalized.isEmpty) {
      return 'Campo obrigatorio';
    }
    final parsed = double.tryParse(normalized);
    if (parsed == null || parsed <= 0) {
      return 'Informe um numero maior que zero';
    }
    return null;
  }

  String? _optionalPositiveNumberValidator(String? value) {
    final normalized = value?.trim().replaceAll(',', '.') ?? '';
    if (normalized.isEmpty) {
      return null;
    }
    final parsed = double.tryParse(normalized);
    if (parsed == null || parsed < 0) {
      return 'Informe um numero valido';
    }
    return null;
  }

  double _parseNumber(String value) {
    return double.parse(value.trim().replaceAll(',', '.'));
  }
}

class RequisicaoItemDialogProductHeader extends StatelessWidget {
  const RequisicaoItemDialogProductHeader({
    super.key,
    required this.productName,
    required this.description,
    this.metadata = const [],
  });

  final String productName;
  final String description;
  final List<String> metadata;

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final s = context.spacing;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: EdgeInsets.all(s.md),
      decoration: BoxDecoration(
        color: t.bgPrimary.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(t.radiusMd),
        border: Border.all(color: t.border.withValues(alpha: 0.9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Produto',
            style: textTheme.erpOverline.copyWith(color: t.brandBlue),
          ),
          SizedBox(height: s.xs),
          Text(
            productName,
            style: textTheme.erpCardTitle.copyWith(
              color: t.textPrimary,
              height: 1.2,
            ),
          ),
          SizedBox(height: s.xs),
          Text(
            description,
            style: textTheme.erpBodySecondary.copyWith(color: t.textSecondary),
          ),
          if (metadata.isNotEmpty) ...[
            SizedBox(height: s.sm),
            Wrap(
              spacing: s.sm,
              runSpacing: s.sm,
              children: [
                for (final item in metadata)
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: s.sm,
                      vertical: s.xs,
                    ),
                    decoration: BoxDecoration(
                      color: t.card.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(t.radiusMd),
                      border: Border.all(
                        color: t.border.withValues(alpha: 0.7),
                      ),
                    ),
                    child: Text(
                      item,
                      style: textTheme.erpLabel.copyWith(color: t.textPrimary),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class RequisicaoItemDialogField extends StatelessWidget {
  const RequisicaoItemDialogField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    this.validator,
    this.keyboardType,
    this.inputFormatters,
    this.onEditingComplete,
    this.suffixIcon,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final VoidCallback? onEditingComplete;
  final Widget? suffixIcon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: TextFormField(
        controller: controller,
        validator: validator,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        onEditingComplete: onEditingComplete,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: const OutlineInputBorder(),
          suffixIcon: suffixIcon,
        ),
      ),
    );
  }
}
