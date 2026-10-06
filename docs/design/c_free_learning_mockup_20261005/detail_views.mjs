import {local,ko,meaning,href,grammarQuestion} from './model.mjs';
import {escape as e,art,go,icon,button,quiet,audioButton,structured} from './ui.mjs';
export function grammarDetail(env) {
 const {model,route,t}=env,row=model.maps.grammar.get(route.id),lang=route.lang;
 const linked=model.data.extras.filter(item=>item.kind==='media'&&item.data.grammar_ids.includes(row.id));
 const eligible=grammarQuestion(model,row,lang);
 return {body:`<section class="paper board inset"><p class="eyebrow">${e(row.level)} · ${e(row['type_'+lang])}</p><h1 class="ko">${e(row.pattern)}</h1><p class="space">${e(row['explanation_'+lang])}</p><div class="rule"></div><h2>${t('example')}</h2><div class="example"><p class="ko">${e(row.example_korean)}</p><span class="muted">${e(row[lang==='de'?'example_german':'example_en'])}</span></div>${audioButton(row.example_korean,env)}${row[lang==='de'?'note':'note_en']?`<div class="rule"></div><p class="note">${e(row[lang==='de'?'note':'note_en'])}</p>`:''}<div class="rule"></div>${quiet(env.store.planned(row.id)?t('inPlan'):t('plan'),'plan')}${linked.length?`<h2 class="category-title">${t('media')}</h2>${linked.map(item=>go(route,{view:'extra',m:'extras',id:item.id,item:''},item.data.korean,'quiet')).join('')}`:''}${!eligible?`<p class="notice">${t('notQuiz')}</p>`:''}</section>`,footer:eligible?go(route,{view:'practice',item:'',mode:'quiz'},t('quiz')):go(route,{view:'library',id:'',item:''},t('library'),'button secondary')};
}
export function pronunciationDetail(env) {
 const {model,route,t,ui}=env,row=model.maps.pronunciation.get(route.id),error=route.state==='permission-denied'||ui.micError;
 return {body:`<section class="paper board inset"><p class="eyebrow">${row.level.toUpperCase()} · ${t('pronunciation')}</p><h1 class="ko korean-main">${e(row.ko)}</h1><p>${e(meaning(row,route.lang))}</p><div class="rule"></div><p class="muted">${t('focus')}</p><p class="ko space">${e(row.focus)}</p><div class="rule"></div>${audioButton(row.ko,env)}
 ${ui.recording?`<div class="recording"><span class="record-light"></span><strong class="record-time" role="timer" data-record-timer>00:00</strong></div>`:''}${error?`<p class="audio-status" role="alert">${t('micDenied')}</p>`:''}
 ${ui.recordUrl?`<div class="rule"></div><p class="active-note">${t('recordSaved')}</p><div class="space">${button(t('playMine'),'play-record','secondary')}</div><p class="note space">${t('noScore')}</p>${quiet(t('again'),'record')}`:`<p class="muted space">${t('localOnly')}</p>`}</section>`,footer:ui.recording?button(t('stop'),'stop-record','jade'):button(ui.recordUrl?t('again'):t('record'),'record')};
}
export function relationDetail(env) {
 const {model,route,t}=env,c=model.maps.relations.get(route.id);
 let selected='';
 if(route.item){const field=route.item.slice(c.id.length+1).split(':')[0],i=Number(route.item.split(':').at(-1)),node=c[field]?.[i];
  if(node)selected=`<section class="paper inset space"><h2 class="ko">${e(node.ko)}</h2><p class="space">${e(meaning(node,route.lang))}</p><p class="note space">${e(node[route.lang==='de'?'nuanceDe':'nuanceEn']||'')}</p>${node.exampleKo?`<div class="example"><p class="ko">${e(node.exampleKo)}</p><p class="muted">${e(node[route.lang==='de'?'exampleDe':'exampleEn'])}</p></div>`:''}${audioButton(node.ko,env)}${node.vocabId&&model.maps.vocab.has(node.vocabId)?go(route,{m:'words',view:'card',id:model.maps.vocab.get(node.vocabId).pack_id,item:node.vocabId,mode:'learn'},t('show'),'quiet'):''}</section>`;
 }
 return {body:`<section class="paper board inset"><p class="eyebrow">${e(c.level)} · ${t('relations')}</p><h1 class="ko korean-main">${e(c.sourceKo)}</h1><p>${e(meaning(c,route.lang))}</p><div class="space">${audioButton(c.sourceKo,env)}</div>
 ${['synonyms','antonyms','related','expressions'].filter(field=>c[field].length).map(field=>`<div class="rule"></div><h2 class="category-title">${t(field)}</h2>${c[field].map((node,index)=>`<a class="list-row" data-go href="${e(href(route,{item:c.id+':'+field+':'+index}))}"><span><strong class="ko">${e(node.ko)}</strong><small>${e(meaning(node,route.lang))}</small>${node[route.lang==='de'?'nuanceDe':'nuanceEn']?`<small>${e(node[route.lang==='de'?'nuanceDe':'nuanceEn'])}</small>`:''}${node.exampleKo?`<small class="ko">${e(node.exampleKo)}</small><small>${e(node[route.lang==='de'?'exampleDe':'exampleEn'])}</small>`:''}</span>${icon('next')}</a>`).join('')}`).join('')}</section>${selected}`,footer:go(route,{view:'practice',item:'',mode:'quiz'},t('quiz'))};
}
