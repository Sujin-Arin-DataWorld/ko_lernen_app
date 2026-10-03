"use strict";
const {onCall,onRequest,HttpsError}=require('firebase-functions/v2/https');
const {onSchedule}=require('firebase-functions/v2/scheduler');
const {onObjectFinalized}=require('firebase-functions/v2/storage');
const {getFirestore}=require('firebase-admin/firestore');
const {getStorage}=require('firebase-admin/storage');
const {createDancheongShareAdapters}=require('./dancheong_share_adapters');
const {createDancheongShareRuntime}=require('./dancheong_share_runtime');
const bucketName='ko-lernen-app.firebasestorage.app';
const adapters=()=>createDancheongShareAdapters({firestore:getFirestore(),bucket:getStorage().bucket(bucketName)});
const runtime=()=>createDancheongShareRuntime(adapters());
const small={region:'europe-west3',timeoutSeconds:15,maxInstances:10,memory:'128MiB'};
function callable(method,options=small){return onCall({...options,enforceAppCheck:true},async request=>{
 try{return await runtime()[method](request);}catch(error){
  const allowed=['unauthenticated','invalid-argument','already-exists','not-found','failed-precondition','resource-exhausted','aborted'];
  throw new HttpsError(allowed.includes(error.code)?error.code:'internal','Dancheong operation could not be completed.');
 }
});}
function publicHandler(image){return onRequest(small,async(req,res)=>{
 res.set({'Cache-Control':'private, no-store, max-age=0','X-Content-Type-Options':'nosniff','X-Robots-Tag':'noindex, nofollow','Content-Security-Policy':"default-src 'none'"});
 if(!['GET','HEAD'].includes(req.method)){res.status(405).end();return;}
 try{
  const value=image?await runtime().getImage(req.query.shareId):await runtime().getPublic(req.query.shareId);
  if(!value){res.status(404).end();return;}
  res.type(image?'image/png':'application/json');
  if(req.method==='HEAD'){res.status(200).end();}else if(image){res.send(value);}else{res.json(value);}
 }catch(_){res.status(404).end();}
});}
module.exports={
 createDancheongShare:callable('create',{region:'europe-west3',timeoutSeconds:60,maxInstances:5,memory:'256MiB'}),
 getOwnDancheongShare:callable('own'),revokeDancheongShare:callable('revoke'),
 getDancheongShare:publicHandler(false),getDancheongShareImage:publicHandler(true),
 cleanupDancheongShares:onSchedule({...small,schedule:'every 60 minutes',timeoutSeconds:60,maxInstances:1},()=>adapters().cleanup()),
 cleanupLateDancheongImage:onObjectFinalized({bucket:bucketName,region:'europe-west3',timeoutSeconds:60,maxInstances:1,memory:'128MiB',retry:true},event=>adapters().cleanupFinalized(event.data.name)),
};
