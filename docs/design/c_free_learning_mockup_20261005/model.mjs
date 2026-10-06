export const MODULES = ['words', 'review', 'grammar', 'pronunciation', 'listening', 'scenarios', 'relations'];
export const stages = ['intro', 'vocab', 'dialog', 'grammar', 'role', 'quests', 'result'];
export const normalise = value => String(value ?? '').trim().replace(/\s+/g, ' ');
export const local = (value, lang) => typeof value === 'string' ? value : value?.[lang] ?? value?.de ?? value?.ko ?? '';
export const ko = value => value?.korean ?? value?.ko ?? value?.sourceKo ?? value?.pattern ?? '';
export const meaning = (value, lang) => value?.[lang] ?? value?.[lang === 'de' ? 'german' : 'english'] ?? value?.[lang === 'de' ? 'sourceDe' : 'sourceEn'] ?? '';
export function indexData(data) {
  const maps = {};
  for (const name of ['vocab', 'packs', 'grammar', 'pronunciation', 'listening', 'scenarios', 'relations', 'extras']) {
    maps[name] = new Map(data[name].map(item => [item.id, item]));
  }
  const all = Object.values(maps).flatMap(map => [...map.values()]);
  const byKo = new Map(data.vocab.map(v => [v.korean.trim(), v]));
  return { data, maps, all, byKo, stamp: Object.values(data.sourceHashes).join('').slice(-32),
    find: (module, id) => maps[({words:'packs',review:'vocab',grammar:'grammar',pronunciation:'pronunciation',listening:'listening',scenarios:'scenarios',relations:'relations',extras:'extras'})[module]]?.get(id) };
}
export function parseRoute(search) {
  const params = new URLSearchParams(search);
  return {view:params.get('view') || 'home', m:params.get('m') || 'words', id:params.get('id') || '',
    item:params.get('item') || '', mode:params.get('mode') || '', stage:params.get('stage') || 'intro',
    lang:params.get('lang') === 'en' ? 'en' : 'de', level:params.get('level') || 'all',
    topic:params.get('topic') || '', q:params.get('q') || '', page:Math.max(0, Number(params.get('page')) || 0),
    at:Math.max(0, Number(params.get('at')) || 0), scale:params.get('scale') === '2' ? 2 : 1,
    state:params.get('state') || '', fresh:params.has('fresh')};
}
export function href(route, changes={}) {
  const next = {...route, ...changes};
  const params = new URLSearchParams();
  for (const key of ['view','m','id','item','mode','stage','lang','level','topic','q','page','at','scale','state']) {
    const value = next[key];
    if (value !== undefined && value !== null && value !== '' && value !== 0 && !(key === 'scale' && value === 1)) params.set(key,String(value));
  }
  return 'screen.html?' + params;
}
export function resolve(model, route) {
  if (['home','library'].includes(route.view)) return {valid:MODULES.includes(route.m)||route.m==='extras', kind:route.view};
  const record = model.find(route.m,route.id);
  if (!record) return {valid:false, reason:'missing_record'};
  if (route.m==='words' && route.item && !record.wordIds.includes(route.item)) return {valid:false,reason:'word_outside_pack'};
  if (route.m==='listening' && route.item && !record.questions.some(q=>q.id===route.item)) return {valid:false,reason:'missing_question'};
  if (route.m==='scenarios' && route.item && route.view==='practice' && !record.quests.some(q=>q.id===route.item)) return {valid:false,reason:'missing_quest'};
  if (route.m==='relations' && route.item) {
    const field = route.item.slice(record.id.length+1).split(':')[0];
    const index = Number(route.item.split(':').at(-1));
    if (!record[field]?.[index]) return {valid:false,reason:'missing_relation_node'};
  }
  return {valid:true, record};
}
const unique = values => [...new Set(values)];
export function ordered(values, seed='') {
  return [...values].map((value,index)=>({value,key:[...seed+String(index)].reduce((s,c)=>(s*31+c.charCodeAt(0))>>>0,7)})).sort((a,b)=>a.key-b.key).map(x=>x.value);
}
function choices(answer, pool, seed) {
  const other = ordered(unique(pool).filter(v=>v!==answer),seed).slice(0,3);
  return other.length===3 ? ordered([answer,...other],seed+'options') : [];
}
export function grammarQuestion(model, row, lang) {
  const text = row[lang==='de'?'example_german':'example_en'];
  const focus = row['quiz_focus_'+lang]?.trim();
  const ids = [row.id,...row.quiz_distractor_ids.split('|').filter(Boolean)];
  const options = ids.map(id=>model.maps.grammar.get(id));
  if (row.quiz_enabled!=='true' || !focus || !text || text.split(focus).length!==2 || unique(ids).length!==4 ||
      options.some(o=>!o || o.level!==row.level || o.quiz_enabled!=='true' || !o['quiz_focus_'+lang]?.trim())) return null;
  return {id:row.id,type:'choice',prompt:text,focus,answer:row.id,options:ordered(options,row.id).map(o=>({value:o.id,text:o.pattern,korean:true})),
    evidence:row.example_korean,explanation:row['explanation_'+lang], origin:row};
}
function relationQuestions(model, cluster, lang) {
  const fields = ['synonyms','antonyms','related','expressions'];
  const known = new Map();
  for (const c of model.data.relations) for (const field of fields) for (const node of c[field]) {
    if (!known.has(c.sourceKo)) known.set(c.sourceKo,new Set());
    if (!known.has(node.ko)) known.set(node.ko,new Set());
    known.get(c.sourceKo).add(node.ko); known.get(node.ko).add(c.sourceKo);
  }
  return fields.flatMap(field=>{
    const answer = cluster[field][0]; if (!answer) return [];
    const blocked = new Set([cluster.sourceKo,...(field==='related' ? known.get(cluster.sourceKo)||[] : cluster[field].map(n=>n.ko))]);
    const pool = model.data.relations.flatMap(c=>c[field].map(n=>n.ko)).filter(v=>!blocked.has(v));
    const fallback = model.data.relations.flatMap(c=>fields.flatMap(f=>c[f].map(n=>n.ko))).filter(v=>!blocked.has(v));
    const options = choices(answer.ko,[...pool,...fallback],cluster.id+field);
    return options.length ? [{id:cluster.id+':quiz:'+field,type:'choice',relationKind:field,
      prompt:field==='expressions'?meaning(answer,lang):cluster.sourceKo,answer:answer.ko,
      options:options.map(text=>({value:text,text,korean:true})),evidence:answer.ko,
      explanation:answer[lang==='de'?'nuanceDe':'nuanceEn']||meaning(answer,lang), origin:answer}] : [];
  });
}
export function practice(model, route) {
  const resolved = resolve(model,route); if (!resolved.valid) return {questions:[],invalid:true};
  const record = resolved.record, lang = route.lang;
  let questions = [];
  if (route.m==='words') {
    const ids = route.mode==='boss'?record.bossIds:record.normalIds;
    const pool = model.data.vocab.filter(v=>v.level===record.level).map(v=>meaning(v,lang));
    questions = ordered(ids,record.id+route.mode).map(id=>{
      const v = model.maps.vocab.get(id), answer = meaning(v,lang);
      return {id,type:'choice',prompt:v.korean,answer,options:choices(answer,pool,id).map(text=>({value:text,text})),
        audio:v.korean,evidence:v.korean,explanation:meaning(v,lang),origin:v};
    }).filter(q=>q.options.length===4);
  } else if (route.m==='grammar') questions = [grammarQuestion(model,record,lang)].filter(Boolean);
  else if (route.m==='listening') questions = record.questions.map(q=>({
    ...q,prompt:local(q.prompt,lang),explanation:local(q.explanation,lang),audio:q.audioKo,
    answer:q.type==='choice'?String(q.correctIndex):q.targetKo,
    options:q.type==='choice'?q.options.map((o,i)=>({value:String(i),text:local(o,lang),korean:lang==='ko'})):[],
    evidence:q.evidenceKo,origin:q }));
  else if (route.m==='scenarios') questions = record.quests.map(q=>{
    const d=q.data, type=['satzBauen'].includes(q.type)?'order':q.type==='diktat'?'typing':'choice';
    const prompt = q.type==='hoerverstehen'?'':d['prompt'+(lang==='de'?'De':'En')] || d.sentence || (d.prefix||'')+'___'+(d.suffix||'');
    return {id:q.id,type,sourceType:q.type,prompt,audio:d.audioKo||(['diktat','satzBauen'].includes(q.type)?d.targetKo:''),
      answer:type==='choice'?String(d.correctIndex):d.targetKo,
      options:type==='choice'?(d.options||[]).map((o,i)=>({value:String(i),text:typeof o==='string'?o:local(o,lang)||o.ko,korean:q.type!=='hoerverstehen'})):[],
      distractors:d.distractors||[],evidence:d.targetKo||d.audioKo||(typeof d.options?.[d.correctIndex]==='string'?d.options[d.correctIndex]:d.options?.[d.correctIndex]?.ko)||'',
      explanation:d['explanation'+(lang==='de'?'De':'En')]||'', origin:q};
  });
  else if (route.m==='relations') questions=relationQuestions(model,record,lang);
  return {questions,record,start:Math.max(0,questions.findIndex(q=>q.id===route.item))};
}
export function grade(question, answer) {
  return normalise(answer)===normalise(question.answer);
}
export function summary(questions, attempts) {
  const records = questions.map(q=>attempts[q.id]).filter(Boolean);
  return {total:questions.length,answered:records.length,unaided:records.filter(a=>a.firstCorrect&&!a.help).length,
    assisted:records.filter(a=>a.help).length,wrong:records.filter(a=>!a.firstCorrect).length};
}
