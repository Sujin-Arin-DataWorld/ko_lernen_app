"""Repair missing gate load paths and registered photographic passage details.

The existing measured/traced roof envelopes, openings and estate coordinates
stay fixed. New joints are photo reconstructions, not newly claimed surveys.
"""
from pathlib import Path
import bpy,sys,json,math,shutil,hashlib,ast,random,numpy as np
from mathutils import Vector,Matrix
sys.path.insert(0,str(Path(__file__).parent))
from northern_courtyard_photo_repair import OUT,g,d,tag_flush
from northern_timber_sections import groups
from repair_masonry_coping import fingerprint
from refine_september_photo_details import setup_art
import canonical_surface_reuse as art
sha=lambda p:hashlib.sha256(Path(p).read_bytes()).hexdigest()
for node in ast.parse(Path('C:/dev/hangulsori/ko_lernen_app_worktrees/hanok-warm-stone-20260923/tool/hanok_scene/refine_noble_surfaces.py').read_text(encoding='utf8')).body:
 if isinstance(node,ast.FunctionDef) and node.name=='aligned_grain':exec(compile(ast.unparse(node),'approved timber mapping','exec'))

def bounds(o,ids=None):
 a=np.array([(o.matrix_world@o.data.vertices[i].co)[:] for i in (ids if ids is not None else range(len(o.data.vertices)))])
 return a.min(0),a.max(0)

