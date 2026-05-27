import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/providers/auth_session_notifier.dart';
import '../../../../app/providers/connection_notifier.dart';
import '../../../../core/config/api_host_resolver.dart';
import '../../../../core/network/connectivity/endpoint_resolver.dart';
import '../../../../app/router/routes.dart';
import '../../../../core/network/connectivity/connection_mode.dart';
import '../../../../core/network/connectivity/connection_status.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../shared/layouts/auth_layout.dart';
import '../../../../shared/widgets/feedback/pharma_snackbar.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final ok = await ref.read(authSessionProvider.notifier).login(
          email: _emailCtrl.text.trim(),
          password: _passCtrl.text,
        );
    if (!mounted) return;

    if (!ok) {
      var msg = ref.read(authSessionProvider).errorMessage;
      if (msg != null) {
        if (msg.contains('Sem ligação ao servidor')) {
          msg = '$msg\n${ApiHostResolver.connectionHintForPlatform()}';
        }
        PharmaSnackbar.showError(context, msg);
      }
      return;
    }

    final session = ref.read(authSessionProvider).session;
    if (session == null) return;

    if (session.hasTenantContext) {
      context.go(AppRoutePaths.dashboard);
    } else {
      context.go(AppRoutePaths.authTenant);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final auth = ref.watch(authSessionProvider);
    final connection = ref.watch(connectionNotifierProvider);
    final apiBaseUrl = ref.watch(activeBaseUrlProvider);
    final loading = auth.isLoading || auth.isBootstrapping;
    final showConnectionBanner = connection.isOffline;
    final connectionMessage = switch (connection.status) {
      ConnectionStatus.offline =>
        'Sem ligação ao servidor local nem ao serviço na nuvem. Pode tentar novamente quando a rede estabilizar.',
      _ => null,
    };

    return AuthLayout(
      showOfflineBanner: showConnectionBanner,
      offlineMessage: connectionMessage,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: t.minTouchTarget + AppSpacing.sm,
                    height: t.minTouchTarget + AppSpacing.sm,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [t.brandBlue, t.brandGreen]),
                      borderRadius: BorderRadius.circular(t.radiusXl),
                      boxShadow: [
                        BoxShadow(color: t.brandBlue.withValues(alpha: 0.35), blurRadius: 24),
                      ],
                    ),
                    child: Icon(Icons.local_pharmacy_rounded, color: t.bgPrimary, size: 30),
                  ),
                  const SizedBox(width: AppSpacing.lg),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pharma ERP',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.5,
                              ),
                        ),
                        Text(
                          'Enterprise • Offline-first • RBAC',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: t.textMuted,
                                letterSpacing: 1.2,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xxxl),
              Material(
                color: t.bgSecondary,
                borderRadius: BorderRadius.circular(t.radiusMd),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(t.radiusMd),
                    border: Border.all(color: t.border.withValues(alpha: 0.75)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.35),
                        blurRadius: 48,
                        offset: const Offset(0, 28),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        height: 3,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [t.brandBlue, t.brandGreen]),
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(AppSpacing.xxl),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Iniciar sessão',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: t.textMuted,
                                  ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Wrap(
                              spacing: AppSpacing.sm,
                              runSpacing: AppSpacing.sm,
                              children: [
                                _StatusChip(
                                  icon: connection.mode == ConnectionMode.cloud
                                      ? Icons.cloud_done_outlined
                                      : Icons.lan_outlined,
                                  label: connection.mode == ConnectionMode.cloud
                                      ? 'Modo nuvem'
                                      : 'Modo local',
                                  color: connection.mode == ConnectionMode.cloud
                                      ? t.brandBlue
                                      : t.brandGreen,
                                ),
                                _StatusChip(
                                  icon: connection.isOffline
                                      ? Icons.cloud_off_outlined
                                      : Icons.check_circle_outline_rounded,
                                  label: connection.isOffline
                                      ? 'Sem ligação'
                                      : (connection.mode == ConnectionMode.cloud
                                          ? 'Nuvem activa'
                                          : 'Local activo'),
                                  color: connection.isOffline ? t.posDanger : t.brandGreen,
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            TextFormField(
                              controller: _emailCtrl,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              autocorrect: false,
                              decoration: const InputDecoration(
                                labelText: 'E-mail',
                                prefixIcon: Icon(Icons.alternate_email_rounded),
                              ),
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) {
                                  return 'Indique o e-mail';
                                }
                                if (!v.contains('@')) {
                                  return 'E-mail inválido';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            TextFormField(
                              controller: _passCtrl,
                              obscureText: _obscure,
                              textInputAction: TextInputAction.done,
                              autocorrect: false,
                              enableSuggestions: false,
                              onFieldSubmitted: (_) => _submit(),
                              decoration: InputDecoration(
                                labelText: 'Palavra-passe',
                                prefixIcon: const Icon(Icons.lock_outline_rounded),
                                suffixIcon: IconButton(
                                  onPressed: () => setState(() => _obscure = !_obscure),
                                  icon: Icon(
                                    _obscure
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                  ),
                                ),
                              ),
                              validator: (v) {
                                if (v == null || v.isEmpty) {
                                  return 'Indique a palavra-passe';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () => context.push(AppRoutePaths.authForgotPassword),
                                child: const Text('Esqueceu-se da palavra-passe?'),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            FilledButton(
                              onPressed: loading ? null : _submit,
                              child: loading
                                  ? SizedBox(
                                      height: 22,
                                      width: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: t.bgPrimary,
                                      ),
                                    )
                                  : const Text('Entrar'),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            OutlinedButton.icon(
                              onPressed: null,
                              icon: const Icon(Icons.fingerprint_rounded),
                              label: const Text('Biometria (em breve)'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
              Text(
                'API: $apiBaseUrl',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(color: t.textMuted),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                '© 2026 Pharma ERP — Operação crítica com auditoria e rastreio ANARME.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(color: t.textMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: AppSpacing.xs),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}
