#!/usr/bin/env bash
# Fails if app or package code mentions a network host outside the allow
# list in README.md ("Сетевая политика"). Comments count too: a URL in code is
# a URL someone may start calling.
set -euo pipefail
cd "$(dirname "$0")/../.."

allowed=(
  # Stage 2: online tiles and region packs.
  tiles.openfreemap.org
  openfreemap.org
  github.com
  objects.githubusercontent.com
)

found=$(grep -rhoE 'https?://[A-Za-z0-9.-]+' app/lib packages/*/lib \
  --include='*.dart' --exclude='*.g.dart' --exclude='app_localizations*.dart' | sort -u || true)

bad=0
for url in $found; do
  host=${url#*://}
  ok=0
  for a in "${allowed[@]}"; do
    [[ $host == "$a" ]] && ok=1
  done
  if [[ $ok == 0 ]]; then
    echo "Not on the allow list: $url"
    bad=1
  fi
done

# Analytics, crash reporting and ad SDKs must never be added.
if grep -qiE '^\s+(firebase_|sentry|amplitude|mixpanel|appsflyer|google_mobile_ads|onesignal|datadog)' app/pubspec.yaml; then
  echo "Telemetry or ads dependency in app/pubspec.yaml"
  bad=1
fi
exit $bad
