#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

identity_name="DuoLapse Self-Signed"
identity="$(security find-identity -p codesigning | awk -v name="$identity_name" 'index($0, name) { print $2; exit }')"
if [[ -z "$identity" ]]; then
  echo "No \"$identity_name\" signing identity in your keychain." >&2
  echo "Follow \"Signing local builds\" in RELEASING.md, then run this again." >&2
  exit 1
fi

xcodegen generate
xcodebuild build \
  -project DuoLapse.xcodeproj \
  -scheme DuoLapse \
  -configuration Release \
  -destination 'platform=macOS' \
  -derivedDataPath build \
  CODE_SIGNING_ALLOWED=NO

app=build/Build/Products/Release/DuoLapse.app
scripts/sign-app.sh "$app" "$identity"

osascript -e 'quit app "DuoLapse"' > /dev/null 2>&1 || true
rm -rf /Applications/DuoLapse.app
ditto "$app" /Applications/DuoLapse.app
open /Applications/DuoLapse.app
