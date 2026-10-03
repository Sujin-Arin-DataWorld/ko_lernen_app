import test from 'node:test';import assert from 'node:assert/strict';
import {publicSnapshot,visitorDraft,validShareId,languageChoice} from '../app/dancheong/public-contract.ts';
const snapshot={shareId:'A'.repeat(32),artworkRevision:1,imageSha256:'a'.repeat(64),manifest:{version:1,template:'letter',templateVersion:1,assetVersion:1,format:'portrait',width:1080,height:1350,motifSlugs:['lotus'],koreanText:'내 비밀 이름',translation:'Grüße',translationLocale:'de',signature:'Jürgen'}};
test('visitor carries composition choice without copying owner text or materials',()=>{
 assert.deepEqual(visitorDraft(publicSnapshot(snapshot)),{version:1,template:'letter',koreanText:'',signature:''});
 assert.equal(validShareId('../secret'),false);assert.equal(languageChoice('ko'),'de');
 assert.equal(publicSnapshot({...snapshot,ownerUid:'private'}),null);
 assert.equal(publicSnapshot({...snapshot,manifest:{...snapshot.manifest,motifSlugs:['fake']}}),null);
});
