#!/usr/bin/env bash
# Arranque web rápido — NÃO volta a resolver/baixar pacotes (use dev_web.sh --deps se mudou pubspec).
# Uso: bash scripts/run_web.sh

set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

PORT="${WEB_PORT:-5000}"

exec flutter run -d chrome --no-pub --web-port="$PORT" "$@"
