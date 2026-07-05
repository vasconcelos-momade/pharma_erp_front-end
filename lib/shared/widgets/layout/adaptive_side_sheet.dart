import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/extensions.dart';

/// Largura do painel lateral conforme o prompt (tablet vs desktop).
abstract final class AdaptiveSideSheetMetrics {
  AdaptiveSideSheetMetrics._();

  static const double mobileBreakpoint = 768;
  static const double desktopBreakpoint = 1200;
  static const double tabletWidth = 480;
  static const double desktopWidth = 640;
  static const double backdropOpacity = 0.38;

  static double panelWidthForScreen(double screenWidth) {
    if (screenWidth >= desktopBreakpoint) return desktopWidth;
    return tabletWidth;
  }
}

/// Side Sheet Material 3 com Stack + animação horizontal (sem Dialog).
class AdaptiveSideSheet {
  AdaptiveSideSheet._();

  static Future<T?> show<T>({
    required BuildContext context,
    required WidgetBuilder builder,
    double? width,
    bool barrierDismissible = true,
  }) {
    final overlay = Overlay.of(context, rootOverlay: true);
    final completer = Completer<T?>();
    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (overlayContext) => _AdaptiveSideSheetOverlay<T>(
        width: width ??
            AdaptiveSideSheetMetrics.panelWidthForScreen(
              MediaQuery.sizeOf(overlayContext).width,
            ),
        barrierDismissible: barrierDismissible,
        onClosed: (result) {
          entry.remove();
          if (!completer.isCompleted) {
            completer.complete(result);
          }
        },
        child: Builder(builder: builder),
      ),
    );

    overlay.insert(entry);
    return completer.future;
  }
}

class _AdaptiveSideSheetOverlay<T> extends StatefulWidget {
  const _AdaptiveSideSheetOverlay({
    required this.width,
    required this.barrierDismissible,
    required this.onClosed,
    required this.child,
  });

  final double width;
  final bool barrierDismissible;
  final void Function(T? result) onClosed;
  final Widget child;

  @override
  State<_AdaptiveSideSheetOverlay<T>> createState() =>
      _AdaptiveSideSheetOverlayState<T>();
}

class _AdaptiveSideSheetOverlayState<T> extends State<_AdaptiveSideSheetOverlay<T>>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _slide;
  bool _closing = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Motion.durationNormal,
      reverseDuration: Motion.durationFast,
    );
    _slide = Tween<Offset>(
      begin: const Offset(1, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Motion.emphasized));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _close([T? result]) async {
    if (_closing) return;
    _closing = true;
    await _controller.reverse();
    widget.onClosed(result);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final scheme = Theme.of(context).colorScheme;
    final elevation = context.elevationTokens.level8;

    return Positioned.fill(
      child: Material(
        type: MaterialType.transparency,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Positioned.fill(
              child: FadeTransition(
                opacity: CurvedAnimation(
                  parent: _controller,
                  curve: Curves.easeOut,
                ),
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: widget.barrierDismissible ? () => _close() : null,
                  child: ColoredBox(
                    color: scheme.scrim.withValues(
                      alpha: AdaptiveSideSheetMetrics.backdropOpacity,
                    ),
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: Align(
                alignment: Alignment.centerRight,
                child: SlideTransition(
                  position: _slide,
                  child: SafeArea(
                    child: SizedBox(
                      width: widget.width,
                      height: double.infinity,
                      child: Material(
                        color: t.bgPrimary,
                        elevation: elevation,
                        shadowColor: scheme.shadow.withValues(alpha: 0.22),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: t.bgPrimary,
                            border: Border(
                              left: BorderSide(
                                color: t.border.withValues(alpha: 0.45),
                              ),
                            ),
                            boxShadow: AppShadows.dialog(context),
                          ),
                          child: _AdaptiveSideSheetScope(
                            close: ([result]) => _close(result as T?),
                            child: widget.child,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdaptiveSideSheetScope extends InheritedWidget {
  const _AdaptiveSideSheetScope({
    required this.close,
    required super.child,
  });

  final Future<void> Function([Object? result]) close;

  static _AdaptiveSideSheetScope? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<_AdaptiveSideSheetScope>();
  }

  @override
  bool updateShouldNotify(_AdaptiveSideSheetScope oldWidget) => false;
}

/// Fecha o side sheet activo (se existir) com resultado opcional.
Future<void> closeAdaptiveSideSheet<T>(BuildContext context, [T? result]) {
  final scope = _AdaptiveSideSheetScope.maybeOf(context);
  return scope?.close(result) ?? Future.value();
}

/// Indica se o [context] está dentro de um [AdaptiveSideSheet].
bool isInsideAdaptiveSideSheet(BuildContext context) {
  return _AdaptiveSideSheetScope.maybeOf(context) != null;
}
