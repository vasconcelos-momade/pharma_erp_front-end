import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../../app/providers/session_access_notifier.dart';
import '../../../../../core/constants/report_paths.dart';
import '../../../../../core/errors/api_failure.dart';
import '../../../../../core/theme/design_tokens.dart';
import '../../../../../core/theme/spacing.dart';
import '../../../../../shared/navigation/adaptive_navigator.dart';
import '../../../../../shared/responsive/pharma_screen_layout.dart';
import '../../../../../shared/widgets/cards/enterprise_stat_card.dart';
import '../../../../../shared/widgets/feedback/module_data_states.dart';
import '../../../../../shared/widgets/feedback/pharma_feedback.dart';
import '../../../../../shared/widgets/layout/enterprise_module_hub.dart';
import '../../../../../shared/widgets/tables/enterprise_data_table.dart';
import '../../../../stock/presentation/widgets/movimentacoes_pagination.dart';
import '../../data/repositories/user_repository_impl.dart';
import '../../domain/entities/user_entities.dart';
import '../providers/user_list_provider.dart';
import '../widgets/admin_report_exports.dart';
import '../widgets/user_detail_panel.dart';
import '../widgets/user_form_dialog.dart';

class UsersPage extends ConsumerStatefulWidget {
  const UsersPage({super.key});

