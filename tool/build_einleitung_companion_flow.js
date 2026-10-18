// Prepared 2026-10-18. Root executes; this reviewer does not write to Figma.
// File rVlcMLvngw07BYJ7nRT87C / page77:2, after material v8 on80:505 and80:537.
// Scope: 07 companion only. DO NOT modify any Spiele/Vorschau node.
// Official API: https://developers.figma.com/docs/plugins/working-with-variables/
// STRING -> variant property binding, SET_VARIABLE -> immediate same-frame state.
// Set only to an explicitly approved, existing app-entry frame. Null preserves
// the current design-only final CTA endpoint; this script never simulates save.
const START_DESTINATION_ID = null;
const NS = 'Einleitung UX07 / ';
const STATES = ['none', 'taego', 'joy'];
const page = await figma.getNodeByIdAsync('77:2');
if (!page || page.type !== 'PAGE') throw new Error('Missing page77:2');
await figma.setCurrentPageAsync(page);
const get = async id => {
  const n = await figma.getNodeByIdAsync(id);
  if (!n) throw new Error('Missing source ' + id);
  return n;
};
const [taegoSource, joySource, previous, previousContinue] = await Promise.all([
  get('80:505'), get('80:537'), get('80:480'), get('80:500'),
]);
const startDestination = START_DESTINATION_ID ? await get(START_DESTINATION_ID) : null;
const child = (root, name) => {
  const n = root.children.find(x => x.name === name);
  if (!n) throw new Error('Missing ' + name + ' in ' + root.id);
  return n;
};
const walk = n => [n, ...('children' in n ? n.children.flatMap(walk) : [])];
const near = (a, b) => Math.abs(a - b) < .02;
for (const source of [taegoSource, joySource]) {
  if (!near(source.width, 402) || !near(source.height, 934)) throw new Error('Expected402x934 source');
  for (const [name, x, y, w, h] of [
    ['Choose Taego', 7, 236, 195, 360], ['Choose Joy', 210, 236, 188, 360],
    ['Gye reading', 12, 605, 378, 156], ['Einleitung / Brass CTA / Reference v2', 16, 772, 370, 58],
  ]) {
    const n = child(source, name);
    if (![n.x-x,n.y-y,n.width-w,n.height-h].every(v=>Math.abs(v)<.02)) {
      throw new Error('Source v8 geometry changed: ' + name + ' in ' + source.id);
    }
  }
}
if (previousContinue.parent.id !== previous.id) throw new Error('Step06 continuation ownership changed');
const fontMap = new Map();
for (const source of [taegoSource, joySource]) {
  for (const n of walk(source).filter(x => x.type === 'TEXT')) {
    for (const run of n.getStyledTextSegments(['fontName'])) fontMap.set(JSON.stringify(run.fontName), run.fontName);
  }
}
for (const font of fontMap.values()) await figma.loadFontAsync(font);
const created = new Set(), changed = new Set(), removed = [];
const add = n => (walk(n).forEach(x=>created.add(x.id)), n);
const mark = n => (changed.add(n.id), n);
async function react(n, actions) {
  mark(n);
  await n.setReactionsAsync(actions.length ? [{trigger:{type:'ON_CLICK'},actions}] : []);
}
async function clearReactions(root) {
  for (const n of walk(root)) if ('reactions' in n && n.reactions.length) await react(n, []);
}
const collections = await figma.variables.getLocalVariableCollectionsAsync();
let collection = collections.find(c => c.name === NS + 'Prototype state');
const createdCollectionIds = [], createdVariableIds = [];
if (!collection) {
  collection = figma.variables.createVariableCollection(NS + 'Prototype state');
  createdCollectionIds.push(collection.id);
}
const vars = await figma.variables.getLocalVariablesAsync();
let selection = vars.find(v => v.variableCollectionId === collection.id && v.name === 'selectedCompanionId');
if (!selection) {
  selection = figma.variables.createVariable('selectedCompanionId', collection, 'STRING');
  selection.scopes = [];
  selection.setValueForMode(collection.defaultModeId, 'none');
  createdVariableIds.push(selection.id);
}
if (selection.resolvedType !== 'STRING') throw new Error('selectedCompanionId must be STRING');
const select = value => ({type:'SET_VARIABLE',variableId:selection.id,
  variableValue:{type:'STRING',resolvedType:'STRING',value}});
