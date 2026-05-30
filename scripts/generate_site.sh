#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."
source src/backup_restore_drill_runner.sh

report="site/api/dashboard.txt"
mkdir -p site/api site/drill-lane site/recovery-matrix site/restore-posture site/verification site/docs
analyze_drills "$report"

total_drills="$(summary_value "$report" total_drills)"
red_drills="$(summary_value "$report" red_drills)"
yellow_drills="$(summary_value "$report" yellow_drills)"
avg_blockers="$(summary_value "$report" avg_blockers)"
avg_overrun="$(summary_value "$report" avg_overrun_hours)"

drill_rows="$(awk -F'|' '
  $1=="drill" {
    printf "<tr><td><b>%s</b><br><span class=\"section-note\">%s · %s</span></td><td>%s</td><td>%s</td><td>%s</td><td>%s</td><td><span class=\"status %s\">%s</span></td></tr>\n",
      $3, $2, $4, $6, $7, $13, $9, ($11=="red"?"bad":($11=="yellow"?"warn":"green")), toupper($11)
  }' "$report")"

card_items="$(awk -F'|' '
  $1=="drill" {
    printf "<div class=\"card\"><div class=\"eyebrow\">%s</div><h3>%s</h3><p>%s on the %s lane is currently in %s.</p><p>%s</p><p>%s</p></div>\n",
      $2, $3, $4, $3, $10, $14, $15
  }' "$report")"

matrix_items="$(awk -F'|' '
  $1=="drill" {
    printf "<div class=\"card\"><div class=\"eyebrow\">%s</div><h3>%s</h3><p>Target %s hours, actual %s hours, blockers %s.</p><p>%s</p></div>\n",
      $2, $4, $6, $7, $9, $15
  }' "$report")"

posture_rows="$(awk -F'|' '
  $1=="drill" {
    printf "<tr><td><b>%s</b><br><span class=\"section-note\">%s</span></td><td>%s hrs</td><td>%s</td></tr>\n",
      $3, $4, $13, $15
  }' "$report")"

