#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."
source src/backup_restore_drill_runner.sh

tmp_report="$(mktemp)"
trap 'rm -f "$tmp_report"' EXIT

analyze_drills "$tmp_report"

echo "Backup restore drill runner"
echo "==========================="
echo "Total drills: $(summary_value "$tmp_report" total_drills)"
echo "Recover-now drills: $(summary_value "$tmp_report" red_drills)"
echo "Drill-and-tighten drills: $(summary_value "$tmp_report" yellow_drills)"
echo "Average blockers: $(summary_value "$tmp_report" avg_blockers)"
echo "Average overrun hours: $(summary_value "$tmp_report" avg_overrun_hours)"
echo
echo "Highest-priority restore gaps:"
awk -F'|' '$1=="drill" { printf "%s | %s | %s | %s\n", $2, $3, $12, $15 }' "$tmp_report"
