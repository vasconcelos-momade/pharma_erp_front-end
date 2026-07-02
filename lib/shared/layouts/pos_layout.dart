import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router/routes.dart';
import '../../core/theme/design_tokens.dart';
import '../../core/theme/extensions.dart';
import '../../core/theme/dimensions.dart';
import '../../core/theme/spacing.dart';
import '../../modules/sales/pdv/presentation/providers/caixa_sessao_provider.dart';
import '../../modules/sales/pdv/presentation/widgets/abrir_caixa_dialog.dart';
import '../widgets/buttons/pharma_button_loader.dart';
import '../widgets/sync/sync_status_strip.dart';

/// Chrome PDV ultra-rápido: atalhos, scanner, sync e saída segura.
class PosLayout extends ConsumerWidget {
  const PosLayout({super.key, required this.child});

  final Widget child;

  Future<void> _onCaixaPressed(
    BuildContext context,
    WidgetRef ref,
    CaixaSessaoState caixaState,
  ) async {
    if (caixaState.hasSessaoAberta && caixaState.sessaoAtual != null) {
      await showFecharCaixaDialog(context, sessao: caixaState.sessaoAtual!);
      return;
    }

    await showAbrirCaixaDialog(context);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.pharmaTokens;
    final width = MediaQuery.sizeOf(context).width;
    final isMobile = width < 640;
    final caixaState = ref.watch(caixaSessaoProvider);
    final sessaoAtual = caixaState.sessaoAtual;
    final caixaAberto = sessaoAtual != null;
    final caixaLabel = caixaAberto ? 'Caixa Aberto' : 'Abrir Caixa';
    final caixaIcon =
        caixaAberto ? Icons.lock_open_rounded : Icons.lock_outline_rounded;
    final caixaColor = caixaAberto ? t.brandGreen : t.posDanger;
    final subtitle = caixaAberto
        ? 'Caixa aberto • Operações liberadas • FEFO • ESC/POS'
        : 'Caixa fechado • Abra o caixa para iniciar as operações';

    return Scaffold(
      backgroundColor: t.bgPrimary,
      body: Column(
        children: [
          Container(
            height: AppDimensions.posHeader,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            decoration: BoxDecoration(
              color: t.bgSecondary,
              border: Border(bottom: BorderSide(color: t.border)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: LayoutBuilder(
              builder: (context, bx) {
                final narrow = bx.maxWidth < 640;
                return Row(
                  children: [
                    Container(
                      width: narrow ? 40 : 44,
                      height: narrow ? 40 : 44,
                      decoration: BoxDecoration(
                        gradient:
                            LinearGradient(colors: [t.brandBlue, t.brandGreen]),
                        borderRadius: BorderRadius.circular(t.radiusMd),
                      ),
                      child: Icon(
                        Icons.point_of_sale_rounded,
                        color: t.bgPrimary,
                        size: narrow ? 22 : 24,
                      ),
                    ),
                    SizedBox(width: narrow ? AppSpacing.sm : AppSpacing.md),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Pharma ERP — PDV',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.erpTabLabel.copyWith(
                                  fontWeight: FontWeight.w800,
                                  fontSize: narrow ? 13 : null,
                                ),
                          ),
                          if (!narrow)
                            Text(
                              subtitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.erpOverline.copyWith(color: t.textMuted),
                            ),
                        ],
                      ),
                    ),
                    if (!narrow && caixaState.isLoading)
                      const Padding(
                        padding: EdgeInsets.only(right: AppSpacing.sm),
                        child: PharmaButtonLoader(),
                      ),
                    Tooltip(
                      message: caixaLabel,
                      child: narrow
                          ? IconButton(
                              onPressed: caixaState.isSubmitting
                                  ? null
                                  : () => _onCaixaPressed(
                                        context,
                                        ref,
                                        caixaState,
                                      ),
                              icon: Icon(caixaIcon, color: caixaColor),
                            )
                          : OutlinedButton.icon(
                              onPressed: caixaState.isSubmitting
                                  ? null
                                  : () => _onCaixaPressed(
                                        context,
                                        ref,
                                        caixaState,
                                      ),
                              icon: caixaState.isSubmitting
                                  ? const PharmaButtonLoader()
                                  : Icon(caixaIcon, color: caixaColor),
                              label: Text(
                                caixaLabel,
                                style: Theme.of(context).textTheme.erpTabLabel.copyWith(color: caixaColor),
                              ),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(
                                  color: caixaColor.withValues(alpha: 0.45),
                                ),
                              ),
                            ),
                    ),
                    SizedBox(width: narrow ? AppSpacing.sm : AppSpacing.md),
                    SyncStatusStrip(
                      state: SyncVisualState.online,
                      pendingCount: 0,
                      compact: narrow,
                    ),
                    SizedBox(width: narrow ? AppSpacing.sm : AppSpacing.lg),
                    if (narrow)
                      IconButton(
                        tooltip: 'Sair PDV',
                        onPressed: () => context.go(AppRoutePaths.dashboard),
                        icon: Icon(
                          Icons.close_rounded,
                          color: t.textSecondary,
                        ),
                      )
                    else
                      TextButton.icon(
                        onPressed: () => context.go(AppRoutePaths.dashboard),
                        icon: Icon(
                          Icons.arrow_back_rounded,
                          color: t.textSecondary,
                          size: t.iconSm,
                        ),
                        label: Text(
                          'Sair do PDV',
                          style: Theme.of(context).textTheme.erpLabel.copyWith(color: t.textSecondary),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
          Expanded(
            child: Padding(
              padding: t.density.pageInsets,
              child: child,
            ),
          ),
          if (!isMobile)
            Container(
              height: AppDimensions.posFooter,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              decoration: BoxDecoration(
                color: t.bgSecondary,
                border: Border(top: BorderSide(color: t.border)),
              ),
              child: Row(
                children: [
                  _ShortcutChip(icon: Icons.search, label: 'F2 Busca'),
                  const SizedBox(width: AppSpacing.md),
                  _ShortcutChip(icon: Icons.qr_code_scanner, label: 'Scanner'),
                  const SizedBox(width: AppSpacing.md),
                  _ShortcutChip(
                    icon: Icons.payments_outlined,
                    label: 'F4 Pagamento',
                  ),
                  const Spacer(),
                  Text(
                    'Multi-caixa • Impressão térmica',
                    style: Theme.of(context).textTheme.erpOverline.copyWith(color: t.textMuted),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _ShortcutChip extends StatelessWidget {
  const _ShortcutChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: t.card.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(t.radiusMd),
        border: Border.all(color: t.border.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: t.brandBlue),
          const SizedBox(width: AppSpacing.xs),
          Text(
            label,
            style: Theme.of(context).textTheme.erpOverline.copyWith(color: t.textSecondary),
          ),
        ],
      ),
    );
  }
}
