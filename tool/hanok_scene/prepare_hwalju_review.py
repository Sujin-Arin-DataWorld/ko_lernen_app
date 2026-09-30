from pathlib import Path
import shutil,json,hashlib
ROOT=Path(__file__).resolve().parents[2];OUT=ROOT/'assets_unused/pending_review/hwalju-blueprint-review'
SOURCE=Path('C:/dev/hangulsori/ko_lernen_app_worktrees/hanok-warm-stone-20260923/assets_unused/pending_review/ildu_spatial_preservation_20260922/pair-construction-v26')
BP=Path('C:/dev/hangulsori/ko_lernen_app/assets_unused/pending_review/personal_hanok_v3/ildu_Blueprint/사랑채')
shutil.copytree(SOURCE/'vendor',OUT/'vendor',dirs_exist_ok=True)
shutil.copyfile(Path(__file__).with_name('hwalju_review.js'),OUT/'viewer.js')
refs={
 'photo-front.png':Path('C:/Users/vjinn/Pictures/Screenshots/스크린샷 2026-09-23 113112.png'),
 'photo-numaru.png':Path('C:/Users/vjinn/Pictures/Screenshots/스크린샷 2026-09-23 113059.png'),
 'plan004.jpg':Path('C:/dev/hangulsori/ko_lernen_app_worktrees/hanok-spatial-preservation-plan-20260922/assets_unused/pending_review/ildu_spatial_preservation_20260922/sources/rear-junction-reference/sarang-floor-user-marked.jpg'),
 'front005.jpg':BP/'도면_국가민속문화재_함양_일두_고택_기록화보고서_사랑채_정면도.jpg',
 'side007.jpg':BP/'도면_국가민속문화재_함양_일두_고택_기록화보고서_사랑채_우측면도.jpg',
 'detail028.jpg':BP/'도면_국가민속문화재_함양_일두_고택_기록화보고서_사랑채_기둥_상세도(4).jpg',
}
manifest=[]
for name,path in refs.items():
    shutil.copyfile(path,OUT/name)
    digest=hashlib.sha256(path.read_bytes()).hexdigest();assert hashlib.sha256((OUT/name).read_bytes()).hexdigest()==digest
    manifest.append({'source':str(path),'copy':name,'sha256':digest,'bytes':path.stat().st_size})
