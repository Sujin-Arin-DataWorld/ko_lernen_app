await figma.setCurrentPageAsync(await figma.getNodeByIdAsync('77:2'));
await figma.loadFontAsync({family:'Roboto',style:'Regular'});await figma.loadFontAsync({family:'Roboto',style:'Bold'});
const created=[],changed=[];
let board=figma.currentPage.children.find(n=>n.name==='Einleitung · First reference comparison · 2026-10-18');
if(!board){board=figma.createFrame();board.name='Einleitung · First reference comparison · 2026-10-18';created.push(board.id);}else{for(const c of [...board.children])c.remove();}
board.x=0;board.y=5100;board.resize(1318,2120);board.fills=[{type:'SOLID',color:{r:.09,g:.12,b:.12}}];board.clipsContent=false;changed.push(board.id);
function label(s,x,y,w,size=16,bold=false){const t=figma.createText();board.appendChild(t);t.name=s;t.fontName={family:'Roboto',style:bold?'Bold':'Regular'};t.fontSize=size;t.characters=s;t.fills=[{type:'SOLID',color:{r:1,g:1,b:1}}];t.x=x;t.y=y;t.resize(w,36);created.push(t.id);return t;}
function ref(parent,hash){const r=figma.createRectangle();parent.appendChild(r);r.name='Full source mockup — REVIEW ONLY, never runtime';r.x=-52*402/748;r.y=-52*402/748;r.resize(853*402/748,1844*402/748);r.fills=[{type:'IMAGE',imageHash:hash,scaleMode:'FIT'}];created.push(r.id);}
function frame(x,y){const f=figma.createFrame();board.appendChild(f);f.x=x;f.y=y;f.resize(402,934);f.fills=[];f.clipsContent=true;created.push(f.id);return f;}
label('01 + level chooser · same 402 × 934 viewport · DE 100%',24,16,1240,22,true);
label('Reference artwork differs from independent generated assets; this is a review candidate.',24,48,1260,16);
for(const [row,id,hash] of [[0,'80:336','733b2e1aa444b6d2f93f00ca750401664bf7d1b4'],[1,'80:569','73f79372cb784a38c146d39425f53528fe419479']]){
 const yy=102+row*1010;
 label('Approved original',24,yy-26,402,16,true);label('Editable Figma candidate',458,yy-26,402,16,true);label('50% overlay · geometry review',892,yy-26,402,16,true);
 const rf=frame(24,yy);rf.name='Original viewport '+row;ref(rf,hash);
 const source=await figma.getNodeByIdAsync(id);const copy=source.clone();board.appendChild(copy);copy.x=458;copy.y=yy;created.push(copy.id);
 const of=frame(892,yy);of.name='Overlay '+row;ref(of,hash);const overlay=source.clone();of.appendChild(overlay);overlay.x=0;overlay.y=0;overlay.opacity=.5;created.push(overlay.id);
}
label('Hardware notch excluded from app implementation. Artwork, texture and exact font identity still require review.',24,2081,1260,14);
figma.viewport.scrollAndZoomIntoView([board]);
return {board:board.id,created,changed};
