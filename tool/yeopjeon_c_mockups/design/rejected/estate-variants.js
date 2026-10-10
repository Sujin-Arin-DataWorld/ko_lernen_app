/* A/B proposal art. These are metaphors for growth, never future stage assets. */
'use strict';
const ESTATE_ART={
 a:{board:'ab-board.png',bw:1374,bh:1145,x:201,y:69,w:472,h:952,scene:{x:222,y:239,w:430,h:379},name:'A · 엽전이 여는 금빛 문'},
 b:{board:'ab-board.png',bw:1374,bh:1145,x:700,y:69,w:475,h:952,scene:{x:723,y:239,w:432,h:379},name:'B · 엽전이 깨우는 나의 마당'}
};
function estateVariant(m){return m.variant==='a'?'a':'b';}
function estateArtStyle(v){return `--art:url('design/${v.board}');--board-w:${v.bw/v.w*100}%;--board-h:${v.bh/v.h*100}%;--board-x:${v.x/(v.bw-v.w)*100}%;--board-y:${v.y/(v.bh-v.h)*100}%;--phone-ratio:${v.w}/${v.h}`;}
function useEstateVisual(m){return exactVisual&&!matchMedia('(max-height:639px)').matches&&lang==='de'&&document.getElementById('size-select').value==='1'&&m.state==='milestone'&&m.balance===70&&m.amount===40;}
function estateEffectLayers(){return '<span class="estate-light" aria-hidden="true"></span><span class="estate-ring ring-one" aria-hidden="true"></span><span class="estate-ring ring-two" aria-hidden="true"></span><span class="estate-ring ring-three" aria-hidden="true"></span><span class="estate-coin-glow" aria-hidden="true"></span>';}
function renderEstateLocked(m){
 const variant=estateVariant(m),v=ESTATE_ART[variant],name=variant==='a'?'Die Münze und das goldene Tor':'Die Münze weckt deinen Hof';
 return `<article class="screen-wrap visual-locked estate-locked variant-${variant}" data-screen="${m.id}" style="${estateArtStyle(v)}"><p class="screen-caption">${v.name}<a href="index.html?solo=1&screen=milestone&variant=${variant}" aria-label="${variant.toUpperCase()}안 한 화면으로 보기">크게 보기 ↗</a></p><div class="phone"><div class="screen locked-screen" lang="de" data-state="${m.state}" data-variant="${variant}" data-balance="${m.balance}" data-owned="${m.owned}" data-eligible="${m.eligible}"><div class="locked-art" aria-hidden="true"></div><div class="locked-semantic sr-only"><span>HANGUL SORI</span><h2 class="app-title" tabindex="-1">Dein Ildu-Haus</h2><p lang="ko">나의 일두고택</p><h3>+40 Yeopjeon</h3><p>Bauzuschuss. Mit jedem Lernen wächst dein Ildu-Haus. Der nächste Teil bleibt eine Überraschung.</p><p>Dein Guthaben: 70 Yeopjeon.</p></div><button class="wallet-badge locked-wallet" data-action="wallet" aria-label="Dein Guthaben: 70 Yeopjeon"><span class="sr-only">70</span></button><button class="hero locked-hero estate-hero" data-action="magic" aria-label="${name}. Tippe auf die Münze." data-effect="ready"><span class="locked-depth estate-depth" aria-hidden="true"></span>${estateEffectLayers()}</button><footer class="locked-foot"><button class="locked-primary" data-action="confirm"><span class="sr-only">Für 40 weiterbauen</span></button><button class="locked-secondary" data-action="learn"><span class="sr-only">Weiterlernen</span></button></footer><div class="motion-layer" aria-hidden="true"></div><div class="sr-only" aria-live="polite" data-live></div></div></div><p class="variant-explanation">${variant==='a'?'엽전 터치 → 문틈의 금빛 → 다음 변화의 기대감':'엽전 터치 → 마당에 퍼지는 빛 → 쌓이는 나의 공간'}<br><small>건설 모습은 건설 후 공개 · 새 정본 에셋은 교체 대기</small></p></article>`;
}
function estateHero(m){
 const variant=estateVariant(m),v=ESTATE_ART[variant],s=v.scene;
 const label=lang==='ko'?'엽전을 눌러 일두고택의 빛 깨우기':lang==='de'?'Tippe auf die Münze und wecke dein Ildu-Haus':'Tap the coin to awaken your Ildu house';
 const art=`--scene-w:${v.bw/s.w*100}%;--scene-h:${v.bh/s.h*100}%;--scene-x:${s.x/(v.bw-s.w)*100}%;--scene-y:${s.y/(v.bh-s.h)*100}%`;
 return `<button class="hero estate-hero estate-editable variant-${variant}" data-action="magic" aria-label="${label}" data-effect="ready" style="${art}"><span class="estate-scene estate-depth" aria-hidden="true"></span>${estateEffectLayers()}<span class="estate-hint" aria-hidden="true">${lang==='ko'?'엽전을 눌러보세요':lang==='de'?'Tippe auf die Münze':'Tap the coin'}</span></button>`;
}
function estateProgress(m){return `<div class="estate-progress"><span>${esc(t('held'))}</span><strong>${m.owned}</strong><span class="growth-dots" aria-hidden="true"><i></i><i></i><i></i><i></i><i></i></span></div>`;}
function awakenEstate(article){
 const hero=article?.querySelector('.estate-hero');if(!hero)return false;
 if(hero.dataset.effect==='playing')return true;
 const variant=estateVariant(models[Number(article.dataset.screen)]);
 if(motionOff()){live(article,t('secretNote'));return true;}
 hero.dataset.effect='playing';
 const depth=hero.querySelector('.estate-depth');
 animate(depth,[{transform:'perspective(1000px) rotateY(0deg) translateY(0)'},{offset:.38,transform:`perspective(1000px) rotateY(${variant==='a'?-3:3}deg) rotateX(2deg) translateY(-6px)`},{transform:'perspective(1000px) rotateY(0deg) translateY(0)'}],{duration:1100,easing:'cubic-bezier(.2,.8,.2,1)'});
 animate(hero.querySelector('.estate-coin-glow'),[{opacity:0,scale:.65},{offset:.3,opacity:.85,scale:1.35},{opacity:0,scale:1.7}],{duration:1000,easing:'ease-out'});
 animate(hero.querySelector('.estate-light'),variant==='a'?[{opacity:0,scale:'0.2 1'},{offset:.4,opacity:.95,scale:'1 1'},{opacity:0,scale:'1.8 1'}]:[{opacity:0,scale:.3},{offset:.4,opacity:.8,scale:1},{opacity:0,scale:1.3}],{duration:1150,easing:'ease-out'});
 hero.querySelectorAll('.estate-ring').forEach((ring,i)=>animate(ring,[{opacity:0,scale:.1},{offset:.2,opacity:.8},{opacity:0,scale:variant==='a'?1.1:1.5}],{duration:1150,delay:i*120,easing:'cubic-bezier(.15,.5,.4,1)'}));
 shimmer(article,hero);
 const layer=article.querySelector('.motion-layer'),bounds=article.querySelector('.screen').getBoundingClientRect(),rect=hero.getBoundingClientRect();
 for(let i=0;i<8;i++){
  const node=document.createElement('span');node.className='fly-coin coin-sprite';layer.append(node);
  const a=i/8*Math.PI*2,cx=rect.x-bounds.x+rect.width*.5-13,cy=rect.y-bounds.y+rect.height*.48-13;
  const flight=animate(node,[{transform:`translate3d(${cx+Math.cos(a)*rect.width*.39}px,${cy+Math.sin(a)*rect.height*.4}px,80px) rotateY(0deg) scale(.9)`,opacity:0},{offset:.15,opacity:1},{offset:.7,transform:`translate3d(${cx+Math.cos(a+1)*35}px,${cy+Math.sin(a+1)*30}px,160px) rotateY(220deg) scale(.85)`,opacity:1},{transform:`translate3d(${cx}px,${cy}px,0) rotateY(360deg) scale(.15)`,opacity:0}],{duration:1000,delay:i*55,easing:'cubic-bezier(.3,.05,.2,1)'});
  if(flight)flight.finished.then(()=>node.remove()).catch(()=>node.remove());else node.remove();
 }
 live(article,t('secretNote'));
 setTimeout(()=>{if(hero.isConnected)hero.dataset.effect='ready';},1600);
 return true;
}
