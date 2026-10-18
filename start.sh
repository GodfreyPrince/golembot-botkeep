#!/usr/bin/env bash
# Botkeep start command for the GolemBot gateway: the single long-running process.
set -euo pipefail
cd "$(dirname "$0")"

# Persist boot output (Botkeep log buffer resets on restart)
exec > >(tee -a boot.log) 2>&1
echo "[start] boot $(date -u +%FT%TZ) node $(node -v)"

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

# Keep the 2 GB disk lean: drop npm cache, OpenCode undo snapshots, unused platform binaries
rm -rf "$HOME/.npm/_cacache" "$HOME/.npm/_logs" .local/share/opencode/snapshot .cache/opencode/tmp temp_file/* 2>/dev/null || true
for d in node_modules/opencode-darwin-* node_modules/opencode-windows-* node_modules/opencode-linux-arm64* node_modules/opencode-linux-x64-musl node_modules/opencode-linux-x64-baseline-musl; do rm -rf "$d"; done
find .local/share/opencode/log -name '*.log' -mtime +3 -delete 2>/dev/null || true

# Botkeep writes panel Environment variables to .env rather than the process env
if [ -f .env ]; then set -a; . ./.env; set +a; fi

# 3. Fail fast with a clear message if the Telegram token is missing
if [ -z "${TELEGRAM_BOT_TOKEN:-}" ]; then
  echo "[start] FATAL: TELEGRAM_BOT_TOKEN is not set."
  echo "[start] Create a bot with @BotFather on Telegram, add TELEGRAM_BOT_TOKEN"
  echo "[start] in the Botkeep panel under Environment, then restart this workload."
  exit 1
fi

# Force OpenCode undo snapshots off (they copy the whole workspace incl. node_modules)
node -e 'const f="opencode.json";const fs=require("fs");let c={};try{c=JSON.parse(fs.readFileSync(f,"utf8"))}catch{};if(c.snapshot!==false){c.snapshot=false;fs.writeFileSync(f,JSON.stringify(c,null,2)+"\n")}'

# Janitor: in-container "cron" every 30 min (no cron daemon on Botkeep)
janitor() {
  while sleep 1800; do
    rm -rf "$HOME/.npm/_cacache" "$HOME/.npm/_logs" .local/share/opencode/snapshot .cache/opencode/tmp temp_file/* 2>/dev/null
    find .local/share/opencode/log -name '*.log' -mtime +2 -delete 2>/dev/null
    find .golem/history -name '*.jsonl' -size +5M -exec sh -c 'tail -n 500 "$1" > "$1.tmp" && mv "$1.tmp" "$1"' _ {} \; 2>/dev/null
    [ -f boot.log ] && [ "$(wc -c < boot.log)" -gt 1000000 ] && tail -n 2000 boot.log > boot.log.tmp && mv boot.log.tmp boot.log
    used=$(du -sm . 2>/dev/null | cut -f1)
    echo "[janitor] $(date -u +%FT%TZ) disk ${used}MB"
    if [ "${used:-0}" -gt 1700 ]; then
      echo "[janitor] over 1700MB, purging OpenCode logs and caches"
      rm -rf .local/share/opencode/log/* .cache/opencode/* 2>/dev/null
    fi
  done
}
janitor &

# Cap the gateway's Node heap so it can't starve OpenCode
export NODE_OPTIONS="--max-old-space-size=512"

echo "[start] launching golembot gateway (telegram)…"
exec ./node_modules/.bin/golembot gateway
