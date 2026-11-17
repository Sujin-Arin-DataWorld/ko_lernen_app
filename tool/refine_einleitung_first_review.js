await figma.setCurrentPageAsync(await figma.getNodeByIdAsync('77:2'));
for(const family of ['Noto Sans','Noto Sans KR','Roboto','Noto Serif'])for(const style of ['Regular','Bold'])await figma.loadFontAsync({family,style});
const changed=[],created=[],removed=[];
const paperHash='9c1da78ad1199554039254fde096607ed0ed75ee';
for(const id of ['80:336','80:569']){
 const root=await figma.getNodeByIdAsync(id);
 for(const t of root.findAll(n=>n.type==='TEXT'&&n.fontName.family==='Noto Sans')){t.fontName={family:'Roboto',style:t.fontName.style};changed.push(t.id);}
 const title=root.children.find(n=>n.type==='TEXT'&&n.name==='Title');title.fontSize=31.5;title.x=20;title.y=141;title.resize(274,78);changed.push(title.id);
 const tiger=root.children.find(n=>n.name==='Taego header');tiger.x=242;tiger.y=101;tiger.resize(184,276);changed.push(tiger.id);
 const hint=root.findAll(n=>n.name==='Hint')[0];hint.resize(190,23);hint.fontSize=14.5;hint.x=94;changed.push(hint.id);
 const action=root.findAll(n=>n.name==='Change label')[0];action.characters='Ändern ⌄';changed.push(action.id);
 const field=root.findAll(n=>n.name==='Change level')[0];field.fills=[{type:'IMAGE',imageHash:paperHash,scaleMode:'FILL'}];changed.push(field.id);
 let inset=field.children.find(n=>n.name==='Gold inner edge');
 if(!inset){inset=figma.createRectangle();field.appendChild(inset);inset.name='Gold inner edge';created.push(inset.id);}inset.x=2;inset.y=2;inset.resize(366,70);inset.cornerRadius=13;inset.fills=[];inset.strokes=[{type:'SOLID',color:{r:.84,g:.68,b:.35}}];inset.strokeWeight=.8;changed.push(inset.id);
 const cloud=root.children.find(n=>n.name==='Generated cloud mark');if(cloud){cloud.x=15;cloud.y=43;cloud.resize(55,55);changed.push(cloud.id);}
 const first=root.children.find(n=>n.name==='Step 1');first.fills=[];first.strokes=[];changed.push(first.id);
 let dot=root.children.find(n=>n.name==='Step 1 · supplied metal');
 if(!dot){dot=figma.createRectangle();root.appendChild(dot);dot.name='Step 1 · supplied metal';created.push(dot.id);}dot.x=70.3;dot.y=94.3;dot.resize(19.4,19.4);dot.fills=[{type:'IMAGE',imageHash:'d30e73f22e0a3045cfdebefabc5f542d0d6060ab',scaleMode:'FIT'}];changed.push(dot.id);
 if(id==='80:569'){const dim=root.children.find(n=>n.name==='Modal dim');root.insertChild(root.children.indexOf(dim),dot);if(cloud)root.insertChild(root.children.indexOf(dim),cloud);}
}
const close=await figma.getNodeByIdAsync('80:613');close.fontName={family:'Roboto',style:'Regular'};close.fontSize=15;close.x=307;close.resize(79,23);close.characters='Schließen';changed.push(close.id);
const sheet=await figma.getNodeByIdAsync('80:611');
for(const n of sheet.children.filter(n=>n.name==='Beginner'||n.name.startsWith('Level '))){n.fills=[{type:'SOLID',color:n.name==='Level A2'?{r:.96,g:.94,b:.86}:{r:1,g:.973,b:.925}},{type:'IMAGE',imageHash:paperHash,scaleMode:'FILL',opacity:n.name==='Level A2'?.55:.85}];changed.push(n.id);}
const bg=sheet.children.find(n=>n.name==='Hanji sheet — independently generated');bg.y=-184;bg.resize(402,704);bg.fills=[{type:'IMAGE',imageHash:paperHash,scaleMode:'FIT'}];changed.push(bg.id);
const old=sheet.children.find(n=>n.name.startsWith('Einleitung / Brass CTA')||n.name==='Apply level · native editable');if(old){removed.push(old.id);old.remove();}
const f=figma.createFrame();sheet.appendChild(f);f.name='Apply level · native editable';f.x=16;f.y=429;f.resize(370,58);f.fills=[];f.clipsContent=false;created.push(f.id);
const art=figma.createRectangle();f.appendChild(art);art.name='Whole gold button v2';art.x=-15.3;art.y=-37.8;art.resize(400.6,133.53);art.fills=[{type:'IMAGE',imageHash:'2101804632e35fa2b55261051fc7fa5563e40462',scaleMode:'FIT'}];created.push(art.id);
const t=figma.createText();f.appendChild(t);t.name='Apply label';t.fontName={family:'Roboto',style:'Bold'};t.fontSize=22;t.characters='Niveau übernehmen';t.x=12;t.y=10;t.resize(346,32);t.textAlignHorizontal='CENTER';t.textAlignVertical='CENTER';t.fills=[{type:'SOLID',color:{r:.027,g:.11,b:.13}}];created.push(t.id);
const reaction=[{trigger:{type:'ON_CLICK'},actions:[{type:'NODE',destinationId:'80:336',navigation:'NAVIGATE',transition:{type:'DISSOLVE',duration:.15,easing:{type:'EASE_OUT'}},preserveScrollPosition:false}]}];
await f.setReactionsAsync(reaction);await close.setReactionsAsync(reaction);
const root=await figma.getNodeByIdAsync('80:569');const c=root.children.find(n=>n.name==='Einleitung / Brass CTA / Reference v2');const dim=root.children.find(n=>n.name==='Modal dim');if(c){root.insertChild(root.children.indexOf(dim),c);changed.push(c.id);}changed.push(root.id);
const component=figma.currentPage.children.find(n=>n.type==='COMPONENT'&&n.name==='Einleitung / Brass CTA / Reference v2');const lab=component.children.find(n=>n.name==='Label');lab.fontName={family:'Roboto',style:'Bold'};changed.push(lab.id);
return {changed,created,removed};
