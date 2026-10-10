"""Keep the review handoff consistent with the user's latest design critique."""
from pathlib import Path
import json

ROOT=Path(__file__).resolve().parent
documents={
'FLOW_AND_HANDOFF.md':'''# 엽전 보상 · 정리한 C안의 흐름과 구현 명세

2026-10-10 최신 방향. 사용자가 이전 A/B의 과한 장식을 지적해 구현을 중단하고, `refined.html`을 새 검토 제안으로 만들었다. 판단 근거는 `DESIGN_CRITIQUE.md`, 스타일 토큰은 `refined-tokens.css`다. 사용자 승인·앱 병합·배포가 완료됐다는 뜻이 아니다.

## 시각 권한

한지/녹청/나무의 재질과 원본 3D 도깨비/엽전은 유지한다. 각 화면은 중심 오브젝트 하나와 명확한 주 행동을 가진다. 새 글자·금액·잔액·버튼은 실제 HTML이다. 이전 보드의 글자를 포함한 PNG를 배경으로 쓰지 않는다.

`approved-reference.html`에서 이전 승인 도깨비 두 구도만 원본 비율대로 확인할 수 있다. `design/secret-board.png`, `design/ab-board.png`와 `design/rejected/`는 사용자 거절 방향이며 복사 금지다. 금장 틀·꽃 테두리·대문·봉인 옷감·물음표 오브젝트·장식 풍경은 새 정리안에서 사용하지 않는다.

## 정보 구조와 흐름

학습 결과는 끝낸 내용을, 영수증은 이번 지급과 이유를, 지갑/건설은 잔액과 사용 조건을, 다음 학습은 이어갈 공부를 담당한다. 단청·XP·퀘스트 장식 상자는 건설용 엽전과 합치지 않는다. 새 UI는 “나의 일두고택”으로 표시하며 특정 건물 이름이나 전체 공정 수를 고정하지 않는다. 실제 서비스의 sarangchae/b2 구분이 고택의 모든 건물을 개별 구매하는 모델이라는 뜻은 아니다.

```mermaid
flowchart TD
 A[학습 완료·결과 저장] --> B{지급 확인}
 B -->|첫20| F[도깨비 보상·금액·이유]
 B -->|둘째10| S[짧은 엽전 수령]
 B -->|확인 중| P[결과 저장·계속 학습]
 B -->|한도 또는 중복| Z[추가 지급 없음]
 B -->|공정 자격 해금40| M[건설 지원 안내]
 F --> W[나의 일두고택·현재 엽전]
 S --> L[계속 학습]
 M --> W
 W --> C{학습 자격·잔액40 이상}
 C -->|부족| L
 C -->|가능| K[40 사용 확인·전후 잔액]
 K -->|확정| D[40 차감·소유 공정 증가]
 D --> E[건설 연출]
 E --> H[승인된 현재 보유 모습]
 H --> L
```

영상/엽전 터치는 지급·지출을 발생시키지 않는다. 실제 앱에서는 YeopjeonService의 확정 영수증을 받아야 하며 예시 잔액이나 애니메이션 타이머를 원장으로 쓰면 안 된다. 기본 두 화면은 서로 다른 예시다. 왼쪽은 첫 학습 +20/잔액40, 오른쪽은 공정 지원 +40/잔액70이다. 한 학습의 고정 보상이 +60이라는 뜻이 아니다.

새 정리안에서 도깨비/엽전 터치, 일두고택 이동, 40 사용 확인, 한 번 차감, 건설 완료/다음 학습을 누를 수 있다. 검토 설정은 첫20/둘째10/지원40/확인 중/한도/부족/학습 조건 부족, KO/DE/EN, 100/150/200%, 동작 줄이기를 제공한다. 복구·중복·클라우드 합치기 등 서비스의 더 넓은 경계는 `AUDIT.md`에 기록했다. 새 정리안이 모든 예외 상태를 구현했다는 뜻은 아니다. 이전 12상태 실험은 보존되지만 기본 화면에 연결하지 않는다.

## 모션과 투명 영상

첫 보상은 원본5.04초/960×960/24fps/121프레임을 유지한 `assets/making_money_alpha.webm`을 한 번 재생한다. 약3.7초에 다섯 엽전이 지갑으로 이동한다. 버튼 눌림140ms/2px, 터치 반응700ms, 파동800ms. 상시 입자 루프는 없다. 영상 넘기기는 장면 내부의 독립 버튼이며 금액/CTA를 밀어내지 않는다.

VP9에 실제 알파가 인코딩된 파생 파일이고 원본 MP4는 보존했다. 디코딩 알파 범위0–255, 모든 프레임 모서리 알파0, 한지/녹청 주요 프레임을 확인했다. 밝은 효과에 약한 압축/흰 매트 흔적은 남을 수 있다. 파일 증거는 `media-review/video-alpha-report.json`, 직접 검토는 `media.html`이다.

HTML에서 투명 재생/종료를 확인했다. Flutter Android/iOS의 동일한 알파 지원은 확인하지 않았다. 경로만 바꿔 지원된다고 가정하지 않는다. 흰 MP4를 새 사용자 화면의 자동 대체 영상으로 연결하지 않는다.

## 한옥 정본 교체와 비공개

현재 한옥 원본의 배경 수정은 보류했다. 새 정본으로 바뀔 자산을 임시 가공하거나 미래 형태를 새로 고정하지 않는다. 카탈로그는 승인 단계0개/새 정본 대기다. 새 정리안은 지금 한옥 파일을 로드하지 않는다.

새 정본은 투명 RGBA PNG/WebP, 건물별 기하/공정/카메라/재질을 함께 승인한다. 승인과 실제 알파 검사 후 현재 소유 단계만 연결한다. 미래 그림/실루엣/이름은 미리 조회하거나 표시하지 않는다. 원장과 그림은 독립적이며 그림 누락이 확정 지급/건설을 되돌리지 않는다. 전체 고택의 단계 매핑이 확정되면 보유 아트 슬롯을 추가한다. `verify_hanok_assets.py`는 빈 카탈로그도 대기 상태로 명시한다.

## 접근성과 검증

375×812/100%에서 금액과 행동이 한 화면에 있다. 200%는 실제 글자를 줄바꿈하고 필요 시 세로 스크롤한다. 가로844×390은 오브젝트/설명을 나란히 둔다. 앱 버튼은 최소44px, 주 버튼54px. reduced motion은 영상·비행·파동을 생략한다. 단색 토큰 대비는 본문13.57:1, 보조7.05:1, 버튼8.58:1이며 전체 앱 WCAG 인증은 아니다. 실제 실행/미검증 범위는 `QA.md`다.

## 스킬과 이어받기

현재 비평은 design-system-builder, ui-ux-designer, ui-styling, ux-audit-critique의 토큰/위계/모바일/비평 원칙을 적용했다. 이전 조사/흐름/영상에는 user-flows, information-architecture, ui-ux-pro-max, high-fidelity-mockups, mobile-app-ui, microinteractions-motion, accessibility-audit, design-handoff, imagegen을 사용했다. 선택과 이유는 `audit.html`에 있다. 캐시737개를 설치된 스킬737개로 해석하지 않는다.

경로: C:/dev/hangulsori/ko_lernen_app_worktrees/yeopjeon-c-mockups-20261009/tool/yeopjeon_c_mockups. 브랜치: session/yeopjeon-c-mockups-20261009. 기반 HEAD:44727c1921b4b7f40748ac0d210d0ca62a094028. 앱 소스·기존 한옥 정본·메인 작업은 수정하지 않았다. 새 정리안을 사용자 승인/런타임/출시 완료로 해석하지 않는다.
''',
'README.md':'''# Hangul Sori · 엽전 보상 디자인 검토

2026-10-10 최신: 과한 장식의 A/B를 중단하고 재질과 입체 오브젝트를 남긴 정리안. `DESIGN_CRITIQUE.md`가 현재 판단 기준이다. HTML 검토 패키지이며 실제 Flutter 병합/배포 패키지가 아니다.

폴더: C:/dev/hangulsori/ko_lernen_app_worktrees/yeopjeon-c-mockups-20261009/tool/yeopjeon_c_mockups.

```powershell
rtk proxy python -X utf8 server.py
```

http://127.0.0.1:8793/ 에서 새 정리안이 열린다. 폴더를 통째로 복사하면 화면의 자산/폰트/투명 영상이 함께 이동한다. 원본430이미지 전체는 별도 생성 이미지 폴더에 있고, 이 패키지는 조사 기록/contact sheet를 제공한다.

- refined.html: 새 보상/일두고택 정리안. 실제 글자/버튼/잔액/터치/투명 영상.
- refined.html?solo=1&view=reward: 학습 보상 한 화면.
- refined.html?solo=1&view=estate: 일두고택 한 화면.
- refined.html?solo=1&view=reward&play=1: 영상 시작부터 검토.
- DESIGN_CRITIQUE.md: 문제·우선순위·남길 재질·덜어낼 장식·토큰.
- refined-tokens.css: 색/간격/컨트롤의 의미 기반 토큰.
- AUDIT.md: 실제 지급 대상/금액/코드 존재 상태의 조사 시점 기록.
- FLOW_AND_HANDOFF.md: 흐름/모션/비공개/정본 교체/한계.
- QA.md: 실제 검증과 미검증 범위.
- media.html: 투명 영상 한지/녹청/격자 검토.
- audit.html: Oct2–9 이미지/영상/스킬 조사 목록.
- approved-reference.html: 이전 승인 도깨비 두 구도 보존.
- review-proof/proof-refined-pair.jpg: 브라우저 캡처.
- asset-provenance.json / PACKAGE_MANIFEST.json: 원본/파생 자산과 파일 SHA-256.

한옥은 새 정본을 기다리므로 실제 파일을 새 화면에 연결하지 않았다. 미래 형태/단계명/전체 단계 수/봉인 옷감을 미리 보여주지 않는다. design/rejected, design/secret-board.png, design/ab-board.png는 사용자 거절 방향으로 기본 화면에 연결하지 않는다.

```powershell
rtk proxy python -X utf8 verify_package.py
rtk proxy python -X utf8 verify_hanok_assets.py
```

transparent_video.py는 원본 MP4를 보존하고 VP9 알파 파생 영상을 재생성한다. 재생성에는 OpenCV/NumPy/FFmpeg가 필요하다. 목업 재생은 외부 CDN 없이 제공 파일을 사용한다.
''',
'QA.md':'''# 실제 검증 결과

2026-10-10. 검토용 HTML/자료의 검증이다. 앱 승인·Flutter 통합·스토어 배포·실기기 QA를 의미하지 않는다.

## 현재 정리안

Codex 브라우저 API로 실제 UI를 조작하고 DOM/렌더를 확인했다.

| 검증 | 실제 결과 |
|---|---|
| 375×812, KO/DE/EN, 첫20/둘째10/지원40/확인 중/한도/부족/학습 조건 부족 | 21조합: 가로/본문 넘침 없음, 주 CTA 화면 안 |
| 200% 첫 보상/지원, KO/DE/EN | 6조합. 첫 DE/EN 단위의 가로 넘침 발견→줄바꿈 수정→두 실패 조합 재검증 통과. 세로 스크롤/실제 텍스트 유지 |
| 844×390, EN 첫 보상/지원/확인 중/학습 조건 부족 | 4조합: 가로/본문 넘침 없음, CTA 화면 안 |
| 엽전 터치 | phase=playing, 잔액70 유지, 장식 상태 안내 |
| 건설 확인/빠른 두 번 클릭 | 사용 전70/후30 표시, 차감1회 balance30/spends1/eligible=false |
| 건설 완료 | 완료 화면과 40 사용 완료 안내 |
| 동작 줄이기 | 체크true, 영상 hidden, transition0s, balance40 유지 |
| 실제 투명 영상 | WebM, playing→settled, 지급 안내, balance40 유지, 흰 MP4 자동 대체0 |
| 영상 넘기기 | 영수증/CTA를 밀지 않는 장면 내부 독립 버튼으로 보완 |
| 텍스트/기본 색 | 실제 DOM 글자, 44/54px 앱 버튼, 단색 토큰 대비13.57/7.05/8.58 |
| 미래 한옥 | 새 화면에 한옥/미래 공정 그림0, 사랑채/7 of16 표시 없음 |

정적 캡처: review-proof/proof-refined-pair.jpg. 시각 기준은 이전 PNG 픽셀 복제가 아닌 DESIGN_CRITIQUE.md와 실제 HTML이다.

## 영상 파일

원본 MP4 보존. 파생 WebM은960×960/24fps/121프레임/VP9알파+Opus/약5.04초. 디코딩 알파0–255, 모든 프레임 모서리 알파max0, 투명 픽셀 비율 최소76.543%. 녹청/한지 주요 프레임을 육안 검토했다. 밝은 효과에 약한 압축/흰 매트 흔적이 남을 수 있다. SHA/측정은 media-review/video-alpha-report.json이다.

## 이전 실험에서 이미 수행한 검증

이전 HTML의 DE100%12상태, 3언어 보상/지원/확인 중/학습 조건/부족, 200% 보상/지원/지갑, 가로6상태, 960×900 확대를 확인했다. 큰 글자 지갑의 DE/EN 가로 넘침은 수정 후3언어를 재검증했다. 영상/한 번 차감/동작 줄이기/미래 이미지 없음도 확인했다. 사용자가 장식/봉인 방향을 거절했으므로 새 기본 화면에서 제외했다. 이 기록을 새 정리안 전체의 검증으로 자동 적용하지 않는다.

## 서비스 기준

기반 SHA44727c1921b4b7f40748ac0d210d0ca62a094028에서 다음 명령으로20개 테스트 통과를 확인했다. 이번 작업은 서비스 원장을 변경하지 않았다.

```powershell
rtk proxy flutter test test/services/yeopjeon_service_test.dart test/services/yeopjeon_learning_checkpoint_test.dart
```

JS 구문·자산 SHA·패키지 참조·한옥 카탈로그도 검사했다. 카탈로그0개/새 정본 대기는 새 한옥의 투명 자산 검증 완료를 뜻하지 않는다.

## 미검증 범위

Flutter 새 화면·Android/iOS 알파 재생·실기기 성능/햅틱/오디오·TalkBack/VoiceOver·계정 전환·클라우드 동시 갱신·스토어 출시는 포함하지 않는다. 메인/다른 C안 세션의 작업은 수정하거나 승격하지 않았다.
'''
}
for name,body in documents.items():
    (ROOT/name).write_text(body,encoding='utf-8')
inventory=ROOT/'audit/skill-inventory.json'
rows=json.loads(inventory.read_text(encoding='utf-8'))
reasons={'design-system-builder':'Requested: semantic tokens and restrained component rules','ui-styling':'Requested: hierarchy, mobile layout and reusable styling principles','ux-audit-critique':'Requested: severity-based critique and reduction of decoration'}
for row in rows:
    if row['name'] in reasons:
        row['match']='selected';row['reason']=reasons[row['name']]
inventory.write_text(json.dumps(rows,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print(json.dumps({'documentsUpdated':list(documents),'selectedSkills':sum(x.get('match')=='selected' for x in rows)},ensure_ascii=False))
