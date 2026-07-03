import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/design_metrics.dart';
import '../../../../../core/theme/extensions.dart';
import '../../../../../shared/navigation/adaptive_navigator.dart';
import '../../../../../shared/widgets/dialogs/pharma_responsive_dialog.dart';
import '../../../categories/presentation/providers/category_provider.dart';
import '../../domain/entities/product.dart';
import '../../domain/entities/product_tax_rule.dart';
import '../providers/product_provider.dart';

class ProdutoFormDialogResult {
  const ProdutoFormDialogResult({
    required this.nome,
    required this.categoriaId,
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
  final String categoriaId;
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
      'categoriaId': categoriaId,
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
  const ProdutoFormDialog({
    super.key,
    this.product,
    this.embedded = false,
    this.pinnedFooter = false,
  });

  final Product? product;
  final bool embedded;
  final bool pinnedFooter;

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
  String? _categoriaId;
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
    _categoriaId = product?.categoriaId;
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

    if (_categoriaId == null || _categoriaId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seleccione uma categoria')),
      );
      return;
    }

    AdaptiveNavigator.complete(
      context,
      ProdutoFormDialogResult(
        nome: _nomeController.text.trim(),
        categoriaId: _categoriaId!,
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
    final categoriesAsync = ref.watch(activeCategoriesProvider);
    final taxRules = taxRulesAsync.maybeWhen(
      data: (value) => value,
      orElse: () => const <ProductTaxRule>[],
    );
    final effectiveTaxRuleId = _resolveSelectedTaxRuleId(taxRules);

    final formFields = Column(
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
        categoriesAsync.when(
          data: (categories) {
            final resolvedId = _categoriaId != null &&
                    categories.any((c) => c.id == _categoriaId)
                ? _categoriaId
                : (categories.isNotEmpty ? categories.first.id : null);
            if (_categoriaId == null && resolvedId != null) {
              _categoriaId = resolvedId;
            }
            return DropdownButtonFormField<String>(
              key: ValueKey('form-categoria-$resolvedId'),
              initialValue: resolvedId,
              decoration: const InputDecoration(
                labelText: 'Categoria *',
                border: OutlineInputBorder(),
              ),
              items: categories
                  .map(
                    (c) => DropdownMenuItem(
                      value: c.id,
                      child: Text(c.nome),
                    ),
                  )
                  .toList(growable: false),
              onChanged: categories.isEmpty
                  ? null
                  : (value) => setState(() => _categoriaId = value),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Categoria é obrigatória';
                }
                return null;
              },
            );
          },
          loading: () => const InputDecorator(
            decoration: InputDecoration(
              labelText: 'Categoria *',
              border: OutlineInputBorder(),
            ),
            child: LinearProgressIndicator(),
          ),
          error: (_, _) => const InputDecorator(
            decoration: InputDecoration(
              labelText: 'Categoria *',
              border: OutlineInputBorder(),
            ),
            child: Text('Não foi possível carregar categorias'),
          ),
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
            style: Theme.of(context).textTheme.erpBody.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
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
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
      ],
    );

    final actions = [
      TextButton(
        onPressed: () => AdaptiveNavigator.cancel(context),
        child: const Text('Cancelar'),
      ),
      FilledButton.icon(
        onPressed: _submit,
        icon: const Icon(Icons.save_outlined),
        label: Text(widget.isEditing ? 'Guardar' : 'Criar'),
      ),
    ];

    final formBody = Form(
      key: _formKey,
      child: widget.pinnedFooter
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: formFields,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: actions,
                ),
              ],
            )
          : ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: widget.embedded
                    ? double.infinity
                    : MediaQuery.sizeOf(context).height *
                        DesignMetrics.dialogBodyMaxHeightFraction,
              ),
              child: SingleChildScrollView(
                child: formFields,
              ),
            ),
    );

    if (widget.embedded) {
      if (widget.pinnedFooter) {
        return formBody;
      }
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          formBody,
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: actions,
          ),
        ],
      );
    }

    return PharmaResponsiveDialog(
      title: Text(widget.isEditing ? 'Editar produto' : 'Novo produto'),
      content: formBody,
      actions: actions,
    );
  }
}

Future<ProdutoFormDialogResult?> showProdutoFormDialog(
  BuildContext context, {
  Product? product,
}) {
  final titleText = product != null ? 'Editar produto' : 'Novo produto';
  final title = Text(titleText);
  return AdaptiveNavigator.open<ProdutoFormDialogResult>(
    context: context,
    sideSheetWidth: AdaptiveNavigator.isDesktop(context) ? 640 : 520,
    routeSettings: RouteSettings(
      name: product == null ? '/produtos/novo' : '/produtos/${product.id}/editar',
    ),
    builder: (formContext) {
      if (AdaptiveNavigator.isMobile(formContext)) {
        return Scaffold(
          appBar: AppBar(title: title),
          body: SingleChildScrollView(
            padding: EdgeInsets.all(formContext.spacing.lg),
            child: ProdutoFormDialog(product: product, embedded: true),
          ),
        );
      }

      return _ProdutoFormSideSheet(
        title: titleText,
        child: ProdutoFormDialog(
          product: product,
          embedded: true,
          pinnedFooter: true,
        ),
      );
    },
  );
}

class _ProdutoFormSideSheet extends StatelessWidget {
  const _ProdutoFormSideSheet({
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final s = context.spacing;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(s.lg, s.lg, s.sm, s.sm),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.erpCardTitle,
                ),
              ),
              IconButton(
                tooltip: 'Fechar',
                onPressed: () => AdaptiveNavigator.close(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: Padding(
            padding: EdgeInsets.all(s.lg),
            child: child,
          ),
        ),
      ],
    );
  }
}
