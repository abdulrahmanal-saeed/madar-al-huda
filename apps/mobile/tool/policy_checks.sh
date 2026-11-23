#!/usr/bin/env bash
# Product-policy checks for the mobile app. Run from apps/mobile/.
#
#  1. No advertising, analytics/attribution or tracking SDKs (D-04, PRD).
#  2. Main AndroidManifest permissions match an explicit allow-list
#     (core screens must open without network or location).
#  3. Direct dependencies in pubspec.yaml are pinned to exact versions.
#  4. No signing keys, keystores or service credentials are tracked.
#
# Changing an allow-list below is a product decision: reference the
# tracker task / decision ID in the same PR.
set -euo pipefail

cd "$(dirname "$0")/.."
fail=0
err() { echo "::error::$*"; fail=1; }

# --- 1. Forbidden SDKs -------------------------------------------------------
forbidden='^  (google_mobile_ads|admob[a-z_]*|facebook_[a-z_]+|flutter_facebook[a-z_]*|firebase_analytics|firebase_in_app_messaging|appsflyer_sdk|adjust_sdk|branch_sdk|flutter_branch_sdk|mixpanel_flutter|amplitude_flutter|segment_analytics|posthog_flutter|unity_ads_plugin|applovin_max|ironsource_mediation|gma_mediation_[a-z_]+|onesignal_flutter|clevertap_plugin|smartlook|uxcam|flutter_uxcam):$'
if grep -Eq "$forbidden" pubspec.lock; then
  err "Forbidden ads/analytics/tracking package in pubspec.lock:"
  grep -E "$forbidden" pubspec.lock
fi

# --- 2. Android permissions --------------------------------------------------
# P01-06 media playback, P01-07/P01-08 optional foreground location.
# P00-11 opt-in update notifications and scheduled checks after a reboot.
allowed_permissions=(
  android.permission.ACCESS_COARSE_LOCATION
  android.permission.ACCESS_FINE_LOCATION
  android.permission.INTERNET
  android.permission.WAKE_LOCK
  android.permission.FOREGROUND_SERVICE
  android.permission.FOREGROUND_SERVICE_MEDIA_PLAYBACK
  android.permission.POST_NOTIFICATIONS
  android.permission.RECEIVE_BOOT_COMPLETED
)
manifest=android/app/src/main/AndroidManifest.xml
while IFS= read -r perm; do
  [[ -z "$perm" ]] && continue
  ok=0
  for a in "${allowed_permissions[@]+"${allowed_permissions[@]}"}"; do
    [[ "$perm" == "$a" ]] && ok=1
  done
  [[ $ok -eq 1 ]] || err "Permission not in allow-list: $perm ($manifest)"
done < <(grep -oE 'uses-permission[^>]*android:name="[^"]+"' "$manifest" |
  sed -E 's/.*android:name="([^"]+)".*/\1/' || true)

# --- 3. Exact version pins ---------------------------------------------------
unpinned=$(awk '
  /^(dependencies|dev_dependencies):/ { section = 1; next }
  /^[^ #]/ { section = 0 }
  section && /^  [a-z0-9_]+: / {
    v = $2
    if (v !~ /^[0-9]+\.[0-9]+\.[0-9]+([-+][0-9A-Za-z.-]+)?$/) print $1 " " v
  }
' pubspec.yaml)
if [[ -n "$unpinned" ]]; then
  err "Dependencies must be pinned to exact versions:"
  echo "$unpinned"
fi

# --- 4. Secret / signing files -----------------------------------------------
tracked=$(git ls-files -- . | grep -Ei '(\.jks|\.keystore|\.p12|\.pem|key\.properties|google-services\.json|GoogleService-Info\.plist|(^|/)\.env(\..+)?)$' | grep -v '\.env\.example$' || true)
if [[ -n "$tracked" ]]; then
  err "Signing keys or credential files must not be committed:"
  echo "$tracked"
fi

if [[ $fail -ne 0 ]]; then
  echo "Policy checks FAILED"
  exit 1
fi
echo "Policy checks passed"
