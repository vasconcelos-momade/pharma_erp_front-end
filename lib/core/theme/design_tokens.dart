import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'design_metrics.dart';

enum DensityLevel {
  mobile,
  compact,
  comfortable,
}

@immutable
class DensityTokens {
  const DensityTokens({
    required this.level,
    required this.xxs,
    required this.xs,
    required this.sm,
    required this.md,
    required this.lg,
    required this.xl,
    required this.xxl,
    required this.xxxl,
    required this.gutter,
    required this.page,
    required this.cardPadding,
    required this.buttonPadding,
    required this.inputPadding,
  });

  final DensityLevel level;
  final double xxs;
  final double xs;
  final double sm;
  final double md;
  final double lg;
  final double xl;
  final double xxl;
  final double xxxl;
  final double gutter;
  final double page;
  final EdgeInsets cardPadding;
  final EdgeInsets buttonPadding;
  final EdgeInsets inputPadding;

  /// Margens do conteúdo principal (shell das páginas de módulo).
  EdgeInsets get pageInsets => EdgeInsets.fromLTRB(gutter, md, gutter, lg);

  static const DensityTokens mobile = DensityTokens(
    level: DensityLevel.mobile,
    xxs: 2,
    xs: 4,
    sm: 6,
    md: 8,
    lg: 12,
    xl: 16,
    xxl: 20,
    xxxl: 24,
    gutter: 12,
    page: 12,
    cardPadding: EdgeInsets.all(12),
    buttonPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    inputPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
  );

  static const DensityTokens compact = DensityTokens(
    level: DensityLevel.compact,
    xxs: 2,
    xs: 4,
    sm: 8,
    md: 12,
    lg: 16,
    xl: 20,
    xxl: 24,
    xxxl: 32,
    gutter: 16,
    page: 16,
    cardPadding: EdgeInsets.all(16),
    buttonPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    inputPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  );

  static const DensityTokens comfortable = DensityTokens(
    level: DensityLevel.comfortable,
    xxs: 2,
    xs: 4,
    sm: 8,
    md: 12,
    lg: 16,
    xl: 20,
    xxl: 24,
    xxxl: 32,
    gutter: 16,
    page: 16,
    cardPadding: EdgeInsets.all(16),
    buttonPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    inputPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  );
}

@immutable
class PharmaTokens extends ThemeExtension<PharmaTokens> {
  const PharmaTokens({
    required this.bgPrimary,
    required this.bgSecondary,
    required this.card,
    required this.cardHover,
    required this.border,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.brandBlue,
    required this.brandBlueHover,
    required this.brandGreen,
    required this.brandGreenHover,
    required this.posSuccess,
    required this.posWarning,
    required this.posDanger,
    required this.posInfo,
    required this.psychotropic,
    required this.quarantine,
    required this.incineration,
    required this.recall,
    required this.radiusMd,
    required this.radiusXl,
    required this.radius2xl,
    required this.radius3xl,
    required this.minTouchTarget,
    required this.iconMd,
    required this.iconSm,
    required this.avatarMd,
    required this.topBarDesktop,
    required this.topBarCompact,
    required this.posHeader,
    required this.posFooter,
    required this.sidebarExpanded,
    required this.sidebarCollapsed,
    required this.contentMaxWidth,
    required this.density,
  });

  final Color bgPrimary;
  final Color bgSecondary;
  final Color card;
  final Color cardHover;
  final Color border;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color brandBlue;
  final Color brandBlueHover;
  final Color brandGreen;
  final Color brandGreenHover;
  final Color posSuccess;
  final Color posWarning;
  final Color posDanger;
  final Color posInfo;
  final Color psychotropic;
  final Color quarantine;
  final Color incineration;
  final Color recall;
  final double radiusMd;
  final double radiusXl;
  final double radius2xl;
  final double radius3xl;
  final double minTouchTarget;
  final double iconMd;
  final double iconSm;
  final double avatarMd;
  final double topBarDesktop;
  final double topBarCompact;
  final double posHeader;
  final double posFooter;
  final double sidebarExpanded;
  final double sidebarCollapsed;
  final double contentMaxWidth;
  final DensityTokens density;

  // Backward-compatible aliases used by older widgets/layouts.
  double get radiusSm => radiusMd;
  double get radiusLg => radiusXl;

