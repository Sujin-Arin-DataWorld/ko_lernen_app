await figma.setCurrentPageAsync(await figma.getNodeByIdAsync('77:2'));
const page=figma.currentPage,created=[],changed=[];
for(const root of page.children.filter(n=>['80:336','80:569','116:328','116:449','116:375','116:523'].includes(n.id)||n.name.startsWith('Einleitung UX7 / Setup /'))){
 const jade=root.children.find(n=>n.name==='Generated jade');if(!jade)continue;
 let glaze=root.children.find(n=>n.name==='Jade glaze · reference luminance');
 if(!glaze){glaze=figma.createRectangle();root.insertChild(root.children.indexOf(jade)+1,glaze);glaze.name='Jade glaze · reference luminance';created.push(glaze.id)}
 glaze.x=0;glaze.y=0;glaze.resize(402,402);glaze.fills=[{type:'SOLID',color:{r:9/255,g:72/255,b:56/255},opacity:.60}];glaze.strokes=[];changed.push(glaze.id);
}
return{createdNodeIds:created,mutatedNodeIds:changed,sourceImageUnchanged:true};
