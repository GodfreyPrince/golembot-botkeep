#!/usr/bin/env bash
# Botkeep start command for the GolemBot gateway: the single long-running process.
set -euo pipefail
cd "$(dirname "$0")"

# 1. Dependencies (Botkeep usually runs `npm install` on deploy; no-op if done)
if [ ! -d node_modules/golembot ]; then
  echo "[start] installing dependencies…"
  npm install --no-audit --no-fund
fi

# 2. opencode CLI comes from the `opencode-ai` npm package — GolemBot shells out to it
export PATH="$PWD/node_modules/.bin:$PATH"
if ! command -v opencode >/dev/null 2>&1; then
  echo "[start] FATAL: opencode binary missing after npm install."
  exit 1
fi

# 3. Fail fast with a clear message if the Telegram token is missing
if [ -z "${TELEGRAM_BOT_TOKEN:-}" ]; then
  echo "[start] FATAL: TELEGRAM_BOT_TOKEN is not set."
  echo "[start] Create a bot with @BotFather on Telegram, add TELEGRAM_BOT_TOKEN"
  echo "[start] in the Botkeep panel under Environment, then restart this workload."
  exit 1
fi

echo "[start] launching golembot gateway (telegram)…"
exec ./node_modules/.bin/golembot gateway
