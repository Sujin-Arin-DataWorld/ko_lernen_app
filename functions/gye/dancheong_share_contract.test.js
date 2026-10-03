const test=require('node:test');
const assert=require('node:assert/strict');
const {validatePublicManifest,validateShareId,validateSharePng,decodePng,canonicalPublicationDigest}=require('./dancheong_share_contract');
const {PNG}=require('pngjs');
const manifest={version:1,template:'flower',templateVersion:1,assetVersion:1,format:'portrait',width:1080,height:1350,motifSlugs:['lotus'],koreanText:'안녕',translation:'Grüße',translationLocale:'de',signature:'Jürgen'};
test('manifest whitelists fields, versions, dimensions and owned-material slugs',()=>{
 assert.deepEqual(validatePublicManifest(manifest),manifest);
 for(const bad of [{...manifest,ownerUid:'secret'},{...manifest,version:2},{...manifest,height:1},
  {...manifest,motifSlugs:[]},{...manifest,motifSlugs:['made-up']},{...manifest,koreanText:'가'.repeat(81)}]){
  assert.throws(()=>validatePublicManifest(bad),{code:'invalid-argument'});
 }
 assert.throws(()=>validateShareId('../users/private'),{code:'invalid-argument'});
});
test('bounded PNG validates full decode and CRC while preserving original bytes',()=>{
 const png=PNG.sync.write(new PNG({width:1080,height:1350}));
 assert.equal(validateSharePng(png,manifest).width,1080);
 assert.deepEqual(decodePng(png.toString('base64')),png);
 const broken=Buffer.from(png);broken[broken.length-1]^=1;
 assert.throws(()=>validateSharePng(broken,manifest),{code:'invalid-argument'});
 assert.throws(()=>decodePng('not-base64'),{code:'invalid-argument'});
 assert.throws(()=>validateSharePng(png.subarray(0,33),manifest),{code:'invalid-argument'});
 const digest=canonicalPublicationDigest({manifest,artworkRevision:1,imageSha256:'a'.repeat(64)});
 assert.equal(digest.length,64);
 assert.notEqual(digest,canonicalPublicationDigest({manifest,artworkRevision:2,imageSha256:'a'.repeat(64)}));
});
test('real Flutter flower/frame export validates unchanged and canonical digest matches the client JSON ordering',()=>{
 const fs=require('node:fs');const path=require('node:path');const crypto=require('node:crypto');
 const fixture=JSON.parse(fs.readFileSync(path.join(__dirname,'fixtures/dancheong/native-portrait.json'),'utf8'));
 const png=fs.readFileSync(path.join(__dirname,'fixtures/dancheong/native-portrait.png'));
 assert.equal(validateSharePng(png,fixture.manifest).sha256,fixture.imageSha256);
 assert.equal(canonicalPublicationDigest(fixture),crypto.createHash('sha256').update(JSON.stringify([fixture.manifest,fixture.artworkRevision,fixture.imageSha256])).digest('hex'));
 assert.throws(()=>validatePublicManifest({...fixture.manifest,border:'arbitrary-url'}),{code:'invalid-argument'});
});
