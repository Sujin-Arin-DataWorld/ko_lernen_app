const test=require('node:test');const assert=require('node:assert/strict');
const {initializeTestEnvironment}=require('@firebase/rules-unit-testing');
const {initializeApp,deleteApp}=require('firebase-admin/app');const {getFirestore}=require('firebase-admin/firestore');
const {createDancheongShareAdapters}=require('./dancheong_share_adapters');
let env,app,db;
test.before(async()=>{env=await initializeTestEnvironment({projectId:'demo-hangul-sori-dancheong'});app=initializeApp({projectId:'demo-hangul-sori-dancheong'},'dancheong-tests');db=getFirestore(app);});
test.beforeEach(async()=>env.clearFirestore());test.after(async()=>{await env.cleanup();await deleteApp(app);});
function harness(){const images=new Map();const bucket={file:path=>({async save(bytes){if(images.has(path)){throw Object.assign(new Error(),{code:412});}images.set(path,bytes);},async delete(){images.delete(path);},async download(){return [images.get(path)];},async getMetadata(){return [{size:images.get(path)?.length??0}];}})};
 return {...createDancheongShareAdapters({firestore:db,bucket,now:()=>1000000000}),images};}
const input=n=>({uid:'alice',requestId:`00000000-0000-4000-8000-${String(n).padStart(12,'0')}`,shareId:String(n).padStart(32,'A'),payloadDigest:'a'.repeat(64),imageSha256:'b'.repeat(64),manifest:{},artworkRevision:1});
test('real transactions stabilize concurrent requests and preserve rate-limit retries',async()=>{
 const h=harness();const p=input(1);const rows=await Promise.all(Array.from({length:8},()=>h.repository.reserve(p)));
 assert.equal(new Set(rows.map(r=>r.shareId)).size,1);
 assert.equal((await db.doc('users/alice/dancheong_publications/_rate').get()).data().count,1);
 await Promise.all([h.repository.activate(p),h.repository.activate(p)]);
 assert.equal((await h.repository.publicRecord(p.shareId)).status,'active');
 for(let n=2;n<=5;n++){await h.repository.reserve(input(n));}
 await assert.rejects(h.repository.reserve(input(6)),{code:'resource-exhausted'});
 await h.repository.reserve(p);await h.repository.revoke(p);
 await assert.rejects(h.repository.activate(p),{code:'failed-precondition'});assert.equal(await h.repository.publicRecord(p.shareId),null);
});
test('deletion markers fence reserve/activate/read and finalized late uploads are physically removed',async()=>{
 const h=harness();const p=input(1);const row=await h.repository.reserve(p);
 h.images.set(row.imageObjectPath,Buffer.from([1]));await h.cleanupFinalized(row.imageObjectPath);assert.equal(h.images.size,1);
 await db.doc('account_deletions/alice').set({status:'deleting'});
 await assert.rejects(h.repository.activate(p),{code:'failed-precondition'});
 await assert.rejects(h.repository.reserve(input(2)),{code:'failed-precondition'});
 assert.equal(await h.repository.publicRecord(p.shareId),null);
 await h.cleanupFinalized(row.imageObjectPath);assert.equal(h.images.size,0);
 await db.doc('dancheong_public_index/'+p.shareId).delete();
 h.images.set(row.imageObjectPath,Buffer.from([2]));await h.cleanupFinalized(row.imageObjectPath);assert.equal(h.images.size,0);
 const foreign='learning-art/v1/canonical.png';h.images.set(foreign,Buffer.from([3]));await h.cleanupFinalized(foreign);assert.equal(h.images.has(foreign),true);
});
test('revocation cleanup cannot delete active art and late finalize retries remain bounded to the private path',async()=>{
 const h=harness();const p=input(1);const row=await h.repository.reserve(p);await h.repository.activate(p);h.images.set(row.imageObjectPath,Buffer.from([1]));
 await h.cleanupFinalized(row.imageObjectPath);assert.equal(h.images.size,1);
 await h.repository.revoke(p);await h.cleanup();assert.equal(h.images.size,0);
 h.images.set(row.imageObjectPath,Buffer.from([2]));await h.cleanupFinalized(row.imageObjectPath);assert.equal(h.images.size,0);
});
test('activation cleanup claims fence pending writes and exclude committed active records',async()=>{
 const h=harness();const active=input(1);await h.repository.reserve(active);await h.repository.activate(active);
 assert.equal(await h.repository.flagCleanup(active),false);
 assert.equal((await h.repository.publicRecord(active.shareId)).status,'active');
 const pending=input(2);await h.repository.reserve(pending);
 assert.equal(await h.repository.flagCleanup(pending),true);
 await assert.rejects(h.repository.activate(pending),{code:'failed-precondition'});
});