style=':root{--bg:#070a0f;--panel:#0b1220;--line:rgba(120,255,170,.18);--line2:rgba(120,255,170,.10);--text:#e9f3ff;--muted:rgba(233,243,255,.72);--muted2:rgba(233,243,255,.55);--bert:#37ff8b;--bert2:#19c7ff;--warn:#ffcc66;--bad:#ff5c7a;--plum:#b88cff;--shadow:0 18px 60px rgba(0,0,0,.55);--mono:ui-monospace,SFMono-Regular,Menlo,Monaco,Consolas,"Courier New",monospace;--sans:ui-sans-serif,system-ui,-apple-system,Segoe UI,Roboto,Helvetica,Arial,sans-serif}*{box-sizing:border-box}html,body{height:100%}body{margin:0;font-family:var(--sans);color:var(--text);background:radial-gradient(1200px 600px at 20% -10%, rgba(55,255,139,.18), transparent 60%),radial-gradient(900px 520px at 90% 0%, rgba(25,199,255,.16), transparent 55%),radial-gradient(1000px 600px at 50% 110%, rgba(55,255,139,.10), transparent 60%),linear-gradient(180deg,#05070c 0%,#070a0f 35%,#05070c 100%)}.grid-bg{position:fixed;inset:0;pointer-events:none;opacity:.12;z-index:-1;background-image:linear-gradient(to right, rgba(55,255,139,.14) 1px, transparent 1px),linear-gradient(to bottom, rgba(55,255,139,.10) 1px, transparent 1px);background-size:46px 46px;mask-image:radial-gradient(900px 600px at 40% 10%, #000 60%, transparent 100%)}.wrap{max-width:1280px;margin:0 auto;padding:24px 22px 80px}.topbar{display:flex;justify-content:space-between;align-items:flex-start;gap:14px;border-bottom:1px solid var(--line2);padding-bottom:14px;margin-bottom:22px;font-family:var(--mono);font-size:11px;letter-spacing:.16em;color:var(--muted);text-transform:uppercase}.topbar .left{color:var(--bert)}.topbar .right{text-align:right}.herorow{display:grid;grid-template-columns:1.45fr .85fr;gap:18px}@media (max-width:1000px){.herorow{grid-template-columns:1fr}}.hero,.mini,.tablewrap{background:linear-gradient(180deg, rgba(11,18,32,.95), rgba(8,14,26,.92));border:1px solid var(--line);border-radius:22px;box-shadow:var(--shadow)}.hero{padding:28px 28px 24px;border-top:2px solid var(--bert2)}.hero h1{font-size:60px;line-height:.97;margin:0 0 18px;font-weight:800;letter-spacing:-.5px}@media (max-width:700px){.hero h1{font-size:40px}}.hero p,.mini p,.tablewrap p{color:var(--muted);font-size:15px;line-height:1.55}.chiprow{display:flex;flex-wrap:wrap;gap:8px}.meta-chip,.pill{font-family:var(--mono);font-size:11px;padding:7px 12px;border-radius:999px;border:1px solid var(--line);background:rgba(6,10,18,.4);color:var(--muted)}.side{display:flex;flex-direction:column;gap:14px}.mini{padding:18px}.mini .lbl,.section-note{font-family:var(--mono);font-size:10px;letter-spacing:.18em;text-transform:uppercase;color:var(--bert2)}.mini h3{margin:8px 0 6px;font-size:28px;line-height:1.02}.notice{margin-top:16px;padding:14px 16px;border:1px solid rgba(255,204,102,.28);border-left:4px solid var(--warn);border-radius:14px;background:rgba(255,204,102,.06);color:var(--muted)}.section{margin-top:34px}.sh{display:flex;justify-content:space-between;align-items:baseline;gap:14px;padding-bottom:10px;border-bottom:1px solid var(--line2);margin-bottom:14px}.sh h2{margin:0;font-size:24px;font-weight:600}.sh .note{font-family:var(--mono);font-size:11px;color:var(--muted2);letter-spacing:.16em;text-transform:uppercase}.kpis{display:grid;grid-template-columns:repeat(4,1fr);gap:12px}@media (max-width:900px){.kpis{grid-template-columns:repeat(2,1fr)}}@media (max-width:640px){.kpis{grid-template-columns:1fr}}.kpi,.card{border:1px solid var(--line);border-radius:16px;padding:16px;background:linear-gradient(180deg, rgba(11,18,32,.85), rgba(8,14,26,.65))}.kpi .v{font-family:var(--mono);font-size:28px;font-weight:700}.kpi .lbl{font-family:var(--mono);font-size:10px;letter-spacing:.18em;text-transform:uppercase;color:var(--muted);margin-top:6px}.kpi .h{font-size:12px;color:var(--muted);line-height:1.45;margin-top:8px}.cards{display:grid;grid-template-columns:repeat(3,1fr);gap:14px}@media (max-width:1000px){.cards{grid-template-columns:1fr}}.card h3{margin:8px 0 8px;font-size:22px}.card .eyebrow{font-family:var(--mono);font-size:10px;letter-spacing:.18em;text-transform:uppercase;color:var(--bert)}table{width:100%;border-collapse:collapse}th,td{padding:13px 14px;text-align:left;font-size:13.5px;vertical-align:top}thead th{font-family:var(--mono);font-size:11px;letter-spacing:.16em;text-transform:uppercase;color:var(--muted2);border-bottom:1px solid var(--line);background:rgba(11,18,32,.5)}tbody tr:hover{background:rgba(55,255,139,.03)}tbody td{color:var(--muted);border-bottom:1px solid var(--line2)}.tablewrap{padding:0;overflow:hidden}.status{display:inline-block;padding:4px 9px;border-radius:6px;border:1px solid currentColor;font-family:var(--mono);font-size:10px;letter-spacing:.1em;text-transform:uppercase}.green{color:var(--bert)}.warn{color:var(--warn)}.bad{color:var(--bad)}.quote{margin-top:34px;border:1px solid rgba(55,255,139,.22);background:radial-gradient(700px 200px at 0% 0%, rgba(55,255,139,.10), transparent 60%),linear-gradient(180deg, rgba(11,18,32,.92), rgba(8,14,26,.88));border-radius:18px;padding:24px 26px}.quote .lbl{font-family:var(--mono);font-size:11px;color:var(--bert);letter-spacing:.22em;text-transform:uppercase}.quote .q{margin-top:12px;font-size:32px;line-height:1.25;font-weight:600;max-width:1000px}footer{margin-top:30px;padding-top:14px;border-top:1px dashed var(--line2);display:flex;justify-content:space-between;gap:10px;flex-wrap:wrap;font-family:var(--mono);font-size:11px;color:var(--muted2);letter-spacing:.08em}a{color:var(--bert2);text-decoration:none}'

