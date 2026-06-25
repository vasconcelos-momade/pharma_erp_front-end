import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/design_metrics.dart';
import '../../../../../core/theme/spacing.dart';
import '../../../../../shared/widgets/dialogs/pharma_responsive_dialog.dart';
import '../../domain/entities/categoria_produto.dart';
import '../../domain/entities/product.dart';
import '../../domain/entities/product_tax_rule.dart';
import '../providers/product_provider.dart';

class ProdutoFormDialogResult {
  const ProdutoFormDialogResult({
    required this.nome,
    required this.categoria,
    required this.activo,
    this.barcode,
    this.substanciaActiva,
    this.dosagem,
    this.forma,
    this.apresentacao,
    this.estoqueMinimo,
    this.taxRuleId,
  });

  final String nome;
  final CategoriaProduto categoria;
  final bool activo;
  final String? barcode;
  final String? substanciaActiva;
  final String? dosagem;
  final String? forma;
  final String? apresentacao;
  final double? estoqueMinimo;
  final String? taxRuleId;

  Map<String, dynamic> toPayload() {
    return <String, dynamic>{
      'nome': nome,
      'categoria': categoria.apiValue,
      'ativo': activo,
      'activo': activo,
      'taxRuleId': taxRuleId,
      if (barcode != null && barcode!.isNotEmpty) 'barcode': barcode,
      if (substanciaActiva != null && substanciaActiva!.isNotEmpty)
        'substanciaActiva': substanciaActiva,
      if (dosagem != null && dosagem!.isNotEmpty) 'dosagem': dosagem,
      if (forma != null && forma!.isNotEmpty) 'forma': forma,
      if (apresentacao != null && apresentacao!.isNotEmpty)
        'apresentacao': apresentacao,
      if (estoqueMinimo != null) 'estoqueMinimo': estoqueMinimo,
    };
  }
}

class ProdutoFormDialog extends ConsumerStatefulWidget {
  const ProdutoFormDialog({super.key, this.product});

  final Product? product;

  bool get isEditing => product != null;

  @override
  ConsumerState<ProdutoFormDialog> createState() => _ProdutoFormDialogState();
}

