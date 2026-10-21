import * as THREE from 'three';
import {GLTFLoader} from 'three/addons/GLTFLoader.js';
import {OrbitControls} from 'three/addons/OrbitControls.js';
const $=id=>document.getElementById(id), make=(tag,text)=>{const e=document.createElement(tag);if(text!=null)e.textContent=text;return e;};
const catalog=await fetch('catalog.json',{cache:'no-store'}).then(r=>{if(!r.ok)throw Error('목록 로딩 실패');return r.json();});
const renderer=new THREE.WebGLRenderer({antialias:true,alpha:false,powerPreference:'low-power'});
renderer.setPixelRatio(Math.min(devicePixelRatio,1.5));renderer.outputColorSpace=THREE.SRGBColorSpace;
renderer.toneMapping=THREE.AgXToneMapping;renderer.toneMappingExposure=1.1;
$('viewport').append(renderer.domElement);
const scene=new THREE.Scene();scene.background=new THREE.Color('#e7e0d1');
const hemisphere=new THREE.HemisphereLight(0xfff8e9,0x6c706b,2);scene.add(hemisphere);const directions=[];
renderer.shadowMap.enabled=true;renderer.shadowMap.type=THREE.PCFShadowMap;
for(const [p,e] of [[[6,12,8],2.8],[[-8,4,-5],1]]){const l=new THREE.DirectionalLight(0xfff7e8,e);l.position.set(...p);scene.add(l);directions.push(l);}
const camera=new THREE.PerspectiveCamera(34,1,.01,3000);
const controls=new OrbitControls(camera,$('viewport'));controls.enableDamping=false;controls.autoRotate=false;controls.maxPolarAngle=Math.PI*.96;
const loader=new GLTFLoader();let root=null,selected=null,stage=1,radius=1,epoch=0,controller=null,pending=false,loadingPromise=Promise.resolve(),lastError=null,renderCount=0;
function draw(){pending=false;if(document.hidden)return;renderer.render(scene,camera);renderCount++;}
function invalidate(){if(!pending&&!document.hidden){pending=true;requestAnimationFrame(draw);}}
controls.addEventListener('change',invalidate);
function resize(){const r=$('viewport').getBoundingClientRect();renderer.setSize(r.width,r.height,false);camera.aspect=r.width/Math.max(1,r.height);camera.updateProjectionMatrix();invalidate();}
new ResizeObserver(resize).observe($('viewer'));document.addEventListener('visibilitychange',invalidate);
function dispose(model){if(!model)return;const gs=new Set(),ms=new Set(),ts=new Set(),is=new Set();model.traverse(o=>{if(o.geometry)gs.add(o.geometry);for(const m of [].concat(o.material||[]))ms.add(m);});for(const m of ms)for(const v of Object.values(m))if(v?.isTexture)ts.add(v);for(const t of ts){const im=t.source?.data;if(im?.close)is.add(im);t.dispose();}gs.forEach(g=>g.dispose());ms.forEach(m=>m.dispose());is.forEach(i=>i.close());}
function cameraView(view='hero'){if(!root)return;const ds={hero:[1,.95,1.45],front:[0,.3,1],back:[0,.3,-1],left:[-1,.3,0],right:[1,.3,0],top:[0,1,.001],eaves:[1,.1,1.4]};
 const v=new THREE.Vector3(...ds[view]).normalize(), fov=THREE.MathUtils.degToRad(camera.fov),angle=Math.min(fov/2,Math.atan(Math.tan(fov/2)*camera.aspect));
 camera.position.copy(v.multiplyScalar(radius/Math.sin(angle)*1.08));controls.target.set(0,0,0);controls.update();invalidate();}
