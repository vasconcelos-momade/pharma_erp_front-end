import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/api_failure.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../shared/widgets/feedback/module_data_states.dart';
import '../../../../shared/widgets/layout/enterprise_module_hub.dart';
import '../../../../shared/widgets/tables/enterprise_data_table.dart';
import '../../../sales/pdv/data/datasources/pdv_remote_datasource.dart';
import '../../../sales/pdv/data/models/caixa_sessao_model.dart';

class TerminalsPage extends ConsumerStatefulWidget {
  const TerminalsPage({super.key});

  @override
  ConsumerState<TerminalsPage> createState() => _TerminalsPageState();
}

class _TerminalsPageState extends ConsumerState<TerminalsPage> {
  bool _loading = true;
  String? _error;
  List<CaixaDisponivelModel> _items = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final items =
          await ref.read(pdvRemoteDataSourceProvider).listCaixasDisponiveis();
      if (!mounted) return;
      setState(() {
        _items = items;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e is ApiFailure ? e.message : e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;

    return EnterpriseModuleHub(
      title: 'Terminais & PDV',
      subtitle: 'Registo de dispositivos, licenças e heartbeat.',
      tag: 'Sistema',
      actions: [
        OutlinedButton.icon(
          onPressed: _loading ? null : _load,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Atualizar'),
        ),
      ],
      child: _buildBody(t),
    );
  }

  Widget _buildBody(PharmaTokens t) {
    if (_loading) return const ModuleLoadingState();
    if (_error != null) {
      return ModuleErrorState(
        title: 'Falha ao carregar terminais',
        message: _error!,
        onRetry: _load,
        icon: Icons.point_of_sale_outlined,
      );
    }
    if (_items.isEmpty) {
      return const ModuleEmptyState(
        title: 'Nenhum terminal disponível',
        subtitle: 'Não existem caixas registadas para esta unidade.',
      );
    }

    return EnterpriseDataTable(
      columns: [
        for (final label in ['Terminal', 'Código', 'Localização', 'Caixa'])
          DataColumn(
            label: Text(
              label.toUpperCase(),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
                color: t.textMuted,
              ),
            ),
          ),
      ],
      rowCount: _items.length,
      rowBuilder: (context, index) {
        final item = _items[index];
        return DataRow(
          cells: [
            DataCell(Text(
              item.terminalNome,
              style: TextStyle(
                color: t.textPrimary,
                fontWeight: FontWeight.w800,
              ),
            )),
            DataCell(Text(
              item.terminalCodigo,
              style: TextStyle(color: t.textSecondary),
            )),
            DataCell(Text(
              item.localizacao ?? '—',
              style: TextStyle(color: t.textMuted),
            )),
            DataCell(Text(
              item.caixaId,
              style: TextStyle(color: t.textMuted),
            )),
          ],
        );
      },
    );
  }
}
