#!/usr/bin/env bash
# Configure DeepSeek Harness with Grok as primary and OpenRouter as fallback.
# Keys are read from environment variables (never written into settings.yaml).
#
# Usage:
#   configure-dsh-providers.sh [grok|openrouter]
# The optional argument forces the default provider. Otherwise Grok is preferred
# when GROK_API_KEY is set, and OpenRouter is used if only that key is present.
set -euo pipefail

DSH_HOME="${DSH_HOME:-${HOME}/.dsh}"
GROK_BASE_URL="${GROK_BASE_URL:-https://api.picpi.top/v1}"
GROK_MODEL="${GROK_MODEL:-grok-4.6}"
OPENROUTER_BASE_URL="${OPENROUTER_BASE_URL:-https://openrouter.ai/api/v1}"
OPENROUTER_MODEL="${OPENROUTER_MODEL:-nvidia/nemotron-3-ultra-550b-a55b:free}"
REQUESTED_DEFAULT="${1:-}"

mkdir -p "$DSH_HOME"

if [ -z "${GROK_API_KEY:-}" ] && [ -z "${OPENROUTER_API_KEY:-}" ]; then
  echo "Neither GROK_API_KEY nor OPENROUTER_API_KEY is set" >&2
  exit 1
fi

has_grok=0
has_openrouter=0
[ -n "${GROK_API_KEY:-}" ] && has_grok=1
[ -n "${OPENROUTER_API_KEY:-}" ] && has_openrouter=1

if [ "$REQUESTED_DEFAULT" = "openrouter" ]; then
  if [ "$has_openrouter" -ne 1 ]; then
    echo "Requested OpenRouter default but OPENROUTER_API_KEY is not set" >&2
    exit 1
  fi
  DEFAULT_PROVIDER="openrouter"
  DEFAULT_MODEL="$OPENROUTER_MODEL"
elif [ "$REQUESTED_DEFAULT" = "grok" ]; then
  if [ "$has_grok" -ne 1 ]; then
    echo "Requested Grok default but GROK_API_KEY is not set" >&2
    exit 1
  fi
  DEFAULT_PROVIDER="grok"
  DEFAULT_MODEL="$GROK_MODEL"
elif [ "$has_grok" -eq 1 ]; then
  DEFAULT_PROVIDER="grok"
  DEFAULT_MODEL="$GROK_MODEL"
else
  DEFAULT_PROVIDER="openrouter"
  DEFAULT_MODEL="$OPENROUTER_MODEL"
fi

{
  echo "llm-pi-ai:"
  echo "  providers:"
  if [ "$has_grok" -eq 1 ]; then
    cat <<EOF
    grok:
      displayName: Grok
      api: openai-completions
      baseURL: ${GROK_BASE_URL}
      apiKeyEnv: GROK_API_KEY
      models:
        - id: '${GROK_MODEL}'
EOF
  fi
  if [ "$has_openrouter" -eq 1 ]; then
    cat <<EOF
    openrouter:
      displayName: OpenRouter (fallback)
      api: openai-completions
      baseURL: ${OPENROUTER_BASE_URL}
      apiKeyEnv: OPENROUTER_API_KEY
      models:
        - id: '${OPENROUTER_MODEL}'
EOF
  fi
  cat <<EOF
agent-default-model:
  provider: ${DEFAULT_PROVIDER}
  model: '${DEFAULT_MODEL}'
EOF
} > "$DSH_HOME/settings.yaml"

umask 077
: > "$DSH_HOME/.env"
if [ "$has_grok" -eq 1 ]; then
  printf 'GROK_API_KEY=%s\n' "$GROK_API_KEY" >> "$DSH_HOME/.env"
fi
if [ "$has_openrouter" -eq 1 ]; then
  printf 'OPENROUTER_API_KEY=%s\n' "$OPENROUTER_API_KEY" >> "$DSH_HOME/.env"
fi
chmod 600 "$DSH_HOME/.env" "$DSH_HOME/settings.yaml"

echo "DSH home: $DSH_HOME"
echo "Primary API: ${GROK_BASE_URL} (model ${GROK_MODEL})"
echo "Fallback API: ${OPENROUTER_BASE_URL} (model ${OPENROUTER_MODEL})"
echo "Default provider: ${DEFAULT_PROVIDER}"
echo "Default model: ${DEFAULT_MODEL}"
echo "GROK_API_KEY: $([ "$has_grok" -eq 1 ] && echo configured || echo missing)"
echo "OPENROUTER_API_KEY: $([ "$has_openrouter" -eq 1 ] && echo configured || echo missing)"
echo "===== DSH settings.yaml ====="
cat "$DSH_HOME/settings.yaml"
