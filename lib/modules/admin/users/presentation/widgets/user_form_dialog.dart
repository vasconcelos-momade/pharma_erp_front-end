import 'package:flutter/material.dart';

import '../../../../../core/theme/spacing.dart';
import '../../../../../shared/widgets/dialogs/pharma_responsive_dialog.dart';
import '../../domain/entities/user_entities.dart';

class UserFormResult {
  const UserFormResult({
    required this.name,
    required this.email,
    required this.role,
    this.active = true,
    this.version,
  });

  final String name;
  final String email;
  final String role;
  final bool active;
  final int? version;

  UserFormPayload toPayload() => UserFormPayload(
        name: name,
        email: email,
        role: role,
        active: active,
        version: version,
      );
}

Future<UserFormResult?> showUserFormDialog(
  BuildContext context, {
  TenantUserDetail? user,
}) {
  return showDialog<UserFormResult>(
    context: context,
    builder: (_) => UserFormDialog(user: user),
  );
}

class UserFormDialog extends StatefulWidget {
  const UserFormDialog({super.key, this.user});

  final TenantUserDetail? user;

  bool get isEditing => user != null;

  @override
  State<UserFormDialog> createState() => _UserFormDialogState();
}

class _UserFormDialogState extends State<UserFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late String _role;
  late bool _active;

  static const _roles = [
    ('ADMIN', 'Administrador'),
    ('GERENTE', 'Gestor'),
    ('FARMACEUTICO', 'Farmacêutico'),
    ('DIRETOR_TECNICO', 'Director técnico'),
    ('CAIXA', 'Caixa PDV'),
  ];

  @override
  void initState() {
    super.initState();
    final u = widget.user;
    _nameController = TextEditingController(text: u?.name ?? '');
    _emailController = TextEditingController(text: u?.email ?? '');
    _role = u?.role ?? 'GERENTE';
    _active = u?.active ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(
      UserFormResult(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        role: _role,
        active: _active,
        version: widget.user?.version,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = context.spacing;

    return PharmaResponsiveDialog(
      title: Text(widget.isEditing ? 'Editar utilizador' : 'Novo utilizador'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nome *',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Nome obrigatório' : null,
            ),
            SizedBox(height: s.md),
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email *',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Email obrigatório';
                if (!v.contains('@')) return 'Email inválido';
                return null;
              },
            ),
            SizedBox(height: s.md),
            DropdownButtonFormField<String>(
              initialValue: _role,
              decoration: const InputDecoration(
                labelText: 'Perfil',
                border: OutlineInputBorder(),
              ),
              items: _roles
                  .map(
                    (r) => DropdownMenuItem(value: r.$1, child: Text(r.$2)),
                  )
                  .toList(),
              onChanged: (v) => setState(() => _role = v ?? 'GERENTE'),
            ),
            SizedBox(height: s.sm),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Utilizador activo'),
              value: _active,
              onChanged: (v) => setState(() => _active = v),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(widget.isEditing ? 'Guardar' : 'Criar'),
        ),
      ],
    );
  }
}
