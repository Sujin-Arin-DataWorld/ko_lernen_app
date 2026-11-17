// Prepared from real Figma Play finding, 2026-10-18. Root executes.
// A full-viewport dim CLOSE reaction receives taps through noninteractive sheet
// content, including the disabled Apply. Limit dismissal hit geometry to the
// visible backdrop above the sheet, while retaining full-viewport dim artwork.
const page = await figma.getNodeByIdAsync('77:2');
if (!page || page.type !== 'PAGE') throw new Error('Missing page77:2');
await figma.setCurrentPageAsync(page);
const levels = ['Beginner','A1','A2','B1','B2','C1','C2','none'];
const overlays = levels.map(level => {
  const all=page.children.filter(n=>n.name==='Einleitung UX7 / Overlay / draft='+level);
  if(all.length!==1) throw new Error('Expected one overlay '+level);
  const overlay=all[0],dim=overlay.children.find(n=>n.name==='Modal dim'),sheet=overlay.children.find(n=>n.name==='Level chooser');
  if(!dim||!sheet||sheet.y<=0) throw new Error('Invalid overlay '+level);
  return {level,overlay,dim,sheet};
});
const created=[],changed=[];
for(const {overlay,dim,sheet} of overlays){
  await dim.setReactionsAsync([]); changed.push(dim.id);
  let hit=overlay.children.find(n=>n.name==='Backdrop dismissal · above sheet only');
  if(!hit){hit=figma.createFrame();overlay.insertChild(overlay.children.indexOf(sheet),hit);hit.name='Backdrop dismissal · above sheet only';created.push(hit.id);}
  hit.x=0;hit.y=0;hit.resize(overlay.width,sheet.y);hit.fills=[];hit.strokes=[];
  await hit.setReactionsAsync([{trigger:{type:'ON_CLICK'},actions:[{type:'CLOSE'}]}]);
  changed.push(hit.id);
}
return {createdNodeIds:created,mutatedNodeIds:changed,
  hitRegions:overlays.map(({level,overlay,sheet})=>({level,overlay:overlay.id,x:0,y:0,width:overlay.width,height:sheet.y})),
  acceptance:[
    'Tap disabled Apply in null overlay: stays open, no draft selected.',
    'Tap title, explanatory text and gaps inside sheet: stays open.',
    'Tap visible dim above sheet: closes without committing.',
    'Draft/cancel/apply and purpose preservation still pass after replay.',
  ],
  replay:'Run after the level and entry/return scripts; those original scripts still own initial dim reactions.',
};
