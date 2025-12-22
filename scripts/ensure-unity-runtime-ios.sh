#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TARGET_DIR="$ROOT_DIR/packages/expo-unity-view/ios/UnityFrameworkWrapper/Unity"

# Default to the wrapper Unity directory so users can drop the export there.
# Override with UNITY_EXPORT_PATH to point at a Unity iOS export root.
UNITY_EXPORT_PATH=${UNITY_EXPORT_PATH:-"$TARGET_DIR"}

DERIVED_DATA=${UNITY_DERIVED_DATA:-"$ROOT_DIR/artifacts/unity/DerivedData"}
PROJECT_PATH="$UNITY_EXPORT_PATH/Unity-iPhone.xcodeproj"
EXPORT_DATA_DIR="$UNITY_EXPORT_PATH/Data"
BUILT_FRAMEWORK="$DERIVED_DATA/Build/Products/Release-iphoneos/UnityFramework.framework"
NCP_HEADER_PATH="$UNITY_EXPORT_PATH/Libraries/Plugins/iOS/NativeCallProxy.h"

log() { printf '[ensure-unity-runtime-ios] %s\n' "$*"; }

require_path() {
  local path=$1 desc=$2
  if [[ ! -e "$path" ]]; then
    log "Missing ${desc}: $path"
    exit 1
  fi
}

if [[ -d "$TARGET_DIR/UnityFramework.framework" && -d "$TARGET_DIR/Data" ]]; then
  log "Unity runtime already present at $TARGET_DIR (UnityFramework.framework + Data/)"
  exit 0
fi

require_path "$PROJECT_PATH" "Unity exported Xcode project (set UNITY_EXPORT_PATH)"
require_path "$EXPORT_DATA_DIR" "Unity Data directory"

if [[ -f "$NCP_HEADER_PATH" ]]; then
  log "Ensuring NativeCallProxy.h is Public in UnityFramework headers"
  if command -v bundle >/dev/null 2>&1; then
    BUNDLE_CMD="bundle exec"
  else
    BUNDLE_CMD=""
  fi

  if ! $BUNDLE_CMD ruby - "$PROJECT_PATH" "$NCP_HEADER_PATH" <<'RUBY'
require 'xcodeproj'
require 'pathname'

project_path = Pathname(ARGV[0]).expand_path
header_abs = Pathname(ARGV[1]).expand_path
header_rel = header_abs.relative_path_from(project_path.parent).to_s

project = Xcodeproj::Project.open(project_path.to_s)
target = project.targets.find { |t| t.name == 'UnityFramework' }
raise 'UnityFramework target not found' unless target

file_ref = project.files.find { |f| f.real_path.to_s == header_abs || f.path == header_rel || f.path&.end_with?('NativeCallProxy.h') }
file_ref ||= project.main_group.find_file_by_path(header_rel)
file_ref ||= project.main_group.new_file(header_rel)

headers_phase = target.headers_build_phase
build_file = headers_phase.files.find { |bf| bf.file_ref == file_ref }
build_file ||= headers_phase.add_file_reference(file_ref)
build_file.settings ||= {}
build_file.settings['ATTRIBUTES'] = ['Public']

project.save
RUBY
  then
    echo "[ensure-unity-runtime-ios] Warning: failed to mark NativeCallProxy.h as Public" >&2
  fi
fi

mkdir -p "$DERIVED_DATA" "$TARGET_DIR"
touch "$TARGET_DIR/.keep"

log "Building UnityFramework (Release, iphoneos) from $PROJECT_PATH"
if command -v xcpretty >/dev/null 2>&1; then
  xcodebuild -project "$PROJECT_PATH" -scheme UnityFramework -configuration Release -sdk iphoneos -derivedDataPath "$DERIVED_DATA" build | xcpretty
else
  xcodebuild -project "$PROJECT_PATH" -scheme UnityFramework -configuration Release -sdk iphoneos -derivedDataPath "$DERIVED_DATA" build
fi

require_path "$BUILT_FRAMEWORK" "built UnityFramework.framework"

log "Copying UnityFramework.framework -> $TARGET_DIR"
rsync -a --delete "$BUILT_FRAMEWORK" "$TARGET_DIR/"

log "Copying Data/ -> $TARGET_DIR/Data"
rsync -a --delete "$EXPORT_DATA_DIR/" "$TARGET_DIR/Data/"

log "Done. Unity runtime is ready at $TARGET_DIR"
