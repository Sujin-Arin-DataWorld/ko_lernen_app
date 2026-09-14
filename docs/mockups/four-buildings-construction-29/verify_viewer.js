(async () => {
  const byId = id => document.getElementById(id);
  const base = new URL('../../../assets_unused/pending_review/personal_hanok_v3/four_buildings_construction_29deg_v1/', location.href);
  const catalog = await (await fetch(new URL('construction_catalog.json', base), {cache:'no-store'})).json();
  const rows = [], controls = [];
  for (const b of catalog.buildings) {
    document.querySelector('#buildings button[data-id="'+b.id+'"]').click();
    const buttons = [...byId('timeline').querySelectorAll('button')];
    controls.push({check:b.id+' timeline count',pass:buttons.length===b.steps.length});
    for (const [i,s] of b.steps.entries()) {
      buttons[i].click();
      const im=byId('stage-image');
      await im.decode();
      rows.push({building:b.id,stage:i+1,file:s.file,pass:im.naturalWidth===1536&&im.naturalHeight===1024&&im.src===new URL(s.file,base).href&&byId('download').href===im.src});
    }
    controls.push({check:b.id+' final next disabled',pass:byId('next').disabled});
    buttons[0].click(); await byId('stage-image').decode();
    controls.push({check:b.id+' initial previous disabled',pass:byId('previous').disabled});
    if(byId('overview').hidden) byId('overview-toggle').click();
    controls.push({check:b.id+' overview count',pass:byId('overview').querySelectorAll('img').length===b.steps.length&&!byId('overview').hidden});
    byId('overview-toggle').click();
  }
  document.querySelector('#buildings button[data-id="anchae"]').click();
  byId('timeline').querySelectorAll('button')[11].click();
  await byId('stage-image').decode();
  const ko=byId('sentence-ko').textContent;
  const lang=byId('language');
  lang.value='en'; lang.dispatchEvent(new Event('change',{bubbles:true}));
  const en=byId('sentence-translation').textContent;
  const enNext=byId('next').textContent;
  controls.push({check:'English navigation and description',pass:enNext==='Next stage →'&&byId('building-role').textContent==='Kitchen · rooms · main hall'});
  lang.value='de'; lang.dispatchEvent(new Event('change',{bubbles:true}));
  controls.push({check:'Korean retained across English/German',pass:ko===byId('sentence-ko').textContent&&en!==byId('sentence-translation').textContent&&!!en&&!!byId('sentence-translation').textContent});
  controls.push({check:'German navigation and description',pass:byId('next').textContent==='Nächster Bauschritt →'&&byId('building-role').textContent==='Küche · Zimmer · Haupthalle'});
  byId('overlay').value=45; byId('overlay').dispatchEvent(new Event('input',{bubbles:true}));
  controls.push({check:'completion overlay opacity',pass:byId('complete-image').style.opacity==='0.45'&&byId('opacity').textContent==='45%'});
  byId('overlay').value=0; byId('overlay').dispatchEvent(new Event('input',{bubbles:true}));
  byId('enlarge').click(); await byId('zoom-image').decode();
  controls.push({check:'full image dialog',pass:byId('zoom').open&&byId('zoom-image').naturalWidth===1536});
  byId('close-zoom').click();
  controls.push({check:'dialog closes',pass:!byId('zoom').open});
  byId('next').click(); await byId('stage-image').decode();
  controls.push({check:'next step',pass:new URL(location).searchParams.get('stage')==='13'});
  byId('previous').click();
  controls.push({check:'previous step',pass:new URL(location).searchParams.get('stage')==='12'});
  byId('play').click();
  await new Promise(resolve=>setTimeout(resolve,3400));
  controls.push({check:'autoplay advances',pass:new URL(location).searchParams.get('stage')==='13'});
  byId('play').click();
  controls.push({check:'autoplay stops',pass:byId('play').getAttribute('aria-pressed')==='false'});
  document.querySelector('#buildings button[data-id="jungmunganchae"]').click();
  byId('timeline').querySelectorAll('button')[4].click(); await byId('stage-image').decode();
  controls.push({check:'no page horizontal overflow',pass:document.documentElement.scrollWidth<=innerWidth});
  return {schemaVersion:1,viewport:{width:innerWidth,height:innerHeight},imageChecks:rows.length,imagePass:rows.filter(r=>r.pass).length,controlChecks:controls.length,controlPass:controls.filter(r=>r.pass).length,rows,controls};
})()