  @override
  ConsumerState<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends ConsumerState<UsersPage> {
  late final TextEditingController _searchController;
  static final _dateFmt = DateFormat('dd/MM/yyyy');
  static final _dateTimeFmt = DateFormat('dd/MM/yyyy HH:mm');

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(
      text: ref.read(userListProvider).query.search,
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
    final access = ref.watch(sessionAccessProvider);
    final state = ref.watch(userListProvider);
    final notifier = ref.read(userListProvider.notifier);
    final dash = state.dashboard;
    final reportQuery = adminUserReportQuery(
      search: state.query.search,
      role: state.query.role,
      active: state.query.active,
    );

    if (_searchController.text != state.query.search) {
      _searchController.value = TextEditingValue(
        text: state.query.search,
        selection: TextSelection.collapsed(offset: state.query.search.length),
      );
    }

    return EnterpriseModuleHub(
      title: 'Utilizadores',
      subtitle: 'RBAC, multi-inquilino e políticas de sessão.',
      tag: 'Administração',
      actions: [
        ...adminReportActions(
          ref: ref,
          enabled: !state.isBusy,
          path: ReportPaths.adminUsers,
          queryParameters: reportQuery,
        ),
        OutlinedButton.icon(
          onPressed: state.isBusy ? null : notifier.refresh,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Atualizar'),
        ),
        FilledButton.icon(
          onPressed: state.isBusy ? null : () => _openCreateDialog(context),
          icon: const Icon(Icons.person_add_outlined),
          label: const Text('Novo utilizador'),
        ),
      ],
      filters: Wrap(
        spacing: s.sm,
        runSpacing: s.sm,
        children: [
          SizedBox(
            width: 260,
            child: TextField(
              controller: _searchController,
              onChanged: notifier.onSearchChanged,
              decoration: const InputDecoration(
                hintText: 'Nome ou email...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
          ),
        ],
      ),
      kpis: [
        EnterpriseStatCard(
          title: 'Total',
          value: '${dash.totalUtilizadores}',
          icon: Icons.people_outline,
          accent: StatCardAccent.info,
        ),
        EnterpriseStatCard(
          title: 'Activos',
          value: '${dash.ativos}',
          icon: Icons.check_circle_outline,
          accent: StatCardAccent.positive,
        ),
        EnterpriseStatCard(
          title: 'Inactivos',
          value: '${dash.inativos}',
          icon: Icons.person_off_outlined,
          accent: StatCardAccent.danger,
        ),
      ],
      child: !access.isResolved
          ? const ModuleLoadingState()
          : access.canAccessAdministration
          ? _buildBody(context, state, notifier)
          : ModuleErrorState(
              title: 'Sem acesso à administração',
              message:
                  'A sessão atual não possui a permissão UTILIZADORES:VIEW.',
              onRetry: () => ref.read(sessionAccessProvider.notifier).refresh(),
              icon: Icons.lock_outline,
            ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    UserListState state,
    UserListController notifier,
  ) {
    if (state.viewState == UserViewState.loading) {
      return const ModuleLoadingState();
    }
    if (state.viewState == UserViewState.error) {
      return ModuleErrorState(
        title: 'Falha ao carregar utilizadores',
        message: state.errorMessage ?? 'Erro desconhecido',
        onRetry: notifier.refresh,
        icon: Icons.people_outline,
      );
    }
    if (state.viewState == UserViewState.empty) {
      return ModuleEmptyState(
        title: 'Nenhum utilizador encontrado',
        subtitle: 'Ainda não existem utilizadores.',
      );
    }

    final t = context.pharmaTokens;
    final s = context.spacing;
    final recentAccess = state.dashboard.ultimosAcessos;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          flex: recentAccess.isEmpty ? 1 : 3,
          child: EnterpriseDataTable(
            columns: [
              for (final label in ['Nome', 'Email', 'Perfil', 'Estado', 'Registo'])
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
            rowCount: state.items.length,
            rowBuilder: (context, index) {
              final u = state.items[index];
              return DataRow(
                onSelectChanged: (_) => _openDetails(context, u),
                cells: [
                DataCell(Text(u.name, style: TextStyle(color: t.textPrimary, fontWeight: FontWeight.w700))),
                DataCell(Text(u.email ?? '—', style: TextStyle(color: t.textSecondary))),
                DataCell(Text(_roleLabel(u.role), style: TextStyle(color: t.brandBlue, fontWeight: FontWeight.w700))),
                DataCell(Text(
                  u.active ? 'Activo' : 'Inactivo',
                  style: TextStyle(
                    color: u.active ? t.brandGreen : t.posDanger,
                    fontWeight: FontWeight.w800,
                  ),
                )),
                DataCell(Text(_dateFmt.format(u.createdAt), style: TextStyle(color: t.textMuted, fontSize: 12))),
                ],
              );
            },
          ),
        ),
        if (recentAccess.isNotEmpty) ...[
          SizedBox(height: s.md),
          Text(
            'Últimos acessos',
            style: TextStyle(
              color: t.textPrimary,
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
          SizedBox(height: s.sm),
          Expanded(
            flex: 2,
            child: ListView.separated(
              itemCount: recentAccess.length,
              separatorBuilder: (_, _) =>
                  Divider(color: t.border.withValues(alpha: 0.35)),
              itemBuilder: (context, index) {
                final access = recentAccess[index];
                return ListTile(
                  dense: true,
                  leading: Icon(Icons.login, color: t.brandBlue, size: 20),
                  title: Text(
                    access.userName ?? 'Utilizador',
                    style: TextStyle(
                      color: t.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  subtitle: Text(
                    '${access.action} • ${_dateTimeFmt.format(access.createdAt)}',
                    style: TextStyle(color: t.textMuted, fontSize: 12),
                  ),
                  trailing: access.userEmail != null
                      ? Text(
                          access.userEmail!,
                          style: TextStyle(color: t.textMuted, fontSize: 11),
                        )
                      : null,
                );
              },
            ),
          ),
        ],
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

  String _roleLabel(String role) => switch (role) {
        'ADMIN' => 'Administrador',
        'GERENTE' => 'Gestor',
        'FARMACEUTICO' => 'Farmacêutico',
        'DIRETOR_TECNICO' => 'Director técnico',
        'CAIXA' => 'Caixa PDV',
        _ => role,
      };

  Future<void> _openDetails(BuildContext context, TenantUserSummary user) async {
    Future<void> onEdit() async {
      final detail = await ref.read(userRepositoryProvider).getUser(user.id);
      if (!context.mounted) return;
      final result = await showUserFormDialog(context, user: detail);
      if (result == null || !context.mounted) return;
      try {
        await ref.read(userListProvider.notifier).updateUser(user.id, result.toPayload());
        if (context.mounted) PharmaFeedback.success(context, 'Utilizador actualizado');
      } on ApiFailure catch (e) {
        if (context.mounted) PharmaFeedback.error(context, e.message);
      }
    }

    Future<void> onToggleActive() async {
      final detail = await ref.read(userRepositoryProvider).getUser(user.id);
      if (!context.mounted) return;
      try {
        await ref.read(userListProvider.notifier).updateUser(
              user.id,
              UserFormPayload(
                name: detail.name,
                email: detail.email ?? '',
                role: detail.role,
                active: !detail.active,
                version: detail.version,
              ),
            );
        if (context.mounted) {
          PharmaFeedback.success(
            context,
            detail.active ? 'Utilizador desactivado' : 'Utilizador activado',
          );
          AdaptiveNavigator.close(context);
        }
      } on ApiFailure catch (e) {
        if (context.mounted) PharmaFeedback.error(context, e.message);
      }
    }

    Future<void> onDelete() async {
      final confirmed = await PharmaFeedback.confirm(
        context: context,
        title: 'Excluir utilizador',
        message: 'Deseja excluir «${user.name}»?',
        confirmText: 'Excluir',
      );
      if (!context.mounted || confirmed != true) return;
      try {
        await ref.read(userListProvider.notifier).deleteUser(user.id);
        if (context.mounted) {
          PharmaFeedback.success(context, 'Utilizador excluído');
          AdaptiveNavigator.close(context);
        }
      } on ApiFailure catch (e) {
        if (context.mounted) PharmaFeedback.error(context, e.message);
      }
    }

    await AdaptiveNavigator.openDetail(
      context: context,
      title: user.name,
      routeSettings: RouteSettings(name: '/utilizadores/${user.id}'),
      builder: (_, onClose) => UserDetailPanel(
        userId: user.id,
        onClose: onClose,
        onEdit: onEdit,
        onDelete: onDelete,
        onToggleActive: onToggleActive,
      ),
    );
  }

  Future<void> _openCreateDialog(BuildContext context) async {
    final result = await showUserFormDialog(context);
    if (result == null || !context.mounted) return;
    try {
      await ref.read(userListProvider.notifier).createUser(result.toPayload());
      if (context.mounted) {
        PharmaFeedback.success(context, 'Utilizador criado com sucesso');
      }
    } on ApiFailure catch (e) {
      if (context.mounted) PharmaFeedback.error(context, e.message);
    }
  }
}
