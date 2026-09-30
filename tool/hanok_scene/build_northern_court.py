"""Northern buildings from their own drawing axes and byte-preserved artwork.

Never rebuild the accepted Sarang/Jung pair. Site registration is a tracing of
sheet 002, not a claim of a new measured survey. Geometry wins over conflicting
painted viewpoints; the latter supply pigment and craft, not invented bays.
"""
from pathlib import Path
import ast, bpy, hashlib, json, math, random, sys
import numpy as np
from mathutils import Vector
sys.path.insert(0,str(Path(__file__).parent))
from northern_photo_details import add_photo_details
from northern_timber_sections import apply_sections
from refine_northern_materials import apply_craft_surfaces
from northern_mineral_surfaces import apply_mineral_surfaces
from northern_tile_ends import refine_tile_end_profiles,give_tile_shells_depth
from northern_shrine_gate_roof import refine_shrine_gate_roof
from northern_painted_timber import apply_painted_timber
from northern_shrine_joinery import refine_shrine_joinery
from northern_roof_envelope import refine_roof_envelopes
from northern_wall_joints import close_anchae_wall_joints
from northern_anchae_plan import repair_anchae_plan
from northern_anchae_veranda import refine_anchae_veranda
from northern_anchae_rear_access import refine_anchae_rear_access
from northern_anchae_hall_access import refine_anchae_hall_access
ROOT=Path(__file__).resolve().parents[2]
BASE=ROOT/'assets_unused/pending_review/hwalju-blueprint-review'
OUT=BASE/'northern-court'; REF=OUT/'references'; SOUTH=BASE/'side-connections'
OLD=Path('C:/dev/hangulsori/ko_lernen_app_worktrees/hanok-warm-stone-20260923')
sys.path.insert(0,str(OLD/'tool/hanok_scene'))
import reconstruction_geometry as g
import reference_detail_geometry as d
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
bpy.ops.wm.open_mainfile(filepath=str(SOUTH/'scene.blend'))
s=bpy.context.scene; bpy.context.view_layer.update()
def fingerprint(o):
 h=hashlib.sha256();h.update(np.array(o.matrix_world,dtype=np.float64).tobytes())
 h.update(np.array([v.co[:] for v in o.data.vertices],dtype=np.float32).tobytes())
 h.update(str([tuple(p.vertices) for p in o.data.polygons]).encode())
 h.update(str([m.name for m in o.data.materials]).encode());return h.hexdigest()
protected={o.name:fingerprint(o) for o in s.objects if o.type=='MESH'}
assert not any(o.get('construction_building') in ('anchae','arae','angotgan','gokgan','sadang','sadangmun') for o in s.objects)
for node in ast.parse((Path(__file__).parent/'refine_canonical_gates.py').read_text(encoding='utf8')).body:
 if isinstance(node,ast.FunctionDef) and node.name in ('new_material','pigment','components','art_uv'):
  source=ast.unparse(node).replace("('beam', 'stone', 'tile')", "('beam', 'stone', 'tile', 'decoration', 'floor')")
  exec(compile(source,'canonical pigment helpers','exec'))
def flat(name,rgb,rough=.85,metal=0):
 m=new_material('North '+name);p=m.node_tree.nodes.get('Principled BSDF');p.inputs['Base Color'].default_value=(*rgb,1);p.inputs['Roughness'].default_value=rough;p.inputs['Metallic'].default_value=metal;return m
paper=flat('warm hanji',(.68,.62,.47));lime=flat('lime plaster',(.65,.59,.47));clay=flat('earthen plaster',(.43,.30,.17));soil=flat('tamped earth',(.34,.28,.18));iron=flat('forged iron',(.025,.022,.019),.66,.65)
red=flat('weathered vermilion',(.32,.065,.027));green=flat('aged blue green',(.04,.145,.09));yellow=flat('ochre painted line',(.48,.29,.08));blue=flat('taegeuk indigo',(.014,.057,.10));black=flat('recess shadow',(.018,.014,.009))
end=flat('lime tile ends',(.61,.55,.41))
# An unrestricted substring also selected pale ceramic END materials. Use only
# the six fired-grey body materials, exactly as on the accepted main gate.
tiles=[bpy.data.materials[f'Ansarang retained V33 main_gate source ceramic {i}'] for i in range(6)]
created=[]; mapped=[]; doors=[]; building_records=[]; openings=[]
PIGMENT={
 'anchae':{'post':[(.423,.405,.431,.64)],'wood':[(.242,.477,.255,.59)],'beam':[(.352,.610,.413,.621)],'stone':[(.255,.705,.29,.736)]},
 'arae':{'post':[(.533,.483,.547,.73)],'wood':[(.543,.51,.554,.70)],'floor':[(.575,.783,.596,.788)],'beam':[(.21,.786,.30,.803)],'stone':[(.406,.862,.44,.884)]},
 'angotgan':{'post':[(.44,.537,.454,.748)],'wood':[(.483,.558,.497,.714)],'beam':[(.29,.515,.422,.528)],'stone':[(.20,.80,.233,.813)]},
 'gokgan':{'post':[(.402,.52,.41,.814)],'wood':[(.194,.648,.206,.800)],'beam':[(.425,.572,.565,.581)],'stone':[(.218,.854,.248,.870)]},
 'sadang':{'post':[(.500,.57,.513,.75)],'wood':[(.250,.793,.280,.800)],'floor':[(.250,.793,.280,.800)],'beam':[(.57,.397,.63,.414)],'decoration':[(.371,.461,.465,.482)],'stone':[(.305,.882,.331,.916)]},
 'sadangmun':{'post':[(.205,.445,.23,.735)],'wood':[(.285,.45,.31,.70)],'beam':[(.31,.412,.58,.425)],'stone':[(.25,.81,.35,.835)]}
}
def begin(ident,center,angle,datum,bays,depth,authority):
 global ID,TR,ART,base_image,materials,regions,wood,beam,stone,post,NM
 ID=ident;NM='North.'+ident;TR=d.basis((*center,datum),angle);g.set_transform(TR)
 ART=REF/ident/'canonical.png';base_image=bpy.data.images.load(str(ART),check_existing=True);materials={};regions=PIGMENT[ident]
 wood=pigment('wood');beam=pigment('beam');post=pigment('post');stone=pigment('stone')
 for m in materials.values():m.name='North '+ident+' '+m.get('surfaceKind','pigment')
 record={'id':ident,'center':center,'angle':angle,'datum':datum,'bays':bays,'bodyWidth':sum(bays),'bodyDepth':depth,'authority':authority,'canonicalSha256':sha(ART),'placementAuthority':'Sheet 002 pixel registration; center traced, yaw aligned with existing registered estate'}
 building_records.append(record);return np.r_[-sum(bays)/2,-sum(bays)/2+np.cumsum(bays)].tolist()
