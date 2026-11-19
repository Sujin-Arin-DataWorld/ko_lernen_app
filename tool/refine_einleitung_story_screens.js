// Execute with Figma use_figma on rVlcMLvngw07BYJ7nRT87C after loading
// figma-use and figma-generate-design. Prepared by the read-only visual reviewer.
// This script has NOT been executed by its author. No reference screenshot pixels.
// Insert uploaded whole replacement hashes below; null retains the current master
// and returns an explicit unresolved-art gate. See einleitung_story_art_review.json.
const REPLACEMENTS = {
  path: 'c8e657ebabdc70b39bcff13ae4abafe2c2460862',
  soundTextFree: '4a10b1e13b2aa6887c02650eb4214cc9abc808d9',
  games: '526889b1c41b6b2886a7287945d0a428d53bbfb9',
  scholarTextFree: 'b827136fb2c68c79590209253047aa71ac4c1f51',
  hanok: 'b80647032e51874373d2c8da05aa1d8c45104ca7',
  hanokTools: 'ef92b00296b466c3099bc1501d383df4d7bccc45',
};

await figma.setCurrentPageAsync(await figma.getNodeByIdAsync('77:2'));
const changed = new Set(), created = [], pending = [];
const must = async id => {
  const n = await figma.getNodeByIdAsync(id);
  if (!n) throw new Error('Missing inspected node: ' + id);
  return n;
};
const source = await must('80:336');
const specs = [
  { id:'80:380', step:2, art:'path', rect:[0,41,402,603], bottom:644,
    title:[20,138,352,39,40.5], content:[18,667,366], summarySize:23,
    summaryLine:30, bodySize:16.4, bodyLine:23, gap:7, cta:782, back:849,
    labels:[[20,607,116],[143,607,116],[265,607,116]] },
  { id:'80:406', step:3, art:'soundTextFree', rect:[0,0,402,600], bottom:600,
    title:[20,140,352,43,47], content:[18,706,366], summarySize:23.2,
    summaryLine:31, bodySize:19.5, bodyLine:26, gap:2, cta:776, back:847 },
  { id:'80:433', step:4, art:'games', rect:[0,9,402,603], bottom:612,
    title:[20,144,352,37,40.5], content:[30,657,356], summarySize:25.3,
    summaryLine:34, bodySize:17.6, bodyLine:26, gap:9, cta:763, back:834 },
  { id:'80:455', step:5, art:'scholarTextFree', rect:[0,21,402,603], bottom:664,
    title:[20,133,352,40,41], content:[18,677,366], summarySize:24,
    summaryLine:31, bodySize:19.5, bodyLine:25, gap:0, cta:772, back:840,
    labels:[[28,631,112],[145,631,112],[262,631,112]] },
  { id:'80:480', step:6, art:'hanok', rect:[0,43,402,603], bottom:646,
    title:[20,138,352,34,35.5], content:[18,660,366], summarySize:21.5,
    summaryLine:31, bodySize:18.7, bodyLine:25, gap:0, cta:760, back:825,
    labels:[[25,620,116],[144,620,116],[263,620,116]] },
];
const roots = await Promise.all(specs.map(s => must(s.id)));
const find = (root,name) => root.children.find(n => n.name === name);
const fonts = new Map();
for (const root of [source,...roots]) {
  for (const n of root.findAllWithCriteria({types:['TEXT']})) {
    for (const seg of n.getStyledTextSegments(['fontName'])) {
      fonts.set(JSON.stringify(seg.fontName),seg.fontName);
    }
  }
}
const titleSource = find(source,'Title');
const regularSource = find(source,'Can change later');
const boldSource = find(source,'Next hint');
const latinBold = titleSource.fontName;
const latinRegular = regularSource.fontName;
const korean = {family:'Noto Sans KR',style:'Regular'};
const serif = {family:'Lora',style:'Regular'};
for (const f of [latinBold,latinRegular,korean,serif]) fonts.set(JSON.stringify(f),f);
const available = await figma.listAvailableFontsAsync();
for (const f of fonts.values()) {
  if (!available.some(x => x.fontName.family===f.family && x.fontName.style===f.style)) {
    throw new Error('Unavailable required font: ' + JSON.stringify(f));
  }
  await figma.loadFontAsync(f);
}
const cloneValue = v => JSON.parse(JSON.stringify(v));
const ink = cloneValue(boldSource.fills);
const blue = cloneValue(regularSource.fills);
// Use the approved ink token from its actual native field, not the blue hint.
const fieldTitle = source.findOne(n => n.type==='TEXT' && n.name==='Start level');
const inkPaint = fieldTitle ? cloneValue(fieldTitle.fills) : ink;
const reactionSnapshot = new Map();
for (const r of roots) {
  for (const n of [r,...r.findAll(()=>true)]) {
    if ('reactions' in n && n.reactions.length) reactionSnapshot.set(n.id,JSON.stringify(n.reactions));
  }
}
function box(n,x,y,w,h) { n.resize(w,h); n.x=x; n.y=y; changed.add(n.id); }
function type(n,value,x,y,w,size,line,font=latinRegular,paint=inkPaint,align='CENTER') {
  if (!n || n.type!=='TEXT') throw new Error('Expected editable text');
  n.fontName=font; n.characters=value; n.fontSize=size;
  n.lineHeight={unit:'PIXELS',value:line}; n.letterSpacing={unit:'PIXELS',value:0};
  n.textAlignHorizontal=align; n.textAutoResize='NONE'; n.fills=cloneValue(paint);
  // Figma resize after HEIGHT can freeze the node to one line. All inspected
  // copy uses explicit line breaks, so preserve each line's physical height.
  const lineCount=Math.max(1,value.split(/\r\n|\r|\n/).length);
  n.resize(w,Math.max(line*lineCount,1)); n.x=x; n.y=y; changed.add(n.id);
}
function newText(parent,name,value,x,y,w,size,line,font=latinRegular,paint=inkPaint,align='CENTER') {
  let n=find(parent,name);
  if (!n) { n=figma.createText(); parent.appendChild(n); n.name=name; created.push(n.id); }
  type(n,value,x,y,w,size,line,font,paint,align); return n;
}
function layer(parent,name) {
  let n=find(parent,name);
  if (!n) { n=figma.createFrame(); parent.appendChild(n); n.name=name; n.fills=[]; n.clipsContent=false; created.push(n.id); }
  return n;
}
function copyTextStyle(n,src) {
  for (const key of ['fontName','fontSize','lineHeight','letterSpacing','textAlignHorizontal','fills']) {
    n[key]=cloneValue(src[key]);
  }
  box(n,src.x,src.y,src.width,src.height);
}
function whole(n,hash,rect) {
  box(n,...rect);
  n.fills=n.fills.map(p => p.type==='IMAGE' ? {...p,imageHash:hash||p.imageHash,scaleMode:'FIT'} : p);
  changed.add(n.id);
}
const approvedCTA = source.children.find(n => n.type==='INSTANCE' && n.name.includes('Brass CTA'));
if (!approvedCTA || !approvedCTA.mainComponent) throw new Error('Approved v7 CTA unavailable');
const ctaMaster=approvedCTA.mainComponent;
const approvedStep=find(source,'Step 1 · supplied metal');
const approvedJadeGlaze=await must('152:224');
for (let i=0;i<roots.length;i++) {
  const root=roots[i], s=specs[i];
  // Existing action-bearing nodes retain their IDs and reactions.
  const scene=find(root,'Whole generated scene');
  whole(scene,REPLACEMENTS[s.art],s.rect);
  if (!REPLACEMENTS[s.art]) pending.push({screen:s.step,asset:s.art,reason:'Current whole master retained; see bounded image edit brief'});
  const paper=find(root,'Generated paper and footer'), paperSource=find(source,'Generated paper and footer');
  box(paper,paperSource.x,paperSource.y,paperSource.width,paperSource.height);
  paper.fills=cloneValue(paperSource.fills); changed.add(paper.id);
  const jade=find(root,'Generated jade'), jadeSource=find(source,'Generated jade');
  box(jade,0,0,402,402); jade.fills=cloneValue(jadeSource.fills); changed.add(jade.id);
  // Darken only the background behind the whole scene. This removes the bright
  // top strip without painting a glaze over characters, props or learner content.
  let glaze=find(root,'Story jade glaze behind scene');
  if(!glaze){glaze=figma.createRectangle();root.appendChild(glaze);glaze.name='Story jade glaze behind scene';created.push(glaze.id);}
  box(glaze,0,0,402,402);glaze.fills=cloneValue(approvedJadeGlaze.fills);
  glaze.opacity=approvedJadeGlaze.opacity;glaze.blendMode=approvedJadeGlaze.blendMode;
  root.insertChild(root.children.indexOf(scene),glaze);
  copyTextStyle(find(root,'Brand'),find(source,'Brand'));
  copyTextStyle(find(root,'Progress'),find(source,'Progress'));
  const mark=find(root,'Generated cloud mark'), markSource=find(source,'Generated cloud mark');
  box(mark,markSource.x,markSource.y,markSource.width,markSource.height);
  mark.fills=cloneValue(markSource.fills); changed.add(mark.id);
  for (let j=1;j<=7;j++) {
    const n=find(root,'Step '+j), src=find(source,'Step '+j);
    if (!n || !src) continue;
    box(n,src.x,src.y,src.width,src.height);
    const inactiveStyle=j===1 ? find(source,'Step 2') : src;
    n.visible=true;n.fills=cloneValue(inactiveStyle.fills);
    n.strokes=cloneValue(inactiveStyle.strokes);n.strokeWeight=inactiveStyle.strokeWeight;
  }
  let active=find(root,'Active progress · approved metal');
  if (!active) { active=approvedStep.clone(); root.appendChild(active); active.name='Active progress · approved metal'; created.push(active.id); }
  box(active,approvedStep.x+(s.step-1)*35.2,approvedStep.y,approvedStep.width,approvedStep.height);
  const t=find(root,'Title'), [tx,ty,tw,ts,tl]=s.title;
  type(t,t.characters,tx,ty,tw,ts,tl,latinBold,titleSource.fills,'LEFT');
  if (s.step===3) t.letterSpacing={unit:'PIXELS',value:1.3};
  if (s.step===6) t.letterSpacing={unit:'PIXELS',value:.35};
  const content=find(root,'Native content');
  content.layoutMode='VERTICAL'; content.primaryAxisSizingMode='AUTO'; content.counterAxisSizingMode='FIXED';
  content.itemSpacing=s.gap; content.paddingTop=0; content.paddingBottom=0; content.paddingLeft=0; content.paddingRight=0;
  box(content,...s.content,1); content.primaryAxisSizingMode='AUTO';
  const summary=find(content,'Summary'), desc=find(content,'Description');
  type(summary,summary.characters,0,0,s.content[2],s.summarySize,s.summaryLine,latinBold,inkPaint,s.step===4?'LEFT':'CENTER');
  type(desc,desc.characters,0,0,s.content[2],s.bodySize,s.bodyLine,latinRegular,blue,s.step===4?'LEFT':'CENTER');
  if (s.step===2) {
    const split=summary.characters.indexOf('\n');
    summary.setRangeFontSize(split+1,summary.characters.length,20.5);
    const hint=find(content,'Next hint');
    type(hint,hint.characters,0,0,s.content[2],14.5,20,latinRegular,inkPaint);
    // 60 +7 +23 +0 +20 =110px. Keep the last helper above the CTA at782.
    content.itemSpacing=4;
  }
  const next=root.children.find(n => n.type==='INSTANCE' && n.findOne(c=>c.type==='TEXT'&&c.name==='Label'&&c.characters==='Weiter'));
  if (!next) throw new Error('Existing Weiter action unavailable on '+s.id);
  next.swapComponent(ctaMaster); box(next,16,s.cta,370,58);
  const label=next.findOne(n=>n.type==='TEXT'&&n.name==='Label');
  // The approved instance supplies typography and layout. Do not write child transforms.
  label.characters='Weiter'; changed.add(label.id);
  const back=find(root,'Back'); type(back,'Zurück',140,s.back,122,20,28,latinRegular,blue);
  // Keep the original Back text node/action, and expand its hit rectangle vertically.
  back.textAutoResize='NONE'; back.resize(122,48); back.textAlignVertical='TOP'; changed.add(back.id);
  if (s.labels) for(let j=0;j<3;j++) {
    const n=find(root,'Scene label '+j), [x,y,w]=s.labels[j];
    type(n,n.characters,x,y,w,17.5,24,latinBold,titleSource.fills);
  }
  // Vorschau is owned by the other task: no movement, restyling, rewiring or removal.
}

