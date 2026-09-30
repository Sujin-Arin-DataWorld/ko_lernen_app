"""Photographic courtyard details with explicit source/interpretation boundaries."""
from pathlib import Path
import bpy,json,math,random,sys
import numpy as np
from mathutils import Vector,Matrix
sys.path.insert(0,str(Path(__file__).parent))
from register_site002 import to_world
from northern_painted_timber import apply_painted_timber
from northern_mineral_surfaces import apply_mineral_surfaces
from refine_northern_materials import apply_craft_surfaces
from northern_tile_ends import refine_tile_end_profiles,give_tile_shells_depth
sys.path.insert(0,'C:/dev/hangulsori/ko_lernen_app_worktrees/hanok-warm-stone-20260923/tool/hanok_scene')
import reconstruction_geometry as g
import reference_detail_geometry as d
OUT=Path(__file__).resolve().parents[2]/'assets_unused/pending_review/hwalju-blueprint-review/northern-court'

def tag_flush(ident):
 obs=g.flush();g.BATCHES.clear()
 for ob in obs:
  for k,v in {'construction_building':ident,'northExtension':True,'construction_first':1,'construction_last':99,'source_object_name':ob.name}.items():ob[k]=v
  for mod in ob.modifiers:
   if mod.type=='BEVEL':mod.width=.002;mod.segments=2
 return obs

