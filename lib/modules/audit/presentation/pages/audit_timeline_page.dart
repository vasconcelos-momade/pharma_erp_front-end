import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/report_paths.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../shared/widgets/feedback/module_data_states.dart';
import '../../../../shared/widgets/layout/enterprise_module_hub.dart';
import '../../../stock/presentation/widgets/movimentacoes_pagination.dart';
import '../../domain/entities/audit_entities.dart';
import '../providers/audit_providers.dart';
import '../widgets/audit_report_exports.dart';

class AuditTimelinePage extends ConsumerStatefulWidget {
  const AuditTimelinePage({super.key});

  @override
  ConsumerState<AuditTimelinePage> createState() => _AuditTimelinePageState();
}

class _AuditTimelinePageState extends ConsumerState<AuditTimelinePage> {
  late final TextEditingController _searchController;
  static final _dateTime = DateFormat('dd/MM/yyyy HH:mm');

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(
      text: ref.read(auditEventsProvider).query.search,
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.spacing;
    final state = ref.watch(auditEventsProvider);
    final notifier = ref.read(auditEventsProvider.notifier);

    if (_searchController.text != state.query.search) {
      _searchController.value = TextEditingValue(
        text: state.query.search,
        selection: TextSelection.collapsed(offset: state.query.search.length),
      );
    }

    return EnterpriseModuleHub(
      title: 'Cronologia de eventos',
      subtitle: 'Imutável, assinado e correlacionado a utilizador/terminal.',
      tag: 'Auditoria',
      actions: [
        OutlinedButton.icon(
          onPressed: state.isBusy ? null : notifier.refresh,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Atualizar'),
        ),
      ],
      filters: Wrap(
        spacing: s.sm,
        runSpacing: s.sm,
        children: [
          SizedBox(
            width: 280,
            child: TextField(
              controller: _searchController,
              onChanged: notifier.onSearchChanged,
              decoration: const InputDecoration(
                hintText: 'Tipo, entidade...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
          ),
          if (state.query.hasFilters)
            TextButton.icon(
              onPressed: state.isBusy ? null : notifier.clearFilters,
              icon: const Icon(Icons.filter_alt_off_outlined),
              label: const Text('Limpar'),
            ),
        ],
      ),
      child: Column(
        children: [
          Expanded(child: _buildBody(context, state, notifier)),
        ],
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    AuditListState<AuditEventSummary> state,
    AuditEventsController notifier,
  ) {
    if (state.viewState == AuditViewState.loading) {
      return const ModuleLoadingState();
    }
    if (state.viewState == AuditViewState.error) {
      return ModuleErrorState(
        title: 'Falha ao carregar eventos',
        message: state.errorMessage ?? 'Erro desconhecido',
        onRetry: notifier.refresh,
        icon: Icons.timeline,
      );
    }
    if (state.viewState == AuditViewState.empty) {
      return ModuleEmptyState(
        title: 'Nenhum evento encontrado',
        subtitle: state.query.hasFilters
            ? 'Tenta limpar os filtros.'
            : 'Ainda não existem eventos registados.',
        onClearFilters: state.query.hasFilters ? notifier.clearFilters : null,
      );
    }

    final t = context.pharmaTokens;
    final s = context.spacing;

    return Column(
      children: [
        Expanded(
          child: ListView.separated(
            itemCount: state.items.length,
            separatorBuilder: (_, _) =>
                Divider(color: t.border.withValues(alpha: 0.35)),
            itemBuilder: (context, index) {
              final e = state.items[index];
              return ListTile(
                leading: Icon(Icons.bolt, color: t.brandBlue),
                title: Text(
                  '${e.type} • ${e.entity}',
                  style: TextStyle(color: t.textPrimary, fontWeight: FontWeight.w700),
                ),
                subtitle: Text(
                  '${e.userName ?? 'Sistema'} • ${_dateTime.format(e.createdAt)}',
                  style: TextStyle(color: t.textMuted, fontSize: 12),
                ),
                trailing: e.entityId != null
                    ? Text('#${e.entityId}', style: TextStyle(color: t.textMuted, fontSize: 11))
                    : null,
              );
            },
          ),
        ),
        SizedBox(height: s.md),
        MovimentacoesPagination(
          page: state.query.page,
          pageSize: state.query.pageSize,
          hasMore: state.hasMore,
          isBusy: state.isBusy,
          onPrev: state.query.page > 1
              ? () => notifier.goToPage(state.query.page - 1)
              : null,
          onNext: state.hasMore
              ? () => notifier.goToPage(state.query.page + 1)
              : null,
          onPageSizeChanged: notifier.setPageSize,
        ),
      ],
    );
  }
}
