import {local,meaning,href,ordered} from './model.mjs';
import {escape as e,art,icon,go,button,quiet,audioButton,notesFor,noteLinks} from './ui.mjs';
export function packDetail(env) {
 const {model,route,t}=env,pack=model.maps.packs.get(route.id);
 return {body:`<section class="paper board inset"><p class="eyebrow">${e(pack.level)} · ${pack.wordIds.length} ${t('words')}</p>${art(pack.art||'assets/illustrations/concept_c/book_v2.png',local(pack.title,route.lang),pack.art?'art scene-art':'art book-art')}<h1 class="title-wrap">${e(local(pack.title,route.lang))}</h1><div class="rule"></div><nav class="chips">${go(route,{view:'card',mode:'learn',item:pack.wordIds[0]},t('learn'),'chip active')}${go(route,{view:'practice',mode:'quiz',item:''},t('quiz'),'chip')}${go(route,{view:'practice',mode:'boss',item:''},t('boss'),'chip')}</nav><div class="rule"></div><div class="list">${pack.wordIds.map((id,i)=>{
  const v=model.maps.vocab.get(id);return `<a class="list-row" data-go href="${e(href(route,{view:'card',mode:'learn',item:id,at:i}))}"><span><strong class="ko">${e(v.korean)}</strong><small>${e(meaning(v,route.lang))}</small></span>${icon('next')}</a>`;
 }).join('')}</div></section>`,footer:go(route,{view:'card',mode:'learn',item:pack.wordIds[0],at:0},t('learn'),'button')};
}
export function wordCard(env) {
 const {model,route,t}=env;
 const pack=route.m==='words'?model.maps.packs.get(route.id):null;
 const item=pack?model.maps.vocab.get(route.item||pack.wordIds[route.at]||pack.wordIds[0]):model.maps.vocab.get(route.id)||env.store.custom().find(v=>v.id===route.id);
 const index=pack?pack.wordIds.indexOf(item.id):0;
 const revealed=env.ui.revealed;
 const review=route.m==='review';
 const next=pack?.wordIds[index+1];
 const noteItems=notesFor(item,env);
 const front=`<p class="eyebrow">${e(item.level||'★')} · ${review?t('reviewPool'):t('learn')}</p><div class="card-focus"><h1 class="ko korean-main">${e(item.korean)}</h1>${item.romanization?`<p class="muted">${e(item.romanization)}</p>`:''}${audioButton(item.korean,env)}${revealed?`<div class="rule"></div><p class="word-meaning">${e(meaning(item,route.lang))}</p>`:`<div class="space">${button(t('flip'),'flip','jade')}</div>`}</div>`;
 const explanation=revealed?`<div class="rule"></div><h2>${t('example')}</h2><div class="example"><p class="ko">${e(item.example_korean)}</p><span class="muted">${e(item[route.lang==='de'?'example_german':'example_english']||'')}</span></div>${noteLinks(noteItems,env)}`:'';
 const footer=review?(revealed?`<div class="chips">${button(t('unknown'),'review-grade','secondary', {rating:'again'})}${button(t('defer'),'review-grade','secondary',{rating:'later'})}${button(t('known'),'review-grade','jade',{rating:'known'})}</div>`:button(t('flip'),'flip','jade')):
  revealed?(next?go(route,{item:next,at:index+1},t('continue')):go(route,{view:'practice',mode:'quiz',item:'',at:0},t('quiz'))):button(t('flip'),'flip','jade');
 return {progress:pack?{label:local(pack.title,route.lang),current:index+1,total:pack.wordIds.length}:undefined,
  body:`<section class="paper board inset">${front}${explanation}${revealed?quiet(t('recall'),'recall'):''}</section>`,footer};
}
export function reviewHomeResult(env) {
 const {t,store,route,model}=env, attempts=store.review();
 const items=Object.entries(attempts);
 return {body:`<section class="paper board inset"><div class="line">${art('assets/illustrations/concept_c/seal_v2.png','','seal')}<div><p class="eyebrow">${t('review')}</p><h1>${t('result')}</h1></div></div><div class="metrics"><div class="metric"><strong>${items.filter(([,a])=>a.rating==='known').length}</strong><small>${t('known')}</small></div><div class="metric"><strong>${items.filter(([,a])=>a.rating!=='known').length}</strong><small>${t('unknown')}</small></div></div>${items.length?items.map(([id,a])=>`<div class="list-row"><span><strong class="ko">${e(model.maps.vocab.get(id)?.korean||store.custom().find(v=>v.id===id)?.korean||id)}</strong><small>${t(a.rating==='known'?'known':a.rating==='later'?'defer':'unknown')}</small></span></div>`).join(''):`<p class="muted">${t('noAttempt')}</p>`}<p class="save-status">${t('saved')}</p></section>`,footer:go(route,{view:'library',m:'review',id:'',item:'',mode:''},t('reviewAll'))};
}
