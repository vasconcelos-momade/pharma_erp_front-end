import 'package:flutter/material.dart';

import '../../core/theme/design_tokens.dart';
import '../../core/theme/extensions.dart';
import '../../core/theme/spacing.dart';
import '../widgets/sync/offline_mode_banner.dart';

/// Layout autenticação: fundo do design system e indicadores offline.
class AuthLayout extends StatelessWidget {
  const AuthLayout({
    super.key,
    required this.child,
    this.showOfflineBanner = false,
    this.offlineMessage,
    this.footer,
    this.scrollPadding,
  });

  final Widget child;
  final bool showOfflineBanner;
  final String? offlineMessage;
  final Widget? footer;
  final EdgeInsets? scrollPadding;

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    return Scaffold(
      backgroundColor: t.bgPrimary,
      body: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: t.contentMaxWidth),
                  child: Padding(
                    padding: t.density.pageInsets.copyWith(bottom: 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.md),
                          child: Row(
                            children: [
                              Container(
                                width: t.minTouchTarget,
                                height: t.minTouchTarget,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: t.brandGreen,
                                  borderRadius: BorderRadius.circular(t.radiusMd),
                                ),
                                child: Icon(
                                  Icons.local_pharmacy_rounded,
                                  color: t.bgPrimary,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Text(
                                'Pharma ERP',
                                style: Theme.of(context).textTheme.erpCardTitle.copyWith(
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: -0.5,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        if (showOfflineBanner)
                          OfflineModeBanner(
                            message:
                                offlineMessage ??
                                'A trabalhar em modo offline. As alterações serão sincronizadas.',
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              padding: scrollPadding ?? AppSpacing.pagePadding,
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
