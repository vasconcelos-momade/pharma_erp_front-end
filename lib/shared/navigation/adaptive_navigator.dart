import 'package:flutter/material.dart';

import '../../core/theme/breakpoints.dart';
import '../widgets/dialogs/pharma_responsive_dialog.dart';
import '../widgets/layout/adaptive_side_sheet.dart';

/// Callback para construir painéis de detalhe / histórico.
typedef AdaptiveDetailBuilder = Widget Function(
  BuildContext context,
  VoidCallback onClose,
);

/// Callback para construir formulários em modo incorporado (sem container).
typedef AdaptiveEmbeddedFormBuilder = Widget Function(
  BuildContext context, {
  required bool embedded,
});

/// Navegação adaptativa conforme o padrão do ERP.
abstract final class AdaptiveNavigator {
  AdaptiveNavigator._();

  static const double _mobileBreakpoint = AdaptiveSideSheetMetrics.mobileBreakpoint;

  static double widthOf(BuildContext context) => MediaQuery.sizeOf(context).width;

  static bool isMobile(BuildContext context) =>
      widthOf(context) < _mobileBreakpoint;

  static bool isDesktop(BuildContext context) =>
      widthOf(context) >= Breakpoints.desktop;

  static bool isTablet(BuildContext context) =>
      !isMobile(context) && !isDesktop(context);

  static bool useSideSheet(BuildContext context) => !isMobile(context);

  /// Completa formulário / painel (Dialog, Side Sheet ou rota mobile).
  static void complete<T>(BuildContext context, [T? result]) {
    if (isInsideAdaptiveSideSheet(context)) {
      closeAdaptiveSideSheet<T>(context, result);
      return;
    }
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop<T>(result);
    }
  }

  /// Cancela formulário / painel actual.
  static void cancel(BuildContext context) => complete<void>(context);

  /// Detalhes / Histórico — Side Sheet (tablet/desktop) ou página (mobile).
  static Future<T?> openPanel<T>({
    required BuildContext context,
    required WidgetBuilder builder,
    double? sideSheetWidth,
    bool barrierDismissible = true,
    RouteSettings? routeSettings,
  }) {
    return open<T>(
      context: context,
      builder: builder,
      sideSheetWidth: sideSheetWidth,
      barrierDismissible: barrierDismissible,
      routeSettings: routeSettings,
    );
  }

  /// Detalhe com [Scaffold] automático no mobile.
  static Future<void> openDetail({
    required BuildContext context,
    required String title,
    required AdaptiveDetailBuilder builder,
    RouteSettings? routeSettings,
    double? sideSheetWidth,
    bool barrierDismissible = true,
  }) {
    return openPanel<void>(
      context: context,
      routeSettings: routeSettings,
      sideSheetWidth: sideSheetWidth,
      barrierDismissible: barrierDismissible,
      builder: (detailContext) {
        void onClose() => close(detailContext);
        if (isMobile(detailContext)) {
          return Scaffold(
            appBar: AppBar(title: Text(title)),
            body: builder(detailContext, onClose),
          );
        }
        return builder(detailContext, onClose);
      },
    );
  }

  /// Novo / Editar — Dialog (desktop), Side Sheet (tablet) ou página (mobile).
  static Future<T?> openForm<T>({
    required BuildContext context,
    required Widget title,
    required WidgetBuilder contentBuilder,
    bool barrierDismissible = true,
    RouteSettings? routeSettings,
    double? sideSheetWidth,
  }) {
    if (isMobile(context)) {
      return Navigator.of(context, rootNavigator: true).push<T>(
        MaterialPageRoute<T>(
          settings: routeSettings,
          builder: contentBuilder,
        ),
      );
    }

    if (isDesktop(context)) {
      return showPharmaResponsiveDialog<T>(
        context: context,
        barrierDismissible: barrierDismissible,
        builder: (dialogContext) => PharmaResponsiveDialog(
          title: title,
          content: contentBuilder(dialogContext),
          scrollable: true,
        ),
      );
    }

    return AdaptiveSideSheet.show<T>(
      context: context,
      width: sideSheetWidth,
      barrierDismissible: barrierDismissible,
      builder: (sheetContext) => _AdaptiveFormSheetChrome(
        title: title,
        onClose: () => closeAdaptiveSideSheet<T>(sheetContext),
        child: contentBuilder(sheetContext),
      ),
    );
  }

  /// Formulário com corpo incorporável (sem [PharmaResponsiveDialog] duplicado).
  static Future<T?> openEmbeddedForm<T>({
    required BuildContext context,
    required Widget title,
    required AdaptiveEmbeddedFormBuilder formBuilder,
    RouteSettings? routeSettings,
    double? sideSheetWidth,
    bool barrierDismissible = true,
  }) {
    return openForm<T>(
      context: context,
      title: title,
      routeSettings: routeSettings,
      sideSheetWidth: sideSheetWidth,
      barrierDismissible: barrierDismissible,
      contentBuilder: (formContext) {
        final form = formBuilder(formContext, embedded: true);
        if (isMobile(formContext)) {
          return Scaffold(
            appBar: AppBar(
              title: title is Text ? title : const Text('Formulário'),
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: form,
            ),
          );
        }
        return form;
      },
    );
  }

  /// Desktop/Tablet → [AdaptiveSideSheet]; Mobile → push no [rootNavigator].
  static Future<T?> open<T>({
    required BuildContext context,
    required WidgetBuilder builder,
    double? sideSheetWidth,
    bool barrierDismissible = true,
    RouteSettings? routeSettings,
    bool fullscreenDialog = false,
  }) {
    if (useSideSheet(context)) {
      return AdaptiveSideSheet.show<T>(
        context: context,
        builder: builder,
        width: sideSheetWidth,
        barrierDismissible: barrierDismissible,
      );
    }

    return Navigator.of(context, rootNavigator: true).push<T>(
      MaterialPageRoute<T>(
        settings: routeSettings,
        fullscreenDialog: fullscreenDialog,
        builder: builder,
      ),
    );
  }

  /// Fecha a rota actual, side sheet ou dialog.
  static void close<T>(BuildContext context, [T? result]) {
    if (isInsideAdaptiveSideSheet(context)) {
      closeAdaptiveSideSheet<T>(context, result);
      return;
    }
    final navigator = Navigator.of(context, rootNavigator: true);
    if (navigator.canPop()) {
      navigator.pop<T>(result);
    } else {
      Navigator.of(context).maybePop<T>(result);
    }
  }
}

class _AdaptiveFormSheetChrome extends StatelessWidget {
  const _AdaptiveFormSheetChrome({
    required this.title,
    required this.onClose,
    required this.child,
  });

  final Widget title;
  final VoidCallback onClose;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
          child: Row(
            children: [
              Expanded(
                child: DefaultTextStyle.merge(
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                  child: title,
                ),
              ),
              IconButton(
                tooltip: 'Fechar',
                onPressed: onClose,
                icon: const Icon(Icons.close),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: child,
          ),
        ),
      ],
    );
  }
}
