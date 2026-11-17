// Review-only Figma patch. Prepared 2026-10-18; not executed by the UX reviewer.
// Run with use_figma against rVlcMLvngw07BYJ7nRT87C after material edits pass.
// Scope: existing 80:336 and 80:569 plus four clearly named state frames.
// No new medal art is generated. The source beginner seedling is still missing;
// the existing approved blank medal base is an explicitly unresolved placeholder.
// This demonstrates Beginner/A2 only. A1/B1/B2/C1/C2, no-selection, interests,
// keyboard/screen-reader behavior and adaptive layouts remain separate gates.

const page = await figma.getNodeByIdAsync('77:2');
if (!page || page.type !== 'PAGE') throw new Error('Expected Einleitung page 77:2.');
await figma.setCurrentPageAsync(page);
const changed = new Set();
const created = new Set();
const mark = node => (changed.add(node.id), node);
const descendants = node => [node, ...('children' in node ? node.children.flatMap(descendants) : [])];
const child = (node, name) => {
  const match = node.children.find(n => n.name === name);
  if (!match) throw new Error('Missing ' + name + ' in ' + node.id);
  return match;
};
const get = async id => {
  const node = await figma.getNodeByIdAsync(id);
  if (!node) throw new Error('Missing node ' + id);
  return node;
};
const setupA2 = await get('80:336');
const beginnerToA2 = await get('80:569');
const base = await get('101:39');
const basePaint = base.fills.find(paint => paint.type === 'IMAGE');
if (!basePaint) throw new Error('Approved blank medallion image missing.');

// Load existing fonts before any text edits, parenting, or clone operations.
const fonts = new Map();
for (const root of [setupA2, beginnerToA2]) {
  for (const text of descendants(root).filter(n => n.type === 'TEXT')) {
    for (const segment of text.getStyledTextSegments(['fontName'])) {
      fonts.set(JSON.stringify(segment.fontName), segment.fontName);
    }
  }
}
for (const font of fonts.values()) await figma.loadFontAsync(font);

const prefix = 'UX state · ';
const occupiedRight = Math.max(0, ...page.children.map(n => n.x + n.width));
let nextX = occupiedRight + 80;
function stateClone(source, name) {
  const existing = page.children.find(n => n.name === prefix + name);
  if (existing) {
    if (existing.type !== 'FRAME') throw new Error('State name collision: ' + name);
    return existing;
  }
  const clone = source.clone();
  page.appendChild(clone);
  clone.name = prefix + name;
  clone.x = nextX;
  clone.y = 100;
  nextX += clone.width + 48;
  for (const node of descendants(clone)) created.add(node.id);
  return clone;
}

// Clone all four before changing the supplied comparison modal.
const setupBeginner = stateClone(setupA2, '01 · committed Beginner');
const a2ToA2 = stateClone(beginnerToA2, '01 · committed A2 · draft A2');
const a2ToBeginner = stateClone(beginnerToA2, '01 · committed A2 · draft Beginner');
const beginnerToBeginner = stateClone(beginnerToA2, '01 · committed Beginner · draft Beginner');