class _ProdutoFormDialogState extends ConsumerState<ProdutoFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nomeController;
  late final TextEditingController _barcodeController;
  late final TextEditingController _substanciaController;
  late final TextEditingController _dosagemController;
  late final TextEditingController _formaController;
  late final TextEditingController _apresentacaoController;
  late final TextEditingController _estoqueMinimoController;
  late CategoriaProduto _categoria;
  late bool _activo;
  String? _selectedTaxRuleId;

  @override
  void initState() {
    super.initState();
    final product = widget.product;
    _nomeController = TextEditingController(text: product?.nome ?? '');
    _barcodeController = TextEditingController(text: product?.barcode ?? '');
    _substanciaController =
        TextEditingController(text: product?.substanciaActiva ?? '');
    _dosagemController = TextEditingController(text: product?.dosagem ?? '');
    _formaController = TextEditingController(text: product?.forma ?? '');
    _apresentacaoController =
        TextEditingController(text: product?.apresentacao ?? '');
    _estoqueMinimoController = TextEditingController(
      text: product != null ? product.estoqueMinimo.toString() : '',
    );
    _categoria = product?.categoria ?? CategoriaProduto.medicamento;
    _activo = product?.ativo ?? true;
    _selectedTaxRuleId = product?.taxRule?.id;
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _barcodeController.dispose();
    _substanciaController.dispose();
    _dosagemController.dispose();
    _formaController.dispose();
    _apresentacaoController.dispose();
    _estoqueMinimoController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final taxRules = ref.read(productTaxRulesProvider).maybeWhen(
          data: (value) => value,
          orElse: () => const <ProductTaxRule>[],
        );
    final resolvedTaxRuleId = _resolveSelectedTaxRuleId(taxRules);
    final estoqueText = _estoqueMinimoController.text.trim().replaceAll(',', '.');
    final estoqueMinimo =
        estoqueText.isEmpty ? null : double.tryParse(estoqueText);

    Navigator.of(context).pop(
      ProdutoFormDialogResult(
        nome: _nomeController.text.trim(),
        categoria: _categoria,
        activo: _activo,
        barcode: _barcodeController.text.trim(),
        substanciaActiva: _substanciaController.text.trim(),
        dosagem: _dosagemController.text.trim(),
        forma: _formaController.text.trim(),
        apresentacao: _apresentacaoController.text.trim(),
        estoqueMinimo: estoqueMinimo,
        taxRuleId: resolvedTaxRuleId,
      ),
    );
  }

  String? _resolveSelectedTaxRuleId(List<ProductTaxRule> rules) {
    if (_selectedTaxRuleId != null &&
        rules.any((rule) => rule.id == _selectedTaxRuleId)) {
      return _selectedTaxRuleId;
    }

    final currentRule = widget.product?.taxRule;
    if (currentRule == null) {
      return _selectedTaxRuleId;
    }

    for (final rule in rules) {
      if (rule.id == null) {
        continue;
      }
      final sameId = currentRule.id != null && currentRule.id == rule.id;
      final sameCode =
          currentRule.codigo != null &&
          currentRule.codigo == rule.codigo;
      final sameSignature =
          currentRule.tipo == rule.tipo &&
          (currentRule.taxa - rule.taxa).abs() < 0.0001;
      if (sameId || sameCode || sameSignature) {
        return rule.id;
      }
    }

    return _selectedTaxRuleId;
  }

  @override
  Widget build(BuildContext context) {
    final s = context.spacing;
    final taxRulesAsync = ref.watch(productTaxRulesProvider);
    final taxRules = taxRulesAsync.maybeWhen(
      data: (value) => value,
      orElse: () => const <ProductTaxRule>[],
    );
    final effectiveTaxRuleId = _resolveSelectedTaxRuleId(taxRules);

    return PharmaResponsiveDialog(
      title: Text(widget.isEditing ? 'Editar produto' : 'Novo produto'),
      content: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height *
              DesignMetrics.dialogBodyMaxHeightFraction,
        ),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _nomeController,
                  decoration: const InputDecoration(
                    labelText: 'Nome *',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Nome é obrigatório';
                    }
                    return null;
                  },
                ),
                SizedBox(height: s.md),
                DropdownButtonFormField<CategoriaProduto>(
                  initialValue: _categoria,
                  decoration: const InputDecoration(
                    labelText: 'Categoria',
                    border: OutlineInputBorder(),
                  ),
                  items: CategoriaProduto.values
                      .map(
                        (categoria) => DropdownMenuItem(
                          value: categoria,
                          child: Text(categoria.label),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _categoria = value);
                    }
                  },
                ),
                SizedBox(height: s.md),
                SwitchListTile.adaptive(
                  value: _activo,
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Activo'),
                  subtitle: const Text(
                    'Produtos inactivos deixam de aparecer no catálogo operacional.',
                  ),
                  onChanged: (value) {
                    setState(() => _activo = value);
                  },
                ),
                SizedBox(height: s.md),
                DropdownButtonFormField<String?>(
                  key: ValueKey(
                    'tax-rule-${effectiveTaxRuleId ?? 'none'}-${taxRules.length}-${taxRulesAsync.isLoading}',
                  ),
                  initialValue: effectiveTaxRuleId,
                  decoration: const InputDecoration(
                    labelText: 'Taxa de IVA',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('Sem regra fiscal'),
                    ),
                    ...taxRules
                        .where((rule) => rule.id != null && rule.ativo)
                        .map(
                          (rule) => DropdownMenuItem<String?>(
                            value: rule.id,
                            child: Text(rule.displayLabel),
                          ),
                        ),
                  ],
                  onChanged: taxRulesAsync.isLoading
                      ? null
                      : (value) {
                          setState(() => _selectedTaxRuleId = value);
                        },
                  hint: taxRulesAsync.isLoading
                      ? const Text('A carregar taxas de IVA...')
                      : const Text('Seleccione a taxa de IVA'),
                ),
                if (taxRulesAsync.hasError) ...[
                  SizedBox(height: s.xs),
                  Text(
                    'Não foi possível carregar as taxas de IVA.',
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                ],
                SizedBox(height: s.md),
                TextFormField(
                  controller: _barcodeController,
                  decoration: const InputDecoration(
                    labelText: 'Código de barras',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: s.md),
                TextFormField(
                  controller: _substanciaController,
                  decoration: const InputDecoration(
                    labelText: 'Substância activa',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: s.md),
                TextFormField(
                  controller: _dosagemController,
                  decoration: const InputDecoration(
                    labelText: 'Dosagem',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: s.md),
                TextFormField(
                  controller: _formaController,
                  decoration: const InputDecoration(
                    labelText: 'Forma',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: s.md),
                TextFormField(
                  controller: _apresentacaoController,
                  decoration: const InputDecoration(
                    labelText: 'Apresentação',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: s.md),
                TextFormField(
                  controller: _estoqueMinimoController,
                  decoration: const InputDecoration(
                    labelText: 'Estoque mínimo',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton.icon(
          onPressed: _submit,
          icon: const Icon(Icons.save_outlined),
          label: Text(widget.isEditing ? 'Guardar' : 'Criar'),
        ),
      ],
    );
  }
}

Future<ProdutoFormDialogResult?> showProdutoFormDialog(
  BuildContext context, {
  Product? product,
}) {
  return showPharmaResponsiveDialog<ProdutoFormDialogResult>(
    context: context,
    builder: (context) => ProdutoFormDialog(product: product),
  );
}
