"""Explicit sculpted solid features for a roof-mounted ceramic Dokkaebi relief."""
import bpy,math
from mathutils import Vector

def add_sculpt(sc,cap,kind):
 import guardian_sculpt_r11 as g
 center=Vector((12.56,-3.544,6.66+.18)) if kind=='main' else Vector((9.195 if 'left' in cap.name else 15.925,-5.401,4.793+.065))
 scale=1 if kind=='main' else .5
 collection=cap.users_collection[0];body=bpy.data.materials['HS11 fired mineral teal guardian'];edge=bpy.data.materials['HS11 worn mineral ridge']
 cavity=bpy.data.materials.get('HS11 recessed ceramic') or g.make_material('HS11 recessed ceramic','333D33')
 parts=[]
 def keep(o,name,mat):
  o.name=cap.name+' '+name
  for co in list(o.users_collection):co.objects.unlink(o)
  collection.objects.link(o);o.data.materials.clear();o.data.materials.append(mat);o['construction_parent']=cap['construction_parent'];parts.append(o)
  for poly in getattr(o.data,'polygons',[]):poly.use_smooth=True
  return o
 def ellipsoid(name,loc,radii,mat=body,rotation=0):
  bpy.ops.mesh.primitive_uv_sphere_add(segments=40,ring_count=24,location=center+Vector(loc)*scale)
  o=bpy.context.object;o.scale=Vector(radii)*scale;o.rotation_euler.y=rotation;bpy.ops.object.transform_apply(location=False,rotation=False,scale=True);return keep(o,name,mat)
 def path(name,points,radii,mat=body):
  # Swept closed tube with individually tapered rings and rounded ends.
  ps=[Vector(x) for x in points];verts=[];faces=[];sides=12
  for i,pt in enumerate(ps):
   tangent=(ps[min(len(ps)-1,i+1)]-ps[max(0,i-1)]).normalized();ref=Vector((0,1,0))
   if abs(tangent.dot(ref))>.95:ref=Vector((1,0,0))
   u=tangent.cross(ref).normalized();v=tangent.cross(u).normalized()
   for k in range(sides):
    a=2*math.pi*k/sides;co=center+(pt+(u*math.cos(a)+v*math.sin(a))*radii[i])*scale;verts.append(tuple(co))
  for i in range(len(ps)-1):
   for k in range(sides):j=(k+1)%sides;faces.append((i*sides+k,(i+1)*sides+k,(i+1)*sides+j,i*sides+j))
  faces.append(tuple(reversed(range(sides))));faces.append(tuple((len(ps)-1)*sides+k for k in range(sides)))
  me=bpy.data.meshes.new(name);me.from_pydata(verts,[],faces);me.update();o=bpy.data.objects.new(name,me);collection.objects.link(o);return keep(o,name,mat)
 def bez(a,b,c,d,n=28):
  a,b,c,d=map(Vector,[a,b,c,d]);return [(1-t)**3*a+3*(1-t)**2*t*b+3*(1-t)*t*t*c+t**3*d for t in [i/(n-1) for i in range(n)]]
 def stroke(name,a,b,c,d,r,mat=body,taper=True):
  ps=bez(a,b,c,d);rs=[r*(.24+.76*math.sin(math.pi*i/(len(ps)-1))**.45) if taper else r for i in range(len(ps))];return path(name,ps,rs,mat)
 def cut(obj,cutter):
  bpy.context.view_layer.objects.active=obj;mod=obj.modifiers.new('Actual carved recess','BOOLEAN');mod.operation='DIFFERENCE';mod.solver='EXACT';mod.object=cutter;bpy.ops.object.modifier_apply(modifier=mod.name);parts.remove(cutter);bpy.data.objects.remove(cutter,do_unlink=True)
 head=ellipsoid('carved face',(0,-.005,0),(.085,.024,.092))
 # Hollow eye and mouth recesses are Boolean cuts in the face volume.
 for s in [-1,1]:
  cutter=ellipsoid('socket cutter',(s*.033,-.025,.025),(.023,.017,.014),rotation=s*.16);cut(head,cutter)
 cutter=ellipsoid('smile cutter',(0,-.025,-.045),(.043,.018,.021));cut(head,cutter)
 for s in [-1,1]:
  ellipsoid('cheek '+str(s),(s*.052,-.016,-.018),(.031,.018,.029))
  ellipsoid('recessed eye '+str(s),(s*.033,-.011,.025),(.016,.007,.010),cavity)
  ellipsoid('iris '+str(s),(s*.030,-.018,.026),(.0045,.0038,.007),edge)
  stroke('upper eyelid '+str(s),(s*.010,-.026,.027),(s*.025,-.029,.043),(s*.048,-.027,.041),(s*.057,-.021,.026),.0025,edge)
  stroke('lower eyelid '+str(s),(s*.010,-.024,.021),(s*.025,-.026,.011),(s*.048,-.023,.012),(s*.057,-.020,.026),.0018)
  stroke('heavy brow '+str(s),(s*.009,-.023,.045),(s*.026,-.033,.067),(s*.052,-.027,.060),(s*.068,-.010,.044),.008)
  # Pointed ears lean into the face, remaining inside the original cap footprint.
  stroke('ear '+str(s),(s*.070,-.002,.013),(s*.086,-.010,.039),(s*.104,-.009,.045),(s*.112,-.001,.046),.011)
  stroke('ear inner '+str(s),(s*.074,-.017,.017),(s*.085,-.018,.029),(s*.098,-.015,.035),(s*.105,-.006,.039),.002,edge)
 # Wide nose and nostrils are distinct solids with actual cavities.
 nose=ellipsoid('broad nose',(0,-.030,-.005),(.024,.014,.017))
 ellipsoid('nose bridge',(0,-.018,.019),(.012,.015,.032))
 for s in [-1,1]:
  cutter=ellipsoid('nostril cutter',(s*.012,-.041,-.011),(.005,.007,.0035));cut(nose,cutter)
 ellipsoid('mouth shadow',(0,-.007,-.046),(.036,.005,.015),cavity)
 stroke('lower grin',(-.042,-.020,-.031),(-.034,-.028,-.076),(.034,-.028,-.076),(.042,-.020,-.031),.004)
 for s in [-1,1]:
  ps=bez((s*.024,-.028,-.032),(s*.028,-.033,-.038),(s*.024,-.034,-.050),(s*.019,-.029,-.057),18);path('fang '+str(s),ps,[.006*(1-i/17)+.0005 for i in range(18)],edge)
  # Curved conical horns, not a color/height-map representation.
  ps=bez((s*.049,-.010,.073),(s*.066,-.029,.100),(s*.050,-.032,.128),(s*.047,-.018,.140),32)
  path('horn '+str(s),ps,[.013*(1-i/31)**.85+.00035 for i in range(32)],edge)
  # Thick swept hair masses with fine raised strands following each mass.
  for k in range(5):
   z=.055+k*.014;x=.025+k*.012
   a=(s*.014,-.008,z);b=(s*(x+.040),-.024,z+.046);cc=(s*.095,-.011,z+.038);d=(s*(.078+.004*k),.002,z-.018)
   stroke('swept hair '+str(s)+' '+str(k),a,b,cc,d,.0075)
   a2=(a[0],a[1]-.005,a[2]+.002);b2=(b[0],b[1]-.006,b[2]+.002);c2=(cc[0],cc[1]-.006,cc[2]+.002);d2=(d[0],d[1]-.004,d[2])
   stroke('hair strand '+str(s)+' '+str(k),a2,b2,c2,d2,.001,edge)
  # Cheek spiral cut/ridge treatment.
  ts=[i*2*math.pi/40 for i in range(41)];ps=[]
  for i,t in enumerate(ts):r=.012*(1-i/45);ps.append((s*(.061+r*math.cos(t)),-.031,-.018+r*math.sin(t)))
  path('cheek scroll '+str(s),ps,[.0013]*len(ps),edge)
 stroke('headband',(-.063,-.009,.069),(-.020,-.025,.076),(.020,-.025,.076),(.063,-.009,.069),.0035,edge)
 # Surrounding clouds connect the face to the architectural border as real tubes.
 if kind=='main':
  for i,(x,z,r) in enumerate([(-.105,-.045,.021),(.105,-.045,.021),(-.082,.155,.020),(.082,.155,.020),(0,.195,.020),(-.058,-.100,.020),(.058,-.100,.020)]):
   ts=[j*math.pi*2.4/64 for j in range(65)];ps=[(x+(r*(1-j/74))*math.cos(t),-.003,z+(r*(1-j/74))*math.sin(t)) for j,t in enumerate(ts)];path('border cloud '+str(i),ps,[.0024]*len(ps),edge)
 # All new sculpt parts retain a shared construction owner. Source meshes untouched.
 return [o.name for o in parts]