function zoom(f){const v=camera.position.clone().sub(controls.target);v.setLength(THREE.MathUtils.clamp(v.length()*f,controls.minDistance,controls.maxDistance));camera.position.copy(controls.target).add(v);controls.update();invalidate();}
function orbit(a,p=0){const v=new THREE.Spherical().setFromVector3(camera.position.clone().sub(controls.target));v.theta+=a;v.phi=THREE.MathUtils.clamp(v.phi+p,.03,Math.PI*.96);camera.position.copy(new THREE.Vector3().setFromSpherical(v).add(controls.target));controls.update();invalidate();}
function applyArtLighting(){
 const painted=selected?.key==='sadangmun'&&selected.materialMode&&$('artLighting').value==='illustrated';
 hemisphere.intensity=painted?1.25:2;hemisphere.color.set(painted?0xfffaf0:0xfff8e9);
 directions[0].intensity=painted?2.8:2.8;directions[0].color.set(painted?0xfff1dc:0xfff7e8);
 directions[1].intensity=painted?1:1;directions[1].color.set(painted?0xe6edf0:0xfff7e8);
 directions[0].position.copy(new THREE.Vector3(...(painted?[-4,8,6]:[6,12,8])).normalize().multiplyScalar(radius*6));
 directions[1].position.copy(new THREE.Vector3(...(painted?[4,2,7]:[-8,4,-5])).normalize().multiplyScalar(radius*5));
 const light=directions[0];light.castShadow=!!painted;
 light.shadow.mapSize.set(2048,2048);light.shadow.radius=3;light.shadow.normalBias=radius*.0008;light.shadow.bias=-.00003;
 const c=light.shadow.camera;c.left=c.bottom=-radius*1.6;c.right=c.top=radius*1.6;c.near=radius*.01;c.far=radius*14;c.updateProjectionMatrix();light.shadow.needsUpdate=true;
 if(root)root.traverse(o=>{if(o.isMesh){o.castShadow=!String(o.userData.sourceObject||'').includes('.paint.');o.receiveShadow=true;for(const m of [].concat(o.material||[]))m.shadowSide=THREE.FrontSide;}});
 if($('displayMode').value==='3d'&&selected?.materialMode)$('viewTag').textContent=painted?'승인 재질 · 일러스트 광원 표본':'실제 3D · 승인 원본 재질';
 invalidate();
}
$('artLighting').onchange=applyArtLighting;
function renderList(){const q=$('search').value.trim();$('buildings').replaceChildren();for(const b of catalog.buildings){if(q&&!b.name.includes(q))continue;const button=make('button',b.name);button.dataset.key=b.key;button.setAttribute('aria-pressed',String(b.key===selected?.key));button.append(make('small',b.steps.length?b.steps.length+'공정 · '+(b.newGate?'최신 문 R6c':'R12 구조'):'공유 공간 · 마당 R5 렌더'));button.onclick=()=>selectBuilding(b.key);$('buildings').append(button);}}
function renderDetails(){const b=selected;$('artLightingLabel').hidden=!(b.key==='sadangmun'&&b.materialMode);$('groupName').textContent=b.group||'공유 공간';$('buildingName').textContent=b.name;
 $('buildingMeta').textContent=(b.steps.length?b.steps.length+'개 공정 · ':'공유 공간 · ')+b.memberCount+'개 원본 부재'+(b.materialMode?' · 승인 원본 재질 포함':' · 구조 검토용');
 $('displayMode').options[0].textContent=b.materialMode?'실제 3D · 승인 원본 재질':'실제 3D · 구조';
 $('materialNote').textContent=b.materialMode?'승인 원본 재질을 부재별 동일 좌표로 베이크했습니다. 드래그 회전 · 휠 / 두 손가락 확대':'구조 검토용 중성 재질입니다. 원본 색과 질감은 재질 렌더로 확인하세요.';
 $('approvalTitle').textContent=b.historicalApproval.status;$('approvalQuote').textContent=b.historicalApproval.quote;$('approvalScope').textContent=b.historicalApproval.scope;
 $('designation').textContent='2026-10-21 사용자 정본 지정 · 원본 3D와 공정 자료. 앱 적용·출시·실기기 승인은 별도입니다.';
 $('sourceDetails').replaceChildren();for(const [k,v] of [['원본 버전',b.newGate?'최신 도면 재제작 R6c':'기존 R12'],['형상 규칙','배치·외관·구조·디테일 고정. 재질·색상만 변경 허용.'],['원본 경로',b.native],['SHA-256',b.nativeSha256||catalog.sourceNative.sha256],['승인 근거 출처',b.historicalApproval.source],['공정 승인','현재 사용자 정본 지정. 과거 모든 단계 개별 승인으로 추정하지 않음.']]){$('sourceDetails').append(make('dt',k),make('dd',v));}
 $('referencePicker').replaceChildren(...b.views.map((v,i)=>{const o=make('option',v.label+' · '+v.sourceVersion);o.value=i;return o;}));updateReference();
 $('stageRange').max=Math.max(1,b.steps.length);$('stageRange').disabled=!b.steps.length;$('assemblyMode').disabled=!b.steps.length;
 $('steps').replaceChildren(...b.steps.map(s=>{const button=make('button',String(s.sequence).padStart(2,'0')+' '+s.label);button.dataset.sequence=s.sequence;button.onclick=()=>setStage(s.sequence);return button;}));
 $('buildingPicker').value=b.key;$('variantLabel').hidden=!b.standaloneModel;$('variant').value='connected';renderList();applyStage();}
