import 'package:flutter/foundation.dart';

/// Host da API sem prefixo `/api/v1` (porta 3300 por defeito no Docker).
abstract final class ApiHostResolver {
  ApiHostResolver._();

  static const int defaultPort = 3300;

  /// Valor de `--dart-define=API_BASE_URL=...` ou host por plataforma.
  static String get defaultHost {
    const fromDefine = String.fromEnvironment('API_BASE_URL');
    if (fromDefine.isNotEmpty) {
      return fromDefine;
    }
    return _platformDefaultHost();
  }

  static String get defaultCloudHost {
    const fromDefine = String.fromEnvironment('API_CLOUD_URL');
    if (fromDefine.isNotEmpty) {
      return fromDefine;
    }
    return defaultHost;
  }

  static String _platformDefaultHost() {
    if (kIsWeb) {
      // No browser, 127.0.0.1 aponta para a máquina do utilizador.
      // Usamos o host actual (onde o web app está a correr) e a porta da API.
      final scheme = Uri.base.scheme.isEmpty ? 'http' : Uri.base.scheme;
      final host = Uri.base.host.isEmpty ? '127.0.0.1' : Uri.base.host;
      return '$scheme://$host:$defaultPort';
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        // Emulador Android: localhost do host é 10.0.2.2
        return 'http://10.0.2.2:$defaultPort';
      default:
        return 'http://127.0.0.1:$defaultPort';
    }
  }

  /// Dica curta para o ecrã de login quando a ligação falha.
  static String connectionHintForPlatform() {
    if (kIsWeb) {
      return 'Web: a API deve estar acessível no mesmo host (porta 3300). Se estiver a abrir o web app a partir de outra máquina, use o IP do servidor ou passe --dart-define=API_BASE_URL=...';
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'Android: emulador usa 10.0.2.2:3300; dispositivo físico precisa do IP da máquina na LAN.';
      default:
        return 'Desktop: API em 127.0.0.1:3300 (docker compose up na pasta do backend).';
    }
  }
}
