#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."
source src/backup_restore_drill_runner.sh

report="$(mktemp)"
trap 'rm -f "$report"' EXIT

analyze_drills "$report"

[[ "$(summary_value "$report" total_drills)" == "4" ]]
[[ "$(summary_value "$report" red_drills)" == "1" ]]
[[ "$(summary_value "$report" yellow_drills)" == "2" ]]
[[ "$(summary_value "$report" green_drills)" == "1" ]]
grep -q 'recover-now' "$report"
grep -q 'restore-ready' "$report"

echo "All tests passed."
