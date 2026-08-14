#!/usr/bin/env bash
# Copy root .env → assets/env/.env so device builds get secrets.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
if [[ ! -f "$ROOT/.env" ]]; then
  echo "Missing $ROOT/.env — copy from .env.example and fill SUPABASE_*"
  exit 1
fi
mkdir -p "$ROOT/assets/env"
cp "$ROOT/.env" "$ROOT/assets/env/.env"
echo "Synced .env → assets/env/.env (gitignored). Full restart app after this."
