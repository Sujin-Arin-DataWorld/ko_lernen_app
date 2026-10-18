// Prepared 2026-10-18; UX reviewer has NOT executed this in Figma.
// Target rVlcMLvngw07BYJ7nRT87C, page77:2. Load figma-use and figma-generate-library.
// Root fills these after medal/material review. Missing hashes fail BEFORE mutations.
const MEDAL_HASHES = {
  Beginner: 'a8994975a7d1572b904ce95226b3f3afad8777b5',
  A1: '606701e38f606e537475ffbc3cc2f94e6c7b3bd1',
  A2: '4817b4480ee9edbbe66a86d3dfdf9486f93d0578',
  B1: 'eaba0fc4a4b9d57c95c1e31a3746b60f867ce969',
  B2: '1b532a878c8cb6889fb4236a7b327d376c4961f4',
  C1: 'c046fb4144a1b160614615ef0a87b3af1e4cefb9',
  C2: 'ffe42b538175619b73480659d891da864fda538c',
};
// Official behavior verified 2026-10-18:
// https://developers.figma.com/docs/plugins/api/Action/
// SWAP replaces the top overlay; CLOSE dismisses it; NAVIGATE closes all overlays.
// https://developers.figma.com/docs/plugins/working-with-variables/
// A STRING variable can bind to an instance's variant property via setProperties.
// Overlay placement/background properties are readonly. Full-viewport shells
// contain only a dim rectangle and one sheet, so no duplicated backdrop is needed.
const LEVELS = ['Beginner', 'A1', 'A2', 'B1', 'B2', 'C1', 'C2'];
const INTERESTS = ['lifeTravel', 'peopleCulture', 'studyWork', 'kContent'];
const HINTS = {A1:'Anfänger', A2:'Du kennst die Grundlagen.', B1:'Mittelstufe',
  B2:'Fortgeschritten', C1:'Kompetent', C2:'Expertenniveau'}; // current app_de.arb
for (const level of LEVELS) {
  if (!/^[0-9a-f]{40}$/i.test(MEDAL_HASHES[level] || '')) {
    throw new Error('Fill reviewed MEDAL_HASHES.' + level + ' before running.');
  }
}
const page = await figma.getNodeByIdAsync('77:2');
if (!page || page.type !== 'PAGE') throw new Error('Missing page77:2.');
await figma.setCurrentPageAsync(page);
const get = async id => {
  const node = await figma.getNodeByIdAsync(id);
  if (!node) throw new Error('Missing source node ' + id);
  return node;
};
const [sourceA2, sourceBeginner, sourceSheet, sourceModal] = await Promise.all([
  get('80:336'), get('116:328'), get('80:611'), get('80:569'),
]);
const child = (parent, name) => {
  const node = parent.children.find(n => n.name === name);
  if (!node) throw new Error('Missing ' + name + ' in ' + parent.id);
  return node;
};
const walk = n => [n, ...('children' in n ? n.children.flatMap(walk) : [])];
const created = new Set(), changed = new Set(), removed = [];
const add = n => (walk(n).forEach(x => created.add(x.id)), n);
const mark = n => (changed.add(n.id), n);
const fontMap = new Map();
for (const root of [sourceA2, sourceBeginner, sourceSheet]) {
  for (const node of walk(root).filter(n => n.type === 'TEXT')) {
    for (const run of node.getStyledTextSegments(['fontName'])) fontMap.set(JSON.stringify(run.fontName), run.fontName);
  }
}
for (const font of fontMap.values()) await figma.loadFontAsync(font);
const NS = 'Einleitung UX7 / ';
const startX = Math.max(0, ...page.children.map(n => n.x + n.width)) + 80;
const copy = value => JSON.parse(JSON.stringify(value));
const sourcePaper = child(sourceA2, 'Setup paper');
const sourceCards = sourcePaper.children.filter(n => n.type === 'FRAME' && n.name.startsWith('Interest '));
if (sourceCards.length !== 4) throw new Error('Expected exactly four source interest cards.');
const sourceSelected = child(sourceSheet, 'Level A2');
const sourceUnselected = child(sourceSheet, 'Level A1');
const sourceCheck = child(sourceSelected, 'Approved check — original user asset');
const sourceInset = child(sourceSelected, 'Selected gold inset');
const sourceDim = child(sourceModal, 'Modal dim');

