'use strict';
const demoTargets=[...document.querySelectorAll('[data-demo-target]')];
const statusCopy={rest:'기본 · 선명한 형태와 낮은 깊이',preview:'미리보기 · 표면과 오브젝트가 살짝 들림',press:'누르는 중 · 아래면이 줄고 표면이 눌림',release:'손을 뗀 뒤 · 부드럽게 원래 깊이로 복귀'};
let sequence=0,running=false;
function demoState(name){
 for(const target of demoTargets){target.classList.remove('demo-preview','demo-press','demo-release');if(name!=='rest')target.classList.add('demo-'+name);}
 for(const button of document.querySelectorAll('[data-state]'))button.setAttribute('aria-pressed',String(button.dataset.state===name));
 document.querySelector('#motion-status').textContent=statusCopy[name];
}
function stopDemo(){sequence++;running=false;document.querySelector('#play-demo').textContent='모션 순서 재생';}
document.querySelector('#state-controls').addEventListener('click',event=>{const button=event.target.closest('[data-state]');if(!button)return;stopDemo();demoState(button.dataset.state);});
document.querySelector('#play-demo').addEventListener('click',()=>{
 if(running){stopDemo();demoState('rest');return;}
 running=true;const epoch=++sequence;document.querySelector('#play-demo').textContent='재생 멈추기';
 demoState('preview');
 setTimeout(()=>{if(epoch===sequence)demoState('press');},500);
 setTimeout(()=>{if(epoch===sequence)demoState('release');},850);
 setTimeout(()=>{if(epoch===sequence){demoState('rest');stopDemo();}},1300);
});
document.querySelector('#reduce').addEventListener('change',event=>document.body.classList.toggle('reduced',event.target.checked));
document.addEventListener('visibilitychange',()=>{if(document.hidden){stopDemo();demoState('rest');}});
