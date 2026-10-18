# GolemBot on Botkeep

Slack bot gateway connecting OpenCode (free Zen tier, keyless) to Slack via
Socket Mode — the same setup as the Oracle VPS (`golembot-vps` runbook),
repackaged for Botkeep's hosting.

**This repo is public on purpose:** Botkeep's developer API only accepts
_public_ GitHub URLs as a deploy source. There are no secrets in this repo —
Slack tokens are injected via the Botkeep panel's Environment tab and never
appear here.

## What's inside

- `package.json` — `golembot@0.51.0` + `@slack/bolt` (peer dep); `postinstall`
  reapplies our patches.
- `patches/` — pre-patched `slack.js` (no thread replies) and `channel.js`
  (one shared OpenCode session per channel, not per thread).
- `scripts/apply-patches.js` — copies the patches over a fresh `npm install`.
- `golem.yaml` — gateway config; tokens referenced as `${SLACK_BOT_TOKEN}` /
  `${SLACK_APP_TOKEN}` from the environment.
- `start.sh` — Botkeep start command: installs deps, installs the `opencode`
  binary, fails fast if tokens are missing, then `exec`s the gateway.

## Deploy

Workload spec (via the Botkeep developer API):

- `platform: "general"`, `runtime: "nodejs"`, `runtimeVersion: "22"`
- `sourceType: "github"`, `repository: "https://github.com/GodfreyPrince/golembot-botkeep"`
- `startCommand: "bash start.sh"`
- resources: up to the full Founder Free pool
  (`memoryLimitMb: 2048`, `cpuLimitPercent: 150`, `storageLimitMb: 2048`)

Then, in the Botkeep panel under **Environment**, set:

- `SLACK_BOT_TOKEN` — `xoxb-…` (Slack app → OAuth & Permissions)
- `SLACK_APP_TOKEN` — `xapp-…` (Slack app → Basic Information → App-Level Tokens)

and restart the workload.

## One Slack app per gateway

Slack Socket Mode allows a single live connection per app-level token. Do not
point this instance at the same tokens as the Oracle VPS gateway while both
run — the second connection will knock the first one off. Either create a
second Slack app for this instance, or stop the VPS gateway and move its
tokens over.
