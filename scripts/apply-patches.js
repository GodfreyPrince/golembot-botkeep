// Reapplies our two GolemBot patches after every `npm install`.
// Upstream GolemBot replies inside Slack threads and keys one OpenCode
// session per thread; we want main-channel-only replies and one shared
// session per channel (matching the Oracle VPS setup).
const fs = require('fs');
const path = require('path');

const dist = path.join(__dirname, '..', 'node_modules', 'golembot', 'dist');
const jobs = [
  ['channels/slack.js', 'slack.js'], // no thread_ts on replies
  ['channel.js', 'channel.js'],       // channel-wide shared session
];

let ok = true;
for (const [target, patched] of jobs) {
  const dst = path.join(dist, target);
  const src = path.join(__dirname, '..', 'patches', patched);
  try {
    if (!fs.existsSync(dst)) {
      console.error(`[patches] target missing: ${dst} — is golembot ${require('../package.json').dependencies.golembot} installed?`);
      ok = false;
      continue;
    }
    const bak = dst + '.bak';
    if (!fs.existsSync(bak)) fs.copyFileSync(dst, bak); // keep pristine copy once
    fs.copyFileSync(src, dst);
    console.log(`[patches] applied ${patched} -> dist/${target}`);
  } catch (e) {
    console.error(`[patches] FAILED dist/${target}: ${e.message}`);
    ok = false;
  }
}
if (!ok) {
  console.error('[patches] one or more patches failed — verify the golembot version matches patches/');
  process.exit(1);
}