def repair(scene,c):
 if c.get('courtyardPhotoVersion'):return
 wood=bpy.data.materials['North anchae wood'];beam=bpy.data.materials['North anchae beam'];stone=bpy.data.materials['North anchae stone']
 green=bpy.data.materials['North aged blue green'];red=bpy.data.materials['North weathered vermilion'];lime=bpy.data.materials['North lime plaster'];paper=bpy.data.materials['North warm hanji'];iron=bpy.data.materials['North forged iron'];clay=bpy.data.materials['North earthen plaster']
 tiles=[bpy.data.materials[f'Ansarang retained V33 main_gate source ceramic {i}'] for i in range(6)];end=bpy.data.materials['North lime tile ends']
 g.BATCHES.clear()
 # 059 front elevation, calibrated against 6760 between end-column axes:
 # outer openings about 780 mm, middle 1080 mm; clear leaf height 1520 mm.
 # These are line-trace dimensions, not printed schedule measurements.
 rec=next(r for r in c['buildings'] if r['id']=='sadang');origin=Vector((*rec['center'],rec['datum']));rot=Matrix.Rotation(rec['angle'],3,'Z')
 for ob in list(scene.objects):
  if ob.get('construction_building')=='sadang' and any(t in ob.name for t in ('front sanctuary infill','green sanctuary pair')):bpy.data.objects.remove(ob,do_unlink=True)
 # Register the elevation vertically as well as its openings. The old
 # generic wall height added 700 mm above the door heads. Keep floor/ridge
 # levels and horizontal beam cross-sections; lower the beam/eave assembly
 # and restore the steeper roof silhouette traced on 059. No post widening.
 def height(z):
  if z<=.70:return z
  if z<2.65:return .70+(z-.70)*1.25/1.95
  if z<=3.70:return z-.70
  return 3.00+(z-3.70)*2.16/1.46
 for ob in scene.objects:
  if ob.type!='MESH' or ob.get('construction_building')!='sadang':continue
  inv=ob.matrix_world.inverted()
  for v in ob.data.vertices:
   p=rot.transposed()@(ob.matrix_world@v.co-origin);p.z=height(p.z);v.co=inv@(origin+rot@p)
  ob.data.update()
 rec['elevationHeightRepair']={'eaveDrop':.70,'oldEave':3.70,'eave':3.00,'ridge':5.16,'columnHead':2.57,'authority':'059 elevation line tracing calibrated by 6760 end-column spacing; not a printed vertical dimension','printedHorizontalBeamSectionsUnchanged':True}
 g.set_transform(lambda p:origin+rot@Vector(p));xs=[-3.38,-1.23,1.22,3.38]
 shrine_openings=[]
 for i,(a,b) in enumerate(zip(xs,xs[1:])):
  cx=(a+b)/2;w=(.780,1.080,.780)[i];count=(1,2,1)[i];nm='North.sadang.survey sanctuary '+str(i)
  l,r=cx-w/2,cx+w/2
  for x0,x1 in ((a+.115,l),(r,b-.115)):g.box(nm+'.infill',((x0+x1)/2,-.84,1.505),(x1-x0,.15,1.99),lime)
  for z0,z1 in ((.51,.62),(2.14,2.50)):g.box(nm+'.infill',(cx,-.84,(z0+z1)/2),(w,.15,z1-z0),lime)
  for x in (l,r):g.box(nm+'.measured jamb',(x,-.867,1.38),(.087,.150,1.607),red)
  for z in (.62,2.14):g.box(nm+'.measured head and sill',(cx,-.867,z),(w+.087,.150,.087),red)
  d.lattice(nm,cx-w/2+.013,cx+w/2-.013,-.887,.64,2.12,green,paper,leaves=count,solid=.22)
  for j in range(count):
   hx=cx+w/2-.085 if count==1 else cx+(-.055 if j==0 else .055)
   g.torus(nm+f'.leaf{j+1}.iron ring',(hx,-.946,1.30),.021,.0035,iron)
  shrine_openings.append({'building':'sadang','tag':'survey sanctuary '+str(i),'center':[cx,-.887,1.38],'width':w,'height':1.52,'leaves':count,'authority':'059 elevation line trace; user photographs confirm single/double/single'})
 tag_flush('sadang');c['openings']=[r for r in c['openings'] if not(r['building']=='sadang' and 'green sanctuary pair' in r['tag'])]+shrine_openings
 rec['sanctuaryOpenings']=shrine_openings
 # The printed gate detail overrides the smaller-scale 002 opening trace.
 from northern_gate_survey import build as build_measured_gate
 endpoints=to_world([[1180,1064],[1178,1090]]);center=endpoints.mean(0);delta=endpoints[1]-endpoints[0];angle=math.atan2(delta[1],delta[0])
 world=d.basis((*center,1.50),angle)
 door,evidence=build_measured_gate(g,d,world,(wood,beam,stone,iron,tiles,end))
 tag_flush('north_site');c['doors'].append(door)
 c['rearYardGate']={'center':center.tolist(),'angle':angle,**evidence}
 # Replace the route which cut through the former generic rectangular wall.
 for ob in list(scene.objects):
  if ob.name.startswith('North.site.path worn stepping stone'):bpy.data.objects.remove(ob,do_unlink=True)
 gate=next(r for r in c['buildings'] if r['id']=='sadangmun');sg=np.array(gate['center'])
 routes=[[(18.092,1.7),(18.092,10.2),(20.1,11.8),(20.1,15.6),(sg[0],sg[1]-1.1)],[(18,13.1),(15.93,13.10),tuple(center),(15.77,14.65),(16.13,18.84),(16.0,24.7)],[(18.092,10.2),(13.0,8.0),(7.0,8.0),(4.38,12.04),(3.31,16.93),(5.5,22.0)],[(3.31,16.93),(1,17.5),(1,15.6)]]
 g.set_transform(lambda p:p);rng=random.Random(2958)
 for path in routes:
  for a,b in zip(path,path[1:]):
   count=max(1,round(math.dist(a,b)/.72))
   for k in range(count):
    x=a[0]+(b[0]-a[0])*(k+.5)/count;y=a[1]+(b[1]-a[1])*(k+.5)/count;z=1.5 if y>8.2 else 1.20+.30*max(0,min(1,(y-5.2)/3))
    if y<5.1:z*=max(0,min(1,(y-.5)/4.6))
    g.rock('North.site.path worn stepping stone',(x,y,z+.027),(rng.uniform(.38,.58),rng.uniform(.32,.48),.075),stone,rng)
 # Stacked tile chimney seen between the rear veranda and jars. A real
 # arched vent and spaced cap stay open; no black decal on a solid block.
 rec=next(r for r in c['buildings'] if r['id']=='anchae');rot=Matrix.Rotation(rec['angle'],3,'Z');origin=Vector((*rec['center'],rec['datum']));g.set_transform(lambda p:origin+rot@Vector(p));nm='North.site.rear yard chimney';x,y=-4.08,3.88
 g.box(nm+'.stone foot',(x,y,.14),(.88,.68,.28),stone)
 for i in range(13):
  z=.29+i*.060
  g.box(nm+'.lime joint',(x,y,z+.025),(.61,.49,.045),lime)
  for yy in (y-.235,y+.235):g.box(nm+'.stacked tile edge',(x,yy,z+.051),(.68,.068,.025),tiles[i%6])
  for xx in (x-.30,x+.30):g.box(nm+'.stacked tile end',(xx,y,z+.051),(.068,.43,.025),tiles[i%6])
 for sign in (-1,1):g.box(nm+'.arched cap pier',(x+sign*.24,y,1.08),(.15,.50,.22),lime)
 for i in range(24):
  t0=math.pi*i/24;t1=math.pi*(i+1)/24
  poly=[(x+r*math.cos(t),1.11+r*math.sin(t)) for r,t in ((.18,t0),(.18,t1),(.31,t1),(.31,t0))]
  d.extruded_profile(nm+'.hollow arched cap',poly,y-.26,y+.26,lime)
 tag_flush('north_site');g.set_transform(lambda p:p)
 c['routes']=routes;c['courtyardPhotoVersion']=1
 c['courtyardPhotoEvidence']={'shrineLeaves':[1,2,1],'flowerWall':'Fieldstone base; gray tile-edge petal motifs embedded in ochre plaster only on photographed gate frontage','rearYard':'Separate timber gate, through path, continuous rear veranda, stacked tile chimney and jars','interpretations':['Rear-yard gate roof curve and small hardware','Chimney dimensions and location relative to porch','Floral motif spacing/depth','Elevation line-trace opening dimensions']}
 c['illustratedTimber']+=apply_craft_surfaces(scene,scope=('north_site',))
 c['paintedTimber']+=apply_painted_timber(scene);c['mineralSurfaces']+=apply_mineral_surfaces(scene)
 c['tileEndProfiles']+=refine_tile_end_profiles(scene);c['tileShells']+=give_tile_shells_depth(scene)
 bpy.context.view_layer.update()

if __name__=='__main__':
 bpy.ops.wm.open_mainfile(filepath=str(OUT/'spatial-detail-study.blend'));c=json.loads((OUT/'spatial-detail-contract.json').read_text(encoding='utf8'))
 repair(bpy.context.scene,c)
 (OUT/'spatial-detail-contract.json').write_text(json.dumps(c,ensure_ascii=False,indent=2),encoding='utf8');bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'spatial-detail-study.blend'),compress=True)
 print('COURTYARD PHOTOGRAPH DETAILS SAVED',flush=True)
