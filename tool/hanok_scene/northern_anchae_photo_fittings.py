"""Anchae kitchen and hearth fittings from the supplied photographic evidence.

The enclosing surveyed building is retained. Hearth/pot profiles, curved wear
and grille spacing are photographic interpretations, never survey dimensions.
"""
from pathlib import Path
import bpy,math,sys
import numpy as np
from mathutils import Vector,Matrix
sys.path.insert(0,str(Path(__file__).parent))
from northern_wall_joints import basis
from northern_courtyard_photo_repair import tag_flush,g,d
from refine_northern_materials import apply_craft_surfaces

def add(scene,c):
 if c.get('anchaePhotoFittingsVersion'):return
 origin,rot,axes=basis(c['buildings']);rec=next(r for r in c['buildings'] if r['id']=='anchae');g.BATCHES.clear();g.set_transform(lambda p:origin+rot@Vector(p))
 wood=bpy.data.materials['North anchae wood'];beam=bpy.data.materials['North anchae beam'];lime=bpy.data.materials['North lime plaster'];iron=bpy.data.materials['North forged iron']
 cx=(axes[1]+axes[2])/2
 # The saved scene already has its elevation translated relative to the
 # initial builder. Register to the actual window, not the old hardcoded Z.
 existing=bpy.data.objects['North.anchae.kitchen high ventilator.stile']
 inv=rot.inverted();points=np.array([inv@(existing.matrix_world@v.co-origin) for v in existing.data.vertices])
 vent_bottom=float(points[:,2].min());vent_top=vent_bottom+.560
 # Retain the door schedule rectangle; the photographed edge wear is an
 # inset curve at the lower ends of the seven planks, not an enlarged door.
 for ob in list(scene.objects):
  if ob.get('construction_building')!='anchae':continue
  if ob.name.startswith('North.anchae.kitchen.') and any(t in ob.name for t in ('solid board','forged hinge','.nail','rear rail')):bpy.data.objects.remove(ob,do_unlink=True)
  elif ('kitchen high ventilator' in ob.name and any(t in ob.name for t in ('three horizontal bars','.stile','.rail'))) or ob.name.startswith('North.anchae.photo low maru'):bpy.data.objects.remove(ob,do_unlink=True)
 for leaf in range(2):
  a=cx-.56+leaf*.56+.004;b=a+.552;nm=f'North.anchae.kitchen.leaf{leaf+1}'
  for i in range(4):
   l=a+i*(b-a)/4;r=a+(i+1)*(b-a)/4-.0025
   def lower(x):return .35+.16*(abs((x-cx)/.56)**1.6)
   poly=[(l,lower(l)),(r,lower(r)),(r,2.07),(l,2.07)]
   d.extruded_profile(nm+'.photo curved plank',poly,-2.332,-2.308,wood)
  for z in (.62,1.80):g.box(nm+'.photo front timber rail',((a+b)/2,-2.352,z),(b-a-.02,.040,.065),beam)
 # Diamond vent: intersect each diagonal with the existing 1626 x 560 frame.
 for x in (cx-.813+.026,cx+.813-.026):g.box('North.anchae.kitchen high ventilator.stile',(x,-2.350,(vent_bottom+vent_top)/2),(.052,.040,.560),wood)
 for z in (vent_bottom+.026,vent_top-.026):g.box('North.anchae.kitchen high ventilator.rail',(cx,-2.350,z),(1.626-.104,.040,.052),wood)
 x0,x1=cx-.813+.052,cx+.813-.052;z0,z1=vent_bottom+.052,vent_top-.052
 for sign in (-1,1):
  offsets=[z-sign*x for x in (x0,x1) for z in (z0,z1)]
  for off in np.arange(min(offsets),max(offsets),.108):
   candidates=[]
   for x in (x0,x1):
    z=sign*x+off
    if z0<=z<=z1:candidates.append((x,z))
   for z in (z0,z1):
    x=(z-off)/sign
    if x0<x<x1:candidates.append((x,z))
   if len(candidates)==2:
    a,b=candidates; dx,dz=b[0]-a[0],b[1]-a[1];length=math.hypot(dx,dz)
    ox,oz=-dz/length*.004,dx/length*.004
    verts=[(x+sign*ox,-2.350+dep,z+sign*oz) for dep in (-.0125,.0125) for x,z,sign in ((a[0],a[1],-1),(b[0],b[1],-1),(b[0],b[1],1),(a[0],a[1],1))]
    for ids in ((0,3,2,1),(4,5,6,7),(0,1,5,4),(1,2,6,5),(2,3,7,6),(3,0,4,7)):g.face('North.anchae.kitchen high ventilator diamond sal',[verts[i] for i in ids],wood)
 def lid(nm,x,y,z,r):
  for j in range(6):
   r0=r*j/6;r1=r*(j+1)/6
   for i in range(32):
    a=i*math.tau/32;b=(i+1)*math.tau/32
    def p(rad,t):return(x+rad*math.cos(t),y+rad*math.sin(t),z+.035*(1-(rad/r)**2))
    g.face(nm+'.cast iron lid',[p(r0,a),p(r0,b),p(r1,b),p(r1,a)],iron)
  g.rod(nm+'.lid knob',(x,y,z+.027),(x,y,z+.074),.018,iron,14)
 def hearth(nm,x,y,width,depth,height,base):
  # An actual cavity with a front arch and a recessed back. The dark mouth
  # is the unlit interior between the cheeks, not a pasted black rectangle.
  a=width/2;hole=min(.135,width*.22);h=min(.32,height*.69)
  profile=[(x-a,base),(x-a,base+height),(x+a,base+height),(x+a,base),(x+hole,base),(x+hole,base+h*.8),(x+hole*.78,base+h),(x-hole*.78,base+h),(x-hole,base+h*.8),(x-hole,base)]
  d.extruded_profile(nm+'.arched fire mouth',profile,y-depth/2,y-depth/2+.12,lime)
  for sign in (-1,1):g.box(nm+'.hearth cheek',(x+sign*(a-.07),y+.03,base+height/2),(.14,depth-.16,height),lime)
  g.box(nm+'.rear hearth body',(x,y+depth/2-.09,base+height/2),(width,.18,height),lime)
  g.box(nm+'.cooking top',(x,y,base+height-.045),(width,depth,.090),lime)
  lid(nm,x,y,base+height+.018,min(.23,width*.34))
 # L-shaped three-pot kitchen seen in photo 7, within the measured kitchen.
 for i,(x,y) in enumerate(((cx-.59,.88),(cx+.31,.88),(cx+.48,-.01))):hearth('North.anchae.photo kitchen stove '+str(i),x,y,.85,.81,.56,.27)
 # The east room has a low panelled porch rail and a small stove beneath.
 a,b=axes[6]+.14,axes[7]-.13;hx=(a+b)/2
 for z in (.73,1.02):g.box('North.anchae.photo low maru handrail',((a+b)/2,-2.23,z),(b-a,.105,.075),wood)
 for x in np.linspace(a,b,7):g.box('North.anchae.photo low maru upright',(x,-2.23,.875),(.054,.084,.31),wood)
 for left,right in zip(np.linspace(a,b,7),np.linspace(a,b,7)[1:]):g.box('North.anchae.photo low maru inset panel',((left+right)/2,-2.207,.875),(right-left-.055,.025,.20),wood)
 hearth('North.anchae.photo east room hearth',hx,-2.08,.78,.70,.31,.10)
 # The removable iron cover slopes outward into the shallow ash recess.
 g.rod('North.anchae.photo hearth iron cover side',(hx-.115,-2.73,.03),(hx-.115,-2.43,.34),.010,iron,8)
 g.rod('North.anchae.photo hearth iron cover side',(hx+.115,-2.73,.03),(hx+.115,-2.43,.34),.010,iron,8)
 old=g.TRANSFORM;theta=-math.pi/4
 g.set_transform(lambda p:old((hx+p[0],-2.58+p[1]*math.cos(theta)-p[2]*math.sin(theta),.185+p[1]*math.sin(theta)+p[2]*math.cos(theta))))
 g.box('North.anchae.photo hearth removable cover',(0,0,0),(.23,.017,.43),iron);g.set_transform(old)
 tag_flush('anchae');g.set_transform(lambda p:p)
 c['illustratedTimber']+=apply_craft_surfaces(scene)
 c['anchaePhotoFittingsVersion']=1
 c['anchaePhotoFittings']={'kitchen':'Diamond vent, inset curved plank ends, wood front rails, three-pot L-shaped hearth','eastRoom':'Inset panelled low porch rail and hollow fire mouth with iron pot lid','authority':'2007 Anchae WD1: 1120x1720, board24, rails65x40; WW9: 1626x560, frame52x40, sal8x25. Photographs supplement wear and hearth forms','interpreted':['Hearth sizes and precise offsets','Curvature of worn door bottoms','Grille pitch','Small iron hardware']}
 c['anchaePhotoFittings']['ventPlacement']={'bottom':vent_bottom,'top':vent_top,'status':'Registered to retained window elevation. Absolute height and separation from WD1 need section reconciliation.'}
 bpy.context.view_layer.update()
