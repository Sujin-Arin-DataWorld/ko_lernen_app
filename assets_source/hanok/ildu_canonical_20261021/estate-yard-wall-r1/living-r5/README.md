# 흙마당 절단선 수정 R5

## 원인

사용자가 보낸 계단 앞 이미지는 R4 `overview-B.png`의 같은 위치와 매칭된다(배율 약 .79, 정규화 상관 .9899). 해당 선 양쪽의 실제 바닥 객체·재질·높이·면/모서리 법선은 같았고, R4 재질 적용 범위도 1이었다. 새 재질이 일부만 연결된 문제로 단정한 것은 잘못이다.

실제 원인은 원본 보조조명 `Warm estate | P16 low broad courtyard reflection.005`였다. 중심 높이 2.545m, 지름8m의 원판이 거의 수직(회전X 약90.77°)으로 놓여 원판 아래쪽이 땅속 약1.455m까지 들어갔다. 발광면과 바닥이 만나는 직선이 이미지의 대각 경계와 일치한다. 기존 R3에도 약한 경계가 있었으며 R4 재료감에서 더 드러났다.

근거는 R4 폴더의 `seam-image-match.json`, `seam-probe-normals.json`, `actual-render-ownership.png`, `actual-lighting-scene.json`이다. 고정색 Diffuse·Bump 없음·그림자 유무·후처리 없음으로 렌더해도 선이 남았다. 같은 saved R4 재질과 원본 조명을 평면에 재현한 `light-proof-before.png`에서도 선이 재현됐고, 조명의 위치·방향만 고친 `light-proof-after.png`에서는 사라졌다.

## 수정

기존 낮은 보조조명은 건물·밭 등 원래 비마당 대상에 유지한다. 두 마당 바닥 객체만 그 빛의 수신 대상에서 제외하고, 높이6.545m에서 아래를 향하는 지름8m/200W 조명을 별도로 연결한다. 이 조명은 두 흙마당만 비춘다. Light Linking도 실제 `light-proof-linked-after.png`로 시험했다.

흙의 큰 기질·고운 입자·다짐 분포·색, 건축과 밭의 재질·형상·UV·배치를 보존한다. 마당 반사광이 달라지므로 간접광까지 픽셀 단위로 동일하다고 주장하지 않는다.

별개로 발견된 R4 외곽 마스크의 작은 불연속도 고친다. 볼록 영역마다 별도 페더를 적용하던 방식을, 영역 전체의 포함 판정과 실제 원래 외곽18선분의 공통 페더로 분리한다. 이것은 계단 앞 절단선의 주원인과 구분한다.

## 재현

`run.py`는 R1 native → 검증된 R3 재질 → R4 재질을 정확한 SHA로 재구성한 뒤 R5를 적용한다. 완성된 고택 장면 전체를 렌더하며 새 작업공간은 만들지 않는다.

`blender -b <ildu-estate-yard-wall-r1.blend> -t 8 --python-exit-code 1 --python <living-r5/run.py> -- render overview full detail`

저장 라이브러리 재현은 `-- apply render overview full detail`이다. 라이브러리는 재질과 조명 데이터만 담으며, 조명 위치와 연결 대상은 `lighting_patch.py`와 검증 JSON으로 재현한다. 전체 건축 파일을 중복 저장한 것으로 표시하지 않는다.

완성 장면의 3시점 A/B 6장과 실제 렌더에서 추출한 계단 앞 확대 2장을 저장했다. Blender 실행95473은 exit0으로 종료했다. Root와 독립 아트 디자이너가 실제 overview 전후에서 해당 절단선 제거와 건물·밭의 기존 표현 유지를 확인했다. `VISUAL_REVIEW.md`, `VISUAL_DESIGNER_REVIEW.md`, `package-verification.json` 참조.

최종 native 라이브러리 SHA256은 `ece671ac893dc57fcbd7c6ad1312bd4e982ba59164a53fd43f6454322ad98f7f`다. A는 직전 R4, B는 조명을 수정한 R5다. 같은 카메라·해상도·샘플·seed이며 **조명 수정은 의도된 차이**다. 앱 통합·정본 승격·새 세 문 결합·커밋·푸시는 포함하지 않는다.

실제 브라우저의 네 시점 이미지 로딩·A/B·키보드 비교·가로 넘침 검사는 `browser-qa.json`에 저장했다. 현재 화면은 계단 앞 B100/477px이며 `browser-final.png`가 최종 캡처다.
