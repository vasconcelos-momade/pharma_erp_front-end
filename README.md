# pharma_erp

ERP para farmácia em **Flutter** — arranque modular (auth, farmácia, vendas/PDV, stock, finanças, auditoria, etc.).

## Documentação da estrutura

- **Português:** [docs/estrutura_do_projecto.md](docs/estrutura_do_projecto.md) — guia completo, diagrama de dependências e **índice em árvore** de `lib/`.
- **English:** [docs/project_structure.md](docs/project_structure.md) — same guide in English (including the tree).
- **UI React → Flutter:** [docs/ui_react_para_flutter.md](docs/ui_react_para_flutter.md) — design system, responsividade, mapeamento do protótipo `pharmaerp-moçambique (2)/`.

## Arranque rápido

```bash
# Uma vez (ou após mudar pubspec.yaml / pubspec.lock)
flutter pub get

# Web Chrome na porta 5000 — sem repetir "Downloading packages..." em cada run
flutter run -d chrome --web-port=5000 --no-pub

# Ou script equivalente
bash scripts/dev_web.sh
# Após alterar dependências:
bash scripts/dev_web.sh --deps
```

No Cursor/VS Code, use a configuracao **pharma_erp (Web — Chrome, port 5000)** (ja inclui `--no-pub` e `--web-port=5000`).

Variáveis locais: copie ou crie um ficheiro **`.env`** na raiz (não é versionado; ver `.gitignore`). Os valores podem ser lidos em `lib/core/config/env.dart` à medida que configurar o projecto.

## Testes

```bash
flutter test
flutter test integration_test/
```

`test/ui_shell_test.dart` cobre o fluxo de **login → dashboard** e **navegação para inventário** (GoRouter + Riverpod).

## Recursos Flutter

- [Documentação Flutter](https://docs.flutter.dev/)
- [Codelab inicial](https://docs.flutter.dev/get-started/codelab)
- [Cookbook](https://docs.flutter.dev/cookbook)