function updateReference(){const v=selected.views[Number($('referencePicker').value)||0];if(!v)return;for(const id of ['reference','thumbnail']){$(id).src=v.image;$(id).alt=selected.name+' '+v.label+' 원본 재질 렌더';}$('referenceLink').href=v.image;invalidate();}
function applyStage(){const s=selected.steps[stage-1];let visible=0,total=0;
 if(root)root.traverse(o=>{if(o.userData.reviewStage!=null){o.visible=!s||($('assemblyMode').value==='delta'?o.userData.reviewStage===stage:o.userData.reviewStage<=stage);}if(o.isMesh){total++;if(o.visible&&o.parent?.visible!==false)visible++;}});
 $('stageTitle').textContent=s?String(stage).padStart(2,'0')+' / '+selected.steps.length+' · '+s.label:'담장과 마당 · 전체';
 $('stageDescription').textContent=s?.description||'실제 원본의 담장과 마당 형상입니다. 마당 R5와 담장 R3의 표면은 원본 재질 렌더에서 확인하세요.';
 $('stageCounts').textContent=s?'기존 배정 '+s.memberCount+'부재 · 현재 표시 메시 '+visible+' / '+total+'개'+(s.noNewGeometry?' · 신규 형상 없는 공정':''):'공유 공간은 보상 공정을 추가하지 않습니다.';
 $('stageRange').value=stage;for(const b of $('steps').children)b.setAttribute('aria-pressed',String(Number(b.dataset.sequence)===stage));
 $('previous').disabled=stage<=1;$('next').disabled=stage>=selected.steps.length;$('complete').disabled=!selected.steps.length;
 history.replaceState(null,'','#'+selected.key+'/'+stage);directions[0].shadow.needsUpdate=true;invalidate();}
function setStage(s){if($('variant').value==='standalone'&&Number(s)<selected.steps.length){$('variant').value='connected';epoch++;loadingPromise=loadSelected(epoch);}stage=THREE.MathUtils.clamp(Number(s),1,Math.max(1,selected.steps.length));applyStage();}
async function loadSelected(token){controller?.abort();controller=new AbortController();const signal=controller.signal;$('retry').hidden=true;lastError=null;
 if(root){scene.remove(root);dispose(root);root=null;renderer.renderLists.dispose();}invalidate();
 $('loading').textContent='실제 3D 파일을 불러오는 중…';
 try{const response=await fetch($('variant').value==='standalone'&&selected.standaloneModel?selected.standaloneModel:selected.model,{signal});if(!response.ok)throw Error('3D 파일 응답 '+response.status);
 const bytes=await response.arrayBuffer();if(token!==epoch||signal.aborted)return;
 const gltf=await loader.parseAsync(bytes,new URL('.',location.href).href);
 if(token!==epoch||signal.aborted){dispose(gltf.scene);return;}
 root=gltf.scene;root.updateMatrixWorld(true);const box=new THREE.Box3().setFromObject(root),center=box.getCenter(new THREE.Vector3());radius=Math.max(.1,box.getBoundingSphere(new THREE.Sphere()).radius);
 root.position.sub(center);scene.add(root);camera.near=radius*.02;camera.far=radius*40;camera.updateProjectionMatrix();controls.minDistance=radius*.12;controls.maxDistance=radius*18;
 resize();cameraView();applyStage();applyArtLighting();$('loading').textContent='';if(!selected.materialMode&&$('displayMode').value==='3d')$('viewTag').textContent=$('variant').value==='standalone'?'실제 3D · 기존 단독 완성 지붕':'실제 3D · 구조 검토';invalidate();
 }catch(e){if(token!==epoch||e.name==='AbortError')return;lastError=String(e);$('loading').textContent='3D를 열지 못했습니다. 다시 불러오거나 원본 재질 렌더를 보세요.';$('retry').hidden=false;}}
