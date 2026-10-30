// Lossless packaging of already approved artwork. No generation, resizing or cropping.
// Set HANGULSORI_NODE_MODULES to a node_modules directory containing sharp.
const fs=require('node:fs/promises'),path=require('node:path'),crypto=require('node:crypto');
const {createRequire}=require('node:module');
const req=process.env.HANGULSORI_NODE_MODULES?createRequire(path.resolve(process.env.HANGULSORI_NODE_MODULES,'entry.js')):require;
const sharp=req('sharp');
const root=path.resolve(__dirname,'../..'),source=path.join(root,'docs/hanok_r16');
const assets='assets/illustrations/ildu_r16/';
const sha=b=>crypto.createHash('sha256').update(b).digest('hex');
const read=async p=>JSON.parse(await fs.readFile(p,'utf8'));
const counts={'sarangchae':16,'changgo':8,'jungmunganchae':12,'araechae':12,'toilet-south':9,'anchae':14,'anchae-store':11,'toilet-north':9,'gokgan':11,'ansarang':14,'sadang':12};
const cache=new Map();
async function image(rel,expected){
  const p=path.resolve(source,rel);
  if(!p.startsWith(source+path.sep))throw Error('Source path escaped package');
  const input=await fs.readFile(p),sourceHash=sha(input);
  if(expected&&sourceHash!==expected)throw Error('Source hash changed: '+rel);
  if(cache.has(sourceHash))return cache.get(sourceHash);
  const raw=await sharp(input).ensureAlpha().raw().toBuffer({resolveWithObject:true});
  const webp=await sharp(input).webp({lossless:true,effort:6}).toBuffer();
  const decoded=await sharp(webp).ensureAlpha().raw().toBuffer({resolveWithObject:true});
  if(raw.info.width!==decoded.info.width||raw.info.height!==decoded.info.height||!raw.data.equals(decoded.data))throw Error('Lossless pixel check failed: '+rel);
  const hash=sha(webp),asset=assets+hash+'.webp';await fs.writeFile(path.join(root,asset),webp);
  const r={asset,sha256:hash,width:raw.info.width,height:raw.info.height,sourceImage:'docs/hanok_r16/'+rel,sourceSha256:sourceHash,pixelSha256:sha(raw.data),bytes:webp.length};cache.set(sourceHash,r);return r;
}
(async()=>{
  await fs.mkdir(path.join(root,assets),{recursive:true});
  const contract=await read(path.join(source,'APP_ASSET_CONTRACT.json'));
  const roofs=await read(path.join(source,'ROOF_VARIANT_POLICY.json'));
  if(!contract.artworkCanonical||contract.buildingCount!==11||contract.stageCount!==128||!roofs.standaloneReady)throw Error('Unapproved/incomplete R16 source');
  const byId=new Map(contract.buildings.map(b=>[b.catalogBuildingId,b]));
  const buildings=[];
  for(const [id,count]of Object.entries(counts)){
    const b=byId.get(id),variant=roofs.standaloneBuildings[b.key]??b;
    if(variant.stages.length!==count)throw Error('Stage count changed: '+id);
    const stages=[];
    for(const s of variant.stages){
      const original=b.stages.find(x=>x.processId===s.processId);
      if(!original||original.sequence!==s.sequence)throw Error('Process identity/order changed');
      stages.push({processId:s.processId,sequence:s.sequence,labelKo:s.label,roofVariant:roofs.standaloneBuildings[b.key]?'standalone':'original',...await image(s.reviewImage,s.sha256)});
    }
    buildings.push({id,sourceKey:b.key,nameKo:b.name,full:await image(variant.fullImage??b.fullImage,variant.fullImageSha256??b.fullImageSha256),stages});
    console.log(id+' '+stages.length+' stages');
  }
  const estate=await image('estate/complete.png');
  const result={schemaVersion:1,revision:'ildu-r16',artworkCanonical:true,presentationOnly:true,
    processPolicyIncluded:false,progressOrOwnershipMigrationIncluded:false,realtime3dIncluded:false,
    sourceContractSha256:sha(await fs.readFile(path.join(source,'APP_ASSET_CONTRACT.json'))),
    roofPolicySha256:sha(await fs.readFile(path.join(source,'ROOF_VARIANT_POLICY.json'))),
    encoding:'Lossless WebP; original canvas, RGBA pixels and source hashes verified',
    buildingCount:11,processCount:128,buildings,estate};
  await fs.writeFile(path.join(root,'assets/data/ildu_r16_art_v1.json'),JSON.stringify(result,null,2)+'\n');
  console.log(JSON.stringify({buildings:11,processes:128,uniqueImages:cache.size,bytes:[...cache.values()].reduce((a,b)=>a+b.bytes,0)}));
})().catch(e=>{console.error(e);process.exitCode=1;});
