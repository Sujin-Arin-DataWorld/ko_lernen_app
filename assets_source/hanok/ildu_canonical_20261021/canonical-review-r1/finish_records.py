"""Refresh small versioned records after actual material and browser QA."""
from pathlib import Path
import json
OUT=Path(__file__).resolve().parent;ROOT=OUT.parent
p=OUT/'index.html';s=p.read_text(encoding='utf-8').replace('href="style.css"','href="style.css?v=r6c-materials-2"').replace('src="app.js"','src="app.js?v=r6c-materials-2"');p.write_text(s,encoding='utf-8')
for name in ['material-model-verification.json','material-browser-qa.json','package-verification.json','browser-controls-qa.json']:
 assert json.loads((OUT/name).read_text(encoding='utf-8'))['passed'],name
note='''

## 승인 재질 공정 3D 복구 완료 · 2026-10-22

- 이 세션 승인 R6c `left-new.blend`, `right-new.blend`, `shrine-new.blend`를 정확한 해시로 정본 지정했다.
- 회색 GLB를 최종본처럼 보인 연결을 실제 원본 셰이더의 PBR GLB로 교체했다. 원본 파일은 저장·수정하지 않았다.
- 협문 6+6, 사당문 8단계가 완성본과 같은 부재·표면 좌표를 공유한다. 1,655부재 형상/노멀/변환과 공정 배정을 검사했다.
- 사당문 1동에서 별도 일러스트 광원 표본을 만들었다. 다른 건물을 새로 채색한 상태는 아니다.
- 태극 칠 2부재의 UV 격자 문제를 연속 평면 베이크로 수정했고, 실제 회전/확대/모바일 402·320px 검사를 통과했다.
- 전체 native 결합본은 보존 검사·저장 완료. 추가 Cycles 전체 렌더는 메모리 부족으로 중단되어 접합부 시각 승인을 주장하지 않는다.
- 검토: `canonical-review-r1/index.html#sadangmun/8`, 검증: `material-model-verification.json`, `material-browser-qa.json`.
- 앱 통합·최적화·실기기 검증은 미완료. 정본 소스 커밋과 앱 배포를 구분한다.
'''
for name in ['CONTINUATION.md','WORK.md']:
 p=ROOT/name;s=p.read_text(encoding='utf-8')
 if '## 승인 재질 공정 3D 복구 완료 · 2026-10-22' not in s:p.write_text(s.rstrip()+note,encoding='utf-8')
print('FINISH RECORDS SAVED')
