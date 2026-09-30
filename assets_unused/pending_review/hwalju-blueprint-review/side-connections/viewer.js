import * as THREE from 'three';
import {GLTFLoader} from 'three/addons/loaders/GLTFLoader.js';
import {OrbitControls} from 'three/addons/controls/OrbitControls.js';
import {EffectComposer} from 'three/addons/postprocessing/EffectComposer.js';
import {SSAOPass} from 'three/addons/postprocessing/SSAOPass.js';
import {OutputPass} from 'three/addons/postprocessing/OutputPass.js';
import {RenderPass} from 'three/addons/postprocessing/RenderPass.js';
const host=document.querySelector('#space'), status=document.querySelector('#status');
const renderer=new THREE.WebGLRenderer({antialias:true});
renderer.setPixelRatio(Math.min(devicePixelRatio,1.5));renderer.shadowMap.enabled=true;
renderer.shadowMap.type=THREE.PCFShadowMap;renderer.shadowMap.autoUpdate=false;
renderer.toneMapping=THREE.ACESFilmicToneMapping;renderer.toneMappingExposure=1.12;
host.append(renderer.domElement);renderer.domElement.setAttribute('role','img');renderer.domElement.setAttribute('aria-label','솟을대문부터 사랑채, 안채와 사당까지 이어지는 고택 3D 공간');renderer.domElement.tabIndex=0;
const scene=new THREE.Scene();scene.background=new THREE.Color('#e9e3d8');
const camera=new THREE.PerspectiveCamera(42,1,.04,250),controls=new OrbitControls(camera,renderer.domElement);
controls.enableDamping=true;controls.minDistance=.7;controls.maxDistance=160;controls.maxPolarAngle=Math.PI*.49;
scene.add(new THREE.HemisphereLight(0xfff5e5,0x716552,1.15));
const sun=new THREE.DirectionalLight(0xffecd4,3);sun.position.set(-26,55,15);sun.target.position.set(8,1.5,-9);scene.add(sun,sun.target);
sun.castShadow=true;sun.shadow.mapSize.set(Math.min(8192,renderer.capabilities.maxTextureSize),Math.min(8192,renderer.capabilities.maxTextureSize));Object.assign(sun.shadow.camera,{left:-54,right:54,top:50,bottom:-50,near:.1,far:180});sun.shadow.bias=.00002;sun.shadow.normalBias=.003;
const fill=new THREE.DirectionalLight(0xdde5ed,.45);fill.position.set(12,10,-10);scene.add(fill);
const ground=new THREE.Mesh(new THREE.PlaneGeometry(65,65),new THREE.MeshStandardMaterial({color:0xb4a58b,roughness:1}));ground.rotation.x=-Math.PI/2;ground.position.set(5,-.28,-4);ground.receiveShadow=true;
const composer=new EffectComposer(renderer),ao=new SSAOPass(scene,camera,800,600,16);
ao.kernelRadius=.26;ao.minDistance=.001;ao.maxDistance=.12;composer.addPass(new RenderPass(scene,camera));composer.addPass(ao);composer.addPass(new OutputPass());
const vec=(a)=>new THREE.Vector3(a[0],a[2],-a[1]);
const views={north:[[-24, -9, 34], [11, 17, 2]],northPlan:[[10, 8, 85], [10, 8, 0]],anchae:[[-5, 6, 10], [10.945, 20.012, 3.1]],arae:[[11, 16, 7], [2.855, 28.004, 3]],angotgan:[[9, 10, 9], [-4.447, 21.683, 3.2]],gokgan:[[10, -1, 9], [24.909, 10.51, 3.6]],sadang:[[12, 13, 9], [24.311, 22.429, 4.2]],sadangmun:[[16, 11, 4.7], [19.859, 16.853, 2.9]],jars:[[12, 19, 12], [15.8, 26.8, 2]],innerRoute:[[18, 3.6, 3.4], [19, 17, 3]],innerCourt:[[-1, 13, 8], [5, 23, 2.5]],anchaeTimber:[[5.7, 18.7, 3.45], [9.3, 18.2, 3.7]],sadangTimber:[[17.2, 19.8, 4.8], [24.311, 22.429, 4.1]],anchaeRear:[[18.0, 20.012, 8.5], [10.945, 20.012, 3.5]],anchaeVeranda:[[21, 29, 4.3], [13.15, 24, 2.7]],anchaeAccess:[[16.9, 25.8, 3.15], [12.55, 22.5, 2.8]],anchaeHall:[[10.095, 16.612, 3.4], [11.191, 19.9245, 3.05]],warehouseEnd:[[-9.6,-9,3.3],[-8.65,-3.535,2.2]],photoFront:[[-8.85,-31.0,3.3],[-6.5,-13.18,2.25]],photoInside:[[-5.33,-4.26,3.2],[-6.5,-13.18,2.25]],soffit:[[-6.95,-16.6,1.65],[-6.45,-12.8,3.4]],estate:[[-39,-51,44],[3,-5,1.5]],estatePlan:[[3,0,86],[3,0,0]],mainGate:[[-14,-24,7],[-6.5,-13.18,2.35]],mainInside:[[0,-2,6.8],[-6.5,-13.18,2.3]],mainDetail:[[-8,-19,3.4],[-6.6,-14.4,2.1]],toilet:[[-16,-10,3.5],[-18.5,-7,1.5]],westBoundary:[[-31,-19,20],[-13,-7,1.1]],eastBoundary:[[28,-36,26],[6,-15,1.3]],enclosure:[[6,-30,27],[22,-10,1.3]],numaruWall:[[21,-19,8],[12.7,-5.5,1.7]],leftJoint:[[-3,10,6],[-5,3.8,1.9]],wallCorridor:[[18,-18,3.5],[18,.1,1.8]],whole:[[-30,-43,35],[9,-3,1.5]],left:[[-6,-5,4.1],[-3.2,3.8,2.2]],leftRear:[[-5,12,4.4],[-2.1,3.8,2.4]],right:[[17,-10,3.6],[18.092,.083,1.9]],rightRear:[[22,10,4.2],[18.092,.083,1.9]],warehouse:[[-.5,3.5,5.5],[-8.634,3.105,2]],plan:[[10,-4,59],[10,-4,0]],detail:[[17.3,-5.8,3],[18.092,.083,2.15]],ansarang:[[12,-17,6],[24,-9.7,2]],path:[[11.3,-13.5,1.72],[24,-14.2,1.8]],ansarangRight:[[16,-22,3.7],[23.7,-13.9,1.9]],joinery:[[19.7,-14,2.2],[23.3,-13.7,1.75]]};
let dirty=true,shadowDirty=true,active='north',old=[],changed=[];
function view(id){active=id;host.dataset.view=id;for(const b of document.querySelectorAll("[data-view]"))b.setAttribute("aria-pressed",String(b.dataset.view===id));const [p,t]=views[id];const factor=Math.max(1,1.2/camera.aspect);camera.position.copy(vec(p).sub(vec(t)).multiplyScalar(factor).add(vec(t)));controls.target.copy(vec(t));controls.update();dirty=true;}
for(const b of document.querySelectorAll('[data-view]'))b.onclick=()=>view(b.dataset.view);
function state(after){ground.visible=!after;for(const o of old)o.visible=!after;for(const o of changed)o.visible=after;document.querySelector('#state').textContent=after?'사당과 안채까지 연결':'확정 사랑채·중문채';document.querySelector('#before').setAttribute('aria-pressed',String(!after));document.querySelector('#after').setAttribute('aria-pressed',String(after));host.dataset.mode=after?'after':'before';dirty=shadowDirty=true;}
document.querySelector('#before').onclick=()=>state(false);document.querySelector('#after').onclick=()=>state(true);
controls.addEventListener('change',()=>dirty=true);
renderer.domElement.addEventListener('keydown',e=>{if(!['ArrowLeft','ArrowRight'].includes(e.key))return;const offset=camera.position.clone().sub(controls.target);offset.applyAxisAngle(new THREE.Vector3(0,1,0),e.key==='ArrowRight'?.12:-.12);camera.position.copy(controls.target).add(offset);controls.update();e.preventDefault();});
new ResizeObserver(()=>{const w=host.clientWidth,h=host.clientHeight;renderer.setSize(w,h);composer.setSize(w,h);camera.aspect=w/h;camera.updateProjectionMatrix();view(active);}).observe(host);
const setup=o=>o.traverse(m=>{if(m.isMesh){m.castShadow=true;m.receiveShadow=true;for(const mat of Array.isArray(m.material)?m.material:[m.material])if(mat.map)mat.map.anisotropy=renderer.capabilities.getMaxAnisotropy();}});
const pivots=[];
async function setupDoors(){
 const contract=await(await fetch('connection-contract.json')).json();const northern=await(await fetch('../northern-court/northern-contract.json')).json();contract.doors.push(...northern.doors);scene.updateMatrixWorld(true);
 for(const door of contract.doors){if(!['left_changgo','right_ansarang','main_gate','toilet','anchae','angotgan','gokgan','sadangmun'].includes(door.building))continue;
  for(let i=0;i<door.hinges.length;i++){
   const parts=changed.filter(o=>o.userData.source_object_name?.startsWith(door.prefix+'.leaf'+(i+1)+'.'));
   const pivot=new THREE.Group();pivot.position.copy(vec(door.hinges[i]));scene.add(pivot);pivot.updateMatrixWorld(true);
   for(const part of parts)pivot.attach(part);
   pivots.push({pivot,building:door.building,leaf:i,sign:door.rotationSigns[i],target:0});
  }
 }
 doorMode('photo',true);
}
function doorMode(mode,instant=false){
 for(const p of pivots){const deg=mode==='closed'?0:mode==='open'?78:p.building==='left_changgo'||p.building==='main_gate'||(p.building==='right_ansarang'&&p.leaf===1)?78:0;p.target=THREE.MathUtils.degToRad(deg)*p.sign;if(instant)p.pivot.rotation.y=p.target;}
 for(const b of document.querySelectorAll('[data-door]'))b.setAttribute('aria-pressed',String(b.dataset.door===mode));dirty=shadowDirty=true;
}
for(const b of document.querySelectorAll('[data-door]'))b.onclick=()=>doorMode(b.dataset.door);
function animateDoors(){for(const p of pivots){const d=p.target-p.pivot.rotation.y;if(Math.abs(d)>.0001){p.pivot.rotation.y+=d*.2;dirty=shadowDirty=true;}}}
try{
 const gltf=await new GLTFLoader().loadAsync('../northern-court/connected.glb?v=361681a9fc33',e=>status.textContent=`3D 불러오는 중 ${e.total?Math.round(100*e.loaded/e.total):0}%`);
 setup(gltf.scene);scene.add(gltf.scene);
 gltf.scene.traverse(o=>{const d=o.userData;if(!d.source_object_name)return;if(d.source_object_name.startsWith('ConnectionSite.')||['left_changgo','right_ansarang','changgo','ansarang','connection_garden','main_gate','toilet','forecourt_wall','anchae','arae','angotgan','gokgan','sadang','sadangmun','north_site'].includes(d.construction_building))changed.push(o);else {const end=d.construction_building==='jung'?12:16;o.visible=d.construction_building!=='context'&&d.construction_first<=end&&d.construction_last>=end;}});
 const proof=await(await fetch('delivery-validation.json')).json();
 for(const index of proof.detachedOldGroundNodes){const o=await gltf.parser.getDependency('node',index);setup(o);scene.add(o);old.push(o);}
 await setupDoors();state(true);host.dataset.loaded='true';document.querySelector('#controls').disabled=false;status.textContent='드래그로 회전 · 휠로 확대 · 문을 열어 마당과 방 안쪽을 확인하세요';
}catch(error){status.textContent='3D 로드 오류: '+error.message;host.dataset.error=error.message;console.error(error);}
function frame(){requestAnimationFrame(frame);controls.update();animateDoors();if(dirty){if(shadowDirty){renderer.shadowMap.needsUpdate=true;shadowDirty=false;}composer.render();dirty=false;host.dataset.camera=camera.position.toArray().map(v=>v.toFixed(3)).join(',');}}
requestAnimationFrame(frame);
