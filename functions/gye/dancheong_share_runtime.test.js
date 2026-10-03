const test=require('node:test');const assert=require('node:assert/strict');
const {PNG}=require('pngjs');
const {createDancheongShareRuntime}=require('./dancheong_share_runtime');
const requestId='00000000-0000-4000-8000-000000000001';
function harness(){
 const rows=new Map();let deleted=false;let readGate;const images=new Map();
 const repository={
  async reserve(p){if(deleted){throw Object.assign(new Error(),{code:'failed-precondition'});}const key=p.uid+p.requestId;const old=rows.get(key);if(old){if(old.payloadDigest!==p.payloadDigest){throw Object.assign(new Error(),{code:'already-exists'});}return old;}
   const row={...p,status:'pending',imageObjectPath:`dancheong_public/${p.uid}/${p.shareId}/art.png`};rows.set(key,row);return row;},
  async activate(p){const row=rows.get(p.uid+p.requestId);if(deleted || row.status!=='pending'){throw Object.assign(new Error(),{code:'failed-precondition'});}row.status='active';return row;},
  async own(p){return rows.get(p.uid+p.requestId);},
  async publicRecord(id){return !deleted?[...rows.values()].find(r=>r.shareId===id && r.status==='active'):null;},
  async revoke(p){const row=rows.get(p.uid+p.requestId);row.status='revoked';return row;},
  async flagCleanup(p){const row=rows.get(p.uid+p.requestId);if(row?.status==='active'&&!deleted){return false;}if(row){row.status='revoked';row.cleanupClaim=true;}return true;},
 };
 const objects={async putOnce(p){images.set(p.path,p.bytes);},async read(path){await readGate;return images.get(path);},async remove(path){images.delete(path);}};
 const runtime=createDancheongShareRuntime({repository,objects,randomId:()=> 'A'.repeat(32)});
 const manifest={version:1,template:'flower',templateVersion:1,assetVersion:1,format:'portrait',width:1080,height:1350,motifSlugs:['lotus'],koreanText:'안녕',translation:'',translationLocale:null,signature:''};
 const req={auth:{uid:'a'},app:{appId:'test'},data:{requestId,artworkRevision:1,manifest,pngBase64:PNG.sync.write(new PNG({width:1080,height:1350})).toString('base64')}};
 return {runtime,req,rows,images,repository,setDeleted(){deleted=true;},gate(p){readGate=p;}};
}
test('auth/app check required, retry stable, conflicting payload rejected',async()=>{
 const h=harness();await assert.rejects(h.runtime.create({...h.req,auth:null}),{code:'unauthenticated'});
 await assert.rejects(h.runtime.create({...h.req,app:null}),{code:'failed-precondition'});
 const first=await h.runtime.create(h.req);assert.deepEqual(await h.runtime.create(h.req),first);assert.equal(h.rows.size,1);
 await assert.rejects(h.runtime.create({...h.req,data:{...h.req.data,artworkRevision:2}}),{code:'already-exists'});
 const publicJson=await h.runtime.getPublic(first.shareId);assert.equal('uid' in publicJson,false);assert.equal('imageObjectPath' in publicJson,false);
});
test('committed activation with a lost acknowledgment retains the active original image',async()=>{
 const h=harness();const activate=h.repository.activate;
 h.repository.activate=async p=>{await activate(p);throw new Error('Acknowledgment lost');};
 await assert.rejects(h.runtime.create(h.req),/Acknowledgment lost/);
 const retry=await h.runtime.create(h.req);
 assert.equal(retry.status,'active');assert.equal(h.images.size,1);
 assert.ok(await h.runtime.getImage(retry.shareId));
});
test('failed pending activation claims cleanup before removing bytes',async()=>{
 const h=harness();h.repository.activate=async()=>{throw new Error('Not committed');};
 await assert.rejects(h.runtime.create(h.req),/Not committed/);
 assert.equal(h.rows.get('a'+requestId).status,'revoked');assert.equal(h.images.size,0);
 await assert.rejects(h.runtime.create(h.req),{code:'failed-precondition'});
});
test('revocation during image await and account deletion hide the public image',async()=>{
 const h=harness();const p=await h.runtime.create(h.req);let release;h.gate(new Promise(resolve=>release=resolve));
 const loading=h.runtime.getImage(p.shareId);await new Promise(resolve=>setImmediate(resolve));
 await h.runtime.revoke({...h.req,data:{requestId}});release();assert.equal(await loading,null);
 await assert.rejects(h.runtime.create(h.req),{code:'failed-precondition'});
 const b=harness();const shared=await b.runtime.create(b.req);b.setDeleted();assert.equal(await b.runtime.getPublic(shared.shareId),null);
});
