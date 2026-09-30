"""Extend the existing review in place; retain all accepted south GLB bytes."""
from pathlib import Path
import hashlib,json,re,sys,copy,html
ROOT=Path(__file__).resolve().parents[2];BASE=ROOT/'assets_unused/pending_review/hwalju-blueprint-review';S=BASE/'side-connections';N=BASE/'northern-court'
sys.path.insert(0,str(Path(__file__).parent));import glb_parts as glb
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
if '--ui-only' in sys.argv:
 proof=json.loads((N/'delivery-validation.json').read_text());digest=proof['combinedSha256']
else:
 south,blob=glb.read(S/'connected.glb');north,extra=glb.read(N/'northern.glb');original=copy.deepcopy(south);southbytes=bytes(blob)
 contract=json.loads((N/'northern-contract.json').read_text(encoding='utf8'))
 overrides=set(contract.get('southOverrides',[]));replaced=[]
 north_names={n.get('name') for n in north['nodes']}
 assert overrides<=north_names,'Missing exported south surface replacements'
 for node in south['nodes']:
  if node.get('name') in overrides:
   assert 'mesh' in node
   replaced.append(node['name']);del node['mesh'];node['name']+=' [retained source, superseded surface]'
 assert set(replaced)==overrides,'Unknown south replacement name'
 result,joined=glb.append(south,blob,north,extra,join=False)
 for key in ('nodes','meshes','materials','accessors','bufferViews','images'):
  expected=south[key] if key=='nodes' else original[key]
  assert result[key][:len(expected)]==expected,key
 assert joined[0]==southbytes
 digest=glb.write(N/'connected.glb',result,joined)
 proof={'combinedSha256':digest,'southSha256':sha(S/'connected.glb'),'southBytesRetained':len(southbytes),'southNodesUnchanged':len(original['nodes'])-len(replaced),'southSurfaceOverrides':replaced,'northNodes':len(north['nodes']),'northNativeSha256':sha(N/'scene.blend'),'runtimePromoted':False}
 (N/'delivery-validation.json').write_text(json.dumps(proof,indent=2),encoding='utf8')
views={'north':[[-24,-9,34],[11,17,2]],'northPlan':[[10,8,85],[10,8,0]],'anchae':[[-5,6,10],[10.945,20.012,3.1]],'arae':[[11,16,7],[2.855,28.004,3]],'angotgan':[[9,10,9],[-4.447,21.683,3.2]],'gokgan':[[10,-1,9],[24.909,10.51,3.6]],'sadang':[[12,13,9],[24.311,22.429,4.2]],'sadangmun':[[16,11,4.7],[19.859,16.853,2.9]],'jars':[[12,19,12],[15.8,26.8,2]],'innerRoute':[[18,3.6,3.4],[19,17,3]],'innerCourt':[[-1,13,8],[5,23,2.5]]}
labels={'north':'북쪽 연결 전체','northPlan':'고택 전체 배치','anchae':'안채와 대청','arae':'아래채','angotgan':'안곳간채','gokgan':'곳간채 (광채)','sadang':'사당','sadangmun':'사당문','jars':'장독 뒷마당','innerRoute':'협문에서 안쪽으로','innerCourt':'안채 마당'}
views.update({'anchaeTimber':[[5.7,18.7,3.45],[9.3,18.2,3.7]],'sadangTimber':[[17.2,19.8,4.8],[24.311,22.429,4.1]]})
labels.update({'anchaeTimber':'안채 목재 가까이','sadangTimber':'사당 처마 가까이'})
views['anchaeRear']=[[18.0,20.012,8.5],[10.945,20.012,3.5]]
labels['anchaeRear']='안채 뒷면과 벽체'
views['anchaeVeranda']=[[21,29,4.3],[13.15,24,2.7]]
labels['anchaeVeranda']='뒤 툇마루와 방문'
views['anchaeAccess']=[[16.9,25.8,3.15],[12.55,22.5,2.80]]
labels['anchaeAccess']='뒤 방문·주춧돌 가까이'
views['anchaeHall']=[[10.095,16.612,3.40],[11.191,19.9245,3.05]]
labels['anchaeHall']='대청 방문·문틀 두께'
views.update({'rearGates':[[18.8,8.7,3.8],[18.8,16.7,2.7]],'flowerWall':[[20.8,15.2,3.5],[24,16.7,2.35]],'anchaeCorner':[[5.5,5,4.1],[9.3,10.2,2.6]]})
labels.update({'rearGates':'사당문과 뒤뜰 협문','flowerWall':'사당 꽃담 가까이','anchaeCorner':'안채 열린 끝마루'})
contract=json.loads((N/'northern-contract.json').read_text(encoding='utf8'))
for key,view in views.items():
 ident=next((r for r in contract['buildings'] if key.lower().startswith(r['id'])),None)
 if ident and ident.get('placementTransform'):
  mat=ident['placementTransform'];views[key]=[[sum(mat[i][j]*point[j] for j in range(3))+mat[i][3] for i in range(3)] for point in view]
