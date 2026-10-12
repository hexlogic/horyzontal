#!/usr/bin/env bash
# Fails if app or package code mentions a network host outside the allow
# list in README.md ("Сетевая политика"). Comments count too: a URL in code is
# a URL someone may start calling.
set -euo pipefail
cd "$(dirname "$0")/../.."

allowed=(
  # Online tiles.
  tiles.openfreemap.org
  # Region packs from the `maps` release; GitHub redirects downloads to its
  # asset hosts.
  github.com
  objects.githubusercontent.com
  release-assets.githubusercontent.com
  # XML namespace identifiers (SVG, KML, GPX), never fetched.
  www.w3.org
  www.opengis.net
  www.topografix.com
  www.google.com
  osmand.net
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

# Google ML Kit sends usage metrics to Google; QR scanning goes through ZXing.
# The lock file also catches it coming in as a transitive dependency.
if grep -qiE '^\s+(mobile_scanner|google_mlkit[a-z_]*|[a-z_]*mlkit[a-z_]*):' app/pubspec.yaml pubspec.lock; then
  echo "ML Kit (or mobile_scanner, which bundles it) in the dependencies"
  bad=1
fi
exit $bad