def finish():
 add_photo_details(globals())
 obs=g.flush();g.BATCHES.clear()
 for o in obs:
  mat=o.data.materials[0];kind=next((k for k,m in materials.items() if m==mat),None)
  if ID in ('sadang','sadangmun') and '.roof.gable timber' in o.name:art_uv(o,'post')
  elif kind:art_uv(o,kind)
  elif mat in tiles:
   uv=o.data.uv_layers.new(name='Ansarang retained PBR')
   for poly in o.data.polygons:
    axes=[a for a in range(3) if a!=int(np.argmax(np.abs(poly.normal)))]
    for li in poly.loop_indices:
     v=o.data.vertices[o.data.loops[li].vertex_index].co;uv.data[li].uv=(v[axes[0]]/.85,v[axes[1]]/.85)
   o.data.uv_layers.active=uv;uv.active_render=True
   # The inherited baked ceramic multiplies by this vertex color. Missing
   # attributes evaluate black in Cycles, although glTF defaults to white.
   attr=o.data.color_attributes.new(name='Craft tonal variation',type='FLOAT_COLOR',domain='CORNER')
   rng=random.Random(o.name)
   for poly in o.data.polygons:
    tone=rng.uniform(.93,1.07)
    for li in poly.loop_indices:attr.data[li].color=(tone,tone,tone,1)
   o.data.color_attributes.active_color=attr
  for mod in o.modifiers:
   if mod.type=='BEVEL':mod.width=.0035 if any(k in o.name for k in ('sal','lattice','door','paint')) else .008;mod.segments=2
  for k,v in {'construction_building':ID,'construction_first':1,'construction_last':99,'source_object_name':o.name,'northExtension':True}.items():o[k]=v
 created.extend(obs);print('BUILT',ID,len(obs),flush=True)
def box(tag,center,size,mat=None):g.box(NM+'.'+tag,center,size,mat or wood)
def boarded(tag,a,b,y,lo,hi,mat=None):
 n=max(1,round((b-a)/.16))
 for i in range(n):box(tag, (a+(i+.5)*(b-a)/n,y,(lo+hi)/2),((b-a)/n-.0025,.030,hi-lo),mat)
def frame(xs,ys,floor,head,round_posts=False):
 rng=random.Random(ID)
 for x in xs:
  for y in ys:
   g.rock(NM+'.foundation individual plinth',(x,y,.22),(.45,.40,.20),stone,rng)
   if round_posts and y==ys[0]:
    g.rod(NM+'.round stone plinth',(x,y,.20),(x,y,.37),.175,stone,24)
    g.rod(NM+'.frame round red column',(x,y,.37),(x,y,head),.120,post,24)
   else:
    size=.230 if round_posts else .195 if ID=='gokgan' else .19
    box('frame square post',(x,y,(.30+head)/2),(size,size,head-.30),post)
  box('frame transverse beam',(x,(ys[0]+ys[-1])/2,head-.01),(.22,ys[-1]-ys[0]+.26,.26),beam)
 for y in ys:
  for z,sz in ((floor-.13,.17),(head-.08,.20)):
   if round_posts and y==ys[0] and z<floor:continue
   box('frame longitudinal beam',((xs[0]+xs[-1])/2,y,z),(xs[-1]-xs[0]+.17,.18,sz),beam)
 for x in xs:
  for y in (ys[0],ys[-1]):
   for z in (floor+.06,head-.14):g.rod(NM+'.frame mortise peg',(x,y-.102,z),(x,y-.111,z),.012,wood,10)
def foundation(w,depth,top=.25,margin=.5):
 g.stones(NM+'.foundation',-w/2-margin,w/2+margin,-depth/2-margin,depth/2+margin,-.06,top,[stone,stone],32)
 box('foundation earth top',(0,0,top-.025),(w+margin*2-.20,depth+margin*2-.20,.08),soil)
def floor(a,b,y0,y1,z):
 for yy in np.arange(y0+.12,y1,.60):box('floor under joists',((a+b)/2,yy,z-.16),(b-a,.10,.17),beam)
 g.planks(NM+'.floor individual boards',a,b,y0,y1,z,[pigment('floor') if 'floor' in regions else wood],axis='Y',thick=.045 if ID in ('anchae','sadang') else .05,width=.18)
def panel(tag,a,b,y,lo,hi,opening=None,mat=None):
 g.wall_opening(NM+'.'+tag,a,b,y,lo,hi,opening,mat or lime,beam,thickness=.09)
def sal(tag,cx,y,bottom,w,h,leaves=2,reverse=False,paint=False):
 d.lattice(NM+'.'+tag,cx-w/2,cx+w/2,y,bottom,bottom+h,green if paint else wood,paper,leaves=leaves,profile='sarang-long',solid=.14,reverse=reverse)
 openings.append({'building':ID,'tag':tag,'center':[cx,y,bottom+h/2],'width':w,'height':h,'leaves':leaves})
