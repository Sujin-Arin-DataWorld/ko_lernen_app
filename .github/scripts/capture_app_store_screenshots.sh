#!/usr/bin/env bash
set -euo pipefail

# ci_post_clone.sh runs in the previous Actions step. Persist its pinned SDK
# location explicitly because shell exports do not cross step boundaries.
export PATH="$HOME/flutter/bin:$HOME/.pub-cache/bin:$PATH"

if [[ $# -ne 1 ]]; then
  echo "usage: $0 OUTPUT_ROOT" >&2
  exit 2
fi

output_root="$1"
runtime_id="com.apple.CoreSimulator.SimRuntime.iOS-26-2"
iphone_type="com.apple.CoreSimulator.SimDeviceType.iPhone-16-Pro-Max"
ipad_type="com.apple.CoreSimulator.SimDeviceType.iPad-Pro-13-inch-M4"
app_path="$PWD/build/ios/Debug-iphonesimulator/Runner.app"
bundle_id="com.hangulsori.app"

mkdir -p "$output_root/captures" "$output_root/logs"

xcrun simctl list runtimes available -j | python3 -c \
  'import json,sys; wanted=sys.argv[1]; rows=json.load(sys.stdin)["runtimes"]; assert any(r["identifier"] == wanted and r["isAvailable"] for r in rows), wanted' \
  "$runtime_id"
xcrun simctl list devicetypes -j | python3 -c \
  'import json,sys; wanted=set(sys.argv[1:]); actual={d["identifier"] for d in json.load(sys.stdin)["devicetypes"]}; missing=wanted-actual; assert not missing, sorted(missing)' \
  "$iphone_type" "$ipad_type"

run_suffix="${GITHUB_RUN_ID:-local}-${GITHUB_RUN_ATTEMPT:-1}"
iphone_id="$(xcrun simctl create "HangulSori-iPhone-$run_suffix" "$iphone_type" "$runtime_id")"
ipad_id="$(xcrun simctl create "HangulSori-iPad-$run_suffix" "$ipad_type" "$runtime_id")"

cleanup() {
  for simulator_id in "$iphone_id" "$ipad_id"; do
    xcrun simctl shutdown "$simulator_id" >/dev/null 2>&1 || true
    xcrun simctl delete "$simulator_id" >/dev/null 2>&1 || true
  done
}
trap cleanup EXIT

xcrun simctl boot "$iphone_id"
xcrun simctl bootstatus "$iphone_id" -b

flutter build ios --simulator --debug --no-pub --config-only \
  --target=integration_test/app_store_screenshots_test.dart \
  2>&1 | tee "$output_root/logs/flutter-config.log"

# Build exactly once for the Intel simulator architecture. The same immutable
# Runner.app is installed on both device families and reused for both locales.
xcodebuild build-for-testing -workspace ios/Runner.xcworkspace -scheme Runner \
  -configuration Debug \
  -destination "platform=iOS Simulator,id=$iphone_id,arch=x86_64" \
  CODE_SIGNING_ALLOWED=NO ARCHS=x86_64 ONLY_ACTIVE_ARCH=YES \
  BUILD_DIR="$PWD/build/ios" FLUTTER_BUILD_MODE=debug \
  2>&1 | tee "$output_root/logs/ios-screenshot-build.log"
test -d "$app_path"
app_executable="$app_path/Runner"
test -f "$app_executable"
binary_sha256="$(shasum -a 256 "$app_executable" | awk '{print $1}')"
binary_bytes="$(stat -f '%z' "$app_executable")"

cat > "$output_root/device-manifest.json" <<EOF
{
  "runtimeIdentifier": "$runtime_id",
  "runtimeVersion": "26.2",
  "appExecutable": {
    "bundleId": "$bundle_id",
    "bytes": $binary_bytes,
    "sha256": "$binary_sha256"
  },
  "devices": {
    "iphone-6.9": {
      "name": "iPhone 16 Pro Max",
      "typeIdentifier": "$iphone_type",
      "udid": "$iphone_id"
    },
    "ipad-13": {
      "name": "iPad Pro 13-inch (M4)",
      "typeIdentifier": "$ipad_type",
      "udid": "$ipad_id"
    }
  }
}
EOF

for device in iphone-6.9 ipad-13; do
  if [[ "$device" == "iphone-6.9" ]]; then
    simulator_id="$iphone_id"
  else
    xcrun simctl shutdown "$iphone_id" >/dev/null 2>&1 || true
    simulator_id="$ipad_id"
    xcrun simctl boot "$simulator_id"
    xcrun simctl bootstatus "$simulator_id" -b
  fi

  for locale in de en; do
    capture_dir="$output_root/captures/$locale/$device"
    mkdir -p "$capture_dir"
    xcrun simctl terminate "$simulator_id" "$bundle_id" >/dev/null 2>&1 || true
    xcrun simctl uninstall "$simulator_id" "$bundle_id" >/dev/null 2>&1 || true
    xcrun simctl install "$simulator_id" "$app_path"
    APP_STORE_SCREENSHOT_OUTPUT="$capture_dir" \
      flutter drive --no-pub --no-dds --keep-app-running --no-uninstall-first \
        --use-application-binary="$app_path" \
        --route="/app-store-screenshots/$locale" \
        --driver=test_driver/app_store_screenshots_driver.dart \
        --target=integration_test/app_store_screenshots_test.dart \
        -d "$simulator_id" \
        2>&1 | tee "$output_root/logs/$locale-$device-driver.log"
    cp build/integration_response_data.json \
      "$output_root/logs/$locale-$device-response.json"
    xcrun simctl terminate "$simulator_id" "$bundle_id"
  done
done
