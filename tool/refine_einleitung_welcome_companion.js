// Material review preparation, 2026-10-18. Reviewer has NOT executed this file.
// Root runs through use_figma after review, then exports the three frames.
// Native edits only; no PNG pixel edits or source-screenshot fragments.
// Companion roots stay at 402x934. Welcome retains its source's own aspect.
// No reactions, flows, routes, preview action or selection behavior are changed.
const CONFIG = {
  welcomeId:'85:32', companionIds:['80:505','80:537'],
  applyWelcome:true,
  // Full scene is 941x1672. A separate Flutter adaptation is required for402x934.
  welcomeWidth:402, welcomeHeight:402*1672/941,
  taegoReplacementHash:'263e8d55f4d2d06d67eee57648e6becfa5f125c0',
  jade:'6f491fecf54b88d71803b6d995449cb0570672cf',
  paper:'2b04ce49b5b575b4e55d89a0c23d430c9a25cc39',
  check:'9d1d4c06ecef94534d268af293dd33ee961cb7de',
  blankMedal:'d30e73f22e0a3045cfdebefabc5f542d0d6060ab',
  plum:'72164c5f6f1a7ee1c9d4578f4d95805dbbfdf848',
  cloud:'5be9b121e5d8fdb33d6a1be8cb4cd7aecfd4eef8',
  welcomeScene:'b05dffa8f6df3c5c679c758a07a58d7ea8fabb11',
  sharedGoldComponentId:'103:48',
};
const page=await figma.getNodeByIdAsync('77:2');
if(!page||page.type!=='PAGE')throw new Error('Expected Einleitung page77:2');
await figma.setCurrentPageAsync(page);
const changed=new Set(),created=new Set(),warnings=[];
const mark=n=>(changed.add(n.id),n);
const walk=n=>[n,...('children'in n?n.children.flatMap(walk):[])];
const direct=(p,name)=>p.children.find(n=>n.name===name);
const need=(p,name)=>{const n=direct(p,name);if(!n)throw new Error('Missing '+name+' in '+p.id);return n;};
const get=async id=>{const n=await figma.getNodeByIdAsync(id);if(!n)throw new Error('Missing '+id);return n;};
const roots=await Promise.all(CONFIG.companionIds.map(get));
const welcome=await get(CONFIG.welcomeId), gold=await get(CONFIG.sharedGoldComponentId);
if(gold.type!=='COMPONENT')throw new Error('The approved shared CTA must remain a component');
// Fail early on a changed structure. The UX reviewer takes ownership after this patch.
for(const root of roots){
  if(root.type!=='FRAME')throw new Error('Companion target must be an outer frame');
  for(const name of ['Generated jade','Generated paper and footer','Title','Brand','Progress','Choose Taego','Choose Joy','Gye reading'])need(root,name);
  for(const name of ['Choose Taego','Choose Joy'])for(const child of ['New generated close portrait','Name','Role'])need(need(root,name),child);
  const cta=root.children.find(n=>n.type==='INSTANCE'&&n.children.some(c=>c.name==='Label'));
  if(!cta)throw new Error('Companion CTA instance missing');
}
if(CONFIG.applyWelcome){
  for(const name of ['Brand','Title','Start','Later'])need(welcome,name);
  if(!direct(welcome,'Start label')&&!direct(need(welcome,'Start'),'Start label'))throw new Error('Welcome start label missing');
  if(!welcome.children.some(n=>n.type==='TEXT'&&n.characters.startsWith('Entdecke Koreanisch')))throw new Error('Welcome body missing');
}
const fonts=new Map();
for(const n of [...roots,welcome,gold].flatMap(walk).filter(n=>n.type==='TEXT'))for(const s of n.getStyledTextSegments(['fontName']))fonts.set(JSON.stringify(s.fontName),s.fontName);
for(const f of [{family:'Roboto',style:'Bold'},{family:'Roboto',style:'Regular'},{family:'Roboto Condensed',style:'Bold'},{family:'Roboto Condensed',style:'Regular'},{family:'Noto Serif',style:'Regular'},{family:'Lora',style:'SemiBold'}])fonts.set(JSON.stringify(f),f);
for(const f of fonts.values())await figma.loadFontAsync(f);

