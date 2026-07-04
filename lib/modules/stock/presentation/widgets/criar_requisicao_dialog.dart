import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/design_metrics.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../shared/navigation/adaptive_navigator.dart';
import '../../../../shared/widgets/dialogs/pharma_responsive_dialog.dart';
import '../../domain/entities/fornecedor.dart';
import '../providers/fornecedor_provider.dart';

enum CriarRequisicaoModalTipo { compra, entrada, saida }

Future<CriarRequisicaoDialogResult?> showCriarRequisicaoDialog(
  BuildContext context, {
  CriarRequisicaoModalTipo initialTipo = CriarRequisicaoModalTipo.compra,
}) {
  return AdaptiveNavigator.openEmbeddedForm<CriarRequisicaoDialogResult>(
    context: context,
    title: const Text('Criar Requisição'),
    routeSettings: const RouteSettings(name: '/requisicoes/nova'),
    formBuilder: (ctx, {required embedded}) =>
        CriarRequisicaoDialog(initialTipo: initialTipo, embedded: embedded),
  );
}

class CriarRequisicaoDialogResult {
  const CriarRequisicaoDialogResult({
    required this.tipo,
    this.fornecedorId,
    this.fornecedorNome,
    this.numeroDocumento,
    this.origem,
    this.destino,
    this.observacao,
  });

  final CriarRequisicaoModalTipo tipo;
  final String? fornecedorId;
  final String? fornecedorNome;
  final String? numeroDocumento;
  final String? origem;
  final String? destino;
  final String? observacao;
}

class CriarRequisicaoDialog extends ConsumerStatefulWidget {
  const CriarRequisicaoDialog({
    super.key,
    this.initialTipo = CriarRequisicaoModalTipo.compra,
    this.embedded = false,
  });

  final CriarRequisicaoModalTipo initialTipo;
  final bool embedded;

  @override
  ConsumerState<CriarRequisicaoDialog> createState() =>
      _CriarRequisicaoDialogState();
}