const navigate = target => ({type:'NODE',destinationId:target.id,navigation:'NAVIGATE',
  transition:null,resetScrollPosition:false,resetInteractiveComponents:false});
const startX = Math.max(0,...page.children.map(n=>n.x+n.width)) + 80;

// Only the card group changes variant. Header, portraits' geometry, Gye, footer
// and the frame itself never navigate, dissolve, slide or reset scroll on tap.
let cardsSet = page.children.find(n=>n.type==='COMPONENT_SET'&&n.name===NS+'Companion cards');
if (!cardsSet) {
  const variants = [];
  for (const state of STATES) {
    const variant = add(figma.createComponent());
    variant.name = 'Companion=' + state;
    variant.resize(402, 360); variant.fills=[]; variant.clipsContent=false;
    for (const companion of ['taego','joy']) {
      const name = companion === 'taego' ? 'Choose Taego' : 'Choose Joy';
      const source = companion === 'taego'
        ? (state === 'taego' ? taegoSource : joySource)
        : (state === 'joy' ? joySource : taegoSource);
      const original = child(source, name);
      const card = add(original.clone()); variant.appendChild(card);
      card.x=original.x; card.y=0;
      await clearReactions(card);
      await react(card,[select(companion)]);
    }
    variants.push(variant);
  }
  cardsSet=add(figma.combineAsVariants(variants,page));
  cardsSet.name=NS+'Companion cards';
  cardsSet.description='One local selection. Same-frame SET_VARIABLE only; fixed v8 portrait/card geometry. none is initial; reselect does not deselect.';
  cardsSet.x=startX;cardsSet.y=1200;
  cardsSet.children.forEach((v,i)=>{v.x=20+i*430;v.y=20;});
  cardsSet.resizeWithoutConstraints(1310,400);
}
let ctaSet=page.children.find(n=>n.type==='COMPONENT_SET'&&n.name===NS+'Companion CTA');
if (!ctaSet) {
  const variants=[];
  for (const state of STATES) {
    const variant=add(figma.createComponent());variant.name='Companion='+state;
    variant.resize(370,58);variant.fills=[];variant.clipsContent=false;
    const source=state==='joy'?joySource:taegoSource;
    const button=add(child(source,'Einleitung / Brass CTA / Reference v2').clone());
    variant.appendChild(button);button.x=0;button.y=0;
    await clearReactions(button);
    if(state==='none') {
      const label=button.findOne(n=>n.type==='TEXT'&&n.name==='Label');
      if(!label)throw new Error('Missing native CTA label');
      mark(label).characters='Auswahl bestätigen'; // existing app_de.arb
      button.opacity=.48;
    }
    if(state!=='none'&&startDestination)await react(button,[navigate(startDestination)]);
    variants.push(variant);
  }
  ctaSet=add(figma.combineAsVariants(variants,page));
  ctaSet.name=NS+'Companion CTA';
  ctaSet.description='Fixed370x58 CTA geometry. Same selectedCompanionId STRING as cards; native editable label. Empty selection disabled.';
  ctaSet.x=startX;ctaSet.y=1670;
  ctaSet.children.forEach((v,i)=>{v.x=20+i*400;v.y=45;});
  ctaSet.resizeWithoutConstraints(1220,145);
}
const cardsNone=cardsSet.children.find(n=>n.name==='Companion=none');
const ctaNone=ctaSet.children.find(n=>n.name==='Companion=none');
if(!cardsNone||!ctaNone||cardsSet.children.length!==3||ctaSet.children.length!==3) {
  throw new Error('Incomplete07 component sets; inspect before retry');
}
// Replay repairs only our own reaction wiring; it does not regenerate art.
for(const v of cardsSet.children)for(const companion of ['taego','joy']) {
  const card=child(v,companion==='taego'?'Choose Taego':'Choose Joy');
  await clearReactions(card);await react(card,[select(companion)]);
}
for(const v of ctaSet.children) {
  const button=v.children[0];await clearReactions(button);
  if(v.name!=='Companion=none'&&startDestination)await react(button,[navigate(startDestination)]);
}
let live=page.children.find(n=>n.name===NS+'07 companion / live');
if(!live) {
  live=add(taegoSource.clone());page.appendChild(live);
  live.name=NS+'07 companion / live';live.x=startX;live.y=100;
  const first=child(live,'Choose Taego'),second=child(live,'Choose Joy');
  const index=live.children.indexOf(first);
  removed.push(first.id,second.id);first.remove();second.remove();
  const cards=add(cardsNone.createInstance());live.insertChild(index,cards);
  cards.name='Companion state · fixed card group';cards.x=0;cards.y=236;
  const oldCta=child(live,'Einleitung / Brass CTA / Reference v2');
  const ctaIndex=live.children.indexOf(oldCta);removed.push(oldCta.id);oldCta.remove();
  const cta=add(ctaNone.createInstance());live.insertChild(ctaIndex,cta);
  cta.name='Companion state · fixed CTA';cta.x=16;cta.y=772;
}
const cards=child(live,'Companion state · fixed card group');
const cta=child(live,'Companion state · fixed CTA');
mark(cards).setProperties({Companion:figma.variables.createVariableAlias(selection)});
mark(cta).setProperties({Companion:figma.variables.createVariableAlias(selection)});
// Preserve Back caption's exact visual position; its old hit rectangle overlaps
// the CTA by7px. Separate the transparent48px target without moving the text.
await react(child(live,'Back'),[]);
let back=live.children.find(n=>n.name==='Back · separated48px target');
if(!back){back=add(figma.createFrame());live.appendChild(back);back.name='Back · separated48px target';}
back.x=140;back.y=834;back.resize(122,48);back.fills=[];back.strokes=[];
await react(back,[navigate(previous)]);
await react(previousContinue,[navigate(live)]);
// Keep the two v8 reference frames and all their visual pixels. Their old
// selection NAVIGATE hotspots are removed so reference inspection cannot jump.
for(const source of [taegoSource,joySource]) {
  for(const name of ['Choose Taego','Choose Joy'])await clearReactions(child(source,name));
}
// Hard guard: selections may only set our STRING. No full-frame transition.
for(const v of cardsSet.children)for(const n of walk(v))if('reactions'in n) {
  for(const r of n.reactions)for(const a of r.actions||[]) {
    if(a.type!=='SET_VARIABLE'||a.variableId!==selection.id)throw new Error('Unexpected selection action '+n.id);
  }
}
if(back.y<cta.y+cta.height)throw new Error('Back target overlaps CTA');
return {
  createdNodeIds:[...created],mutatedNodeIds:[...changed],removedClonedNodeIds:removed,
  createdVariableIds,createdCollectionIds,
  liveFrame:live.id,referenceFrames:[taegoSource.id,joySource.id],
  cardsSet:cardsSet.id,ctaSet:ctaSet.id,selectionVariable:selection.id,
  instances:{cards:cards.id,cta:cta.id},backTarget:back.id,
  entry06:{frame:previous.id,button:previousContinue.id},
  states:STATES,selectionBehavior:'SET_VARIABLE only; same frame; no transition or scroll reset',
  startDestination:startDestination?.id||null,
  warnings:startDestination?[]:['Final start CTA has no approved Figma app destination; native commit remains phase5. No saved state or completion is simulated.'],
  acceptance:[
    'Play none→Taego→Joy→Taego: frame URL unchanged, rest pixels fixed, exactly one supplied check.',
    'Repeated selection is stable. Both card and CTA instances resolve the same variable.',
    'Back→06→Continue retains the selection; no reset-on-entry action.',
    'Initial CTA is disabled. Selected CTA label is native editable and fits fixed370x58.',
    'Back caption stays put; its48px target is below CTA hit area.',
  ],
  untouched:'All Spiele/Vorschau nodes and original01 comparison frames.',
};
