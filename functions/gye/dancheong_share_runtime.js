"use strict";
const {randomBytes,createHash}=require('node:crypto');
const {ShareFailure,validateShareId,validateRequestId,validatePublicManifest,decodePng,validateSharePng,canonicalPublicationDigest}=require('./dancheong_share_contract');
function identity(request){
 if(!request?.auth?.uid){throw new ShareFailure('unauthenticated');}
 if(!request.app){throw new ShareFailure('failed-precondition');}
 return request.auth.uid;
}
function snapshot(row){return {shareId:row.shareId,artworkRevision:row.artworkRevision,manifest:row.manifest,imageSha256:row.imageSha256};}
function createDancheongShareRuntime({repository,objects,randomId=()=>randomBytes(24).toString('base64url')}){
 return {
  async create(request){
   const uid=identity(request);const data=request.data;
   if(!data || Object.keys(data).some(k=>!['requestId','artworkRevision','manifest','pngBase64'].includes(k))){throw new ShareFailure('invalid-argument');}
   const requestId=validateRequestId(data.requestId);const manifest=validatePublicManifest(data.manifest);
   const bytes=decodePng(data.pngBase64);const {sha256:imageSha256}=validateSharePng(bytes,manifest);
   const payloadDigest=canonicalPublicationDigest({manifest,artworkRevision:data.artworkRevision,imageSha256});
   const row=await repository.reserve({uid,requestId,manifest,artworkRevision:data.artworkRevision,imageSha256,payloadDigest,shareId:validateShareId(randomId())});
   if(row.status==='active'){return {shareId:row.shareId,status:row.status};}
   if(row.status!=='pending'||row.cleanupClaim){throw new ShareFailure('failed-precondition');}
   await objects.putOnce({path:row.imageObjectPath,bytes,sha256:imageSha256});
   try{const active=await repository.activate({uid,requestId,payloadDigest,imageSha256});return {shareId:active.shareId,status:active.status};}
   catch(error){
    // An activation may have committed even if its acknowledgment was lost.
    // A transaction fences future activation before physical removal. Unknown
    // outcomes retain the bytes for recovery or scheduled cleanup.
    let claimed=false;
    try{claimed=await repository.flagCleanup({uid,requestId});}catch(_){/* Preserve the original on an unknown status. */}
    if(claimed){try{await objects.remove(row.imageObjectPath);}catch(_){/* Durable claimed record is retried by scheduled cleanup. */}}
    throw error;
   }
  },
  async own(request){const uid=identity(request);const requestId=validateRequestId(request.data?.requestId);
   const row=await repository.own({uid,requestId});return row?{shareId:row.shareId,status:row.status}:null;},
  async revoke(request){const uid=identity(request);const requestId=validateRequestId(request.data?.requestId);
   const row=await repository.revoke({uid,requestId});try{await objects.remove(row.imageObjectPath);}catch(_){/* Scheduled physical retry; page is already inaccessible. */}
   return {shareId:row.shareId,status:'revoked'};},
  async getPublic(shareId){const row=await repository.publicRecord(validateShareId(shareId));return row?snapshot(row):null;},
  async getImage(shareId){
   const id=validateShareId(shareId);const before=await repository.publicRecord(id);if(!before){return null;}
   let bytes;try{bytes=await objects.read(before.imageObjectPath);}catch(_){return null;}
   const after=await repository.publicRecord(id);
   if(!after || after.payloadDigest!==before.payloadDigest || createHash('sha256').update(bytes).digest('hex')!==before.imageSha256){return null;}
   return bytes;
  },
 };
}
module.exports={createDancheongShareRuntime};
