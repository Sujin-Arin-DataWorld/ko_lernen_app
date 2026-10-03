'use client';
import {useEffect,useRef,useState} from 'react';
import type {Border,Template} from './public-contract';
import {parseVisitorDraft} from './visitor-contract';
import {renderVisitor} from './visitor-renderer';
import {STORE_LINKS} from '../store-links';
import './studio.css';
const storageKey='hs_dancheong_visitor_v1';
export function VisitorStudio({initialTemplate,language}:{initialTemplate:Template;language:'de'|'en'}){
 const de=language==='de';const canvas=useRef<HTMLCanvasElement>(null);
 const [template,setTemplate]=useState(initialTemplate);
 const [border,setBorder]=useState<Border>('brocadeFlow');const [renderedKey,setRenderedKey]=useState('');const [errorKey,setErrorKey]=useState('');
 const [motif,setMotif]=useState('lotus');const [text,setText]=useState('');const [signature,setSignature]=useState('');
 const [ready,setReady]=useState(false);const [answer,setAnswer]=useState<boolean|null>(null);
 const key=JSON.stringify([template,border,motif,text,signature]);const rendered=renderedKey===key;const error=errorKey===key;
 useEffect(()=>{
  let active=true;
  Promise.resolve().then(()=>{try{return parseVisitorDraft(localStorage.getItem(storageKey));}catch{return null;}}).then(draft=>{
   if(!active){return;}
   if(draft){setTemplate(draft.template);setText(draft.koreanText);setSignature(draft.signature);setBorder(draft.border);setMotif(draft.motif);}
   setReady(true);
  });return()=>{active=false;};
 },[]);
 useEffect(()=>{
  if(ready){try{localStorage.setItem(storageKey,JSON.stringify({version:1,template,border,motif,koreanText:text,signature}));}catch{/* In-memory work remains downloadable. */}}
 },[ready,template,border,motif,text,signature]);
 useEffect(()=>{
  let active=true;
  if(canvas.current){renderVisitor(canvas.current,{template,border,motif,text,signature},()=>active)
   .then(()=>{if(active){setRenderedKey(key);}}).catch(()=>{if(active){setErrorKey(key);}});}
  return ()=>{active=false;};
 },[template,border,motif,text,signature,key]);
 function download(){canvas.current?.toBlob(blob=>{if(!blob){setErrorKey(key);return;}const url=URL.createObjectURL(blob);const anchor=document.createElement('a');anchor.href=url;anchor.download='my-dancheong-artwork.png';anchor.click();setTimeout(()=>URL.revokeObjectURL(url),1000);},'image/png');}
 return <main className="dancheong-page" lang={language}>
  <a className="dancheong-wordmark" href={`/${language}`}>한글소리 · Hangul Sori</a>
  <h1>{de?'Gestalte dein erstes Dancheong-Kunstwerk':'Create your first Dancheong artwork'}</h1>
  <p>{de?'Zum Ausprobieren: zwei frei verfügbare Startmuster. In der App sammelst du durch Lernen weitere Muster. Dein Bild bleibt hier auf deinem Gerät.':'Try two freely available starter patterns. Collect more patterns by learning in the app. Your image stays on your device here.'}</p>
  <canvas className="dancheong-masterpiece" ref={canvas} width={1080} height={1350} aria-label={de?'Vorschau deines Kunstwerks':'Your artwork preview'}/>
  {error&&<p role="alert">{de?'Dein Bild konnte nicht erstellt werden. Kürze den Text oder lade die Seite erneut.':'Your image could not render. Shorten the text or reload the page.'}</p>}
  <label htmlFor="template">{de?'Komposition':'Composition'}</label>
  <select id="template" value={template} onChange={e=>setTemplate(e.target.value as Template)}>
   <option value="flower">{de?'Blütenkranz':'Flower wreath'}</option><option value="brocade">{de?'Seidenmuster':'Brocade pattern'}</option><option value="letter">{de?'Motiv & Hangul':'Motif & Hangul'}</option>
  </select>
  <label htmlFor="border">{de?'Rahmen':'Frame'}</label>
  <select id="border" value={border} onChange={e=>setBorder(e.target.value as Border)}>
   <option value="brocadeFlow">{de?'Fließendes Seidenmuster':'Flowing brocade'}</option><option value="colorRibbon">{de?'Farbbänder & Geometrie':'Color bands & geometry'}</option><option value="lotusScroll">{de?'Lotus & Ranken':'Lotus & scrolls'}</option><option value="none">{de?'Ohne Rahmen':'No frame'}</option>
  </select>
  <p>{de?'Startmuster':'Starter patterns'}</p>
  <div className="dancheong-palette">{['lotus','cloud'].map(slug=><button key={slug} aria-pressed={motif===slug} onClick={()=>setMotif(slug)}>
   <img src={`/dancheong/starter/${slug}.png`} alt=""/>{slug==='lotus'?(de?'Lotus':'Lotus'):(de?'Wolke':'Cloud')}</button>)}</div>
  <label htmlFor="korean-text">{de?'Koreanischer Text · optional (80 Zeichen)':'Korean text · optional (80 characters)'}</label>
  <input id="korean-text" value={text} maxLength={80} onChange={e=>setText(e.target.value)}/>
  <label htmlFor="signature">{de?'Dein Name · optional (40 Zeichen)':'Your name · optional (40 characters)'}</label>
  <input id="signature" value={signature} maxLength={40} onChange={e=>setSignature(e.target.value)}/>
  <button onClick={download} disabled={error||!rendered}>{de?'Kunstwerk als PNG speichern':'Save artwork as PNG'}</button>
  <section aria-labelledby="mini-practice"><h2 id="mini-practice">{de?'Dein erstes koreanisches Wort':'Your first Korean word'}</h2>
   <p>안녕 · annyeong</p><p>{de?'Ein informelles Hallo unter Freundinnen und Freunden. Was heißt 안녕?':'An informal hello between friends. What does 안녕 mean?'}</p>
   <button onClick={()=>{setAnswer(true);setText('안녕');}}>{de?'Hallo':'Hello'}</button>
   <button onClick={()=>setAnswer(false)}>{de?'Danke':'Thank you'}</button>
   {answer!==null&&<p role="status">{answer?(de?'Richtig! 안녕 passt zu deinem ersten Kunstwerk.':'Correct! 안녕 fits your first artwork.'):(de?'Versuch es erneut: 안녕 begrüßt einen Freund.':'Try again: 안녕 greets a friend.')}</p>}
  </section>
  <p>{de?'Lerne in der App weiter. Öffne danach Hanok → Dancheong-Atelier und wähle dieselbe Komposition. Dieses Probe-Werk vergibt keine Lernbelohnungen.':'Continue learning in the app. Then open Hanok → Dancheong Studio and choose the same composition. This trial artwork does not award learning rewards.'}</p>
  <a className="dancheong-primary" href={STORE_LINKS.android}>{de?'Hangul Sori für Android öffnen':'Open Hangul Sori for Android'}</a>
  <a className="dancheong-secondary" href={`/${language}#tester-access`}>{de?'iOS-Testzugang anfragen':'Request iOS test access'}</a>
 </main>;
}
