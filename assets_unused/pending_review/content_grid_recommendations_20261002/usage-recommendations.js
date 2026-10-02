(function (root) {
  'use strict';
  const DAY = 86400000;
  const RULES = Object.freeze({lookbackDays: 28, halfLifeDays: 7, retainedDays: 90, maxEvents: 1400, dedupeMs: 30000, visitsEvery: 3, visitGapMs: 1800000, exposureGapMs: DAY, itemGapMs: 7 * DAY, dailyCap: 3});
  const DEFAULTS = ['listening', 'scenarios', 'vocab_packs', 'grammar'];
  const DISCOVERY = ['hangul', 'grammar', 'smalltalk', 'word_web', 'chosung'];
  const dayKey = now => {
    const d = new Date(now);
    return `${d.getFullYear()}-${String(d.getMonth()+1).padStart(2,'0')}-${String(d.getDate()).padStart(2,'0')}`;
  };
  const fresh = () => ({version: 1, events: [], everUsed: [], visitCount: 0, lastVisitAt: 0, lastShownAt: 0, lastSuggested: {}, dismissedUntil: {}, slate: null, currentSuggestion: null});
  const allowed = catalog => catalog.filter(a => a.enabled !== false).map(a => a.id);
  function normalize(value, catalog, now) {
    const s = fresh(), ids = new Set(allowed(catalog));
    if (!value || value.version !== 1 || typeof value !== 'object') return s;
    const time = v => Number.isFinite(v) && v > 0 && v <= now + 1000 ? v : 0;
    s.events = (Array.isArray(value.events) ? value.events : []).filter(e => e && ids.has(e.id) && time(e.at) && e.at >= now - RULES.retainedDays * DAY).slice(-RULES.maxEvents).map(e => ({id:e.id, at:e.at}));
    s.everUsed = [...new Set([...(Array.isArray(value.everUsed) ? value.everUsed : []).filter(id => ids.has(id)), ...s.events.map(e => e.id)])];
    s.visitCount = Number.isSafeInteger(value.visitCount) && value.visitCount >= 0 ? value.visitCount : 0;
    s.lastVisitAt = time(value.lastVisitAt);
    s.lastShownAt = time(value.lastShownAt);
    for (const id of ids) {
      if (time(value.lastSuggested?.[id])) s.lastSuggested[id] = value.lastSuggested[id];
      if (Number.isFinite(value.dismissedUntil?.[id]) && value.dismissedUntil[id] > now && value.dismissedUntil[id] <= now + 7 * DAY) s.dismissedUntil[id] = value.dismissedUntil[id];
    }
    if (value.slate && typeof value.slate.day === 'string' && Array.isArray(value.slate.ids)) s.slate = {day:value.slate.day, ids:[...new Set(value.slate.ids.filter(id => ids.has(id)))].slice(0,4)};
    if (value.currentSuggestion && ids.has(value.currentSuggestion.id) && ['unseen','dormant'].includes(value.currentSuggestion.reason)) s.currentSuggestion = {id:value.currentSuggestion.id, reason:value.currentSuggestion.reason};
    return s;
  }
  function recordUse(value, id, catalog, now) {
    const s = normalize(value, catalog, now);
    if (!allowed(catalog).includes(id)) return s;
    const previous = [...s.events].reverse().find(e => e.id === id);
    if (previous && now - previous.at < RULES.dedupeMs) return s;
    s.events.push({id, at:now});
    s.events = s.events.slice(-RULES.maxEvents);
    if (!s.everUsed.includes(id)) s.everUsed.push(id);
    if (s.currentSuggestion?.id === id) s.currentSuggestion = null;
    // The current day's four positions stay fixed. Usage affects the next day.
    return s;
  }
  function rank(value, catalog, now) {
    const s = normalize(value, catalog, now), scores = new Map(), caps = new Map();
    const events = s.events.filter(e => e.at >= now - RULES.lookbackDays * DAY).sort((a,b) => b.at-a.at);
    for (const e of events) {
      const key = e.id + ':' + dayKey(e.at), n = caps.get(key) || 0;
      if (n >= RULES.dailyCap) continue;
      caps.set(key, n+1);
      scores.set(e.id, (scores.get(e.id) || 0) + Math.pow(.5, (now-e.at)/(RULES.halfLifeDays*DAY)));
    }
    const fallback = [...new Set([...DEFAULTS, ...allowed(catalog)])];
    return allowed(catalog).sort((a,b) => (scores.get(b)||0)-(scores.get(a)||0) || fallback.indexOf(a)-fallback.indexOf(b));
  }
  function visit(value, catalog, now) {
    const s = normalize(value, catalog, now);
    if (!s.lastVisitAt || now-s.lastVisitAt >= RULES.visitGapMs) {
      s.visitCount += 1;
      s.lastVisitAt = now;
      s.currentSuggestion = null;
    }
    return s;
  }
  function plan(value, catalog, now) {
    const s = normalize(value, catalog, now), count = Math.min(4,allowed(catalog).length);
    if (!s.slate || s.slate.day !== dayKey(now) || s.slate.ids.length !== count) s.slate = {day:dayKey(now), ids:rank(s,catalog,now).slice(0,count)};
    const blocked = id => s.slate.ids.includes(id) || (s.dismissedUntil[id]||0)>now;
    if (s.currentSuggestion && (blocked(s.currentSuggestion.id) || s.currentSuggestion.reason==='unseen' && s.everUsed.includes(s.currentSuggestion.id))) s.currentSuggestion = null;
    if (!s.currentSuggestion && s.visitCount >= RULES.visitsEvery && s.visitCount % RULES.visitsEvery === 0 && (!s.lastShownAt || now-s.lastShownAt >= RULES.exposureGapMs)) {
      const candidates = allowed(catalog).filter(id => !blocked(id) && (!s.lastSuggested[id] || now-s.lastSuggested[id] >= RULES.itemGapMs));
      const unseen = candidates.filter(id => !s.everUsed.includes(id));
      const ordered = [...new Set([...DISCOVERY, ...allowed(catalog)])];
      unseen.sort((a,b) => ordered.indexOf(a)-ordered.indexOf(b));
      const lastUse = id => Math.max(0,...s.events.filter(e => e.id===id).map(e => e.at));
      const dormant = candidates.filter(id => now-lastUse(id)>=14*DAY).sort((a,b)=>lastUse(a)-lastUse(b) || ordered.indexOf(a)-ordered.indexOf(b));
      if (unseen[0]) s.currentSuggestion={id:unseen[0],reason:'unseen'};
      else if (dormant[0]) s.currentSuggestion={id:dormant[0],reason:'dormant'};
    }
    return {state:s, ids:s.slate.ids, discovery:s.currentSuggestion};
  }
  function impression(value, id, catalog, now) {
    const s=normalize(value,catalog,now);
    if (s.currentSuggestion?.id!==id) return s;
    if (!s.lastSuggested[id] || now-s.lastSuggested[id]>=RULES.exposureGapMs) {
      s.lastShownAt=now;
      s.lastSuggested[id]=now;
    }
    return s;
  }
  function dismiss(value, id, catalog, now) {
    const s=impression(value,id,catalog,now);
    if (!allowed(catalog).includes(id)) return s;
    s.dismissedUntil[id]=now+RULES.itemGapMs;
    s.currentSuggestion=null;
    return s;
  }
  function store(storage, key, catalog, clock=Date.now) {
    let memory=fresh();
    try {memory=normalize(JSON.parse(storage?.getItem(key)||'null'),catalog,clock());} catch (_) {}
    const save=s=>{memory=s;try {storage?.setItem(key,JSON.stringify(s));} catch (_) {}return s;};
    return {read:()=>normalize(memory,catalog,clock()), visit:()=>save(visit(memory,catalog,clock())), record:id=>save(recordUse(memory,id,catalog,clock())), plan:()=>{const p=plan(memory,catalog,clock());save(p.state);return p;}, impression:id=>save(impression(memory,id,catalog,clock())), dismiss:id=>save(dismiss(memory,id,catalog,clock())), reset:()=>save(fresh())};
  }
  const api={RULES,DEFAULTS,dayKey,fresh,normalize,recordUse,rank,visit,plan,impression,dismiss,store};
  root.SoriUsage=api;
  if (typeof module!=='undefined' && module.exports) module.exports=api;
})(typeof globalThis!=='undefined'?globalThis:this);
