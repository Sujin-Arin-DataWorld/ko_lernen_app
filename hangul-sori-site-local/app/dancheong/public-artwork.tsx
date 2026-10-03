'use client';
import {useEffect,useState} from 'react';
import {publicSnapshot,validShareId,type PublicSnapshot} from './public-contract';
import './studio.css';
export function PublicArtwork({shareId,language}:{shareId:string;language:'de'|'en'}){
 const [result,setResult]=useState<{id:string;art:PublicSnapshot|null}>({id:'',art:null});
 const art=result.id===shareId?result.art:null;const state=!validShareId(shareId)?'missing':result.id!==shareId?'loading':art?'ready':'missing';
 const de=language==='de';
 useEffect(()=>{
  if(!validShareId(shareId)){return;}
  const abort=new AbortController();
  fetch(`/api/dancheong/art/${shareId}`,{cache:'no-store',signal:abort.signal})
   .then(async response=>response.ok?publicSnapshot(await response.json()):null)
   .then(value=>{if(!abort.signal.aborted){setResult({id:shareId,art:value?.shareId===shareId?value:null});}})
   .catch(()=>{if(!abort.signal.aborted){setResult({id:shareId,art:null});}});
  return ()=>abort.abort();
 },[shareId]);
 return <main className="dancheong-page" lang={language}>
  <a className="dancheong-wordmark" href={`/${language}`}>한글소리 · Hangul Sori</a>
  <nav aria-label={de?"Sprache":"Language"}><a href="?lang=de" lang="de">Deutsch</a> · <a href="?lang=en" lang="en">English</a></nav>
  <h1>{de?'Ein Lernweg. Ein Kunstwerk.':'A learning journey. A work of art.'}</h1>
  {state==='loading'?<p role="status">{de?'Kunstwerk wird geladen …':'Loading artwork …'}</p>
   :!art?<><p role="status">{de?'Dieses Kunstwerk ist nicht mehr öffentlich verfügbar.':'This artwork is no longer publicly available.'}</p><a className="dancheong-primary" href={`/dancheong/try?lang=${language}`}>{de?'Dein erstes Kunstwerk gestalten':'Create your first artwork'}</a></>
   :<>
    {/* Owner strings are escaped React text, never markup or URLs. */}
    <img className="dancheong-masterpiece" src={`/art/${shareId}/image.png`} width={art.manifest.width} height={art.manifest.height} alt={de?'Dancheong-Kunstwerk':'Dancheong artwork'} onError={()=>{setResult({id:shareId,art:null});}}/>
    <p>{de?'Dancheong ist die koreanische Kunst farbig bemalter Holzarchitektur. Dieses persönliche Werk entstand aus Mustern, die beim Koreanischlernen gesammelt wurden.':'Dancheong is the Korean art of decorative painting on wooden architecture. This personal artwork uses patterns collected while learning Korean.'}</p>
    {art.manifest.signature && <p>{art.manifest.signature}</p>}
    <a className="dancheong-primary" href={`/dancheong/try?template=${art.manifest.template}&lang=${language}`}>{de?'Deine eigene Version gestalten':'Create your own version'}</a>
   </>}
  <a className="dancheong-secondary" href={`/${language}#tester-access`}>{de?'Koreanisch lernen mit Hangul Sori':'Learn Korean with Hangul Sori'}</a>
 </main>;
}
