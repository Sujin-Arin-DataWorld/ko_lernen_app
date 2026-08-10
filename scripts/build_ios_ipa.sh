#!/usr/bin/env bash
# App Store 제출용 .ipa 빌드 — macOS 전용, 한 방에 끝.
#
# 사용:
#   export APPLE_TEAM_ID=ABCDE12345      # developer.apple.com → Membership details
#   export RC_IOS_KEY=appl_xxxxxxxx      # RevenueCat 공개 Apple SDK 키
#   bash scripts/build_ios_ipa.sh
#
# 결과:  build/ios/ipa/*.ipa  (App Store Connect 에 올릴 그 파일)
# 절차 전체(계정 등록~업로드~심사)는 docs/store/APPSTORE_UPLOAD_KO.md 참조.
# 자격증명 세부 설정은 docs/store/ios-external-setup.md 가 정본.
#
# 이 스크립트는 저장소에 자격증명을 남기지 않는다. ExportOptions.plist 의 빈
# teamID 는 커밋본을 고치지 않고 임시 복사본에만 주입한다.
#
# 옵션 환경변수:
#   SKIP_POD_INSTALL=1   pod install 생략 (직전 빌드에서 Pods 그대로 재사용)
#   SKIP_VERIFY=1        dart 검증 게이트 생략 (권장하지 않음 — 디버깅용)
#   ASC_KEY_ID / ASC_ISSUER_ID / ASC_KEY_PATH
#                        셋 다 있으면 빌드 후 App Store Connect 업로드까지 수행.
#                        없으면 .ipa 만 만들고 멈춘다(Transporter.app 으로 수동 업로드).

set -euo pipefail

cd "$(dirname "$0")/.." # repo root

step() { printf '\n\033[1m── %s\033[0m\n' "$1"; }
ok() { printf '✅ %s\n' "$1"; }
die() {
  printf '\n❌ %s\n' "$1" >&2
  exit 1
}

# ── 0. 환경 전제 ────────────────────────────────────────────────
step "환경 확인"

[ "$(uname -s)" = Darwin ] ||
  die "macOS 전용이다. .ipa 는 Xcode 코드사인이 필요해 리눅스/윈도우에서 만들 수 없다."

for cmd in flutter dart pod xcodebuild; do
  command -v "$cmd" >/dev/null ||
    die "$cmd 없음. flutter/dart 는 Flutter SDK, pod 는 'sudo gem install cocoapods', xcodebuild 는 Xcode + 'sudo xcode-select -s /Applications/Xcode.app' 로 설치."
done
ok "flutter · dart · pod · xcodebuild"

xcodebuild -runFirstLaunch >/dev/null 2>&1 || true
xcrun --find xcodebuild >/dev/null 2>&1 ||
  die "Xcode Command Line Tools 가 Xcode.app 을 가리키지 않는다. 'sudo xcode-select -s /Applications/Xcode.app' 실행."

: "${APPLE_TEAM_ID:?APPLE_TEAM_ID 미설정 — developer.apple.com → Membership details 의 10자 Team ID}"
[ "${#APPLE_TEAM_ID}" -eq 10 ] ||
  die "APPLE_TEAM_ID 는 10자여야 한다 (지금 ${#APPLE_TEAM_ID}자)."
ok "APPLE_TEAM_ID (10자)"

: "${RC_IOS_KEY:?RC_IOS_KEY 미설정 — RevenueCat Project Settings → API keys 의 공개 Apple SDK 키}"
case "$RC_IOS_KEY" in
appl_*) ok "RC_IOS_KEY (appl_ 접두사)" ;;
*) die "RC_IOS_KEY 가 Apple 공개 SDK 키가 아니다 (appl_ 로 시작해야 함). secret 키를 앱에 넣지 말 것." ;;
esac

[ -s ios/Runner/GoogleService-Info.plist ] ||
  die "ios/Runner/GoogleService-Info.plist 없음 (의도적 gitignore). docs/store/ios-external-setup.md §1 대로 'flutterfire configure --platforms ios' 로 로컬 생성할 것."
plutil -lint ios/Runner/GoogleService-Info.plist >/dev/null ||
  die "GoogleService-Info.plist 가 유효한 plist 가 아니다."
ok "GoogleService-Info.plist (로컬)"

version_line="$(grep -m1 '^version:' pubspec.yaml | awk '{print $2}')"
ok "빌드 대상 버전: $version_line   (CFBundleShortVersionString+CFBundleVersion 로 주입)"
printf '   ⚠️  빌드번호(+뒤 숫자)는 App Store Connect 에 이미 올라간 값과 겹치면 거부된다.\n'
printf '      겹치면 pubspec.yaml 의 version 뒷자리만 올리고 다시 돌릴 것.\n'

# ── 1. 의존성 ──────────────────────────────────────────────────
step "의존성"
flutter pub get
if [ "${SKIP_POD_INSTALL:-0}" = 1 ]; then
  ok "pod install 생략 (SKIP_POD_INSTALL=1)"