def vent(tag,cx,y,zc,w,h,vertical=False):
 box(tag+' black void',(cx,y+.025,zc),(w,.03,h),black)
 d.panel_frame(NM+'.'+tag,cx-w/2,cx+w/2,y,zc-h/2,zc+h/2,wood,.09,.035)
 if vertical:
  for x in np.arange(cx-w/2+.10,cx+w/2,.12):box(tag+' vertical grille',(x,y-.02,zc),(.025,.045,h),wood)
 else:
  for k in (-1,0,1):box(tag+' three horizontal bars',(cx,y-.022,zc+k*h/4),(w,.040,.022),wood)
def door(tag,cx,y,bottom,w,h,paint=False,taegeuk=False):
 prefix=NM+'.'+tag;hinges=[]
 for leaf in range(2):
  a=cx-w/2+leaf*w/2+.004;b=a+w/2-.008;nm=prefix+f'.leaf{leaf+1}'
  n=max(2,round((b-a)/.13))
  for i in range(n):g.box(nm+'.solid board',(a+(i+.5)*(b-a)/n,y,bottom+h/2),((b-a)/n-.002,.03,h),post if paint else wood)
  for z in (bottom+.14,bottom+h/2,bottom+h-.14):g.box(nm+'.rear rail',((a+b)/2,y+.04,z),(b-a,.065,.065),red if paint else beam)
  for z in (bottom+.16,bottom+h-.16):
   g.box(nm+'.forged hinge',((a+b)/2,y-.022,z),(b-a-.02,.014,.042),iron)
   for x in np.linspace(a+.06,b-.06,3):g.rod(nm+'.nail',(x,y-.025,z),(x,y-.040,z),.014,iron,10)
  hx=b-.06 if leaf==0 else a+.06;g.torus(nm+'.iron ring',(hx,y-.06,bottom+h*.48),.040,.006,iron)
  hinge=a if leaf==0 else b;hinges.append(list(TR((hinge,y+.035,bottom))))
  if taegeuk:
   # Pigment on a solid door: the symbol splits with the two physical leaves.
   radius=.31;cz=bottom+h*.51
   for ix in range(96):
    left=max(-radius+ix*2*radius/96,a-cx);right=min(-radius+(ix+1)*2*radius/96,b-cx)
    if right<=left:continue
    def limits(xx):
     outer=math.sqrt(max(0,radius*radius-xx*xx))
     seam=math.sqrt(max(0,(radius/2)**2-(xx-(radius/2 if xx>0 else -radius/2))**2))*(1 if xx>0 else -1)
     return -outer,seam,outer
    za,zb=limits(left),limits(right)
    for lower,upper,mat in ((0,1,blue),(1,2,red)):
     g.face(nm+'.taegeuk paint',[(cx+left,y-.017,cz+za[lower]),(cx+right,y-.017,cz+zb[lower]),(cx+right,y-.017,cz+zb[upper]),(cx+left,y-.017,cz+za[upper])],mat)
 doors.append({'building':ID,'prefix':prefix,'hinges':hinges,'rotationSigns':[-1,1],'width':w,'height':h,'doorBottom':bottom,'state':'closed'})
 openings.append({'building':ID,'tag':tag,'width':w,'height':h,'leaves':2})
def endwall(tag,x,y0,y1,lo,hi,window=None,angle=math.pi/2):
 old=g.TRANSFORM;g.set_transform(lambda p:old((x-p[1],p[0],p[2])))
 op=None if window is None else (window[0]-window[2]/2,window[0]+window[2]/2,window[1],window[1]+window[3])
 panel(tag,y0,y1,0,lo,hi,op)
 if window:sal(tag+' lattice',window[0],0,window[1],window[2],window[3],window[4])
 g.set_transform(old)
def roof(bounds,eave,ridge,kind='gable',courses=5):
 timber=green if ID in ('sadang','sadangmun') else wood
 field=g.roof(NM+'.roof',bounds,eave,ridge,timber,tiles,end,kind=kind,turn=.20,ridge_turn=.08,columns=round((bounds[1]-bounds[0])/.205),ridge_courses=courses,channels_between_covers=True)
 # Continuous clay/board roof bed seats the separately modeled overlapping
 # ceramic courses. It also gives a solid, shaded underside to the eaves.
 x0,x1,y0,y1=bounds;nx=math.ceil((x1-x0)/.20);ny=math.ceil((y1-y0)/.16)
 for i in range(nx):
  for j in range(ny):
   pts=[(x0+a*(x1-x0)/nx,y0+b*(y1-y0)/ny) for a,b in [(i,j),(i+1,j),(i+1,j+1),(i,j+1)]]
   for dz,mat in [(-.040,tiles[0]),(-.10,lime if ID in ('sadang','sadangmun') else timber)]:g.face(NM+'.roof continuous bed',[(x,y,field(x,y)+dz) for x,y in pts],mat)
 return field

# Anchae: eight measured bays, two-bay daechong, separate kitchen/rooms/rear facade.
xs=begin('anchae',[10.945,20.012],-math.pi/2,1.50,[1.440,2.545,2.570,2.580,2.410,2.555,2.545,1.450],4.525,'2007 front sheet 047 and eight bay axes; 1995 plan retained separately; canonical and eight views for craft')
foundation(sum(np.diff(xs)),4.525,.24,.45)
anchae_basis=TR
def anchae_body(p):
 x,y,z=p
 # The rear edge steps 725mm at the daechong. Preserve the 1175mm
 # front porch rather than scaling the facade or its measured openings.
 if x<xs[4] and y>-.9875:y-=.725*min(1,(y+.9875)/3.25)
 return anchae_basis((x,y,z))
TR=anchae_body;g.set_transform(TR)
building_records[-1]['leftBodyDepth']=3.800
building_records[-1]['rightBodyDepth']=4.525
frame(xs,[-2.2625,-1.0875,2.2625],.62,3.15)
floor(xs[1],xs[-1],-2.26,-1.09,.62);floor(xs[4],xs[6],-1.09,2.2625,.62)
for i in (1,2,3,6):
 box('room ondol raised clay',(sum(xs[i:i+2])/2,.40,.41),(xs[i+1]-xs[i]-.2,2.89,.38),clay)
 box('room warm paper floor',(sum(xs[i:i+2])/2,.40,.616),(xs[i+1]-xs[i]-.22,2.87,.035),paper)
