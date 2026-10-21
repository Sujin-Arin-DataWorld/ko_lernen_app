from pathlib import Path
OUT=Path(__file__).resolve().parent
p=OUT/'index.html';s=p.read_text(encoding='utf-8')
needle='<label>보기<select id="displayMode">'
insert='<label id="artLightingLabel" hidden>표현<select id="artLighting"><option value="illustrated">일러스트 광원 · 시험</option><option value="source">재질 확인광</option></select></label>'
assert needle in s;s=s.replace(needle,insert+needle)
p.write_text(s,encoding='utf-8')
p=OUT/'app.js';s=p.read_text(encoding='utf-8')
s=s.replace("scene.add(new THREE.HemisphereLight(0xfff8e9,0x6c706b,2));","const hemisphere=new THREE.HemisphereLight(0xfff8e9,0x6c706b,2);scene.add(hemisphere);const directions=[];\nrenderer.shadowMap.enabled=true;renderer.shadowMap.type=THREE.PCFSoftShadowMap;")
s=s.replace("scene.add(l);}","scene.add(l);directions.push(l);}",1)
s=s.replace("function renderDetails(){const b=selected;","function renderDetails(){const b=selected;$('artLightingLabel').hidden=!(b.key==='sadangmun'&&b.materialMode);")
needle="function renderList(){"
fn="""function applyArtLighting(){
 const painted=selected?.key==='sadangmun'&&selected.materialMode&&$('artLighting').value==='illustrated';
 hemisphere.intensity=painted?.9:2;hemisphere.color.set(painted?0xfffaf0:0xfff8e9);
 directions[0].intensity=painted?3.1:2.8;directions[0].color.set(painted?0xfff1dc:0xfff7e8);
 directions[1].intensity=painted?.85:1;directions[1].color.set(painted?0xe6edf0:0xfff7e8);
 directions[0].position.copy(new THREE.Vector3(...(painted?[-4,8,6]:[6,12,8])).normalize().multiplyScalar(radius*6));
 directions[1].position.copy(new THREE.Vector3(...(painted?[4,2,7]:[-8,4,-5])).normalize().multiplyScalar(radius*5));
 const light=directions[0];light.castShadow=!!painted;
 light.shadow.mapSize.set(2048,2048);light.shadow.normalBias=radius*.0008;light.shadow.bias=-.00003;
 const c=light.shadow.camera;c.left=c.bottom=-radius*1.6;c.right=c.top=radius*1.6;c.near=radius*.01;c.far=radius*14;c.updateProjectionMatrix();light.shadow.needsUpdate=true;
 if(root)root.traverse(o=>{if(o.isMesh){o.castShadow=!String(o.userData.sourceObject||'').includes('.paint.');o.receiveShadow=true;for(const m of [].concat(o.material||[]))m.shadowSide=THREE.FrontSide;}});
 if($('displayMode').value==='3d'&&selected?.materialMode)$('viewTag').textContent=painted?'승인 재질 · 일러스트 광원 표본':'실제 3D · 승인 원본 재질';
 invalidate();
}
$('artLighting').onchange=applyArtLighting;
"""
assert needle in s;s=s.replace(needle,fn+needle)
s=s.replace("resize();cameraView();applyStage();$('loading').textContent='';","resize();cameraView();applyStage();applyArtLighting();$('loading').textContent='';")
s=s.replace("history.replaceState(null,'','#'+selected.key+'/'+stage);invalidate();","history.replaceState(null,'','#'+selected.key+'/'+stage);directions[0].shadow.needsUpdate=true;invalidate();")
s=s.replace("if($('displayMode').value==='3d')$('viewTag').textContent=selected.materialMode?'실제 3D · 승인 원본 재질':$('variant').value==='standalone'?'실제 3D · 기존 단독 완성 지붕':'실제 3D · 구조 검토';invalidate();","if(!selected.materialMode&&$('displayMode').value==='3d')$('viewTag').textContent=$('variant').value==='standalone'?'실제 3D · 기존 단독 완성 지붕':'실제 3D · 구조 검토';invalidate();")
p.write_text(s,encoding='utf-8')
print('One-building shrine lighting pilot installed; original textures unchanged')

