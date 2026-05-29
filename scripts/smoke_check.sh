#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."
bash scripts/generate_site.sh

required_paths=(
  site/index.html
  site/drill-lane/index.html
  site/recovery-matrix/index.html
  site/restore-posture/index.html
  site/verification/index.html
  site/docs/index.html
  site/robots.txt
  site/sitemap.xml
)

for path in "${required_paths[@]}"; do
  [[ -f "$path" ]] || { echo "Missing generated path: $path" >&2; exit 1; }
done

root_html="$(<site/index.html)"
for needle in "Backup restore drill runner" "/restore-posture/" "platform engineering"; do
  grep -q "$needle" <<<"$root_html" || { echo "Expected keyword missing from root HTML: $needle" >&2; exit 1; }
done

echo "Smoke check passed."
