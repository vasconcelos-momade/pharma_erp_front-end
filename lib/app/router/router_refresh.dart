import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_session_notifier.dart';

/// Notifica o [GoRouter] para voltar a avaliar [redirect] quando a sessão muda.
class GoRouterRefresh extends ChangeNotifier {
  void notify() => notifyListeners();
}

final routerRefreshProvider = Provider<GoRouterRefresh>((ref) {
  final refresh = GoRouterRefresh();
  ref.onDispose(refresh.dispose);
  ref.listen<AuthSessionState>(authSessionProvider, (previous, next) {
    refresh.notify();
  });
  return refresh;
});
