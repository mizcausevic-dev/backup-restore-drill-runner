#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."
source src/backup_restore_drill_runner.sh

mkdir -p screenshots
report="$(mktemp)"
trap 'rm -f "$report"' EXIT
analyze_drills "$report"

wrap_text() {
  local text="$1" width="${2:-44}"
  python - "$text" "$width" <<'PY'
import sys, textwrap
text = sys.argv[1]
width = int(sys.argv[2])
print("\n".join(textwrap.wrap(text, width=width)))
PY
}

write_svg_card() {
  local path="$1" eyebrow="$2" title="$3" accent="$4"
  shift 4
  local y=138
  {
    echo '<?xml version="1.0" encoding="UTF-8"?>'
    echo '<svg xmlns="http://www.w3.org/2000/svg" width="1600" height="900" viewBox="0 0 1600 900">'
    echo '  <defs><linearGradient id="bg" x1="0" y1="0" x2="0" y2="1"><stop offset="0%" stop-color="#0b1220"/><stop offset="100%" stop-color="#08101d"/></linearGradient></defs>'
    echo '  <rect width="1600" height="900" fill="#05070c"/>'
    echo '  <rect x="48" y="48" width="1504" height="804" rx="30" fill="url(#bg)" stroke="#17324d" stroke-width="2"/>'
    printf '  <text x="96" y="118" fill="%s" font-family="ui-monospace,Consolas,monospace" font-size="26" letter-spacing="6">%s</text>\n' "$accent" "$(printf '%s' "$eyebrow" | tr '[:lower:]' '[:upper:]')"
    printf '  <text x="96" y="196" fill="#f2f7ff" font-family="Georgia,Times New Roman,serif" font-size="62" font-weight="700">%s</text>\n' "$title"
    for block in "$@"; do
      echo "  <text x=\"96\" y=\"$y\" fill=\"#b8c9df\" font-family=\"Segoe UI,Arial,sans-serif\" font-size=\"30\">"
      first=1
      while IFS= read -r line; do
        [[ -z "$line" ]] && continue
        if [[ $first -eq 1 ]]; then
          printf '    <tspan x="96" dy="0">%s</tspan>\n' "$line"
          first=0
        else
          printf '    <tspan x="96" dy="40">%s</tspan>\n' "$line"
        fi
      done < <(wrap_text "$block")
      echo '  </text>'
      local line_count
      line_count=$(wrap_text "$block" | python -c "import sys; print(sum(1 for _ in sys.stdin) or 1)")
      y=$(( y + (line_count * 40) + 34 ))
    done
    echo '</svg>'
  } > "$path"
}

overview_line_1="Total drills: $(summary_value "$report" total_drills) · recover-now drills: $(summary_value "$report" red_drills) · average overrun: $(summary_value "$report" avg_overrun_hours) hours."
overview_line_2="Highest-pressure systems: $(awk -F'|' '$1=="drill" && $11=="red" { print $3 }' "$report" | paste -sd ', ' -)."
overview_line_3="The operator surface keeps restore timing, blockers, checksum evidence, and rehearsal state visible in one proof set."

lane_line_1="$(awk -F'|' '$1=="drill" { printf "%s · %s · %s blockers · %s\n", $3, $4, $9, toupper($11) }' "$report" | sed -n '1p')"
lane_line_2="$(awk -F'|' '$1=="drill" { printf "%s · %s · %s blockers · %s\n", $3, $4, $9, toupper($11) }' "$report" | sed -n '2p')"
lane_line_3="$(awk -F'|' '$1=="drill" { printf "%s · %s · %s blockers · %s\n", $3, $4, $9, toupper($11) }' "$report" | sed -n '3p')"
lane_line_4="$(awk -F'|' '$1=="drill" { printf "%s · %s · %s blockers · %s\n", $3, $4, $9, toupper($11) }' "$report" | sed -n '4p')"

posture_line_1="Restore posture flags where rehearsal timing, evidence packets, or checksum validation still lag."
posture_line_2="$(awk -F'|' '$1=="drill" { printf "%s: %s", $3, $15; if (NR < 4) printf " | " }' "$report")"

verification_line_1="Proof assets are generated from the same Bash scenario and analysis functions used for the dashboard routes."
verification_line_2="Routes: / · /drill-lane/ · /recovery-matrix/ · /restore-posture/ · /verification/ · /docs/."

write_svg_card "screenshots/01-overview.svg" "backup restore drill runner" "Backup and restore drill runner for recovery timing and evidence posture." "#19c7ff" \
  "$overview_line_1" "$overview_line_2" "$overview_line_3"
write_svg_card "screenshots/02-drill-lane.svg" "drill lane" "Systems with the most fragile recovery drills stay visible." "#37ff8b" \
  "$lane_line_1" "$lane_line_2" "$lane_line_3" "$lane_line_4"
write_svg_card "screenshots/03-restore-posture.svg" "restore posture" "Restore evidence and timing gaps stay buyer-readable." "#ffcc66" \
  "$posture_line_1" "$posture_line_2"
write_svg_card "screenshots/04-verification.svg" "verification" "Shell analysis and static proof routes stay in sync." "#b88cff" \
  "$verification_line_1" "$verification_line_2"

echo "Rendered README assets."
