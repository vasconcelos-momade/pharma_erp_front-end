import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/api_failure.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/theme/extensions.dart';
import '../../../../shared/responsive/responsive_builder.dart';
import '../../../../shared/widgets/cards/enterprise_list_card.dart';
import '../../../../shared/widgets/feedback/module_data_states.dart';
import '../../../../shared/widgets/layout/enterprise_mobile_scroll_list.dart';
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
    return EnterpriseModuleHub(
      title: 'Terminais & PDV',
      subtitle: 'Registo de dispositivos, licenças e heartbeat.',
      tag: 'Sistema',
      actions: null,
      filters: null,
      child: ResponsiveBuilder(
        builder: (context, constraints) {
          final isMobile = !constraints.isTabletOrWider;
          return _buildBody(context, context.pharmaTokens, isMobile);
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context, PharmaTokens t, bool isMobile) {
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

    if (isMobile) {
      final s = context.spacing;
      return EnterpriseMobileScrollList(
        stickyHeader: ColoredBox(
          color: t.bgPrimary,
          child: Padding(
            padding: EdgeInsets.fromLTRB(s.md, s.sm, s.md, s.sm),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Terminais registados',
                    style: Theme.of(context).textTheme.erpSectionTitle.copyWith(
                          color: t.textPrimary,
                        ),
                  ),
                ),
                IconButton(
                  onPressed: _load,
                  icon: const Icon(Icons.refresh_rounded),
                ),
              ],
            ),
          ),
        ),
        itemCount: _items.length,
        itemBuilder: (context, index) {
          final item = _items[index];
          return EnterpriseListCard(
            leading: Icons.point_of_sale_outlined,
            title: item.terminalNome,
            subtitle: item.terminalCodigo,
            metadata: [
              EnterpriseListCardMeta(label: 'Localização: ${item.localizacao ?? '—'}'),
              EnterpriseListCardMeta(label: 'Caixa: ${item.caixaId}'),
            ],
          );
        },
        hasMore: false,
        isLoading: false,
        emptyMessage: 'Nenhum terminal disponível',
      );
    }

    return EnterpriseDataTable(
      adaptive: false,
      showCheckboxColumn: false,
      columns: [
        for (final label in ['Terminal', 'Código', 'Localização', 'Caixa'])
          DataColumn(
            label: Text(
              label.toUpperCase(),
              style: Theme.of(context).textTheme.erpOverline.copyWith(color: t.textMuted),
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
              style: Theme.of(context).textTheme.erpCardTitle.copyWith(color: t.textPrimary),
            )),
            DataCell(Text(
              item.terminalCodigo,
              style: Theme.of(context).textTheme.erpBodySecondary.copyWith(color: t.textSecondary),
            )),
            DataCell(Text(
              item.localizacao ?? '—',
              style: Theme.of(context).textTheme.erpBodySecondary.copyWith(color: t.textSecondary),
            )),
            DataCell(Text(
              item.caixaId,
              style: Theme.of(context).textTheme.erpBodySecondary.copyWith(color: t.textSecondary),
            )),
          ],
        );
      },
    );
  }
}
