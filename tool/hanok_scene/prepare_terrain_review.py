from pathlib import Path
import shutil,json,hashlib,re
ROOT=Path(__file__).resolve().parents[2]
SOURCE=ROOT/'assets_unused/pending_review/hwalju-blueprint-review';OUT=SOURCE/'terrain'
BP=Path('C:/dev/hangulsori/ko_lernen_app/assets_unused/pending_review/personal_hanok_v3/ildu_Blueprint/중문채')
refs={
 'elevation039.jpg':next(BP.glob('*중문채_정면도1.jpg')),
 'section042.jpg':next(BP.glob('*중문채_종단면도-1,2.jpg')),
 'section043.jpg':next(BP.glob('*중문채_횡단면도.jpg')),
}
manifest=[]
for name,path in refs.items():
    shutil.copyfile(path,OUT/name);digest=hashlib.sha256(path.read_bytes()).hexdigest()
    assert hashlib.sha256((OUT/name).read_bytes()).hexdigest()==digest
    manifest.append({'source':str(path),'copy':name,'sha256':digest,'bytes':path.stat().st_size})
(OUT/'reference-manifest.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2),encoding='utf8')
js=Path(__file__).with_name('hwalju_review.js').read_text(encoding='utf8')
js=js.replace('활주 위치 수정 전후를 회전하고 확대하는 3D 공간','중문채 지면 수정 전후를 회전하고 확대하는 3D 공간')
js=js.replace("const views={front:","const views={front:")
start=js.index('const views=');end=js.index(';',start)
js=js[:start]+"const views={connection:[[-23,3,5.6],[4,6,2.3]],junction:[[-10,-2,4],[0,3.7,1.5]],gate:[[-10,18,4.8],[0,12.8,1.9]],pair:[[-23,-26,17],[6,5,2.7]],front:[[12,-16,7],[7.4,-.1,2.7]]}"+js[end:]
js=js.replace('Math.max(1,1.2/camera.aspect)','Math.max(.45,1.2/camera.aspect)')
js=js.replace("active='front'","active='connection'").replace("function state(after){","function state(after){ground.visible=!after;")
js=js.replace("after?'도면 기준 수정본':'수정 전 V26'","after?'이어지는 흙 지면':'수정 전 바닥판'")
js=js.replace("startsWith('HwaljuFix.')","startsWith('TerrainFix.')").replace('detachedOldSupportNodes','detachedOldGroundNodes')
(OUT/'viewer.js').write_text(js,encoding='utf8')
style=re.search(r'<style>.*?</style>',(SOURCE/'review.html').read_text(encoding='utf8'),re.S)[0]
html='''<!doctype html><html lang="ko"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>중문채 — 이어지는 전저후고 지면</title>STYLE
<script type="importmap">{"imports":{"three":"../vendor/build/three.module.js","three/addons/":"../vendor/examples/jsm/"}}</script>
<main><div class="eyebrow">한글소리 · 사랑채–중문채 지면 수정 검토</div><h1>중문채까지 지면이 자연스럽게 올라갑니다</h1>
<p>중문채 아래 떠 보이던 네모난 바닥판을 걷어내고, 사랑채 앞마당에서 중문채와 뒤쪽 높은 마당까지 하나의 흙 지면으로 연결했습니다.</p>
<fieldset id="controls" disabled><button id="before" aria-pressed="false">수정 전 바닥판</button><button id="after" aria-pressed="true">이어지는 흙 지면</button><span id="state">이어지는 흙 지면</span><br><button data-view="connection">중문채 연결</button><button data-view="junction">지면 접합부 가까이</button><button data-view="gate">중문 앞 오르막</button><button data-view="pair">두 채 전체</button><button data-view="front">사랑채 정면</button></fieldset>
<div id="space"></div><p id="status" role="status">3D 준비 중…</p>
<p class="notice">기존 화면에는 실제 지형 대신 건축 단계 표시용 바닥판 두 개가 남아 있었습니다. 이번에는 지면을 연속된 경사로 연결하고, 높아지는 지면이 중문채 기단의 아래쪽을 자연스럽게 감싸도록 했습니다.</p>
<section><h2>같은 시점에서 전후 비교</h2>RENDERS</section>
<section><h2>높이 판단에 사용한 도면</h2><p>042의 중문채 앞뒤 지면 차이 900mm를 반영했습니다. 039에는 중문 쪽으로 높아지는 지면이 보입니다. 두 건물 사이의 공통 측량 기준점은 확인되지 않아, 사랑채 앞마당 대비 중문채 낮은 마당 +600mm는 기존 모델의 배치를 유지했습니다.</p><div class="grid">BLUEPRINTS</div></section>
<section><details><summary>검증 범위와 추정한 부분</summary><p>기존 건물 메시 940개와 앞서 수정한 활주의 위치를 유지했습니다. 회전용 파일에서도 기존 건물·재질·바이너리를 그대로 두고 바닥판 두 개의 표시만 해제한 뒤 연속 지형 한 개를 추가했습니다.</p><p>중문 앞 접근부의 추가 상승량 680mm와 경사의 길이·곡률은 정면도에 따른 재구성입니다. 실측 등고선이 아니며, 중문채 자체를 새로 들어 올린 것은 아닙니다. 낮은 계단 단은 흙에 묻히고 위쪽 단이 드러납니다.</p><p>이번 수정은 지면 연결입니다. 목재 색감·질감의 미술 개선과 앱 에셋 교체는 포함하지 않았습니다.</p><p><a href="geometry-validation.json">지형·계단 검사</a> · <a href="delivery-validation.json">3D 파일 보존 검사</a> · <a href="reference-manifest.json">도면 원본 해시</a> · <a href="../review.html">이전 활주 수정본</a></p></details></section></main><script type="module" src="viewer.js"></script></html>'''
renders=''
for view,label in [('connection','중문채와 사랑채 연결'),('junction','기단 아래 접합부'),('gate','중문 앞 접근부')]:
    renders+=f'<h3>{label}</h3><div class="grid">'+''.join(f'<figure><a href="{state}-{view}.png"><img loading="lazy" src="{state}-{view}.png" alt="{label} {caption}"></a><figcaption>{caption}</figcaption></figure>' for state,caption in [('before','수정 전: 분리된 바닥판'),('after','수정 후: 이어지는 흙 지면')])+'</div>'
blueprints=''.join(f'<figure><a href="{name}"><img loading="lazy" src="{name}" alt="{caption}"></a><figcaption>{caption}</figcaption></figure>' for name,caption in [('elevation039.jpg','039 정면도 — 중문 쪽으로 높아지는 지면'),('section042.jpg','042 종단면도 — 앞뒤 지면 높이 차이 900mm'),('section043.jpg','043 횡단면도 — 사랑채와 연결되는 바닥')])
(OUT/'review.html').write_text(html.replace('STYLE',style).replace('RENDERS',renders).replace('BLUEPRINTS',blueprints),encoding='utf8')
print(OUT/'review.html')
