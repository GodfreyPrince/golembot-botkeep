# GolemBot on Botkeep (Telegram)

Slack/Discord/Telegram bot gateway connecting OpenCode (free Zen tier, keyless)
to Telegram via GolemBot — the same setup as the Oracle VPS (`golembot-vps`
runbook), repackaged for Botkeep's hosting. Currently wired to **Telegram**.

**This repo is public on purpose:** Botkeep's developer API only accepts
_public_ GitHub URLs as a deploy source. There are no secrets in this repo —
the Telegram token is injected via the Botkeep panel's Environment tab and
never appears here.

## What's inside

- `package.json` — `golembot@0.51.0` + `@slack/bolt` (peer dep) + `opencode-ai`
  (the `opencode` CLI, installed via npm as requested); `postinstall`
  reapplies our patches.
- `patches/` — pre-patched `slack.js` (no thread replies) and `channel.js`
  (one shared OpenCode session per channel, not per thread). Kept for the
  Slack channel if it's ever re-enabled.
- `scripts/apply-patches.js` — copies the patches over a fresh `npm install`.
- `golem.yaml` — gateway config; token referenced as `${TELEGRAM_BOT_TOKEN}`
  from the environment.
- `start.sh` — Botkeep start command: installs deps, puts the npm-installed
  `opencode` on PATH, fails fast if the token is missing, then `exec`s the
  gateway.

## Deploy

Workload spec (via the Botkeep developer API):

- `platform: "general"`, `runtime: "nodejs"`, `runtimeVersion: "22"`
- `sourceType: "github"`, `repository: "https://github.com/GodfreyPrince/golembot-botkeep"`, `branch: "master"`
- `startCommand: "bash start.sh"`
- resources: up to the full Founder Free pool
  (`memoryLimitMb: 2048`, `cpuLimitPercent: 150`, `storageLimitMb: 2048`)

Then, in the Botkeep panel under **Environment**, set:

- `TELEGRAM_BOT_TOKEN` — talk to [@BotFather](https://t.me/BotFather) on
  Telegram, `/newbot`, paste the token it gives you.

and restart the workload. DM the bot on Telegram to talk to OpenCode.

## Re-enabling Slack

Add a `slack:` block under `channels:` in `golem.yaml` (see git history),
set `SLACK_BOT_TOKEN` / `SLACK_APP_TOKEN` in Environment. Note: Slack Socket
Mode allows a single live connection per app-level token — don't point two
gateways at the same tokens.