(OUT/'reference-manifest.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2),encoding='utf8')
html='''<!doctype html><html lang="ko"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>사랑채 활주 — 도면 위치 수정</title>
<style>*{box-sizing:border-box}body{margin:0;background:#f3efe7;color:#32281c;font:16px/1.7 system-ui,sans-serif}main{max-width:1250px;margin:auto;padding:24px}h1{font-size:30px;line-height:1.3;margin:8px 0 16px}.eyebrow{font-size:12px;letter-spacing:.12em;color:#73634a}#space{height:min(66vh,720px);min-height:400px;border:1px solid #c0b39e;border-radius:12px;overflow:hidden}canvas{display:block}fieldset{border:0;padding:0;margin:14px 0}button{font:inherit;cursor:pointer;border:1px solid #b8a78b;background:#fffaf2;color:#35291a;padding:9px 14px;border-radius:7px;margin:3px}button[aria-pressed=true]{background:#483820;color:white}#state{font-weight:700;margin-left:10px}#status,.muted{font-size:14px;color:#74654e}.grid{display:grid;grid-template-columns:repeat(2,minmax(0,1fr));gap:14px}.grid img{display:block;width:100%;background:white}figure{margin:0;border:1px solid #d9cdb9;padding:10px;background:#fffaf3}figcaption{font-size:14px;margin-top:5px}section{margin-top:32px}a{color:#73512b}p{max-width:950px}summary{cursor:pointer;font-weight:600}.notice{border-left:3px solid #9c754a;padding-left:15px}@media(max-width:650px){main{padding:14px}.grid{grid-template-columns:1fr}h1{font-size:25px}#space{min-height:360px}}</style>
<script type="importmap">{"imports":{"three":"./vendor/build/three.module.js","three/addons/":"./vendor/examples/jsm/"}}</script>
<main><div class="eyebrow">한글소리 · V26에서 파생한 기둥 위치 수정 검토</div><h1>처마 받침기둥의 자리를 바로잡았습니다</h1>
<p>도면 004·005·007·028을 기준으로 사랑채 정면 왼쪽과 누마루의 활주를 수정했습니다. 표시하신 누마루 안쪽 기둥을 복원하고, 바깥쪽 기둥은 난간 모서리에서 더 바깥으로 옮겼습니다.</p>
<fieldset id="controls" disabled><button id="before" aria-pressed="false">수정 전 V26</button><button id="after" aria-pressed="true">도면 기준 수정본</button><span id="state">도면 기준 수정본</span><br><button data-view="front">정면 사선</button><button data-view="straight">정면도 방향</button><button data-view="numaru">① 누마루 기둥</button><button data-view="left">② 왼쪽 기둥</button><button data-view="pair">중문채 연결 보기</button></fieldset>
<div id="space"></div><p id="status" role="status">3D 준비 중…</p>
<p class="notice">028 번호 배치도와 005 정면도에는 정면 쪽 활주가 세 곳에 있습니다. V26은 누마루 안쪽 한 곳을 누락했고, 바깥쪽과 왼쪽의 위치도 달랐습니다. 왼쪽의 떠 있던 받침 아래와 누마루 안쪽에는 연결되는 돌받침을 보완했습니다.</p>
<section><h2>첨부 실사</h2><div class="grid"><figure><a href="photo-front.png"><img src="photo-front.png" alt="왼쪽 처마 받침기둥이 보이는 첨부 실사"></a><figcaption>정면 왼쪽: 처마 아래의 가는 활주와 기단 관계</figcaption></figure><figure><a href="photo-numaru.png"><img src="photo-numaru.png" alt="누마루 안쪽 흰 활주가 보이는 첨부 실사"></a><figcaption>누마루: 앞 안쪽에 서 있는 흰 활주</figcaption></figure></div></section>
<section><h2>같은 카메라로 비교</h2>RENDERS</section>
<section><h2>우선 적용한 도면</h2><p>그림을 누르면 원본 크기로 확인할 수 있습니다. 028의 번호 2는 정면 왼쪽, 3은 누마루 안쪽, 4는 누마루 바깥쪽입니다.</p><div class="grid">BLUEPRINTS</div></section>
<section><details><summary>검증 범위와 남은 추정</summary><p>V26 사랑채·중문채의 기존 부재, 지붕, 창호, 연결부는 유지했습니다. 수정한 활주 외의 원본 메시·재질과 GLB 바이너리를 비교했습니다. 평면상 활주 중심은 스캔에서 읽은 약 ±40mm 범위의 위치이며, 치수 숫자로 직접 기입된 값은 아닙니다. 받침돌의 세부 분할과 접합 높이는 기존 지형·처마에 맞춘 재구성입니다. 028의 후면 1번 활주는 이번 정면 표시 수정 범위에 포함하지 않았습니다.</p><p>색감과 질감은 V26 그대로이며 별도의 미술 개선본이 아닙니다. 앱 에셋 교체는 하지 않았습니다.</p><p><a href="geometry-validation.json">형상 비교</a> · <a href="contact-validation.json">위아래 접촉 검사</a> · <a href="delivery-validation.json">3D 파일 보존 검사</a> · <a href="reference-manifest.json">도면·사진 원본 해시</a></p></details></section></main><script type="module" src="viewer.js"></script></html>'''
renders=''
for view,label in [('front','정면'),('numaru','누마루 안쪽'),('left','왼쪽')]:
    renders+=f'<h3>{label}</h3><div class="grid">'+''.join(f'<figure><a href="{state}-{view}.png"><img loading="lazy" src="{state}-{view}.png" alt="{label} {caption}"></a><figcaption>{caption}</figcaption></figure>' for state,caption in [('before','수정 전 V26'),('after','도면 기준 수정본')])+'</div>'
blueprints=''.join(f'<figure><a href="{name}"><img loading="lazy" src="{name}" alt="{caption}"></a><figcaption>{caption}</figcaption></figure>' for name,caption in [('detail028.jpg','028 활주 번호 배치와 상세'),('plan004.jpg','004 평면도 — 보존된 사용자 표시본'),('front005.jpg','005 정면도'),('side007.jpg','007 우측면도')])
(OUT/'review.html').write_text(html.replace('RENDERS',renders).replace('BLUEPRINTS',blueprints),encoding='utf8')
print(OUT/'review.html')