  static PharmaTokens enterpriseDark({DensityTokens density = DensityTokens.comfortable}) {
    return PharmaTokens(
      bgPrimary: AppColors.ink950,
      bgSecondary: AppColors.ink900,
      card: AppColors.ink800,
      cardHover: const Color(0xFF171D26),
      border: const Color(0xFF1F2937),
      textPrimary: const Color(0xFFF5F7FA),
      textSecondary: const Color(0xFF9CA3AF),
      textMuted: const Color(0xFF6B7280),
      brandBlue: AppColors.pharmaBlueSoft,
      brandBlueHover: AppColors.pharmaBlue,
      brandGreen: AppColors.hospitalGreenBright,
      brandGreenHover: AppColors.hospitalGreen,
      posSuccess: AppColors.hospitalGreenBright,
      posWarning: AppColors.attention,
      posDanger: AppColors.critical,
      posInfo: AppColors.info,
      psychotropic: const Color(0xFF8B5CF6),
      quarantine: const Color(0xFFFB923C),
      incineration: const Color(0xFFDC2626),
      recall: const Color(0xFFEAB308),
      radiusMd: 8,
      radiusXl: 16,
      radius2xl: 20,
      radius3xl: 32,
      minTouchTarget: DesignMetrics.minTouchTarget,
      iconMd: DesignMetrics.iconMd,
      iconSm: DesignMetrics.iconSm,
      avatarMd: DesignMetrics.avatarMd,
      topBarDesktop: DesignMetrics.topBarDesktop,
      topBarCompact: DesignMetrics.topBarCompact,
      posHeader: DesignMetrics.posHeader,
      posFooter: DesignMetrics.posFooter,
      sidebarExpanded: DesignMetrics.sidebarExpanded,
      sidebarCollapsed: DesignMetrics.sidebarCollapsed,
      contentMaxWidth: DesignMetrics.contentMaxWidth,
      density: density,
    );
  }

  static PharmaTokens enterpriseLight({DensityTokens density = DensityTokens.comfortable}) {
    return PharmaTokens(
      bgPrimary: AppColors.cloud50,
      bgSecondary: AppColors.cloud100,
      card: Colors.white,
      cardHover: const Color(0xFFFAFBFC),
      border: AppColors.cloud200,
      textPrimary: const Color(0xFF0F172A),
      textSecondary: AppColors.slate600,
      textMuted: const Color(0xFF64748B),
      brandBlue: AppColors.pharmaBlue,
      brandBlueHover: AppColors.pharmaBlueDeep,
      brandGreen: AppColors.hospitalGreen,
      brandGreenHover: const Color(0xFF047857),
      posSuccess: AppColors.success,
      posWarning: AppColors.attention,
      posDanger: AppColors.critical,
      posInfo: AppColors.info,
      psychotropic: const Color(0xFF7C3AED),
      quarantine: const Color(0xFFEA580C),
      incineration: const Color(0xFFB91C1C),
      recall: const Color(0xFFCA8A04),
      radiusMd: 8,
      radiusXl: 16,
      radius2xl: 20,
      radius3xl: 32,
      minTouchTarget: DesignMetrics.minTouchTarget,
      iconMd: DesignMetrics.iconMd,
      iconSm: DesignMetrics.iconSm,
      avatarMd: DesignMetrics.avatarMd,
      topBarDesktop: DesignMetrics.topBarDesktop,
      topBarCompact: DesignMetrics.topBarCompact,
      posHeader: DesignMetrics.posHeader,
      posFooter: DesignMetrics.posFooter,
      sidebarExpanded: DesignMetrics.sidebarExpanded,
      sidebarCollapsed: DesignMetrics.sidebarCollapsed,
      contentMaxWidth: DesignMetrics.contentMaxWidth,
      density: density,
    );
  }

