// Run via agent-browser eval -b with this file's UTF-8 source encoded as Base64.
(async () => {
  const findings=[];
  const assert=(condition,message)=>{if(!condition)throw Error(message);};
  const click=selector=>{const el=document.querySelector(selector);assert(el,`Missing ${selector}`);el.click();};
  const selected=()=>Number(document.querySelector('#scene').dataset.stage);
  const structure=HANOK_STRUCTURE.validate();assert(structure.status==='passed',JSON.stringify(structure.issues));
  click('[data-lang="ko"]');click('.brand');
  assert(Object.keys(HANOK_ARTWORKS).length===15,'All 15 intermediate artworks must be registered');
  if(document.querySelector('[data-art-view="art"]'))click('[data-art-view="art"]');
  assert(document.querySelector('#previous').disabled,'Stage 1 previous must be disabled');
  assert(document.querySelectorAll('#timeline [data-stage]').length===16,'Exactly 16 stages required');
  for(let n=1;n<=15;n++){
    assert(selected()===n,`Next flow skipped stage ${n}`);
    const candidate=document.querySelector('#scene > img[data-artwork-stage]');
    assert(candidate&&Number(candidate.dataset.artworkStage)===n,`Stage ${n} needs its matching artwork`);
    await candidate.decode();
    assert(candidate.naturalWidth===1536&&candidate.naturalHeight===1024,`Stage ${n} canvas changed`);
    assert(getComputedStyle(candidate).filter==='none'&&getComputedStyle(candidate).objectFit==='contain',`Stage ${n} must be unfiltered and uncropped`);
    const data=await(await fetch(candidate.currentSrc)).arrayBuffer();
    const digest=[...new Uint8Array(await crypto.subtle.digest('SHA-256',data))].map(x=>x.toString(16).padStart(2,'0')).join('');
    assert(digest===HANOK_ARTWORKS[n].sha256,`Stage ${n} bytes differ from registered artwork`);
    assert(!document.querySelector('#canonical-completion'),`Completion appeared early at ${n}`);
    click('#next');
  }
  assert(selected()===16,'Next flow did not finish at 16');
  const img=document.querySelector('#canonical-completion');await img.decode();
  assert(img.naturalWidth===1536&&img.naturalHeight===1024,'Canonical dimensions changed');
  assert(getComputedStyle(img).filter==='none'&&getComputedStyle(img).objectFit==='contain','Original must not be filtered or cropped');
  const bytes=await(await fetch(img.currentSrc)).arrayBuffer();
  const hash=[...new Uint8Array(await crypto.subtle.digest('SHA-256',bytes))].map(x=>x.toString(16).padStart(2,'0')).join('');
  assert(hash==='f917724120d4080d7c004b65dc51a9c336fcfbccdb9997e830de06ead1bcfc1a','Completed image is not the approved original');
  findings.push('All 16 sequential states reached; original appears only at stage 16 in the main scene.');
  findings.push('Every intermediate stage loads its own unfiltered 1536x1024 PNG with matching SHA-256.');
  click('#next');assert(selected()===1,'Completion action must restart, never create a stage 17');
  click('#timeline [data-stage="8"]');click('[data-art-view="diagram"]');assert(document.querySelector('#scene > svg'),'Structure view missing');click('[data-art-view="art"]');assert(document.querySelector('#scene > img[data-artwork-stage="8"]'),'Artwork view did not return');
  click('#compare-artwork');assert(document.querySelector('#detail-dialog').open,'Comparison did not open');
  const slider=document.querySelector('#art-overlay');slider.value='0';slider.dispatchEvent(new Event('input',{bubbles:true}));assert(document.querySelector('#comparison-master').style.opacity==='0','Overlay zero endpoint failed');slider.value='100';slider.dispatchEvent(new Event('input',{bubbles:true}));assert(document.querySelector('#comparison-master').style.opacity==='1','Overlay full endpoint failed');assert(document.querySelector('#comparison-master').src===img.src,'Overlay must use canonical image');click('#close-detail');
  click('#inspect');assert(document.querySelector('#detail-content img[data-artwork-stage="8"]'),'Artwork enlargement missing');click('#close-detail');
  findings.push('Artwork/sketch switching, original-image overlay endpoints and artwork enlargement work.');
  click('#timeline [data-stage="4"]');click('#detail-action');assert(document.querySelector('#detail-dialog').open,'Fitting dialog did not open');click('#demo-toggle');assert(document.querySelector('#detail-demo').classList.contains('joined'),'Fitting interaction failed');click('#close-detail');
  click('#timeline [data-stage="13"]');click('#detail-action');click('#demo-toggle');assert(document.querySelector('#detail-demo').classList.contains('heating'),'Ondol heat interaction failed');click('#demo-toggle');assert(!document.querySelector('#detail-demo').classList.contains('heating'),'Ondol heat toggle did not stop');click('#close-detail');
  findings.push('Post fitting and ondol heat toggle work in separate detail dialogs.');
  click('#overview');assert(document.querySelectorAll('.overview-card').length===16,'Overview needs 16 stages');assert(document.querySelector('.overview-card[data-stage="16"] img').src===img.src,'Overview completion must use same original');click('.overview-card[data-stage="11"]');assert(selected()===11&&!document.querySelector('#overview-dialog').open,'Overview stage selection failed');
  document.dispatchEvent(new KeyboardEvent('keydown',{key:'ArrowLeft',bubbles:true}));assert(selected()===10,'Keyboard previous failed');
  document.dispatchEvent(new KeyboardEvent('keydown',{key:'ArrowRight',bubbles:true}));assert(selected()===11,'Keyboard next failed');
  for(const lang of ['de','en','ko']){click(`[data-lang="${lang}"]`);assert(document.documentElement.lang===lang,'Language did not change');assert(selected()===11,'Language change moved the stage');}
  findings.push('Overview, keyboard navigation and Korean/English/German switching work.');
  click('#timeline [data-stage="15"]');click('#play');await new Promise(resolve=>setTimeout(resolve,2550));assert(selected()===16,'Playback did not reach 16');assert(document.querySelector('#play').getAttribute('aria-pressed')==='false','Playback did not stop at 16');
  findings.push('Playback stops at 16; completion cannot advance to stage 17.');
  return {status:'passed',stageCount:16,canonicalSha256:hash,bytes:bytes.byteLength,structure,findings};
})().then(result=>{window.__mockupQa=result;return result;}).catch(error=>{window.__mockupQa={status:'failed',error:String(error)};throw error;})
