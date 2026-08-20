#!/bin/sh

# Xcode Cloud post-clone hook.
#
# Xcode Cloud's macOS runners do NOT ship Flutter. Without it, the Runner
# target's "Run Script"/"Thin Binary" build phases call `flutter`/xcode_backend.sh,
# which is not on PATH — the archive fails with exit code 127 ("command not found").
# This script installs the pinned Flutter SDK and resolves dependencies so the
# subsequent Xcode archive can find Flutter and the CocoaPods it generates.
#
# Pin matches the project (.github/workflows/ci.yml → Flutter 3.44.0).

set -e

FLUTTER_VERSION="3.44.0"
FLUTTER_HOME="$HOME/flutter"

echo "▸ Installing Flutter ${FLUTTER_VERSION}"
if [ ! -x "${FLUTTER_HOME}/bin/flutter" ]; then
  git clone https://github.com/flutter/flutter.git --depth 1 --branch "${FLUTTER_VERSION}" "${FLUTTER_HOME}"
fi
export PATH="${FLUTTER_HOME}/bin:${PATH}"

flutter --version
flutter config --no-analytics >/dev/null 2>&1 || true
flutter precache --ios

echo "▸ flutter pub get (generates ios/Flutter/Generated.xcconfig)"
cd "${CI_PRIMARY_REPOSITORY_PATH}"
flutter pub get

echo "▸ pod install"
cd "${CI_PRIMARY_REPOSITORY_PATH}/ios"
POD_INSTALL_ATTEMPT=1
while [ "${POD_INSTALL_ATTEMPT}" -le 3 ]; do
  if pod install; then
    break
  fi

  if [ "${POD_INSTALL_ATTEMPT}" -eq 3 ]; then
    echo "CocoaPods installation failed after 3 attempts." >&2
    exit 1
  fi

  POD_INSTALL_RETRY_DELAY=$((POD_INSTALL_ATTEMPT * 10))
  echo "CocoaPods download failed; retrying in ${POD_INSTALL_RETRY_DELAY}s." >&2
  sleep "${POD_INSTALL_RETRY_DELAY}"
  POD_INSTALL_ATTEMPT=$((POD_INSTALL_ATTEMPT + 1))
done

echo "Preparing Rive Native iOS libraries"
# CocoaPods creates rive_native's development-pod symlink during pod install.
# Prepare the verified libraries afterwards, then mark the exact source path
# Xcode's [CP-User] phase reads. Without that marker, the upstream phase runs
# Dart from ios/Pods and cannot locate the app pubspec.
cd "${CI_PRIMARY_REPOSITORY_PATH}"
dart run rive_native:setup --verbose --clean --platform ios

RIVE_NATIVE_IOS_ROOT="${CI_PRIMARY_REPOSITORY_PATH}/ios/.symlinks/plugins/rive_native"
RIVE_NATIVE_IOS_MARKER="${RIVE_NATIVE_IOS_ROOT}/ios/rive_marker_ios_setup_complete"
RIVE_NATIVE_DEVICE_LIBRARY="${RIVE_NATIVE_IOS_ROOT}/native/build/iphoneos/bin/release/librive_native.a"
RIVE_NATIVE_SIMULATOR_LIBRARY="${RIVE_NATIVE_IOS_ROOT}/native/build/iphoneos/bin/emulator/librive_native.a"

for RIVE_NATIVE_REQUIRED_FILE in \
  "${RIVE_NATIVE_DEVICE_LIBRARY}" \
  "${RIVE_NATIVE_SIMULATOR_LIBRARY}"
do
  if [ ! -f "${RIVE_NATIVE_REQUIRED_FILE}" ]; then
    echo "Rive Native setup did not create ${RIVE_NATIVE_REQUIRED_FILE}." >&2
    exit 1
  fi
done

touch "${RIVE_NATIVE_IOS_MARKER}"
echo "Rive Native iOS setup verified at ${RIVE_NATIVE_IOS_ROOT}."

echo "▸ Post-clone complete — Flutter available for archive."
