#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ANDROID_GRADLE_FILE="$ROOT_DIR/packages/expo-unity-view/android/unityLibrary/unityLibrary/build.gradle"

patch_android() {
  if [[ ! -f "$ANDROID_GRADLE_FILE" ]]; then
    echo "[unity:patch][android] unityLibrary build.gradle not found, skipping." >&2
    return 0
  fi

  GRADLE_FILE="$ANDROID_GRADLE_FILE" python3 - <<'PY'
import os
import sys
from pathlib import Path

path = Path(os.environ["GRADLE_FILE"])
text = path.read_text()
original = text

block_props = """def unityPropsFile = file(\"${projectDir}/../gradle.properties\")
if (unityPropsFile.exists()) {
    def unityProps = new Properties()
    unityPropsFile.withInputStream { unityProps.load(it) }
    unityProps.each { key, value ->
        if (!project.hasProperty(key)) {
            project.ext.set(key, value)
        }
    }
}
"""

if block_props not in text:
    marker = "apply from: '../shared/common.gradle'\n"
    idx = text.find(marker)
    if idx == -1:
        print("[unity:patch][android] anchor for unityPropsFile not found.")
        sys.exit(1)
    insert_pos = idx + len(marker)
    text = text[:insert_pos] + "\n" + block_props + text[insert_pos:]

block_stream = "def unityStreamingAssets = project.findProperty(\"unityStreamingAssets\") ?: \"\"\n"
if block_stream not in text:
    marker = "\nandroid {"
    idx = text.find(marker)
    if idx == -1:
        print("[unity:patch][android] anchor for unityStreamingAssets not found.")
        sys.exit(1)
    text = text[:idx] + "\n" + block_stream + text[idx:]

if text != original:
    path.write_text(text)
PY
}

patch_android
if [[ -x "$ROOT_DIR/scripts/patch-unity-library-ios.sh" ]]; then
  "$ROOT_DIR/scripts/patch-unity-library-ios.sh"
else
  echo "[unity:patch][ios] patch-unity-library-ios.sh not found, skipping." >&2
fi
