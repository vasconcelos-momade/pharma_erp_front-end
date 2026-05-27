#!/usr/bin/env bash
# Desenvolvimento web sem voltar a correr pub get em cada arranque.
# Primeira vez (ou após alterar pubspec): bash scripts/dev_web.sh --deps

set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

PORT="${WEB_PORT:-5000}"
EXTRA_ARGS=()

if [[ "${1:-}" == "--deps" ]]; then
  flutter pub get
  shift
fi

EXTRA_ARGS+=(--no-pub --web-port="$PORT")

exec flutter run -d chrome "${EXTRA_ARGS[@]}" "$@"