page() {
  local title="$1" description="$2" canonical="$3" content="$4"
  cat <<EOF
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>${title}</title>
  <meta name="description" content="${description}">
  <meta name="robots" content="index,follow">
  <meta property="og:title" content="${title}">
  <meta property="og:description" content="${description}">
  <meta property="og:type" content="website">
  <meta property="og:url" content="${canonical}">
  <link rel="canonical" href="${canonical}">
  <style>${style}</style>
</head>
<body>
  <div class="grid-bg"></div>
  <div class="wrap">
${content}
  </div>
</body>
</html>
EOF
}

overview_content="$(cat <<EOF
<div class="topbar"><div class="left">language atlas · shell recovery surface</div><div class="right"><div>backup.kineticgain.com</div><div>generated 2026-05-28 · platform engineering</div></div></div>
<div class="herorow"><section class="hero">
  <div class="chiprow"><span class="meta-chip">shell / bash</span><span class="meta-chip">recovery drills</span><span class="meta-chip">restore windows</span><span class="meta-chip">evidence packets</span></div>
  <h1>Backup restore drill runner for recovery windows, operator evidence, and restore-safe posture.</h1>
  <p>A Bash-native operator surface for platform and infrastructure teams: rehearse backup restores, keep target versus actual recovery windows visible, and turn drill evidence into buyer-readable recovery posture.</p>
  <div class="chiprow"><span class="pill">Route: /drill-lane/</span><span class="pill">Route: /recovery-matrix/</span><span class="pill">Route: /restore-posture/</span></div>
  <div class="notice">Synthetic demonstration data only. This repo models backup and recovery drills for operational proof and does not claim certified disaster-recovery compliance.</div>
</section><aside class="side">
  <div class="mini"><div class="lbl">Total drills</div><h3>${total_drills}</h3><p>Modeled restore drills included in the shell runner.</p></div>
  <div class="mini"><div class="lbl">Recover-now drills</div><h3>${red_drills}</h3><p>Restore runs that currently miss timing or evidence expectations.</p></div>
  <div class="mini"><div class="lbl">Average overrun</div><h3>${avg_overrun} hrs</h3><p>How far drills are drifting beyond the target recovery window.</p></div>
</aside></div>
<section class="section"><div class="sh"><h2>Control-plane summary</h2><div class="note">Recovery timing and proof from one shell analysis path</div></div>
<div class="kpis">
  <div class="kpi"><div class="v">${total_drills}</div><div class="lbl">Total Drills</div><div class="h">Restore rehearsals modeled across database, vault, warehouse, and asset systems.</div></div>
  <div class="kpi"><div class="v bad">${red_drills}</div><div class="lbl">Recover Now</div><div class="h">Drills where timing or evidence gaps still block restore confidence.</div></div>
  <div class="kpi"><div class="v warn">${yellow_drills}</div><div class="lbl">Drill And Tighten</div><div class="h">Runs that need more validation before they count as operator-safe.</div></div>
  <div class="kpi"><div class="v">${avg_blockers}</div><div class="lbl">Avg Blockers</div><div class="h">Average unresolved blockers per rehearsal cycle.</div></div>