function editText(node, value) {
  if (node.type !== 'TEXT') throw new Error('Text expected: ' + node.id);
  mark(node).characters = value;
}
function beginnerBackdrop(root) {
  const paper = child(root, 'Setup paper');
  const field = child(paper, 'Change level');
  const heading = child(paper, 'Start level');
  editText(heading, 'Wo möchtest du starten?');
  mark(heading).fontSize = 24;
  const code = child(field, 'Level code');
  editText(code, 'Dein Startniveau');
  mark(code).fontSize = 20;
  code.resize(234, 31);
  editText(child(field, 'Hint'), 'Ich fange neu an');
  mark(child(field, 'Hint')).resize(230, 23);
  mark(child(field, 'Change action')).visible = false;
  const medal = field.children.find(n => n.name === 'A2 — generated embossed metal' || n.name === 'Beginner · approved blank base · seedling pending');
  if (!medal) throw new Error('Expected existing level medal in ' + field.id);
  mark(medal).name = 'Beginner · approved blank base · seedling pending';
  medal.fills = [{...basePaint, scaleMode: 'FIT'}];
  mark(field).strokes = [{type: 'SOLID', color: {r: .80, g: .74, b: .64}}];
  field.strokeWeight = 1;
  const inset = field.children.find(n => n.name === 'Gold inner edge');
  if (inset) mark(inset).visible = false;
  let arrow = field.children.find(n => n.name === 'Beginner field chevron');
  if (!arrow) {
    // Clone an already loaded text style; no new font dependency or image asset.
    arrow = child(child(field, 'Change action'), 'Change label').clone();
    field.appendChild(arrow);
    arrow.name = 'Beginner field chevron';
    created.add(arrow.id);
  }
  editText(arrow, '›');
  arrow.x = 329;
  arrow.y = 13;
  arrow.resize(32, 48);
  arrow.fontSize = 32;
  arrow.lineHeight = {unit: 'PIXELS', value: 43};
  arrow.textAlignHorizontal = 'CENTER';
  arrow.textAlignVertical = 'CENTER';
  arrow.fills = [{type: 'SOLID', color: {r: .027, g: .11, b: .13}}];
  arrow.visible = true;
}
for (const root of [setupBeginner, beginnerToBeginner, beginnerToA2]) beginnerBackdrop(root);
mark(beginnerToA2).name = '01 · committed Beginner · draft A2 · source comparison';

const originalSheet = child(beginnerToA2, 'Level chooser');
const selectedTemplate = child(originalSheet, 'Level A2');
const unselectedTemplate = child(originalSheet, 'Level A1');
const selectedPaints = JSON.parse(JSON.stringify(selectedTemplate.fills));
const selectedStrokes = JSON.parse(JSON.stringify(selectedTemplate.strokes));
const selectedWeight = selectedTemplate.strokeWeight;
const unselectedPaints = JSON.parse(JSON.stringify(unselectedTemplate.fills));
const unselectedStrokes = JSON.parse(JSON.stringify(unselectedTemplate.strokes));
const unselectedWeight = unselectedTemplate.strokeWeight;
const checkTemplate = selectedTemplate.children.find(n => n.name === 'Approved check — original user asset');
const insetTemplate = selectedTemplate.children.find(n => n.name === 'Selected gold inset');
if (!checkTemplate || !insetTemplate) throw new Error('A2 selected check/inset must exist before this patch.');

function selectDraft(root, value) {
  const sheet = child(root, 'Level chooser');
  for (const option of sheet.children.filter(n => n.name === 'Beginner' || n.name.startsWith('Level '))) {
    const selected = option.name === (value === 'Beginner' ? 'Beginner' : 'Level A2');
    mark(option).fills = selected ? selectedPaints : unselectedPaints;
    option.strokes = selected ? selectedStrokes : unselectedStrokes;
    option.strokeWeight = selected ? selectedWeight : unselectedWeight;
    for (const adornmentName of ['Selected gold inset', 'Approved check — original user asset']) {
      let adornment = option.children.find(n => n.name === adornmentName);
      if (selected && !adornment) {
        const source = adornmentName === 'Selected gold inset' ? insetTemplate : checkTemplate;
        adornment = source.clone();
        option.appendChild(adornment);
        created.add(adornment.id);
      }
      if (adornment) {
        mark(adornment).visible = selected;
        if (selected && option.name === 'Beginner') {
          if (adornmentName === 'Selected gold inset') {
            adornment.x = 4;
            adornment.y = 4;
            adornment.resize(option.width - 8, option.height - 8);
          } else {
            const rightInset = selectedTemplate.width - checkTemplate.x - checkTemplate.width;
            adornment.x = option.width - rightInset - adornment.width;
            adornment.y = (option.height - adornment.height) / 2;
          }
        }
      }
    }
  }
}
selectDraft(beginnerToA2, 'A2');
selectDraft(a2ToA2, 'A2');
selectDraft(beginnerToBeginner, 'Beginner');
selectDraft(a2ToBeginner, 'Beginner');

