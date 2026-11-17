// Prepared by the material reviewer, 2026-10-18. Not executed by this reviewer.
// Run via Figma use_figma on rVlcMLvngw07BYJ7nRT87C after inspecting this script.
// Source: einleitung1.png / einleitung1_levelchoose.png, normalized to 402x934.
// No PNG crop, pixel edit, nonuniform resize, screenshot asset, or reaction change.
// Existing CTA hit frames remain 370x58; the independent gold BODY must be 370x51.
// The old 2006x305 body cannot meet both dimensions by uniform scaling.

const CONFIG = {
  // Root supplies the NEW uploaded blank-gold PNG and measured alpha>=128 body.
  // Example structure only: {imageHash:'...', canvas:[2172,724], body:[l,t,r,b]}.
  // null performs only vector/text/field refinements and reports CTA as pending.
  goldAsset: {imageHash:'d06a4daa43ed56bf2d53a4b829c8210e90a175fd',canvas:[2170,725],body:[73,205,2102,491]},
  ctaBodyWidth: 370,
  ctaBodyHeight: 51,
  ctaHeightTolerance: 1.5,
  setupIds: ['116:328','116:449','116:375','116:523','133:164','127:151','127:243','127:334','127:423','127:514','127:605','127:696'],
  overlayIds: ['133:212','127:212','127:303','127:394','127:483','127:574','127:665','127:756'],
};

const page = await figma.getNodeByIdAsync('77:2');
if (!page || page.type !== 'PAGE') throw new Error('Expected Einleitung page 77:2.');
await figma.setCurrentPageAsync(page);
const changed = new Set(), created = new Set(), warnings = [];
const mark = node => (changed.add(node.id), node);
const rgb = hex => ({r:parseInt(hex.slice(1,3),16)/255,g:parseInt(hex.slice(3,5),16)/255,b:parseInt(hex.slice(5,7),16)/255});
const solid = (hex,opacity=1) => ({type:'SOLID',color:rgb(hex),opacity});
const gradient = stops => ({type:'GRADIENT_LINEAR',gradientTransform:[[0,1,0],[-1,0,1]],gradientStops:stops.map(([position,hex])=>({position,color:{...rgb(hex),a:1}}))});
const shadow = (hex,alpha,x,y,radius,type='DROP_SHADOW') => ({type,color:{...rgb(hex),a:alpha},offset:{x,y},radius,spread:0,visible:true,blendMode:'NORMAL'});
const descendants = n => [n,...('children' in n ? n.children.flatMap(descendants) : [])];
const direct = (n,name) => n.children.find(c=>c.name===name);
const required = (n,name) => {const x=direct(n,name);if(!x)throw new Error('Missing '+name+' in '+n.id);return x;};
const get = async id => {const n=await figma.getNodeByIdAsync(id);if(!n)throw new Error('Missing node '+id);return n;};

// Preflight all target roots and fonts before any mutation.
const cta = await get('103:48');
if (cta.type !== 'COMPONENT') throw new Error('103:48 must remain the shared CTA component.');
const roots = [];
for (const id of ['80:336','80:569',...CONFIG.setupIds,...CONFIG.overlayIds]) roots.push(await get(id));
const fonts = new Map();
for (const n of [cta,...roots].flatMap(descendants).filter(n=>n.type==='TEXT')) {
  for(const part of n.getStyledTextSegments(['fontName'])) fonts.set(JSON.stringify(part.fontName),part.fontName);
}
for (const font of fonts.values()) await figma.loadFontAsync(font);

let goldFit = null;
if (CONFIG.goldAsset) {
  const a=CONFIG.goldAsset,[cw,ch]=a.canvas,[l,t,r,b]=a.body,bw=r-l,bh=b-t;
  if(!a.imageHash||bw<=0||bh<=0||l<0||t<0||r>cw||b>ch)throw new Error('Invalid new gold asset body measurement.');
  const scale=CONFIG.ctaBodyWidth/bw,height=bh*scale;
  if(Math.abs(height-CONFIG.ctaBodyHeight)>CONFIG.ctaHeightTolerance)throw new Error('New gold body ratio still fails: visible '+CONFIG.ctaBodyWidth+' x '+height.toFixed(3)+'. No crop or stretch allowed.');
  goldFit={imageHash:a.imageHash,x:-l*scale,y:-t*scale,width:cw*scale,height:ch*scale,visibleWidth:CONFIG.ctaBodyWidth,visibleHeight:height,scale};
} else {
  warnings.push('CTA surface still pending new aspect-correct PNG: old body2006x305 yields370x56.256; width360 still yields54.736 high.');
}

