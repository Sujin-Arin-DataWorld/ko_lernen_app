from pathlib import Path
P=Path(__file__).resolve().parent.parent
f=P/'app.js';s=f.read_text(encoding='utf-8')
old="function materialLabel(b){return b.newGate||b.materialUserApproved?'승인 재질':'재질 변환 시안 · 검수 중';}"
new="function materialLabel(b){if(b.canonicalMaterial&&!b.canonicalMaterial.viewerUpdated)return '이전 3D 표면 · R5는 재질 렌더';return b.newGate||b.materialUserApproved?'승인 재질':'재질 변환 시안 · 검수 중';}"
assert old in s or new in s;s=s.replace(old,new)
helper="""function referenceViews(){return $('variant').value==='standalone'&&selected.standaloneViews?.length?selected.standaloneViews:selected.views;}
function refreshR5Reference(){const b=selected,standalone=$('variant').value==='standalone';$('referencePicker').replaceChildren(...referenceViews().map((v,i)=>{const o=make('option',v.label+' · '+v.sourceVersion);o.value=i;return o;}));updateReference();if(!b.canonicalMaterial)return;const path=standalone&&b.standaloneNative?b.standaloneNative:b.native,sha=standalone&&b.standaloneNativeSha256?b.standaloneNativeSha256:b.nativeSha256;$('sourceDetails').replaceChildren();for(const [k,v] of [['원본 버전','R5 정본 재질 · '+(standalone?'독립형':'연결형')],['형상 규칙','기존 외관·구조·디테일 보존'],['정본 Blender',path],['SHA-256',sha],['정본 지정 기록','MATERIAL_CANONICAL_PROMOTION_R5.json'],['현재 3D 보기','기존 구조·이전 표면. R5 재질은 원본 재질 렌더에서 확인.']])$('sourceDetails').append(make('dt',k),make('dd',v));}
"""
if 'function referenceViews()' not in s:s=s.replace('function renderDetails(){',helper+'function renderDetails(){')
s=s.replace("function renderDetails(){const b=selected;","function renderDetails(){const b=selected;$('variant').value='connected';")
s=s.replace("$('referencePicker').replaceChildren(...b.views.map((v,i)=>{const o=make('option',v.label+' · '+v.sourceVersion);o.value=i;return o;}));updateReference();","refreshR5Reference();")
s=s.replace("const v=selected.views[Number($('referencePicker').value)||0]","const v=referenceViews()[Number($('referencePicker').value)||0]")
s=s.replace("$('variant').onchange=()=>{setStage(selected.steps.length);","$('variant').onchange=()=>{refreshR5Reference();setStage(selected.steps.length);")
s=s.replace("$('approvalTitle').textContent=b.historicalApproval.status;","$('approvalTitle').textContent=b.canonicalMaterial?'R5 정본 재질 · 사용자 지정':b.historicalApproval.status;")
s=s.replace("$('designation').textContent='2026-10-21 사용자 정본 지정 · 원본 3D와 공정 자료. 앱 적용·출시·실기기 승인은 별도입니다.';","$('designation').textContent=b.canonicalMaterial?'2026-10-22 R5 재질 정본 지정 · Blender 원본과 현재 재질 렌더. 360도 뷰어·앱 표면 반영은 별도입니다.':'2026-10-21 사용자 정본 지정 · 원본 3D와 공정 자료.';")
f.write_text(s,encoding='utf-8')
f=P/'index.html';s=f.read_text(encoding='utf-8')
s=s.replace('href="CANONICAL_PROMOTION.json"','href="MATERIAL_CANONICAL_PROMOTION_R5.json"')
if 'R5 정본 재질·Blender' not in s:s=s.replace('<div class="workspace">','<p style="margin:16px 24px"><a href="lookdev-buildings-r5/index.html?rev=canonical-r5#sarang/detail">R5 정본 재질·Blender 원본 보기 ↗</a> · 현재 360도 보기는 기존 구조·이전 표면입니다.</p><div class="workspace">')
s=s.replace('app.js?v=material-status-20261022','app.js?v=canonical-material-r5');f.write_text(s,encoding='utf-8')
f=P/'export_building_pbr.py';s=f.read_text(encoding='utf-8');s=s.replace("native=(OUT/row['native']).resolve();expected=row['nativeSha256']","native=(OUT/(row['standaloneNative'] if variant and row.get('standaloneNative') else row['native'])).resolve();expected=row['standaloneNativeSha256'] if variant and row.get('standaloneNative') else row['nativeSha256']")
f.write_text(s,encoding='utf-8')
print('CANONICAL SOURCES AND REVIEW LABELS UPDATED')
