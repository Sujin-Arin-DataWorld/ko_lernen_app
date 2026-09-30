"""Restore the open Anchae corner and measured shrine-gate solid joinery.

Printed sections remain metric; no global inflation of historic timber.
Run on a saved review scene and retain an independently inspectable candidate.
"""
from pathlib import Path
import bpy,bmesh,json,sys,math,hashlib
import numpy as np
from mathutils import Vector,Matrix
sys.path.insert(0,str(Path(__file__).parent))
from northern_anchae_plan import local_parts,MAIN_REAR,FRONT
from northern_wall_joints import basis
from refine_northern_materials import apply_craft_surfaces
from northern_painted_timber import apply_painted_timber
from northern_mineral_surfaces import apply_mineral_surfaces
sys.path.insert(0,'C:/dev/hangulsori/ko_lernen_app_worktrees/hanok-warm-stone-20260923/tool/hanok_scene')
import reconstruction_geometry as g
OUT=Path(__file__).resolve().parents[2]/'assets_unused/pending_review/hwalju-blueprint-review/northern-court'

def repair(scene,c):
 if c.get('spatialDetailVersion')==1:return
 origin,rot,axes=basis(c['buildings']);changed=[];removed=[]
 def drop_parts(ob,predicate):
  ids=[i for indices,points in local_parts(ob,origin,rot) if predicate(points) for i in indices]
  if not ids:return
  bm=bmesh.new();bm.from_mesh(ob.data);bm.verts.ensure_lookup_table()
  bmesh.ops.delete(bm,geom=[bm.verts[i] for i in ids],context='VERTS');bm.to_mesh(ob.data);bm.free();ob.data.update();changed.append(ob.name)
 def remove(ob):removed.append(ob.name);bpy.data.objects.remove(ob,do_unlink=True)
 # The front veranda is 1175 mm deep; the middle side post is not its back wall.
 # Remove just the inappropriate end-bay facade; room 2 stays enclosed.
 for ob in list(scene.objects):
  if ob.type!='MESH' or ob.get('construction_building')!='anchae':continue
  if any(k in ob.name for k in ('end bay plaster','end high lattice 7','end bay rear','room ceiling')):
   drop_parts(ob,lambda q:q[:,0].mean()>axes[7]+.05)
  if 'right room end' in ob.name:
   inv=ob.matrix_world.inverted()
   # Clip end components at the front room wall, leaving a high head.
   drop_parts(ob,lambda q:q[:,1].max()<FRONT+1.175 and q[:,2].mean()<2.75)
   drop_parts(ob,lambda q:q[:,1].min()>=MAIN_REAR+.045 and q[:,2].mean()<2.75)
   for ids,q in local_parts(ob,origin,rot):
    if q[:,2].mean()>2.75:continue
    for i,p in zip(ids,q):
     p[1]=max(p[1],FRONT+1.175);p[1]=min(p[1],MAIN_REAR+.045)
     ob.data.vertices[i].co=inv@(origin+rot@Vector(p))
   ob.data.update();changed.append(ob.name)
 g.BATCHES.clear();g.set_transform(lambda p:origin+rot@Vector(p));nm='North.anchae.open corner'
 wood=bpy.data.materials['North anchae wood'];beam=bpy.data.materials['North anchae beam'];lime=bpy.data.materials['North lime plaster'];paper=bpy.data.materials['North warm hanji']
 mid=FRONT+1.175;a,b=axes[7],axes[8];cx=(a+b)/2
 # Rear room remains a volume; its front is set behind the open sitting bay.
 g.box(nm+'.room front plaster',(cx,mid,1.83),(b-a-.16,.09,2.42),lime)
 g.box(nm+'.room front head',(cx,mid,2.99),(b-a+.02,.135,.18),beam)
 g.box(nm+'.room rear plaster',(cx,MAIN_REAR,1.83),(b-a-.16,.09,2.42),lime)
 g.box(nm+'.room floor',(cx,(mid+MAIN_REAR)/2,.616),(b-a-.13,MAIN_REAR-mid-.09,.035),paper)
 g.box(nm+'.room ceiling',(cx,(mid+MAIN_REAR)/2,3.05),(b-a-.16,MAIN_REAR-mid,.045),paper)
 # Continuous 45 mm plank floor extends around the end post, not a painted panel.
 g.planks(nm+'.solid sitting floor',a+.03,b-.03,FRONT+.03,mid-.04,.62,[wood],axis='Y',thick=.045,width=.18)
 g.box(nm+'.side floor binding',(b, (FRONT+mid)/2,.50),(.135,1.175,.24),beam)
 g.box(nm+'.rear floor binding',(cx,mid,.50),(b-a,.135,.24),beam)
 added=g.flush();g.BATCHES.clear()
 for ob in added:
  for k,v in {'construction_building':'anchae','northExtension':True,'construction_first':1,'construction_last':99,'source_object_name':ob.name}.items():ob[k]=v
  for mod in ob.modifiers:
   if mod.type=='BEVEL':mod.width=.003;mod.segments=2
 rec=next(r for r in c['buildings'] if r['id']=='anchae')
 rec['openCorner']={'bay':7,'openSideDepth':1.175,'floorThickness':.045,'authority':'NRICH fig4.15: front veranda 1175, enclosed room depth 2625. Middle side post is not a partition line.','frontRoomWallInterpretation':True}
 # Shrine gate sheet 086/087: 170 round main posts, 70x80 side props.
 rec=next(r for r in c['buildings'] if r['id']=='sadangmun');o=Vector((*rec['center'],rec['datum']));r=Matrix.Rotation(rec['angle'],3,'Z');g.set_transform(lambda p:o+r@Vector(p))
 red=bpy.data.materials['North weathered vermilion'];green=bpy.data.materials['North aged blue green'];iron=bpy.data.materials['North forged iron']
 for ob in list(scene.objects):
  if ob.get('construction_building')!='sadangmun':continue
  if 'rear roof support' in ob.name or ob.name=='North.sadangmun.threshold' or any(t in ob.name for t in ('.rear rail','.forged hinge','.nail')):remove(ob)
 nm='North.sadangmun'
 for x in (-.675,.675):
  for y in (-.5,.5):g.box(nm+'.measured side support',(x,y,1.025),(.070,.080,1.650),red)
  g.box(nm+'.measured side head',(x,0,1.885),(.070,1.150,.080),green)
 for z in (.275,1.82):g.box(nm+'.measured sill and head',(0,0,z),(1.350,.072,.150),red if z<1 else green)
 for x in (-.552,.552):g.box(nm+'.measured recessed jamb',(x,.014,1.10),(.072,.090,1.650),red)
 for leaf in range(2):
  a=-.510+leaf*.510+.004;b=a+.502;pre=nm+'.taegeuk leaves.leaf'+str(leaf+1)
  for z in (.51,1.69):g.box(pre+'.measured rear daejang',((a+b)/2,.0225,z),(b-a,.065,.095),red)
  g.box(pre+'.measured centre daejang',((a+b)/2,.007,1.03),(b-a,.034,.054),red)
  pivot=a if leaf==0 else b
  for z in (.3025,1.905):
   g.box(pre+'.measured mundunte',(pivot+(1 if leaf==0 else -1)*.068,.035,z),(.210,.073,.085 if z<1 else .110),red)
   g.rod(pre+'.solid pivot pin',(pivot,.035,z-.080),(pivot,.035,z+.080),.017,red,18)
  for z in (.51,1.69):
   for x in np.linspace(a+.06,b-.06,3):g.rod(pre+'.round iron stud',(x,-.041,z),(x,-.046,z),.011,iron,14)
  g.box(pre+'.bolt keeper',((a+b)/2,.073,1.03),(.054,.035,.09),red)
 new=g.flush();g.BATCHES.clear();g.set_transform(lambda p:p)
 for ob in new:
  for k,v in {'construction_building':'sadangmun','northExtension':True,'construction_first':1,'construction_last':99,'source_object_name':ob.name,'gateJoineryVersion':1}.items():ob[k]=v
  for mod in ob.modifiers:
   if mod.type=='BEVEL':mod.width=.0015;mod.segments=3
 c['spatialDetailVersion']=1
 c['spatialDetailRepair']={'changed':changed,'removed':removed,'added':[ob.name for ob in added+new],
  'shrineGateSections':{'postDiameter':.170,'support':[.070,.080],'jamb':[.072,.090],'doorBoard':.030,'rearRails':[.065,.095],'centreRail':[.034,.054],'sill':[.072,.150]},'authority':'Shrine gate sheets 086 and 087; Anchae plan fig4.15','unmeasured':'Small clearances, pin diameters, bevels and room3 front finish are interpreted; no 100 percent survey claim'}
 c['illustratedTimber']+=apply_craft_surfaces(scene)
 # The side gates already have solid 36 mm doors. Correct texture direction
 # on all six faces instead of inflating their surveyed timber sections.
 gate_craft=apply_craft_surfaces(scene,scope=('left_changgo','right_ansarang'))
 c['southOverrides']=[r['object'] for r in gate_craft]
 for name in c['southOverrides']:
  bpy.data.objects[name]['northExtension']=True;bpy.data.objects[name]['southOverride']=True
 c['illustratedTimber']+=gate_craft
 # Sheet 058 explicitly labels the front round posts diameter 240 mm.
 # Do not enlarge the ends to make them visually heavier.
 rec=next(r for r in c['buildings'] if r['id']=='sadang');so=Vector((*rec['center'],rec['datum']));sr=Matrix.Rotation(rec['angle'],3,'Z')
 ob=bpy.data.objects['North.sadang.frame round red column']
 for poly in ob.data.polygons:poly.use_smooth=len(poly.vertices)==4
 ob.data.update();rec['frontColumnDiameters']=[.240]*4
 # Grain on the round surfaces remains longitudinal. These are physical
 # floor bindings from 058, visible beneath the 45 mm boards.
 g.set_transform(lambda p:so+sr@Vector(p));wood=bpy.data.materials['North sadang wood']
 sx=[-3.38,-1.23,1.22,3.38]
 for a,b in zip(sx,sx[1:]):g.box('North.sadang.measured porch donggwiteul',((a+b)/2,-1.47,.4125),(b-a,.140,.150),wood)
 for x in sx:g.box('North.sadang.measured porch janggwiteul',(x,-1.47,.4125),(.090,1.260,.150),wood)
 added_shrine=g.flush();g.BATCHES.clear();g.set_transform(lambda p:p)
 for ob in added_shrine:
  for k,v in {'construction_building':'sadang','northExtension':True,'construction_first':1,'construction_last':99,'source_object_name':ob.name}.items():ob[k]=v
 c['spatialDetailRepair']['shrineFrontColumns']={'diameters':[.240]*4,'authority':'2007 sheet058 plan','porchBindings':[[.140,.150],[.090,.150]]}
 c['paintedTimber']+=apply_painted_timber(scene)
 c['mineralSurfaces']+=apply_mineral_surfaces(scene)
 bpy.context.view_layer.update()

if __name__=='__main__':
 bpy.ops.wm.open_mainfile(filepath=str(OUT/'scene.blend'));c=json.loads((OUT/'northern-contract.json').read_text(encoding='utf8'))
 repair(bpy.context.scene,c)
 (OUT/'spatial-detail-contract.json').write_text(json.dumps(c,ensure_ascii=False,indent=2),encoding='utf8')
 bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'spatial-detail-study.blend'),compress=True)
 print('SPATIAL DETAIL CANDIDATE SAVED',json.dumps(c['spatialDetailRepair'],ensure_ascii=False),flush=True)