async function react(node, actions, trigger = {type:'ON_CLICK'}) {
  mark(node);
  await node.setReactionsAsync(actions.length ? [{trigger, actions}] : []);
}
const nodeAction = (target, navigation) => ({type:'NODE', destinationId:target.id,
  navigation, transition:null, resetScrollPosition:false, resetInteractiveComponents:false});
async function clearReactions(root) {
  for (const node of walk(root)) if ('reactions' in node && node.reactions.length) await react(node, []);
}
function namedClone(source, name, x, y) {
  const existing = page.children.find(n => n.name === NS + name);
  if (existing) return existing;
  const clone = add(source.clone());
  page.appendChild(clone);
  clone.name = NS + name;
  clone.x = x;
  clone.y = y;
  return clone;
}

// Prototype state is one STRING, not four independent booleans. Thus two
// interests can never be selected at once; tapping the active one keeps it.
const collections = await figma.variables.getLocalVariableCollectionsAsync();
let collection = collections.find(c => c.name === NS + 'Prototype state');
const createdVariableIds = [], createdCollectionIds = [];
if (!collection) {
  collection = figma.variables.createVariableCollection(NS + 'Prototype state');
  createdCollectionIds.push(collection.id);
}
const vars = await figma.variables.getLocalVariablesAsync();
let interestVar = vars.find(v => v.variableCollectionId === collection.id && v.name === 'selectedPurposeId');
if (!interestVar) {
  interestVar = figma.variables.createVariable('selectedPurposeId', collection, 'STRING');
  interestVar.scopes = []; // prototype-only state; hidden from design token pickers
  interestVar.setValueForMode(collection.defaultModeId, 'none');
  createdVariableIds.push(interestVar.id);
}
if (interestVar.resolvedType !== 'STRING') throw new Error('selectedPurposeId must be STRING.');
const setInterest = value => ({type:'SET_VARIABLE', variableId:interestVar.id,
  variableValue:{type:'STRING', resolvedType:'STRING', value}});

// Scoped adaptation of figma-generate-library/scripts/createComponentWithVariants.js:
// five values of one axis; clone source art; combine then position variants.
let interestSet = page.children.find(n => n.type === 'COMPONENT_SET' && n.name === NS + 'Interest single selection');
if (!interestSet) {
  const variants = [];
  for (const selected of ['none', ...INTERESTS]) {
    const variant = add(figma.createComponent());
    variant.name = 'Interest=' + selected;
    variant.resize(371, 252);
    variant.fills = [];
    variant.clipsContent = false;
    for (let i = 0; i < sourceCards.length; i++) {
      const card = add(sourceCards[i].clone());
      variant.appendChild(card);
      card.x = sourceCards[i].x - 16;
      card.y = sourceCards[i].y - 197;
      await clearReactions(card);
      if (selected === INTERESTS[i]) {
        card.strokes = copy(sourceSelected.strokes);
        card.strokeWeight = sourceSelected.strokeWeight;
        card.strokeAlign = 'INSIDE';
        const check = add(sourceCheck.clone());
        card.appendChild(check);
        check.name = 'Approved check · selected interest';
        // Keep the real asset complete and clear of the caption strip.
        check.x = card.width - check.width - 6;
        check.y = 6;
        check.visible = true;
      }
      await react(card, [setInterest(INTERESTS[i])]);
    }
    variants.push(variant);
  }
  interestSet = add(figma.combineAsVariants(variants, page));
  interestSet.name = NS + 'Interest single selection';
  interestSet.description = 'Source art and single selected purpose. One shared STRING variable drives all seven setup instances, preserving the purpose when a level is applied. None is an initial state; selection does not toggle off.';
  interestSet.x = startX;
  interestSet.y = 2190;
  interestSet.children.forEach((variant, i) => {variant.x = 20 + i * 395; variant.y = 20;});
  interestSet.resizeWithoutConstraints(5 * 395 + 20, 292);
}
const interestNone = interestSet.children.find(n => n.name === 'Interest=none');
if (!interestNone || interestSet.children.length !== 5) throw new Error('Inspect incomplete interest component set before retry.');

