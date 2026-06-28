import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../app/router/routes.dart';
import '../../../../../shared/widgets/feedback/module_data_states.dart';
import '../../../../../shared/widgets/layout/enterprise_module_hub.dart';

class SalesQuotationsPage extends StatelessWidget {
  const SalesQuotationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return EnterpriseModuleHub(
      title: 'Cotações',
      subtitle: 'Propostas comerciais e orçamentos antes da facturação.',
      tag: 'Terminal',
      actions: [
        FilledButton.icon(
          onPressed: () => context.go(AppRoutePaths.pos),
          icon: const Icon(Icons.point_of_sale_outlined),
          label: const Text('Abrir PDV'),
        ),
      ],
      child: const ModuleEmptyState(
        title: 'Cotações em preparação',
        subtitle:
            'Este módulo listará cotações e orçamentos emitidos pelo terminal. '
            'Por agora, utilize o PDV / Caixa para preparar vendas em rascunho.',
      ),
    );
  }
}