const rgb=h=>({r:parseInt(h.slice(1,3),16)/255,g:parseInt(h.slice(3,5),16)/255,b:parseInt(h.slice(5,7),16)/255});
const solid=(hex,opacity=1)=>({type:'SOLID',color:rgb(hex),opacity});
const grad=stops=>({type:'GRADIENT_LINEAR',gradientTransform:[[0,1,0],[-1,0,1]],gradientStops:stops.map(([position,hex])=>({position,color:{...rgb(hex),a:1}}))});
const shadow=(hex,a,x,y,radius,type='DROP_SHADOW')=>({type,color:{...rgb(hex),a},offset:{x,y},radius,spread:0,visible:true,blendMode:'NORMAL'});
function box(n,x,y,w,h){mark(n);n.resize(w,h);n.x=x;n.y=y;return n;}
function rect(p,name,x,y,w,h,r=0){
  let n=direct(p,name);if(n&&n.type!=='RECTANGLE')throw new Error(name+' is not a rectangle');
  if(!n){n=figma.createRectangle();p.appendChild(n);n.name=name;created.add(n.id);mark(p);}
  box(n,x,y,w,h);n.cornerRadius=r;n.fills=[];n.strokes=[];n.effects=[];n.visible=true;return n;
}
function imageRect(p,name,hash,x,y,w,h,r=0){const n=rect(p,name,x,y,w,h,r);n.fills=[{type:'IMAGE',imageHash:hash,scaleMode:'FIT'}];return n;}
function text(n,characters,x,y,w,h,family,style,size,line,color,align='LEFT'){
  mark(n);n.fontName={family,style};n.characters=characters;n.fontSize=size;n.textAutoResize='NONE';
  n.lineHeight={unit:'PIXELS',value:line};n.letterSpacing={unit:'PIXELS',value:0};
  n.textAlignHorizontal=align;n.textAlignVertical='CENTER';n.fills=[solid(color)];n.effects=[];
  n.textDecoration='NONE';return box(n,x,y,w,h);
}
function nativeVector(p,name,path,x,y,w,h,paint,strokeWidth=0){
  let n=direct(p,name);if(n&&n.type!=='VECTOR')throw new Error(name+' is not a vector');
  if(!n){n=figma.createVector();p.appendChild(n);n.name=name;created.add(n.id);mark(p);}
  mark(n);n.vectorPaths=[{windingRule:'NONZERO',data:path}];n.resize(w,h);n.x=x;n.y=y;
  n.fills=strokeWidth?[]:[paint];n.strokes=strokeWidth?[paint]:[];n.strokeWeight=strokeWidth||1;
  n.strokeCap='ROUND';n.strokeJoin='ROUND';n.effects=[];n.visible=true;return n;
}
function selectedRim(card,w,h,selected){
  const rail=rect(card,'Material / portrait jade rail',0,0,w,h,17);
  rail.strokes=[grad([[0,'#087b6a'],[.42,'#00594d'],[1,'#003e33']])];rail.strokeWeight=2.6;rail.strokeAlign='INSIDE';
  rail.effects=[shadow('#5a3919',.24,0,2,1.2)];rail.visible=selected;
  const outer=rect(card,'Material / portrait outer gold bevel',0,0,w,h,17);
  outer.strokes=[grad([[0,'#ffe6a5'],[.35,'#c69a4d'],[1,'#81531f']])];outer.strokeWeight=.85;outer.strokeAlign='INSIDE';outer.visible=selected;
  const inner=rect(card,'Material / portrait inner gold bevel',3.0,3.0,w-6,h-6,14);
  inner.strokes=[grad([[0,'#fff0bc'],[.5,'#c6a05a'],[1,'#e5c57d']])];inner.strokeWeight=.75;inner.strokeAlign='INSIDE';inner.visible=selected;
}
function suppliedCheck(card,person,selected){
  for(const n of card.children.filter(n=>n.name==='Brass medal ✓'||n.name==='Medal value'))mark(n).visible=false;
  // Exact supplied RGBA1254square; alpha>=128 bbox[171,169,1079,1071].
  const s=46/908,x=person==='Taego'?11:132,y=239;
  const n=imageRect(card,'Material / supplied selection check',CONFIG.check,x-171*s,y-169*s,1254*s,1254*s);
  n.visible=selected;
}
const rootReport=[];
for(let i=0;i<roots.length;i++){
  const root=roots[i],selected=i===0?'Taego':'Joy';
  mark(root);root.resize(402,934);root.clipsContent=true;root.fills=[solid('#fff2dc')];
  // The original source has jade visible in the narrow portrait gutter below402.
  // Continue the approved composed median with native paint; keep the WHOLE jade
  // image402square, avoiding a cropped or nonuniformly stretched texture.
  const continuation=rect(root,'Material / jade continuation',0,0,402,526);continuation.fills=[solid('#06523e')];root.insertChild(0,continuation);mark(root);
  const jade=need(root,'Generated jade');box(jade,0,0,402,402);jade.fills=[{type:'IMAGE',imageHash:CONFIG.jade,scaleMode:'FIT'}];root.insertChild(1,jade);
  const glaze=rect(root,'Material / jade glaze60',0,0,402,402);glaze.fills=[solid('#094838',.60)];root.insertChild(2,glaze);
  // Whole paper retains its948:1660ratio. Its top is occluded by the header;
  // footer and corner flowers remain visible with no image crop or stretch.
  const paper=need(root,'Generated paper and footer'),paperH=402*1660/948;
  box(paper,0,934-paperH,402,paperH);paper.fills=[{type:'IMAGE',imageHash:CONFIG.paper,scaleMode:'FIT'}];root.insertChild(0,paper);
  // Put the jade continuation back above paper so it ends exactly at the portraits.
  root.insertChild(1,continuation);root.insertChild(2,jade);root.insertChild(3,glaze);
  const brand=text(need(root,'Brand'),'EINLEITUNG',70,61,210,22,'Noto Serif','Regular',15,22,'#f8df99');brand.letterSpacing={unit:'PIXELS',value:2.8};
  text(need(root,'Progress'),'07/07',318,58,66,27,'Noto Serif','Regular',21,27,'#fff0bd','RIGHT');
  const title=text(need(root,'Title'),'Ein Freund\nan deiner Seite.',20,140,280,78,'Roboto','Bold',36,37,'#fffaf0');
  title.setRangeLetterSpacing(0,10,{unit:'PIXELS',value:.4});title.setRangeLetterSpacing(11,title.characters.length,{unit:'PIXELS',value:-.15});
  title.effects=[shadow('#00392e',.30,0,1.0,.35)];
  const markNode=need(root,'Generated cloud mark');box(markNode,15,43,55,55);markNode.fills=[{type:'IMAGE',imageHash:CONFIG.cloud,scaleMode:'FIT'}];
  for(let j=0;j<7;j++){
    const step=need(root,'Step '+(j+1));box(step,72+35.2*j,96,16,16);step.fills=[];step.strokes=[solid('#e9ca80')];step.strokeWeight=1.05;
    step.effects=[shadow('#002e26',.85,.3,1.1,.3)];step.visible=j!==6;
  }
  imageRect(root,'Step 7 · supplied metal',CONFIG.blankMedal,281.5,94.3,19.4,19.4);
  for(const [person,x,w] of [['Taego',7,195],['Joy',210,188]]){
    const card=need(root,'Choose '+person);box(card,x,236,w,360);card.cornerRadius=16;card.clipsContent=false;
    card.fills=[solid('#fff6e7',.80)];card.strokes=[solid('#f5e5cf')];card.strokeWeight=.65;card.strokeAlign='INSIDE';card.effects=[shadow('#967b53',.18,0,1.5,1.0)];
    const portrait=need(card,'New generated close portrait');
    box(portrait,person==='Taego'?3:0,3,person==='Taego'?190:188,285);portrait.cornerRadius=15;
    if(CONFIG.taegoReplacementHash&&person==='Taego')portrait.fills=[{type:'IMAGE',imageHash:CONFIG.taegoReplacementHash,scaleMode:'FIT'}];
    else portrait.fills=portrait.fills.map(f=>f.type==='IMAGE'?{...f,scaleMode:'FIT'}:f);
    text(need(card,'Name'),person,3,294,w-6,34,'Roboto Condensed','Bold',26,34,'#09121a','CENTER');
    const role=person==='Taego'?'Dein ruhiger Begleiter':'Deine neugierige Begleiterin';
    // Source optical sizes differ: long Joy line is narrower, without raster scaling.
    text(need(card,'Role'),role,4,325,w-8,26,'Roboto Condensed','Regular',person==='Taego'?17.5:15,26,'#164e68','CENTER');
    selectedRim(card,w,288,person===selected);suppliedCheck(card,person,person===selected);
    // Keep editable labels above the transparent PNG padding.
    card.appendChild(need(card,'Name'));card.appendChild(need(card,'Role'));mark(card);
  }
  const gye=need(root,'Gye reading');box(gye,12,605,378,156);gye.cornerRadius=14;gye.clipsContent=true;
  gye.fills=[solid('#fff6e7',.60)];gye.strokes=[solid('#fff9e9')];gye.strokeWeight=1;gye.effects=[shadow('#967b53',.24,0,1.4,1.1)];
  // Whole1536x1024scene: preserve its ratio and all characters/vase/books.
  const scene=need(gye,'Generated reading scene');box(scene,0,6.667,214,142.667);scene.cornerRadius=12;scene.fills=scene.fills.map(f=>f.type==='IMAGE'?{...f,scaleMode:'FIT'}:f);
  text(need(gye,'Gye title'),'Auch gemeinsam: Gye',222,44,156,24,'Roboto Condensed','Bold',17,24,'#111820');
  const body=text(need(gye,'Gye body'),'Finde später deine Lerngruppe.\nDu kannst alleine starten.',223,67,155,44,'Roboto Condensed','Regular',12.5,20,'#10252b');
  const second=body.characters.indexOf('\n')+1;body.setRangeFills(second,body.characters.length,[solid('#164e68')]);
  const cta=root.children.find(n=>n.type==='INSTANCE'&&n.children.some(c=>c.name==='Label'));
  mark(cta);cta.swapComponent(gold);cta.name='Einleitung / Brass CTA / Reference v2';box(cta,16,772,370,58);cta.clipsContent=false;
  const ctaLabel=need(cta,'Label');mark(ctaLabel);ctaLabel.characters='Mit '+selected+' beginnen';
  need(cta,'Label').effects=[shadow('#ffe7a4',.38,0,.65,0)];
  const back=root.children.find(n=>n.type==='TEXT'&&n.characters==='Zurück');if(!back)throw new Error('Back label missing');
  text(back,'Zurück',140,823,122,48,'Roboto Condensed','Regular',18,24,'#101b1b','CENTER');
  // Reuse the complete approved plum ornament, transposed natively. This aligns
  // the stem to the right and larger bloom at the top without cutting the asset.
  const branch=imageRect(root,'Material / upper right whole plum',CONFIG.plum,0,0,215,215*866/1816);
  branch.relativeTransform=[[0,1,291],[1,0,105]];mark(branch);
  rootReport.push({id:root.id,selected,cardRects:[[7,236,195,360],[210,236,188,360]],gye:[12,605,378,156],ctaHit:[16,772,370,58],checkVisible:[selected==='Taego'?18:342,475,46,46*902/908]});
}
if(!CONFIG.taegoReplacementHash)warnings.push('Taego portrait still contains the rejected broad diagonal sash. Root must provide the reviewed minimal replacement hash. Geometry can be reviewed now; art approval remains pending.');

