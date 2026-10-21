# 일두고택 표면·세 문 공정 검토본

현재 검토판은 `index.html`, 세 문 20개 공정은 `construction/index.html`, 돌담·흙마당 전후는 `estate-yard-wall-r1/index.html`에서 연다. 폴더를 로컬 HTTP 서버로 제공하면 이미지 비교와 공정 이전/다음 선택이 작동한다.

세 문은 도면 기반으로 승인된 형상을 유지하며 목재의 길이 방향 결과 판석 표면을 개선했다. 각 `.blend`에 필요한 목재·기와·판석 이미지가 포장되어 있다. 사당문의 승인된 적갈·녹색 색 계열과 태극 문양은 유지한다. 원도면 충돌·축척 판독 부분 때문에 전체 도면 100% 일치는 주장하지 않는다.

기존 공정 계약의 ID와 순서를 유지했다. 사랑채 왼쪽 협문과 안채 연결 협문은 각각 6단계, 사당문은 8단계다. 새 부재를 단계별로 나눈 뒤 누적 구성·중복·누락을 검사했고 최종 단계는 현재 완성 렌더와 같은 바이트다. 기존 학습 문구의 3단 계단 표현 대신 현재 도면의 낮은 받침·5단 계단을 설명한다.

마당은 반복 이미지의 UV 타일링을 걷어내고 실제 위치를 따라 이어지는 여러 크기의 흙색·면 변화와 디딤돌 주변의 약한 다짐을 사용한다. 담장의 원래 돌 쌓기·개별 색과 건물·지형·UV를 유지한다. 조선시대 생활 마당의 절제된 일러스트 표현을 위한 해석이며 새로운 역사적 복원 사실을 주장하지 않는다.

## 저장 원본과 재현

- 세 문: `left-new.blend`, `right-new.blend`, `shrine-new.blend`. 재생성은 Blender에서 `build_gates.py`를 실행한다.
- 세 문 검사: `blender -b -t 2 --python validate_drawings.py -- left right shrine` 이후 `python verify_surface_package.py`.
- 정본 R12가 다른 위치에 있으면 `ILDU_R12_SOURCE` 환경변수로 지정한다. 정본 원본 없이 배포 패키지의 파일·샘플만 검사하려면 명시적으로 `python verify_surface_package.py --allow-missing-upstream`을 사용한다. 결과의 `upstreamNativeHashVerified`를 함께 확인한다.
- 공정: `construction/README.md`의 재현 명령과 `construction/verification.json` 참고. 원래 계약 파일의 실제 바이트도 포함한다.
- 전체 일두고택의 큰 후보 `.blend`는 로컬에 보존한다. 푸시 패키지에는 대상 재질 라이브러리·부재 바인딩·재적용 스크립트를 넣으며 `estate-yard-wall-r1/REVIEW.md`의 방법으로 원본 R12에 재적용할 수 있다.

이 패키지는 Blender 제작·검토 결과다. Flutter 런타임 통합, 사용자 최종 표면 승인, 실기기 및 배포 완료로 표시하지 않는다. 앱의 보상·건설 자격·진도 소유권은 수정하지 않았다.
