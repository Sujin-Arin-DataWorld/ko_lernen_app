"""Apply registered rigid placements and traced northern enclosure paths."""
from pathlib import Path
import bpy,json,math,random,sys
import numpy as np
from mathutils import Matrix,Vector
sys.path.insert(0,str(Path(__file__).parent))
from register_site002 import registration,to_world
from northern_mineral_surfaces import apply_mineral_surfaces
from northern_tile_ends import give_tile_shells_depth,refine_tile_end_profiles
sys.path.insert(0,'C:/dev/hangulsori/ko_lernen_app_worktrees/hanok-warm-stone-20260923/tool/hanok_scene')
import reconstruction_geometry as g
import reference_detail_geometry as d
OUT=Path(__file__).resolve().parents[2]/'assets_unused/pending_review/hwalju-blueprint-review/northern-court'

def apply(scene,c):
 if c.get('site002PlacementVersion')==1:return
 fits=registration(c);c['site002Registration']=fits
 for fit in fits['buildings']:
  rec=next(r for r in c['buildings'] if r['id']==fit['id']);old=Vector((*rec['center'],rec['datum']));new=Vector((*fit['center'],rec['datum']))
  delta=Matrix.Translation(new)@Matrix.Rotation(fit['angle']-rec['angle'],4,'Z')@Matrix.Translation(-old)
  for ob in scene.objects:
   if ob.type=='MESH' and ob.get('construction_building')==rec['id']:ob.matrix_world=delta@ob.matrix_world
  for door in c['doors']:
   if door['building']==rec['id']:door['hinges']=[list(delta@Vector(p)) for p in door['hinges']]
  rec['center']=fit['center'];rec['angle']=fit['angle'];rec['placementAuthority']='002 traced column centres; rigid least-squares fit, no dimension scaling';rec['placementTransform']=list(map(list,delta))
 # Rebuild only the independent north enclosures. The previous generic box
 # placed a wall beside the inner store where the drawing has open yard.
 oldwalls=[r['name'] for r in c['walls']]
 for ob in list(scene.objects):
  if ob.get('construction_building')=='north_site' and any(ob.name.startswith('North.site.'+name+' ') for name in oldwalls):bpy.data.objects.remove(ob,do_unlink=True)
 clay=bpy.data.materials['North earthen plaster'];stone=bpy.data.materials['North anchae stone'];beam=bpy.data.materials['North anchae beam'];end=bpy.data.materials['North lime tile ends']
 tiles=[bpy.data.materials[f'Ansarang retained V33 main_gate source ceramic {i}'] for i in range(6)]
 walls=[];g.BATCHES.clear()
 def wall(name,start,stop,height=1.35):
  start=np.asarray(start);stop=np.asarray(stop);length=float(np.linalg.norm(stop-start));g.set_transform(d.basis((*start,1.5),math.atan2(*(stop-start)[::-1])))
  nm='North.site.'+name;g.box(nm+' earth core',(length/2,0,height/2),(length,.32,height),clay);rng=random.Random(name)
  floral=name in ('shrine gate left','shrine gate right')
  stone_height=.52 if floral else height
  rows=max(1,round(stone_height/.22))
  for side in (-1,1):
   for row in range(rows):
    x=0
    while x<length-.03:
     w=min(length-x,rng.uniform(.28,.46));g.rock(nm+' irregular stone',(x+w/2,side*.19,(row+.5)*stone_height/rows),(w-.02,.12,stone_height/rows-.016),stone,rng);x+=w
   if floral:
    # Visible tile shards embedded in ochre plaster, not painted flowers.
    # The other boundary faces remain fieldstone where the jar-yard photo
    # shows fieldstone. Ornament is limited to the photographed gate wall.
    mat=tiles[3]
    for cx in np.arange(.39,length-.30,.76):
     for z,spread,rise in ((.70,.33,.13),(.90,.34,.18),(1.08,.30,.15)):
      for sign in (-1,1):
       points=[]
       for t in np.linspace(0,1,17):
        xx=spread*(3*(1-t)*t*t*.58+t**3)
        zz=rise*(3*(1-t)**2*t+3*(1-t)*t*t*1.18+t**3)
        points.append((cx+sign*xx,side*.170,z+zz))
       for a,b in zip(points,points[1:]):g.rod(nm+' inset petal tile edges',a,b,.010,mat,6)
     for sign in (-1,1):
      points=[(cx+sign*.15*t,side*.17,1.08+.17*t-.055*math.sin(t*math.pi)) for t in np.linspace(0,1,10)]
      for a,b in zip(points,points[1:]):g.rod(nm+' inset central petal',a,b,.009,mat,6)
  g.roof(nm+' coping',(0,length,-.31,.31),height+.025,height+.105,beam,tiles,end,turn=0,ridge_turn=0,columns=max(2,round(length/.19)),ridge_courses=2)
  walls.append({'name':name,'start':start.tolist(),'stop':stop.tolist(),'base':1.5,'height':height,'floral':floral,'authority':'002 source-pixel wall centreline trace; wall height and tile-shard pattern are photographic interpretations'})
 shrine=to_world([[915,779],[1158,814],[1129,1017],[887,990]])
 gate=next(r for r in c['buildings'] if r['id']=='sadangmun');gr=Matrix.Rotation(gate['angle'],3,'Z');go=Vector((*gate['center'],1.5))
 gleft=(go+gr@Vector((-.675,0,0)))[:2];gright=(go+gr@Vector((.675,0,0)))[:2]
 for name,a,b in [('shrine west',shrine[0],shrine[3]),('shrine rear',shrine[0],shrine[1]),('shrine east',shrine[3],shrine[2]),('shrine gate left',shrine[2],gleft),('shrine gate right',gright,shrine[1])]:wall(name,a,b)
 # The jar yard has one real opening in its eastern return.
 rear_end=to_world([[1180,1064],[1178,1090]]);rear_center=rear_end.mean(0)
 rear_axis=(rear_end[1]-rear_end[0])/np.linalg.norm(rear_end[1]-rear_end[0])
 # 084 printed 1020 mm post spacing overrides the coarse 002 gap.
 upper=rear_center-rear_axis*.510;lower=rear_center+rear_axis*.510
 for name,a,b in [('jar yard return',*to_world([[1129,1017],[1184,1020]])),
                  ('jar yard east upper',to_world([[1184,1020]])[0],upper),
                  ('jar yard east lower',lower,to_world([[1175,1122]])[0]),
                  ('jar yard west',*to_world([[887,990],[872,1119]]))]:wall(name,a,b,1.12)
 # The neighbouring Gwang yard is separated from the shrine by the gate wall.
 for name,p0,p1 in [('gwang north',[1169,818],[1396,857]),('gwang east',[1396,857],[1360,1047])]:
  a,b=to_world([p0,p1]);wall(name,a,b,1.12)
 newwalls=g.flush();g.BATCHES.clear();g.set_transform(lambda p:p)
 for ob in newwalls:
  for k,v in {'construction_building':'north_site','northExtension':True,'construction_first':1,'construction_last':99,'source_object_name':ob.name}.items():ob[k]=v
 c['walls']=walls;c['site002PlacementVersion']=1
 c['tileEndProfiles']+=refine_tile_end_profiles(scene);c['tileShells']+=give_tile_shells_depth(scene);c['mineralSurfaces']+=apply_mineral_surfaces(scene)
 bpy.context.view_layer.update()
 for rec in c['buildings']:
  pts=[ob.matrix_world@Vector(v) for ob in scene.objects if ob.type=='MESH' and ob.get('construction_building')==rec['id'] for v in ob.bound_box]
  rec['bounds']={'min':[min(p[k] for p in pts) for k in range(3)],'max':[max(p[k] for p in pts) for k in range(3)]}
 bpy.context.view_layer.update()

if __name__=='__main__':
 bpy.ops.wm.open_mainfile(filepath=str(OUT/'spatial-detail-study.blend'));c=json.loads((OUT/'spatial-detail-contract.json').read_text(encoding='utf8'))
 apply(bpy.context.scene,c)
 (OUT/'spatial-detail-contract.json').write_text(json.dumps(c,ensure_ascii=False,indent=2),encoding='utf8')
 bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'spatial-detail-study.blend'),compress=True)
 print('002 RIGID PLACEMENT APPLIED',flush=True)
