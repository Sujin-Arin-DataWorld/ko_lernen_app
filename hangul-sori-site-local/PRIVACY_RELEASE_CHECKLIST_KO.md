# Hangul Sori 개인정보 보호 출시 체크리스트

코드는 비필수 분석 태그를 사전 차단하도록 구성되어 있다. 아래 관리자 설정과 법적 정보는 코드에서 대신 확정할 수 없으므로 공개 마케팅 전에 직접 확인한다.

## Cookiebot Manager

- Domain group에는 `hangul-sori.com`을 등록한다. `www`는 같은 도메인 그룹으로 처리한다.
- Distribution은 EEA만이 아니라 **All visitors**로 설정한다.
- Consent method는 **Explicit consent**로 설정한다.
- 사이트의 자체 패널에서 **필수만 허용**, **통계 허용**, **상세정보**를 제공한다.
- 필수만 허용과 통계 허용은 같은 단계에 있고 시각적 비중과 클릭 수가 동등해야 한다.
- Necessary는 항상 켜고 Statistics, Preferences, Marketing은 기본값을 끈다.
- 독일어, 영어, 한국어 번역을 활성화하고 각 문구를 검수한다.
- 사이트 푸터의 Cookie settings 버튼이 자체 설정 패널을 다시 여는지 확인한다.
- Consent duration은 6개월을 권장하며 최대 12개월을 넘기지 않는다.
- Domain scan을 실행하고 **Unclassified cookies 0**인지 확인한다.
- 정적 쿠키 목록이 `/privacy`, `/privacy?lang=en`, `/privacy?lang=ko`에 표시되고 실제 코드와 일치하는지 확인한다.
- Usercentrics/Cookiebot DPA를 체결하고 PDF 사본을 보관한다.
- 로컬에서 배너까지 테스트하려면 라이선스가 허용하는 경우 `localhost`를 Domain alias로 추가한다. 추가하지 않아도 GA는 fail-closed 상태로 유지된다.

## Google Analytics 4

- Data retention은 제공되는 가장 짧은 기간인 **2 months**로 설정한다.
- Reset user data on new activity를 끈다.
- Google Signals를 끈다.
- Granular location and device data collection을 끈다.
- Ads personalization, advertising features, User-ID를 끈다.
- Google Ads 등 광고 제품 링크를 만들지 않는다. 나중에 만들 경우 별도 Marketing 동의를 설계한다.
- 불필요한 Account data sharing을 끄고 Google 데이터 처리 약관을 확인한다.

## 법적 정보와 운영

- Impressum과 개인정보처리방침의 사업자 주소가 `Kurfürstenstraße 14, 60486 Frankfurt am Main`으로 일치하는지 확인한다.
- Cloudflare, Usercentrics/Cookiebot, Google과 체결한 DPA 및 설정 화면을 보관한다.
- 테스터 신청 메일은 테스트 단계 종료 후 최대 6개월 이내에 삭제한다.
- 삭제 일정을 캘린더나 운영 절차로 관리하고, 삭제·열람 요청 처리 기록을 남긴다.
- 새 외부 스크립트, 픽셀, 영상 임베드, 폼 제공자를 추가할 때마다 Cookiebot 재스캔과 개인정보처리방침 업데이트를 수행한다.

## 출시 후 검증

- 새 시크릿 창에서 아무 버튼도 누르기 전에 Google Analytics와 Google Tag Manager 네트워크 요청이 0건인지 확인한다.
- Deny all 후에도 Google 요청과 `_ga` 쿠키가 0건인지 확인한다.
- Statistics만 허용하면 GA가 동작하는지 확인한다.
- 푸터의 Cookie settings에서 Statistics를 철회하면 `_ga` 쿠키가 삭제되고 이후 측정이 멈추는지 확인한다.
- 데스크톱과 390px 모바일에서 두 선택 버튼, 상세 설정, 개인정보처리방침 링크가 잘리지 않는지 확인한다.