for x in (xs[1],xs[2],xs[4],xs[6],xs[7]):box('interior partition',(x,.50,1.83),(.09,3.42,2.42),lime)
for i,(a,b) in enumerate(zip(xs,xs[1:])):
 cx=(a+b)/2
 if i in (4,5):
  box('open daechong head',(cx,-1.0875,2.97),(b-a-.2,.09,.36),lime)
  # Elevation projects the rear plank doors through an OPEN daechong.
  panel('daechong rear wall',a+.1,b-.1,2.2625,.62,3.12,(cx-.55,cx+.55,.75,2.18))
  door('daechong rear door '+str(i),cx,2.20,.75,1.10,1.43)
 elif i==1:
  panel('kitchen front',a+.1,b-.1,-2.2625,.28,3.12,(cx-.56,cx+.56,.35,2.07),clay);door('kitchen',cx,-2.32,.35,1.12,1.72)
  vent('kitchen high ventilator',cx,-2.324,2.66,1.626,.56)
  panel('kitchen rear',a+.1,b-.1,2.2625,.28,3.12,(cx-.535,cx+.535,1.50,2.43),clay);sal('kitchen rear window',cx,2.20,1.50,1.07,.93)
 elif i in (2,3,6):
  w=1.11;h=1.43 if i!=3 else 1.15;bt=1.0
  panel('room facade',a+.1,b-.1,-1.0875,.62,3.12,(cx-w/2,cx+w/2,bt,bt+h));sal('room front '+str(i),cx,-1.15,bt,w,h)
  panel('room rear',a+.1,b-.1,2.2625,.62,3.12,(cx-.555,cx+.555,.95,2.38));sal('room rear '+str(i),cx,2.20,.95,1.11,1.43)
 else:
  panel('end bay plaster',a+.1,b-.1,-1.0875,.62,3.12,(cx-.44,cx+.44,2.05,2.59));vent('end high lattice '+str(i),cx,-1.15,2.32,.88,.54)
  panel('end bay rear',a+.1,b-.1,2.2625,.62,3.12)
 # Room ceilings remain solid while the daechong exposes its rafters.
 if i not in (4,5):box('room ceiling',(cx,.53,3.05),(b-a-.20,3.24,.045),paper)
endwall('left room end',xs[0],-2.26,2.26,.3,3.12)
endwall('right room end',xs[-1],-2.26,2.26,.62,3.12,(.32,1.01,1.35,1.43,2))
TR=anchae_basis;g.set_transform(TR)
roof((xs[0]-1.27,xs[-1]+1.27,-3.40,3.40),3.55,4.62,'paljak')
# Lower lean-to kitchen at the narrow left end, as the front and side drawing.
old=g.TRANSFORM;g.set_transform(lambda p:old((xs[0]+p[1],p[0],p[2])))
panel('kitchen annex',-1.50,1.65,1.05,.24,2.20,(-.3,.3,.65,1.95),clay);sal('kitchen annex small door',0,1.0,.65,.6,1.3,1)
for x in (-1.5,1.65):box('kitchen annex corner',(x,1.05,1.25),(.15,.15,2.05),post)
g.set_transform(old)
# A single sloping, tiled roof joins the lower kitchen to the main end wall.
for j in range(15):
 y=-1.60+j*.235
 for i in range(5):
  x=xs[0]-1.60+i*.32;z=2.38+(x-(xs[0]-1.60))*.28
  g.face(NM+'.annex roof',[(x,y,z),(x+.34,y,z+.095),(x+.34,y+.23,z+.095),(x,y+.23,z)],tiles[(i+j)%len(tiles)])
  g.rod(NM+'.annex tile cover',(x,y+.11,z+.03),(x+.34,y+.11,z+.125),.035,tiles[0],8)
for cx in ((xs[2]+xs[3])/2,(xs[3]+xs[4])/2,(xs[6]+xs[7])/2):g.rock(NM+'.worn stepping stones',(cx,-2.66,.35),(.90,.43,.18),stone,random.Random(cx))
finish()

# Arae: the current three-bay drawing, NEVER the mislabelled 1990 Jung facade.
xs=begin('arae',[2.855,28.004],0,1.50,[2.44,2.38,2.68],4.0,'2007 sheet 026 roof grid, 7500 overall; WD01..07 schedule; old Jung elevation excluded')
foundation(7.5,4.0,.24,.32);frame(xs,[-2,-.82,2],.55,2.46);floor(-3.75,3.75,-2.03,-.80,.55);floor(xs[0],xs[1],-.80,2,.55)
for i in (1,2):box('ondol room',((xs[i]+xs[i+1])/2,.58,.38),(xs[i+1]-xs[i]-.20,2.64,.34),clay);box('hanji room floor',((xs[i]+xs[i+1])/2,.58,.55),(xs[i+1]-xs[i]-.20,2.64,.035),paper)
for x in xs[1:-1]:box('interior dividing wall',(x,.58,1.51),(.09,2.64,1.92),lime)
for i,(a,b) in enumerate(zip(xs,xs[1:])):
 cx=(a+b)/2;w,h,n=[(1.98,1.34,4),(1.22,1.34,2),(1.11,1.21,2)][i]
 panel('front plaster',a+.10,b-.10,-.82,.55,2.46,(cx-w/2,cx+w/2,.66,.66+h));sal('front WD'+str(i),cx,-.88,.66,w,h,n)
 if i==0:op=(cx-.99,cx+.99,.65,1.90)
 elif i==2:op=(cx-.2775,cx+.2775,.63,2.12)
 else:op=None
 panel('rear plaster',a+.1,b-.1,2,.55,2.46,op)
 if op:sal('rear WD'+str(i),cx,1.94,op[2],op[1]-op[0],op[3]-op[2],4 if i==0 else 1)
 box('room ceiling',(cx,.58,2.40),(b-a-.18,2.64,.04),paper)
