# Hangul Sori Android Closed Testing 안내

이 안내는 학습 루프 Phase 5의 Android 비공개 베타용이다. 설치는 **Google Play
Closed Testing** 경로만 사용한다. APK를 따로 내려받거나 Play Protect 경고를 우회하지
않는다. 그래야 실제 출시 경로의 App Check, 업데이트, 서명 동작을 함께 확인할 수 있다.

테스트 기간과 현재 후보의 정확한 커밋, versionCode, opt-in 링크는
docs/store/closed-testing-checklist-v2.md의 실행 기록에서 확인한다.

## 테스터가 설치하는 방법

1. 초대받은 Google 계정으로 Play Console opt-in 링크를 연다.
2. **Tester werden**을 선택한 뒤 Google Play에서 Hangul Sori를 설치하거나 업데이트한다.
3. Play Store의 앱 정보에서 beta 트랙과 새 버전이 보이는지 확인한다.
4. 문제가 있으면 앱을 삭제하거나 데이터를 초기화하기 전에 Tiger Pulse 피드백을 남긴다.
   기존 설치 위 업데이트 보존은 별도 검증 항목이다.

### 테스터에게 보낼 짧은 독일어 안내

```text
Danke, dass du Hangul Sori im geschlossenen Android-Test ausprobierst.

Bitte öffne den Einladungslink mit deinem Google-Konto, tritt dem Test bei und
installiere oder aktualisiere die App über Google Play. Bitte installiere keine
APK-Datei aus einem Chat oder einer Cloud.

Probiere im ersten verfügbaren Vokabel-Pack jede Lernkarte aus, beantworte Quiz
und Boss und prüfe danach, ob der nächste Pack bei mindestens 70 % freigeschaltet
wird. Du kannst Wörter freiwillig eintippen. Das blockiert deinen Fortschritt nicht.

Melde Probleme über Tiger Pulse. Bitte schreibe dort keine Kontaktdaten,
persönlichen Informationen oder koreanischen Lernantworten hinein.
```

## 배정된 첫 팩 확인

첫 사용 흐름에서는 첫 번째 사용 가능한 단어팩을 열고 아래를 확인한다.

1. Learn에서 **모든 카드의 앞면과 뒷면**을 본다. Boss 단어도 Learn에서 먼저 보인다.
2. Learn 뒤 Quiz와 Boss의 문제 순서가 Learn 순서를 그대로 반복하지 않는다.
3. Boss에서 70% 이상을 맞히면 팩은 clear되고 다음 팩이 열린다.
4. 앱을 종료해 다시 열어도 팩 완료와 다음 팩 잠금 해제 상태가 유지된다.
5. Boss는 4지선다 인식 평가다. 장기 숙달이나 독립 회상 평가로 해석하지 않는다.

의도적으로 틀린 뒤 다시 맞혀도 완료, XP, 재시도 흐름은 정상이어야 한다. 단발 오답은
Hard Words 안내를 만들지 않는다. 기존 기준에 닿을 만큼 반복해서 틀린 단어에서만
어려운 단어 연습 안내가 보일 수 있다.

결과 화면의 선택형 타이핑 회상은 사용해도 되고 건너뛰어도 된다. 힌트와 정답 보기의
의미가 분명한지, 그리고 이 연습이 팩 완료나 다음 팩 해금을 막지 않는지를 알려 달라.

## 담당별 추가 확인

- 새 계정 또는 새 앱 데이터: 첫 학습 경로를 처음부터 확인한다.
- 기존 설치를 업데이트: 설치 전 데이터를 지우지 않고, 업데이트 뒤 팩 진행도가 남는지 확인한다.
- 기기 매트릭스: Android 버전과 화면 크기, 130~150% 글자 크기, 회전, 분할 화면을 나누어 확인한다.

배정된 조건이 무엇인지 확실하지 않으면 테스트 담당자에게 먼저 물어본다. 임의로
계정을 바꾸거나 데이터를 초기화하지 않는다.

## 피드백과 개인정보

Tiger Pulse의 구조화된 피드백을 우선 사용한다. 다음 정보를 짧게 적으면 충분하다.

- 문제가 난 화면과 재현 순서
- 기대한 동작과 실제 동작
- 기기 모델, Android 버전, 글자 크기, 네트워크 상태

자유 텍스트에는 이름, 이메일, 연락처, 계정 식별자, 학습 답안, 또는 개인정보가 보이는
스크린샷을 넣지 않는다. 스크린샷이 꼭 필요하면 개인정보와 학습 답안을 가린다.

## Release owner only: Closed-testing AAB

테스터에게 이 명령이나 AAB를 전달하지 않는다. 정확한 clean release commit에서만 아래
명령을 실행하고, Play Console의 최고 versionCode보다 큰지 먼저 확인한다.

```bash
release_sha=$(git rev-parse --short HEAD)
flutter build appbundle --release --obfuscate \
  --split-debug-info=build/app/outputs/symbols \
  --dart-define=ENABLE_TESTER_FEEDBACK=true \
  --dart-define=GIT_COMMIT="$release_sha"
```

모든 빌드는 결제·구독 플래그 없이 전체 학습 콘텐츠를 연다. 저장된 팩 진행도,
70% clear, 다음 팩 잠금 해제 같은 학습 순서는 그대로 유지한다. 전체 후보 절차와 14일 종료 기준은
docs/store/closed-testing-checklist-v2.md를 따른다.