# The south generator is run first on every build, making this extension idempotent.
js=(S/'viewer.js').read_text(encoding='utf8')
js=re.sub(r"loadAsync\('connected.glb[^']*'",f"loadAsync('../northern-court/connected.glb?v={digest[:12]}'",js)
js=js.replace('const views={','const views={'+','.join(f'{key}:{json.dumps(value)}' for key,value in views.items())+',')
js=js.replace("active='mainGate'","active='north'")
js=js.replace("'forecourt_wall'].includes(d.construction_building)","'forecourt_wall','anchae','arae','angotgan','gokgan','sadang','sadangmun','north_site'].includes(d.construction_building)")
js=js.replace("const contract=await(await fetch('connection-contract.json')).json();scene.updateMatrixWorld(true);","const contract=await(await fetch('connection-contract.json')).json();const northern=await(await fetch('../northern-court/northern-contract.json')).json();contract.doors.push(...northern.doors);scene.updateMatrixWorld(true);")
js=js.replace("['left_changgo','right_ansarang','main_gate','toilet'].includes(door.building)","['left_changgo','right_ansarang','main_gate','toilet','anchae','angotgan','gokgan','sadangmun','north_site'].includes(door.building)")
js=js.replace("p.building==='left_changgo'||p.building==='main_gate'||p.leaf===1?78:0","p.building==='left_changgo'||p.building==='main_gate'||p.building==='north_site'||p.building==='anchae'||(p.building==='right_ansarang'&&p.leaf===1)?78:0")
js=js.replace('대문·화장실까지 연결','사당과 안채까지 연결')
js=js.replace('사랑채와 안사랑채, 솟을대문과 화장실을 회전하고 문을 여닫는 3D 공간','솟을대문부터 사랑채, 안채와 사당까지 이어지는 고택 3D 공간')
js=js.replace('left:-36,right:36,top:30,bottom:-30,near:.1,far:100','left:-54,right:54,top:50,bottom:-50,near:.1,far:180')
js=js.replace('sun.position.set(-9,22,10);sun.target.position.set(5,2,-4)','sun.position.set(-26,55,15);sun.target.position.set(8,1.5,-9)')
(S/'viewer.js').write_text(js,encoding='utf8')
page=(S/'review.html').read_text(encoding='utf8')
page=re.sub(r'<title>.*?</title>','<title>일두고택 · 안채와 사당까지</title>',page,count=1)
page=page.replace('대문·화장실까지 연결','안채·사당까지 연결')
page=page.replace('안사랑채의 독립된 마당에서 솟을대문으로, 창고에서 왼쪽 화장실 공간을 돌아 대문으로 이어집니다. 높은 대문 지붕과 낮은 양옆 지붕, 문살과 판문, 돌담 위 겹기와를 가까이 살펴보세요.','사랑마당에서 안사랑채와 곳간채를 지나, 안채 마당과 장독 뒷마당, 사당으로 이어집니다. 목재 가까이 보기에서 기둥과 대들보, 마루 귀틀과 처마의 두께를 살펴보세요.')
page=re.sub(r'<h1>.*?</h1>','<h1>사랑마당에서 안채와 사당까지</h1>',page,count=1)
page=page.replace('<fieldset id="controls" disabled>','<fieldset id="controls" disabled><div class="north-nav">'+''.join(f'<button data-view="{k}">{v}</button>' for k,v in labels.items())+'</div>')
page=page.replace('</style>','.north-nav{padding-bottom:12px;margin-bottom:12px;border-bottom:1px solid #cbbba3}.refviews{display:grid;grid-template-columns:repeat(4,minmax(0,1fr));gap:8px}.refviews img{width:100%;background:#ddd3bf}.north-compare img{background:#ded3bf}.north-compare{margin-top:32px}#space{height:min(78vh,820px)}.north-nav button{font-weight:600}@media(max-width:700px){.refviews{grid-template-columns:repeat(2,minmax(0,1fr))}}</style>')
manifest=json.loads((N/'references/eight-view-manifest.json').read_text(encoding='utf8'))
photo_evidence=json.loads((N/'references/photo-manifest.json').read_text(encoding='utf8'))
gallery='<section class="north-compare"><h2>실사 · 정본 · 이번 3D</h2><p>도면의 칸 구성과 창호를 기준으로 정본 8면도, 국가유산청 기록과 직접 촬영된 답사 사진을 대조했습니다. 곳간채는 광채와 같은 건물이며, 안채 쪽 안곳간채와 구분합니다.</p><p>'
for source in photo_evidence['webSources']:gallery+=f'<a href="{html.escape(source["url"])}" target="_blank" rel="noopener">{html.escape(source["title"])}</a> · '
gallery+='</p><p class="notice">도면에서 확인한 치수와 사진을 보고 복원한 세부를 구분해 검토 중입니다. 전체 고증 100%를 검증 완료한 상태는 아닙니다.</p>'
for ident in ('anchae','sadang','sadangmun'):
 photos=[p for p in photo_evidence['photos'] if p['building']==ident]
 gallery+=f'<h3>{labels[ident]} · 실사 대조</h3><div class="triplet"><figure><a href="../northern-court/references/{photos[0]["file"]}"><img loading="lazy" src="../northern-court/references/{photos[0]["file"]}"></a><figcaption>{html.escape(photos[0]["features"])}</figcaption></figure><figure><img loading="lazy" src="../northern-court/references/{ident}/canonical.png"><figcaption>정본 원화</figcaption></figure><figure><img loading="lazy" src="../northern-court/{ident}.png"><figcaption>이번 입체 제작본</figcaption></figure></div><details><summary>처마·마루·창호 실사 더 보기</summary><div class="refviews">'
 for p in photos[1:]:gallery+=f'<figure><a href="../northern-court/references/{p["file"]}"><img loading="lazy" src="../northern-court/references/{p["file"]}"></a><figcaption>{html.escape(p["features"])}</figcaption></figure>'
 gallery+='</div></details>'