class _CriarRequisicaoDialogState extends ConsumerState<CriarRequisicaoDialog>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _numeroDocumentoController = TextEditingController();
  final _origemController = TextEditingController();
  final _destinoController = TextEditingController();
  final _observacaoController = TextEditingController();
  final _fornecedorSearchController = TextEditingController();

  late TabController _tabController;
  String? _selectedFornecedorId;
  String? _selectedFornecedorNome;
  FornecedorResumo? _selectedFornecedorDropdown;
  String _fornecedorSearch = '';

  @override
  void initState() {
    super.initState();
    final initialIndex = switch (widget.initialTipo) {
      CriarRequisicaoModalTipo.compra => 0,
      CriarRequisicaoModalTipo.entrada => 1,
      CriarRequisicaoModalTipo.saida => 2,
    };
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: initialIndex,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _numeroDocumentoController.dispose();
    _origemController.dispose();
    _destinoController.dispose();
    _observacaoController.dispose();
    _fornecedorSearchController.dispose();
    super.dispose();
  }

  CriarRequisicaoModalTipo get _activeTipo => switch (_tabController.index) {
    0 => CriarRequisicaoModalTipo.compra,
    1 => CriarRequisicaoModalTipo.entrada,
    2 => CriarRequisicaoModalTipo.saida,
    _ => CriarRequisicaoModalTipo.compra,
  };

  bool get _canSubmit {
    switch (_activeTipo) {
      case CriarRequisicaoModalTipo.compra:
        return _selectedFornecedorId != null &&
            _numeroDocumentoController.text.trim().isNotEmpty;
      case CriarRequisicaoModalTipo.entrada:
        return _origemController.text.trim().isNotEmpty &&
            _selectedFornecedorDropdown != null;
      case CriarRequisicaoModalTipo.saida:
        return _destinoController.text.trim().isNotEmpty &&
            _selectedFornecedorDropdown != null;
    }
  }

  void _submit() {
    if (_formKey.currentState?.validate() != true || !_canSubmit) {
      return;
    }

    switch (_activeTipo) {
      case CriarRequisicaoModalTipo.compra:
        AdaptiveNavigator.complete(
          context,
          CriarRequisicaoDialogResult(
            tipo: CriarRequisicaoModalTipo.compra,
            fornecedorId: _selectedFornecedorId,
            fornecedorNome: _selectedFornecedorNome,
            numeroDocumento: _numeroDocumentoController.text.trim(),
          ),
        );
      case CriarRequisicaoModalTipo.entrada:
        AdaptiveNavigator.complete(
          context,
          CriarRequisicaoDialogResult(
            tipo: CriarRequisicaoModalTipo.entrada,
            fornecedorId: _selectedFornecedorDropdown?.id,
            fornecedorNome: _selectedFornecedorDropdown?.nome,
            origem: _origemController.text.trim(),
            observacao: _observacaoController.text.trim().isEmpty
                ? null
                : _observacaoController.text.trim(),
          ),
        );
      case CriarRequisicaoModalTipo.saida:
        AdaptiveNavigator.complete(
          context,
          CriarRequisicaoDialogResult(
            tipo: CriarRequisicaoModalTipo.saida,
            fornecedorId: _selectedFornecedorDropdown?.id,
            fornecedorNome: _selectedFornecedorDropdown?.nome,
            destino: _destinoController.text.trim(),
            observacao: _observacaoController.text.trim().isEmpty
                ? null
                : _observacaoController.text.trim(),
          ),
        );
    }
  }

  Widget _buildCompraTab(List<FornecedorResumo> fornecedores) {
    final s = context.spacing;
    final filtered = fornecedores
        .where(
          (supplier) =>
              supplier.nome.toLowerCase().contains(
                _fornecedorSearch.toLowerCase(),
              ) ||
              supplier.id.toLowerCase().contains(
                _fornecedorSearch.toLowerCase(),
              ),
        )
        .toList();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: _numeroDocumentoController,
          decoration: const InputDecoration(
            labelText: 'Número do Documento *',
            hintText: 'Ex.: FT-2026/00123',
            prefixIcon: Icon(Icons.description_outlined),
            border: OutlineInputBorder(),
          ),
          onChanged: (_) => setState(() {}),
          validator: (value) {
            if (_activeTipo != CriarRequisicaoModalTipo.compra) {
              return null;
            }
            if (value == null || value.trim().isEmpty) {
              return 'Informe o número do documento';
            }
            return null;
          },
        ),
        SizedBox(height: s.md),
        TextField(
          controller: _fornecedorSearchController,
          decoration: const InputDecoration(
            labelText: 'Pesquisar fornecedor',
            prefixIcon: Icon(Icons.search),
            border: OutlineInputBorder(),
          ),
          onChanged: (value) => setState(() => _fornecedorSearch = value),
        ),
        SizedBox(height: s.md),
        ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight:
                MediaQuery.sizeOf(context).height *
                DesignMetrics.dialogSelectableListHeightFraction,
          ),
          child: filtered.isEmpty
              ? const Center(child: Text('Nenhum fornecedor encontrado'))
              : ListView.separated(
                  itemCount: filtered.length,
                  separatorBuilder: (_, _) => const Divider(),
                  itemBuilder: (context, index) {
                    final supplier = filtered[index];
                    final isSelected = _selectedFornecedorId == supplier.id;
                    return ListTile(
                      selected: isSelected,
                      title: Text(supplier.nome),
                      subtitle: Text('ID: ${supplier.id}'),
                      onTap: () => setState(() {
                        _selectedFornecedorId = supplier.id;
                        _selectedFornecedorNome = supplier.nome;
                      }),
                      trailing: isSelected
                          ? Icon(
                              Icons.check_circle,
                              color: context.pharmaTokens.brandGreen,
                            )
                          : null,
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildEntradaTab(List<FornecedorResumo> fornecedores) {
    final s = context.spacing;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: _origemController,
          decoration: const InputDecoration(
            labelText: 'Origem *',
            border: OutlineInputBorder(),
          ),
          onChanged: (_) => setState(() {}),
          validator: (value) {
            if (_activeTipo != CriarRequisicaoModalTipo.entrada) {
              return null;
            }
            if (value == null || value.trim().isEmpty) {
              return 'Informe a origem';
            }
            return null;
          },
        ),
        SizedBox(height: s.md),
        DropdownButtonFormField<FornecedorResumo>(
          decoration: const InputDecoration(
            labelText: 'Fornecedor *',
            border: OutlineInputBorder(),
          ),
          initialValue: _selectedFornecedorDropdown,
          items: fornecedores
              .map((f) => DropdownMenuItem(value: f, child: Text(f.nome)))
              .toList(),
          onChanged: (value) =>
              setState(() => _selectedFornecedorDropdown = value),
          validator: (value) {
            if (_activeTipo != CriarRequisicaoModalTipo.entrada) {
              return null;
            }
            return value == null ? 'Seleccione um fornecedor' : null;
          },
        ),
        SizedBox(height: s.md),
        TextFormField(
          controller: _observacaoController,
          decoration: const InputDecoration(
            labelText: 'Observação',
            border: OutlineInputBorder(),
          ),
          minLines: 2,
          maxLines: 4,
        ),
      ],
    );
  }

  Widget _buildSaidaTab(List<FornecedorResumo> fornecedores) {
    final s = context.spacing;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: _destinoController,
          decoration: const InputDecoration(
            labelText: 'Destino *',
            border: OutlineInputBorder(),
          ),
          onChanged: (_) => setState(() {}),
          validator: (value) {
            if (_activeTipo != CriarRequisicaoModalTipo.saida) {
              return null;
            }
            if (value == null || value.trim().isEmpty) {
              return 'Informe o destino';
            }
            return null;
          },
        ),
        SizedBox(height: s.md),
        DropdownButtonFormField<FornecedorResumo>(
          decoration: const InputDecoration(
            labelText: 'Fornecedor *',
            border: OutlineInputBorder(),
          ),
          initialValue: _selectedFornecedorDropdown,
          items: fornecedores
              .map((f) => DropdownMenuItem(value: f, child: Text(f.nome)))
              .toList(),
          onChanged: (value) =>
              setState(() => _selectedFornecedorDropdown = value),
          validator: (value) {
            if (_activeTipo != CriarRequisicaoModalTipo.saida) {
              return null;
            }
            return value == null ? 'Seleccione um fornecedor' : null;
          },
        ),
        SizedBox(height: s.md),
        TextFormField(
          controller: _observacaoController,
          decoration: const InputDecoration(
            labelText: 'Observação',
            border: OutlineInputBorder(),
          ),
          minLines: 2,
          maxLines: 4,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final s = context.spacing;
    final suppliersAsync = ref.watch(supplierListProvider);

    final tabBar = Material(
      color: t.card,
      borderRadius: BorderRadius.circular(t.radiusMd),
      child: TabBar(
        controller: _tabController,
        onTap: (_) => setState(() {}),
        labelColor: t.textPrimary,
        unselectedLabelColor: t.textMuted,
        indicatorColor: t.brandBlue,
        dividerColor: t.card,
        labelPadding: EdgeInsets.symmetric(horizontal: s.sm),
        tabs: [
          Tab(height: t.minTouchTarget, text: 'Compra'),
          Tab(height: t.minTouchTarget, text: 'Entrada'),
          Tab(height: t.minTouchTarget, text: 'Saída'),
        ],
      ),
    );

    Widget tabContent(List<FornecedorResumo> fornecedores) {
      return SingleChildScrollView(
        child: switch (_activeTipo) {
          CriarRequisicaoModalTipo.compra => _buildCompraTab(fornecedores),
          CriarRequisicaoModalTipo.entrada => _buildEntradaTab(fornecedores),
          CriarRequisicaoModalTipo.saida => _buildSaidaTab(fornecedores),
        },
      );
    }

    final suppliersSection = suppliersAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('Erro: $err')),
      data: tabContent,
    );

    final actions = [
      TextButton(
        onPressed: () => AdaptiveNavigator.cancel(context),
        child: const Text('Cancelar'),
      ),
      FilledButton.icon(
        onPressed: _canSubmit ? _submit : null,
        icon: const Icon(Icons.check_rounded),
        label: const Text('Iniciar requisição'),
      ),
    ];

    if (widget.embedded) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                tabBar,
                SizedBox(height: s.md),
                suppliersSection,
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(mainAxisAlignment: MainAxisAlignment.end, children: actions),
        ],
      );
    }

    return PharmaResponsiveDialog(
      title: const Text('Criar Requisição'),
      scrollable: false,
      content: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight:
              MediaQuery.sizeOf(context).height *
              DesignMetrics.dialogBodyMaxHeightFraction,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              tabBar,
              SizedBox(height: s.md),
              Expanded(child: suppliersSection),
            ],
          ),
        ),
      ),
      actions: actions,
    );
  }
}
