"use strict";
const {createHash}=require('node:crypto');
const {ShareFailure}=require('./dancheong_share_contract');
function createDancheongShareAdapters({firestore,bucket,now=()=>Date.now()}){
 const owner=(uid,requestId)=>firestore.doc(`users/${uid}/dancheong_publications/${requestId}`);
 const marker=uid=>firestore.doc(`account_deletions/${uid}`);
 const index=id=>firestore.doc(`dancheong_public_index/${id}`);
 const repository={
  async reserve(p){return firestore.runTransaction(async tx=>{
   const ref=owner(p.uid,p.requestId);const rate=owner(p.uid,'_rate');
   const [deletion,existing,counter]=await Promise.all([tx.get(marker(p.uid)),tx.get(ref),tx.get(rate)]);
   if(deletion.exists){throw new ShareFailure('failed-precondition');}
   if(existing.exists){const row=existing.data();if(row.payloadDigest!==p.payloadDigest){throw new ShareFailure('already-exists');}return row;}
   const collision=await tx.get(index(p.shareId));if(collision.exists){throw new ShareFailure('aborted');}
   const time=now();const old=counter.data();const count=old && time-old.windowStart<60000?old.count:0;
   if(count>=5){throw new ShareFailure('resource-exhausted');}
   const row={...p,status:'pending',createdAt:new Date(time),cleanupRequired:true,cleanupClaim:false,
    imageObjectPath:`dancheong_public/${p.uid}/${p.shareId}/art.png`};
   tx.create(ref,row);tx.create(index(p.shareId),{uid:p.uid,requestId:p.requestId,
    ownerSubjectHash:createHash('sha256').update(p.uid).digest('hex')});
   tx.set(rate,{windowStart:count===0?time:old.windowStart,count:count+1});return row;
  });},
  async activate(p){return firestore.runTransaction(async tx=>{
   const ref=owner(p.uid,p.requestId);const [deletion,document]=await Promise.all([tx.get(marker(p.uid)),tx.get(ref)]);const row=document.data();
   if(deletion.exists || !row || !['pending','active'].includes(row.status) || row.cleanupClaim || row.payloadDigest!==p.payloadDigest || row.imageSha256!==p.imageSha256){throw new ShareFailure('failed-precondition');}
   tx.update(ref,{status:'active',cleanupRequired:false});return {...row,status:'active'};
  });},
  async own({uid,requestId}){return (await owner(uid,requestId).get()).data()??null;},
  async flagCleanup({uid,requestId}){return firestore.runTransaction(async tx=>{
   const ref=owner(uid,requestId);const [deletion,document]=await Promise.all([tx.get(marker(uid)),tx.get(ref)]);const row=document.data();
   if(row?.status==='active'&&!deletion.exists){return false;}
   if(row){tx.update(ref,{status:'revoked',cleanupRequired:true,cleanupClaim:true});}
   return true;
  });},
  async publicRecord(id){return firestore.runTransaction(async tx=>{
   const lookup=await tx.get(index(id));if(!lookup.exists){return null;}const {uid,requestId}=lookup.data();
   const [deletion,document]=await Promise.all([tx.get(marker(uid)),tx.get(owner(uid,requestId))]);const row=document.data();
   return !deletion.exists && row?.status==='active' && row.shareId===id?row:null;
  });},
  async revoke({uid,requestId}){return firestore.runTransaction(async tx=>{
   const ref=owner(uid,requestId);const doc=await tx.get(ref);if(!doc.exists){throw new ShareFailure('not-found');}
   const row=doc.data();tx.update(ref,{status:'revoked',cleanupRequired:true,cleanupClaim:true});return {...row,status:'revoked'};
  });},
 };
 async function cleanupFinalized(path){
  const match=/^dancheong_public\/([^/]+)\/([A-Za-z0-9_-]{32})\/art\.png$/.exec(path??'');
  if(!match){return;}
  const retain=await firestore.runTransaction(async tx=>{
   const lookup=await tx.get(index(match[2]));if(!lookup.exists || lookup.data().uid!==match[1]){return false;}
   const {uid,requestId}=lookup.data();const [deletion,record]=await Promise.all([tx.get(marker(uid)),tx.get(owner(uid,requestId))]);const row=record.data();
   return !deletion.exists && row && ['pending','active'].includes(row.status) && !row.cleanupClaim && row.imageObjectPath===path;
  });
  if(!retain){await objects.remove(path);}
 }
 const objects={
  async putOnce({path,bytes,sha256}){
   const file=bucket.file(path);
   try{await file.save(bytes,{resumable:false,contentType:'image/png',preconditionOpts:{ifGenerationMatch:0},metadata:{cacheControl:'private, no-store',metadata:{sha256}}});}
   catch(error){if(error.code!==412){throw error;}const [existing]=await file.download();if(createHash('sha256').update(existing).digest('hex')!==sha256){throw new ShareFailure('already-exists');}}
  },
  async read(path){const file=bucket.file(path);const [metadata]=await file.getMetadata();if(Number(metadata.size)>4*1024*1024){throw new ShareFailure('invalid-argument');}return (await file.download())[0];},
  async remove(path){await bucket.file(path).delete({ignoreNotFound:true});},
 };
 async function cleanup(){
  const groups=firestore.collectionGroup('dancheong_publications');
  const [pending,revoked]=await Promise.all([
   groups.where('status','==','pending').where('createdAt','<',new Date(now()-86400000)).limit(20).get(),
   groups.where('status','==','revoked').where('cleanupRequired','==',true).limit(20).get()]);
  for(const doc of [...pending.docs,...revoked.docs]){
   const row=await firestore.runTransaction(async tx=>{const current=await tx.get(doc.ref);const value=current.data();
    if(!value || value.status==='active'){return null;}tx.update(doc.ref,{status:'revoked',cleanupClaim:true,cleanupRequired:true});return value;});
   if(!row){continue;}
   try{await objects.remove(row.imageObjectPath);await doc.ref.update({cleanupRequired:false});}catch(_){/* Bounded next-hour retry. */}
  }
 }
 return {repository,objects,cleanup,cleanupFinalized};
}
module.exports={createDancheongShareAdapters};