const setups = {}, overlays = {};
for (let i = 0; i < LEVELS.length; i++) {
  const level = LEVELS[i];
  const setup = namedClone(level === 'Beginner' ? sourceBeginner : sourceA2,
    'Setup / committed=' + level, startX + i * 450, 100);
  setups[level] = setup;
  const paper = child(setup, 'Setup paper');
  const field = child(paper, 'Change level');
  const medal = field.children.find(n => n.type === 'RECTANGLE' && ('fills' in n)
    && n.fills.some(p => p.type === 'IMAGE') && !n.name.includes('edge'));
  if (!medal) throw new Error('Missing existing medal slot in ' + field.id);
  mark(medal).fills = [{type:'IMAGE', imageHash:MEDAL_HASHES[level], scaleMode:'FIT'}];
  medal.name = 'Reviewed level medal · ' + level;
  if (level !== 'Beginner') {
    mark(child(field, 'Level code')).characters = level;
    mark(child(field, 'Hint')).characters = HINTS[level];
  }
  let instance = paper.children.find(n => n.name === 'Interest state · shared purpose');
  if (!instance) {
    for (const card of paper.children.filter(n => n.type === 'FRAME' && n.name.startsWith('Interest '))) {
      removed.push(card.id); card.remove(); // exact cloned children only
    }
    instance = add(interestNone.createInstance());
    paper.appendChild(instance);
    instance.name = 'Interest state · shared purpose';
    instance.x = 16; instance.y = 197;
  }
  mark(instance).setProperties({Interest:figma.variables.createVariableAlias(interestVar)});

  const name = NS + 'Overlay / draft=' + level;
  let overlay = page.children.find(n => n.name === name);
  if (!overlay) {
    overlay = add(figma.createFrame());
    page.appendChild(overlay);
    overlay.name = name;
    overlay.resize(402, 934);
    overlay.x = startX + i * 450; overlay.y = 1150;
    overlay.fills = []; overlay.clipsContent = true;
    const dim = add(sourceDim.clone());
    overlay.appendChild(dim);
    dim.x = 0; dim.y = 0; dim.resize(402, 934);
    const sheet = add(sourceSheet.clone());
    overlay.appendChild(sheet);
    sheet.x = 0; sheet.y = 414;
  }
  overlays[level] = overlay;
  await clearReactions(overlay);
  const sheet = child(overlay, 'Level chooser');
  for (const option of sheet.children.filter(n => n.name === 'Beginner' || n.name.startsWith('Level '))) {
    const optionLevel = option.name === 'Beginner' ? 'Beginner' : option.name.slice(6);
    const selected = optionLevel === level;
    mark(option).fills = copy(selected ? sourceSelected.fills : sourceUnselected.fills);
    option.strokes = copy(selected ? sourceSelected.strokes : sourceUnselected.strokes);
    option.strokeWeight = selected ? sourceSelected.strokeWeight : sourceUnselected.strokeWeight;
    for (const [name, template] of [['Selected gold inset',sourceInset],['Approved check — original user asset',sourceCheck]]) {
      let item = option.children.find(n => n.name === name);
      if (!item && selected) {item = add(template.clone()); option.appendChild(item);}
      if (item) {
        mark(item).visible = selected;
        if (selected && name === 'Selected gold inset') item.resize(option.width - 8, option.height - 8);
        if (selected && name === 'Approved check — original user asset') {
          const right = sourceSelected.width - sourceCheck.x - sourceCheck.width;
          item.x = option.width - right - item.width;
          item.y = (option.height - item.height) / 2;
        }
      }
    }
  }
}

