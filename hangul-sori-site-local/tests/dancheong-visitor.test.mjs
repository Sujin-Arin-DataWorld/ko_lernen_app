import test from 'node:test';import assert from 'node:assert/strict';
import {parseVisitorDraft} from '../app/dancheong/visitor-contract.ts';
import {publicSnapshot,visitorDraft} from '../app/dancheong/public-contract.ts';
test('visitor save contains only local choices, rejects owner fields and cannot mutate the owner snapshot',()=>{
 const manifest={version:1,template:'flower',templateVersion:1,assetVersion:1,format:'portrait',width:1080,height:1350,motifSlugs:['lotus'],koreanText:'Private Hangul',translation:'',translationLocale:null,signature:'Private Name',border:'brocadeFlow'};
 const owner=publicSnapshot({shareId:'A'.repeat(32),artworkRevision:1,manifest,imageSha256:'a'.repeat(64)});
 const a=visitorDraft(owner),b=visitorDraft(owner);a.koreanText='안녕';assert.equal(b.koreanText,'');assert.equal(owner.manifest.koreanText,'Private Hangul');assert.equal('motifSlugs' in a,false);
 const raw=JSON.stringify({...a,border:'brocadeFlow',motif:'cloud'});assert.equal(parseVisitorDraft(raw).motif,'cloud');
 assert.equal(parseVisitorDraft(JSON.stringify({...a,ownerUid:'alice'})),null);assert.equal(parseVisitorDraft(JSON.stringify({...a,koreanText:'가'.repeat(81)})),null);assert.equal(parseVisitorDraft('invalid'),null);
});