if(CONFIG.applyWelcome){
  mark(welcome);welcome.resize(CONFIG.welcomeWidth,CONFIG.welcomeHeight);welcome.clipsContent=true;
  welcome.fills=[{type:'IMAGE',imageHash:CONFIG.welcomeScene,scaleMode:'FIT'}];
  text(need(welcome,'Brand'),'HANGUL SORI',100,40,202,18,'Noto Serif','Regular',12,18,'#f5d18a','CENTER').letterSpacing={unit:'PIXELS',value:1.7};
  text(need(welcome,'Title'),'Willkommen bei\nHangul Sori.',65,69,272,68,'Lora','SemiBold',28,30.5,'#fff2d5','CENTER');
  const body=welcome.children.find(n=>n.type==='TEXT'&&n.characters.startsWith('Entdecke Koreanisch'));
  if(!body)throw new Error('Welcome body missing');
  text(body,'Entdecke Koreanisch, Kultur und\ndein wachsendes Hanok-Abenteuer.',75,139,252,33,'Roboto','Regular',12.5,16,'#dce5df','CENTER');
  // Native stroked cloud ornament; complete paths, not raster source fragments.
  const cloudPath='M 8 36 L 30 36 C 32 27 38 23 43 24 C 44 11 55 3 67 4 C 80 4 86 11 89 20 C 101 17 112 25 112 36 L 128 36 C 137 36 137 44 128 44 L 109 44 C 105 55 91 60 80 55 C 70 62 54 59 47 52 C 39 55 31 51 29 44 L 8 44 C 0 44 0 36 8 36 Z M 67 20 C 58 15 51 21 53 29 C 55 36 64 35 65 29 C 66 25 63 24 61 25 M 45 34 C 34 30 31 42 39 47 C 47 52 56 44 53 38 M 85 29 C 96 24 104 33 100 41 C 96 48 85 45 86 38 C 86 34 90 33 93 35';
  nativeVector(welcome,'Material / welcome cloud mark',cloudPath,172,14.5,58,25,solid('#d8b777'),.9);
  function partialCloud(name,x,y,w,h,dx,dy,cw,ch){
    let f=direct(welcome,name);if(!f){f=figma.createFrame();welcome.appendChild(f);f.name=name;created.add(f.id);mark(welcome);}
    box(f,x,y,w,h);f.fills=[];f.strokes=[];f.clipsContent=true;
    nativeVector(f,'Whole outline',cloudPath,dx,dy,cw,ch,solid('#c4aa6e',.75),1.1);return f;
  }
  partialCloud('Material / left welcome cloud',17,20,63,46,-36,0,98,44);
  partialCloud('Material / right welcome cloud',306,45,55,34,0,0,96,43);
  const start=need(welcome,'Start');box(start,84.5,601.5,233,50);start.cornerRadius=25;start.clipsContent=true;
  start.fills=[grad([[0,'#285953'],[.45,'#174d48'],[1,'#113c39']])];
  start.strokes=[grad([[0,'#ffe4a6'],[.5,'#d4af66'],[1,'#edcd8a']])];start.strokeWeight=1.5;start.strokeAlign='INSIDE';
  start.effects=[shadow('#3c2a16',.35,0,1.5,1),shadow('#bfddbf',.14,0,1,.7,'INNER_SHADOW')];
  let label=direct(start,'Start label')||direct(welcome,'Start label');
  if(!label)throw new Error('Welcome start label missing');
  if(label.parent!==start){start.appendChild(label);mark(welcome);mark(start);}
  text(label,'Los geht’s',54,9.5,123,32,'Lora','SemiBold',20,30,'#fff2d5','CENTER');
  nativeVector(start,'Material / start right arrow','M 0 6 L 11.5 6 M 7 1 L 12 6 L 7 11',187,19,13,12,solid('#fff2d5'),1.1);
  const c1=nativeVector(start,'Material / left button cloud',cloudPath,-9,20,58,26,solid('#6e9c84',.2),1.2);
  const c2=nativeVector(start,'Material / right button cloud',cloudPath,193,31,58,26,solid('#6e9c84',.2),1.2);
  start.insertChild(0,c1);start.insertChild(1,c2);mark(start);
  const later=text(need(welcome,'Later'),'Später',151,650,100,48,'Roboto','Regular',12,18,'#e8e5d6','CENTER');later.textDecoration='UNDERLINE';
}
return {
  createdNodeIds:[...created],mutatedNodeIds:[...changed],companionGeometry:rootReport,
  welcomeRect:[402,CONFIG.welcomeHeight],welcomeAspectMode:'SOURCE_941x1672_FULL_SCENE',
  warnings,reactionsChanged:false,previewAdded:false,pngFilesChanged:false,
  approval:'Pending root execution and fresh rendered comparison. Taego art remains pending until replacement hash is supplied. Flutter/device/accessibility validation is separate.',
};