function selectBuilding(key,requestedStage){const b=catalog.buildings.find(b=>b.key===key)||catalog.buildings[0];selected=b;stage=requestedStage?Math.min(Number(requestedStage),Math.max(1,b.steps.length)):Math.max(1,b.steps.length);epoch++;renderDetails();const token=epoch;loadingPromise=loadSelected(token);return loadingPromise;}
$('displayMode').onchange=()=>{const render=$('displayMode').value==='render';$('reference').hidden=!render;$('viewport').style.visibility=render?'hidden':'visible';controls.enabled=!render;$('viewTag').textContent=render?'Blender 원본 재질 렌더 · 고정 시점':'실제 3D · 구조 검토';$('materialNote').textContent=render?'고정 렌더입니다. 자유 회전은 실제 3D 보기로 돌아가세요.':selected.materialMode?'승인 원본 재질 포함 · 드래그 회전 · 휠 / 두 손가락 확대':'구조 검토용 중성 재질 · 드래그 회전 · 휠 / 두 손가락 확대';applyArtLighting();invalidate();};
$('variant').onchange=()=>{setStage(selected.steps.length);epoch++;loadingPromise=loadSelected(epoch);$('viewTag').textContent=$('variant').value==='standalone'?'실제 3D · 기존 단독 완성 지붕':'실제 3D · 전체 단지 연결형';};
$('referencePicker').onchange=updateReference;$('assemblyMode').onchange=applyStage;$('search').oninput=renderList;
$('buildingPicker').replaceChildren(...catalog.buildings.map(b=>{const o=make('option',b.name+' · '+b.steps.length+'공정');o.value=b.key;return o;}));$('buildingPicker').onchange=()=>selectBuilding($('buildingPicker').value);
$('stageRange').oninput=e=>setStage(e.target.value);$('previous').onclick=()=>setStage(stage-1);$('next').onclick=()=>setStage(stage+1);$('complete').onclick=()=>setStage(selected.steps.length);
$('zoomIn').onclick=()=>zoom(.8);$('zoomOut').onclick=()=>zoom(1.25);$('reset').onclick=()=>cameraView();$('turnLeft').onclick=()=>orbit(-Math.PI/2);$('turnRight').onclick=()=>orbit(Math.PI/2);$('retry').onclick=()=>{epoch++;loadingPromise=loadSelected(epoch);};
document.querySelectorAll('[data-view]').forEach(b=>b.onclick=()=>cameraView(b.dataset.view));
$('viewport').onkeydown=e=>{const keys={ArrowLeft:[-.15,0],ArrowRight:[.15,0],ArrowUp:[0,-.1],ArrowDown:[0,.1]};if(keys[e.key]){e.preventDefault();orbit(...keys[e.key]);}else if(e.key==='+'||e.key==='='){e.preventDefault();zoom(.8);}else if(e.key==='-'){e.preventDefault();zoom(1.25);}else if(e.key==='Home'){e.preventDefault();cameraView();}};
function surfaceState(){const mats=new Set(),textures=new Set();root?.traverse(o=>{for(const m of [].concat(o.material||[])){mats.add(m.uuid);for(const t of Object.values(m))if(t?.isTexture)textures.add(t.uuid);}});return {materialMode:selected?.materialMode||'structural',materials:[...mats].sort(),textures:[...textures].sort(),lighting:$('artLighting').value};}
window.reviewQA={selectBuilding,setStage,surfaceState,ready:()=>loadingPromise,state:()=>({key:selected?.key,stage,loaded:!!root,error:lastError,renderCount,camera:camera.position.toArray(),target:controls.target.toArray(),azimuth:controls.getAzimuthalAngle(),distance:camera.position.distanceTo(controls.target),visibleMeshes:root?(()=>{let n=0;root.traverse(o=>{if(o.isMesh&&o.visible)n++;});return n;})():0}),catalog};
const parts=location.hash.slice(1).split('/');await selectBuilding(parts[0]||'left_changgo',parts[1]);