</div></section>
<section class="section"><div class="sh"><h2>Restore drill matrix</h2><div class="note">Target window, overrun, blockers, and posture</div></div>
<div class="tablewrap"><table><thead><tr><th>System</th><th>Target</th><th>Actual</th><th>Overrun</th><th>Blockers</th><th>Status</th></tr></thead><tbody>
${drill_rows}
</tbody></table></div></section>
<section class="section"><div class="sh"><h2>Priority recovery queue</h2><div class="note">Modeled remediation sequence</div></div><div class="cards">
${card_items}
</div></section>
<div class="quote"><div class="lbl">Why this matters</div><div class="q">A backup and restore drill kit becomes monetizable when the same Bash analysis can support runbook templates, recovery evidence packets, and embedded resilience work for platform teams.</div></div>
<footer><div>discipline · backup and recovery drills</div><div>focus · restore timing / blockers / evidence</div><div>overview snapshot</div><div><a href="https://github.com/mizcausevic-dev/">GitHub</a> · <a href="https://www.linkedin.com/in/mirzacausevic/">LinkedIn</a> · <a href="https://kineticgain.com/">Kinetic Gain</a></div></footer>
EOF
)"

drill_lane_content="$(cat <<EOF
<div class="topbar"><div class="left">backup restore drill runner · drill lane</div><div class="right"><div>platform engineering</div><div>recovery review board</div></div></div>
<section class="hero"><h1>Recovery drills stay tied to the system that owns them.</h1><p>The drill lane keeps recovery targets, actual restore windows, evidence completeness, and blockers on one route so teams can review where recovery confidence is still fragile.</p><div class="notice">Synthetic demonstration data only. Use this repo as operational proof, not as a claim of certified disaster-recovery compliance.</div></section>
<section class="section"><div class="tablewrap"><table><thead><tr><th>System</th><th>Lane</th><th>Drill type</th><th>State</th><th>Status</th></tr></thead><tbody>
$(awk -F'|' '$1=="drill" { printf "<tr><td><b>%s</b><br><span class=\"section-note\">%s</span></td><td>%s</td><td>%s</td><td>%s</td><td><span class=\"status %s\">%s</span></td></tr>\n", $3, $2, $4, $5, $10, ($11=="red"?"bad":($11=="yellow"?"warn":"green")), toupper($11) }' "$report")
</tbody></table></div></section>
EOF
)"

recovery_matrix_content="$(cat <<EOF
<div class="topbar"><div class="left">backup restore drill runner · recovery matrix</div><div class="right"><div>timing and proof by drill</div></div></div>
<section class="hero"><h1>Restore timing stays visible before disaster week, not during it.</h1><p>This route turns target versus actual recovery windows into drill-specific guidance teams can use for resilience reviews, backup strategy packets, and restore governance.</p></section>
<section class="section"><div class="cards">
${matrix_items}
</div></section>
EOF
)"

restore_posture_content="$(cat <<EOF
<div class="topbar"><div class="left">backup restore drill runner · restore posture</div><div class="right"><div>evidence and recovery posture</div></div></div>
<section class="hero"><h1>Restore posture stays auditable.</h1><p>The posture route shows which systems need immediate drill repetition and where evidence packets still need tightening before leadership treats recovery as operator-safe.</p><div class="notice">This is readiness and evidence posture only. It does not claim audited DR certification or formal compliance attestation.</div></section>
<section class="section"><div class="tablewrap"><table><thead><tr><th>System</th><th>Overrun</th><th>Recommendation</th></tr></thead><tbody>
${posture_rows}
</tbody></table></div></section>
EOF
)"

