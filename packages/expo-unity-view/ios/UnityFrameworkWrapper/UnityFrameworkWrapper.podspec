Pod::Spec.new do |s|
  s.name         = "UnityFrameworkWrapper"
  s.version      = "1.0.0"
  s.summary      = "Unity as a Library wrapped as a CocoaPod"
  s.homepage     = "https://github.com/shogo0x2e/uaal-for-expo-example"
  s.license      = { :type => "Proprietary", :text => "Copyright (c) 2025" }
  s.author       = { "Shogo Kitada" => "contact@shogo0x2e.com" }

  # Local development pod
  s.source       = { :path => "." }

  s.platform     = :ios, "15.1"

  s.source_files = "Sources/**/*.{h,m,mm,swift}"
  s.swift_version = "5.9"

  s.vendored_frameworks = "Unity/UnityFramework.framework"

  s.script_phase = {
    :name => "Copy Unity Data",
    :script => <<-SCRIPT,
      set -e
      SRC="${PODS_TARGET_SRCROOT}/Unity/Data"
      DEST="${TARGET_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}/Data"
      mkdir -p "${DEST}"
      if [ -d "${SRC}" ]; then
        rsync -a --delete "${SRC}/" "${DEST}/"
      fi
    SCRIPT
    :execution_position => :after_compile,
    :input_files => ["${PODS_TARGET_SRCROOT}/Unity/Data"],
    :output_files => ["${TARGET_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}/Data"]
  }

  s.frameworks = [
    "Metal", "MetalKit", "AVFoundation",
    "CoreVideo", "CoreMedia", "GameController"
  ]
  s.libraries = "c++"

  s.preserve_paths = "Unity/**/*"
end
