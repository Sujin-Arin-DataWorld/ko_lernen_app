export type Border = 'brocadeFlow' | 'colorRibbon' | 'lotusScroll' | 'none';
export type Template = 'flower' | 'brocade' | 'letter';
export type PublicManifest = {
 version:1; border?:Border; template:Template; templateVersion:1; assetVersion:1;
 format:'portrait'|'story'; width:1080; height:1350|1920; motifSlugs:string[];
 koreanText:string; translation:string; translationLocale:'de'|'en'|null; signature:string;
};
export type PublicSnapshot = {shareId:string;artworkRevision:number;manifest:PublicManifest;imageSha256:string};
export const validShareId=(value:unknown):value is string=>typeof value==='string' && /^[A-Za-z0-9_-]{32}$/.test(value);
export const templateChoice=(value:unknown):Template=>['flower','brocade','letter'].includes(String(value))?value as Template:'flower';
export const languageChoice=(value:unknown):'de'|'en'=>value==='en'?'en':'de';
const motifs=new Set('lotus chrysanthemum plum bamboo cloud octagon mountain manja vine chilbo gwigap wave taegeuk peony changsal suryeon noemun mugunghwa moran munbangsau bok crane wadang yeopjeon soban'.split(' '));
const segmenter=new Intl.Segmenter('ko',{granularity:'grapheme'});
const text=(value:unknown,max:number)=>typeof value==='string' && [...segmenter.segment(value)].length<=max;
export function publicSnapshot(value:unknown):PublicSnapshot|null {
 if(!value || typeof value!=='object'){return null;}
 const v=value as PublicSnapshot;const m=v.manifest;
 if(!validShareId(v.shareId)||!Number.isInteger(v.artworkRevision)||v.artworkRevision<1||v.artworkRevision>1000000||!/^[a-f0-9]{64}$/.test(v.imageSha256)||!m){return null;}
 const keys=['version','template','templateVersion','assetVersion','format','width','height','motifSlugs','koreanText','translation','translationLocale','signature'];
 if(Object.keys(v).some(k=>!['shareId','artworkRevision','manifest','imageSha256'].includes(k))||keys.some(k=>!Object.hasOwn(m,k))||Object.keys(m).some(k=>!keys.includes(k)&&k!=='border')||(Object.hasOwn(m,'border')&&!['brocadeFlow','colorRibbon','lotusScroll','none'].includes(m.border!))){return null;}
 if(m.version!==1||m.templateVersion!==1||m.assetVersion!==1||!['flower','brocade','letter'].includes(m.template)||!['portrait','story'].includes(m.format)||m.width!==1080||m.height!==(m.format==='story'?1920:1350)||!Array.isArray(m.motifSlugs)||m.motifSlugs.length<1||m.motifSlugs.length>4||new Set(m.motifSlugs).size!==m.motifSlugs.length||m.motifSlugs.some(s=>!motifs.has(s))||!text(m.koreanText,80)||!text(m.translation,160)||!text(m.signature,40)||(m.translationLocale!==null&&!['de','en'].includes(m.translationLocale))){return null;}
 return {shareId:v.shareId,artworkRevision:v.artworkRevision,manifest:{...m,motifSlugs:[...m.motifSlugs]},imageSha256:v.imageSha256};
}
export function visitorDraft(snapshot:PublicSnapshot) {
 // A visitor carries only the template, never the owner's text or ownership.
 return {version:1,template:snapshot.manifest.template,koreanText:'',signature:''};
}