function rect(parent,name,x,y,w,h,radius) {
  let n=direct(parent,name);
  if(n&&n.type!=='RECTANGLE')throw new Error('Expected rectangle '+name);
  if(!n){n=figma.createRectangle();parent.appendChild(n);n.name=name;created.add(n.id);mark(parent);}
  mark(n);n.x=x;n.y=y;n.resize(w,h);n.cornerRadius=radius;n.fills=[];n.strokes=[];n.effects=[];n.visible=true;
  return n;
}
function vector(parent,name,path,x,y,w,h,paint,effects=[]) {
  let n=direct(parent,name);
  if(n&&n.type!=='VECTOR')throw new Error('Expected vector '+name);
  if(!n){n=figma.createVector();parent.appendChild(n);n.name=name;created.add(n.id);mark(parent);}
  mark(n);n.vectorPaths=[{windingRule:'NONZERO',data:path}];n.resize(w,h);n.x=x;n.y=y;n.fills=[paint];n.strokes=[];n.effects=effects;n.visible=true;
  return n;
}
const rightPath='M 0 0 L 2.8 0 L 10 8 L 2.8 16 L 0 16 L 7.2 8 Z';
const downPath='M 0 0 L 2.2 0 L 6 4.1 L 9.8 0 L 12 0 L 6 7 Z';
function rightChevron(parent,name,x,y,w=10,h=16,bevel=true) {
  return vector(parent,name,rightPath,x,y,w,h,solid('#102019'),bevel ? [
    shadow('#ffe9a3',.95,-.65,-.45,0),
    shadow('#75481a',.65,.55,.75,.25),
  ] : [shadow('#fff8e8',.35,0,.6,0)]);
}
function fitGold(art) {
  if(!goldFit)return;
  mark(art);art.x=goldFit.x;art.y=goldFit.y;art.resize(goldFit.width,goldFit.height);
  art.fills=[{type:'IMAGE',imageHash:goldFit.imageHash,scaleMode:'FIT'}];
  art.strokes=[];art.effects=[];
}

// Shared main CTA: edit its component once. Existing instance reactions survive.
mark(cta);cta.resize(370,58);cta.clipsContent=false;
fitGold(required(cta,'Whole independent gold asset'));
const mainLabel=required(cta,'Label');
mark(mainLabel);mainLabel.x=16;mainLabel.y=6;mainLabel.resize(338,43);
mainLabel.fontSize=23;mainLabel.lineHeight={unit:'PIXELS',value:43};
mainLabel.textAlignHorizontal='CENTER';mainLabel.textAlignVertical='CENTER';
mainLabel.effects=[shadow('#ffe7a4',.38,0,.65,0)];
mark(required(cta,'Arrow')).visible=false;
rightChevron(cta,'Control relief / main right arrow',336,18);

