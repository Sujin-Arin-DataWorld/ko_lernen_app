"use strict";
const {createHash}=require('node:crypto');
const {PNG}=require('pngjs');
class ShareFailure extends Error {constructor(code){super(code);this.code=code;}}
const fail=()=>{throw new ShareFailure('invalid-argument');};
const motifSlugs=new Set('lotus chrysanthemum plum bamboo cloud octagon mountain manja vine chilbo gwigap wave taegeuk peony changsal suryeon noemun mugunghwa moran munbangsau bok crane wadang yeopjeon soban'.split(' '));
const keys=['version','template','templateVersion','assetVersion','format','width','height','motifSlugs','koreanText','translation','translationLocale','signature'];
const segmenter=new Intl.Segmenter('ko',{granularity:'grapheme'});
function text(value,max){if(typeof value!=='string' || [...segmenter.segment(value)].length>max || Buffer.byteLength(value)>max*32){fail();}return value;}
function validateShareId(value){if(typeof value!=='string'|| !/^[A-Za-z0-9_-]{32}$/.test(value)){fail();}return value;}
function validateRequestId(value){if(typeof value!=='string'|| !/^[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}$/i.test(value)){fail();}return value.toLowerCase();}
function validatePublicManifest(value){
 if(!value || Array.isArray(value) || keys.some(k=>!Object.hasOwn(value,k)) || Object.keys(value).some(k=>!keys.includes(k)&&k!=='border')){fail();}
 if(value.version!==1||value.templateVersion!==1||value.assetVersion!==1||!['flower','brocade','letter'].includes(value.template)||!['portrait','story'].includes(value.format)||value.width!==1080||value.height!==(value.format==='story'?1920:1350)){fail();}
 if(!Array.isArray(value.motifSlugs)||value.motifSlugs.length<1||value.motifSlugs.length>4||new Set(value.motifSlugs).size!==value.motifSlugs.length||value.motifSlugs.some(s=>!motifSlugs.has(s))){fail();}
 if(value.translationLocale!==null && !['de','en'].includes(value.translationLocale)){fail();}
 if(Object.hasOwn(value,'border')&&!['brocadeFlow','colorRibbon','lotusScroll','none'].includes(value.border)){fail();}
 text(value.koreanText,80);text(value.translation,160);text(value.signature,40);
 return Object.freeze(Object.fromEntries([...keys,...(Object.hasOwn(value,'border')?['border']:[])].map(k=>[k,k==='motifSlugs'?Object.freeze([...value[k]]):value[k]])));
}
function decodePng(value){
 if(typeof value!=='string'||value.length===0||value.length>Math.ceil(4*1024*1024/3)*4||!/^(?:[A-Za-z0-9+/]{4})*(?:[A-Za-z0-9+/]{2}==|[A-Za-z0-9+/]{3}=)?$/.test(value)){fail();}
 const bytes=Buffer.from(value,'base64');if(bytes.toString('base64')!==value){fail();}return bytes;
}
function validateSharePng(bytes,manifest){
 if(!Buffer.isBuffer(bytes)||bytes.length<45||bytes.length>4*1024*1024||!bytes.subarray(0,8).equals(Buffer.from([137,80,78,71,13,10,26,10]))){fail();}
 if(bytes.readUInt32BE(8)!==13 || bytes.toString('ascii',12,16)!=='IHDR' || bytes.readUInt32BE(16)!==manifest.width || bytes.readUInt32BE(20)!==manifest.height){fail();}
 // Canvas export contract: 8-bit RGB/RGBA, noninterlaced. Preflight every
 // chunk before decoder allocation; no APNG, compressed profiles or metadata.
 if(bytes[24]!==8 || ![2,6].includes(bytes[25]) || bytes[26]!==0 || bytes[27]!==0 || bytes[28]!==0){fail();}
 let offset=8,ended=false,idat=false;const metadata=new Set();
 while(offset<bytes.length){
  if(offset+12>bytes.length){fail();}const length=bytes.readUInt32BE(offset);const type=bytes.toString('ascii',offset+4,offset+8);
  if(length>4*1024*1024 || offset+length+12>bytes.length || !['IHDR','IDAT','IEND','sRGB','gAMA','sBIT'].includes(type)){fail();}
  if(['sRGB','gAMA','sBIT'].includes(type)){
   if(idat||metadata.has(type)){fail();}metadata.add(type);
   if(type==='sRGB'&&(length!==1||bytes[offset+8]>3)){fail();}
   if(type==='gAMA'&&(length!==4||bytes.readUInt32BE(offset+8)===0)){fail();}
   if(type==='sBIT'&&(length!==(bytes[25]===6?4:3)||bytes.subarray(offset+8,offset+8+length).some(value=>value!==8))){fail();}
  }
  if(type==='IHDR' && offset!==8){fail();}if(type==='IDAT'){idat=true;}if(type==='IEND'){if(length!==0 || offset+12!==bytes.length){fail();}ended=true;}
  offset+=length+12;
 }
 if(!idat||!ended){fail();}
 try{const decoded=PNG.sync.read(bytes,{checkCRC:true});if(decoded.width!==manifest.width || decoded.height!==manifest.height || decoded.data.length!==manifest.width*manifest.height*4){fail();}}
 catch(_){fail();}
 return {width:manifest.width,height:manifest.height,sha256:createHash('sha256').update(bytes).digest('hex')};
}
function canonicalPublicationDigest({manifest,artworkRevision,imageSha256}){
 if(!Number.isSafeInteger(artworkRevision)||artworkRevision<1||artworkRevision>1000000||!/^[a-f0-9]{64}$/.test(imageSha256)){fail();}
 return createHash('sha256').update(JSON.stringify([validatePublicManifest(manifest),artworkRevision,imageSha256])).digest('hex');
}
module.exports={ShareFailure,validateShareId,validateRequestId,validatePublicManifest,decodePng,validateSharePng,canonicalPublicationDigest};
