import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/extensions.dart';
import '../../../../../core/theme/pharma_surface.dart';
import '../../../../../shared/navigation/adaptive_navigator.dart';
import '../../../../../shared/widgets/dialogs/pharma_responsive_dialog.dart';
import '../../../customers/data/repositories/customer_repository_impl.dart';
import '../../../customers/domain/entities/customer.dart';

class SaveQuotationDialogResult {
  const SaveQuotationDialogResult({
    required this.clienteId,
    required this.validade,
    this.observacoes,
  });

  final String clienteId;
  final DateTime validade;
  final String? observacoes;
}

class SaveQuotationDialog extends ConsumerStatefulWidget {
  const SaveQuotationDialog({super.key});

  @override
  ConsumerState<SaveQuotationDialog> createState() =>
      _SaveQuotationDialogState();
}

class _SaveQuotationDialogState extends ConsumerState<SaveQuotationDialog> {
  final _observacoesController = TextEditingController();
  String? _clienteId;
  late DateTime _validade;
  bool _loadingCustomers = true;
  List<CustomerSummary> _customers = const [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _validade = DateTime.now().add(const Duration(days: 30));
    Future.microtask(_loadCustomers);
  }

  @override
  void dispose() {
    _observacoesController.dispose();
    super.dispose();
  }

  Future<void> _loadCustomers() async {
    try {
      final response = await ref.read(customerRepositoryProvider).listCustomers(
            const CustomerQuery(page: 1, pageSize: 100),
          );
      if (!mounted) {
        return;
      }
      setState(() {
        _customers = response.items;
        _clienteId = response.items.isNotEmpty ? response.items.first.id : null;
        _loadingCustomers = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loadingCustomers = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _pickValidade() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _validade,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (picked != null) {
      setState(() => _validade = picked);
    }
  }

  void _submit() {
    if (_clienteId == null || _clienteId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seleccione um cliente')),
      );
      return;
    }

    AdaptiveNavigator.complete(
      context,
      SaveQuotationDialogResult(
        clienteId: _clienteId!,
        validade: _validade,
        observacoes: _observacoesController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = context.spacing;

    return PharmaResponsiveDialog(
      title: const Text('Guardar cotação'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_loadingCustomers)
            const LinearProgressIndicator()
          else if (_error != null)
            Text(
              'Não foi possível carregar clientes.',
              style: Theme.of(context).textTheme.erpBody.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
            )
          else
            PharmaInstantDropdown<String?>(
              label: 'Cliente *',
              value: _clienteId,
              items: _customers
                  .map(
                    (c) => DropdownMenuItem<String?>(
                      value: c.id,
                      child: Text(c.nome, overflow: TextOverflow.ellipsis),
                    ),
                  )
                  .toList(growable: false),
              onChanged: (value) => setState(() => _clienteId = value),
            ),
          SizedBox(height: s.md),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Validade'),
            subtitle: Text(
              '${_validade.day.toString().padLeft(2, '0')}/'
              '${_validade.month.toString().padLeft(2, '0')}/'
              '${_validade.year}',
            ),
            trailing: const Icon(Icons.calendar_today_outlined),
            onTap: _pickValidade,
          ),
          SizedBox(height: s.md),
          TextField(
            controller: _observacoesController,
            decoration: const InputDecoration(
              labelText: 'Observações',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => AdaptiveNavigator.cancel(context),
          child: const Text('Cancelar'),
        ),
        FilledButton.icon(
          onPressed: _loadingCustomers || _clienteId == null ? null : _submit,
          icon: const Icon(Icons.save_outlined),
          label: const Text('Guardar'),
        ),
      ],
    );
  }
}

Future<SaveQuotationDialogResult?> showSaveQuotationDialog(
  BuildContext context,
) {
  return AdaptiveNavigator.open<SaveQuotationDialogResult>(
    context: context,
    builder: (_) => const SaveQuotationDialog(),
  );
}
