#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

VERSION="${1:-${VERSION:-v0.0.0}}"
APP_PATH="${2:-${APP_PATH:-$PROJECT_DIR/build/Release/ImageDrop.app}}"
OUTPUT_DIR="${3:-${OUTPUT_DIR:-$PROJECT_DIR/dist}}"
BACKGROUND_PATH="${DMG_BACKGROUND:-$PROJECT_DIR/assets/dmg-background.png}"
DMG_BACKEND="${DMG_BACKEND:-auto}"
DMG_NAME="ImageDrop-$VERSION.dmg"
DMG_PATH="$OUTPUT_DIR/$DMG_NAME"

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "error: DMG packaging must run on macOS." >&2
  exit 1
fi

if [[ -z "$VERSION" ]]; then
  echo "error: VERSION must not be empty." >&2
  exit 1
fi

if [[ ! "$VERSION" =~ ^[A-Za-z0-9][A-Za-z0-9._+-]*$ ]]; then
  echo "error: VERSION may contain only letters, numbers, dot, underscore, plus, and hyphen." >&2
  exit 1
fi

if [[ ! -d "$APP_PATH" || "$(basename "$APP_PATH")" != "ImageDrop.app" ]]; then
  echo "error: ImageDrop.app was not found at: $APP_PATH" >&2
  echo "usage: $0 [version] [path/to/ImageDrop.app] [output-directory]" >&2
  exit 1
fi

if [[ ! -f "$BACKGROUND_PATH" ]]; then
  echo "error: DMG background was not found at: $BACKGROUND_PATH" >&2
  exit 1
fi

for required_command in codesign ditto shasum; do
  if ! command -v "$required_command" >/dev/null 2>&1; then
    echo "error: required command is unavailable: $required_command" >&2
    exit 1
  fi
done

if [[ "$DMG_BACKEND" == "auto" ]]; then
  MACOS_MAJOR_VERSION="$(sw_vers -productVersion | cut -d. -f1)"
  if (( MACOS_MAJOR_VERSION >= 26 )); then
    DMG_BACKEND="dmgbuild"
  else
    DMG_BACKEND="create-dmg"
  fi
fi

case "$DMG_BACKEND" in
  create-dmg)
    if ! command -v create-dmg >/dev/null 2>&1; then
      echo "error: create-dmg is required on macOS 15 and earlier." >&2
      echo "Install it with: brew install create-dmg" >&2
      exit 1
    fi
    ;;
  dmgbuild)
    if ! command -v dmgbuild >/dev/null 2>&1; then
      echo "error: dmgbuild is required on macOS 26 and later because Finder no longer persists create-dmg backgrounds." >&2
      echo "Install it with: pipx install dmgbuild" >&2
      exit 1
    fi
    ;;
  *)
    echo "error: DMG_BACKEND must be auto, create-dmg, or dmgbuild." >&2
    exit 1
    ;;
esac

mkdir -p "$OUTPUT_DIR"

STAGING_DIR="$(mktemp -d "${TMPDIR:-/tmp}/imagedrop-dmg.XXXXXX")"
VERIFY_MOUNT_DIR=""
VERIFY_MOUNTED=0
cleanup() {
  if (( VERIFY_MOUNTED == 1 )); then
    hdiutil detach "$VERIFY_MOUNT_DIR" >/dev/null 2>&1 || true
  fi
  if [[ -n "$VERIFY_MOUNT_DIR" ]]; then
    rm -rf "$VERIFY_MOUNT_DIR"
  fi
  rm -rf "$STAGING_DIR"
}
trap cleanup EXIT

echo "Applying an ad-hoc signature to $APP_PATH"
codesign --force --deep -s - "$APP_PATH"
codesign --verify --deep --strict "$APP_PATH"

ditto "$APP_PATH" "$STAGING_DIR/ImageDrop.app"

if [[ -e "$DMG_PATH" ]]; then
  echo "Removing existing artifact: $DMG_PATH"
  rm -f "$DMG_PATH"
fi

echo "Creating $DMG_PATH with $DMG_BACKEND"
if [[ "$DMG_BACKEND" == "create-dmg" ]]; then
  create-dmg \
    --volname "ImageDrop Installer" \
    --background "$BACKGROUND_PATH" \
    --window-pos 200 120 \
    --window-size 660 400 \
    --icon-size 100 \
    --icon "ImageDrop.app" 180 140 \
    --hide-extension "ImageDrop.app" \
    --app-drop-link 480 140 \
    --no-internet-enable \
    "$DMG_PATH" \
    "$STAGING_DIR"
else
  dmgbuild \
    -s "$SCRIPT_DIR/dmgbuild_settings.py" \
    -D "app=$STAGING_DIR/ImageDrop.app" \
    -D "background=$BACKGROUND_PATH" \
    "ImageDrop Installer" \
    "$DMG_PATH"
fi

if [[ ! -f "$DMG_PATH" ]]; then
  echo "error: create-dmg completed without producing: $DMG_PATH" >&2
  exit 1
fi

VERIFY_MOUNT_DIR="$(mktemp -d "${TMPDIR:-/tmp}/imagedrop-dmg-verify.XXXXXX")"
hdiutil attach -readonly -nobrowse -mountpoint "$VERIFY_MOUNT_DIR" "$DMG_PATH" >/dev/null
VERIFY_MOUNTED=1

if [[ ! -f "$VERIFY_MOUNT_DIR/.DS_Store" ]] ||
  { ! LC_ALL=C grep -a -q "backgroundImageAlias" "$VERIFY_MOUNT_DIR/.DS_Store" &&
    ! LC_ALL=C grep -a -q "BKGD" "$VERIFY_MOUNT_DIR/.DS_Store"; }; then
  echo "error: generated DMG does not contain a Finder background record." >&2
  echo "The packaging backend reported success, but Finder would show a plain window." >&2
  exit 1
fi

hdiutil detach "$VERIFY_MOUNT_DIR" >/dev/null
VERIFY_MOUNTED=0
rm -rf "$VERIFY_MOUNT_DIR"
VERIFY_MOUNT_DIR=""

echo "SHA-256:"
shasum -a 256 "$DMG_PATH"
