"""Create a source-linked drawing audit; never publish candidate geometry."""
from pathlib import Path
import hashlib, json, datetime

ROOT=Path(__file__).resolve().parents[2]
OUT=ROOT/'assets_unused/pending_review/hwalju-blueprint-review/northern-court'
REF=OUT/'references/survey-audit'
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
inventory=json.loads((REF/'inventory.json').read_text(encoding='utf8'))
for r in inventory:
    source=Path(r['source']);source=source if source.is_absolute() else ROOT/source
    target=ROOT/r['file']
    r.update(source=str(source.resolve()),file=target.relative_to(OUT).as_posix(),sha256=sha(target),bytes=target.stat().st_size)
    r['sourceBytesMatch']=r['sha256']==sha(source)
    r['preview']=f'references/survey-audit/{r["key"]}-preview.png'
assert all(r['sourceBytesMatch'] for r in inventory)
# Keep inventory paths relative to the review directory from this version on.
(OUT/'survey-source-manifest.json').write_text(json.dumps(inventory,ensure_ascii=False,indent=2),encoding='utf8')

def item(id,title,sources,dimensions,reading,changes,pending,render=None):
    return dict(id=id,title=title,sources=sources,printedDimensions=dimensions,interpretation=reading,
                candidateChanges=changes,unresolved=pending,candidateRender=render)