verification_content="$(cat <<EOF
<div class="topbar"><div class="left">backup restore drill runner · verification</div><div class="right"><div>git bash only</div></div></div>
<section class="hero"><h1>One shell analysis path, one static proof surface.</h1><p>The same Bash functions produce the recovery analysis, posture routes, site pages, smoke checks, and README proof assets.</p></section>
<section class="section"><div class="cards">
  <div class="card"><div class="eyebrow">Validation</div><h3>Shell runtime</h3><p>Validated with Bash demo, tests, site generation, smoke checks, and proof asset rendering.</p></div>
  <div class="card"><div class="eyebrow">Routes</div><h3>Static proof surface</h3><p>/ · /drill-lane/ · /recovery-matrix/ · /restore-posture/ · /verification/ · /docs/</p></div>
  <div class="card"><div class="eyebrow">Commercial path</div><h3>Runbook kit and consulting</h3><p>Paid runbook kit now, with embedded recovery evidence work by engagement.</p></div>
</div></section>
EOF
)"

docs_content="$(cat <<EOF
<div class="topbar"><div class="left">backup restore drill runner · docs</div><div class="right"><div>kinetic gain embedded</div></div></div>
<section class="hero"><h1>Recovery drill proof for backup and restore operations.</h1><p>This repo sits in the Language Atlas and Industry Atlas at once: real Bash, platform-engineering framing, and a monetizable path into recovery drill templates, resilience briefings, and embedded evidence-routing work.</p><div class="notice">Synthetic demonstration data only. It is framed as readiness, evidence, and operator posture.</div></section>
<section class="section"><div class="cards">
  <div class="card"><div class="eyebrow">Tier 1</div><h3>Public proof</h3><p>Open-source recovery drill route and restore timing model with buyer-readable outputs.</p></div>
  <div class="card"><div class="eyebrow">Tier 2</div><h3>Paid runbook kit</h3><p>Restore rehearsal packets, recovery readiness decks, and backup evidence starter kits.</p></div>
  <div class="card"><div class="eyebrow">Tier 4</div><h3>Embedded by engagement</h3><p>Kinetic Gain can adapt the shell runner for a platform, SRE, or infrastructure operations team.</p></div>
</div></section>
EOF
)"

page "Backup restore drill runner" "Bash-native recovery drill operator surface for restore timing, blockers, and evidence posture." "https://backup.kineticgain.com/" "$overview_content" > site/index.html
page "Drill lane · Backup restore drill runner" "Recovery drill lane and triage routes." "https://backup.kineticgain.com/drill-lane/" "$drill_lane_content" > site/drill-lane/index.html
page "Recovery matrix · Backup restore drill runner" "Target versus actual restore windows and drill guidance." "https://backup.kineticgain.com/recovery-matrix/" "$recovery_matrix_content" > site/recovery-matrix/index.html
page "Restore posture · Backup restore drill runner" "Restore readiness and evidence posture routing." "https://backup.kineticgain.com/restore-posture/" "$restore_posture_content" > site/restore-posture/index.html
page "Verification · Backup restore drill runner" "Validation and commercial path for the shell recovery surface." "https://backup.kineticgain.com/verification/" "$verification_content" > site/verification/index.html
page "Docs · Backup restore drill runner" "Platform-engineering documentation and monetization path." "https://backup.kineticgain.com/docs/" "$docs_content" > site/docs/index.html

cat > site/robots.txt <<'EOF'
User-agent: *
Allow: /
Sitemap: https://backup.kineticgain.com/sitemap.xml
EOF

cat > site/sitemap.xml <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
  <url><loc>https://backup.kineticgain.com/</loc><lastmod>2026-05-28</lastmod></url>
  <url><loc>https://backup.kineticgain.com/drill-lane/</loc><lastmod>2026-05-28</lastmod></url>
  <url><loc>https://backup.kineticgain.com/recovery-matrix/</loc><lastmod>2026-05-28</lastmod></url>
  <url><loc>https://backup.kineticgain.com/restore-posture/</loc><lastmod>2026-05-28</lastmod></url>
  <url><loc>https://backup.kineticgain.com/verification/</loc><lastmod>2026-05-28</lastmod></url>
  <url><loc>https://backup.kineticgain.com/docs/</loc><lastmod>2026-05-28</lastmod></url>
</urlset>
EOF

cp CNAME site/CNAME
cp site/index.html site/404.html
