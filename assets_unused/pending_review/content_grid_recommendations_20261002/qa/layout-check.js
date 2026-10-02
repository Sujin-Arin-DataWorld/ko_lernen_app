(() => {
 const tiles=[...document.querySelectorAll('.content-tile')];
 return {
  width:innerWidth,locale:document.documentElement.lang,demo:new URLSearchParams(location.search).get('demo'),
  count:tiles.length,labels:tiles.map(e=>e.querySelector('strong').textContent),
  subtitles:tiles.reduce((n,e)=>n+e.querySelectorAll('small').length,0),
  images:tiles.every(e=>e.querySelector('img').complete&&e.querySelector('img').naturalWidth>0),
  minTap:Math.min(...tiles.map(e=>Math.min(e.getBoundingClientRect().width,e.getBoundingClientRect().height))),
  labelInside:tiles.every(e=>{const b=e.getBoundingClientRect(),l=e.querySelector('strong').getBoundingClientRect();return l.bottom<=b.bottom+1&&l.right<=b.right+1&&l.left>=b.left-1;}),
  overflow:document.documentElement.scrollWidth>innerWidth||document.querySelector('#screen').scrollWidth>document.querySelector('#screen').clientWidth,
  nav:document.querySelectorAll('#nav button').length,
  discovery:document.querySelector('[data-discovery]')?.dataset.discovery||null,
  font:document.fonts.check('17px Sori'),
  reduced:document.body.classList.contains('reduced'),
  transform:getComputedStyle(tiles[0]).transform,
  inventory:{learn:homeInventory.activities.filter(a=>a.tab==='learn').length,games:homeInventory.activities.filter(a=>a.tab==='games').length,packs:homeInventory.packs.length}
 };
})();
