#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 2 ]]; then
  echo "Usage: scripts/sign-app.sh <path to DuoLapse.app> <signing identity> [keychain]" >&2
  exit 1
fi

app="$1"
identity="$2"
keychain="${3:-}"
entitlements="$(cd "$(dirname "$0")/.." && pwd)/DuoLapse/DuoLapse.entitlements"

keychain_arguments=()
if [[ -n "$keychain" ]]; then
  keychain_arguments=(--keychain "$keychain")
fi

sign() {
  codesign --force --options runtime --timestamp=none \
    ${keychain_arguments[@]+"${keychain_arguments[@]}"} --sign "$identity" "$@"
}

sparkle="$app/Contents/Frameworks/Sparkle.framework"
if [[ -d "$sparkle" ]]; then
  for component in XPCServices/Installer.xpc Autoupdate Updater.app; do
    if [[ -e "$sparkle/Versions/B/$component" ]]; then
      sign "$sparkle/Versions/B/$component"
    fi
  done
  if [[ -e "$sparkle/Versions/B/XPCServices/Downloader.xpc" ]]; then
    sign --preserve-metadata=entitlements "$sparkle/Versions/B/XPCServices/Downloader.xpc"
  fi
  sign "$sparkle"
fi

sign --entitlements "$entitlements" "$app"
codesign --verify --deep --strict --verbose=2 "$app"
codesign --display --requirements - "$app"
