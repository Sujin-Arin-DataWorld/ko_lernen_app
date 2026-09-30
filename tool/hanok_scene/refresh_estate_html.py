"""Keep the local review page aligned with the current wall and garden scene."""
from pathlib import Path

DIST = Path('C:/dev/hangulsori/sites/ildu-survey-review-20260929/dist')
page = DIST / 'estate.html'
viewer = DIST / 'estate-viewer.js'


def replace_once(source, old, new):
    assert old in source, f'Review template changed: {old[:70]}'
    return source.replace(old, new, 1)


html = page.read_text(encoding='utf8')
html = replace_once(html, '<title>일두고택 · 전체 연결 수정본</title>',
                    '<title>일두고택 · 담장 연결 검토본</title>')
html = replace_once(html, '<h1>일두고택 · 전체 연결 수정본</h1>',
                    '<h1>일두고택 · 담장 연결 검토본</h1>')
html = replace_once(html, '2026.09.30 · ⑪ 화장실 · 담장 중복 수정 · 빈 텃밭 · 흙바닥 보완',
                    '2026.09.30 · 담장 재질 통일 · 끊긴 접점 연결 · 빈 텃밭 · 흙바닥 보완')
html = replace_once(html, '<button data-view="south">사랑채·중문채 연결</button>',
                    '<button data-view="south">사랑채·중문채 연결</button>'
                    '<button data-view="boundary">대문채·별당 담</button>'
                    '<button data-view="service">중문채·곳간채 담</button>')
html = replace_once(html,
    '대문채 오른쪽 중복 담과 별당 뒤 돌출 담을 제거하고, 아래채·안곳간채·광채·창고채의 나뭇결과 회벽 표면을 보완했습니다.',
    '대문채 오른쪽 담을 원래 구간으로 연결하고 별당 뒤·옆의 평행 담을 정리했습니다. '
    '곳간채 뒤 외곽 담과 중문채 접점도 이어 새 담의 돌색·기와 마감을 기존 외곽 담에 맞췄습니다. '
    '아래채·안곳간채·광채·창고채의 나뭇결과 회벽 표면을 보완했습니다.')
html = replace_once(html, 'estate-viewer.js?v=20260930-earth-garden',
                    'estate-viewer.js?v=20260930-wall-junctions-3')
page.write_text(html, encoding='utf8')

js = viewer.read_text(encoding='utf8')
js = replace_once(js, "estate_wall:['배치도 담장','002 경로 복원']",
                  "estate_wall:['이번 연결 담','기존 돌쌓기·기와 마감 적용']")
js = replace_once(js, "forecourt_wall:['바깥 돌담','연결 검토']",
                  "forecourt_wall:['바깥 돌담','기존 담장 유지']")
js = replace_once(js, "south:[[-22,20,23],[5,1,0]]};",
                  "south:[[-22,20,23],[5,1,0]],boundary:[[34,19,32],[16,1,17]],service:[[-29,19,1],[-12,1,-13]]};")
js = replace_once(js, 'service:[[-29,19,1],[-12,1,-13]]};\nlet root',
    "service:[[-29,19,1],[-12,1,-13]]};\n"
    "const viewStatus={whole:'고택 전체',plan:'위에서 본 전체 배치',court:'안채 마당',gates:'사당문·꽃담 접점',south:'사랑채·중문채 접점',boundary:'대문채 오른쪽·별당 담장',service:'중문채·곳간채 뒤 담장'};\n"
    'let root')
js = replace_once(js, "controls.update();for(const b of document.querySelectorAll('[data-view]'))b.setAttribute('aria-pressed',b.dataset.view===name);dirty=true;}",
    "controls.update();for(const b of document.querySelectorAll('[data-view]'))b.setAttribute('aria-pressed',b.dataset.view===name);if(host.dataset.loaded)$('#status').textContent=viewStatus[name]+' · 드래그로 회전, 휠로 확대';dirty=true;}")
viewer.write_text(js, encoding='utf8')
print('ESTATE REVIEW HTML REFRESHED', page, viewer)
