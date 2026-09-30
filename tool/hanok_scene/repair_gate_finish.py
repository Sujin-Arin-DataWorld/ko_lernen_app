"""Finish the gate shown in 084/085, including the previously missing siding.

The X braces are internal members. THK45 pungjipan and the adjacent masonry
are visible in elevation and photographs; a naked skeleton is not a finish.
"""
import bpy, numpy as np, math
from mathutils import Vector,Matrix
from northern_courtyard_photo_repair import g,d,tag_flush

def apply(scene,c):
 nm='North.site.rear yard gate';r=c['rearYardGate'];origin=Vector((*r['center'],1.5));rot=Matrix.Rotation(r['angle'],3,'Z')
 wood=bpy.data.materials['North anchae wood'];beam=bpy.data.materials['North anchae beam'];clay=bpy.data.materials['North earthen plaster'];end=bpy.data.materials['North lime tile ends']
 tiles=[bpy.data.materials[f'Ansarang retained V33 main_gate source ceramic {i}'] for i in range(6)]
 for ob in list(scene.objects):
  if ob.name.startswith(nm+'.roof') or ob.name.startswith(nm+'.gable board'):bpy.data.objects.remove(ob,do_unlink=True)
 g.BATCHES.clear();g.set_transform(lambda p:origin+rot@Vector(p))
 # Siding thickness is printed on 085; its upper contour is traced from
 # the side elevation. It encloses the braces rather than deleting them.
 for side in (-1,1):
  old=g.TRANSFORM;g.set_transform(lambda p,s=side:old((s*.5575+p[1],p[0],p[2])))
  def top(y):return 1.625+.20*(1-abs(y)/.405)
  for j in range(6):
   a=-.405+j*.135+.0007;b=a+.1336
   d.extruded_profile(nm+'.finish pungjipan THK45',[(a,.16),(b,.16),(b,top(b)),(a,top(a))],-.0225,.0225,wood)
  g.set_transform(old)
 # Roof deck, bedding and tiles form one supported section, not a thin
 # floating sheet. Surface extrema remain within the 2210 x 1516 plan.
 def z(x,y):
  t=abs(y)/.758;return 1.855+.300*(1-t)**1.25+.075*(abs(x)/1.105)**8*t*t
 for side in (-1,1):
  for i in range(32):
   a=-1.105+i*2.210/32;b=a+2.210/32
   for j in range(16):
    y0=side*j*.758/16;y1=side*(j+1)*.758/16
    q=[(a,y0),(b,y0),(b,y1),(a,y1)]
    for dep,mat,label in ((.130,wood,'deck'),(.075,clay,'clay bedding')):
     vv=[(x,y,z(x,y)-dep) for x,y in q];g.face(nm+'.finish roof '+label,vv if side>0 else list(reversed(vv)),mat)
   y=side*.758
   # Continuous yeonham, 60 x 80, follows the eave rise.
   poly=[(a,z(a,y)-.16),(b,z(b,y)-.16),(b,z(b,y)-.08),(a,z(a,y)-.08)]
   d.extruded_profile(nm+'.finish yeonham 60x80',poly,y-.03,y+.03,beam)
  # Seven cover lines are traced on elevation 085, not a historic tile count.
  pitch=2.210/7
  for col in range(7):
   x=-1.105+(col+.5)*pitch
   for row in range(4):
    y0=side*(row*.758/4);y1=side*min(.758,(row+1)*.758/4+.012)
    for k in range(12):
     a=k*math.pi/12;b=(k+1)*math.pi/12;vv=[]
     for y,ang,dz in ((y0,a,0),(y0,b,0),(y1,b,.005),(y1,a,.005)):
      xx=x+.075*math.cos(ang);vv.append((xx,y,z(xx,y)+.018+.065*math.sin(ang)+dz))
     g.face(nm+'.finish roof sukiwa',vv,tiles[(col+row)%6])
    for k in range(8):
     f0=k/8;f1=(k+1)/8;vv=[]
     for y,f,dz in ((y0,f0,0),(y0,f1,0),(y1,f1,.004),(y1,f0,.004)):
      xx=x-pitch/2+pitch*f;vv.append((xx,y,z(xx,y)-.006-.025*abs(math.cos(f*math.pi))+dz))
     g.face(nm+'.finish roof amkiwa',vv,tiles[(col+row+2)%6])
   # Seal the actual half-round end instead of a detached white disk.
   y=side*.758;vs=[(x+.075*math.cos(t),y+side*.009,z(x,y)+.018+.065*math.sin(t)) for t in np.linspace(0,math.pi,18)]
   g.face(nm+'.finish roof end cap',vs,end)
 # Thick, shaped barge boards support the sides of the bedding.
 for side in (-1,1):
  old=g.TRANSFORM;g.set_transform(lambda p,s=side:old((s*.790+p[1],p[0],p[2])))
  upper=[(y,z(side*.790,y)-.070) for y in np.linspace(-.70,.70,25)]
  lower=[(y,h-.150) for y,h in reversed(upper)]
  d.extruded_profile(nm+'.finish shaped barge board',upper+lower,-.0225,.0225,wood);g.set_transform(old)
 # Flat three-course ridge bed with articulated joints and a rounded cap.
 for level in range(3):
  for j in range(11):
   x=-1.02+(j+.5)*2.04/11;zz=2.175+level*.045+.055*(abs(x)/1.02)**8
   g.box(nm+'.finish roof ridge courses',(x,0,zz),(2.04/11-.004,.19-level*.018,.042),tiles[(j+level)%6])
 for j in range(22):
  a=-1.045+j*2.09/22;b=a+2.09/22;h=lambda x:2.30+.040*(abs(x)/1.045)**8
  g.rod(nm+'.finish roof ridge cap',(a,0,h(a)),(b,0,h(b)),.060,tiles[j%6],18)
 # Door schedule: two boards per leaf, versus generic equal thirds.
 for ob in list(scene.objects):
  if ob.name.startswith(nm+'.plank door') and 'WD1 plank' in ob.name:bpy.data.objects.remove(ob,do_unlink=True)
 for leaf in range(2):
  a=-.420+leaf*.420
  for j in range(2):g.box(nm+f'.plank door.leaf{leaf+1}.WD1 solid board 30mm',(a+(j+.5)*.210,0,.895),(.209,.030,1.400),wood)
 obs=tag_flush('north_site');g.set_transform(lambda p:p)
 for ob in obs:
  if 'roof sukiwa' in ob.name:
   for p in ob.data.polygons:p.use_smooth=True
  if any(t in ob.name for t in ('roof sukiwa','roof amkiwa','roof deck','roof clay bedding')):
   m=ob.modifiers.new('Physical ceramic or deck thickness','SOLIDIFY');m.thickness=.012 if 'roof' in ob.name else .020;m.offset=-1
 c['gateFinishCorrection']={'pungjipanThickness':.045,'source':'085 side elevations','internalBracesRetained':True,'doorBoardThickness':.030,'doorScheduleBoardsPerLeaf':2,'roofPlan':[2.210,1.516],'interpreted':['curvature between section heights','tile layout between traced seven cover lines','joinery clearances'],'previousDefects':['missing side enclosure','missing roof section build-up','excessively segmented generic tile laps']}
