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
host.append(renderer.domElement);renderer.domElement.setAttribute('role','img');renderer.domElement.setAttribute('aria-label','중문채 지면 수정 전후를 회전하고 확대하는 3D 공간');renderer.domElement.tabIndex=0;
const scene=new THREE.Scene();scene.background=new THREE.Color('#e9e3d8');
const camera=new THREE.PerspectiveCamera(42,1,.04,100),controls=new OrbitControls(camera,renderer.domElement);
controls.enableDamping=true;controls.minDistance=.7;controls.maxDistance=65;controls.maxPolarAngle=Math.PI*.49;
scene.add(new THREE.HemisphereLight(0xfff5e5,0x716552,1.15));
const sun=new THREE.DirectionalLight(0xffecd4,3);sun.position.set(-9,22,10);sun.target.position.set(5,2,-4);scene.add(sun,sun.target);
sun.castShadow=true;sun.shadow.mapSize.set(4096,4096);Object.assign(sun.shadow.camera,{left:-18,right:18,top:18,bottom:-18,near:1,far:65});sun.shadow.bias=-.00005;sun.shadow.normalBias=.008;
const fill=new THREE.DirectionalLight(0xdde5ed,.45);fill.position.set(12,10,-10);scene.add(fill);
const ground=new THREE.Mesh(new THREE.PlaneGeometry(65,65),new THREE.MeshStandardMaterial({color:0xb4a58b,roughness:1}));ground.rotation.x=-Math.PI/2;ground.position.set(5,-.28,-4);ground.receiveShadow=true;scene.add(ground);
const composer=new EffectComposer(renderer),ao=new SSAOPass(scene,camera,800,600,16);
ao.kernelRadius=.26;ao.minDistance=.001;ao.maxDistance=.12;composer.addPass(new RenderPass(scene,camera));composer.addPass(ao);composer.addPass(new OutputPass());
const vec=(a)=>new THREE.Vector3(a[0],a[2],-a[1]);
const views={connection:[[-23,3,5.6],[4,6,2.3]],junction:[[-10,-2,4],[0,3.7,1.5]],gate:[[-10,18,4.8],[0,12.8,1.9]],pair:[[-23,-26,17],[6,5,2.7]],front:[[12,-16,7],[7.4,-.1,2.7]]};
let dirty=true,shadowDirty=true,active='connection',old=[],changed=[];
function view(id){active=id;const [p,t]=views[id];const factor=Math.max(.45,1.2/camera.aspect);camera.position.copy(vec(p).sub(vec(t)).multiplyScalar(factor).add(vec(t)));controls.target.copy(vec(t));controls.update();dirty=true;}
for(const b of document.querySelectorAll('[data-view]'))b.onclick=()=>view(b.dataset.view);
function state(after){ground.visible=!after;for(const o of old)o.visible=!after;for(const o of changed)o.visible=after;document.querySelector('#state').textContent=after?'이어지는 흙 지면':'수정 전 바닥판';document.querySelector('#before').setAttribute('aria-pressed',String(!after));document.querySelector('#after').setAttribute('aria-pressed',String(after));host.dataset.mode=after?'after':'before';dirty=shadowDirty=true;}
document.querySelector('#before').onclick=()=>state(false);document.querySelector('#after').onclick=()=>state(true);
controls.addEventListener('change',()=>dirty=true);
renderer.domElement.addEventListener('keydown',e=>{if(!['ArrowLeft','ArrowRight'].includes(e.key))return;const offset=camera.position.clone().sub(controls.target);offset.applyAxisAngle(new THREE.Vector3(0,1,0),e.key==='ArrowRight'?.12:-.12);camera.position.copy(controls.target).add(offset);controls.update();e.preventDefault();});
new ResizeObserver(()=>{const w=host.clientWidth,h=host.clientHeight;renderer.setSize(w,h);composer.setSize(w,h);camera.aspect=w/h;camera.updateProjectionMatrix();view(active);}).observe(host);
const setup=o=>o.traverse(m=>{if(m.isMesh){m.castShadow=true;m.receiveShadow=true;for(const mat of Array.isArray(m.material)?m.material:[m.material])if(mat.map)mat.map.anisotropy=renderer.capabilities.getMaxAnisotropy();}});
try{
 const gltf=await new GLTFLoader().loadAsync('pair-corrected.glb',e=>status.textContent=`3D 불러오는 중 ${e.total?Math.round(100*e.loaded/e.total):0}%`);
 setup(gltf.scene);scene.add(gltf.scene);
 gltf.scene.traverse(o=>{const d=o.userData;if(!d.source_object_name)return;if(d.source_object_name.startsWith('TerrainFix.'))changed.push(o);else {const end=d.construction_building==='jung'?12:16;o.visible=d.construction_building!=='context'&&d.construction_first<=end&&d.construction_last>=end;}});
 const proof=await(await fetch('delivery-validation.json')).json();
 for(const index of proof.detachedOldGroundNodes){const o=await gltf.parser.getDependency('node',index);setup(o);scene.add(o);old.push(o);}
 state(true);host.dataset.loaded='true';document.querySelector('#controls').disabled=false;status.textContent='같은 시점에서 수정 전·후를 바꾸세요. 드래그로 회전 · 휠로 확대';
}catch(error){status.textContent='3D 로드 오류: '+error.message;host.dataset.error=error.message;console.error(error);}
function frame(){requestAnimationFrame(frame);controls.update();if(dirty){if(shadowDirty){renderer.shadowMap.needsUpdate=true;shadowDirty=false;}composer.render();dirty=false;host.dataset.camera=camera.position.toArray().map(v=>v.toFixed(3)).join(',');}}
requestAnimationFrame(frame);