buildings=[
item('site','전체 배치 · 002',['site002'],
 [['기준','2007 기록화 전체 배치도 002'],['정합 기준','기둥 중심점 + 담장 중심선'],['건물 크기','개별 도면 치수 유지 · 배치 정합에 맞춰 늘이지 않음']],
 ['지붕 끝을 임의로 정렬하지 않고 배치도의 기둥축으로 위치와 회전을 대조합니다.','사랑채·중문채의 기존 연결을 유지하고 북측 건물을 해당 도면 좌표에 정합했습니다.'],
 ['후보 모델에 002 좌표 정합과 사당문·장독대 협문 사이 담장 연결 반영'],
 ['스캔 선두께·도면 간 차이가 있어 정합 잔차가 남습니다. 건물별 수치는 아래 정합 결과에 공개합니다.','002 범례 6·7의 명칭과 개별 안곳간채·중문채 평면의 연결 형상이 서로 맞지 않습니다. 이 충돌을 해결하기 전 배치 100% 일치를 주장하지 않습니다.']),
item('jarGate','장독대 협문',['gate084','gate085'],
 [['기둥 중심 간격','1,020 mm'],['기둥 단면','85 × 85 mm'],['문선','60 × 45 mm'],['문짝','2짝 · 각 420 × 1,400 mm'],['판재','WD1 창호표 30 mm'],['상·하인방','85 × 150 mm'],['지붕 평면','2,210 × 1,516 mm'],['단면 높이','2,400 mm']],
 ['작고 낮은 장독대 출입문입니다. 성인 눈높이 통과 검사에 맞추어 높이를 키우지 않습니다.','각서까래 40 × 50, 판재 20, 박공판 25 mm를 별도 입체 부재로 구성합니다.'],
 ['사진 추정 170 mm 기둥을 도면의 85 mm로 교정','문짝 2짝, 문틀·인방·측면 가새와 서까래 실체 반영','지붕 끝 좌표의 부동소수 오차로 판재가 길게 늘어지던 결함 수정'],
 ['단면에는 문 THK20, WD1에는 THK30이 표기됩니다. 전용 창호표 30 mm를 채택하되 충돌은 보존합니다.','지붕 곡선·철물 크기·맞춤 여유는 해석값입니다. 지붕 최고점 후보는 약 2,394 mm로 2,400 mm 표기와 약 6 mm 차이가 남습니다.'],
 'jar-gate-survey-candidate.png'),
item('sadangmun','사당문',['sadang-gate-plan','sadang-gate-section'],
 [['기둥 축','1,350 × 1,000 mm'],['원기둥','지름 170 mm'],['문짝 전체','1,020 × 1,500 mm · 두께 30 mm'],['문선','72 × 90 mm'],['상·하인방','72 × 150 mm'],['지붕 평면','2,570 × 1,940 mm'],['기둥머리 높이','기단 위 1,800 mm']],
 ['086 평면·지붕평면과 087 단면을 함께 읽습니다.','원주, 문선, 인방, 회전축과 30 mm 문판을 구분합니다.'],
 ['기존 후보의 문틀·문판·각서까래 실체를 도면 치수와 재검사'],
 ['태극 채색·풍화·꽃담 문양 간격은 실사 보완 영역입니다.','일부 바닥 기준점은 도면별 100/200 mm 차이가 있어 공통 기준면을 따로 관리합니다.']),
item('sadang','사당',['sadang-plan','sadang-front'],
 [['정면 기둥축','6,760 = 2,150 + 2,450 + 2,160 mm'],['깊이','4,200 = 실내 2,940 + 퇴칸 1,260 mm'],['전면 원기둥','4개 모두 지름 240 mm'],['후면·벽체 기둥','230 × 230 mm'],['문선','87 × 150 mm']],
 ['058 평면의 원주 지시선을 확대 확인했습니다. 양 끝 기둥만 두껍게 만들 근거가 없습니다.','059 정면은 한짝·두짝·한짝 창호 구성을 보여줍니다.'],
 ['끝 기둥 260 mm 확대를 해제하고 모두 240 mm로 교정','문틀 깊이와 한짝·두짝·한짝 구성 유지'],
 ['현재 높이와 개구부 크기 일부는 059 입면 선형에서 잰 값입니다. 2007 해당 단면 치수 확보 전 확정할 수 없습니다.','1996 도면은 정면 6,750 mm 등 2007 평면과 다르므로 높이만 섞어 쓰지 않습니다.','단청·공포 세부와 지붕 비례의 완성 검토가 남아 있습니다.'],
 'sadang-detail-survey-candidate.png'),
item('anchae','안채',['anchae-plan','anchae-front','anchae-section','anchae-schedule1','anchae-schedule2','anchae-schedule3'],
 [['8칸 합계','18,095 mm'],['칸 간격','1,440 / 2,545 / 2,570 / 2,580 / 2,410 / 2,555 / 2,545 / 1,450 mm'],['주 몸체 깊이','3,800 = 실내 2,625 + 앞 퇴칸 1,175 mm'],['대들보','330 × 330 mm'],['마루판','45 mm'],['부엌 WD1','1,120 × 1,720 mm · 판재 24 · 띠장 65 × 40 mm'],['부엌 WW9','1,626 × 560 mm · 틀 52 × 40 · 살 8 × 25 mm'],['방3 WD5','4짝 · 전체 2,274 × 1,710 mm']],
 ['평면, 047 정면, 052 단면과 창호 상세 3장을 대조했습니다.','오른쪽 중간 기둥선은 실내 앞벽이 아닙니다. 앞 퇴칸과 실내 벽선을 구분해야 합니다.','WD7·WD8이 들어 있는 기존 상세 파일의 kitchen이라는 이름은 잘못된 분류입니다. 원문 용도는 방1입니다.'],
 ['오른쪽 앞 퇴칸 깊이를 임의 1,900 mm에서 도면 1,175 mm로 교정','부엌 문판 24 mm·띠장 65 × 40 mm와 마름모 살 8 × 25 mm 적용'],
 ['방3 WD5와 WW5~WW8을 어느 벽면에 배치할지 평면·측면도를 더 대조해야 합니다. 현재 끝방을 막힌 상태로 완성 처리하지 않습니다.','부엌 WD1·WW9의 개별 규격은 확인했지만 현재 모델의 높이 배치에서 서로 가까워지는 문제가 있습니다. 바닥·아궁이 높이도 간섭이 있어 최종 실내로 승인하지 않습니다.','공개된 2007 수리도면 목록을 추가로 찾았으나 제공 파일은 로그인·신청 방식입니다. 기록화 도면과 수리 현황 도면의 연도를 구분해야 합니다.'],
 'anchae-kitchen-door-survey-candidate.png'),
item('arae','아래채',['arae-grid','arae-doors1','arae-doors2'],
 [['표기 총폭','7,500 mm'],['개별 칸 치수','2,430 + 2,370 + 2,670 = 7,470 mm'],['깊이','4,000 = 실내 2,820 + 퇴칸 1,180 mm'],['정면 왼쪽 WD2','1,980 × 1,340 mm · 4짝'],['정면 가운데 WD6','1,110 × 1,210 mm · 2짝'],['정면 오른쪽 WD4','1,220 × 1,340 mm · 2짝']],
 ['026 지붕평면, 027 창호부호 평면, 028 창호표로 아래채를 별도 확인했습니다.','사용자가 중문채라고 정정한 1990 정면도는 아래채 근거에서 제외합니다.'],
 ['뒤바뀌어 있던 정면 가운데 WD6·오른쪽 WD4 규격 교정'],
 ['총폭과 칸별 합계에 30 mm 불일치가 있습니다. 후보의 칸별 +10 mm 배분은 임시값이며 실측값이 아닙니다.','해당 2007 아래채 단면·입면이 현재 보유 묶음에 없어 높이는 확정하지 못했습니다.'],
 'arae-survey-candidate.png'),
item('angotgan','안곳간채',['angotgan-plan','angotgan-section','angotgan-doors'],
 [['기둥 축','9,360 × 2,700 mm'],['4칸','2,250 / 2,250 / 2,430 / 2,430 mm'],['출입문 WD1','정면 3곳 · 폭 900 · 문판 높이 1,500 mm'],['문 높이 구분','회전축 포함 1,620 mm'],['대들보','180 × 240 mm'],['마루면→용마루','4,350 mm']],
 ['029 평면, 033 단면, 037 창호표를 구분해 읽었습니다.','문판 높이와 위아래 회전축을 포함한 높이를 혼동하지 않습니다.'],
 ['4칸·3개 정면 출입문과 대들보 단면 유지 확인'],
 ['기둥은 평면 190 × 190, 단면 195 × 195 mm로 차이가 있습니다.','문판은 평면 30, 단면 20 mm로 충돌합니다. 창호별 최종 채택 근거 확인이 남습니다.','002 범례 6·7과 개별 평면의 건물명·자리 대조가 남습니다.']),
item('gokgan','곳간채 · 광채',['gokgan1993-plan','gokgan2007-plan'],
 [['채택 후보 평면','1993 · 9,750 × 5,460 mm'],['기둥 축','5 × 1,950 / 깊이 2 × 2,730 mm'],['기둥','195 × 195 mm'],['중앙 출입구','1,360 mm'],['비교 도면','2007 곳간채 · 14,240 × 3,010 mm · 6칸']],
 ['사용자 명칭인 곳간채=광채를 유지합니다. 안곳간채는 별개입니다.','002 북측 2번의 넓은 5칸 평면과 1993 도면을 대조했습니다.','2007 곳간채라는 제목의 6칸 도면은 평면 형상이 다릅니다. 이름만 보고 치수를 합치지 않습니다.'],
 ['5칸 후보 유지 · 동일 건물 중복 생성 없음'],
 ['1993 5칸 도면과 2007 002의 동일 건물 대응은 형상 비교 판단입니다. 기록상의 명칭·연혁 확인이 남습니다.']),
item('ansarang','안사랑채 · 별당',['ansarang-plan'],
 [['기둥 축','10,920 = 4 × 2,730 mm'],['깊이','4,260 mm'],['기둥','200 × 200 mm'],['마루판','45 mm'],['오른쪽 퇴칸','1,200 mm']],
 ['048 별당 평면의 왼쪽 부엌·상부 다락, 방, 오른쪽 대청과 둘레 퇴를 구분합니다.','정본과 기존 연결 모델을 재사용합니다.'],
 ['이번 재대조에서는 기존 형상 유지'],
 ['실내·단면 전체를 재구성 완료했다는 뜻은 아닙니다. 현재 평면 확인 범위를 넘는 세부는 별도 검증이 필요합니다.']),
item('ansarangGate','안사랑채 쪽 협문',['ansarang-gate'],
 [['도면','090 정면·좌측면'],['기준','인쇄 치수 없음 · 스케일바로 환산'],['도면 특징','돌계단 5단과 별도 문기둥·인방']],
 ['정면 그림의 크기를 사진 비율로 바꾸지 않고 스케일바를 먼저 사용합니다.'],
 ['기존 후보 유지'],
 ['현재 기둥축 1,420 mm·기둥 145 mm 등의 수치는 선형 환산값입니다. 직접 표기된 실측치로 분류하지 않습니다.']),
item('jung','중문채',['jung-plan'],
 [['기둥 축','10,240 × 2,570 mm'],['5칸','2,100 / 3,050 / 2,330 / 1,830 / 930 mm'],['형상','끝 통로칸 + 방 + 마루 · 사랑채 쪽 연결']],
 ['038 평면의 출입구와 사랑채 연결부를 확인했습니다.','사용자가 정정한 1990 아래채 제목 도면을 현재 아래채로 다시 만들지 않습니다.'],
 ['완성된 중문채 재사용 · 새 복제 모델 생성 없음'],
 ['002 범례 6·7의 개별 평면 대응은 별도 확인이 필요합니다.']),
item('sarang','사랑채 · 기존 정본',['sarang-ceiling'],
 [['전체 가로 기둥 축','14,545 mm'],['분절','2,595 + 9,295 + 2,655 mm'],['주 몸체 깊이','3,985 mm'],['돌출부 폭','3,970 mm'],['전체 세로 기둥 축','7,980 = 5,320 + 2,660 mm']],
 ['014 천정평면의 ㄱ자 골조와 돌출부를 다시 확인했습니다.','이미 승인된 사랑채 모델은 재생성하지 않습니다.'],
 ['기존 정본 형상 유지'],
 ['이번에는 건물 정체성과 주요 축 확인을 했으며 기존 모델의 전 부재를 재측정한 것은 아닙니다.']),
item('mainGate','솟을대문',[],
 [['도면 상태','현재 대응하는 실측 도면 미확보'],['근거','사용자 제공 실사·정본']],
 ['실측 도면이 없는 예외 항목입니다. 사진으로 추정한 높이·폭은 실측값으로 기록하지 않습니다.'],
 ['이번 도면 재대조에서 추가 형상 변경 없음'],
 ['기존 사진 비례 보정값을 도면 100% 일치로 표시하지 않습니다.'])
]
c=json.loads((OUT/'spatial-detail-contract.json').read_text(encoding='utf8'))
validation=json.loads((OUT/'survey-candidate-validation.json').read_text(encoding='utf8'))
registration=[{k:r[k] for k in ('id','rmsAfterPixels','maxAfterPixels','dimensionScale') if k in r} for r in c['site002Registration']['buildings']]
doc={'version':1,'reviewDate':'2026-09-29','units':'mm unless specified','fullSurveyAccuracyClaimed':False,
 'authorityOrder':['개별 도면 인쇄 치수·창호표','해당 건물 평면·입면·단면 교차 대조','002 전체 배치도 위치·회전','정본·8면도 스타일·재료','실사 표면·생활 흔적'],
 'candidateOnly':True,'buildings':buildings,'sources':inventory,'siteRegistration':registration,
 'geometryValidation':{'passed':validation['passed'],'total':len(validation['checks']),'allPassed':validation['allPassed'],'sceneSha256':validation['sceneSha256'],'report':'survey-candidate-validation.json','scope':'구현한 형상 조건 검사. 역사적 고증이나 미확정 도면의 해결을 뜻하지 않음.'},
 'artifacts':[],
 'externalSources':[{'title':'국가유산청 2007 기록화 보고서','url':'https://digital.khs.go.kr/record/recordDetailReport.do?ichDataUid=13897469727560800355&bizId=BIZ200700002080','access':'로그인 필요. 대용량은 제공 신청 방식.'},{'title':'국가유산청 2007 안채 수리 현황 좌우측면도','url':'https://digital.khs.go.kr/record/recordDetailDwg.do?ichDataUid=13897469014735525410&bizId=BIZ200700002055','access':'도면 목록·메타데이터 확인. 공개 본문 미열람; 로그인·제공 신청 필요.'}]}
