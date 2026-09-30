"""Solid joinery and usable rooms; layered over the audited review candidate.

Printed dimensions override generic parts. Unprinted placement and paint are
explicit interpretations, recorded separately from the metric constraints.
"""
from pathlib import Path
import bpy,bmesh,sys,json,math,hashlib
import numpy as np
from mathutils import Vector,Matrix
sys.path.insert(0,str(Path(__file__).parent))
from northern_courtyard_photo_repair import OUT,g,d,tag_flush
from northern_anchae_plan import local_parts,FRONT,MAIN_REAR,ROOM_REAR
from northern_wall_joints import basis
from refine_northern_materials import apply_craft_surfaces,geometry_fingerprint
from northern_painted_timber import apply_painted_timber
from northern_mineral_surfaces import apply_mineral_surfaces

def apply(scene,c):
 if c.get('measuredRedrawVersion'):return
 protected={o.name:geometry_fingerprint(o) for o in scene.objects if o.type=='MESH' and o.get('construction_building') in ('sarang','jung','main_gate','changgo')}
 changes=[]
 def drop(ob,predicate,origin,rot):
  ids=[i for indices,q in local_parts(ob,origin,rot) if predicate(q) for i in indices]
  if ids:
   bm=bmesh.new();bm.from_mesh(ob.data);bm.verts.ensure_lookup_table();bmesh.ops.delete(bm,geom=[bm.verts[i] for i in ids],context='VERTS');bm.to_mesh(ob.data);bm.free();ob.data.update();changes.append(ob.name)
 def delete(ob):changes.append(ob.name);bpy.data.objects.remove(ob,do_unlink=True)
 def setpart(ob,fn,origin,rot):
  inv=ob.matrix_world.inverted()
  for ids,q in local_parts(ob,origin,rot):
   for i,p in zip(ids,fn(q)):
    ob.data.vertices[i].co=inv@(origin+rot@Vector(p))
  ob.data.update();changes.append(ob.name)
 wood=bpy.data.materials['North anchae wood'];beam=bpy.data.materials['North anchae beam'];lime=bpy.data.materials['North lime plaster'];paper=bpy.data.materials['North warm hanji'];iron=bpy.data.materials['North forged iron'];clay=bpy.data.materials['North earthen plaster']
 origin,rot,axes=basis(c['buildings']);rec=next(r for r in c['buildings'] if r['id']=='anchae')
 cx=(axes[1]+axes[2])/2;trimmed_bindings=[]
 # 052 section: kitchen ground floor, no room ondol or front maru through
 # the doorway. Cut only that bay; retain the neighboring room and veranda.
 for ob in list(scene.objects):
  if ob.type!='MESH' or ob.get('construction_building')!='anchae':continue
  if ob.name in ('North.anchae.room ondol raised clay','North.anchae.room warm paper floor'):
   drop(ob,lambda q:axes[1]<q[:,0].mean()<axes[2],origin,rot)
  if ob.name in ('North.anchae.floor individual boards','North.anchae.floor under joists'):
   drop(ob,lambda q:axes[1]<q[:,0].mean()<axes[2] and q[:,1].mean()<-.95,origin,rot)
  if ob.name in ('North.anchae.frame longitudinal beam','North.anchae.floor under joists'):
   ids=[]
   for indices,q in local_parts(ob,origin,rot):
    lo,hi=q.min(0),q.max(0)
    if hi[2]<.80 and q[:,1].mean()<-.95 and lo[0]<axes[2] and hi[0]>axes[1]:
     ids+=indices
     for x0,x1 in ((lo[0],min(hi[0],axes[1])),(max(lo[0],axes[2]),hi[0])):
      if x1-x0>.01:trimmed_bindings.append(((x0+x1)/2,(lo[1]+hi[1])/2,(lo[2]+hi[2])/2,x1-x0,hi[1]-lo[1],hi[2]-lo[2]))
   if ids:
    bm=bmesh.new();bm.from_mesh(ob.data);bm.verts.ensure_lookup_table();bmesh.ops.delete(bm,geom=[bm.verts[i] for i in ids],context='VERTS');bm.to_mesh(ob.data);bm.free();ob.data.update()
  if ob.name.startswith('North.anchae.right room end') or ob.name.startswith('North.anchae.open corner.room '):delete(ob)
 g.BATCHES.clear();g.set_transform(lambda p:origin+rot@Vector(p))
 for x,y,z,w,dep,h in trimmed_bindings:g.box('North.anchae.redraw interrupted floor binding',(x,y,z),(w,dep,h),beam)
 g.box('North.anchae.redraw kitchen earth floor',(cx,(FRONT+MAIN_REAR)/2,.245),(axes[2]-axes[1]-.20,3.62,.050),clay)
 # Keep the scheduled door and vent separate: the vent sits above the door
 # head. Its absolute datum is an elevation fit, not a printed height.
 for ob in scene.objects:
  if ob.name.startswith('North.anchae.kitchen high ventilator'):
   setpart(ob,lambda q:q+np.array((0,0,.140)),origin,rot)
 # Replace the plaster patch that previously filled the grille aperture.
 ob=bpy.data.objects.get('North.anchae.kitchen front')
 if ob:delete(ob)
 def infill(nm,left,right,y,bottom,top,hole,material=lime,depth=.09):
  l,r,lo,hi=hole
  for a,b,z0,z1 in ((left,l,bottom,top),(r,right,bottom,top),(l,r,bottom,lo),(l,r,hi,top)):
   if b-a>.003 and z1-z0>.003:g.box(nm,((a+b)/2,y,(z0+z1)/2),(b-a,depth,z1-z0),material)
 for a,b in ((axes[1]+.1,cx-.813),(cx+.813,axes[2]-.1)):
  g.box('North.anchae.redraw kitchen side infill',((a+b)/2,FRONT,1.525),(b-a,.09,2.49),clay)
 infill('North.anchae.redraw kitchen lower infill',cx-.813,cx+.813,FRONT,.28,2.135,(cx-.56,cx+.56,.35,2.07),clay)
 g.box('North.anchae.redraw kitchen vent head',(cx,FRONT,2.75),(1.626,.090,.060),beam)
 # Narrow room 3: keep its sitting porch and the 725 mm rear projection.
 a,b=axes[7],axes[8];mid=FRONT+1.175;roomcx=(a+b)/2
 g.box('North.anchae.redraw room3 floor',(roomcx,(mid+ROOM_REAR)/2,.616),(b-a-.13,ROOM_REAR-mid-.09,.035),paper)
 g.box('North.anchae.redraw room3 ceiling',(roomcx,(mid+ROOM_REAR)/2,2.97),(b-a-.16,ROOM_REAR-mid,.045),wood)
 # WW5 and WW8 occupy the two narrow end-room fronts, measured widths.
 # The side WD5 is 2274 wide, so it cannot fit the 1450 mm front bay.
 def diamond(nm,x,y,z,w,h):
  for xx in (x-w/2+.026,x+w/2-.026):g.box(nm+'.stile',(xx,y,z+h/2),(.052,.040,h),wood)
  for zz in (z+.026,z+h-.026):g.box(nm+'.rail',(x,y,zz),(w-.104,.040,.052),wood)
  x0,x1=x-w/2+.052,x+w/2-.052;z0,z1=z+.052,z+h-.052
  for sign in (-1,1):
   for off in np.arange(min(zz-sign*xx for xx in (x0,x1) for zz in (z0,z1)),max(zz-sign*xx for xx in (x0,x1) for zz in (z0,z1)),.108):
    pts=[]
    for xx in (x0,x1):
     zz=sign*xx+off
     if z0<=zz<=z1:pts.append((xx,zz))
    for zz in (z0,z1):
     xx=(zz-off)/sign
     if x0<xx<x1:pts.append((xx,zz))
    if len(pts)==2:
     v=np.array(pts[1])-pts[0];v=np.array((-v[1],v[0]))/np.linalg.norm(v)*.004
     poly=[tuple(np.array(pts[0])-v),tuple(np.array(pts[1])-v),tuple(np.array(pts[1])+v),tuple(np.array(pts[0])+v)]
     d.extruded_profile(nm+'.diamond sal',poly,y-.0125,y+.0125,wood)
 for tag,y,w in (('WW5',mid,1.254),('WW8',ROOM_REAR,1.217)):
  infill('North.anchae.redraw room3 '+tag+' wall',a+.07,b-.07,y,.62,2.99,(roomcx-w/2,roomcx+w/2,2.16,2.865))
  diamond('North.anchae.redraw room3 '+tag,roomcx,y-.035,2.16,w,.705)
  g.planks('North.anchae.redraw room3 '+tag+' lower timber',a+.09,b-.09,.68,2.12,0,[wood],axis='Y',thick=.026,width=.16) if False else None
 # Four-leaf side door, individual frame/sal sections from schedule 057.
 old=g.TRANSFORM;g.set_transform(lambda p:old((b+p[1],.48+p[0],p[2])))
 width=2.274;bt=.66;ht=1.710
 infill('North.anchae.redraw room3 WD5 side wall',mid-.48,ROOM_REAR-.48,0,.62,2.99,(-width/2,width/2,bt,bt+ht))
 for x in (-width/2-.043,width/2+.043):g.box('North.anchae.redraw room3 WD5 jamb',(x,0,bt+ht/2),(.086,.15,ht+.16),wood)
 for z in (bt-.045,bt+ht+.045):g.box('North.anchae.redraw room3 WD5 head sill',(0,0,z),(width+.172,.15,.09),beam)
 pos=-width/2
 for i,w in enumerate((.552,.585,.585,.552)):
  nm=f'North.anchae.redraw room3 WD5.leaf{i+1}';l,r=pos+.002,pos+w-.002;pos+=w
  for x in (l+.0165,r-.0165):g.box(nm+'.stile',(x,.006,bt+ht/2),(.033,.024,ht),wood)
  for z in (bt+.0165,bt+ht-.0165,bt+.31):g.box(nm+'.rail',((l+r)/2,.006,z),(r-l-.066,.024,.033),wood)
  g.box(nm+'.lower board',((l+r)/2,.012,bt+.155),(r-l-.066,.014,.266),wood)
  g.box(nm+'.hanji',((l+r)/2,-.011,bt+(.31+ht)/2),(r-l-.066,.004,ht-.31-.033),paper)
  for x in np.arange(l+.08,r-.04,.105):g.box(nm+'.vertical sal',(x,.012,bt+(.31+ht)/2),(.010,.024,ht-.31-.033),wood)
  for z in np.arange(bt+.38,bt+ht-.04,.105):g.box(nm+'.horizontal sal',((l+r)/2,.012,z),(r-l-.066,.024,.010),wood)
  for z in (bt+.20,bt+ht-.20):g.rod(nm+'.hinge pin',(l,.030,z-.033),(l,.030,z+.033),.005,iron,12)
 g.set_transform(old);tag_flush('anchae');g.set_transform(lambda p:p)
 rec['room3Redraw']={'sideDoor':{'schedule':'WD5','width':2.274,'height':1.710,'leafWidths':[.552,.585,.585,.552],'frame':[.033,.024],'sal':[.010,.024]},'frontPorchDepth':1.175,'rearProjection':.725,'windows':['WW5 1254x705','WW8 1217x705'],'placementAuthority':'Plan spatial fit and window schedule; end-room aperture assignment remains an interpretation pending opening-symbol plan.'}
 # Ansarang measured main posts and floor boards: the inherited donor had
 # 180 mm posts and 90 mm boards despite sheet 048 calling 200 and THK45.
 south=json.loads((OUT.parent/'side-connections/connection-contract.json').read_text(encoding='utf8'));ar=south['buildings']['ansarang'];ao=Vector((*ar['center'],0));arot=Matrix.Rotation(ar['angle'],3,'Z')
 for ob in list(scene.objects):
  if ob.type!='MESH' or ob.get('construction_building')!='ansarang':continue
  ob['northExtension']=True;ob['southOverride']=True
  if ob.name=='V28.ansarang.frame.post':
   def posts(q):
    center=(q.min(0)+q.max(0))/2;size=np.ptp(q,axis=0);q[:,:2]=center[:2]+(q[:,:2]-center[:2])*(.200/size[:2]);return q
   setpart(ob,posts,ao,arot)
  if any(k in ob.name for k in ('maru floor','hall floor','right porch floor')):
   def plank(q):
    top=q[:,2].max();lo=q[:,2].min();q[:,2]=top-(top-q[:,2])*.045/(top-lo);return q
   setpart(ob,plank,ao,arot)
  for mat in ob.data.materials:
   if mat and 'Canonical gate' in mat.name and 'pigment' in mat.name and any(t in mat.name for t in (' wood ', ' post ', ' beam ')):mat['surfaceKind']='wood'
 # Printed 048 bindings inside the existing deck envelope, showing end
 # sections in the porch undercroft rather than a thin fascia alone.
 g.set_transform(lambda p:ao+arot@Vector(p))
 for x in (-2.73,0,2.73,5.46):g.box('North.ansarang.redraw janggwiteul',(x,-1.53,.8975),(.180,1.20,.120),beam)
 for a,b in ((-2.73,0),(0,2.73),(2.73,5.46)):g.box('North.ansarang.redraw donggwiteul',((a+b)/2,-1.53,.8975),(b-a,.170,.120),beam)
 g.box('North.ansarang.redraw wraparound binding',(5.91,0,.8975),(.140,4.26,.120),beam)
 tag_flush('ansarang');g.set_transform(lambda p:p)
 c['ansarangRedraw']={'mainPosts':[.200,.200],'floorThickness':.045,'frontPorch':1.200,'authority':'2007 sheet048; 180x120 janggwiteul and 170x120 donggwiteul','retained':'Four 2730 mm bays, existing room partitions and folding 4-leaf hall doors'}
 # The shrine's full-depth porch is 1260 mm. Expose its real understructure
 # with longitudinal natural wood; paint belongs to the upper structure.
 sr=next(r for r in c['buildings'] if r['id']=='sadang');so=Vector((*sr['center'],sr['datum']));srot=Matrix.Rotation(sr['angle'],3,'Z')
 for ob in scene.objects:
  if ob.get('construction_building')=='sadang' and any(t in ob.name for t in ('floor under joists','measured porch')):
   ob.data.materials.clear();ob.data.materials.append(wood);ob['illustratedPineV1']=False
 # Round columns retain diameter240. Smooth longitudinal faces and round
 # bearing edges keep the post volume legible without changing its section.
 for ident in ('sadang','sadangmun'):
  for ob in scene.objects:
   if ob.type!='MESH' or ob.get('construction_building')!=ident:continue
   if 'column' in ob.name or 'gatepost' in ob.name:
    for poly in ob.data.polygons:
     if len(poly.vertices)==4:poly.use_smooth=True
   for mod in ob.modifiers:
    if mod.type=='BEVEL':mod.width=min(mod.width,.0025);mod.segments=3
 # Real stop rebates on the far side of the leaf; they are part of the
 # fixed jamb, never pasted onto the swinging door or across the aperture.
 for ident in ('sadangmun','north_site'):
  if ident=='sadangmun':
   gr=next(r for r in c['buildings'] if r['id']==ident);go=Vector((*gr['center'],gr['datum']));grot=Matrix.Rotation(gr['angle'],3,'Z');half=.510;lo=.35;hi=1.85;back=.057;nm='North.sadangmun.redraw';mat=bpy.data.materials['North weathered vermilion']
  else:
   gr=c['rearYardGate'];go=Vector((*gr['center'],1.5));grot=Matrix.Rotation(gr['angle'],3,'Z');half=.420;lo=.195;hi=1.595;back=.028;nm='North.site.rear yard gate.redraw';mat=wood
  g.set_transform(lambda p:go+grot@Vector(p))
  for x in (-half-.016,half+.016):g.box(nm+'.solid door stop',(x,back,(lo+hi)/2),(.028,.018,hi-lo),mat)
  g.box(nm+'.head stop',(0,back,hi+.012),(half*2,.018,.024),mat)
  tag_flush(ident);g.set_transform(lambda p:p)
 c['illustratedTimber']+=apply_craft_surfaces(scene,scope=('anchae','ansarang','sadang','north_site','right_ansarang','left_changgo'))
 c['paintedTimber']+=apply_painted_timber(scene);c['mineralSurfaces']+=apply_mineral_surfaces(scene)
 from repair_gate_finish import apply as finish_gate
 from canonical_surface_reuse import apply as reuse_canonical
 finish_gate(scene,c);c['canonicalSurfaceReuse']=reuse_canonical(scene)
 from repair_masonry_coping import apply as repair_masonry
 repair_masonry(scene,c)
 # Small clearances and wear are not survey measurements.
 c['measuredRedrawVersion']=1;c['measuredRedraw']={'changed':changes,'protectedMeshes':len(protected),'gateStops':'18 mm deep stop beads, interpreted joinery clearance; scheduled door thicknesses unchanged','kitchenFloorTop':.270,'kitchenVentBottom':2.160,'shrineHeight':'Retained 059 elevation registration, not declared a printed vertical dimension','sourceConflictsRetained':True}
 assert all(geometry_fingerprint(bpy.data.objects[n])==fp for n,fp in protected.items()),'Approved building modified'
 bpy.context.view_layer.update()

if __name__=='__main__':
 bpy.ops.wm.open_mainfile(filepath=str(OUT/'spatial-detail-study.blend'));c=json.loads((OUT/'spatial-detail-contract.json').read_text(encoding='utf8'))
 apply(bpy.context.scene,c)
 (OUT/'detail-redraw-contract.json').write_text(json.dumps(c,ensure_ascii=False,indent=2),encoding='utf8')
 bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'detail-redraw.blend'),compress=True)
 print('MEASURED REDRAW SAVED',len(c['measuredRedraw']['changed']),flush=True)
