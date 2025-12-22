#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
IOS_UNITY_DIR="$ROOT_DIR/packages/expo-unity-view/ios/UnityLibrary"

if [[ ! -d "$IOS_UNITY_DIR" ]]; then
  echo "[unity:patch][ios] UnityLibrary not found, skipping." >&2
  exit 0
fi

# TODO: add iOS patch rules when Unity export is in place.
echo "[unity:patch][ios] UnityLibrary detected, no patches defined yet." >&2