  @override
  PharmaTokens copyWith({
    Color? bgPrimary,
    Color? bgSecondary,
    Color? card,
    Color? cardHover,
    Color? border,
    Color? textPrimary,
    Color? textSecondary,
    Color? textMuted,
    Color? brandBlue,
    Color? brandBlueHover,
    Color? brandGreen,
    Color? brandGreenHover,
    Color? posSuccess,
    Color? posWarning,
    Color? posDanger,
    Color? posInfo,
    Color? psychotropic,
    Color? quarantine,
    Color? incineration,
    Color? recall,
    double? radiusMd,
    double? radiusXl,
    double? radius2xl,
    double? radius3xl,
    double? minTouchTarget,
    double? iconMd,
    double? iconSm,
    double? avatarMd,
    double? topBarDesktop,
    double? topBarCompact,
    double? posHeader,
    double? posFooter,
    double? sidebarExpanded,
    double? sidebarCollapsed,
    double? contentMaxWidth,
    DensityTokens? density,
  }) {
    return PharmaTokens(
      bgPrimary: bgPrimary ?? this.bgPrimary,
      bgSecondary: bgSecondary ?? this.bgSecondary,
      card: card ?? this.card,
      cardHover: cardHover ?? this.cardHover,
      border: border ?? this.border,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textMuted: textMuted ?? this.textMuted,
      brandBlue: brandBlue ?? this.brandBlue,
      brandBlueHover: brandBlueHover ?? this.brandBlueHover,
      brandGreen: brandGreen ?? this.brandGreen,
      brandGreenHover: brandGreenHover ?? this.brandGreenHover,
      posSuccess: posSuccess ?? this.posSuccess,
      posWarning: posWarning ?? this.posWarning,
      posDanger: posDanger ?? this.posDanger,
      posInfo: posInfo ?? this.posInfo,
      psychotropic: psychotropic ?? this.psychotropic,
      quarantine: quarantine ?? this.quarantine,
      incineration: incineration ?? this.incineration,
      recall: recall ?? this.recall,
      radiusMd: radiusMd ?? this.radiusMd,
      radiusXl: radiusXl ?? this.radiusXl,
      radius2xl: radius2xl ?? this.radius2xl,
      radius3xl: radius3xl ?? this.radius3xl,
      minTouchTarget: minTouchTarget ?? this.minTouchTarget,
      iconMd: iconMd ?? this.iconMd,
      iconSm: iconSm ?? this.iconSm,
      avatarMd: avatarMd ?? this.avatarMd,
      topBarDesktop: topBarDesktop ?? this.topBarDesktop,
      topBarCompact: topBarCompact ?? this.topBarCompact,
      posHeader: posHeader ?? this.posHeader,
      posFooter: posFooter ?? this.posFooter,
      sidebarExpanded: sidebarExpanded ?? this.sidebarExpanded,
      sidebarCollapsed: sidebarCollapsed ?? this.sidebarCollapsed,
      contentMaxWidth: contentMaxWidth ?? this.contentMaxWidth,
      density: density ?? this.density,
    );
  }

  @override
  PharmaTokens lerp(ThemeExtension<PharmaTokens>? other, double t) {
    if (other is! PharmaTokens) return this;
    return PharmaTokens(
      bgPrimary: Color.lerp(bgPrimary, other.bgPrimary, t)!,
      bgSecondary: Color.lerp(bgSecondary, other.bgSecondary, t)!,
      card: Color.lerp(card, other.card, t)!,
      cardHover: Color.lerp(cardHover, other.cardHover, t)!,
      border: Color.lerp(border, other.border, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      brandBlue: Color.lerp(brandBlue, other.brandBlue, t)!,
      brandBlueHover: Color.lerp(brandBlueHover, other.brandBlueHover, t)!,
      brandGreen: Color.lerp(brandGreen, other.brandGreen, t)!,
      brandGreenHover: Color.lerp(brandGreenHover, other.brandGreenHover, t)!,
      posSuccess: Color.lerp(posSuccess, other.posSuccess, t)!,
      posWarning: Color.lerp(posWarning, other.posWarning, t)!,
      posDanger: Color.lerp(posDanger, other.posDanger, t)!,
      posInfo: Color.lerp(posInfo, other.posInfo, t)!,
      psychotropic: Color.lerp(psychotropic, other.psychotropic, t)!,
      quarantine: Color.lerp(quarantine, other.quarantine, t)!,
      incineration: Color.lerp(incineration, other.incineration, t)!,
      recall: Color.lerp(recall, other.recall, t)!,
      radiusMd: lerpDouble(radiusMd, other.radiusMd, t)!,
      radiusXl: lerpDouble(radiusXl, other.radiusXl, t)!,
      radius2xl: lerpDouble(radius2xl, other.radius2xl, t)!,
      radius3xl: lerpDouble(radius3xl, other.radius3xl, t)!,
      minTouchTarget: lerpDouble(minTouchTarget, other.minTouchTarget, t)!,
      iconMd: lerpDouble(iconMd, other.iconMd, t)!,
      iconSm: lerpDouble(iconSm, other.iconSm, t)!,
      avatarMd: lerpDouble(avatarMd, other.avatarMd, t)!,
      topBarDesktop: lerpDouble(topBarDesktop, other.topBarDesktop, t)!,
      topBarCompact: lerpDouble(topBarCompact, other.topBarCompact, t)!,
      posHeader: lerpDouble(posHeader, other.posHeader, t)!,
      posFooter: lerpDouble(posFooter, other.posFooter, t)!,
      sidebarExpanded: lerpDouble(sidebarExpanded, other.sidebarExpanded, t)!,
      sidebarCollapsed: lerpDouble(sidebarCollapsed, other.sidebarCollapsed, t)!,
      contentMaxWidth: lerpDouble(contentMaxWidth, other.contentMaxWidth, t)!,
      density: t < 0.5 ? density : other.density,
    );
  }
}

extension PharmaTokensX on BuildContext {
  PharmaTokens get pharmaTokens =>
      Theme.of(this).extension<PharmaTokens>() ??
      PharmaTokens.enterpriseDark();
}