gallery+='<h2>목재의 두께와 맞물림</h2><p>안채 대들보 330×330mm, 안곳간채 보 180×240mm, 사당 대들보 360×390mm를 도면과 대조했습니다. 안채 기둥은 평면도에 적힌 203×219mm, 230×220mm, 242×237mm 등 개별 단면을 반영했습니다. 표기가 없는 주기둥은 기존 210mm 단면을 유지하며 추가 확인이 필요합니다.</p><div class="triplet"><figure><a href="../northern-court/anchae-detail.png"><img loading="lazy" src="../northern-court/anchae-detail.png"></a><figcaption>안채 대청과 귀틀 · 근접</figcaption></figure><figure><a href="../northern-court/sadang-detail.png"><img loading="lazy" src="../northern-court/sadang-detail.png"></a><figcaption>사당 보와 처마 · 근접</figcaption></figure></div>'
gallery+='<h3>대청 방문 · 두꺼운 문틀 안으로 들어간 문짝</h3><p>대청 양옆 방으로 이어지는 외짝 방문 두 곳을 열었습니다. 057 창호표 WD4의 695×1740mm 문짝, 울거미 54×45mm, 살 12×30mm를 각각 입체 부재로 만들었습니다. 고정 문틀은 평면도의 90×175mm와 90×140mm 단면이며, 문을 열면 문틀 옆면과 문짝 두께가 드러납니다. 방1의 두 칸 사이 바닥 틈과 방2 뒤쪽 바닥 틈도 이어 주었습니다. 문 위치는 평면 선을 추적했으며 문턱 높이·작동 여유·작은 철물은 제작 해석입니다. 아래 근접 렌더에는 내부 단면 확인용 부드러운 보조광을 사용했습니다.</p><div class="triplet"><figure><a href="../northern-court/references/anchae/WD4-hall-door-detail.png"><img loading="lazy" src="../northern-court/references/anchae/WD4-hall-door-detail.png"></a><figcaption>057 WD4 · 두께가 적힌 창호표</figcaption></figure><figure><a href="../northern-court/anchae-hall.png"><img loading="lazy" src="../northern-court/anchae-hall.png"></a><figcaption>이번 · 깊은 문틀과 닫힌 띠살문</figcaption></figure><figure><a href="../northern-court/anchae-hall-open.png"><img loading="lazy" src="../northern-court/anchae-hall-open.png"></a><figcaption>이번 · 열린 문짝과 방으로 이어지는 바닥</figcaption></figure></div>'
gallery+='<h3>안채 목재 · 같은 시점 비교</h3><p>기둥·보의 긴 면과 절단면을 구분하고, 마루 널마다 결 방향을 맞췄습니다. 안채와 아래채의 대들보 중심도 바로잡아 뒤쪽 기둥에 걸치도록 했습니다. 안채의 주구조는 깊이 3800mm로 곧게 이어지며, 725mm 돌출부는 오른쪽 방 뒤에 있습니다. 대청 뒤 벽과 판문, 마루 끝을 이 평면에 맞췄습니다. 아래 새 표면은 정본의 색과 필치를 참고한 일러스트 질감이며, 현존 목재의 흠집을 실측한 자료는 아닙니다.</p><div class="triplet"><figure><img loading="lazy" src="../northern-court/anchae-detail-before-craft.png"><figcaption>이전 표면 · 도면 단면 보강 후</figcaption></figure><figure><img loading="lazy" src="../northern-court/anchae-detail.png"><figcaption>이번 표면 · 긴 나뭇결과 끝면 나이테</figcaption></figure></div>'
gallery+='<h2>기와와 돌 · 표면과 단면</h2><p>돌의 과장된 명암을 줄이고 기와마다 작은 색 차이를 두었습니다. 흰 기와 끝막음은 수키와 안을 채우는 반원형 입체로, 기와 몸체는 안쪽 두께가 있는 겹으로 보강했습니다. 기와 두께 8mm와 끝막음의 세부 맞춤은 제작 해석이며 실측 확정값은 아닙니다. 안채와 사당의 마루널은 각각 단면도에 표기된 45mm를 반영했습니다.</p><div class="triplet"><figure><img loading="lazy" src="../northern-court/anchae-detail-before-minerals.png"><figcaption>이전 · 돌의 강한 명암과 균일한 기와</figcaption></figure><figure><img loading="lazy" src="../northern-court/anchae-detail.png"><figcaption>이번 · 입체에 맞춘 광물결과 기와 표면</figcaption></figure><figure><img loading="lazy" src="../northern-court/sadangmun.png"><figcaption>사당문 · 반원형 끝막음과 기와의 겹침</figcaption></figure></div>'
gallery+='<h2>사당문 · 도면에 맞춘 목구조와 기와</h2><p>087·088 도면의 중앙 수키와 여섯 줄과 양쪽 내림마루 3단, 각연 75×90mm, 개판 30mm를 반영했습니다. 지붕 속 흙층과 박공 널도 두께가 있는 입체입니다. 기와 곡선과 칠의 잔결은 실사를 대조한 제작 해석입니다.</p><div class="triplet"><figure><img loading="lazy" src="../northern-court/sadangmun-before-craft.png"><figcaption>이전 · 공통 규칙의 촘촘한 기와</figcaption></figure><figure><img loading="lazy" src="../northern-court/sadangmun.png"><figcaption>이번 · 여섯 수키와 줄과 올라온 내림마루</figcaption></figure><figure><a href="../northern-court/references/sadangmun/elevation-detail-review.png"><img loading="lazy" src="../northern-court/references/sadangmun/elevation-detail-review.png"></a><figcaption>088 정면도 · 기와와 문틀 대조</figcaption></figure></div>'
gallery+='<h3>사당 · 칠 아래 목재의 결</h3><p>기둥과 보에 목재 길이 방향의 잔결을 넣고, 붉은 칠과 녹색 칠의 과한 선명도를 낮췄습니다. 부재 방향에 맞춘 결 위에 실사와 정본을 참고한 단청 문양을 입혔습니다.</p><div class="triplet"><figure><img loading="lazy" src="../northern-court/sadang-detail-before-paint.png"><figcaption>이전 · 작은 원화 조각을 늘린 표면</figcaption></figure><figure><img loading="lazy" src="../northern-court/sadang-detail.png"><figcaption>이번 · 무광 칠과 부재 방향의 나뭇결</figcaption></figure></div>'
gallery+='<h3>사당 · 기둥 위에 앉는 보와 공포</h3><p>앞으로 치우쳤던 대들보를 앞뒤 기둥 축에 맞췄습니다. 059 도면의 부연 87×120mm와 061 도면의 풍판 30mm·덧살 45×27mm를 입체로 반영하고, 지붕 속 흙층과 용마루 속 채움을 연결했습니다. 단청은 실사와 정본의 문양을 참고한 새 일러스트 표면이며, 현존 문양의 실측 복제는 아닙니다.</p><div class="triplet"><figure><img loading="lazy" src="../northern-court/sadang-detail-before-joinery.png"><figcaption>이전 · 앞으로 돌출된 대들보와 늘어난 문양</figcaption></figure><figure><img loading="lazy" src="../northern-court/sadang-detail.png"><figcaption>이번 · 기둥에 앉은 보와 층이 드러나는 공포</figcaption></figure></div>'
gallery+='<figure><a href="../northern-court/sadang-brackets.png"><img loading="lazy" style="width:100%;max-width:960px" src="../northern-court/sadang-brackets.png"></a><figcaption>처마 아래에서 본 공포 · 목재의 옆면, 단청, 회벽과 서까래의 깊이</figcaption></figure>'
gallery+='<h2>여섯 채의 앞뒤 모습과 도면</h2>'
gallery+='<h3>안채 뒤쪽 · 측정 평면 대조</h3><p>국립문화재연구소의 2009년 조사연구 보고서 136쪽 그림 4.15에서, 2007년 정면도와 같은 여덟 칸 치수의 평면을 확인했습니다. 주기둥은 대청 뒤까지 곧게 이어집니다. 이전의 비스듬한 뒤 보와 비틀린 기둥을 수정하고 판문의 회전축도 함께 옮겼습니다. 부엌·방 뒤에 1200mm 툇마루와 낮은 뒷처마를 연결했습니다. 지붕 곡선은 052 단면의 선을 추적한 재구성이며, 뒷면 전체의 처마 꺾임과 현장 지면 높이는 추가 대조가 필요합니다.</p><div class="triplet"><figure><a href="../northern-court/references/anchae/codil-plan-image-0.png"><img loading="lazy" src="../northern-court/references/anchae/codil-plan-image-0.png"></a><figcaption>연구보고서에 수록된 실측 평면 · 3800mm 본체와 뒤쪽 돌출부</figcaption></figure><figure><img loading="lazy" src="../northern-court/anchae-rear-before-plan.png"><figcaption>이전 · 대청부터 뒤로 돌출된 모델</figcaption></figure><figure><img loading="lazy" src="../northern-court/anchae-rear.png"><figcaption>수정 · 대청과 방의 뒤쪽 선을 구분</figcaption></figure></div><p><a href="https://www.codil.or.kr/filebank/original/RK/OTKCRK190980/OTKCRK190980.pdf">출처: 국립문화재연구소 · 목조 건축물의 내진성능 평가항목 개발을 위한 조사연구</a></p>'
gallery+='<h3>안채 뒤 툇마루 · 방에서 뒤뜰로</h3><p>052 단면의 마루널 45mm, 장귀틀 90×135mm, 도리 165×165mm와 장혀 90×150mm를 입체로 만들었습니다. 마루 위에서 도리 밑까지 1525mm인 낮은 공간이며, 두 방문을 열면 벽에 막히지 않고 툇마루로 이어집니다. 방1의 뒤 방문 두 곳은 057 창호표의 WD6에 맞춰 655×1450mm 외짝 격자살문으로 고쳤습니다. 울거미 54×32mm, 살 9×15mm와 평면의 문선 90×120mm를 각각 두께 있는 부재로 만들었습니다. 뒤 툇마루 아래는 단면의 535mm 높이차를 적용해 주춧돌이 드러나도록 낮췄습니다. 고택 전체의 절대 지면 높이와 작은 철물의 형상은 추가 대조 대상입니다.</p><div class="triplet"><figure><img loading="lazy" src="../northern-court/references/photos/anchae-jar-yard.png"><figcaption>뒤뜰 실사 · 낮은 처마와 긴 툇마루</figcaption></figure><figure><a href="../northern-court/references/anchae/section-052-rear-veranda-detail.png"><img loading="lazy" src="../northern-court/references/anchae/section-052-rear-veranda-detail.png"></a><figcaption>052 단면 · 마루와 기둥, 도리의 치수</figcaption></figure><figure><a href="../northern-court/anchae-veranda.png"><img loading="lazy" src="../northern-court/anchae-veranda.png"></a><figcaption>이번 3D · 뒤 툇마루와 낮은 처마</figcaption></figure></div>'
gallery+='<div class="triplet"><figure><a href="../northern-court/references/anchae/WD6-rear-door-detail.png"><img loading="lazy" src="../northern-court/references/anchae/WD6-rear-door-detail.png"></a><figcaption>057 WD6 · 외짝 격자살문 치수</figcaption></figure><figure><img loading="lazy" src="../northern-court/anchae-veranda-before-access.png"><figcaption>이전 · 잘못 대응한 두 짝 창과 높은 기단</figcaption></figure><figure><a href="../northern-court/anchae-access.png"><img loading="lazy" src="../northern-court/anchae-access.png"></a><figcaption>이번 · 외짝문과 드러난 주춧돌</figcaption></figure></div>'
gallery+='<h3>방과 지붕 · 빈틈 없이 이어지는 구조</h3><p>안채의 기둥과 회벽 사이를 연결했습니다. 대청 뒤 판문은 평면도에 맞춰 벽체와 함께 이동했으며, 창호의 폭과 높이는 유지했습니다. 안채·아래채·안곳간채·곳간채의 지붕 속은 닫힌 입체이며 용마루 밑도 이어집니다. 아래채·안곳간채·곳간채의 지붕 속 60mm는 기존 외형을 유지한 제작 두께입니다. 안채의 240mm 지붕 속 두께는 052 단면의 지붕층을 보고 재구성했습니다. 이 두께들은 도면에 숫자로 표기된 실측값이 아닙니다. 안채 처마 밑 회벽은 대청 실사를 참고했습니다.</p><div class="triplet"><figure><img loading="lazy" src="../northern-court/anchae-detail-before-envelope.png"><figcaption>이전 · 대청 뒤 벽체 사이로 새는 빛</figcaption></figure><figure><img loading="lazy" src="../northern-court/anchae-detail.png"><figcaption>이번 · 기둥과 모서리에 이어지는 회벽</figcaption></figure></div><div class="triplet"><figure><img loading="lazy" src="../northern-court/arae-rear-before-envelope.png"><figcaption>이전 · 용마루 아래의 반복된 틈</figcaption></figure><figure><img loading="lazy" src="../northern-court/arae-rear.png"><figcaption>이번 · 지붕 속과 이어지는 용마루</figcaption></figure></div>'
for ident in ('anchae','arae','angotgan','gokgan','sadang','sadangmun'):
 gallery+=f'<h3>{labels[ident]}</h3><div class="triplet"><figure><img loading="lazy" src="../northern-court/references/{ident}/canonical.png"><figcaption>정본 원화</figcaption></figure><figure><img loading="lazy" src="../northern-court/{ident}.png"><figcaption>이번 3D · 입체와 앞면</figcaption></figure><figure><img loading="lazy" src="../northern-court/{ident}-rear.png"><figcaption>이번 3D · 뒷면</figcaption></figure></div><details><summary>정본의 8면도와 도면 보기</summary><div class="refviews">'
 for item in manifest:
  if item['building']==ident and item['role']=='turnaround':gallery+=f'<a href="../northern-court/references/{html.escape(item["file"])}"><img loading="lazy" src="../northern-court/references/{html.escape(item["file"])}"></a>'
 gallery+='</div>'
 bp=[item for item in manifest if item['building']==ident and item['role']=='blueprint']
 if ident in ('anchae','arae','angotgan'):bp+=[{'file':{'anchae':'anchae-front.jpg','arae':'arae-roof.jpg','angotgan':'angotgan-plan.jpg'}[ident]}]
 for item in bp:gallery+=f'<a href="../northern-court/references/{html.escape(item["file"])}">도면 원본 열기</a> '
 gallery+='</details>'
gallery+='<p class="notice">솟을대문은 실사 비례를 기준으로 높이와 폭을 줄였습니다. 5칸 곳간채는 1993년 실측도면(9,750 × 5,460mm)을 적용했습니다. 같은 이름의 2007년 6칸 건물 도면과 구분했습니다.</p></section>'
page=page.replace('<h2>첨부 실사로 다시 만든 솟을대문',gallery+'<h2>첨부 실사로 다시 만든 솟을대문')
page=re.sub(r'viewer.js\?v=[^"\s]+',f'viewer.js?v={hashlib.sha256(js.encode()).hexdigest()[:12]}',page)
(S/'review.html').write_text(page,encoding='utf8')
print(json.dumps(proof),flush=True)