for (const level of LEVELS) {
  await react(child(child(setups[level], 'Setup paper'), 'Change level'), [nodeAction(overlays[level], 'OVERLAY')]);
  const overlay = overlays[level], sheet = child(overlay, 'Level chooser');
  for (const choice of LEVELS) {
    const option = child(sheet, choice === 'Beginner' ? 'Beginner' : 'Level ' + choice);
    // Avoid invalid same-frame links. The selected option is a stable no-op.
    await react(option, choice === level ? [] : [nodeAction(overlays[choice], 'SWAP')]);
  }
  await react(child(overlay, 'Modal dim'), [{type:'CLOSE'}]);
  await react(child(sheet, 'Close'), []);
  const close = child(sheet, 'Close');
  let hit = sheet.children.find(n => n.name === 'Close · 48px hit target');
  if (!hit) {hit=add(figma.createFrame());sheet.appendChild(hit);hit.name='Close · 48px hit target';}
  mark(hit).x = close.x; hit.y = close.y + close.height / 2 - 24;
  hit.resize(Math.max(48,close.width),48);hit.fills=[];hit.strokes=[];
  await react(hit,[{type:'CLOSE'}]);
  const apply = sheet.children.find(n => n.name === 'Apply level · native editable' || n.name === 'Einleitung / Brass CTA / Reference v2');
  if (!apply) throw new Error('Missing Apply in ' + sheet.id);
  await react(apply,[nodeAction(setups[level],'NAVIGATE')]);
  await react(overlay,[{type:'CLOSE'}],{type:'ON_KEY_DOWN',device:'KEYBOARD',keyCodes:[27]});
}
return {
  createdNodeIds:[...created], mutatedNodeIds:[...changed], removedCloneNodeIds:removed,
  createdVariableIds, createdCollectionIds,
  states:{setups:Object.fromEntries(LEVELS.map(l=>[l,setups[l].id])),
    overlays:Object.fromEntries(LEVELS.map(l=>[l,overlays[l].id]))},
  interest:{componentSet:interestSet.id,variable:interestVar.id,
    variants:interestSet.children.map(n=>({id:n.id,name:n.name}))},
  overlayDefaults:LEVELS.map(l=>({level:l,position:overlays[l].overlayPositionType,
    background:overlays[l].overlayBackground,interaction:overlays[l].overlayBackgroundInteraction})),
  preservedOriginalIds:['80:336','80:569','80:611','116:328'],
  reviewChecks:[
    'Open each committed level, SWAP to every other level, Close/Escape/dim: unchanged underlay.',
    'Apply every level: correct setup/medal/hint; reopening checks that committed level.',
    'Select each interest: exactly one supplied check; change/apply/cancel a level and confirm interest persists.',
    'Compare first-unit 402x934 DE100; check interest check does not cover face or label.',
    'Inspect overlayDefaults for unexpected added dimming and verify actual overlay position in Play.',
  ],
  warnings:[
    'Prepared prototype only. Structural API success must be followed by Play interactions and screenshot review before Figma approval.',
    'Prototype state is session-local; this does not establish Flutter persistence, semantics, device, 200% text or release behavior.',
    'No-selection level/fresh-install disabled Continue, drag dismissal and later-screen return contracts are outside this seven-applied-state patch.',
    'Continue retains the existing route to screen02; its return wiring is not changed by this patch.',
    'Replays reuse named clones/components. Later source-art or typography changes require explicit propagation to these derived states.',
  ],
};
