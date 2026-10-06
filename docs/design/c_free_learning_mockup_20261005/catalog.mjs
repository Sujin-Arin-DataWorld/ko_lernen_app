import {MODULES,local,ko,meaning,href} from './model.mjs';
import {escape as e,art,tools,icon,go,button} from './ui.mjs';
export const moduleArt=(module,model)=>model.data.assetHashes['assets/illustrations/activities/'+tools[module]?.art+'.webp']?'assets/illustrations/activities/'+tools[module].art+'.webp':'assets/illustrations/concept_c/book_v2.png';
const size=(module,data)=>({words:data.packs.length,review:data.vocab.length,grammar:data.grammar.length,pronunciation:data.pronunciation.length,listening:data.listening.length,scenarios:data.scenarios.length,relations:data.relations.length,extras:data.extras.length})[module];
export function home(env) {
 const {model,route,t}=env;
 const last=env.store.last();
 return {title:t('free'),subtitle:t('choose'),headingArt:'assets/illustrations/concept_c/book_v2.png',body:`${last?`<section class="paper inset space"><p class="eyebrow">${t('continue')}</p>${go(route,last,tools[last.m]?.[route.lang]||t('free'),'button jade')}</section><div class="space"></div>`:''}
 <div class="grid">${MODULES.map(module=>`<a class="paper tool" href="${e(href(route,{view:'library',m:module,id:'',item:'',mode:'',level:'all',page:0,q:'',topic:''}))}" data-go>${art(moduleArt(module,model),'')}<strong>${e(tools[module][route.lang])}</strong><small>${size(module,model.data)} ${t(module==='words'?'patterns':module==='grammar'?'patterns':module==='pronunciation'?'phrases':module==='relations'?'clusters':module==='review'?'words':'lessons')}</small></a>`).join('')}</div>
 <div class="space">${go(route,{view:'library',m:'extras',id:'',topic:'',q:'',page:0},t('extras'),'quiet')}</div>`};
}
export function collection(env) {
 const {model,route}=env;
 return ({words:model.data.packs,review:[...model.data.vocab,...env.store.custom()],grammar:model.data.grammar,
  pronunciation:model.data.pronunciation,listening:model.data.listening,scenarios:model.data.scenarios,relations:model.data.relations,extras:model.data.extras})[route.m]||[];
}
export function itemTitle(item,env) {
 const lang=env.route.lang;
 if(item.title)return local(item.title,lang);
 if(item.kind==='patterns')return item.data['name_'+lang];
 if(item.kind==='media')return item.data.korean;
 if(item.kind==='usage')return env.model.maps.vocab.get(item.data.id)?.korean||item.data.nuance?.ko||item.data.id;
 if(item.kind==='culture')return item.data.ko;
 return ko(item);
}
export function itemSub(item,env) {
 const {route,t}=env;
 if(item.wordIds)return `${item.wordIds.length} ${t('words')} · ${item.normalIds.length} Quiz · ${item.bossIds.length} Boss`;
 if(item.questions)return `${item.questions.length} ${t('question')} · ${item.level.toUpperCase()}`;
 if(item.quests)return local(item.intro,route.lang);
 if(item.sourceKo)return meaning(item,route.lang);
 if(route.m==='grammar')return item['type_'+route.lang];
 if(item.kind)return item.kind==='patterns'?item.data['explanation_'+route.lang]:item.kind==='media'?meaning(item.data,route.lang):env.t(item.kind==='usage'?'notes':item.kind);
 return meaning(item,route.lang);
}
const itemLevel = item => (item.level||item.data?.level||'').toUpperCase();
const topicKey = (item,module) => module==='words'?item.topic:module==='listening'?item.topicId:module==='scenarios'?item.shelf:module==='extras'?item.kind:'';
export function library(env) {
 const {model,route,t}=env, all=collection(env);
 const filtered=all.filter(item=>(route.level==='all'||itemLevel(item)===route.level)&&(route.topic===''||topicKey(item,route.m)===route.topic)&&
  (!route.q||JSON.stringify(item).toLocaleLowerCase().includes(route.q.toLocaleLowerCase())));
 const per=24,page=Math.min(route.page,Math.max(0,Math.ceil(filtered.length/per)-1));
 const topics=[...new Set(all.map(item=>topicKey(item,route.m)).filter(Boolean))];
 const levels=[...new Set(all.map(itemLevel).filter(Boolean))].sort();
 const topicLabel=key=>route.m==='extras'?t(key==='usage'?'notes':key==='patterns'?'patterns':key):route.m==='words'?key:itemTitle(all.find(item=>topicKey(item,route.m)===key),env);
 const list=filtered.slice(page*per,(page+1)*per).map(item=>{
  const view=route.m==='review'?'card':route.m==='extras'?'extra':'detail';
  const picture=item.art|| (item.backdrop&&model.data.assetHashes[`assets/illustrations/scenes/${item.backdrop}.png`]?`assets/illustrations/scenes/${item.backdrop}.png`:'');
  return `<a class="list-row" href="${e(href(route,{view,id:item.id,item:'',mode:'',state:'',at:0}))}" data-go ${itemLevel(item)?`data-level="${e(itemLevel(item))}"`:''}>${art(picture,'','mini-art')}<span><strong class="${['review','relations','pronunciation'].includes(route.m)?'ko':''}">${e(itemTitle(item,env))}</strong><small>${e(itemSub(item,env))}</small></span>${icon('next')}</a>`;
 }).join('');
 const extras=route.m==='review'?`${button(t('add'),'add-word','secondary')}<p class="muted space">${t('localOnly')}</p>`:route.m==='listening'?`${button(t('setGoal'),'goal','secondary')}<div class="space"></div>`:route.m==='grammar'?go(route,{m:'extras',view:'library',id:'',topic:'patterns',q:'',page:0},`${model.data.extras.filter(e=>e.kind==='patterns').length} ${t('patterns')}`,'quiet'):'';
 return {title:tools[route.m][route.lang],subtitle:route.m==='review'?t('reviewPool'):'',headingArt:moduleArt(route.m,model),body:`<section class="paper board inset"><form data-filter class="filters"><div class="search"><label class="sr-only" for="search">${t('search')}</label><input id="search" type="search" name="q" value="${e(route.q)}" placeholder="${t('search')}" autocomplete="off"><button class="icon" aria-label="${t('search')}" type="submit">${icon('search')}</button></div><div class="filter-row"><label><span class="sr-only">${t('all')}</span><select name="level" aria-label="${t('all')}"><option value="all">${t('all')}</option>${levels.map(level=>`<option ${level===route.level?'selected':''} value="${e(level)}">${e(level)}</option>`).join('')}</select></label>${topics.length?`<label><span class="sr-only">${t('topic')}</span><select name="topic" aria-label="${t('topic')}"><option value="">${t('topic')}</option>${topics.map(key=>`<option ${key===route.topic?'selected':''} value="${e(key)}">${e(topicLabel(key))}</option>`).join('')}</select></label>`:''}</div></form>
 ${extras}<p class="muted">${filtered.length} / ${all.length}</p><div class="list">${list||`<div class="empty"><h2>${t('noResults')}</h2><p>${t('adjust')}</p>${go(route,{q:'',level:'all',topic:'',page:0},t('clear'),'button secondary')}</div>`}</div>
 ${filtered.length>per?`<nav class="pagination" aria-label="${t('page')}">${page>0?go(route,{page:page-1},t('back'),'quiet'):'<span></span>'}<span class="muted">${page+1} / ${Math.ceil(filtered.length/per)}</span>${(page+1)*per<filtered.length?go(route,{page:page+1},t('next'),'quiet'):'<span></span>'}</nav>`:''}</section>`};
}
export function extra(env) {
 const {model,route,t}=env, item=model.maps.extras.get(route.id), value=item.data, lang=route.lang;
 let body='';
 if(item.kind==='patterns')body=`<h1>${e(value['name_'+lang])}</h1><p class="space">${e(value['explanation_'+lang])}</p>`;
 if(item.kind==='culture')body=`<h1 class="ko">${e(value.ko)}</h1><p class="space">${e(value[lang])}</p>`;
 if(item.kind==='media')body=`<h1 class="ko">${e(value.korean)}</h1><p class="space">${e(meaning(value,lang))}</p><p class="muted space">${e(value.romanization)}</p><p class="space">${e(value['context_'+lang])}</p><div class="rule"></div>${value.grammar_ids.map(id=>model.maps.grammar.has(id)?go(route,{view:'detail',m:'grammar',id,item:''},model.maps.grammar.get(id).pattern,'quiet'):`<p class="source-id">${e(id)} · ${t('missing')}</p>`).join('')}`;
 if(item.kind==='usage')body=`<h1 class="ko">${e(itemTitle(item,env))}</h1>${Object.entries(value).filter(([key])=>!['id','level','register'].includes(key)).map(([key,part])=>`<div class="notice">${env.structured(part,lang)}</div>`).join('')}`;
 return {body:`<section class="paper board inset note">${body}</section>`,footer:go(route,{view:'library',m:'extras',id:'',item:''},t('library'),'button secondary')};
}
