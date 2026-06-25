import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/design_metrics.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../shared/widgets/dialogs/pharma_responsive_dialog.dart';
import '../../domain/entities/fornecedor.dart';
import '../../domain/entities/requisicao.dart';
import '../providers/fornecedor_provider.dart';

class EditarRequisicaoDialogResult {
  const EditarRequisicaoDialogResult({
    required this.numeroDocumento,
    this.fornecedorId,
    this.origem,
    this.destino,
    this.observacao,
  });

  final String numeroDocumento;
  final String? fornecedorId;
  final String? origem;
  final String? destino;
  final String? observacao;

  AtualizarRequisicaoRequest toRequest() {
    return AtualizarRequisicaoRequest(
      numeroDocumento: numeroDocumento,
      fornecedorId: fornecedorId,
      origem: origem,
      destino: destino,
      observacao: observacao,
    );
  }
}

class EditarRequisicaoDialog extends ConsumerStatefulWidget {
  const EditarRequisicaoDialog({
    super.key,
    required this.requisicao,
  });

  final RequisicaoDetalhe requisicao;

  @override
  ConsumerState<EditarRequisicaoDialog> createState() =>
      _EditarRequisicaoDialogState();
}

class _EditarRequisicaoDialogState extends ConsumerState<EditarRequisicaoDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _numeroDocumentoController;
  late final TextEditingController _origemController;
  late final TextEditingController _destinoController;
  late final TextEditingController _observacaoController;
  final _fornecedorSearchController = TextEditingController();

  String? _selectedFornecedorId;
  String? _selectedFornecedorNome;
  FornecedorResumo? _selectedFornecedorDropdown;
  String _fornecedorSearch = '';

  @override
  void initState() {
    super.initState();
    final requisicao = widget.requisicao;
    _numeroDocumentoController =
        TextEditingController(text: requisicao.numeroDocumento);
    _origemController = TextEditingController(text: requisicao.origem ?? '');
    _destinoController = TextEditingController(text: requisicao.destino ?? '');
    _observacaoController =
        TextEditingController(text: requisicao.observacao ?? '');
    _selectedFornecedorId = requisicao.fornecedorId;
    _selectedFornecedorNome = requisicao.fornecedorNome;
  }

  @override
  void dispose() {
    _numeroDocumentoController.dispose();
    _origemController.dispose();
    _destinoController.dispose();
    _observacaoController.dispose();
    _fornecedorSearchController.dispose();
    super.dispose();
  }

  RequisicaoTipo get _tipo => widget.requisicao.tipo;

  bool get _canSubmit {
    if (_numeroDocumentoController.text.trim().isEmpty) {
      return false;
    }

    return switch (_tipo) {
      RequisicaoTipo.compra =>
        _selectedFornecedorId != null && _selectedFornecedorId!.isNotEmpty,
      RequisicaoTipo.entrada =>
        _origemController.text.trim().isNotEmpty &&
            (_selectedFornecedorDropdown != null ||
                (_selectedFornecedorId?.isNotEmpty ?? false)),
      RequisicaoTipo.saida =>
        _destinoController.text.trim().isNotEmpty &&
            (_selectedFornecedorDropdown != null ||
                (_selectedFornecedorId?.isNotEmpty ?? false)),
    };
  }

  void _submit() {
    if (_formKey.currentState?.validate() != true || !_canSubmit) {
      return;
    }

    final fornecedorId = switch (_tipo) {
      RequisicaoTipo.compra => _selectedFornecedorId,
      RequisicaoTipo.entrada || RequisicaoTipo.saida =>
        _selectedFornecedorDropdown?.id ?? _selectedFornecedorId,
    };

    Navigator.of(context).pop(
      EditarRequisicaoDialogResult(
        numeroDocumento: _numeroDocumentoController.text.trim(),
        fornecedorId: fornecedorId,
        origem: _tipo == RequisicaoTipo.entrada
            ? _origemController.text.trim()
            : null,
        destino: _tipo == RequisicaoTipo.saida
            ? _destinoController.text.trim()
            : null,
        observacao: _observacaoController.text.trim().isEmpty
            ? null
            : _observacaoController.text.trim(),
      ),
    );
  }

  Widget _buildCompraFields(List<FornecedorResumo> fornecedores) {
    final s = context.spacing;
    final filtered = fornecedores
        .where(
          (supplier) =>
              supplier.nome.toLowerCase().contains(_fornecedorSearch.toLowerCase()) ||
              supplier.id.toLowerCase().contains(_fornecedorSearch.toLowerCase()),
        )
        .toList();

    return Column(
      children: [
        TextFormField(
          controller: _numeroDocumentoController,
          decoration: const InputDecoration(
            labelText: 'Número do Documento *',
            prefixIcon: Icon(Icons.description_outlined),
            border: OutlineInputBorder(),
          ),
          onChanged: (_) => setState(() {}),
          validator: (value) {
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
        if (_selectedFornecedorNome != null)
          Align(
            alignment: Alignment.centerLeft,
            child: Chip(
              label: Text('Fornecedor: $_selectedFornecedorNome'),
            ),
          ),
        SizedBox(
          height: MediaQuery.sizeOf(context).height *
              DesignMetrics.dialogSelectableListHeightFraction,
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
                          ? const Icon(Icons.check_circle, color: Colors.green)
                          : null,
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildEntradaFields(List<FornecedorResumo> fornecedores) {
    final s = context.spacing;
    final selectedDropdown = _resolveSelectedFornecedor(fornecedores);

    return Column(
      children: [
        TextFormField(
          controller: _numeroDocumentoController,
          decoration: const InputDecoration(
            labelText: 'Número do Documento *',
            prefixIcon: Icon(Icons.description_outlined),
            border: OutlineInputBorder(),
          ),
          onChanged: (_) => setState(() {}),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Informe o número do documento';
            }
            return null;
          },
        ),
        SizedBox(height: s.md),
        TextFormField(
          controller: _origemController,
          decoration: const InputDecoration(
            labelText: 'Origem *',
            border: OutlineInputBorder(),
          ),
          onChanged: (_) => setState(() {}),
          validator: (value) {
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
          initialValue: selectedDropdown,
          items: fornecedores
              .map(
                (f) => DropdownMenuItem(
                  value: f,
                  child: Text(f.nome),
                ),
              )
              .toList(),
          onChanged: (value) => setState(() {
            _selectedFornecedorDropdown = value;
            _selectedFornecedorId = value?.id;
            _selectedFornecedorNome = value?.nome;
          }),
          validator: (value) =>
              value == null ? 'Seleccione um fornecedor' : null,
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

  Widget _buildSaidaFields(List<FornecedorResumo> fornecedores) {
    final s = context.spacing;
    final selectedDropdown = _resolveSelectedFornecedor(fornecedores);

    return Column(
      children: [
        TextFormField(
          controller: _numeroDocumentoController,
          decoration: const InputDecoration(
            labelText: 'Número do Documento *',
            prefixIcon: Icon(Icons.description_outlined),
            border: OutlineInputBorder(),
          ),
          onChanged: (_) => setState(() {}),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Informe o número do documento';
            }
            return null;
          },
        ),
        SizedBox(height: s.md),
        TextFormField(
          controller: _destinoController,
          decoration: const InputDecoration(
            labelText: 'Destino *',
            border: OutlineInputBorder(),
          ),
          onChanged: (_) => setState(() {}),
          validator: (value) {
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
          initialValue: selectedDropdown,
          items: fornecedores
              .map(
                (f) => DropdownMenuItem(
                  value: f,
                  child: Text(f.nome),
                ),
              )
              .toList(),
          onChanged: (value) => setState(() {
            _selectedFornecedorDropdown = value;
            _selectedFornecedorId = value?.id;
            _selectedFornecedorNome = value?.nome;
          }),
          validator: (value) =>
              value == null ? 'Seleccione um fornecedor' : null,
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

  FornecedorResumo? _resolveSelectedFornecedor(
    List<FornecedorResumo> fornecedores,
  ) {
    if (_selectedFornecedorDropdown != null) {
      return _selectedFornecedorDropdown;
    }
    if (_selectedFornecedorId == null) {
      return null;
    }
    for (final fornecedor in fornecedores) {
      if (fornecedor.id == _selectedFornecedorId) {
        return fornecedor;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final suppliersAsync = ref.watch(supplierListProvider);

    return PharmaResponsiveDialog(
      title: Text('Editar requisição (${widget.requisicao.tipo.label})'),
      content: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height *
              DesignMetrics.dialogBodyMaxHeightFraction,
        ),
        child: suppliersAsync.when(
          loading: () => const SizedBox(
            height: DesignMetrics.minTouchTarget * 5,
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (error, _) => SizedBox(
            height: DesignMetrics.minTouchTarget * 2.5,
            child: Center(child: Text(error.toString())),
          ),
          data: (fornecedores) => Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: switch (_tipo) {
                RequisicaoTipo.compra => _buildCompraFields(fornecedores),
                RequisicaoTipo.entrada => _buildEntradaFields(fornecedores),
                RequisicaoTipo.saida => _buildSaidaFields(fornecedores),
              },
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
          onPressed: _canSubmit ? _submit : null,
          icon: const Icon(Icons.save_outlined),
          label: const Text('Guardar'),
        ),
      ],
    );
  }
}
