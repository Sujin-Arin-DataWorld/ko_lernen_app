import test from 'node:test';import assert from 'node:assert/strict';import {build} from 'esbuild';
const bundled=await build({entryPoints:['worker/dancheong.ts'],bundle:true,platform:'node',format:'esm',write:false});
const {handleDancheongProxy}=await import('data:text/javascript;base64,'+Buffer.from(bundled.outputFiles[0].text).toString('base64'));
const id='A'.repeat(32);
const snapshot={shareId:id,artworkRevision:1,imageSha256:'a'.repeat(64),manifest:{version:1,template:'flower',templateVersion:1,assetVersion:1,format:'portrait',width:1080,height:1350,motifSlugs:['lotus'],koreanText:'<script>alert(1)</script>',translation:'Grüße',translationLocale:'de',signature:'Jürgen',border:'brocadeFlow'}};
test('proxy rejects invalid identifiers/methods before network, strips credentials and serves only whitelisted no-cache data',async()=>{
 const original=globalThis.fetch;let calls=0;let supplied=snapshot;
 try{
  globalThis.fetch=async(url,init)=>{calls++;assert.equal(new URL(url).origin,'https://europe-west3-ko-lernen-app.cloudfunctions.net');assert.equal(init.headers,undefined);assert.equal(init.redirect,'error');return Response.json(supplied);};
  assert.equal((await handleDancheongProxy(new Request('https://local/api/dancheong/art/invalid'))).status,404);
  assert.equal((await handleDancheongProxy(new Request(`https://local/api/dancheong/art/${id}`,{method:'POST'}))).status,405);assert.equal(calls,0);
  const response=await handleDancheongProxy(new Request(`https://local/api/dancheong/art/${id}`,{headers:{Authorization:'private-token'}}));
  assert.equal(response.status,200);assert.equal(response.headers.get('cache-control'),'private, no-store, max-age=0');assert.deepEqual(await response.json(),snapshot);
  supplied={...snapshot,ownerUid:'private'};assert.equal((await handleDancheongProxy(new Request(`https://local/api/dancheong/art/${id}`))).status,502);
  globalThis.fetch=async()=>new Response(null,{status:404});assert.equal((await handleDancheongProxy(new Request(`https://local/art/${id}/image.png`))).status,404);
  globalThis.fetch=async()=>new Response(new Uint8Array(4*1024*1024+1),{headers:{'content-type':'image/png'}});assert.equal((await handleDancheongProxy(new Request(`https://local/art/${id}/image.png`))).status,502);
 } finally{globalThis.fetch=original;}
});