// 03: a full text-free generated scene supplies the tactile tile and paper surfaces;
// all learner-facing Hangul and transcription are native text. No painted text mask.
const sound=roots[1], soundLayer=layer(sound,'Native Hangul learning content');
box(soundLayer,0,0,402,600); soundLayer.visible=!!REPLACEMENTS.soundTextFree;
// Match the actual blank faces in dd1e7576 at whole FIT 402x600. The edited
// physical tiles remain 14-19px above the approximate reference landmarks.
const tileSpecs=[['Consonant','ㄱ',32,377,69,77,54],['Vowel','ㅏ',125,375,65,77,54],['Syllable','가',246,337,124,130,98]];
const jadePaint=[{type:'SOLID',color:{r:.025,g:.29,b:.25}}];
for (const [name,value,x,y,w,h,size] of tileSpecs) {
  const slot=layer(soundLayer,name+' native slot'); box(slot,x,y,w,h);
  slot.layoutMode='VERTICAL'; slot.primaryAxisSizingMode='FIXED'; slot.counterAxisSizingMode='FIXED';
  slot.primaryAxisAlignItems='CENTER'; slot.counterAxisAlignItems='CENTER';
  const glyph=newText(slot,name,value,0,0,w,size,size*1.05,korean,jadePaint);
  glyph.layoutSizingHorizontal='FIXED';
}
const goldPaint=[{type:'SOLID',color:{r:1,g:.9,b:.63}}];
newText(soundLayer,'Combine plus','+',103,399,25,37,44,latinBold,goldPaint);
newText(soundLayer,'Combine equals','=',206,399,29,37,44,latinBold,goldPaint);
const reading=newText(soundLayer,'Syllable and romanization','가 · ga',104,511,196,40,52,korean,inkPaint);
reading.setRangeFontName(1,reading.characters.length,serif);
const speaker=find(sound,'Speaker');
// Whole 1312x1199 alpha master bbox [198,207,1120,1047], width137 at target.
const speakerScale=137/922;
box(speaker,32-198*speakerScale,566-207*speakerScale,1312*speakerScale,1199*speakerScale);
speaker.fills=speaker.fills.map(p=>p.type==='IMAGE'?{...p,scaleMode:'FIT'}:p);
const listen=await must('82:41'); box(listen,182,608,190,58);
const listenSurface=find(listen,'Whole generated brass surface');
box(listenSurface,0,0,190,58); listenSurface.cornerRadius=12;
listenSurface.fills=[{type:'GRADIENT_LINEAR',gradientTransform:[[0,1,0],[-1,0,1]],gradientStops:[
  {position:0,color:{r:1,g:.79,b:.37,a:1}},
  {position:.46,color:{r:.93,g:.67,b:.28,a:1}},
  {position:1,color:{r:.68,g:.41,b:.12,a:1}},
]}];
listenSurface.strokes=[{type:'SOLID',color:{r:.56,g:.32,b:.09}}];
listenSurface.strokeWeight=1.2;listenSurface.strokeAlign='INSIDE';
listenSurface.effects=[
  {type:'INNER_SHADOW',color:{r:1,g:.93,b:.69,a:.9},offset:{x:0,y:1.5},radius:1,spread:0,visible:true,blendMode:'NORMAL'},
  {type:'INNER_SHADOW',color:{r:.30,g:.15,b:.03,a:.45},offset:{x:0,y:-2},radius:1.5,spread:0,visible:true,blendMode:'NORMAL'},
  {type:'DROP_SHADOW',color:{r:.25,g:.13,b:.03,a:.3},offset:{x:0,y:3},radius:2,spread:0,visible:true,blendMode:'NORMAL'},
];
type(find(listen,'Label'),'Anhören',6,13,178,23,30,latinBold);
const oldArrow=find(listen,'Arrow'); if(oldArrow){oldArrow.visible=false;changed.add(oldArrow.id);}
if (!listen.reactions.length) pending.push({screen:3,control:listen.id,reason:'No audio reaction existed in inspected Figma; flow owner must supply actual playback behavior'});

