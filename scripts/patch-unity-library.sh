#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ANDROID_GRADLE_FILE="$ROOT_DIR/packages/expo-unity-view/android/unityLibrary/unityLibrary/build.gradle"
ANDROID_SETTINGS_FILE="$ROOT_DIR/android/settings.gradle"
ANDROID_APP_MANIFEST="$ROOT_DIR/android/app/src/main/AndroidManifest.xml"

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

patch_android_settings() {
  if [[ ! -f "$ANDROID_SETTINGS_FILE" ]]; then
    echo "[unity:patch][android] android/settings.gradle not found, skipping." >&2
    return 0
  fi

  SETTINGS_FILE="$ANDROID_SETTINGS_FILE" python3 - <<'PY'
import os
from pathlib import Path

path = Path(os.environ["SETTINGS_FILE"])
text = path.read_text()

marker = "include ':unityLibrary'"
if marker in text:
    print("[unity:patch][android] settings.gradle already includes :unityLibrary")
else:
    addition = "\n// Added by unity integration: include Unity export for expo-unity-view\n"
    addition += "include ':unityLibrary'\n"
    addition += "project(':unityLibrary').projectDir = new File(rootDir, '../packages/expo-unity-view/android/unityLibrary/unityLibrary')\n"
    path.write_text(text + addition)
    print("[unity:patch][android] Added :unityLibrary to settings.gradle")
PY
}

patch_android_manifest() {
  if [[ ! -f "$ANDROID_APP_MANIFEST" ]]; then
    echo "[unity:patch][android] android/app/src/main/AndroidManifest.xml not found, skipping." >&2
    return 0
  fi

  MANIFEST_FILE="$ANDROID_APP_MANIFEST" python3 - <<'PY'
import os
import re
from pathlib import Path

path = Path(os.environ["MANIFEST_FILE"])
text = path.read_text()
original = text

needs_tools = 'xmlns:tools=' not in text
needs_replace = 'tools:replace="android:enableOnBackInvokedCallback"' not in text

def ensure_tools_namespace(src: str) -> str:
    if 'xmlns:tools=' in src:
        return src
    match = re.search(r'<manifest\\s+([^>]*?)>', src, re.DOTALL)
    if not match:
        # Fallback: string-based insertion
        start = src.find("<manifest")
        if start == -1:
            return src
        end = src.find(">", start)
        if end == -1:
            return src
        return src[:end] + ' xmlns:tools="http://schemas.android.com/tools"' + src[end:]
    attrs = match.group(1)
    if 'xmlns:tools=' not in attrs:
        attrs = attrs.strip() + ' xmlns:tools="http://schemas.android.com/tools"'
    return src.replace(match.group(0), f"<manifest {attrs}>", 1)

def ensure_tools_replace(src: str) -> str:
    match = re.search(r'<application\\b([^>]*)>', src, re.DOTALL)
    if not match:
        # Fallback: string-based insertion
        start = src.find("<application")
        if start == -1:
            return src
        end = src.find(">", start)
        if end == -1:
            return src
        head = src[start:end]
        if 'tools:replace=' in head:
            # append to existing tools:replace
            def repl_attr(h):
                m = re.search(r'tools:replace="([^"]*)"', h)
                if not m:
                    return h
                value = m.group(1)
                if "android:enableOnBackInvokedCallback" in value:
                    return h
                return h.replace(m.group(0), f'tools:replace="{value},android:enableOnBackInvokedCallback"')
            head = repl_attr(head)
        else:
            head = head + ' tools:replace="android:enableOnBackInvokedCallback"'
        return src[:start] + head + src[end:]
    attrs = match.group(1)
    if 'tools:replace=' in attrs:
        def repl(m):
            value = m.group(1)
            if 'android:enableOnBackInvokedCallback' in value:
                return m.group(0)
            return f'tools:replace="{value},android:enableOnBackInvokedCallback"'
        new_attrs = re.sub(r'tools:replace="([^"]*)"', repl, attrs, count=1)
    else:
        new_attrs = attrs + ' tools:replace="android:enableOnBackInvokedCallback"'
    return src.replace(match.group(0), f"<application{new_attrs}>", 1)

if not needs_tools and not needs_replace:
    print("[unity:patch][android] AndroidManifest.xml already patched")
    raise SystemExit(0)

text = ensure_tools_namespace(text)
text = ensure_tools_replace(text)

if text != original:
    path.write_text(text)
    print("[unity:patch][android] Patched AndroidManifest.xml (tools:replace enableOnBackInvokedCallback)")
else:
    # Should not normally happen when needs_tools/needs_replace is true,
    # but keep a safe fallback.
    print("[unity:patch][android] AndroidManifest.xml unchanged (unexpected)")
PY
}

patch_android
patch_android_settings
patch_android_manifest
if [[ -x "$ROOT_DIR/scripts/patch-unity-library-ios.sh" ]]; then
  "$ROOT_DIR/scripts/patch-unity-library-ios.sh"
else
  echo "[unity:patch][ios] patch-unity-library-ios.sh not found, skipping." >&2
fi
