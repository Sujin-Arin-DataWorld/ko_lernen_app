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
pod install

echo "▸ Post-clone complete — Flutter available for archive."
