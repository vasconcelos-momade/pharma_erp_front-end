import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:responsive_framework/responsive_framework.dart';

import '../../app/providers/app_theme_mode_provider.dart';
import '../../app/providers/auth_session_notifier.dart';
import '../../app/router/routes.dart';
import '../../core/theme/design_tokens.dart';
import '../../core/theme/dimensions.dart';
import '../../core/theme/spacing.dart';
import '../responsive/pharma_screen_layout.dart';
import '../widgets/navigation/app_nav_config.dart';
import '../widgets/sync/sync_status_strip.dart';
import 'tablet_layout.dart';

/// Shell enterprise: sidebar animada, topbar, breadcrumbs, sync e adaptação tablet/mobile.
class DashboardLayout extends ConsumerStatefulWidget {
  const DashboardLayout({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<DashboardLayout> createState() => _DashboardLayoutState();
}

class _DashboardLayoutState extends ConsumerState<DashboardLayout> {
  bool _sidebarExpanded = true;
  final GlobalKey<ScaffoldState> _shellKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final location = GoRouterState.of(context).uri.path;
    final bp = ResponsiveBreakpoints.of(context);
    final isDesktop = bp.largerOrEqualTo(DESKTOP);
    final isTablet = bp.equals(TABLET);
    final isMobile = PharmaScreenLayout.isMobile(context);

    if (!isDesktop) {
      _sidebarExpanded = false;
    }

    Widget body = Padding(
      padding: PharmaScreenLayout.pagePadding(context),
      child: widget.child,
    );

    if (isTablet && !isDesktop) {
      body = TabletLayout(child: body);
    }

    return Scaffold(
      key: _shellKey,
      backgroundColor: t.bgPrimary,
      drawer: _DrawerNav(
        location: location,
        onSelect: (path) {
          context.go(path);
          Navigator.of(context).pop();
        },
        onLogout: () => _logout(context),
      ),
      body: Row(
        children: [
          if (isDesktop)
            _Sidebar(
              location: location,
              expanded: _sidebarExpanded,
              onToggle: () => setState(() => _sidebarExpanded = !_sidebarExpanded),
              onLogout: () => _logout(context),
            ),
          Expanded(
            child: Column(
              children: [
                _EnterpriseTopBar(
                  isDesktop: isDesktop,
                  isMobile: isMobile,
                  location: location,
                  onLogout: () => _logout(context),
                  onOpenDrawer: () => _shellKey.currentState?.openDrawer(),
                ),
                Expanded(
                  child: Container(
                    color: t.bgPrimary,
                    child: body,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: isMobile
          ? Theme(
              data: Theme.of(context).copyWith(
                navigationBarTheme: NavigationBarThemeData(
                  height: AppDimensions.topBarCompact,
                  indicatorColor: t.brandGreen.withValues(alpha: 0.2),
                ),
              ),
              child: NavigationBar(
                height: AppDimensions.topBarCompact,
                labelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
                selectedIndex: _bottomNavIndex(location),
                onDestinationSelected: (i) {
                  if (i == 4) {
                    _shellKey.currentState?.openDrawer();
                    return;
                  }
                  switch (i) {
                    case 0:
                      context.go(AppRoutePaths.dashboard);
                      break;
                    case 1:
                      context.go(AppRoutePaths.pos);
                      break;
                    case 2:
                      context.go(AppRoutePaths.inventory);
                      break;
                    case 3:
                      context.go(AppRoutePaths.financial);
                      break;
                  }
                },
                destinations: [
                  NavigationDestination(
                    tooltip: 'Painel',
                    icon: Icon(Icons.dashboard_outlined, color: t.textSecondary),
                    selectedIcon: Icon(Icons.dashboard, color: t.brandGreen),
                    label: '',
                  ),
                  NavigationDestination(
                    tooltip: 'PDV',
                    icon: Icon(Icons.point_of_sale_outlined, color: t.textSecondary),
                    selectedIcon: Icon(Icons.point_of_sale, color: t.brandGreen),
                    label: '',
                  ),
                  NavigationDestination(
                    tooltip: 'Stock',
                    icon: Icon(Icons.inventory_2_outlined, color: t.textSecondary),
                    selectedIcon: Icon(Icons.inventory_2, color: t.brandGreen),
                    label: '',
                  ),
                  NavigationDestination(
                    tooltip: 'Finanças',
                    icon: Icon(Icons.payments_outlined, color: t.textSecondary),
                    selectedIcon: Icon(Icons.payments, color: t.brandGreen),
                    label: '',
                  ),
                  NavigationDestination(
                    tooltip: 'Menu',
                    icon: Icon(Icons.menu_rounded, color: t.textSecondary),
                    selectedIcon: Icon(Icons.menu_open_rounded, color: t.brandGreen),
                    label: '',
                  ),
                ],
              ),
            )
          : null,
    );
  }

  int _bottomNavIndex(String path) {
    if (path == AppRoutePaths.dashboard || path.startsWith('/dashboard')) return 0;
    if (path == AppRoutePaths.pos) return 1;
    if (path == AppRoutePaths.inventory || path.startsWith('/pharmacy')) return 2;
    if (path == AppRoutePaths.financial || path.startsWith('/finance')) return 3;
    return 4;
  }

  void _logout(BuildContext context) {
    ref.read(authSessionProvider.notifier).signOut();
    context.go(AppRoutePaths.login);
  }
}

class _EnterpriseTopBar extends ConsumerWidget {
  const _EnterpriseTopBar({
    required this.isDesktop,
    required this.isMobile,
    required this.location,
    required this.onLogout,
    required this.onOpenDrawer,
  });

  final bool isDesktop;
  final bool isMobile;
  final String location;
  final VoidCallback onLogout;
  final VoidCallback onOpenDrawer;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.pharmaTokens;
    final mode = ref.watch(appThemeModeProvider);
    final section = AppRouteTitles.sectionFor(location);
    final title = AppRouteTitles.titleFor(location);
    final compactSync = isMobile || MediaQuery.sizeOf(context).width < 520;

    return Material(
      color: t.bgPrimary.withValues(alpha: 0.94),
      child: Container(
        height: isDesktop ? AppDimensions.topBarDesktop : AppDimensions.topBarCompact,
        padding: EdgeInsets.symmetric(horizontal: isDesktop ? AppSpacing.xxxl : (isMobile ? AppSpacing.sm : AppSpacing.md)),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: t.border.withValues(alpha: 0.55))),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isMobile ? 0.12 : 0.25),
              blurRadius: isMobile ? 8 : 18,
              offset: Offset(0, isMobile ? 2 : 6),
            ),
          ],
        ),
        child: Row(
          children: [
            if (!isDesktop)
              IconButton(
                constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                padding: EdgeInsets.zero,
                tooltip: 'Menu',
                icon: Icon(Icons.menu_rounded, color: t.textSecondary, size: isMobile ? 22 : 24),
                onPressed: onOpenDrawer,
              ),
            Expanded(
              flex: isDesktop ? 2 : 1,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isMobile)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          section.toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: t.brandBlue,
                                letterSpacing: 1.2,
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                color: t.textPrimary,
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                              ),
                        ),
                      ],
                    )
                  else
                    Row(
                      children: [
                        Text(
                          'Pharma ERP',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: t.textMuted,
                                letterSpacing: 2,
                              ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                          child: Icon(Icons.chevron_right_rounded, size: 16, color: t.border),
                        ),
                        Flexible(
                          child: Text(
                            section.toUpperCase(),
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: t.brandBlue,
                                  letterSpacing: 1.6,
                                ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                          child: Icon(Icons.chevron_right_rounded, size: 16, color: t.border),
                        ),
                        Flexible(
                          child: Text(
                            title,
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  color: t.textPrimary,
                                  fontWeight: FontWeight.w700,
                                ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            if (isDesktop)
              SizedBox(
                width: 300,
                child: TextField(
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: t.textPrimary,
                      ),
                  decoration: InputDecoration(
                    hintText: 'Pesquisa global (Ctrl+K)',
                    prefixIcon: Icon(Icons.search_rounded, size: 20, color: t.textMuted),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: AppSpacing.md, horizontal: AppSpacing.md),
                  ),
                ),
              ),
            Flexible(
              fit: FlexFit.loose,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                reverse: false,
                padding: EdgeInsets.zero,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isDesktop) const SizedBox(width: AppSpacing.md),
                    if (!isDesktop) const SizedBox(width: AppSpacing.xs),
                    IconButton(
                      constraints: BoxConstraints(
                        minWidth: t.minTouchTarget,
                        minHeight: t.minTouchTarget,
                      ),
                      padding: EdgeInsets.zero,
                      tooltip: 'Notificações',
                      onPressed: () {},
                      icon: Badge(
                        label: const Text('3', style: TextStyle(fontSize: 9)),
                        child: Icon(Icons.notifications_none_rounded, color: t.textSecondary, size: t.iconMd),
                      ),
                    ),
                    IconButton(
                      constraints: BoxConstraints(
                        minWidth: t.minTouchTarget,
                        minHeight: t.minTouchTarget,
                      ),
                      padding: EdgeInsets.zero,
                      tooltip: mode == ThemeMode.dark ? 'Tema claro' : 'Tema escuro',
                      onPressed: () {
                        ref.read(appThemeModeProvider.notifier).toggle();
                      },
                      icon: Icon(
                        mode == ThemeMode.dark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                        color: t.textSecondary,
                        size: t.iconMd,
                      ),
                    ),
                    PopupMenuButton<String>(
                      padding: EdgeInsets.zero,
                      constraints: BoxConstraints(
                        minWidth: t.minTouchTarget,
                        minHeight: t.minTouchTarget,
                      ),
                      tooltip: 'Conta',
                      child: CircleAvatar(
                        radius: isMobile ? 15 : 18,
                        backgroundColor: t.brandGreen.withValues(alpha: 0.2),
                        child: Text(
                          'OP',
                          style: TextStyle(fontSize: isMobile ? 9 : 11, fontWeight: FontWeight.w900, color: t.brandGreen),
                        ),
                      ),
                      onSelected: (v) {
                        if (v == 'logout') onLogout();
                        if (v == 'settings') context.go(AppRoutePaths.settings);
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(value: 'profile', child: Text('Perfil')),
                        const PopupMenuItem(value: 'settings', child: Text('Configurações')),
                        const PopupMenuDivider(),
                        const PopupMenuItem(value: 'logout', child: Text('Sair')),
                      ],
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    SyncStatusStrip(compact: compactSync),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({
    required this.location,
    required this.expanded,
    required this.onToggle,
    required this.onLogout,
  });

  final String location;
  final bool expanded;
  final VoidCallback onToggle;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final w = expanded ? AppDimensions.sidebarExpanded : AppDimensions.sidebarCollapsed;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
      width: w,
      color: t.bgSecondary,
      child: Column(
        children: [
          SizedBox(
            height: AppDimensions.topBarDesktop,
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (expanded)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                    child: Row(
                      children: [
                        Container(
                          width: t.avatarMd,
                          height: t.avatarMd,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [t.brandBlue, t.brandGreen],
                            ),
                            borderRadius: BorderRadius.circular(t.radiusMd),
                            boxShadow: [
                              BoxShadow(color: t.brandBlue.withValues(alpha: 0.35), blurRadius: 14),
                            ],
                          ),
                          child: Icon(Icons.local_pharmacy_rounded, color: t.bgPrimary, size: 22),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Pharma ERP',
                                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                      color: t.textPrimary,
                                      fontWeight: FontWeight.w800,
                                    ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                'Offline-first • Multi-tenant',
                                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                      color: t.textMuted,
                                      letterSpacing: 0.6,
                                    ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Container(
                    width: t.minTouchTarget,
                    height: t.minTouchTarget,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [t.brandBlue, t.brandGreen]),
                      borderRadius: BorderRadius.circular(t.radiusMd),
                    ),
                    child: Icon(Icons.local_pharmacy_rounded, color: t.bgPrimary, size: t.iconMd),
                  ),
                Positioned(
                  right: -6,
                  child: IconButton(
                    style: IconButton.styleFrom(
                      backgroundColor: t.card,
                      side: BorderSide(color: t.border),
                    ),
                    onPressed: onToggle,
                    icon: Icon(
                      expanded ? Icons.chevron_left_rounded : Icons.chevron_right_rounded,
                      size: 18,
                      color: t.textMuted,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: t.border.withValues(alpha: 0.45)),
          Expanded(child: _NavList(location: location, expanded: expanded)),
          Divider(height: 1, color: t.border.withValues(alpha: 0.45)),
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: expanded ? AppSpacing.lg : AppSpacing.xs,
              vertical: AppSpacing.sm,
            ),
            child: expanded
                ? OutlinedButton.icon(
                    onPressed: onLogout,
                    icon: Icon(Icons.logout_rounded, size: 18, color: t.posDanger),
                    label: Text(
                      'Encerrar sessão',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(color: t.posDanger),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: t.posDanger.withValues(alpha: 0.35)),
                      backgroundColor: t.posDanger.withValues(alpha: 0.06),
                    ),
                  )
                : Tooltip(
                    message: 'Encerrar sessão',
                    child: OutlinedButton(
                      onPressed: onLogout,
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: t.posDanger.withValues(alpha: 0.35)),
                        backgroundColor: t.posDanger.withValues(alpha: 0.06),
                      ),
                      child: Icon(Icons.logout_rounded, size: 18, color: t.posDanger),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _NavList extends StatelessWidget {
  const _NavList({required this.location, required this.expanded});

  final String location;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    String? lastSection;
    final children = <Widget>[];
    for (final item in kAppNavItems) {
      if (item.section != null && item.section != lastSection && expanded) {
        lastSection = item.section;
        children.add(
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.xl, AppSpacing.lg, AppSpacing.sm),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.section!.toUpperCase(),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: t.textMuted,
                        letterSpacing: 2.4,
                      ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Container(
                  height: 2,
                  width: 36,
                  decoration: BoxDecoration(
                    color: t.brandBlue.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            ),
          ),
        );
      }
      final active = location == item.path;
      children.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
          child: Material(
            color: active ? t.brandGreen.withValues(alpha: 0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(t.radiusMd),
            child: InkWell(
              borderRadius: BorderRadius.circular(t.radiusMd),
              onTap: () => context.go(item.path),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.md),
                child: Row(
                  children: [
                    if (active)
                      Container(
                        width: 3,
                        height: 28,
                        margin: const EdgeInsets.only(right: AppSpacing.sm),
                        decoration: BoxDecoration(
                          color: t.brandGreen,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    Icon(item.icon, size: 22, color: active ? t.brandGreen : t.textSecondary),
                    if (expanded) ...[
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Text(
                          item.label,
                          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                color: active ? t.brandGreen : t.textSecondary,
                                letterSpacing: 0.4,
                              ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }
    return ListView(children: children);
  }
}

class _DrawerNav extends StatelessWidget {
  const _DrawerNav({
    required this.location,
    required this.onSelect,
    required this.onLogout,
  });

  final String location;
  final ValueChanged<String> onSelect;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    return Drawer(
      backgroundColor: t.bgSecondary,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Row(
                children: [
                  Container(
                    width: t.minTouchTarget,
                    height: t.minTouchTarget,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [t.brandBlue, t.brandGreen]),
                      borderRadius: BorderRadius.circular(t.radiusMd),
                    ),
                    child: Icon(Icons.local_pharmacy_rounded, color: t.bgPrimary, size: t.iconMd),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      'Pharma ERP',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                    ),
                  ),
                  IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                children: [
                  for (final item in kAppNavItems)
                    Material(
                      color: location == item.path ? t.brandGreen.withValues(alpha: 0.1) : Colors.transparent,
                      child: ListTile(
                        leading: Icon(item.icon, color: location == item.path ? t.brandGreen : t.textSecondary),
                        title: Text(
                          item.label,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: location == item.path ? t.brandGreen : t.textPrimary,
                          ),
                        ),
                        selected: location == item.path,
                        onTap: () => onSelect(item.path),
                      ),
                    ),
                ],
              ),
            ),
            Material(
              color: Colors.transparent,
              child: ListTile(
                leading: Icon(Icons.logout_rounded, color: t.posDanger),
                title: Text('Sair', style: TextStyle(color: t.posDanger, fontWeight: FontWeight.w700)),
                onTap: onLogout,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
