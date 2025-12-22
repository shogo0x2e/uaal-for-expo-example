#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PODFILE_PATH="${1:-${ROOT_DIR}/ios/Podfile}"
TARGET_NAME="uaalforexpoexample"

if [[ ! -f "$PODFILE_PATH" ]]; then
  echo "[patch-podfile] Podfile not found at $PODFILE_PATH" >&2
  exit 1
fi

ruby - "$PODFILE_PATH" "$TARGET_NAME" <<'RUBY'
file = ARGV.fetch(0)
target_name = ARGV.fetch(1)
contents = File.read(file)
contents = contents.gsub('#{target_name}', target_name)

pod_line = "  pod 'UnityFrameworkWrapper', :path => '../packages/expo-unity-view/ios/UnityFrameworkWrapper'\n"

target_start = contents.index("target '#{target_name}' do")
abort "[patch-podfile] target '#{target_name}' not found" unless target_start

unless contents.include?(pod_line) || contents.include?("pod 'UnityFrameworkWrapper'")
  insert_after = contents.index("\n  use_expo_modules!", target_start) ||
                 contents.index("\n  use_react_native!", target_start) ||
                 contents.index("\n  post_install do", target_start)
  abort "[patch-podfile] insertion point not found" unless insert_after
  contents = contents.dup.insert(insert_after + 1, pod_line)
  puts "[patch-podfile] Injected UnityFrameworkWrapper pod"
else
  puts "[patch-podfile] UnityFrameworkWrapper already present"
end

phase_marker = "[CP-User] Copy Unity Data to App"
unless contents.include?(phase_marker)
  insert = <<~EOS
    require 'xcodeproj'

    phase_name = '[CP-User] Copy Unity Data to App'
    copy_script = <<-'EOF'
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

    installer.aggregate_targets.each do |aggregate_target|
      user_project_changed = false
      aggregate_target.user_targets.each do |user_target|
        next unless user_target.name == '#{target_name}'
        phase = user_target.shell_script_build_phases.find { |p| p.name == phase_name }
        if phase
          phase.shell_script = copy_script
        else
          phase = user_target.new_shell_script_build_phase(phase_name)
          phase.shell_script = copy_script
        end
        user_project_changed = true
      end
      aggregate_target.user_project.save if user_project_changed
    end

    app_project_path = File.join(__dir__, '#{target_name}.xcodeproj')
    if File.exist?(app_project_path)
      app_project = Xcodeproj::Project.open(app_project_path)
      app_target = app_project.targets.find { |t| t.name == '#{target_name}' }
      if app_target
        phase = app_target.shell_script_build_phases.find { |p| p.name == phase_name }
        if phase
          phase.shell_script = copy_script
        else
          phase = app_target.new_shell_script_build_phase(phase_name)
          phase.shell_script = copy_script
        end
        app_project.save
      end
    end
EOS

  start = contents.index("post_install do |installer|")
  abort "[patch-podfile] post_install do |installer| not found; Podfile layout may have changed" unless start

  closing = contents.index("\n  end\n", start)
  abort "[patch-podfile] closing '  end' for post_install not found; Podfile layout may have changed" unless closing

  contents = contents.dup.insert(closing, "\n" + insert.rstrip + "\n")
  puts "[patch-podfile] Injected Unity Data copy phase into #{file}"
else
  puts "[patch-podfile] Unity Data copy phase already present"
end

File.write(file, contents)
RUBY