function refineField(field) {
  const action=required(field,'Change action');
  const committed=action.visible;
  if(committed) {
    mark(field);field.cornerRadius=15;field.strokeAlign='INSIDE';field.strokeWeight=3;
    field.strokes=[gradient([[0,'#087b6a'],[.42,'#00594d'],[1,'#003e33']])];
    field.effects=[shadow('#5a3919',.27,0,2.2,1.4),shadow('#fff8df',.45,0,1,.75,'INNER_SHADOW')];
    const outer=rect(field,'Control relief / field outer gold bevel',0,0,field.width,field.height,15);
    outer.strokes=[gradient([[0,'#f2d28b'],[.25,'#b99146'],[.65,'#ab7c32'],[1,'#76501f']])];outer.strokeWeight=.8;outer.strokeAlign='INSIDE';
    let inset=direct(field,'Gold inner edge');
    if(!inset)inset=rect(field,'Gold inner edge',3,3,field.width-6,field.height-6,12);
    mark(inset);inset.x=3;inset.y=3;inset.resize(field.width-6,field.height-6);inset.cornerRadius=12;inset.fills=[];
    inset.strokes=[gradient([[0,'#f5dfa8'],[.5,'#c5a15c'],[1,'#dfbd78']])];inset.strokeWeight=.75;inset.strokeAlign='INSIDE';inset.visible=true;
  }
  // The frame remains the 48px interaction target; visible face is 46px tall.
  mark(action);action.x=267;action.y=13;action.resize(98,48);action.cornerRadius=22;
  action.fills=[];action.strokes=[];action.effects=[];action.clipsContent=false;
  const face=rect(action,'Control relief / jade face',0,1,98,46,22);
  face.fills=[gradient([[0,'#30675a'],[.42,'#145e50'],[1,'#064b3e']])];
  face.strokes=[gradient([[0,'#f5dba0'],[.45,'#c69744'],[1,'#a96d25']])];face.strokeWeight=1.1;face.strokeAlign='INSIDE';
  face.effects=[shadow('#573719',.35,0,1.7,1.1),shadow('#e1e0b5',.20,0,1.1,1.2,'INNER_SHADOW'),shadow('#003b30',.55,0,-1.5,1.2,'INNER_SHADOW')];
  action.insertChild(0,face);mark(action);
  const label=required(action,'Change label');
  mark(label);label.characters='Ändern';label.fontSize=16;label.x=11;label.y=12;label.resize(61,28);
  label.lineHeight={unit:'PIXELS',value:28};label.textAlignHorizontal='CENTER';label.textAlignVertical='CENTER';
  label.effects=[shadow('#003d32',.55,0,.7,.3)];
  vector(action,'Control relief / gold down arrow',downPath,74,19,12,7,
    gradient([[0,'#ffedb1'],[.35,'#efce79'],[1,'#c48a32']]),
    [shadow('#003a2d',.85,.4,1,.3),shadow('#fff4cf',.35,-.3,-.25,0)]);
  // Beginner keeps its neutral field, without adopting the selected jade rim.
  const oldBeginner=direct(field,'Beginner field chevron');
  if(oldBeginner) {
    const priorVector=direct(field,'Control relief / beginner right arrow');
    const wasVisible=priorVector?priorVector.visible:oldBeginner.visible;
    mark(oldBeginner).visible=false;
    const arrow=rightChevron(field,'Control relief / beginner right arrow',342,29,8.5,15,false);
    mark(arrow).visible=wasVisible;
  }
}

const fieldIds=[],applyIds=[];
for(const root of roots) {
  const setup=direct(root,'Setup paper');
  if(setup) {
    const field=required(setup,'Change level');refineField(field);fieldIds.push(field.id);
    const instance=root.children.find(n=>n.type==='INSTANCE'&&n.name==='Einleitung / Brass CTA / Reference v2');
    if(instance){mark(instance);instance.x=16;instance.y=849;instance.resize(370,58);instance.clipsContent=false;}
  }
  const sheet=direct(root,'Level chooser');
  if(sheet) {
    const apply=required(sheet,'Apply level · native editable');
    mark(apply);apply.x=16;apply.y=429;apply.resize(370,58);apply.clipsContent=false;
    fitGold(required(apply,'Whole gold button v2'));
    const label=required(apply,'Apply label');
    mark(label);label.fontSize=20;label.x=14;label.y=6;label.resize(346,32);
    label.lineHeight={unit:'PIXELS',value:32};label.textAlignHorizontal='CENTER';label.textAlignVertical='CENTER';
    label.effects=[shadow('#ffe7a4',.38,0,.65,0)];applyIds.push(apply.id);
  }
}

return {
  createdNodeIds:[...created],mutatedNodeIds:[...changed],fieldIds,applyIds,goldFit,warnings,
  ctaSurfaceStatus:goldFit?'GEOMETRY_READY_FOR_RENDERED_REVIEW':'PENDING_ASPECT_CORRECT_ASSET',
  mainCtaBodyTarget:[16,849,370,51],sheetCtaBodyTarget:[16,843,370,51],
  minimumHitHeight:48,reactionsChanged:false,jadeHeaderChanged:false,
  finalApproval:'Pending fresh rendered review of fields, arrows, labels and new gold surface. This script itself is not approval.',
};
