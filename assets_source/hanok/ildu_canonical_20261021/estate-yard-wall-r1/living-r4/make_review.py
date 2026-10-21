"""Build the familiar local review UI from the previous, already checked viewer."""
from pathlib import Path

OUT = Path(__file__).resolve().parent
source = (OUT.parent/'living-r3/index.html').read_text(encoding='utf-8')
replacements = {
    '<title>일두고택 · 모래 결과 담장 표면</title>':'<title>일두고택 · 전체 흙마당 다시보기</title>',
    '../entry-pilot-r2/index.html':'../living-r3/index.html',
    '← 이전 흙마당 시험':'← 이전 마당·담장 비교',
    '<h1>모래 결과 담장 표면</h1>':'<h1>전체 흙마당 다시보기</h1>',
    '흙의 모래 응집·짧은 쓸림과 담장 돌의 광물 결을 더한 후보입니다. 같은 카메라와 조명에서 기존 표면과 비교합니다.':'밭과 담장은 유지하고, 넓은 마당의 흙결·입자 밀도·다짐 차이를 조정했습니다. 전체 구도에서 먼저 비교해 주세요.',
    '<button type="button" data-view="detail" aria-pressed="true">마당 가까이</button>':'<button type="button" data-view="detail" aria-pressed="false">마당 가까이</button>',
    '<button type="button" data-view="wall" aria-pressed="false">담장 가까이</button>':'',
    '<button type="button" data-view="full" aria-pressed="false">고택 전체</button>':'<button type="button" data-view="full" aria-pressed="true">고택 전체</button>',
    '<button type="button" id="size" aria-pressed="false">작은 화면 크기로 보기</button>':'<button type="button" id="size" aria-pressed="true">크게 보기</button>',
    'B · 모래·광물 결을 더한 표면':'B · 전체 흙결을 조정한 마당',
    'A · 기존 R1 표면':'A · 직전 마당',
    'detail-A.png':'full-A.png',
    'detail-B.png':'full-B.png',
    '마당 가까이 A: 기존 R1 표면':'고택 전체 A: 직전 마당',
    '마당 가까이 B: 모래 결을 더한 표면':'고택 전체 B: 흙결을 조정한 마당',
    '건물·돌의 형상과 배치는 같습니다. 이번 비교는 마당·담장 재질 후보이며, 전체 장면의 문은 기존 R12 모델입니다. 새 세 문 결합과 실제 앱 적용은 별도입니다.':'밭·풀·담장·건물 형상과 배치는 같습니다. 마당 흙만 조정한 검토 후보입니다. 전체 장면의 문은 기존 모델이며, 새 세 문 결합과 실제 앱 적용은 별도입니다.',
    'living-yard-wall-r3-refined.blend':'courtyard-soil-r4.blend',
    "'기존 R1 표면':'모래·광물 결을 더한 표면'":"'직전 마당':'흙결을 조정한 마당'",
}
for old,new in replacements.items():
    assert old in source, old
    source = source.replace(old,new)
# The previous page omitted an explicit body tag. Insert it before main.
if '<body' not in source:
    source = source.replace('<main>', '<body class="small">\n<main>',1)
(OUT/'index.html').write_text(source,encoding='utf-8')
print('R4 review page built')
