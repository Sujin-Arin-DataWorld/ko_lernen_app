/* A replaceable art boundary: unavailable art never blocks a paid build. */
'use strict';
let hanokAssetCatalog={status:'awaiting_new_canonical_assets',buildings:{}};
function approvedOwnedHanok(building,ownedStage){
 const row=hanokAssetCatalog.buildings?.[building]?.approvedStages?.[String(ownedStage)];
 if(!row||row.status!=='approved'||row.alphaVerified!==true||!row.file)return null;
 return row;
}
function ownedHanokVisual(m,bok=false){
 const asset=approvedOwnedHanok('sarangchae',m.owned);
 if(!asset){
   if(m.state==='built'||m.state==='house')return `<div class="hero asset-slot-complete" data-action="magic" role="button" tabindex="0" aria-label="${lang==='ko'?'건설 완료 연출 보기':lang==='de'?'Den fertigen Bauschritt feiern':'Celebrate the completed stage'}"><div class="completed-seal" aria-hidden="true"><span>${m.owned}</span><small>${lang==='ko'?'공정 완성':lang==='de'?'gebaut':'built'}</small></div><div class="ground-shadow" aria-hidden="true"></div></div>`;
   return secretHero(bok);
 }
 return `<div class="hero build-hero" data-action="magic" role="button" tabindex="0" aria-label="${lang==='ko'?'지금까지 지은 집 둘러보기':lang==='de'?'Das bereits gebaute Haus bewegen':'Move the already built house'}"><img src="${esc(asset.file)}" alt="${esc(asset.alt?.[lang]||t('myhouse'))}" class="house-image">${bok?'<img src="assets/bok.png" alt="" class="bok-burst" aria-hidden="true">':''}<div class="ground-shadow" aria-hidden="true"></div></div>`;
}
const hanokCatalogReady=fetch('hanok-assets.json').then(r=>r.ok?r.json():null).then(d=>{if(d)hanokAssetCatalog=d;}).catch(()=>{});