endwall('left maru side',-3.75,-.82,2,.55,2.46,(.59,.64,2.30,1.39,4));endwall('right ondol side',3.75,-.82,2,.55,2.46)
roof((-4.40,4.40,-2.93,2.93),2.68,3.85,'gable',9)
g.rock(NM+'.door stepping stone',(0,-2.38,.29),(.99,.33,.18),stone,random.Random(56));finish()

# Four-bay inner store, three measured doors, slatted vents, two storage rooms.
xs=begin('angotgan',[-4.447,21.683],math.pi/2,1.50,[2.25,2.25,2.43,2.43],2.7,'2007 sheets 029/032/034: four bays, three WD1 doors, 1260 lower boards, 940-1000 upper lime panel, floor-to-ridge 4350; ground exposure 440-740')
foundation(9.36,2.7,.44,.60);frame(xs,[-1.35,1.35],.44,2.85)
box('interior two storage rooms',(-.18,0,1.645),(.030,2.51,2.41),wood)
for i,(a,b) in enumerate(zip(xs,xs[1:])):
 cx=(a+b)/2
 for y in (-1.35,1.35):
  if y<0 and i in (0,2,3):
   boarded('front plank wall',a+.095,cx-.45,y,.44,1.85);boarded('front plank wall',cx+.45,b-.095,y,.44,1.85);door('front WD1 '+str(i),cx,y-.025,.44,.9,1.62)
   panel('upper lime strip',a+.095,b-.095,y,1.85,2.85,(cx-.45,cx+.45,1.85,2.06))
  else:
   boarded('rear or closed bay plank wall',a+.095,b-.095,y,.44,1.85)
   op=(cx-.29,cx+.29,2.28,2.66) if y>0 and i==1 else None
   panel('upper lime strip',a+.095,b-.095,y,1.85,2.85,op)
   if op:vent('rear WW3',cx,1.29,2.47,.58,.38)
for x,w,h in [(-4.68,.38,.38),(4.68,.73,.58)]:
 old=g.TRANSFORM;g.set_transform(lambda p,x=x:old((x-p[1],p[0],p[2])))
 boarded('side plank wall',-1.35,1.35,0,.44,1.85);panel('side upper plaster',-1.35,1.35,0,1.85,2.85,(-w/2,w/2,2.40-h/2,2.40+h/2));vent('side measured vent',0,-.051,2.40,w,h);g.set_transform(old)
roof((-5.28,5.28,-2.80,2.80),3.35,4.39,'gable',5);finish()

def hip_roof(w,depth,eave,ridge,ridgelen):
 """Four continuously tiled slopes; there is no gable triangle on Gwang."""
 hx=w/2;hy=depth/2;hr=ridgelen/2
 def pt(side,u,t,dz=0):
  if side<2:
   x=(-hr+u*2*hr)*(1-t)+(-hx+u*2*hx)*t;y=(-1 if side==0 else 1)*hy*t
  else:
   x=(-1 if side==2 else 1)*(hr+(hx-hr)*t);y=(-hy+u*2*hy)*t
  z=eave+(ridge-eave)*(1-t)**1.40+.23*(abs(x)/hx)**8*t*t
  return (x,y,z+dz)
 for side in range(4):
  n=round((w if side<2 else depth)/.205);rows=12
  for col in range(n):
   for row in range(rows):
    u0=col/n;u1=(col+1)/n;t0=row/rows;t1=min(1,(row+1.03)/rows)
    for dz,mat in [(-.04,tiles[0]),(-.10,wood)]:g.face(NM+'.hip roof continuous bed',[pt(side,u0,t0,dz),pt(side,u1,t0,dz),pt(side,u1,t1,dz),pt(side,u0,t1,dz)],mat)
    for strip in range(4):
     a=strip/4;b=(strip+1)/4
     g.face(NM+'.hip roof tiled channels',[pt(side,u0+(u1-u0)*a,t0,-.024*math.sin(a*math.pi)),pt(side,u0+(u1-u0)*b,t0,-.024*math.sin(b*math.pi)),pt(side,u0+(u1-u0)*b,t1,.013-.024*math.sin(b*math.pi)),pt(side,u0+(u1-u0)*a,t1,.013-.024*math.sin(a*math.pi))],tiles[(col+row)%len(tiles)])
    for k in range(6):
     a=k*math.pi/6;b=(k+1)*math.pi/6;uc=(col+.5)/n
     spread=.055/(w if side<2 else depth)
     g.face(NM+'.hip roof curved cover tiles',[pt(side,uc+spread*math.cos(a),t0,.055*math.sin(a)),pt(side,uc+spread*math.cos(b),t0,.055*math.sin(b)),pt(side,uc+spread*math.cos(b),t1,.055*math.sin(b)+.02),pt(side,uc+spread*math.cos(a),t1,.055*math.sin(a)+.02)],tiles[(col*3+row)%len(tiles)])
   u=(col+.5)/n;a=pt(side,u,.64,-.23);b=pt(side,u,1,-.16);g.rod(NM+'.hip roof rafter',a,b,.063,beam,12)
   p=pt(side,u,1,.035);q=list(p);q[1 if side<2 else 0]+=(.04 if side in (1,3) else -.04);g.rod(NM+'.hip roof white ends',p,q,.054,end,12)
   for dz in (-.13,-.21):g.rod(NM+'.hip roof fascia',pt(side,col/n,1,dz),pt(side,(col+1)/n,1,dz),.06,beam,10)
 for level in range(5):
  for j in range(24):
   a=-hr+j*2*hr/24;b=-hr+(j+1)*2*hr/24
   g.rod(NM+'.hip roof five ridge courses',(a,0,ridge+.06+level*.06+.05*(abs(a)/hr)**8),(b,0,ridge+.06+level*.06+.05*(abs(b)/hr)**8),.065,tiles[level%len(tiles)],10)
 for side in (0,1):
  for u in (0,1):
   for k in range(14):
    for level in range(3):g.rod(NM+'.hip roof three hip courses',pt(side,u,k/14,.06+level*.055),pt(side,u,(k+1)/14,.06+level*.055),.055,tiles[level%len(tiles)],10)