def main():
 source=OUT/'detail-redraw.blend';backup=OUT/'gate-bearings-before.blend';contract=OUT/'detail-redraw-contract.json';saved=OUT/'gate-bearings-before-contract.json'
 if not backup.exists():shutil.copy2(source,backup);shutil.copy2(contract,saved)
 bpy.ops.wm.open_mainfile(filepath=str(backup));s=bpy.context.scene;c=json.loads(saved.read_text(encoding='utf8'))
 south=json.loads((OUT.parent/'side-connections/connection-contract.json').read_text(encoding='utf8'))
 changed=[];added=[];removed=[];sources=[]
 refs=[('5ee171a2-60a8-4561-8298-94d4bfcb1457','sarang-left-gate-eaves'),('7e2d8859-d9f1-4607-9c98-0d25367327dd','jung-courtyard-passage'),('0cdddaf3-2c93-463b-89e9-743f7d0c3764','anchae-eaves-sireong'),('12623d27-1642-41c4-895b-2c7a47dcfbf0','sadang-painted-eaves'),('c2cba827-d544-4487-8dc3-92cc4e8946f2','main-gate-courtyard'),('72ea1102-d507-42bf-93c7-77d267c8d0c2','main-gate-exterior')]
 for token,label in refs:
  src=Path('C:/Users/vjinn/AppData/Local/Temp')/('codex-clipboard-'+token+'.png');dest=OUT/'references/photos'/(label+'.png');shutil.copy2(src,dest)
  sources.append({'file':str(dest.relative_to(OUT)),'original':str(src),'sha256':sha(src),'subject':label})
 editable={o.name for o in s.objects if (o.get('construction_building') in ('left_changgo','right_ansarang') and any(k in o.name for k in ('.roof.rafters','.roof.boarding'))) or o.name.startswith('Jung.gate floor')}
 protected={o.name:fingerprint(o) for o in s.objects if o.type=='MESH' and o.name not in editable}
 wood=bpy.data.materials['North anchae wood'];lime=bpy.data.materials['North lime plaster'];iron=bpy.data.materials['North forged iron']
 def flush(bid,palette='gate'):
  obs=tag_flush(bid);setup_art(palette)
  for o in obs:
   if bid=='jung':o['northExtension']=False
   if bid=='jung' and o.data.materials[0]==wood:
    o.data.materials[0]=bpy.data.materials['Jung dark walnut']
    aligned_grain(o)
   elif o.data.materials[0]==wood:
    art.art_uv(o,'beam' if any(k in o.name for k in ('beam','purlin','lintel')) else 'wood')
   o['photoBearingRepair']=True;o['detailAuthority']='Supplied late Sep29 photos; roof/opening axes retained; joint details photo fitted'
   added.append(o.name)
  return obs
 def box_from(n,lo,hi,mat):g.box(n,tuple((a+b)/2 for a,b in zip(lo,hi)),tuple(b-a for a,b in zip(lo,hi)),mat)
 # Side gates: ties physically touch existing header, all three purlins and
 # king posts. This is a roof assembly, not a lowered floating roof shell.
 gate_records=[]
 for bid in ('left_changgo','right_ansarang'):
  g.BATCHES.clear();g.set_transform(lambda p:p);nm='PhotoRepair.'+bid
  post=bpy.data.objects['V27.'+bid+'.frame.post'];plo,phi=bounds(post)
  xs=[float((bounds(post,ids)[0][0]+bounds(post,ids)[1][0])/2) for ids in groups(post.data)]
  center=(plo+phi)/2;head=bounds(bpy.data.objects['V27.'+bid+'.frame.lintel'])[1][2]
  purlin=bpy.data.objects['V28.'+bid+'.roof.purlin'];ps=[bounds(purlin,ids) for ids in groups(purlin.data)];ps.sort(key=lambda r:r[0][1])
  eavebottom=min(lo[2] for lo,hi in ps);ymin=min(lo[1] for lo,hi in ps);ymax=max(hi[1] for lo,hi in ps);top=eavebottom-.002
  for k,x in enumerate(xs):
   # The deeper centre intersects the original header by 8 mm; cantilever
   # ends taper, with no prop crossing the door opening or decorating stone.
   width=.18 if bid=='left_changgo' else .15;bot=min(head-.008,top-.15)
   g.box(nm+'.bearing.transverse beam '+str(k),(x,(ymin+ymax)/2,(top+bot)/2),(width,ymax-ymin+.23,top-bot),wood)
   for j,(lo,hi) in enumerate(ps):
    y=(lo[1]+hi[1])/2;low=top-.006;high=lo[2]+.0005
    # Minimum 45-mm seat; the middle seat is a proper short king post.
    low=min(low,high-.045)
    g.box(nm+'.bearing.purlin seat '+str(k)+' '+str(j),(x,y,(low+high)/2),(width*.83,.13,high-low),wood)
   for sign in (-1,1):
    g.rod(nm+'.bearing.short knee '+str(k),(x,center[1],head-.22),(x,center[1]+sign*.39,bot+.026),.052,wood,4)
  # The upper slot between separate header courses needs solid bearing
  # blocks at the posts, not a daylight slit running across the whole gate.
  for x in xs:g.box(nm+'.bearing.header neck',(x,center[1],head-.135),(.19,.205,.28),wood)
  g.box(nm+'.bearing.header infill',(center[0],center[1],head-.165),(abs(xs[-1]-xs[0])+.12,.18,.09),wood)
  # Closed triangular wind boards below each sloping verge, following the
  # retained roof envelope. Sheet090 explicitly depicts this side closure.
  board=bpy.data.objects['V28.'+bid+'.roof.boarding'];blo,bhi=bounds(board);cy=center[1]
  for side in (-1,1):
   x=center[0]+side*((bhi[0]-blo[0])/2-.105)
   yy=np.linspace(ymin-.05,ymax+.05,17)
   cloud=np.array([(board.matrix_world@v.co)[:] for v in board.data.vertices])
   # Register the edge to the actual curved underside, including end lift.
   zz=[]
   for y in yy:
    near=cloud[np.argsort((cloud[:,0]-x)**2+(cloud[:,1]-y)**2)[:8]]
    A=np.column_stack((near[:,0]-x,near[:,1]-y,np.ones(len(near))))
    zz.append(float(np.linalg.lstsq(A,near[:,2],rcond=None)[0][2])-.011)
   lower=top-.07
   old=g.TRANSFORM;g.set_transform(lambda p,x=x:(x+p[1],p[0],p[2]))
   d.extruded_profile(nm+'.gable wind board',[(yy[0],lower),(yy[-1],lower)]+list(zip(yy[::-1],zz[::-1])),-.0225,.0225,wood)
   g.set_transform(old)
  flush(bid)
  # Restore readable ROUND rafters: old 52-mm cylinders were thin sticks.
  ob=bpy.data.objects['V28.'+bid+'.roof.rafters'];ob.data=ob.data.copy();inv=ob.matrix_world.inverted()
  for ids in groups(ob.data):
   pts=np.array([(ob.matrix_world@ob.data.vertices[i].co)[:] for i in ids]);mid=pts.mean(0);_,basis=np.linalg.eigh((pts-mid).T@(pts-mid));axis=basis[:,-1];along=np.outer((pts-mid)@axis,axis);radial=pts-mid-along
   radius=np.mean(np.linalg.norm(radial,axis=1));q=mid+along+radial*(.044/radius)
   for i,p in zip(ids,q):ob.data.vertices[i].co=inv@Vector(p)
  ob.data.update();changed.append(ob.name)
  # Lime infill is confined to the underside, with round timber projecting.
  board.data=board.data.copy();idx=len(board.data.materials);board.data.materials.append(lime)
  for p in board.data.polygons:
   if (board.matrix_world.to_3x3()@p.normal).z<-.2:p.material_index=idx
  changed.append(board.name)
  gate_records.append({'gate':bid,'headerTop':float(head),'eavePurlinBottom':float(eavebottom),'previousUnsupportedGap':float(eavebottom-head),'photoRafterDiameter':.088,'roofEnvelopePreserved':True,'doorDimensionsPreserved':True})
 # Jungmun WD01: retain the approved facade and door dimensions; replace
 # just the erroneous plank passage with compacted earth and a curved sill.
 g.BATCHES.clear();g.set_transform(lambda p:p)
 for o in list(s.objects):
  if o.name.startswith('Jung.gate floor'):removed.append(o.name);bpy.data.objects.remove(o,do_unlink=True)
 earth=bpy.data.materials['North earthen plaster']
 g.box('PhotoRepair.jung.passage earth',(1.285,14.175,1.704),(2.57,1.99,.09),earth)
 # Broad but worn natural threshold, rising at both ends as photographed.
 n='PhotoRepair.jung.curved threshold';ys=np.linspace(13.28,15.07,19)
 for j,(ya,yb) in enumerate(zip(ys,ys[1:])):
  def zz(y):return 1.70+.06*(abs(y-14.175)/.895)**1.7+.002*math.sin(y*17)
  pa=[(-.29,ya,zz(ya)),(-.08,ya,zz(ya)+.009),(-.08,yb,zz(yb)+.009),(-.29,yb,zz(yb))]
  pb=[(x,y,z+.14) for x,y,z in pa]
  for ids in ((0,3,2,1),(4,5,6,7),(0,1,5,4),(1,2,6,5),(2,3,7,6),(3,0,4,7)):
   vv=pa+pb;g.face(n,[vv[i] for i in ids],wood)
 # A solid header above the retained WD01 70-mm lintel joins the large
 # original beam. Its inner edge leaves the 1670x2010 door envelope intact.
 g.box('PhotoRepair.jung.passage outer lintel',(-.044,14.175,3.925),(.22,2.10,.19),wood)
 for y in (13.275,15.075):
  g.box('PhotoRepair.jung.passage outer jamb',(-.012,y,2.80),(.225,.102,2.11),wood)
 # Pegs and pivot bearings are structural hardware, small relative to wood.
 for y in (13.32,15.03):
  g.rod('PhotoRepair.jung.wooden pivot peg',(-.06,y,3.74),(-.06,y,3.87),.024,wood,16)
 # White lime backing follows the measured native rafters. The round wood
 # remains exposed below it, including the full depth of the gateway.
 cloud=[]
 for key in ('Jung.attic rafter','Jung.main roof.lower exposed rafters'):
  o=bpy.data.objects[key]
  cloud.extend((o.matrix_world@v.co)[:] for v in o.data.vertices if 13.30<(o.matrix_world@v.co).y<15.08)
 sections={}
 for x,y,z in cloud:
  k=round(x,3);sections[k]=max(z,sections.get(k,-999))
 grid=sorted(sections);zs=[sections[x] for x in grid]
 for xa,xb in zip(np.linspace(-1.07,3.64,48),np.linspace(-1.07,3.64,48)[1:]):
  za=float(np.interp(xa,grid,zs))+.012;zb=float(np.interp(xb,grid,zs))+.012
  vv=[(xa,13.29,za),(xa,15.07,za),(xb,15.07,zb),(xb,13.29,zb)]
  g.face('PhotoRepair.jung.roof lime backing',vv,lime)
  g.face('PhotoRepair.jung.roof lime backing',[(x,y,z+.025) for x,y,z in reversed(vv)],lime)
 flush('jung')
 c['doors'].append({'building':'jung','id':'jung_WD01_passage','prefix':'V26.Jung.WD01 door','hinges':[[0,15.006,1.76],[0,13.344,1.76]],'rotationSigns':[1,-1],'width':1.662,'height':2.01,'doorBottom':1.76,'state':'closed','authority':'Retained WD01 geometry; hinges at actual jamb-side leaf edges, opening angle illustrative'})
 # Main Soseul gate: supports underneath the raised central roof, connected
 # to the existing four post heads; lower wings keep their original forms.
 r=south['buildings']['main_gate'];rot=Matrix.Rotation(r['angle'],3,'Z');origin=Vector((*r['center'],0));world=lambda p:origin+rot@Vector(p)
 local=lambda p:rot.transposed()@(Vector(p)-origin)
 g.BATCHES.clear();g.set_transform(world);nm='PhotoRepair.main_gate.bearing'
 pur=bpy.data.objects['PhotoGate.roof supporting purlin'];localparts=[]
 for ids in groups(pur.data):
  a=np.array([local(pur.matrix_world@pur.data.vertices[i].co)[:] for i in ids]);lo=a.min(0);hi=a.max(0)
  if lo[2]>2.8:localparts.append((lo,hi))
 posthead=3.09215
 for side in (-1,1):
  x=side*1.1625
  for lo,hi in localparts:
   y=(lo[1]+hi[1])/2
   g.box(nm+'.eave seat',(x,y,(posthead+lo[2])/2),(.24,.25,max(.045,lo[2]-posthead+.008)),wood)
  g.box(nm+'.tie',(x,0,3.119),(.22,2.70,.105),wood)
  g.box(nm+'.king post',(x,0,3.43),(.17,.18,.54),wood)
 g.box(nm+'.ridge purlin',(0,0,3.735),(3.56,.17,.13),wood)
 flush('main_gate')
 # Anchae's existing shelf needs suspended brackets and stored bamboo,
 # not another duplicate horizontal rail across the facade.
 r=next(r for r in c['buildings'] if r['id']=='anchae');rot=Matrix.Rotation(r['angle'],3,'Z');origin=Vector((*r['center'],r['datum']));world=lambda p:origin+rot@Vector(p)
 g.BATCHES.clear();g.set_transform(world)
 shelf=bpy.data.objects['North.anchae.photo sireong shelf rail']
 pp=np.array([(rot.transposed()@(shelf.matrix_world@v.co-origin))[:] for v in shelf.data.vertices]);slo,shi=pp.min(0),pp.max(0)
 for i in range(3):
  y=slo[1]+.065+i*(shi[1]-slo[1]-.13)/2;z=shi[2]+.021+i*.005
  g.rod('PhotoRepair.anchae.stored pole',(slo[0]+.1,y,z),(shi[0]-.12-i*.18,y,z+.01),.025 if i<2 else .031,wood,12)
  for x in np.arange(slo[0]+.20,shi[0]-.3,.58):g.rod('PhotoRepair.anchae.bamboo node',(x,y,z),(x+.018,y,z),.028,wood,12)
 flush('anchae','anchae')
 g.set_transform(lambda p:p);bpy.context.view_layer.update()
 assert all(n in bpy.data.objects and fingerprint(bpy.data.objects[n])==h for n,h in protected.items()),'Unrelated approved geometry/material changed'
 from validate_gate_bearings import check
 checks=check();assert all(r['pass'] for r in checks),json.dumps(checks)
 audit={'sourceSceneSha256':sha(backup),'sources':sources,'added':added,'removed':removed,'modified':changed,'protectedMeshes':len(protected),'gates':gate_records,'bearingChecks':checks,'authority':'Roof envelopes and door measurements retained. Supporting joints, threshold wear and shelf fittings reconstructed from supplied photographs. Left gate sheet021 association remains unconfirmed.'}
 bpy.ops.wm.save_as_mainfile(filepath=str(source),compress=True);audit['sceneSha256']=sha(source)
 c['gateBearingRepair']=audit;contract.write_text(json.dumps(c,ensure_ascii=False,indent=2),encoding='utf8')
 (OUT/'gate-bearing-repair.json').write_text(json.dumps(audit,ensure_ascii=False,indent=2),encoding='utf8')
 print('REPAIRED',len(added),'new parts;',len(protected),'protected;',len(checks),'bearing tests',flush=True)

if __name__=='__main__':main()
