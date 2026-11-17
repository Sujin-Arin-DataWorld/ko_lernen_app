await figma.setCurrentPageAsync(await figma.getNodeByIdAsync('77:2'));
const page=figma.currentPage, changed=new Set(),created=[];
const ids=['80:336','80:569','116:328','116:449','116:375','116:523',...page.children.filter(n=>n.name.startsWith('Einleitung UX7 / Setup /')||n.name.startsWith('Einleitung UX7 / Overlay /')).map(n=>n.id),'127:150'];
const roots=await Promise.all([...new Set(ids)].map(id=>figma.getNodeByIdAsync(id)));
const walk=n=>[n,...('children'in n?n.children.flatMap(walk):[])];
const fonts=new Map();for(const n of roots.flatMap(walk).filter(n=>n.type==='TEXT'))for(const s of n.getStyledTextSegments(['fontName']))fonts.set(JSON.stringify(s.fontName),s.fontName);
for(const f of fonts.values())await figma.loadFontAsync(f);
const oldPaper='9c1da78ad1199554039254fde096607ed0ed75ee';
function paint(n,h,mode='FIT'){n.fills=[{type:'IMAGE',imageHash:h,scaleMode:mode}];changed.add(n.id);}
for(const root of roots){
 if(root.name.includes('Setup')||root.children.some(n=>n.name==='Setup paper')){
  const jade=root.children.find(n=>n.name==='Generated jade');if(jade){jade.resize(402,402);paint(jade,'6f491fecf54b88d71803b6d995449cb0570672cf');}
  const tiger=root.children.find(n=>n.name==='Taego header');if(tiger){paint(tiger,'6461bf85e689c67c0bc35f2ca3a571c09a333072');}
  const branch=root.children.find(n=>n.name==='Plum accent');if(branch){branch.x=-10;branch.y=207;changed.add(branch.id);}
  const title=root.children.find(n=>n.type==='TEXT'&&n.name==='Title');if(title){title.y=138;const i=title.characters.indexOf('Dein Rhythmus.');if(i>=0)title.setRangeLetterSpacing(i,title.characters.length,{unit:'PIXELS',value:.65});changed.add(title.id);}
  if(tiger){let leaves=root.children.find(n=>n.name==='Right foliage · independent whole asset');if(!leaves){leaves=figma.createRectangle();root.insertChild(root.children.indexOf(tiger),leaves);leaves.name='Right foliage · independent whole asset';created.push(leaves.id)}leaves.x=351;leaves.y=101;leaves.resize(70,134);paint(leaves,'ebcc6c152e37c12b1dbd5b1169b3720f6fcee261');}
 }
 for(const n of walk(root)){
  if('fills'in n&&Array.isArray(n.fills)&&n.fills.some(f=>f.type==='IMAGE'&&f.imageHash===oldPaper)){n.fills=n.fills.map(f=>f.type==='IMAGE'&&f.imageHash===oldPaper?{...f,imageHash:'2b04ce49b5b575b4e55d89a0c23d430c9a25cc39'}:f);changed.add(n.id);}
  if(n.name==='Later'&&n.type==='TEXT'){n.y=392;n.fontSize=14.2;n.lineHeight={unit:'PIXELS',value:23};n.resize(370,23);changed.add(n.id);}
 }
 const cards=walk(root).filter(n=>n.type==='FRAME'&&n.name.startsWith('Interest '));
 for(const card of cards){
  // Component instances inherit the updated five master variants.
  if(card.id.startsWith('I'))continue;
  const art=card.children.find(n=>n.name==='Whole generated illustration'&&n.type==='RECTANGLE');if(!art)continue;
  const name=card.name.toLowerCase(),isTravel=name.includes('alltag')||name.includes('life')||name.includes('travel'),isCulture=name.includes('menschen')||name.includes('culture'),isK=name.includes('k-content')||name.includes('kcontent');
  if(isTravel)paint(art,'cdaea86cff293a3304c3f2384567b0b77bb9899a','FILL');
  if(isTravel||isCulture||isK){
   const w=178,h=isK?91:96;let viewport=card.children.find(n=>n.name==='Art viewport · reference framing');
   if(!viewport){viewport=figma.createFrame();card.insertChild(0,viewport);viewport.name='Art viewport · reference framing';viewport.x=1;viewport.y=1;viewport.resize(w,h);viewport.fills=[];viewport.clipsContent=true;viewport.appendChild(art);created.push(viewport.id)}
   const zoom=isTravel?1.08:1.09;art.resize(w*zoom,h*zoom);art.x=isTravel?-2:-(w*(zoom-1))/2;art.y=isTravel?1:-(h*(zoom-1))/2;changed.add(art.id);
  }
 }
}
for(const [i,id] of ['144:182','144:183','144:184','144:185','144:186','144:187'].entries()){const n=await figma.getNodeByIdAsync(id);n.x=4200+i*340;n.y=4750;n.resize(320,300);changed.add(n.id)}
return{mutatedNodeIds:[...changed],createdNodeIds:created,roots:roots.map(n=>n.id),prototypeReactionsChanged:false};
