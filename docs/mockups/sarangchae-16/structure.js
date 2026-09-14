'use strict';

// Shared coordinates for the explanatory mockup. This is not a measured building model.
// Every rafter support is derived from a purlin; each purlin has a strut resting on a beam.
const HANOK_STRUCTURE = (() => {
  const columnTop=430, beamTop=451, purlinDepth=18, rafterRadius=4.5, roofOffset=14.5;
  const mainXs=[0,140,280,420,560,700,840];
  const posts=mainXs.flatMap(x=>[[x,0,105],[x,230,105]])
    .concat([[840,-155,54],[990,-155,54],[1140,-155,54],[1140,230,54],[990,230,54]]);
  const beams=[],purlins=[],struts=[],rafters=[];
  const beam=(id,x,y,z,w,d,h)=>beams.push({id,x,y,z,w,d,h});
  for(const y of [0,230])beam(`main-lintel-${y}`,-17,y-14,406,874,28,26);
  for(const x of mainXs)beam(`main-cross-${x}`,x-11,-14,424,22,258,27);
  for(const x of [840,990,1140])beam(`wing-long-${x}`,x-11,-170,406,22,410,26);
  for(const y of [-155,0,230])beam(`wing-cross-${y}`,826,y-14,424,333,28,27);
  const lerp=(a,b,t)=>a+(b-a)*t;
  const mainRoofZ=y=>y<=115?lerp(464,619,(y+73)/188):lerp(619,463,(y-115)/167);
  const wingRoofZ=x=>x<=990?lerp(486,657,(x-815)/175):lerp(657,482,(x-990)/200);
  for(const y of [0,60,115,175,230]){
    const z=mainRoofZ(y)-roofOffset-rafterRadius-purlinDepth;
    const id=`main-purlin-${y}`;
    purlins.push({id,x:-100,y:y-9,z,w:1050,d:18,h:purlinDepth,axis:'x',coordinate:y});
    for(const x of mainXs)struts.push({id:`support-${id}-${x}`,x:x-9,y:y-9,z:beamTop,w:18,d:18,h:z-beamTop,beamId:`main-cross-${x}`,purlinId:id});
  }
  for(const x of [840,915,990,1065,1140]){
    const z=wingRoofZ(x)-roofOffset-rafterRadius-purlinDepth;
    const id=`wing-purlin-${x}`;
    purlins.push({id,x:x-9,y:-250,z,w:18,d:560,h:purlinDepth,axis:'y',coordinate:x});
    for(const y of [-155,0,230])struts.push({id:`support-${id}-${y}`,x:x-9,y:y-9,z:beamTop,w:18,d:18,h:z-beamTop,beamId:`wing-cross-${y}`,purlinId:id});
  }
  const support=(p,x,y)=>({x,y,z:p.z+p.h+rafterRadius,purlinId:p.id});
  const mainPurlins=purlins.filter(p=>p.axis==='x'),wingPurlins=purlins.filter(p=>p.axis==='y');
  for(let x=-40;x<=870;x+=26){
    rafters.push({id:`main-front-${x}`,points:[{x,y:-73,z:mainRoofZ(-73)-roofOffset},...mainPurlins.filter(p=>p.coordinate<=115).map(p=>support(p,x,p.coordinate))]});
    rafters.push({id:`main-back-${x}`,points:[...mainPurlins.filter(p=>p.coordinate>=115).map(p=>support(p,x,p.coordinate)),{x,y:282,z:mainRoofZ(282)-roofOffset}]});
  }
  for(let y=-195;y<=275;y+=26){
    rafters.push({id:`wing-left-${y}`,points:[{x:815,y,z:wingRoofZ(815)-roofOffset},...wingPurlins.filter(p=>p.coordinate<=990).map(p=>support(p,p.coordinate,y))]});
    rafters.push({id:`wing-right-${y}`,points:[...wingPurlins.filter(p=>p.coordinate>=990).map(p=>support(p,p.coordinate,y)),{x:1190,y,z:wingRoofZ(1190)-roofOffset}]});
  }
  const containsXY=(b,x,y)=>x>=b.x-1e-8&&x<=b.x+b.w+1e-8&&y>=b.y-1e-8&&y<=b.y+b.d+1e-8;
  function validate(){
    const issues=[];let maxGap=0,contacts=0;
    for(const [x,y]of posts){if(!beams.some(b=>containsXY(b,x,y)&&b.z<=columnTop&&b.z+b.h>=columnTop))issues.push(`Unconnected post ${x},${y}`);}
    for(const s of struts){
      const b=beams.find(v=>v.id===s.beamId),p=purlins.find(v=>v.id===s.purlinId),cx=s.x+s.w/2,cy=s.y+s.d/2;
      const gapBelow=Math.abs(s.z-b.z-b.h),gapAbove=Math.abs(s.z+s.h-p.z);maxGap=Math.max(maxGap,gapBelow,gapAbove);
      if(s.h<0||gapBelow>1e-8||gapAbove>1e-8||!containsXY(b,cx,cy)||!containsXY(p,cx,cy))issues.push(`Unconnected strut ${s.id}`);
    }
    for(const r of rafters)for(const point of r.points.filter(p=>p.purlinId)){
      const p=purlins.find(v=>v.id===point.purlinId);const gap=Math.abs(point.z-rafterRadius-(p.z+p.h));maxGap=Math.max(maxGap,gap);contacts++;
      if(gap>1e-8||!containsXY(p,point.x,point.y))issues.push(`Unseated rafter ${r.id} at ${p.id}`);
    }
    return {status:issues.length?'failed':'passed',postCount:posts.length,beamCount:beams.length,purlinCount:purlins.length,strutCount:struts.length,rafterCount:rafters.length,rafterSupportContacts:contacts,maxContactGapInModelUnits:maxGap,issues,scope:'Mockup contact coordinates only; not structural safety, historical accuracy, or full roof-junction clash certification.',roofJunctionStatus:'Requires a measured plan/section and dedicated junction review before final stage artwork.'};
  }
  return {columnTop,beamTop,mainXs,posts,beams,purlins,struts,rafters,rafterRadius,mainRoofZ,wingRoofZ,validate};
})();
