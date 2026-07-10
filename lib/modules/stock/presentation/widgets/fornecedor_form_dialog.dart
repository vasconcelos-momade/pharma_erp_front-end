import 'package:flutter/material.dart';

import '../../../../../shared/navigation/adaptive_navigator.dart';
import '../../../../../shared/widgets/dialogs/pharma_responsive_dialog.dart';
import '../../domain/entities/fornecedor.dart';

class FornecedorFormResult {
  const FornecedorFormResult({required this.payload});

  final Map<String, dynamic> payload;
}

Future<FornecedorFormResult?> showFornecedorFormDialog(
  BuildContext context, {
  FornecedorDetalhe? fornecedor,
}) {
  return AdaptiveNavigator.openEmbeddedForm<FornecedorFormResult>(
    context: context,
    title: Text(fornecedor == null ? 'Novo fornecedor' : 'Editar fornecedor'),
    routeSettings: RouteSettings(
      name: fornecedor == null ? '/fornecedores/novo' : '/fornecedores/${fornecedor.id}',
    ),
    formBuilder: (ctx, {required embedded}) =>
        _FornecedorFormDialog(fornecedor: fornecedor, embedded: embedded),
  );
}

class _FornecedorFormDialog extends StatefulWidget {
  const _FornecedorFormDialog({this.fornecedor, this.embedded = false});

  final FornecedorDetalhe? fornecedor;
  final bool embedded;

  @override
  State<_FornecedorFormDialog> createState() => _FornecedorFormDialogState();
}

class _FornecedorFormDialogState extends State<_FornecedorFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nome;
  late final TextEditingController _nuit;
  late final TextEditingController _email;
  late final TextEditingController _telefone;
  late final TextEditingController _cidade;
  late final TextEditingController _contato;

  @override
  void initState() {
    super.initState();
    final f = widget.fornecedor;
    _nome = TextEditingController(text: f?.nome ?? '');
    _nuit = TextEditingController(text: f?.nuit ?? '');
    _email = TextEditingController(text: f?.email ?? '');
    _telefone = TextEditingController(text: f?.telefone ?? '');
    _cidade = TextEditingController(text: f?.cidade ?? '');
    _contato = TextEditingController(text: f?.contatoNome ?? '');
  }

  @override
  void dispose() {
    _nome.dispose();
    _nuit.dispose();
    _email.dispose();
    _telefone.dispose();
    _cidade.dispose();
    _contato.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() != true) return;
    AdaptiveNavigator.complete(
      context,
      FornecedorFormResult(
        payload: <String, dynamic>{
          'nome': _nome.text.trim(),
          if (_nuit.text.trim().isNotEmpty) 'nuit': _nuit.text.trim(),
          if (_email.text.trim().isNotEmpty) 'email': _email.text.trim(),
          if (_telefone.text.trim().isNotEmpty) 'telefone': _telefone.text.trim(),
          if (_cidade.text.trim().isNotEmpty) 'cidade': _cidade.text.trim(),
          if (_contato.text.trim().isNotEmpty) 'contatoNome': _contato.text.trim(),
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
        children: [
          TextFormField(
            controller: _nome,
            decoration: const InputDecoration(
              labelText: 'Nome',
              border: OutlineInputBorder(),
            ),
            validator: (value) =>
                value == null || value.trim().length < 2 ? 'Nome obrigatório' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _nuit,
            decoration: const InputDecoration(
              labelText: 'NUIT',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _email,
            decoration: const InputDecoration(
              labelText: 'Email',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _telefone,
            decoration: const InputDecoration(
              labelText: 'Telefone',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _cidade,
            decoration: const InputDecoration(
              labelText: 'Cidade',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _contato,
            decoration: const InputDecoration(
              labelText: 'Contacto',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
    );

    final actions = [
      TextButton(
        onPressed: () => AdaptiveNavigator.cancel(context),
        child: const Text('Cancelar'),
      ),
      FilledButton(
        onPressed: _submit,
        child: Text(widget.fornecedor == null ? 'Criar' : 'Guardar'),
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
      title: Text(widget.fornecedor == null ? 'Novo fornecedor' : 'Editar fornecedor'),
      content: form,
      actions: actions,
    );
  }
}
