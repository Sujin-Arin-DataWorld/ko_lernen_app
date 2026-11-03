# 캐릭터 외형·연기 정본 · 2026-11-02 후속 승인

사용자가 새 시트에 “응 다 좋아”라고 승인하고 기존 백호 폴더와 비교해 선별·정본 등록·커밋·푸시·main 병합을 요청했다. 이번 패키지는9장 시트·기존 태고 보조 이미지3장·사용자 첨부 도깨비 원본1장을 원본 바이트로 보존한다.

## 지금 사용할 기준
- **추가 제작 전 필독:** [캐릭터별 머리~발끝·색상·재질·털/깃 상세명세](specifications/README.md) · [기존46개 치수 전수표](specifications/MEASUREMENTS.md) · [외형/알파/장면 검수](specifications/QA.md) · [이 세션 실패와 금지사항](specifications/SESSION_FINDINGS.md). 2026-11-03 사용자 요청으로 보강한 문서이며 기존 승인 수치·이미지·승인JSON을 교체하지 않는다.
- [전체 캐릭터 기준](CHARACTER_LOCK.json): 수진B2·탈선비·연이8/12세·일반/신수형·제작치수·UI재료를 이전 정본에서 그대로 계승하며, 새 승인 연기를 추가한다. 경로는 이 파일 기준.
- [표정·자세 ID와 시트 매핑](ACTING_CANON.json) · [선택 파일 해시](ASSET_MANIFEST.json) · [승인 범위](CANONICAL_APPROVAL.json).
- [태고 원본15파일 비교](TAEGO_SOURCE_COMPARISON.json) · [선정 이유](TAEGO_COMPARISON.md) · [최종 생성 프롬프트](GENERATION_PROVENANCE.json).
- [앱에서의 연기·미완료 조건](APP_ACTING_USE.md). 이 문서는 앱 구현 완료가 아니다.

| 인물 | 외형 보조 시트 | 표정8종 | 자세6종 |
|---|---|---|---|
| 조이 | [외형](assets/joy/model.png) | [표정](assets/joy/expressions.png) | [자세](assets/joy/poses.png) |
| 태고 | [외형](assets/taego/model.png) | [표정](assets/taego/expressions.png) | [자세](assets/taego/poses.png) |
| 도깨비 | [외형](assets/dokkaebi/model.png) | [표정](assets/dokkaebi/expressions.png) | [자세](assets/dokkaebi/poses.png) |

태고의 기본 얼굴·줄무늬·체형은 [기존 baekho.png와 같은 원본](../20261102/assets/taego/00-original.png)을 유지한다. 새 시트는 같은 태고의 연기를 규정하며 원본 얼굴을 대체하지 않는다. 모델 시트는 조형 참고이고 cm 실측이나 동일3D리그의 증거가 아니다.

추가 보조: [정면 얼굴](assets/taego/source-support/portrait-front.png), [앉은 자세](assets/taego/source-support/seated.png), [선 자세](assets/taego/source-support/standing.png). 이 세 그림은 단독 원본 자료이며 새 표정8종을 대신하지 않는다.

## 보존과 검증
새 시트9장은 RGBA와 완전 투명 픽셀을 확인했다. 개별42개 스프라이트로 분리하거나 실제 앱 배경·기기·96dp에서 검수한 것은 아니다. 생성된 털무늬의 픽셀 일치, 수치 비례, 애니메이션 연속성은 미검증이다. 태고 진행 자세는 배지의 반대쪽 복제를 제거한 보정본을 채택했다. 조이 배지3소용돌이·날개2개·꼬리1개, 도깨비 뿔2개가 고정 조건이다.

기존 RGB 검정 배경 원본을 투명PNG라고 부르지 않는다. 원래 영상 backho.mp4는 이번에 새 승인 영상으로 등록하지 않았다. source 폴더나 과거 후보를 삭제하지 않는다. Flutter·HTML·Figma·pubspec·경제·진도·배포 변경은 없다.

검증: python design/canonical/ensemble/20261102-acting/verify.py

도깨비 원본: [사용자 첨부 편안한 전신](assets/dokkaebi/source-relaxed-standing.png). 이 원본과 기존 중립 정면의 정확한 경로·SHA를 프로필에서 함께 고정했다.
