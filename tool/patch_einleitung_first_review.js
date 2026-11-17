await figma.setCurrentPageAsync(await figma.getNodeByIdAsync('77:2'));
const changed=new Set(),created=new Set(),removed=[];
const mark=n=>(changed.add(n.id),n);
const rgb=h=>({r:parseInt(h.slice(0,2),16)/255,g:parseInt(h.slice(2,4),16)/255,b:parseInt(h.slice(4,6),16)/255});
const solid=h=>[{type:'SOLID',color:rgb(h)}];
const H={paper:'9c1da78ad1199554039254fde096607ed0ed75ee',gold:'2101804632e35fa2b55261051fc7fa5563e40462',a2:'b01afd3772581121d06e6d549f80e66dd00c7090',check:'9d1d4c06ecef94534d268af293dd33ee961cb7de',travel:'473374dedb02792bd6a15a734c76fbf402dd67b6',culture:'024af3b1dc52eb2b8de1e519572a8b31cceb90af',study:'911597566fd64fbbee0cb02a6535114e0db7ed9d',kcontent:'cbf12aa6e5781f7a6f4b0e70339dc361e0910c32'};
for(const family of ['Noto Sans','Noto Sans KR','Noto Serif','Roboto'])for(const style of ['Regular','Bold'])await figma.loadFontAsync({family,style});
const get=id=>figma.getNodeByIdAsync(id);
function box(n,x,y,w,h){mark(n);n.x=x;n.y=y;n.resize(w,h);}
function tx(n,x,y,w,h,size,family='Noto Sans',style='Regular',color='071c21',align='LEFT'){box(n,x,y,w,h);n.fontName={family,style};n.fontSize=size;n.textAutoResize='NONE';n.lineHeight={unit:'PIXELS',value:h};n.textAlignHorizontal=align;n.textAlignVertical='CENTER';n.fills=solid(color);n.letterSpacing={unit:'PIXELS',value:0};}
function image(parent,name,hash,x,y,w,h,mode='FIT'){let n=parent.children.find(c=>c.name===name);if(!n){n=figma.createRectangle();parent.appendChild(n);n.name=name;created.add(n.id);}box(n,x,y,w,h);n.fills=[{type:'IMAGE',imageHash:hash,scaleMode:mode}];n.strokes=[];return n;}
function remove(n){removed.push(n.id);n.remove();}
function named(p,name){return p.children.find(c=>c.name===name);}
const shadow=[{type:'DROP_SHADOW',color:{r:.27,g:.16,b:.05,a:.22},offset:{x:0,y:2},radius:2,visible:true,blendMode:'NORMAL'}];
const setup=await get('80:336');
const modal=await get('80:569');
for(const root of [setup,modal]){
 const paper=named(root,'Setup paper');const title=root.children.find(c=>c.type==='TEXT'&&c.characters.includes('Dein Koreanisch.'));
 tx(title,20,141,282,78,30,'Noto Sans','Bold','fffaf0');title.lineHeight={unit:'PIXELS',value:35.5};
 const tiger=root.children.find(c=>c.name.includes('Taego')&&c.type!=='TEXT');if(tiger)box(tiger,217,94,199,299);
 const footer=root.children.find(c=>c.name.toLowerCase().includes('paper')&&c!==paper);if(footer){box(footer,0,307,402,627);footer.fills=[{type:'IMAGE',imageHash:H.paper,scaleMode:'FILL'}];}
 box(paper,0,307,402,511);paper.fills=[];paper.clipsContent=false;
 const paperBg=image(paper,'Hanji surface — independently generated',H.paper,0,0,402,627,'FILL');paperBg.topLeftRadius=26;paperBg.topRightRadius=26;paper.insertChild(0,paperBg);
 tx(named(paper,'Start level'),20,13,362,34,27,'Noto Sans','Bold');
 const field=named(paper,'Change level');box(field,16,52,370,74);field.fills=solid('fff8ec');field.strokes=solid('005449');field.strokeWeight=3;field.cornerRadius=15;field.effects=shadow;
 for(const n of [...field.children])if(n.name==='Medal value'||n.type==='ELLIPSE')remove(n);
 image(field,'A2 — generated embossed metal',H.a2,15.2,3.1,67.85,67.85);
 tx(named(field,'Level code'),94,8,96,31,29,'Noto Sans','Bold');
 tx(named(field,'Hint'),94,40,174,23,14.5,'Noto Sans','Regular','174b64');
 const action=named(field,'Change action');box(action,267,13,94,48);action.cornerRadius=19;action.fills=solid('005449');action.strokes=solid('d5a244');action.strokeWeight=1.1;
 tx(named(action,'Change label'),3,10,88,28,17,'Noto Sans','Regular','fffaf0','CENTER');
 tx(named(paper,'Range'),16,134,370,22,16,'Noto Sans','Regular','174b64','CENTER');
 tx(named(paper,'Interest heading'),20,165,362,31,24,'Noto Sans','Bold');
 const keys=['travel','culture','study','kcontent'];
 const cards=paper.children.filter(c=>c.type==='FRAME'&&c.name.startsWith('Interest '));
 for(let i=0;i<cards.length;i++){const c=cards[i];const y=i<2?197:329;const hh=i<2?125:120;box(c,i%2?207:16,y,180,hh);c.cornerRadius=13;c.clipsContent=true;c.fills=solid('fff5e8');c.strokes=solid('ffffff');c.strokeWeight=1.3;c.effects=shadow;
 const art=c.children.find(n=>n.type==='RECTANGLE');box(art,1,1,178,hh-29);art.fills=[{type:'IMAGE',imageHash:H[keys[i]],scaleMode:'FILL'}];art.topLeftRadius=12;art.topRightRadius=12;art.bottomLeftRadius=7;art.bottomRightRadius=7;
 const label=c.children.find(n=>n.type==='TEXT');tx(label,1,hh-28,178,24,17,'Noto Sans','Bold','071c21','CENTER');}
 tx(root.children.find(c=>c.type==='TEXT'&&c.characters==='Du kannst das später ändern.'),20,770,362,23,16,'Noto Sans','Regular','174b64','CENTER');
 tx(root.children.find(c=>c.type==='TEXT'&&c.characters.startsWith('Als Nächstes:')),20,793,362,22,15,'Noto Sans','Bold','174b64','CENTER');
 const brand=root.children.find(c=>c.type==='TEXT'&&c.characters==='EINLEITUNG');tx(brand,70,61,210,22,15,'Noto Serif','Regular','f8df99');brand.letterSpacing={unit:'PIXELS',value:2.8};
 const progress=root.children.find(c=>c.type==='TEXT'&&c.characters.includes('01/07'));tx(progress,318,58,66,27,21,'Noto Serif','Regular','fff0bd','RIGHT');
 const dots=root.children.filter(c=>c.type==='ELLIPSE');dots.forEach((n,i)=>box(n,72+i*35.2,96,16,16));
}
const sheet=await get('80:611');box(sheet,0,414,402,520);sheet.fills=solid('fff8ec');sheet.topLeftRadius=28;sheet.topRightRadius=28;sheet.clipsContent=true;
const bg=image(sheet,'Hanji sheet — independently generated',H.paper,0,0,402,520,'FILL');bg.topLeftRadius=28;bg.topRightRadius=28;sheet.insertChild(0,bg);
let handle=named(sheet,'Sheet handle');if(!handle){handle=figma.createRectangle();sheet.appendChild(handle);handle.name='Sheet handle';created.add(handle.id);}box(handle,178,15,46,5);handle.cornerRadius=3;handle.fills=solid('b99871');
tx(await get('80:612'),16,30,300,35,28,'Noto Sans','Bold');
tx(await get('80:613'),321,38,65,23,16,'Noto Sans','Regular','174b64','RIGHT');
const beginner=await get('80:614');box(beginner,16,80,370,66);beginner.fills=solid('fff8ec');beginner.strokes=solid('cbbca4');beginner.strokeWeight=.8;beginner.cornerRadius=13;beginner.effects=shadow;
tx(await get('80:615'),14,9,342,28,23,'Noto Sans','Bold','071c21','CENTER');tx(await get('80:616'),14,38,342,22,16,'Noto Sans','Regular','174b64','CENTER');
for(let i=0;i<6;i++){const c=await get(['80:617','80:621','80:625','80:629','80:633','80:637'][i]);box(c,i%2?207:16,161+Math.floor(i/2)*76,180,64);c.cornerRadius=12;c.fills=solid(i===1?'f4eed9':'fff8ec');c.strokes=solid(i===1?'005449':'d6a85d');c.strokeWeight=i===1?4:1.2;c.effects=shadow;
for(const n of [...c.children])if(n.type==='ELLIPSE'||n.name==='Medal value')remove(n);
const label=named(c,'Level name');tx(label,2,6,176,50,34,'Noto Serif','Bold','071c21','CENTER');
if(i===1){let inset=named(c,'Selected gold inset');if(!inset){inset=figma.createRectangle();c.appendChild(inset);inset.name='Selected gold inset';created.add(inset.id);}box(inset,4,4,172,56);inset.cornerRadius=8;inset.fills=[];inset.strokes=solid('d6ad58');inset.strokeWeight=.8;image(c,'Approved check — original user asset',H.check,123.6,8.6,46.96,46.96);}
}
tx(await get('80:641'),16,396,370,25,16,'Noto Sans','Regular','174b64','CENTER');
let component=figma.currentPage.children.find(c=>c.type==='COMPONENT'&&c.name==='Einleitung / Brass CTA / Reference v2');
if(!component){component=figma.createComponent();component.name='Einleitung / Brass CTA / Reference v2';created.add(component.id);}box(component,450,1850,370,58);component.fills=[];component.clipsContent=false;
const art=image(component,'Whole independent gold asset',H.gold,-15.3,-37.8,400.6,133.53);
let label=named(component,'Label');if(!label){label=figma.createText();component.appendChild(label);label.name='Label';created.add(label.id);}tx(label,16,5,338,43,23,'Noto Sans','Bold','071c21','CENTER');label.characters='Weiter';
let arrow=named(component,'Arrow');if(!arrow){arrow=figma.createText();component.appendChild(arrow);arrow.name='Arrow';created.add(arrow.id);}tx(arrow,331,4,23,43,32,'Noto Sans','Regular','071c21','CENTER');arrow.characters='›';
for(const [parent,oldName,x,y,text,showArrow] of [[setup,'Einleitung / Brass CTA',16,849,'Weiter',true],[modal,'Einleitung / Brass CTA',16,849,'Weiter',true],[sheet,'Einleitung / Brass CTA',16,429,'Niveau übernehmen',false]]){
let old=parent.children.find(c=>c.name===oldName||c.name==='Einleitung / Brass CTA / Reference v2'||c.name==='Apply level · native editable');const reactions=old?.reactions;const instance=component.createInstance();parent.appendChild(instance);created.add(instance.id);box(instance,x,y,370,58);const t=named(instance,'Label');mark(t);t.characters=text;const a=named(instance,'Arrow');mark(a);a.visible=showArrow;if(reactions?.length)await instance.setReactionsAsync(reactions);if(old)remove(old);
}
for(let i=38;i<=48;i++){const n=await get('101:'+i);box(n,(i-38)*430,4350,400,300);n.fills=n.fills.map(f=>f.type==='IMAGE'?{...f,scaleMode:'FIT'}:f);}
figma.viewport.scrollAndZoomIntoView([setup,modal]);
return {changed:[...changed],created:[...created],removed,setup:setup.id,modal:modal.id,cta:component.id};