else
  (cd ios && pod install --repo-update)
fi
[ -f ios/Podfile.lock ] || die "ios/Podfile.lock 미생성 — pod install 실패."
grep -Fq 'GoogleMLKit/TextRecognitionKorean' ios/Podfile.lock ||
  die "Podfile.lock 에 GoogleMLKit/TextRecognitionKorean 없음 — 책 OCR 이 죽은 채로 제출된다."
ok "Pods (한국어 OCR 포함)"

# ── 2. 검증 게이트 ─────────────────────────────────────────────
if [ "${SKIP_VERIFY:-0}" = 1 ]; then
  step "검증 게이트 생략 (SKIP_VERIFY=1)"
else
  step "검증 게이트"
  dart run tool/verify_ios_firebase_config.dart
  dart run tool/verify_ios_store_contract.dart
  ok "Firebase iOS 설정 · iOS/iPad 스토어 계약"
fi

# ── 3. ExportOptions (teamID 주입, 커밋본은 안 건드림) ──────────
step "ExportOptions"
workdir="$(mktemp -d)"
trap 'rm -rf "$workdir"' EXIT
export_options="$workdir/ExportOptions.plist"
cp ios/ExportOptions.plist "$export_options"
/usr/libexec/PlistBuddy -c "Set :teamID $APPLE_TEAM_ID" "$export_options"
[ "$(plutil -extract teamID raw "$export_options")" = "$APPLE_TEAM_ID" ] ||
  die "ExportOptions 에 teamID 주입 실패."
ok "teamID 주입 (임시본 · 저장소 미변경)"

# ── 4. 빌드 ────────────────────────────────────────────────────
step "빌드 (몇 분 걸린다)"
git_commit="$(git rev-parse --short HEAD 2>/dev/null || echo unknown)"
flutter build ipa \
  --release \
  --export-options-plist="$export_options" \
  --dart-define="RC_IOS_KEY=$RC_IOS_KEY" \
  --dart-define="GIT_COMMIT=$git_commit"

ipa="$(find build/ios/ipa -maxdepth 1 -name '*.ipa' -print -quit 2>/dev/null || true)"
[ -n "$ipa" ] && [ -s "$ipa" ] ||
  die "ipa 미생성. 대개 서명 문제다 — Xcode 에서 ios/Runner.xcworkspace 를 열고 Runner → Signing & Capabilities 에서 팀을 고른 뒤 다시 돌릴 것."
ok "$ipa  ($(du -h "$ipa" | cut -f1))"

# ── 5. 업로드 (선택) ───────────────────────────────────────────
if [ -n "${ASC_KEY_ID:-}" ] && [ -n "${ASC_ISSUER_ID:-}" ] && [ -n "${ASC_KEY_PATH:-}" ]; then
  step "App Store Connect 업로드"
  [ -s "$ASC_KEY_PATH" ] || die "ASC_KEY_PATH 파일 없음: $ASC_KEY_PATH"
  # altool 은 ~/.appstoreconnect/private_keys/AuthKey_<KEYID>.p8 규칙을 따른다.
  keydir="$HOME/.appstoreconnect/private_keys"
  mkdir -p "$keydir"
  cp "$ASC_KEY_PATH" "$keydir/AuthKey_${ASC_KEY_ID}.p8"
  chmod 600 "$keydir/AuthKey_${ASC_KEY_ID}.p8"
  xcrun altool --validate-app -f "$ipa" -t ios \
    --apiKey "$ASC_KEY_ID" --apiIssuer "$ASC_ISSUER_ID"
  xcrun altool --upload-app -f "$ipa" -t ios \
    --apiKey "$ASC_KEY_ID" --apiIssuer "$ASC_ISSUER_ID"
  ok "업로드 완료 — App Store Connect → TestFlight 에서 처리(10~30분) 후 나타난다."
else
  cat <<EOF

──────────────────────────────────────────────────────────────
🎉 올릴 파일이 나왔다:

   $ipa

업로드 방법 (둘 중 아무거나):

  A) Transporter.app  ← 처음이면 이게 제일 쉽다
     Mac App Store 에서 'Transporter' 설치 → 앱 열고 Apple ID 로그인
     → 위 .ipa 를 창에 끌어다 놓기 → Deliver

  B) 이 스크립트로 자동 업로드
     App Store Connect → Users and Access → Integrations → App Store Connect API
     에서 키를 만들고 .p8 를 받은 뒤:
       export ASC_KEY_ID=XXXXXXXXXX
       export ASC_ISSUER_ID=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
       export ASC_KEY_PATH=~/Downloads/AuthKey_XXXXXXXXXX.p8
       bash scripts/build_ios_ipa.sh

⚠️ 업로드 전에 App Store Connect 에 앱 레코드(com.sujinarin.koLernenApp)가
   먼저 만들어져 있어야 한다. 없으면 업로드가 거부된다.
   전체 절차: docs/store/APPSTORE_UPLOAD_KO.md
──────────────────────────────────────────────────────────────
EOF
fi
