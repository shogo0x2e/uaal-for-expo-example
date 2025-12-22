#!/usr/bin/env ruby
# Ensure the app target has the Unity Data copy build phase after pod install.

require 'xcodeproj'

root = File.expand_path('..', __dir__)
proj_path = File.expand_path(File.join(root, 'ios', 'uaalforexpoexample.xcodeproj'))
phase_name = '[CP-User] Copy Unity Data to App'

data_script = <<'EOF'
set -eo pipefail

SRC_POD="${PODS_ROOT}/UnityFrameworkWrapper/Unity/Data"
SRC_LOCAL="${SRCROOT}/../packages/expo-unity-view/ios/UnityFrameworkWrapper/Unity/Data"
SRC=""
if [ -d "$SRC_POD" ]; then
  SRC="$SRC_POD"
elif [ -d "$SRC_LOCAL" ]; then
  SRC="$SRC_LOCAL"
fi

DST="${TARGET_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}/Data"

if [ -z "${TARGET_BUILD_DIR}" ] || [ -z "${UNLOCALIZED_RESOURCES_FOLDER_PATH}" ]; then
  echo "[Copy Unity Data] Skip: missing TARGET_BUILD_DIR or UNLOCALIZED_RESOURCES_FOLDER_PATH"
  exit 0
fi

if [ -z "$SRC" ]; then
  echo "[Copy Unity Data] Missing Data source. Tried:"
  echo "  $SRC_POD"
  echo "  $SRC_LOCAL"
  exit 1
fi

rsync -a --delete --chmod=u+rwX,go-rwX --copy-unsafe-links "$SRC/" "$DST/"
xattr -cr "$DST" || true
echo "[Copy Unity Data] Copied from $SRC to $DST"
EOF

unless File.exist?(proj_path)
  abort "[ensure-unity-data-phase] Xcode project not found at #{proj_path}"
end

project = Xcodeproj::Project.open(proj_path)
app_target = project.targets.find { |t| t.name == 'uaalforexpoexample' }
abort "[ensure-unity-data-phase] Target 'uaalforexpoexample' not found in #{proj_path}" unless app_target

phase = app_target.shell_script_build_phases.find { |p| p.name == phase_name }
if phase
  phase.shell_script = data_script
  action = 'updated'
else
  phase = app_target.new_shell_script_build_phase(phase_name)
  phase.shell_script = data_script
  action = 'added'
end

project.save
puts "[ensure-unity-data-phase] #{action} build phase on target 'uaalforexpoexample'"
