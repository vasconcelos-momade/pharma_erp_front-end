import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/errors/api_failure.dart';
import '../../../../../core/theme/design_tokens.dart';
import '../../../../../shared/widgets/feedback/module_data_states.dart';
import '../../../../../shared/widgets/feedback/pharma_feedback.dart';
import '../../../../../shared/widgets/tables/enterprise_data_table.dart';
import '../providers/permission_matrix_provider.dart';

class RolePermissionsEditorDialog extends ConsumerStatefulWidget {
  const RolePermissionsEditorDialog({super.key, required this.role});

  final String role;

  @override
  ConsumerState<RolePermissionsEditorDialog> createState() =>
      _RolePermissionsEditorDialogState();
}

class _RolePermissionsEditorDialogState
    extends ConsumerState<RolePermissionsEditorDialog> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(permissionMatrixProvider.notifier).load(role: widget.role),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(permissionMatrixProvider);
    final notifier = ref.read(permissionMatrixProvider.notifier);

    return AlertDialog(
      title: Text('Permissões — ${widget.role}'),
      content: SizedBox(
        width: 720,
        height: 480,
        child: _buildContent(context, state, notifier),
      ),
      actions: [
        TextButton(
          onPressed: state.isBusy ? null : () => Navigator.of(context).pop(),
          child: const Text('Fechar'),
        ),
        if (state.canEdit && state.hasChanges)
          TextButton(
            onPressed: state.isBusy ? null : notifier.discardChanges,
            child: const Text('Descartar'),
          ),
        FilledButton(
          onPressed: !state.canEdit || state.isBusy || !state.hasChanges
              ? null
              : () => _save(context, notifier),
          child: state.viewState == PermissionMatrixViewState.saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Guardar'),
        ),
      ],
    );
  }

  Widget _buildContent(
    BuildContext context,
    PermissionMatrixState state,
    PermissionMatrixController notifier,
  ) {
    if (state.viewState == PermissionMatrixViewState.loading) {
      return const ModuleLoadingState();
    }
    if (state.viewState == PermissionMatrixViewState.error) {
      return ModuleErrorState(
        title: 'Falha ao carregar',
        message: state.errorMessage ?? 'Erro desconhecido',
        onRetry: () => notifier.load(role: widget.role),
        icon: Icons.vpn_key_outlined,
      );
    }
    if (state.rows.isEmpty) {
      return const ModuleEmptyState(
        title: 'Matriz vazia',
        subtitle: 'Não existem módulos configurados.',
      );
    }

    final t = context.pharmaTokens;

    return EnterpriseDataTable(
      columns: [
        DataColumn(
          label: Text(
            'MÓDULO',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
              color: t.textMuted,
            ),
          ),
        ),
        for (final action in permissionMatrixActions)
          DataColumn(
            label: Text(
              action,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
                color: t.textMuted,
              ),
            ),
          ),
      ],
      rowCount: state.rows.length,
      rowBuilder: (context, index) {
        final row = state.rows[index];
        final moduleMap = state.editableMatrix[row.module] ?? {};
        return DataRow(
          cells: [
            DataCell(Text(
              row.module,
              style: TextStyle(color: t.textPrimary, fontWeight: FontWeight.w700),
            )),
            for (final action in permissionMatrixActions)
              DataCell(
                Checkbox(
                  value: moduleMap[action] ?? false,
                  onChanged: state.isBusy
                      ? null
                      : (_) => notifier.togglePermission(row.module, action),
                ),
              ),
          ],
        );
      },
    );
  }

  Future<void> _save(
    BuildContext context,
    PermissionMatrixController notifier,
  ) async {
    try {
      await notifier.saveRolePermissions();
      if (context.mounted) {
        PharmaFeedback.success(context, 'Permissões actualizadas');
        Navigator.of(context).pop(true);
      }
    } on ApiFailure catch (e) {
      if (context.mounted) PharmaFeedback.error(context, e.message);
    } catch (e) {
      if (context.mounted) PharmaFeedback.error(context, e.toString());
    }
  }
}
