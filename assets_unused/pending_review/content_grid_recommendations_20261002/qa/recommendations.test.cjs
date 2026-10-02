const {test}=require('node:test');
const assert=require('node:assert/strict');
const fs=require('node:fs');
const U=require('../usage-recommendations.js');
const catalog=JSON.parse(fs.readFileSync(require('node:path').join(__dirname,'../catalog-data.json'))).activities;
const now=Date.parse('2026-10-02T10:00:00Z'),DAY=86400000;
const history=events=>({...U.fresh(),events,everUsed:[...new Set(events.map(e=>e.id))]});
test('fresh user has exactly four clear default activities',()=>assert.deepEqual(U.plan(U.fresh(),catalog,now).ids,['listening','scenarios','vocab_packs','grammar']));
test('recent repeated practice beats an old favourite',()=>{
 const events=[...Array.from({length:15},(_,i)=>({id:'grammar',at:now-(20+i/10)*DAY})),{id:'srs',at:now-DAY},{id:'srs',at:now-2*DAY}];
 assert.equal(U.rank(history(events),catalog,now)[0],'srs');
});
test('same activity within 30 seconds is not counted twice',()=>{
 const s=U.recordUse(U.fresh(),'grammar',catalog,now);
 assert.equal(U.recordUse(s,'grammar',catalog,now+10000).events.length,1);
 assert.equal(U.recordUse(s,'grammar',catalog,now+31000).events.length,2);
});
test('many rapid launches in one day cannot outweigh regular practice',()=>{
 const events=[...Array.from({length:30},(_,i)=>({id:'grammar',at:now-i*60000})),...Array.from({length:5},(_,i)=>({id:'srs',at:now-i*DAY}))];
 assert.equal(U.rank(history(events),catalog,now)[0],'srs');
});
test('today positions freeze; tomorrow uses the newly popular category',()=>{
 let s=U.plan(U.fresh(),catalog,now).state;
 s=U.recordUse(s,'chosung',catalog,now);
 assert.deepEqual(U.plan(s,catalog,now+1000).ids,U.DEFAULTS);
 assert.equal(U.plan(s,catalog,now+DAY).ids[0],'chosung');
});
test('disabled activities leave the slate immediately',()=>{
 const s=U.plan(U.fresh(),catalog,now).state;
 const c=catalog.map(a=>({...a,enabled:a.id!=='grammar'}));
 const p=U.plan(s,c,now);
 assert.equal(p.ids.length,4);assert.ok(!p.ids.includes('grammar'));
});
test('malformed and unknown events are ignored',()=>{
 const s=U.normalize({version:1,events:[null,{id:'no-route',at:now},{id:'grammar',at:NaN},{id:'srs',at:now+DAY}],everUsed:['no-route'],visitCount:-10},catalog,now);
 assert.deepEqual(s.events,[]);assert.deepEqual(s.everUsed,[]);assert.equal(s.visitCount,0);
 assert.equal(U.recordUse(s,'no-route',catalog,now).events.length,0);
});
test('rendering and short reloads do not create visits',()=>{
 const a=U.visit(U.fresh(),catalog,now),b=U.visit(a,catalog,now+1000);
 assert.equal(b.visitCount,1);assert.equal(U.visit(b,catalog,now+1800000).visitCount,2);
});
test('discovery appears only on the third distinct visit',()=>{
 let s=U.visit(U.fresh(),catalog,now);
 assert.equal(U.plan(s,catalog,now).discovery,null);
 s=U.visit(s,catalog,now+3600000);assert.equal(U.plan(s,catalog,now+3600000).discovery,null);
 s=U.visit(s,catalog,now+7200000);const p=U.plan(s,catalog,now+7200000);
 assert.equal(p.discovery.id,'hangul');assert.equal(p.discovery.reason,'unseen');assert.equal(p.ids.length,4);
});
test('building a plan does not falsely record a visible impression',()=>{
 const s={...U.fresh(),visitCount:3,lastVisitAt:now};
 const p=U.plan(s,catalog,now);assert.equal(p.state.lastShownAt,0);
 const seen=U.impression(p.state,p.discovery.id,catalog,now);
 assert.equal(seen.lastShownAt,now);assert.equal(U.plan(seen,catalog,now).discovery.id,p.discovery.id);
});
test('discovery dismissal prevents immediate and next-day nagging',()=>{
 let s=U.plan({...U.fresh(),visitCount:3,lastVisitAt:now},catalog,now).state;
 s=U.dismiss(s,'hangul',catalog,now);
 assert.equal(U.plan(s,catalog,now).discovery,null);
 s={...U.visit(s,catalog,now+DAY),visitCount:6};
 assert.notEqual(U.plan(s,catalog,now+DAY).discovery?.id,'hangul');
});
test('global discovery exposure cooldown is 24 hours',()=>{
 let s=U.plan({...U.fresh(),visitCount:3,lastVisitAt:now},catalog,now).state;
 s=U.impression(s,'hangul',catalog,now);
 s={...U.visit(s,catalog,now+4*3600000),visitCount:6};
 assert.equal(U.plan(s,catalog,now+4*3600000).discovery,null);
});
test('trying a suggested activity clears that suggestion',()=>{
 let s=U.plan({...U.fresh(),visitCount:3,lastVisitAt:now},catalog,now).state;
 s=U.impression(s,'hangul',catalog,now);s=U.recordUse(s,'hangul',catalog,now);
 assert.equal(U.plan(s,catalog,now).discovery,null);
});
test('all-used content is never described as unseen',()=>{
 const recent=history(catalog.map(a=>({id:a.id,at:now-DAY})));
 assert.equal(U.plan({...recent,visitCount:3,lastVisitAt:now},catalog,now).discovery,null);
 const old=history(catalog.map(a=>({id:a.id,at:now-20*DAY})));
 assert.equal(U.plan({...old,visitCount:3,lastVisitAt:now},catalog,now).discovery.reason,'dormant');
});
test('ever-used state survives event retention and avoids false unseen claims',()=>{
 const s=U.normalize({...U.fresh(),events:[{id:'hangul',at:now-100*DAY}],everUsed:['hangul']},catalog,now);
 assert.equal(s.events.length,0);assert.deepEqual(s.everUsed,['hangul']);
});
test('storage works offline and survives denied or corrupted storage',()=>{
 const map=new Map(),storage={getItem:k=>map.get(k),setItem:(k,v)=>map.set(k,v)};
 const a=U.store(storage,'test',catalog,()=>now);a.record('srs');
 assert.equal(U.store(storage,'test',catalog,()=>now).read().events[0].id,'srs');
 map.set('broken','{');assert.deepEqual(U.store(storage,'broken',catalog,()=>now).plan().ids,U.DEFAULTS);
 const denied={getItem:()=>{throw Error('denied');},setItem:()=>{throw Error('denied');}};
 const b=U.store(denied,'test',catalog,()=>now);b.record('grammar');assert.equal(b.read().events.length,1);
});
test('at most four available entries, unique stable IDs',()=>{
 const c=catalog.slice(0,2),p=U.plan(U.fresh(),c,now);
 assert.equal(p.ids.length,2);assert.equal(new Set(p.ids).size,2);
});