# The 1993 sheet 023 is the canonical five-bay store (Gwang on site 002).
# The 2007 same-titled 14240 x 3010 six-bay sheet is a DIFFERENT building.
xs=begin('gokgan',[24.909,10.510],-math.pi/2,1.50,[1.95]*5,5.46,'1993 sheets 023-030: 9750 x 5460, five 1950 bays, two 2730 side bays, central 1360 door; four-slope hip roof with 1350 eaves. Excludes 2007 six-bay store.')
foundation(9.75,5.46,.23,.80);frame(xs,[-2.73,2.73],.25,3.09)
for x in (xs[0],xs[-1]):
 box('side centre post',(x,0,1.695),(.195,.195,2.79),post)
 g.rock(NM+'.side centre plinth',(x,0,.22),(.45,.40,.20),stone,random.Random(x))
for i,(a,b) in enumerate(zip(xs,xs[1:])):
 cx=(a+b)/2
 for y in (-2.73,2.73):
  if i==2 and y<0:
   boarded('central door sideboards',a+.1,cx-.68,y,.25,1.97);boarded('central door sideboards',cx+.68,b-.1,y,.25,1.97);door('central grain door',cx,y-.025,.25,1.36,1.72)
  else:
   boarded('vertical store siding',a+.095,b-.095,y,.25,1.97)
   box('siding middle rail',(cx,y-.025,1.0),(b-a-.19,.09,.12),beam)
  op=(cx-.275,cx+.275,2.23,2.78) if i in (1,3) else None
  panel('upper store lime band',a+.095,b-.095,y,1.97,3.09,op)
  if op:vent('store slatted opening',cx,y-.06,2.505,.55,.55,True)
for x in (-4.875,4.875):
 old=g.TRANSFORM;g.set_transform(lambda p,x=x:old((x-p[1],p[0],p[2])))
 for a,b in ((-2.73,0),(0,2.73)):
  boarded('side siding',a+.095,b-.095,0,.25,1.97);box('side siding rail',((a+b)/2,-.025,1.0),(b-a-.19,.09,.12),beam);panel('side lime band',a+.095,b-.095,0,1.97,3.09,((a+b)/2-.275,(a+b)/2+.275,2.23,2.78));vent('side vents',(a+b)/2,-.06,2.505,.55,.55,True)
 g.set_transform(old)
hip_roof(12.45,8.16,3.09,5.225,4.875)
for i in range(2):g.stones(NM+'.central threshold step',-.82,.82,-3.48-i*.28,-3.20-i*.28,-.06,.22-i*.08,[stone,stone],18+i)
finish()

# Shrine: round front columns, recessed doors, raised timber sanctuary, one roof.
xs=begin('sadang',[24.311,22.429],-math.pi/2,1.50,[2.15,2.45,2.16],4.2,'2007 shrine sheet 058 floor and elevations; 6760 x 4200, front porch 1260; double eaves means one roof with two rafter rows')
foundation(6.76,4.2,.20,.8);frame(xs,[-2.10,-.84,2.10],.51,3.27,True);floor(-3.38,3.38,-2.10,2.10,.51)
for i,(a,b) in enumerate(zip(xs,xs[1:])):
 cx=(a+b)/2;w=b-a-.50
 panel('front sanctuary infill',a+.115,b-.115,-.84,.51,3.20,(cx-w/2,cx+w/2,.62,2.84));sal('green sanctuary pair '+str(i),cx,-.91,.62,w,2.22,2,paint=True)
 panel('rear sanctuary plaster',a+.115,b-.115,2.10,.51,3.20)
endwall('left sanctuary plaster',-3.38,-.84,2.10,.51,3.20);endwall('right sanctuary plaster',3.38,-.84,2.10,.51,3.20)
for y in (-2.10,2.10):
 for z in (3.05,3.30):
  box('dancheong painted beam',(0,y,z),(6.99,.22,.21),green)
  for a,b in zip(xs,xs[1:]):box('dancheong floral panel',((a+b)/2,y-.116,z),(b-a-.30,.006,.165),pigment('decoration'))
 for x in xs:d.bracket(NM+'.dancheong carved bracket',x,y,3.38,green,side=-1 if y<0 else 1)
 for x in np.arange(-3.18,3.3,.30):
  for k in range(8):
   a=k*math.tau/8;xx=x+.032*math.cos(a);zz=3.49+.032*math.sin(a)
   g.rod(NM+'.dancheong flower petal',(xx,y-.13,zz),(xx,y-.136,zz),.015,yellow,8)
  g.rod(NM+'.dancheong red flower eye',(x,y-.137,3.49),(x,y-.140,3.49),.018,red,10)
shrine_roof=roof((-4.18,4.18,-2.97,2.97),3.70,5.16,'gable',5)
for side in (-1,1):
 for x in np.arange(-4.08,4.12,.205):
  box('double eave square buyeon',(x,side*2.76,3.45),(.068,.53,.075),green)
  g.rod(NM+'.painted rafter end',(x,side*2.94,3.49),(x,side*2.98,3.49),.047,yellow,12)
for cx in [(a+b)/2 for a,b in zip(xs,xs[1:])]:g.rock(NM+'.granite step',(cx,-3.09,.16),(.81,.30,.16),stone,random.Random(cx))
finish()

