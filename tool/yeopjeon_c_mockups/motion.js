/* Bounded 2.5D motion. Animation never awards or spends currency. */
'use strict';
const MOTION={press:150,enter:460,flight:1050,stagger:55,spring:{stiffness:190,damping:22},maxTilt:3};
const motionOff=()=>reduced||document.hidden;
const animate=(node,frames,options)=>{if(!node||motionOff())return;return node.animate(frames,{fill:'none',...options});};
function flyCoins(article,count=8){
 if(motionOff()||!article?.isConnected)return;
 const layer=article.querySelector('.motion-layer'),screen=article.querySelector('.screen');
 const bounds=screen.getBoundingClientRect(),hero=article.querySelector('.hero').getBoundingClientRect(),wallet=article.querySelector('.wallet-badge').getBoundingClientRect();
 const endX=wallet.x-bounds.x+wallet.width/2-13,endY=wallet.y-bounds.y+wallet.height/2-13;
 for(let i=0;i<count;i++){
   const coin=document.createElement('span');coin.className='fly-coin coin-sprite';
   const angle=i/count*Math.PI*2,sx=hero.x-bounds.x+hero.width/2+Math.cos(angle)*hero.width*.3-13,sy=hero.y-bounds.y+hero.height*.55+Math.sin(angle)*60-13;
   coin.style.left='0';coin.style.top='0';layer.append(coin);
   const a=animate(coin,[{transform:`translate3d(${sx}px,${sy}px,90px) rotateY(-45deg) scale(.7)`,opacity:0},{offset:.22,transform:`translate3d(${sx+Math.cos(angle)*35}px,${sy-48}px,130px) rotateY(150deg) scale(1.2)`,opacity:1},{offset:.62,transform:`translate3d(${sx+(endX-sx)*.5}px,${Math.min(sy,endY)-80}px,70px) rotateY(290deg) scale(.95)`,opacity:1},{transform:`translate3d(${endX}px,${endY}px,0) rotateY(360deg) scale(.35)`,opacity:0}],{duration:MOTION.flight,delay:i*MOTION.stagger,easing:'cubic-bezier(.25,.1,.2,1)'});
   if(a)a.finished.then(()=>coin.remove()).catch(()=>coin.remove());else coin.remove();
 }
 animate(article.querySelector('.wallet-badge'),[{transform:'scale(1)'},{transform:'scale(1.12)'},{transform:'scale(.97)'},{transform:'scale(1)'}],{duration:400,delay:750,easing:'ease-out'});
}
function shimmer(article,hero){
 if(motionOff())return;
 const rect=hero.getBoundingClientRect(),parent=article.querySelector('.screen').getBoundingClientRect(),layer=article.querySelector('.motion-layer');
 for(let i=0;i<10;i++){
   const node=document.createElement('i');node.className='magic-spark';const angle=i*Math.PI/5;node.style.left=(rect.x-parent.x+rect.width/2)+'px';node.style.top=(rect.y-parent.y+rect.height*.4)+'px';layer.append(node);
   const a=animate(node,[{transform:'translate3d(0,0,20px) scale(0)',opacity:0},{offset:.3,opacity:1},{transform:`translate3d(${Math.cos(angle)*96}px,${Math.sin(angle)*72}px,65px) scale(.2)`,opacity:0}],{duration:700,delay:i*22,easing:'ease-out'});if(a)a.finished.then(()=>node.remove()).catch(()=>node.remove());else node.remove();
 }
}
function magic(article){
 if(motionOff())return;
 const hero=article.querySelector('.hero');const character=hero.querySelector('.character'),house=hero.querySelector('.house-image');
 animate(character,[{transform:'translateX(-50%) translateY(0) rotateZ(0deg)'},{transform:'translateX(-50%) translateY(-14px) rotateZ(-5deg)'},{transform:'translateX(-50%) translateY(2px) rotateZ(3deg)'},{transform:'translateX(-50%) translateY(0) rotateZ(0deg)'}],{duration:660,easing:'cubic-bezier(.22,.8,.3,1)'});
 animate(house,[{transform:'perspective(650px) rotateY(0deg) translateY(0)'},{transform:'perspective(650px) rotateY(-9deg) translateY(-12px)'},{transform:'perspective(650px) rotateY(5deg) translateY(-3px)'},{transform:'perspective(650px) rotateY(0deg) translateY(0)'}],{duration:1000,easing:'ease-out'});
 animate(hero.querySelector('.locked-depth'),[{transform:'perspective(1000px) rotateY(0deg)'},{transform:'perspective(1000px) rotateY(-3deg) rotateX(1deg) scale(1.015)'},{transform:'perspective(1000px) rotateY(2deg)'},{transform:'perspective(1000px) rotateY(0deg)'}],{duration:850,easing:'cubic-bezier(.2,.8,.2,1)'});
 animate(hero.querySelector('.sealed-art'),[{transform:'perspective(900px) translateY(0) rotateZ(0deg)'},{transform:'perspective(900px) translateY(-7px) rotateZ(-3deg)'},{transform:'perspective(900px) translateY(0) rotateZ(2deg)'},{transform:'perspective(900px) translateY(0) rotateZ(0deg)'}],{duration:740,easing:'ease-out'});
 shimmer(article,hero);const m=models[Number(article.dataset.screen)];if(['first','second','milestone','recovery','failure'].includes(m.state)&&m.amount>0)flyCoins(article,7);
}
function entrance(article){
 if(motionOff()||!article?.isConnected)return;
 const hero=article.querySelector('.hero');
 animate(hero.querySelector('.character'),[{opacity:0,transform:'translateX(-50%) translateY(26px) scale(.9)'},{opacity:1,transform:'translateX(-50%) translateY(-4px) scale(1.03)'},{opacity:1,transform:'translateX(-50%) translateY(0) scale(1)'}],{duration:640,easing:'cubic-bezier(.2,.7,.2,1)'});
 const nodes=[article.querySelector('.reward-amount'),article.querySelector('.next-build'),article.querySelector('.app-foot .primary')].filter(Boolean);
 nodes.forEach((node,i)=>animate(node,[{opacity:0,transform:'translateY(12px)'},{opacity:1,transform:'translateY(0)'}],{duration:MOTION.enter,delay:100+i*70,easing:'cubic-bezier(.2,.7,.2,1)'}));
 const id=Number(article.dataset.screen),m=models[id];
 if(['second','milestone'].includes(m.state))setTimeout(()=>{if(article.isConnected&&!motionOff())flyCoins(article,8);},600);
}
document.addEventListener('sori:screen',e=>{requestAnimationFrame(()=>{if(e.detail.id===undefined)root.querySelectorAll('[data-screen]').forEach(entrance);else entrance(root.querySelector(`[data-screen="${e.detail.id}"]`));});});
document.addEventListener('sori:coins',e=>flyCoins(root.querySelector(`[data-screen="${e.detail.id}"]`),12));
document.addEventListener('sori:built',e=>{const article=root.querySelector(`[data-screen="${e.detail.id}"]`);if(!article||motionOff())return;const house=article.querySelector('.house-image');animate(house,[{transform:'perspective(600px) translateY(35px) rotateX(14deg) scale(.9)',opacity:.4},{transform:'perspective(600px) translateY(-8px) rotateX(0deg) scale(1.03)',opacity:1},{transform:'perspective(600px) translateY(0) rotateX(0deg) scale(1)',opacity:1}],{duration:1100,easing:'cubic-bezier(.2,.8,.2,1)'});shimmer(article,article.querySelector('.hero'));});
root.addEventListener('click',e=>{const hero=e.target.closest('.hero[data-action="magic"]');if(hero)magic(hero.closest('[data-screen]'));});
root.addEventListener('keydown',e=>{if(['Enter',' '].includes(e.key)&&e.target.matches('.hero[data-action="magic"]')){e.preventDefault();magic(e.target.closest('[data-screen]'));}});
/* Spring-driven shallow parallax, updated only during pointer interaction. */
const springs=new WeakMap();
root.addEventListener('pointermove',e=>{
 if(motionOff()||e.pointerType==='touch')return;const hero=e.target.closest('.hero');if(!hero)return;
 const rect=hero.getBoundingClientRect();let state=springs.get(hero);if(!state){state={x:0,y:0,vx:0,vy:0,tx:0,ty:0,running:false};springs.set(hero,state);}
 state.tx=((e.clientX-rect.x)/rect.width-.5)*2;state.ty=((e.clientY-rect.y)/rect.height-.5)*2;
 if(state.running)return;state.running=true;let previous=performance.now();
 function frame(now){if(!hero.isConnected||motionOff()){state.running=false;return;}const dt=Math.min((now-previous)/1000,.032);previous=now;for(const axis of ['x','y']){const velocity='v'+axis,target='t'+axis;state[velocity]+=(MOTION.spring.stiffness*(state[target]-state[axis])-MOTION.spring.damping*state[velocity])*dt;state[axis]+=state[velocity]*dt;}hero.style.setProperty('--pointer-x',state.x.toFixed(3));hero.style.setProperty('--pointer-y',state.y.toFixed(3));if(Math.abs(state.tx-state.x)+Math.abs(state.ty-state.y)+Math.abs(state.vx)+Math.abs(state.vy)<.012){state.running=false;return;}requestAnimationFrame(frame);}requestAnimationFrame(frame);
},{passive:true});
root.addEventListener('pointerout',e=>{const hero=e.target.closest('.hero');if(hero&&!hero.contains(e.relatedTarget)){hero.style.setProperty('--pointer-x','0');hero.style.setProperty('--pointer-y','0');const state=springs.get(hero);if(state){state.tx=0;state.ty=0;}}});
document.addEventListener('visibilitychange',()=>{if(document.hidden){root.querySelectorAll('.fly-coin,.magic-spark').forEach(n=>n.remove());root.getAnimations({subtree:true}).forEach(a=>a.cancel());}});
requestAnimationFrame(()=>root.querySelectorAll('[data-screen]').forEach(entrance));