for rel,role in [('spatial-detail-study.blend','수정 후보'),('scene.blend','기존 브라우저용 원본'),('northern.glb','기존 브라우저 모델'),('../side-connections/connected.glb','기존 사랑채 연결 모델')]:
    p=OUT/rel
    if p.exists():doc['artifacts'].append({'file':rel,'role':role,'bytes':p.stat().st_size,'sha256':sha(p)})
assert doc['artifacts'][0]['sha256']==validation['sceneSha256']
(OUT/'survey-authority.json').write_text(json.dumps(doc,ensure_ascii=False,indent=2),encoding='utf8')

html='''<!doctype html><html lang="ko"><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1"><title>일두고택 · 건물별 도면 대조</title>
<style>
*{box-sizing:border-box}body{margin:0;background:#f4f1ea;color:#292a24;font:16px/1.7 system-ui,sans-serif}header{padding:30px 4vw 22px;border-bottom:1px solid #b9b2a4;background:#eee9de}header small{letter-spacing:.15em;color:#6b695e}h1{font-size:30px;margin:6px 0 12px;font-weight:650}p{max-width:980px;margin:8px 0}a{color:#315342}nav{display:flex;gap:6px;flex-wrap:wrap;padding:18px 4vw;border-bottom:1px solid #c9c2b5}button{font:inherit;border:1px solid #b4ad9f;background:transparent;padding:6px 12px;cursor:pointer}button[aria-pressed=true]{background:#314a3d;color:white;border-color:#314a3d}button:focus-visible,a:focus-visible{outline:3px solid #9b592e;outline-offset:3px}main{padding:22px 4vw}.grid{display:grid;grid-template-columns:minmax(280px,.9fr) minmax(400px,1.5fr);gap:28px}.notes{max-width:700px}h2{font-size:24px;margin:0 0 12px}h3{font-size:17px;margin:22px 0 8px}table{border-collapse:collapse;width:100%;font-size:14px}td,th{border-bottom:1px solid #d0c8ba;text-align:left;padding:9px 5px;vertical-align:top}th{width:34%;font-weight:500;color:#555748}ul{padding-left:20px;margin:8px 0}li{margin:7px 0}.open{border-left:3px solid #a57443;padding:1px 14px;background:#ede5d7}.drawing{background:white;border:1px solid #cdc8be;display:block;width:100%;max-height:76vh;object-fit:contain}.sourcebar{display:flex;flex-wrap:wrap;gap:5px;margin-bottom:9px}.sourcebar button{font-size:13px}figcaption{font-size:13px;color:#66695e;margin:8px 0;overflow-wrap:anywhere}figure{margin:0 0 28px}details{margin:20px 0}summary{cursor:pointer;font-weight:600}.status{border-left:3px solid #536a58;padding-left:14px}code{overflow-wrap:anywhere;font-size:12px}footer{padding:24px 4vw;border-top:1px solid #c9c2b5;font-size:13px}@media(max-width:850px){.grid{grid-template-columns:1fr}h1{font-size:25px}.drawing{max-height:65vh}}
</style>
<header><small>ILDU HOUSE / DRAWING AUDIT / 2026.09.29</small><h1>건물마다 도면을 다시 읽었습니다.</h1><p>인쇄 치수와 창호표를 먼저 적용하고, 평면·입면·단면을 교차 확인합니다. 정본과 8면도는 스타일과 재료, 실사는 도면에 없는 표면과 생활 흔적을 보완합니다.</p><p class="status"><strong>도면 대조 및 수정 후보</strong> · 현재 브라우저의 기존 3D 모델에는 반영하지 않았습니다. 미확정 항목이 남아 있어 전체 100% 일치나 완성본으로 표시하지 않습니다.</p></header>
<nav id="tabs" aria-label="건물 선택"></nav><main><div class="grid"><section class="notes" id="notes"></section><section id="media" aria-label="선택한 도면 및 후보"></section></div><details><summary>배치 정합 잔차와 검증 범위</summary><p>스캔 도면의 기둥 중심점에 위치·회전을 맞췄습니다. 건물 치수 배율은 1을 유지합니다. 잔차는 원본 이미지의 픽셀 단위이며 수치가 0이 아니라는 점을 숨기지 않습니다.</p><table id="registration"></table><p id="validation"></p><a href="site002-fit.svg" target="_blank" rel="noopener">002 배치도 겹침 대조 열기</a> · <a href="survey-candidate-validation.json" target="_blank" rel="noopener">형상 검사 원본</a></details><details><summary>원본 보존과 출처</summary><p id="sourceCount"></p><div id="external"></div><p><a href="survey-authority.json" target="_blank" rel="noopener">건물별 근거 JSON</a> · <a href="survey-source-manifest.json" target="_blank" rel="noopener">도면 파일 및 SHA-256 목록</a></p></details></main><footer>기존 사랑채·중문채 재사용 · 수정 후보와 기존 GLB 분리 · 미확정 치수는 실측값으로 승격하지 않음</footer>
<script id="data" type="application/json">__DATA__</script><script>
const data=JSON.parse(document.querySelector('#data').textContent);const el=(tag,text)=>{const n=document.createElement(tag);if(text)n.textContent=text;return n};const link=(text,href)=>{const n=el('a',text);n.href=href;n.target='_blank';n.rel='noopener';return n};
function list(parent,title,items,cls){const section=el('section');if(cls)section.className=cls;section.append(el('h3',title));const u=el('ul');items.forEach(t=>u.append(el('li',t)));section.append(u);parent.append(section)}
function show(id){const b=data.buildings.find(b=>b.id===id)||data.buildings[0];history.replaceState(null,'','#'+b.id);document.querySelectorAll('#tabs button').forEach(n=>n.setAttribute('aria-pressed',n.dataset.id===b.id));const n=document.querySelector('#notes');n.replaceChildren(el('h2',b.title));const t=el('table');b.printedDimensions.forEach(([k,v])=>{const r=el('tr');r.append(el('th',k),el('td',v));t.append(r)});n.append(t);list(n,'도면에서 확인한 구성',b.interpretation);list(n,'수정 후보에 반영한 내용',b.candidateChanges);list(n,'남은 대조 · 확정하지 않은 항목',b.unresolved,'open');const media=document.querySelector('#media');media.replaceChildren();const srcs=b.sources.map(k=>data.sources.find(r=>r.key===k));if(srcs.length){const bar=el('div');bar.className='sourcebar';const fig=el('figure');const im=el('img');im.className='drawing';const cap=el('figcaption');fig.append(im,cap);const choose=r=>{im.src=r.preview;im.alt=b.title+' '+r.key+' 도면';cap.replaceChildren(link('원본 확대',r.file),el('span',' · '+r.key+' · '+r.size.join(' × ')+' px · 원본 바이트 일치'));bar.querySelectorAll('button').forEach(x=>x.setAttribute('aria-pressed',x.textContent===r.key))};srcs.forEach(r=>{const bt=el('button',r.key);bt.onclick=()=>choose(r);bar.append(bt)});media.append(bar,fig);choose(srcs[0])}else media.append(el('p','대응하는 실측 도면을 아직 확보하지 못했습니다.'));if(b.candidateRender){const fig=el('figure');const im=el('img');im.src=b.candidateRender;im.className='drawing';im.alt=b.title+' 수정 후보 렌더';fig.append(im,el('figcaption','수정 후보 렌더 · 형상 확인용 · 최종 고증 또는 스타일 승인본 아님'));media.append(fig)}}
data.buildings.forEach(b=>{const bt=el('button',b.title);bt.dataset.id=b.id;bt.onclick=()=>show(b.id);document.querySelector('#tabs').append(bt)});show(location.hash.slice(1));
const table=document.querySelector('#registration');const h=el('tr');['건물','평균제곱근 오차(px)','최대 오차(px)','치수 배율'].forEach(v=>h.append(el('th',v)));table.append(h);data.siteRegistration.forEach(r=>{const tr=el('tr');[r.id,r.rmsAfterPixels.toFixed(2),r.maxAfterPixels.toFixed(2),r.dimensionScale].forEach(v=>tr.append(el('td',String(v))));table.append(tr)});const v=data.geometryValidation;document.querySelector('#validation').textContent=`구현 형상 검사 ${v.passed}/${v.total} 통과. ${v.scope}`;document.querySelector('#sourceCount').textContent=`도면 ${data.sources.length}장 원본의 SHA-256과 보존본을 대조했습니다. 모두 동일한 바이트입니다. 화면의 축소 미리보기는 열람용이며 원본 링크는 보존된 원본 파일을 엽니다.`;data.externalSources.forEach(r=>{const p=el('p');p.append(link(r.title,r.url),el('span',' — '+r.access));document.querySelector('#external').append(p)});
</script></html>'''
html=html.replace('__DATA__',json.dumps(doc,ensure_ascii=False).replace('</','<\\/'))
(OUT/'survey-audit.html').write_text(html,encoding='utf8')
print(json.dumps({'drawings':len(inventory),'buildingsAndGates':len(buildings),'validation':doc['geometryValidation'],'report':str(OUT/'survey-audit.html')},ensure_ascii=False))