# Shrine side gate: sheet 086 is the red taegeuk gate, not the large south gate.
xs=begin('sadangmun',[19.859,16.853],0,1.50,[1.350],1.0,'2007 shrine side-gate sheet 086: posts 1350 apart, door 1020 x 1500, roof 2570 x 1940')
foundation(1.48,1.48,.20,.06)
for x in (-.675,.675):g.rod(NM+'.round vermilion gatepost',(x,0,.20),(x,0,2.15),.085,red,18)
box('threshold',(0,0,.28),(1.18,.15,.15),red)
for z in (1.92,2.09):box('green lintel',(0,0,z),(1.59,.22,.14),green)
door('taegeuk leaves',0,-.025,.35,1.020,1.500,True,True)
for x in (-.52,.52):
 for y in (-.5,.5):box('rear roof support',(x,y,1.09),(.07,.08,1.8),red)
roof((-1.285,1.285,-.97,.97),2.20,2.84,'gable',3);finish()

# Independent enclosure walls. Straight segments meet at the same endpoint;
# openings are explicit intervals, never walls drawn through another building.
begin('anchae',[0,0],0,0,[1],1,'Landscape uses registered site002 lines; non-surveyed wall heights remain reconstruction')
ID='north_site';NM='North.site';g.set_transform(lambda p:p)
walls=[]
def wall(name,start,stop,z,height=1.35):
 old=g.TRANSFORM;length=math.dist(start,stop);basis=d.basis((*start,z),math.atan2(stop[1]-start[1],stop[0]-start[0]));g.set_transform(basis)
 box(name+' earth core',(length/2,0,height/2),(length,.32,height),clay)
 rng=random.Random(name)
 for side in (-1,1):
  for row in range(max(1,round(height/.22))):
   x=0
   while x<length-.03:
    w=min(length-x,rng.uniform(.28,.46));g.rock(NM+'.'+name+' irregular stone',(x+w/2,side*.19,(row+.5)*height/round(height/.22)),(w-.02,.12,height/round(height/.22)-.016),stone,rng);x+=w
 g.roof(NM+'.'+name+' coping',(0,length,-.31,.31),height+.025,height+.105,beam,tiles,end,turn=0,ridge_turn=0,columns=max(2,round(length/.19)),ridge_courses=2)
 walls.append({'name':name,'start':start,'stop':stop,'base':z,'height':height});g.set_transform(old)
# Shrine courtyard with a door gap precisely aligned to the measured posts.
for name,a,b in [('shrine west',(18.15,16.853),(18.15,29.0)),('shrine rear',(18.15,29.0),(28.1,29.0)),('shrine east',(28.1,29.0),(28.1,16.853)),('shrine gate left',(18.15,16.853),(19.184,16.853)),('shrine gate right',(20.534,16.853),(28.1,16.853))]:wall(name,a,b,1.50,1.35)
# The small jar yard occupies the space behind Anchae and left of the shrine gate.
for name,a,b in [('jar yard rear',(13.60,30.2),(18.15,30.2)),('jar yard return',(18.15,29),(18.15,30.2)),('rear court west',(-6.8,31.25),(13.60,31.25)),('rear court east',(13.60,31.25),(13.60,30.2)),('inner store west',(-6.8,31.25),(-6.8,15.4)),('inner court south west',(-6.8,15.4),(-1.30,15.4))]:wall(name,a,b,1.50,1.12)
# Stepping stones indicate a walkable route; no fabricated portal blocks it.
rng=random.Random(2958)
routes=[[(18.092,1.7),(18.092,10.2),(18.6,14.8),(19.859,16.45)],[(18.6,14.8),(16.1,14.8),(15.6,23.8),(15.6,24.80)],[(18.092,10.2),(15.0,10.2),(7.1,10.2),(5.5,17.5),(5.5,22.0)],[(5.5,17.5),(1.0,17.5),(1.0,15.6)]]
for j,path in enumerate(routes):
 for a,b in zip(path,path[1:]):
  n=max(1,round(math.dist(a,b)/.72))
  for k in range(n):
   x=a[0]+(b[0]-a[0])*(k+.5)/n;y=a[1]+(b[1]-a[1])*(k+.5)/n
   z=1.5 if y>8.2 else 1.20+.30*max(0,min(1,(y-5.2)/3))
   if y<5.1:z=(1.2+.3*max(0,min(1,(y-5.2)/3)))*max(0,min(1,(y-.5)/4.6))
   g.rock(NM+'.path worn stepping stone',(x,y,z+.027),(rng.uniform(.38,.58),rng.uniform(.32,.48),.075),stone,rng)
# Thrown earthenware jars: thick hollow mouth, rolled lip and separate domed lid.
jar_mats=[flat('onggi glaze '+str(i),(.085+i*.017,.037+i*.01,.014+i*.006),.40) for i in range(5)]
g.stones(NM+'.jar platform',14.55,17.25,25.25,28.50,1.49,1.66,[stone,stone],77)
for j,(x,y,r,h) in enumerate([(15.05,26,.35,.66),(15.94,26,.38,.80),(16.70,26.2,.31,.61),(15.15,27.05,.43,.88),(16.20,27.16,.43,.92),(16.85,28,.26,.48),(15.1,28.05,.29,.55)]):
 profile=[(r*.56,0),(r*.72,.06*h),(r,.38*h),(r*.99,.60*h),(r*.77,.84*h),(r*.59,.94*h),(r*.65,.97*h),(r*.65,h),(r*.55,h),(r*.53,.93*h)]
 for k in range(len(profile)-1):
  for i in range(40):
   a=i*math.tau/40;b=(i+1)*math.tau/40;p0,z0=profile[k];p1,z1=profile[k+1]
   g.face(NM+'.onggi '+str(j),[(x+p0*math.cos(a),y+p0*math.sin(a),1.66+z0),(x+p0*math.cos(b),y+p0*math.sin(b),1.66+z0),(x+p1*math.cos(b),y+p1*math.sin(b),1.66+z1),(x+p1*math.cos(a),y+p1*math.sin(a),1.66+z1)],jar_mats[j%5])
 for k in range(8):
  r0=r*.68*k/8;r1=r*.68*(k+1)/8
  for i in range(40):
   a=i*math.tau/40;b=(i+1)*math.tau/40
   def p(rr,t):return(x+rr*math.cos(t),y+rr*math.sin(t),1.66+h+.065*(1-(rr/(r*.68))**2))
   g.face(NM+'.onggi lid '+str(j),[p(r0,a),p(r0,b),p(r1,b),p(r1,a)],jar_mats[j%5])
