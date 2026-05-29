#!/usr/bin/env bash
# SPDX-License-Identifier: AGPL-3.0-or-later

set -euo pipefail

sample_drills() {
  cat <<'EOF'
BD-104|payments-postgres|tier1-stateful|point-in-time-restore|critical|4|5|false|2|staging-rehearsal|Restore chain exceeded the target window and operator notes are incomplete
BD-117|identity-vault|security-secrets|vault-snapshot-restore|high|3|2|true|1|evidence-review|Snapshot restored, but credential validation is still pending
BD-125|analytics-warehouse|reporting-platform|cross-region-recovery|high|6|4|true|0|validated|Warehouse recovery run completed with clean signoff and reconciled row counts
BD-138|cms-assets|content-delivery|object-store-restore|medium|2|3|false|1|manual-check|Asset checksum packet is partial and CDN warm-up is still open
EOF
}

status_for_drill() {
  local severity="$1" target_hours="$2" actual_hours="$3" evidence_complete="$4" blockers="$5" drill_state="$6"
  if [[ "$severity" == "critical" && "$actual_hours" -gt "$target_hours" ]] || [[ "$evidence_complete" == "false" && "$blockers" -ge 2 ]] || [[ "$drill_state" == "staging-rehearsal" && "$actual_hours" -gt "$target_hours" ]]; then
    echo "red"
  elif [[ "$evidence_complete" == "false" || "$blockers" -ge 1 || "$drill_state" == "manual-check" || "$drill_state" == "evidence-review" ]]; then
    echo "yellow"
  else
    echo "green"
  fi
}

lane_for_status() {
  local status="$1"
  case "$status" in
    red) echo "recover-now" ;;
    yellow) echo "drill-and-tighten" ;;
    *) echo "restore-ready" ;;
  esac
}

action_for_status() {
  local status="$1" drill_type="$2"
  case "$status" in
    red) echo "Repeat the ${drill_type} run with a named incident commander, reconcile evidence gaps, and tighten restore timing before the next review." ;;
    yellow) echo "Keep the ${drill_type} drill in weekly rotation and close the remaining validation gaps before treating it as operator-safe." ;;
    *) echo "Preserve the ${drill_type} packet as reusable restore proof and maintain the current rehearsal cadence." ;;
  esac
}

analyze_drills() {
  local output="${1:-}"
  local lines=()
  local red=0 yellow=0 green=0 total_blockers=0 total_overrun=0

  while IFS='|' read -r id system_name lane drill_type severity target_hours actual_hours evidence_complete blockers drill_state top_risk; do
    [[ -z "${id}" ]] && continue
    local status lane_code action overrun
    status="$(status_for_drill "$severity" "$target_hours" "$actual_hours" "$evidence_complete" "$blockers" "$drill_state")"
    lane_code="$(lane_for_status "$status")"
    action="$(action_for_status "$status" "$drill_type")"
    overrun=$(( actual_hours - target_hours ))
    if (( overrun < 0 )); then
      overrun=0
    fi

    case "$status" in
      red) red=$((red + 1)) ;;
      yellow) yellow=$((yellow + 1)) ;;
      green) green=$((green + 1)) ;;
    esac
    total_blockers=$((total_blockers + blockers))
    total_overrun=$((total_overrun + overrun))

    lines+=("${id}|${system_name}|${lane}|${drill_type}|${severity}|${target_hours}|${actual_hours}|${evidence_complete}|${blockers}|${drill_state}|${status}|${lane_code}|${overrun}|${top_risk}|${action}")
  done < <(sample_drills)

  local avg_blockers="0.0"
  local avg_overrun="0.0"
  if [[ ${#lines[@]} -gt 0 ]]; then
    avg_blockers="$(awk -v total="$total_blockers" -v count="${#lines[@]}" 'BEGIN { printf "%.1f", total / count }')"
    avg_overrun="$(awk -v total="$total_overrun" -v count="${#lines[@]}" 'BEGIN { printf "%.1f", total / count }')"
  fi

  if [[ -n "$output" ]]; then
    mkdir -p "$(dirname "$output")"
    {
      printf 'summary|total_drills|%s\n' "${#lines[@]}"
      printf 'summary|red_drills|%s\n' "$red"
      printf 'summary|yellow_drills|%s\n' "$yellow"
      printf 'summary|green_drills|%s\n' "$green"
      printf 'summary|avg_blockers|%s\n' "$avg_blockers"
      printf 'summary|avg_overrun_hours|%s\n' "$avg_overrun"
      for line in "${lines[@]}"; do
        printf 'drill|%s\n' "$line"
      done
    } > "$output"
  else
    printf 'summary|total_drills|%s\n' "${#lines[@]}"
    printf 'summary|red_drills|%s\n' "$red"
    printf 'summary|yellow_drills|%s\n' "$yellow"
    printf 'summary|green_drills|%s\n' "$green"
    printf 'summary|avg_blockers|%s\n' "$avg_blockers"
    printf 'summary|avg_overrun_hours|%s\n' "$avg_overrun"
    for line in "${lines[@]}"; do
      printf 'drill|%s\n' "$line"
    done
  fi
}

summary_value() {
  local report="$1" key="$2"
  awk -F'|' -v key="$key" '$1=="summary" && $2==key { print $3 }' "$report"
}
