// Prepared 2026-10-18. UX reviewer does not execute Figma mutations.
// Run AFTER patch_einleitung_level_interactions.js; root executes after review.
// Scope: one fresh/null setup, one null overlay, one 02 return clone, and
// Continue/handle interactions on the seven UX7 clones. Original comparison IDs
// and the seven-level/interest asset ownership remain unchanged.
// API contract: https://developers.figma.com/docs/plugins/api/Action/
// BACK returns the preceding screen; OVERLAY/SWAP preserve its state; CLOSE
// dismisses the top overlay. ON_DRAG exposes no direction or distance threshold.
// App contract: onboarding_journey_state.dart:148,152; first_run_coordinator.dart:
// 422,442,454,474; c_onboarding.dart:809,822. Null != Beginner (A1+beginner=true).

const NS = 'Einleitung UX7 / ';
const LEVELS = ['Beginner', 'A1', 'A2', 'B1', 'B2', 'C1', 'C2'];
const page = await figma.getNodeByIdAsync('77:2');
if (!page || page.type !== 'PAGE') throw new Error('Missing page77:2.');
await figma.setCurrentPageAsync(page);
const find = name => {
  const matches = page.children.filter(n => n.name === NS + name);
  if (matches.length !== 1) throw new Error('Expected exactly one ' + NS + name);
  return matches[0];
};
const child = (root, name) => {
  const n = root.children.find(n => n.name === name);
  if (!n) throw new Error('Missing ' + name + ' in ' + root.id);
  return n;
};
const walk = n => [n, ...('children' in n ? n.children.flatMap(walk) : [])];
const cloneJSON = value => JSON.parse(JSON.stringify(value));
const setups = Object.fromEntries(LEVELS.map(l => [l, find('Setup / committed=' + l)]));
const overlays = Object.fromEntries(LEVELS.map(l => [l, find('Overlay / draft=' + l)]));
const storySource = await figma.getNodeByIdAsync('80:380');
const blankMedal = await figma.getNodeByIdAsync('101:39');
const basePaint = blankMedal?.fills?.find(p => p.type === 'IMAGE');
if (!storySource || !basePaint) throw new Error('Missing reviewed 02 source/blank medal base.');
const continueOf = root => {
  const nodes = root.children.filter(n => n.type === 'INSTANCE' && n.name.includes('Brass CTA'));
  if (nodes.length !== 1) throw new Error('Expected one root Continue in ' + root.id);
  return nodes[0];
};
const applyOf = sheet => child(sheet, 'Apply level · native editable');
// Validate all required existing nodes before mutating anything.
for (const l of LEVELS) {
  continueOf(setups[l]);
  child(child(setups[l], 'Setup paper'), 'Change level');
  const s = child(overlays[l], 'Level chooser');
  child(s, 'Sheet handle'); applyOf(s);
}
const sourceUnselected = child(child(overlays.A2, 'Level chooser'), 'Level A1');
child(storySource, 'Back');
const fonts = new Map();
for (const root of [setups.A2, overlays.A2, storySource]) {
  for (const t of walk(root).filter(n => n.type === 'TEXT')) {
    for (const run of t.getStyledTextSegments(['fontName'])) fonts.set(JSON.stringify(run.fontName), run.fontName);
  }
}
for (const font of fonts.values()) await figma.loadFontAsync(font);
const created = new Set(), changed = new Set();
const add = n => (walk(n).forEach(x => created.add(x.id)), n);
const mark = n => (changed.add(n.id), n);
const startX = Math.max(...page.children.map(n => n.x + n.width), 0) + 80;
function namedClone(source, name, x, y) {
  const matches = page.children.filter(n => n.name === NS + name);
  if (matches.length > 1) throw new Error('Duplicate ' + name);
  if (matches.length === 1) return matches[0];
  const clone = add(source.clone()); page.appendChild(clone);
  clone.name = NS + name; clone.x = x; clone.y = y;
  return clone;
}
async function react(node, actions, trigger = {type:'ON_CLICK'}) {
  mark(node);
  try { await node.setReactionsAsync(actions.length ? [{trigger, actions}] : []); } catch(e) { throw new Error(node.name+' '+JSON.stringify({trigger,actions})+' '+e.message); }
}
const nav = (target, navigation) => ({type:'NODE', destinationId:target.id,
  navigation, transition:null, resetScrollPosition:false, resetInteractiveComponents:false});
async function disable(node) {
  // Clear descendants too: an instance's nested hotspot must not remain active.
  for (const n of walk(node)) if ('reactions' in n && n.reactions.length) await react(n, []);
  await react(node, []); mark(node).opacity = 0.48; // IntroAction.disabledOpacity
}

