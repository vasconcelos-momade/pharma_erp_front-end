import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../app/router/routes.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/utils/list_csv_exporter.dart';
import '../../../../shared/widgets/cards/enterprise_stat_card.dart';
import '../../../../shared/widgets/feedback/module_data_states.dart';
import '../../../../shared/widgets/layout/enterprise_module_hub.dart';
import '../../domain/entities/audit_entities.dart';
import '../providers/audit_providers.dart';

class AuditPage extends ConsumerWidget {
  const AuditPage({super.key});

  static final _dateTime = DateFormat('dd/MM/yyyy HH:mm');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(auditDashboardProvider);
    final notifier = ref.read(auditDashboardProvider.notifier);
    final dash = state.dashboard;

    return EnterpriseModuleHub(
      title: 'Auditoria',
      subtitle: 'Trilho imutável de operações, permissões e eventos críticos.',
      tag: 'Auditoria',
      actions: [
        OutlinedButton.icon(
          onPressed: state.dashboard.recentEvents.isEmpty
              ? null
              : () => _exportEvents(state.dashboard.recentEvents),
          icon: const Icon(Icons.download_outlined),
          label: const Text('Exportar CSV'),
        ),
        OutlinedButton.icon(
          onPressed: state.isBusy ? null : notifier.load,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Atualizar'),
        ),
        FilledButton.icon(
          onPressed: () => context.go(AppRoutePaths.auditTimeline),
          icon: const Icon(Icons.timeline),
          label: const Text('Cronologia'),
        ),
      ],
      kpis: [
        EnterpriseStatCard(
          title: 'Logs totais',
          value: '${dash.totalLogs}',
          icon: Icons.storage_outlined,
          accent: StatCardAccent.info,
        ),
        EnterpriseStatCard(
          title: 'Últimas 24h',
          value: '${dash.logsLast24h}',
          icon: Icons.schedule,
          accent: StatCardAccent.neutral,
        ),
        EnterpriseStatCard(
          title: 'Eventos críticos (7d)',
          value: '${dash.criticalEventsLast7d}',
          icon: Icons.warning_amber_outlined,
          accent: StatCardAccent.danger,
        ),
        EnterpriseStatCard(
          title: 'Alterações permissões',
          value: '${dash.permissionChangesLast7d}',
          icon: Icons.vpn_key_outlined,
          accent: StatCardAccent.warning,
        ),
      ],
      child: _buildBody(context, state, notifier),
    );
  }

  Widget _buildBody(
    BuildContext context,
    AuditDashboardState state,
    AuditDashboardController notifier,
  ) {
    if (state.viewState == AuditViewState.loading) {
      return const ModuleLoadingState();
    }
    if (state.viewState == AuditViewState.error) {
      return ModuleErrorState(
        title: 'Falha ao carregar auditoria',
        message: state.errorMessage ?? 'Erro desconhecido',
        onRetry: notifier.load,
        icon: Icons.history,
      );
    }

    final t = context.pharmaTokens;
    final s = context.spacing;
    final events = state.dashboard.recentEvents;

    if (events.isEmpty) {
      return const ModuleEmptyState(
        title: 'Sem eventos recentes',
        subtitle: 'Não existem eventos de negócio registados.',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Eventos recentes',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: t.textPrimary,
                fontWeight: FontWeight.w800,
              ),
        ),
        SizedBox(height: s.sm),
        Expanded(
          child: ListView.separated(
            itemCount: events.length,
            separatorBuilder: (_, _) =>
                Divider(color: t.border.withValues(alpha: 0.35)),
            itemBuilder: (context, index) {
              final e = events[index];
              return ListTile(
                leading: Icon(Icons.bolt, color: t.brandBlue),
                title: Text(
                  '${e.type} • ${e.entity}',
                  style: TextStyle(
                    color: t.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
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
      ],
    );
  }

  Future<void> _exportEvents(List<AuditEventSummary> events) async {
    await ListCsvExporter.export(
      fileName: 'auditoria-eventos-recentes',
      headers: const ['Tipo', 'Entidade', 'ID entidade', 'Utilizador', 'Data'],
      rows: events
          .map(
            (e) => [
              e.type,
              e.entity,
              e.entityId ?? '—',
              e.userName ?? 'Sistema',
              _dateTime.format(e.createdAt),
            ],
          )
          .toList(),
    );
  }
}
