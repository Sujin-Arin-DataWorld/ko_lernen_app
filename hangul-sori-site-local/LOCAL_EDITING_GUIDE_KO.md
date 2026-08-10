# 한글소리 사이트 로컬 수정 안내

이 폴더는 현재 배포된 한글소리 사이트의 수정용 원본 프로젝트입니다. 단순 화면 캡처가 아니라 React, TypeScript, CSS와 이미지 및 영상이 포함된 실제 소스입니다.

## 1. Mac에서 사이트 열기

이 프로젝트는 Python 프로젝트가 아니므로 `venv`를 켤 필요가 없습니다. Node.js를 사용합니다.

터미널에서 압축을 푼 폴더로 이동한 뒤 아래 명령을 실행하세요.

```bash
node -v
npm install
npm run dev
```

Node.js 버전은 `22.13.0` 이상이 필요합니다. `npm run dev`를 실행하면 터미널에 로컬 주소가 표시됩니다. 그 주소를 브라우저에서 열면 수정 중인 사이트를 확인할 수 있습니다.

종료할 때는 터미널에서 `Control + C`를 누르세요.

## 2. 가장 자주 수정할 파일

| 수정할 내용 | 파일 |
| --- | --- |
| 독일어, 영어, 한국어 메인 문구 | `app/site.tsx` |
| 메인 화면 구성과 각 섹션 | `app/site.tsx` |
| 색상, 글꼴, 카드, 모바일 디자인 | `app/globals.css` |
| 사이트 제목과 검색용 설명 | `app/layout.tsx` |
| 개인정보 처리방침과 법적 공통 레이아웃 | `app/legal.tsx` |
| 개인정보 처리방침 페이지 | `app/privacy/page.tsx` |
| 이용약관 | `app/terms/page.tsx` |
| Impressum | `app/impressum/page.tsx` |
| 고객지원 | `app/support/page.tsx` |
| 계정 삭제 안내 | `app/account-deletion/page.tsx` |
| 전체 기능 페이지 | `app/features/page.tsx` |
| Press 페이지 | `app/press/page.tsx` |
| 로고, 한옥 이미지, 영상 | `public/` 폴더 |

## 3. 이미지와 영상 바꾸기

현재 사이트에서 사용하는 주요 파일은 다음과 같습니다.

| 화면 | 파일 |
| --- | --- |
| 한글소리 로고 | `public/hangul-sori-logo.png` |
| 메인 휴대폰의 한옥 | `public/hanok-gate.png` |
| 한옥 입장 영상 | `public/intro-gate-to-madang.mp4` |
| 호랑이와 까치 영상 | `public/taego-joy-duo.mp4` |
| 영상 정지 화면 | `public/intro-gate-poster.jpg`, `public/taego-joy-poster.jpg` |
| 브라우저 아이콘 | `public/icon-192.png`, `public/favicon.svg` |

가장 쉬운 교체 방법은 새 파일을 같은 이름으로 `public/` 폴더에 덮어쓰는 것입니다. 파일명을 바꾸면 `app/site.tsx` 안의 `/파일명`도 함께 바꿔야 합니다.

## 4. 색상 바꾸기

`app/globals.css` 상단의 `:root`에서 대표 색상을 한 번에 바꿀 수 있습니다.

```css
:root {
  --ink: #20312e;
  --cream: #fbf7ed;
  --paper: #fffdf8;
  --jade: #176d62;
  --jade-dark: #0d5149;
  --red: #b7483b;
  --gold: #d79c35;
  --blue: #3c7384;
}
```

## 5. 언어별 주소

- 독일어: `/de`
- 영어: `/en`
- 한국어: `/ko`
- 개인정보 처리방침: `/privacy`
- 이용약관: `/terms`
- 고객지원: `/support`
- 계정 삭제: `/account-deletion`
- 전체 기능: `/features`
- Press: `/press`
- Impressum: `/impressum`

## 6. 다시 온라인 사이트에 반영하기

수정한 폴더를 다시 ZIP으로 압축해 ChatGPT에 올리고, `현재 Hangul Sori Sites 프로젝트에 이 수정본을 반영해줘`라고 요청하면 됩니다. `.openai/hosting.json`은 기존 Sites 프로젝트를 식별하므로 삭제하지 않는 것이 좋습니다.

`node_modules`, `dist`, `.next` 폴더는 다시 압축할 필요가 없습니다. `npm install`과 빌드 과정에서 자동으로 만들어집니다.