const navigate = target => [{
  trigger: {type: 'ON_CLICK'},
  actions: [{type: 'NODE', destinationId: target.id, navigation: 'NAVIGATE',
    transition: {type: 'DISSOLVE', duration: .15, easing: {type: 'EASE_OUT'}},
    preserveScrollPosition: false}],
}];
async function link(node, target) {
  mark(node);
  let root = node;
  while (root.parent && root.parent.type !== 'PAGE') root = root.parent;
  if (root.id === target.id) {
    await node.setReactionsAsync([]);
    return;
  }
  await node.setReactionsAsync(navigate(target));
}
async function clearUnderlayReactions(root) {
  // Every copied background action is inert while the modal is present.
  const sheet = child(root, 'Level chooser');
  const dim = child(root, 'Modal dim');
  for (const item of root.children.filter(n => n !== sheet && n !== dim)) {
    for (const node of descendants(item)) {
      if ('reactions' in node && node.reactions.length) {
        mark(node);
        await node.setReactionsAsync([]);
      }
    }
  }
}
async function wireModal(root, committed, draft, beginnerSibling, a2Sibling) {
  await clearUnderlayReactions(root);
  const sheet = child(root, 'Level chooser');
  const close = child(sheet, 'Close');
  // Preserve the visible caption geometry exactly. Only the hit area expands.
  await close.setReactionsAsync([]);
  mark(close);
  let hit = sheet.children.find(n => n.name === 'Close · 48px hit target');
  if (!hit) {
    hit = figma.createFrame();
    sheet.appendChild(hit);
    hit.name = 'Close · 48px hit target';
    created.add(hit.id);
  }
  mark(hit).x = close.x;
  hit.y = close.y + close.height / 2 - 24;
  hit.resize(Math.max(48, close.width), 48);
  hit.fills = [];
  hit.strokes = [];
  hit.clipsContent = false;
  await link(hit, committed);
  await link(child(root, 'Modal dim'), committed);
  const apply = sheet.children.find(n => n.name === 'Apply level · native editable' || n.name === 'Einleitung / Brass CTA / Reference v2');
  if (!apply) throw new Error('Apply CTA missing in ' + sheet.id);
  await link(apply, draft === 'Beginner' ? setupBeginner : setupA2);
  await link(child(sheet, 'Beginner'), beginnerSibling);
  await link(child(sheet, 'Level A2'), a2Sibling);
}
await wireModal(beginnerToBeginner, setupBeginner, 'Beginner', beginnerToBeginner, beginnerToA2);
await wireModal(beginnerToA2, setupBeginner, 'A2', beginnerToBeginner, beginnerToA2);
await wireModal(a2ToA2, setupA2, 'A2', a2ToBeginner, a2ToA2);
await wireModal(a2ToBeginner, setupA2, 'Beginner', a2ToBeginner, a2ToA2);
await link(child(child(setupA2, 'Setup paper'), 'Change level'), a2ToA2);
await link(child(child(setupBeginner, 'Setup paper'), 'Change level'), beginnerToBeginner);

return {
  createdNodeIds: [...created],
  mutatedNodeIds: [...changed],
  states: {
    committedBeginner: setupBeginner.id, committedA2: setupA2.id,
    beginnerDraftBeginner: beginnerToBeginner.id, beginnerDraftA2: beginnerToA2.id,
    a2DraftBeginner: a2ToBeginner.id, a2DraftA2: a2ToA2.id,
  },
  warnings: [
    'Beginner seedling artwork is unresolved: approved blank medallion base is a placeholder, not parity approval.',
    'Only Beginner and A2 selection transitions are covered. A1/B1/B2/C1/C2, no-selection and interests still need review.',
    'Figma navigation proves no Flutter persistence, screen-reader focus, keyboard, 200% text or device behavior.',
    'Replaying preserves named state frames; later artwork or typography updates must also be propagated to those clones.',
  ],
};
