import * as THREE from 'three';
import {GLTFLoader} from 'three/addons/loaders/GLTFLoader.js';
import {DRACOLoader} from 'three/addons/loaders/DRACOLoader.js';
import {OrbitControls} from 'three/addons/controls/OrbitControls.js';
const $=s=>document.querySelector(s),host=$('#space'),labels=$('#labels');
const renderer=new THREE.WebGLRenderer({antialias:true});renderer.setPixelRatio(Math.min(devicePixelRatio,1.35));renderer.toneMapping=THREE.ACESFilmicToneMapping;renderer.toneMappingExposure=.94;renderer.shadowMap.enabled=true;renderer.shadowMap.type=THREE.PCFShadowMap;renderer.shadowMap.autoUpdate=false;host.prepend(renderer.domElement);renderer.domElement.setAttribute('aria-label','최신 수정본 전체 건물과 돌담 3D');renderer.domElement.setAttribute('role','img');
const scene=new THREE.Scene();scene.background=new THREE.Color('#ded8cb');const camera=new THREE.PerspectiveCamera(43,1,.03,400),controls=new OrbitControls(camera,renderer.domElement);controls.enableDamping=true;controls.minDistance=.65;controls.maxDistance=180;controls.maxPolarAngle=Math.PI*.495;
scene.add(new THREE.HemisphereLight(0xfff3df,0x807969,1.85));const sun=new THREE.DirectionalLight(0xfff1d7,1.8);sun.position.set(-30,60,35);sun.target.position.set(8,0,-8);scene.add(sun,sun.target);sun.castShadow=true;sun.shadow.mapSize.set(4096,4096);Object.assign(sun.shadow.camera,{left:-60,right:60,top:60,bottom:-60,near:.1,far:160});sun.shadow.normalBias=.016;sun.shadow.bias=-.00005;
const fill=new THREE.DirectionalLight(0xdce9f4,.48);fill.position.set(30,20,-40);scene.add(fill);
const meta={sarang:['사랑채','구조 유지·돌 안료 후보'],jung:['중문채','구조 유지·재질 조정 후보'],anchae:['안채','먹회색 기와·회벽 후보'],ansarang:['안사랑채·별당','먹회색 기와·돌 안료 후보'],sadang:['사당','먹회색 기와 후보'],sadangmun:['사당문','먹회색 기와 후보'],arae:['아래채','따뜻한 잔 목재 결 후보'],angotgan:['안곳간채','그을린 짙은 결 후보'],gokgan:['곳간채·광채','마른 넓은 결 후보'],changgo:['창고채','승인 원화 목재 유지'],main_gate:['대문채','구조·배치 검토'],toilet:['화장실 ⑫','기존 정본 형태'],toilet1:['화장실 ⑪','안곳간채 뒤 작은 건물'],garden_arae:['아래채 뒤 텃밭','빈 흙밭·낮은 두둑'],garden_changgo:['곳간채 ⑨ 뒤 텃밭','작물·농기구는 추후 아이템'],estate_wall:['이번 연결 담','기존 돌쌓기·기와 마감 적용'],left_changgo:['창고 쪽 협문·담','연결·두께 보완'],right_ansarang:['별당 쪽 협문·담','연결·두께 보완'],north_site:['안채 뒤 협문·북쪽 담','연결·두께 보완'],forecourt_wall:['바깥 돌담','기존 담장 유지'],connection_garden:['정원·담장','연결 검토']};
const presets={whole:[[-39,49,55],[5,1,-6]],plan:[[5,88,-6],[5,0,-6]],court:[[-18,26,-9],[6,2,-22]],gates:[[17,6,-10],[21,3,-17]],south:[[-22,20,23],[5,1,0]],boundary:[[34,19,32],[16,1,17]],service:[[-29,19,1],[-12,1,-13]],gokganRear:[[39,17,-14],[26,2,-11]]};
const viewStatus={whole:'고택 전체',plan:'위에서 본 전체 배치',court:'안채 마당',gates:'사당문·꽃담 접점',south:'사랑채·중문채 접점',boundary:'대문채 오른쪽·별당 담장',service:'중문채·곳간채 뒤 담장',gokganRear:'곳간채 뒤 담과 기단 간격'};
let root,dirty=true,shadowDirty=true,noRoof=false,wallOnly=false,showLabels=true,opened=false,entries=[],meshes=[],pivots=[],manifest,selectedEntry,timberAnchors={};
const vec=a=>new THREE.Vector3(a[0],a[2],-a[1]);
function setView(name){const [p,t]=presets[name];camera.position.fromArray(p);controls.target.fromArray(t);if(camera.aspect<1)camera.position.sub(controls.target).multiplyScalar(1.45).add(controls.target);controls.update();for(const b of document.querySelectorAll('[data-view]'))b.setAttribute('aria-pressed',b.dataset.view===name);if(host.dataset.loaded)$('#status').textContent=viewStatus[name]+' · 드래그로 회전, 휠로 확대';dirty=true;}
function focus(entry){
 selectedEntry=entry;delete host.dataset.detail;
 wallOnly=false;$('#walls').setAttribute('aria-pressed','false');visibility();
 const box=new THREE.Box3();for(const o of entry.objects)box.expandByObject(o);
 const center=box.getCenter(new THREE.Vector3()),direction=new THREE.Vector3(-.65,.60,.95).normalize();
 const right=new THREE.Vector3().crossVectors(camera.up,direction).normalize();
 const up=new THREE.Vector3().crossVectors(direction,right).normalize();
 const vertical=Math.tan(THREE.MathUtils.degToRad(camera.fov)*.5),horizontal=vertical*camera.aspect;
 let distance=.8;
 for(const x of [box.min.x,box.max.x])for(const y of [box.min.y,box.max.y])for(const z of [box.min.z,box.max.z]){
  const offset=new THREE.Vector3(x,y,z).sub(center),depth=offset.dot(direction);
  distance=Math.max(distance,Math.abs(offset.dot(right))*1.16/horizontal+depth,Math.abs(offset.dot(up))*1.16/vertical+depth);
 }
 controls.target.copy(center);camera.position.copy(center).addScaledVector(direction,distance);
 controls.update();$('#status').textContent=entry.title+' · '+entry.state+' — 회전·확대해서 주변 접합부를 확인하세요';dirty=true;
}
function timberDetail(){
 const entry=selectedEntry||entries.find(e=>e.id==='arae'),anchor=timberAnchors[entry?.id];
 if(!anchor){$('#status').textContent='이 건물은 목재 확대 지점이 없습니다. 드래그와 휠로 확인하세요.';return;}
 noRoof=true;wallOnly=false;showLabels=false;
 toggle('#roofs',true,'지붕 다시 보기','지붕 걷어 보기');toggle('#walls',false,'','돌담·문만 보기');
 $('#toggleLabels').setAttribute('aria-pressed','false');visibility();
 controls.target.copy(vec(anchor.point));camera.position.copy(controls.target).addScaledVector(new THREE.Vector3(-.65,.40,.95).normalize(),3.2);
 controls.update();host.dataset.detail='timber';$('#status').textContent=entry.title+' · 목재 모서리 확대 · 지붕은 잠시 걷었습니다';dirty=true;
}
$('#timberDetail').onclick=timberDetail;
function visibility(){for(const o of meshes){const n=(o.userData.source_object_name||o.name).toLowerCase(),id=o.userData.construction_building||'site';const wall=['site','north_site','estate_wall','forecourt_wall','left_changgo','right_ansarang','sadangmun','main_gate','connection_garden'].includes(id);const roof=(Array.isArray(o.material)?o.material:[o.material]).some(m=>m.userData.gyeMatteSurfaceV1==='roof');o.visible=(!wallOnly||wall)&&(!noRoof||!(roof||/roof|giwa/.test(n)));}dirty=shadowDirty=true;}
function toggle(selector,flag,textOn,textOff){$(selector).setAttribute('aria-pressed',String(flag));$(selector).textContent=flag?textOn:textOff;}
$('#roofs').onclick=()=>{noRoof=!noRoof;toggle('#roofs',noRoof,'지붕 다시 보기','지붕 걷어 보기');visibility()};
$('#walls').onclick=()=>{wallOnly=!wallOnly;toggle('#walls',wallOnly,'건물 함께 보기','돌담·문만 보기');visibility()};
$('#toggleLabels').onclick=()=>{showLabels=!showLabels;$('#toggleLabels').setAttribute('aria-pressed',String(showLabels));dirty=true};
$('#reset').onclick=()=>{wallOnly=noRoof=false;toggle('#walls',false,'','돌담·문만 보기');toggle('#roofs',false,'','지붕 걷어 보기');visibility();setView('whole')};
for(const b of document.querySelectorAll('[data-view]'))b.onclick=()=>setView(b.dataset.view);
$('#doors').onclick=()=>{opened=!opened;toggle('#doors',opened,'문 닫기','문 열기');for(const p of pivots)p.node.rotation.y=opened?p.angle:0;dirty=shadowDirty=true;};
function resize(){const w=host.clientWidth,h=host.clientHeight;renderer.setSize(w,h);camera.aspect=w/h;camera.updateProjectionMatrix();dirty=true;}new ResizeObserver(resize).observe(host);resize();setView('whole');controls.addEventListener('change',()=>dirty=true);
const labelProjection=new THREE.Vector3();function drawLabels(){for(const e of entries){labelProjection.copy(e.position).project(camera);const visible=showLabels&&!wallOnly&&labelProjection.z<1&&Math.abs(labelProjection.x)<1&&Math.abs(labelProjection.y)<1;e.label.hidden=!visible||!e.labelled;if(visible){e.label.style.left=(labelProjection.x*.5+.5)*host.clientWidth+'px';e.label.style.top=(-labelProjection.y*.5+.5)*host.clientHeight+'px';}}}
function frame(){requestAnimationFrame(frame);controls.update();if(!dirty)return;if(shadowDirty){renderer.shadowMap.needsUpdate=true;shadowDirty=false;}renderer.render(scene,camera);drawLabels();dirty=false;}frame();
try{
 timberAnchors=(await(await fetch('timber-detail-cameras.json',{cache:'no-cache'})).json()).anchors;
 manifest=await(await fetch('estate/manifest.json',{cache:'no-cache'})).json();let received=0;const parts=[];for(const [i,p] of manifest.chunks.entries()){$('#progress').textContent=`전체 연결본 ${Math.round(received/manifest.bytes*100)}% · ${Math.round(manifest.bytes/1048576)} MB`;const response=await fetch('estate/'+p.file+'?v='+p.sha256);if(!response.ok)throw Error('전체 3D 파일 '+response.status);const bytes=new Uint8Array(await response.arrayBuffer());if(bytes.byteLength!==p.bytes)throw Error('3D 파일 크기 불일치');parts.push(bytes);received+=bytes.byteLength;}
 $('#progress').textContent='건물과 돌담의 입체 정보를 구성하고 있습니다…';const bytes=new Uint8Array(received);let offset=0;for(const p of parts){bytes.set(p,offset);offset+=p.length;}const decoder=new DRACOLoader();decoder.setDecoderPath('vendor/three/examples/jsm/libs/draco/gltf/');decoder.setWorkerLimit(2);const loader=new GLTFLoader().setDRACOLoader(decoder);const gltf=await loader.parseAsync(bytes.buffer,'./');root=gltf.scene;scene.add(root);root.updateMatrixWorld(true);
 const groups=new Map();root.traverse(o=>{if(!o.isMesh)return;let owner=o;while(owner&&!owner.userData.construction_building)owner=owner.parent;if(owner&&owner!==o)o.userData={...owner.userData,...o.userData};meshes.push(o);const id=o.userData.construction_building||'site';o.castShadow=id!=='site'&&!id.startsWith('garden_');o.receiveShadow=true;if(!groups.has(id))groups.set(id,[]);groups.get(id).push(o);for(const m of Array.isArray(o.material)?o.material:[o.material])if(m.map)m.map.anisotropy=Math.min(8,renderer.capabilities.getMaxAnisotropy());});
 for(const [id,[title,state]] of Object.entries(meta)){const objects=groups.get(id);if(!objects?.length)continue;const box=new THREE.Box3();objects.forEach(o=>box.expandByObject(o));const position=box.getCenter(new THREE.Vector3());position.y=box.max.y+.4;const label=document.createElement('span');label.className='label';label.textContent=title;labels.append(label);const entry={id,title,state,objects,position,label,labelled:!['north_site','estate_wall','forecourt_wall','connection_garden','left_changgo','right_ansarang'].includes(id)};entries.push(entry);const button=document.createElement('button');button.className='building';const strong=document.createElement('strong');strong.textContent=title;const note=document.createElement('span');note.textContent=state;button.append(strong,note);button.onclick=()=>focus(entry);$('#inventory').append(button);}
 // Real hinge groups use the exact same world coordinates as the native scene.
 for(const door of manifest.doors){const outerPivots=[];for(let i=0;i<door.hinges.length;i++){const leaves=door.leafGroups?.[i]||[i+1];const pieces=meshes.filter(o=>leaves.some(k=>(o.userData.source_object_name||'').startsWith(door.prefix+'.leaf'+k+'.')));if(!pieces.length)continue;const pivot=new THREE.Group();pivot.position.copy(vec(door.hinges[i]));scene.add(pivot);pivot.updateMatrixWorld(true);for(const p of pieces)pivot.attach(p);outerPivots[i]=pivot;pivots.push({node:pivot,angle:THREE.MathUtils.degToRad(76)*door.rotationSigns[i]});}for(const fold of door.folds||[]){const parent=outerPivots[fold.group];if(!parent)continue;const pivot=new THREE.Group();pivot.position.copy(vec(fold.hinge));scene.add(pivot);pivot.updateMatrixWorld(true);for(const p of meshes.filter(o=>(o.userData.source_object_name||'').startsWith(door.prefix+'.leaf'+fold.leaf+'.')))pivot.attach(p);parent.attach(pivot);pivots.push({node:pivot,angle:THREE.MathUtils.degToRad(76)*fold.relativeSign});}}
 $('#load').classList.add('hidden');host.dataset.loaded='true';host.dataset.meshes=meshes.length;host.dataset.scene=manifest.sceneSha256;$('#timberDetail').disabled=false;$('#status').textContent='최신 전체 건물·돌담 표시 완료 · 드래그로 회전, 휠로 확대';dirty=shadowDirty=true;decoder.dispose();const params=new URLSearchParams(location.search),requested=params.get('focus');if(requested){const entry=entries.find(e=>e.id===requested);if(entry)focus(entry);}else if(presets[params.get('view')])setView(params.get('view'));if(params.get('detail')==='timber')timberDetail();
}catch(error){$('#progress').className='error';$('#progress').textContent='전체 장면을 불러오지 못했습니다: '+error.message;host.dataset.error=error.message;console.error(error);}