// 05: preserve the face, fan, open book and whole ornament strip. Native teaching
// copy becomes visible only after the bounded text-free replacement is supplied.
const scholar=roots[3], tools=await must('90:40'); whole(tools,null,[14,545,374,125]);
const card=layer(scholar,'Native example card content'); box(card,77,286,138,121); card.rotation=8.5;
card.visible=!!REPLACEMENTS.scholarTextFree;
card.layoutMode='VERTICAL'; card.primaryAxisSizingMode='FIXED';card.counterAxisSizingMode='FIXED';card.itemSpacing=3;
newText(card,'Example label','Beispiel',0,0,138,12.5,20,latinBold,inkPaint,'LEFT');
newText(card,'Korean greeting','안녕하세요',0,0,138,26,38,korean);
newText(card,'Romanized greeting','annyeonghaseyo',0,0,138,11.5,19,latinRegular);
newText(card,'German greeting','Guten Tag',0,0,138,17,24,latinBold);
const pageText=layer(scholar,'Native open book greeting'); box(pageText,84,476,144,36);pageText.rotation=5;
pageText.visible=!!REPLACEMENTS.scholarTextFree;
newText(pageText,'Book Korean greeting','안녕하세요',0,0,144,25,35,korean);

// 06: the current three-symbol strip is too large within its canvas. The replacement
// keeps the full transparent strip and deliberately shrinks each icon in place.
const hanokTools=await must('90:41'); whole(hanokTools,REPLACEMENTS.hanokTools,[3.122533918,527,397.091950497,132.363983499]);
if(!REPLACEMENTS.hanokTools)pending.push({screen:6,asset:'hanokTools',reason:'Full strip retained; internal icon size/spacing edit remains required'});

const actionChanges=[];
for (const [id,old] of reactionSnapshot) {
  const n=await must(id);
  if(JSON.stringify(n.reactions)!==old) actionChanges.push(id);
}
if(actionChanges.length)throw new Error('Prototype reactions changed unexpectedly: '+actionChanges.join(','));
return {
  mutatedNodeIds:[...changed],createdNodeIds:created,prototypeReactionsChanged:false,
  sourceV7Mutated:false,previewScopeTouched:false,
  frames:roots.map((r,i)=>({id:r.id,artBottom:specs[i].bottom,ctaTop:specs[i].cta,backInkTarget:specs[i].back+6})),
  pending,approval:'Requires one post-execution full-render review; current source/brief review is not static approval',
};
