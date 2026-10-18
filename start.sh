#!/usr/bin/env bash
# Botkeep start command for the GolemBot gateway: the single long-running process.
set -euo pipefail
cd "$(dirname "$0")"

# 1. Dependencies (Botkeep usually runs `npm install` on deploy; no-op if done)
if [ ! -d node_modules/golembot ]; then
  echo "[start] installing dependencies…"
  npm install --no-audit --no-fund
fi

# 2. OpenCode binary on PATH — GolemBot shells out to `opencode`
export PATH="$HOME/.opencode/bin:$PATH"
if ! command -v opencode >/dev/null 2>&1; then
  echo "[start] installing opencode…"
  curl -fsSL https://opencode.ai/install | bash
fi

# 3. Fail fast with a clear message if Slack tokens are missing
if [ -z "${SLACK_BOT_TOKEN:-}" ] || [ -z "${SLACK_APP_TOKEN:-}" ]; then
  echo "[start] FATAL: SLACK_BOT_TOKEN / SLACK_APP_TOKEN are not set."
  echo "[start] Add them in the Botkeep panel under Environment, then restart this workload."
  exit 1
fi

echo "[start] launching golembot gateway…"
exec ./node_modules/.bin/golembot gateway
