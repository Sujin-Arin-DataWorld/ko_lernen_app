import type {Border,Template} from './public-contract';
type VisitorDraft={version:1;template:Template;border:Border;motif:'lotus'|'cloud';koreanText:string;signature:string};
const segmenter=new Intl.Segmenter('ko',{granularity:'grapheme'});
export function parseVisitorDraft(raw:string|null):VisitorDraft|null {
 try {
  const d=JSON.parse(raw??'null');
  if(!d||d.version!==1||Object.keys(d).some(k=>!['version','template','border','motif','koreanText','signature'].includes(k))||!['flower','brocade','letter'].includes(d.template)||typeof d.koreanText!=='string'||typeof d.signature!=='string'||[...segmenter.segment(d.koreanText)].length>80||[...segmenter.segment(d.signature)].length>40||(d.border!==undefined&&!['brocadeFlow','colorRibbon','lotusScroll','none'].includes(d.border))||(d.motif!==undefined&&!['lotus','cloud'].includes(d.motif))){return null;}
  return {version:1,template:d.template,border:d.border??'brocadeFlow',motif:d.motif??'lotus',koreanText:d.koreanText,signature:d.signature};
 } catch {return null;}
}