finish();building_records.pop() # Landscape is not a duplicate Anchae building.
shrine_gate_craft=refine_shrine_gate_roof(s,building_records)
created=[o for o in s.objects if o.type=='MESH' and o.get('northExtension')]
timber_sections=apply_sections(s,building_records)
shrine_joinery=refine_shrine_joinery(s,building_records)
created=[o for o in s.objects if o.type=='MESH' and o.get('northExtension')]
craft_surfaces=apply_craft_surfaces(s)
tile_end_profiles=refine_tile_end_profiles(s)
tile_shells=give_tile_shells_depth(s)
mineral_surfaces=apply_mineral_surfaces(s)
painted_timber=apply_painted_timber(s)
roof_envelopes=refine_roof_envelopes(s,building_records)
wall_joints=close_anchae_wall_joints(s,building_records)
anchae_plan=repair_anchae_plan(s,building_records,doors)
anchae_veranda=refine_anchae_veranda(s,building_records,doors,openings)
anchae_rear_access=refine_anchae_rear_access(s,building_records,doors,openings)
anchae_hall_access=refine_anchae_hall_access(s,building_records,doors,openings)
mineral_surfaces+=apply_mineral_surfaces(s)
for field, reports in (('illustratedTimber',craft_surfaces),('mineralSurfaces',mineral_surfaces)):
 merged={item['object']:item for item in reports}
 for repair in anchae_plan+anchae_veranda+anchae_rear_access+anchae_hall_access:merged.update({item['object']:item for item in repair[field]})
 merged={name:item for name,item in merged.items() if name in bpy.data.objects}
 reports[:]=merged.values()
created=[o for o in s.objects if o.type=='MESH' and o.get('northExtension')]
g.set_transform(lambda p:p);bpy.context.view_layer.update()
assert all(fingerprint(bpy.data.objects[name])==fp for name,fp in protected.items()),'Accepted south geometry was changed'
contract={'buildings':building_records,'doors':doors,'openings':openings,'walls':walls,'routes':routes,'sourceManifest':'references/eight-view-manifest.json','protectedSouthObjects':len(protected),'southNativeSha256':sha(SOUTH/'scene.blend'),'noDuplicateJung':True,'fullSurveyAccuracyClaimed':False,'sourceConflicts':[{'building':'arae','excluded':'jung-front-1990-excluded-from-arae.jpg','resolution':'User identity correction; current 2007 3-bay axes retained'},{'building':'anchae','conflict':'Eight-view generation depicts a gable end; measured front drawing depicts paljak roof','resolution':'Measured roof wins; artwork is pigment and joinery reference'},{'building':'angotgan','conflict':'Painted original/front turnaround has extra doors','resolution':'Sheet 029 four bays; three WD1 doors only'},{'building':'gokgan','conflict':'2007 same-title store has six bays; 1993 set has canonical five bays','resolution':'1993 sheets 023-030 establish 9750 x 5460 and four hip slopes; do not use six-bay sheet 011'}]}
for rec in building_records:
 obs=[o for o in created if o.get('construction_building')==rec['id']];p=[o.matrix_world@Vector(v) for o in obs for v in o.bound_box];rec['bounds']={'min':[min(v[k] for v in p) for k in range(3)],'max':[max(v[k] for v in p) for k in range(3)]};rec['meshes']=len(obs)
contract['timberSections']=timber_sections
contract['illustratedTimber']=craft_surfaces
contract['mineralSurfaces']=mineral_surfaces
contract['tileEndProfiles']=tile_end_profiles
contract['tileShells']=tile_shells
contract['shrineGateCraft']=shrine_gate_craft
contract['paintedTimber']=painted_timber
contract['shrineJoinery']=shrine_joinery
contract['roofEnvelopes']=roof_envelopes
contract['wallJoints']=wall_joints
contract['anchaePlanRepair']=anchae_plan
contract['anchaeVeranda']=anchae_veranda
contract['anchaeRearAccess']=anchae_rear_access
contract['anchaeHallAccess']=anchae_hall_access
from repair_northern_spatial_detail import repair as repair_spatial
from apply_site002_registration import apply as register_site
from northern_courtyard_photo_repair import repair as repair_courtyard
from northern_anchae_photo_fittings import add as add_fittings
from northern_survey_corrections import apply as apply_survey
repair_spatial(s,contract);register_site(s,contract);repair_courtyard(s,contract);add_fittings(s,contract)
apply_survey(s,contract)
created=[o for o in s.objects if o.type=='MESH' and o.get('northExtension')]
bpy.context.view_layer.update()
for rec in building_records:
 obs=[o for o in created if o.get('construction_building')==rec['id']];pts=[o.matrix_world@Vector(v) for o in obs for v in o.bound_box]
 rec['bounds']={'min':[min(p[k] for p in pts) for k in range(3)],'max':[max(p[k] for p in pts) for k in range(3)]};rec['meshes']=len(obs)
(OUT/'northern-contract.json').write_text(json.dumps(contract,ensure_ascii=False,indent=2),encoding='utf8')
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'scene.blend'),compress=True)
for o in s.objects:o.select_set(False)
for o in created:o.hide_set(False);o.hide_render=False;o.select_set(True)
bpy.context.view_layer.objects.active=created[0]
bpy.ops.export_scene.gltf(filepath=str(OUT/'northern.glb'),export_format='GLB',use_selection=True,export_apply=True,export_animations=False,export_cameras=False,export_lights=False,export_yup=True,export_extras=True)
print('NORTHERN COURT BUILT',len(created),'protected south meshes',len(protected),flush=True)
