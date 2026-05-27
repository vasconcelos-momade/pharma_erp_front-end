import 'package:flutter/material.dart';

import '../../core/theme/design_tokens.dart';
import '../../core/theme/spacing.dart';
import '../widgets/sync/offline_mode_banner.dart';

/// Layout autenticação: fundo premium, slot para biometria/indicadores offline.
class AuthLayout extends StatelessWidget {
  const AuthLayout({
    super.key,
    required this.child,
    this.showOfflineBanner = false,
    this.offlineMessage,
    this.footer,
  });

  final Widget child;
  final bool showOfflineBanner;
  final String? offlineMessage;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    return Scaffold(
      backgroundColor: t.bgPrimary,
      body: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    t.brandBlue.withValues(alpha: 0.12),
                    t.bgPrimary,
                    t.brandGreen.withValues(alpha: 0.06),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (showOfflineBanner)
                      OfflineModeBanner(
                        message: offlineMessage ?? 'A trabalhar em modo offline. As alterações serão sincronizadas.',
                      ),
                  ],
                ),
              ),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              padding: AppSpacing.pagePadding,
              child: child,
            ),
          ),
          if (footer != null)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: SafeArea(child: footer!),
            ),
        ],
      ),
    );
  }
}
