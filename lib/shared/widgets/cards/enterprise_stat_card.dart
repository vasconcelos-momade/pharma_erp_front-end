import 'package:flutter/material.dart';

import '../../../core/theme/design_tokens.dart';

/// Densidade visual do KPI (balcão / tablet compacto / desktop).
enum StatCardDensity {
  /// Menos altura, tipografia compacta — mobile e tablet operacional.
  compact,

  /// Área de leitura ligeiramente maior — desktop ou destaques.
  comfortable,
}

/// Cartão KPI enterprise — hierarquia clara, toque com ripple, hover no desktop.
class EnterpriseStatCard extends StatelessWidget {
  const EnterpriseStatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    this.subtitle,
    this.accent = StatCardAccent.neutral,
    this.density = StatCardDensity.compact,
    this.onTap,
    this.badge,
  });

  final String title;
  final String value;
  final IconData icon;
  final String? subtitle;
  final StatCardAccent accent;
  final StatCardDensity density;
  final VoidCallback? onTap;
  /// Texto curto opcional (ex.: LIVE, SYNC).
  final String? badge;

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final compact = density == StatCardDensity.compact;
    final (Color fg, Color bg) = switch (accent) {
      StatCardAccent.positive => (t.brandGreen, t.brandGreen.withValues(alpha: 0.1)),
      StatCardAccent.warning => (t.posWarning, t.posWarning.withValues(alpha: 0.1)),
      StatCardAccent.danger => (t.posDanger, t.posDanger.withValues(alpha: 0.1)),
      StatCardAccent.info => (t.brandBlue, t.brandBlue.withValues(alpha: 0.12)),
      StatCardAccent.neutral => (t.textSecondary, t.textMuted.withValues(alpha: 0.12)),
    };

    final pad = compact ? const EdgeInsets.fromLTRB(10, 8, 10, 8) : const EdgeInsets.all(16);
    final titleSize = compact ? 9.0 : 10.0;
    final valueSize = compact ? 16.0 : 26.0;
    final iconBox = compact ? 5.0 : 8.0;
    final iconSize = compact ? 15.0 : 18.0;
    final gapAfterHeader = compact ? 4.0 : 10.0;
    final gapBeforeSubtitle = compact ? 2.0 : 8.0;

    final child = AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      padding: pad,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(t.radiusMd),
        border: Border.all(color: t.border.withValues(alpha: 0.55)),
      ),
      child: LayoutBuilder(
            builder: (context, constraints) {
              final content = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title.toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: titleSize,
                            fontWeight: FontWeight.w800,
                            letterSpacing: compact ? 1.2 : 1.8,
                            color: t.textMuted,
                            height: 1.1,
                          ),
                        ),
                      ),
                      if (badge != null)
                        Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: fg.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              badge!,
                              style: TextStyle(fontSize: 7.5, fontWeight: FontWeight.w900, color: fg, letterSpacing: 0.5),
                            ),
                          ),
                        ),
                      Container(
                        padding: EdgeInsets.all(iconBox),
                        decoration: BoxDecoration(
                          color: bg,
                          borderRadius: BorderRadius.circular(t.radiusMd),
                        ),
                        child: Icon(icon, size: iconSize, color: fg),
                      ),
                    ],
                  ),
                  SizedBox(height: gapAfterHeader),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: valueSize,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                      height: 1.0,
                      color: accent == StatCardAccent.danger
                          ? t.posDanger
                          : accent == StatCardAccent.info
                              ? t.brandBlue
                              : t.textPrimary,
                    ),
                  ),
                  if (subtitle != null && subtitle!.isNotEmpty) ...[
                    SizedBox(height: gapBeforeSubtitle),
                    Text(
                      subtitle!,
                      maxLines: compact ? 1 : 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: compact ? 9.5 : 11,
                        fontWeight: FontWeight.w600,
                        color: t.textMuted,
                        height: 1.1,
                      ),
                    ),
                  ],
                ],
              );

              if (!constraints.hasBoundedHeight || !constraints.maxHeight.isFinite) {
                return content;
              }

              return SizedBox(
                width: constraints.maxWidth,
                height: constraints.maxHeight,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.topLeft,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: constraints.maxWidth),
                    child: content,
                  ),
                ),
              );
            },
          ),
        );

    if (onTap != null) {
      return Material(
        color: t.card,
        borderRadius: BorderRadius.circular(t.radiusMd),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(t.radiusMd),
          mouseCursor: SystemMouseCursors.click,
          hoverColor: fg.withValues(alpha: 0.06),
          splashColor: fg.withValues(alpha: 0.08),
          child: child,
        ),
      );
    }
    return Material(
      color: t.card,
      borderRadius: BorderRadius.circular(t.radiusMd),
      child: child,
    );
  }
}

enum StatCardAccent { neutral, positive, warning, danger, info }