const fresh = namedClone(setups.A2, 'Setup / committed=none / fresh install', startX, 100);
const empty = namedClone(overlays.A2, 'Overlay / draft=none', startX, 1150);
const story = namedClone(storySource, '02 / return to entered setup', startX + 450, 100);
const freshPaper = child(fresh, 'Setup paper');
const field = child(freshPaper, 'Change level');
const code = child(field, 'Level code');
// New null state has no reference screenshot. Preserve the approved field/art
// geometry; fit the exact app_de.arb prompt into its available label column.
mark(code).characters = 'Wähle ein Level für Beispiel und Lernziele.';
code.fontSize = 16; code.lineHeight = {unit:'PIXELS', value:20};
code.textAutoResize = 'HEIGHT'; code.resize(166, 60); code.x = 94; code.y = 7;
if (code.height > 60.5) throw new Error('Null prompt needs rendered wrapping review: height=' + code.height);
mark(child(field, 'Hint')).visible = false;
const medal = field.children.find(n => n.type === 'RECTANGLE' && (n.name.startsWith('Reviewed level medal') || n.name === 'Unselected level · approved blank medal'));
if (!medal) throw new Error('Missing reviewed medal slot in fresh clone.');
mark(medal).fills = [{...cloneJSON(basePaint), scaleMode:'FIT'}];
medal.name = 'Unselected level · approved blank medal';
let dash = field.children.find(n => n.name === 'Unselected level · dash');
if (!dash) {dash=add(code.clone());field.appendChild(dash);dash.name='Unselected level · dash';}
mark(dash).characters = '–'; dash.fontSize = 28;
dash.lineHeight = {unit:'PIXELS',value:36}; dash.textAutoResize = 'NONE';
dash.resize(medal.width,36); dash.textAlignHorizontal='CENTER';
dash.x=medal.x; dash.y=medal.y+(medal.height-36)/2;
dash.visible=true;
await disable(continueOf(fresh));
await react(field, [nav(empty, 'OVERLAY')]);

const emptySheet = child(empty, 'Level chooser');
for (const l of LEVELS) {
  const option = child(emptySheet, l === 'Beginner' ? 'Beginner' : 'Level ' + l);
  mark(option).fills = cloneJSON(sourceUnselected.fills);
  option.strokes = cloneJSON(sourceUnselected.strokes);
  option.strokeWeight = sourceUnselected.strokeWeight;
  for (const n of option.children.filter(n => ['Selected gold inset','Approved check — original user asset'].includes(n.name))) mark(n).visible=false;
  await react(option, [nav(overlays[l], 'SWAP')]);
}
await disable(applyOf(emptySheet));
await react(child(empty,'Modal dim'),[{type:'CLOSE'}]);
await react(child(emptySheet,'Close · 48px hit target'),[{type:'CLOSE'}]);
await react(child(emptySheet,'Close'),[]);
await react(empty,[{type:'CLOSE'}],{type:'ON_KEY_DOWN',device:'KEYBOARD',keyCodes:[27]});

// 02 uses BACK, not a fixed A2 destination. Its predecessor is the exact setup
// that navigated here. The shared purpose STRING remains bound on that setup.
for (const l of LEVELS) await react(continueOf(setups[l]),[nav(story,'NAVIGATE')]);
const back = child(story,'Back');
await react(back,[]);
let backHit = story.children.find(n => n.name === 'Back · 48px hit target');
if (!backHit) {backHit=add(figma.createFrame());story.appendChild(backHit);backHit.name='Back · 48px hit target';}
mark(backHit).resize(Math.max(48,back.width),48);
backHit.x=back.x;
backHit.y=Math.max(back.y+back.height/2-24,continueOf(story).y+continueOf(story).height);
backHit.fills=[];backHit.strokes=[];
await react(backHit,[{type:'BACK'}]);

// Represent a dismissal outcome on the handle only. Do not put ON_DRAG on the
// whole sheet or options: that would mask option gestures and scrolling.
const dragTargets=[];
for (const overlay of [...Object.values(overlays),empty]) {
  const sheet=child(overlay,'Level chooser'),handle=child(sheet,'Sheet handle');
  let hit=sheet.children.find(n=>n.name==='Drag handle · 48px hit target');
  if(!hit){hit=add(figma.createFrame());sheet.appendChild(hit);hit.name='Drag handle · 48px hit target';}
  mark(hit).resize(64,48);hit.x=handle.x+handle.width/2-32;hit.y=0;
  hit.fills=[];hit.strokes=[];
  // Figma rejects ON_DRAG + CLOSE; tapping the handle demonstrates dismissal.
  await react(hit,[{type:'CLOSE'}]);
  dragTargets.push(hit.id);
}
return {
  createdNodeIds:[...created],mutatedNodeIds:[...changed],
  states:{fresh:fresh.id,emptyOverlay:empty.id,return02:story.id},
  checks:{nullPromptHeight:code.height,continueOpacity:continueOf(fresh).opacity,
    emptyApplyOpacity:applyOf(emptySheet).opacity,backHit:backHit.id,dragTargets},
  preservedOriginalIds:['80:336','80:569','80:611','80:380','116:328'],
  playAcceptance:[
    'Restart prototype at fresh: no selected level/interest; Continue inert; open shows no check and inert Apply.',
    'Choose an interest while level is null, open/change/cancel: interest retained and Continue remains inert.',
    'Apply any level: exact medal/label, one check on reopen, enabled Continue; optional interest is not required.',
    'From each of seven applied levels and each selected purpose, Continue then 02 Back restores the entered level, beginner flag and single purpose.',
    'Close, dim, Escape and handle tap dismiss without committing the draft; no extra dim layer appears.',
    'Inspect null prompt wrapping and 02 Back target against CTA at 402x934 DE100.',
  ],
  warnings:[
    'Run this extension last; replaying the seven-level patch clears overlay handle reactions and does not own the new entry/return frames.',
    'Fresh-install inspection requires a restarted prototype session: selectedPurposeId is session-local and intentionally is not reset on cancel or Back.',
    'ON_DRAG plus CLOSE was rejected by Figma. Handle tap represents dismissal; physical downward drag and accessibility semantics require later Flutter QA.',
    '02 Back requires entering through a UX7 setup; opening 02 directly has no preceding frame. Beyond 02 onward navigation is unchanged and outside this return test.',
    'API success is not Play evidence. Null prompt/new unselected medal treatment and all interactions require rendered Play inspection.',
  ],
};
