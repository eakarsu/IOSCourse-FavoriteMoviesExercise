#!/usr/bin/env bash
set -euo pipefail
project_dir="$(cd "$(dirname "$0")" && pwd)"
cd "$project_dir"

load_env_file() {
  local line key value
  while IFS= read -r line || [ -n "$line" ]; do
    [[ "$line" =~ ^[[:space:]]*# || "$line" =~ ^[[:space:]]*$ ]] && continue
    line="${line#export }"; key="${line%%=*}"; value="${line#*=}"; key="${key//[[:space:]]/}"
    [[ "$key" =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]] || continue
    [ -n "${!key+x}" ] && continue
    if [[ "$value" == \"*\" && "$value" == *\" ]]; then value="${value:1:${#value}-2}"; fi
    export "$key=$value"
  done < .env
}

[ -f .env ] || { printf 'Missing required .env file.\n' >&2; exit 1; }
load_env_file
: "${BACKEND_PORT:?BACKEND_PORT is required}"
: "${FRONTEND_PORT:?FRONTEND_PORT is required}"
: "${DATABASE_URL:?DATABASE_URL is required}"
: "${PROVISION_ADMIN_EMAIL:?PROVISION_ADMIN_EMAIL is required}"
: "${PROVISION_ADMIN_PASSWORD:?PROVISION_ADMIN_PASSWORD is required}"
: "${OPENROUTER_API_KEY:?OPENROUTER_API_KEY is required}"
: "${OPENROUTER_MODEL:?OPENROUTER_MODEL is required}"
: "${OPENROUTER_BASE_URL:?OPENROUTER_BASE_URL is required}"
[ ${#PROVISION_ADMIN_PASSWORD} -ge 16 ] && [[ ! "$PROVISION_ADMIN_PASSWORD" =~ replace|placeholder|change-me ]] || { printf 'PROVISION_ADMIN_PASSWORD must be a non-placeholder value of at least 16 characters.\n' >&2; exit 1; }
[[ "$OPENROUTER_API_KEY" != replace-* && "$OPENROUTER_MODEL" != replace-* ]] || { printf 'OPENROUTER_API_KEY and OPENROUTER_MODEL must be approved non-placeholder values.\n' >&2; exit 1; }
[ "$OPENROUTER_BASE_URL" = 'https://openrouter.ai/api/v1' ] || { printf 'OPENROUTER_BASE_URL must be https://openrouter.ai/api/v1.\n' >&2; exit 1; }
[ "$BACKEND_PORT" != "$FRONTEND_PORT" ] || { printf 'BACKEND_PORT and FRONTEND_PORT must be distinct.\n' >&2; exit 1; }
for name in BACKEND_PORT FRONTEND_PORT; do
  port="${!name}"
  [[ "$port" =~ ^[0-9]+$ ]] && (( port >= 1024 && port <= 65535 )) || { printf '%s must be an assigned numeric port from 1024 through 65535.\n' "$name" >&2; exit 1; }
  if lsof -tiTCP:"$port" -sTCP:LISTEN >/dev/null 2>&1; then printf 'Port %s is occupied.\n' "$port" >&2; exit 1; fi
done

node runtime/setup.mjs
node runtime/api.mjs & api_pid=$!
node runtime/ui.mjs & ui_pid=$!
cleanup() { kill "$api_pid" "$ui_pid" 2>/dev/null || true; wait "$api_pid" "$ui_pid" 2>/dev/null || true; }
trap cleanup EXIT
trap 'exit 0' INT TERM
while kill -0 "$api_pid" 2>/dev/null && kill -0 "$ui_pid" 2>/dev/null; do sleep 1; done
exit 1
